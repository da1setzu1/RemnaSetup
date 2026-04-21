# RemnaNodeSetup

Автоматический установщик **RemnaNode** и оптимизации сервера.  
Поддержка серверов в России (Docker Hub заблокирован — используются зеркала).

**by Daisetzu1**

---

## Быстрый старт

Выполните на сервере от root:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/da1setzu1/RemnaSetup/main/setup.sh)
```

> Если нет `curl`:
> ```bash
> apt install -y curl && bash <(curl -fsSL https://raw.githubusercontent.com/da1setzu1/RemnaSetup/main/setup.sh)
> ```

---

## Требования

- Ubuntu 22.04 / 24.04 или Debian 11 / 12
- Права root (`sudo` или прямой вход под root)
- Интернет-соединение

---

## Как это работает

### Шаг 1 — Выбор гео

При запуске скрипт спрашивает, где находится сервер:

```
  ╔══════════════════════════════════════════╗
  ║    На каком гео находится сервер?        ║
  ╠══════════════════════════════════════════╣
  ║                                          ║
  ║    1. Россия                             ║
  ║    2. Не Россия                          ║
  ║                                          ║
  ╚══════════════════════════════════════════╝
```

Если выбрана **Россия** — Docker устанавливается через зеркала (Docker Hub заблокирован):
- `mirror.gcr.io`
- `dockerhub.icu`
- `docker.1panel.live`

### Шаг 2 — Меню

После выбора гео появляется меню:

```
  Выберите действие:

  1.  Установить все вместе (Откл IPv6, установка bbr, keepalive, fail2ban, ipset, remnanode)
  2.  Отключение IPv6
  3.  Установка BBR TCP
  4.  SSH KeepAlive
  5.  Fail2ban
  6.  ipset
  7.  Установка RemnaNode
  8.  Установка Zapret (для ютуб)
  9.  Оптимизация сервера (Откл IPv6, установка bbr, keepalive, fail2ban, ipset)
```

---

## Что делает каждый пункт

### 1. Установить всё вместе
Запускает по порядку: **2 → 3 → 4 → 5 → 6 → 7**.  
**Zapret не включён** — его нужно ставить отдельно (пункт 8).

---

### 2. Отключение IPv6

Добавляет в `/etc/sysctl.conf`:
```
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
```
Применяет `sysctl -p`.

---

### 3. Установка BBR TCP

Добавляет в `/etc/sysctl.conf`:
```
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
```
Ускоряет TCP-трафик — особенно актуально для прокси-нагрузки.

---

### 4. SSH KeepAlive

Добавляет в `/etc/ssh/sshd_config`:
```
ClientAliveInterval 60
ClientAliveCountMax 10
```
Предотвращает разрыв SSH-сессий при простое.

---

### 5. Fail2ban

Устанавливает `fail2ban` и настраивает защиту SSH:
- Максимум **5 неудачных попыток** входа
- Бан на **3600 секунд** (1 час)
- Окно проверки **600 секунд**

Конфиг сохраняется в `/etc/fail2ban/jail.local`.

---

### 6. ipset — блокировка сканеров

Устанавливает `ipset` и создаёт скрипт `/usr/local/bin/skipa-block.sh`.

Скрипт:
1. Скачивает актуальный список IP-сканеров (CyberOK/Skipa) с `antifilter.download`
2. Добавляет их в ipset `skipa_scan`
3. Блокирует через `iptables`

Автообновление через cron — **каждый день в 03:00**.

Ручное обновление списка в любой момент:
```bash
/usr/local/bin/skipa-block.sh
```

---

### 7. Установка RemnaNode

Полный процесс установки по [официальной документации](https://docs.rw/docs/install/remnawave-node):

1. Устанавливается Docker (с зеркалами если сервер в России)
2. Создаётся директория `/opt/remnanode`
3. Скрипт предлагает перейти в панель RemnaWave и скопировать `docker-compose.yml`:
   ```
   Nodes → Management → Add Node → скопировать docker-compose.yml
   ```
4. Открывается редактор `nano` — нужно вставить конфиг (`Ctrl+Shift+V`) и сохранить (`Ctrl+X → Y → Enter`)
5. Запускается `docker compose up -d`
6. Показываются последние логи контейнера
7. Появляется сообщение: **вернитесь в панель и нажмите Next**

> **Важно:** `docker-compose.yml` генерируется индивидуально в вашей панели RemnaWave — у каждой ноды свой конфиг с уникальным `SECRET_KEY`.

Полезные команды после установки:
```bash
# Следить за логами
cd /opt/remnanode && docker compose logs -f -t

# Перезапустить
cd /opt/remnanode && docker compose restart

# Остановить
cd /opt/remnanode && docker compose down

# Обновить образ
cd /opt/remnanode && docker compose pull && docker compose up -d
```

---

### 8. Установка Zapret (обход DPI-блокировок)

Устанавливает [zapret](https://github.com/bol-van/zapret) — обход DPI-блокировок (YouTube, Discord, Telegram и др.).

Установка **полностью автоматизирована** через `expect`. Скрипт автоматически:

- Определяет **основной сетевой интерфейс** (eth0, ens3 и т.д.) — больше не нужно выбирать вручную
- Определяет **тип файрволла**: `nftables` если доступен (Ubuntu 22.04+), иначе `iptables`

Ответы на все вопросы установщика:

| Вопрос | Ответ | Причина |
|--------|-------|---------|
| **firewall type** | **авто** (`nftables` или `iptables`) | **Определяется автоматически по ОС** |
| flow offloading | `none` | Универсальный режим |
| filtering | `hostlist` | Обработка по списку доменов |
| tpws socks mode | `N` | SOCKS-прокси не нужен |
| tpws transparent | `Y` | Основной метод обхода DPI |
| edit options | `N` | Параметры по умолчанию |
| nfqws | `N` | Не нужен при работающем tpws |
| **LAN interface** | **авто** | **Определяется автоматически** |
| **WAN interface** | **авто** | **Определяется автоматически** |
| auto download | `Y` | Автозагрузка списка доменов |
| list type | `get_antizapret_domains.sh` | Самый популярный список |

> Ошибки `Failed to disable/stop zapret.service` при установке — **это нормально**, так как сервис запускается впервые.
> Ошибка `gzip: stdin: unexpected end of file` при скачивании списка — временная проблема с источником, список обновится по таймеру или вручную.

Проверка после установки:
```bash
systemctl status zapret --no-pager
systemctl status zapret-list-update.timer --no-pager
```

Ручное обновление списка доменов:
```bash
cd /opt/zapret && sudo ./get_antizapret_domains.sh && sudo systemctl restart zapret
```

Добавление своих доменов в список:
```bash
sudo nano /opt/zapret/ipset/zapret-hosts-user.txt
# по одному домену на строку, например:
# discord.com
# discordapp.com
sudo systemctl restart zapret
```

---

### 9. Оптимизация сервера

Запускает пункты **2 + 3 + 4 + 5 + 6** без установки RemnaNode и Zapret.  
Подходит если нода уже установлена или устанавливается вручную.

---

## Структура файлов после установки

```
/opt/remnanode/
└── docker-compose.yml     — конфиг RemnaNode (из панели)

/opt/zapret/               — если установлен Zapret
/usr/local/bin/skipa-block.sh  — скрипт блокировки сканеров
/etc/cron.d/skipa-block    — автообновление списка
/etc/fail2ban/jail.local   — конфиг Fail2ban
```

---

## Лицензия

MIT
