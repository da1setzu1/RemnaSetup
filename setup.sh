#!/bin/bash
# RemnaNodeSetup — Автоматическая установка
# by Daisetzu1

# ============================================================
# ЦВЕТА И ПЕРЕМЕННЫЕ
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

GEO=""

# ============================================================
# УТИЛИТЫ
# ============================================================
ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${CYAN}[→]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }

pause() {
    echo ""
    read -rp "  Нажмите Enter для продолжения..."
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        err "Запустите скрипт от имени root: sudo bash setup.sh"
        exit 1
    fi
}

# ============================================================
# ВЫБОР ГЕО
# ============================================================
ask_geo() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║    На каком гео находится сервер?        ║"
    echo "  ╠══════════════════════════════════════════╣"
    echo "  ║                                          ║"
    echo "  ║    1. Россия                             ║"
    echo "  ║    2. Не Россия                          ║"
    echo "  ║                                          ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    read -rp "  Введите цифру: " geo_choice

    case "$geo_choice" in
        1) GEO="russia" ;;
        2) GEO="other"  ;;
        *)
            err "Неверный выбор, попробуйте снова"
            sleep 1
            ask_geo
            ;;
    esac
}

# ============================================================
# БАННЕР
# ============================================================
show_banner() {
    clear
    local COLS
    COLS=$(tput cols 2>/dev/null || echo 80)
    echo -e "${GREEN}${BOLD}"
    cat << 'BANNER'

  ██████╗ ███████╗███╗   ███╗███╗   ██╗ █████╗
  ██╔══██╗██╔════╝████╗ ████║████╗  ██║██╔══██╗
  ██████╔╝█████╗  ██╔████╔██║██╔██╗ ██║███████║
  ██╔══██╗██╔══╝  ██║╚██╔╝██║██║╚██╗██║██╔══██║
  ██║  ██║███████╗██║ ╚═╝ ██║██║ ╚████║██║  ██║
  ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝

  ███╗   ██╗ ██████╗ ██████╗ ███████╗
  ████╗  ██║██╔═══██╗██╔══██╗██╔════╝
  ██╔██╗ ██║██║   ██║██║  ██║█████╗
  ██║╚██╗██║██║   ██║██║  ██║██╔══╝
  ██║ ╚████║╚██████╔╝██████╔╝███████╗
  ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝

  ███████╗███████╗████████╗██╗   ██╗██████╗
  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
  ███████╗█████╗     ██║   ██║   ██║██████╔╝
  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
  ███████║███████╗   ██║   ╚██████╔╝██║
  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝

BANNER
    echo -e "${NC}"
    printf "%${COLS}s\n" "by Daisetzu1"
    echo ""
}

# ============================================================
# МЕНЮ
# ============================================================
show_menu() {
    show_banner
    echo -e "  ${WHITE}${BOLD}Выберите действие:${NC}"
    echo ""
    echo -e "  ${CYAN}1.${NC}  Установить все вместе (IPv6, bbr, keepalive, fail2ban, ipset, remnanode, zapret)"
    echo -e "  ${CYAN}2.${NC}  Отключение IPv6"
    echo -e "  ${CYAN}3.${NC}  Установка BBR TCP"
    echo -e "  ${CYAN}4.${NC}  SSH KeepAlive"
    echo -e "  ${CYAN}5.${NC}  Fail2ban"
    echo -e "  ${CYAN}6.${NC}  ipset"
    echo -e "  ${CYAN}7.${NC}  Установка RemnaNode"
    echo -e "  ${CYAN}8.${NC}  Установка Zapret (для ютуб)"
    echo -e "  ${CYAN}9.${NC}  Оптимизация сервера (IPv6, bbr, keepalive, fail2ban, ipset)"
    echo ""
    read -rp "  Введите цифру: " menu_choice

    case "$menu_choice" in
        1) install_all      ;;
        2) disable_ipv6     ;;
        3) install_bbr      ;;
        4) install_keepalive ;;
        5) install_fail2ban ;;
        6) install_ipset    ;;
        7) install_remnanode ;;
        8) install_zapret   ;;
        9) optimize_server  ;;
        *)
            err "Неверный выбор"
            sleep 1
            show_menu
            ;;
    esac
}

# ============================================================
# 2. ОТКЛЮЧЕНИЕ IPv6
# ============================================================
disable_ipv6() {
    info "Отключение IPv6..."

    if grep -q "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf; then
        warn "IPv6 уже отключён в sysctl.conf, пропускаем"
    else
        cat >> /etc/sysctl.conf << 'EOF'
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
    fi

    sysctl -p
    ok "IPv6 отключён"
}

# ============================================================
# 3. УСТАНОВКА BBR TCP
# ============================================================
install_bbr() {
    info "Установка BBR TCP..."

    if grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        warn "BBR уже настроен в sysctl.conf, пропускаем"
    else
        cat >> /etc/sysctl.conf << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    fi

    sysctl -p
    ok "BBR TCP установлен"
}

# ============================================================
# 4. SSH KEEPALIVE
# ============================================================
install_keepalive() {
    info "Настройка SSH KeepAlive..."

    if grep -q "ClientAliveInterval" /etc/ssh/sshd_config; then
        warn "SSH KeepAlive уже настроен, пропускаем"
    else
        echo "ClientAliveInterval 60"  >> /etc/ssh/sshd_config
        echo "ClientAliveCountMax 10"  >> /etc/ssh/sshd_config
    fi

    systemctl restart sshd
    ok "SSH KeepAlive настроен"
}

# ============================================================
# 5. FAIL2BAN
# ============================================================
install_fail2ban() {
    info "Установка Fail2ban..."

    apt install -y fail2ban

    cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled  = true
port     = ssh
maxretry = 5
bantime  = 3600
findtime = 600
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban
    ok "Fail2ban установлен и запущен"
}

# ============================================================
# 6. IPSET (блокировка сканеров CyberOK/Skipa)
# ============================================================
install_ipset() {
    info "Установка ipset и блокировки сканеров..."

    apt install -y ipset curl

    cat > /usr/local/bin/skipa-block.sh << 'BLOCKSCRIPT'
#!/bin/bash

IPT="iptables"
IPSET_NAME="skipa_scan"

ipset -exist create "$IPSET_NAME" hash:net maxelem 50000

echo "Скачивание списка сканеров..."
LIST=$(curl -s "https://antifilter.download/list/skipa.tsv" 2>/dev/null)

if [ -z "$LIST" ]; then
    echo "Ошибка: не удалось скачать список"
    exit 1
fi

echo "Обновление ipset..."
ipset flush "$IPSET_NAME"

echo "$LIST" | grep -oP '^\d+\.\d+\.\d+\.\d+/\d+' | while read -r cidr; do
    ipset add "$IPSET_NAME" "$cidr" 2>/dev/null
done

ADDED=$(ipset list "$IPSET_NAME" | grep -c '^[0-9]' || true)
echo "Добавлено IP в ipset: $ADDED"

$IPT -C INPUT -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null || \
    $IPT -I INPUT -m set --match-set "$IPSET_NAME" src -j DROP

echo "Правила iptables обновлены"
echo "Готово!"
BLOCKSCRIPT

    chmod +x /usr/local/bin/skipa-block.sh

    /usr/local/bin/skipa-block.sh

    cat > /etc/cron.d/skipa-block << 'CRON'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 3 * * * root /usr/local/bin/skipa-block.sh > /dev/null 2>&1
CRON

    ok "ipset установлен, сканеры заблокированы"
}

# ============================================================
# ВСПОМОГАТЕЛЬНАЯ: УСТАНОВКА DOCKER
# ============================================================
install_docker() {
    info "Установка Docker..."

    apt update && apt upgrade -y

    if command -v docker &>/dev/null; then
        warn "Docker уже установлен, пропускаем установку"
    else
        curl -fsSL https://get.docker.com | sh
    fi

    systemctl enable docker
    systemctl start docker

    if [ "$GEO" = "russia" ]; then
        info "Настройка зеркал Docker (сервер в России)..."
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.gcr.io",
    "https://dockerhub.icu",
    "https://docker.1panel.live"
  ]
}
EOF
        systemctl restart docker
        ok "Зеркала Docker настроены"
    fi

    ok "Docker установлен и запущен"
}

# ============================================================
# 7. УСТАНОВКА REMNANODE
# ============================================================
install_remnanode() {
    info "Установка RemnaNode..."

    install_docker

    mkdir -p /opt/remnanode
    cd /opt/remnanode || exit 1

    echo ""
    echo -e "  ${YELLOW}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}${BOLD}║         ПОЛУЧИТЕ КОНФИГ ИЗ ПАНЕЛИ REMNAWAVE                  ║${NC}"
    echo -e "  ${YELLOW}${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}${BOLD}║                                                              ║${NC}"
    echo -e "  ${YELLOW}${BOLD}║  1. Войдите в панель RemnaWave                               ║${NC}"
    echo -e "  ${YELLOW}${BOLD}║  2. Nodes → Management → Add Node                           ║${NC}"
    echo -e "  ${YELLOW}${BOLD}║  3. Заполните форму создания ноды                            ║${NC}"
    echo -e "  ${YELLOW}${BOLD}║  4. Скопируйте содержимое docker-compose.yml из панели       ║${NC}"
    echo -e "  ${YELLOW}${BOLD}║                                                              ║${NC}"
    echo -e "  ${YELLOW}${BOLD}║  Когда скопируете — вернитесь сюда и нажмите Enter           ║${NC}"
    echo -e "  ${YELLOW}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -rp "  Нажмите Enter чтобы открыть редактор..."

    echo ""
    info "Откроется nano — вставьте скопированный конфиг (Ctrl+Shift+V)"
    info "Сохранение и выход: Ctrl+X → Y → Enter"
    sleep 1

    nano docker-compose.yml

    if [ ! -s docker-compose.yml ]; then
        err "Файл docker-compose.yml пустой или не создан! Установка прервана."
        exit 1
    fi

    ok "Конфиг сохранён, запускаем RemnaNode..."
    docker compose up -d

    echo ""
    info "Последние логи контейнера:"
    sleep 2
    docker compose logs --tail=30

    echo ""
    echo -e "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${GREEN}${BOLD}║              REMNANODE УСПЕШНО ЗАПУЩЕН!                      ║${NC}"
    echo -e "  ${GREEN}${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${GREEN}${BOLD}║                                                              ║${NC}"
    echo -e "  ${GREEN}${BOLD}║  Вернитесь в панель RemnaWave и нажмите Next                 ║${NC}"
    echo -e "  ${GREEN}${BOLD}║                                                              ║${NC}"
    echo -e "  ${GREEN}${BOLD}║  Следить за логами:                                          ║${NC}"
    echo -e "  ${GREEN}${BOLD}║  cd /opt/remnanode && docker compose logs -f -t              ║${NC}"
    echo -e "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================
# ВСПОМОГАТЕЛЬНАЯ: ОПРЕДЕЛЕНИЕ ОСНОВНОГО ИНТЕРФЕЙСА
# ============================================================
detect_main_iface() {
    local iface
    # Приоритет: eth0 > ens* > первый не-lo интерфейс
    iface=$(ip route show default | awk '/default/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -1)
    if [ -z "$iface" ]; then
        iface=$(ls /sys/class/net/ | grep -vE '^(lo|docker|br-)' | head -1)
    fi
    if [ -z "$iface" ]; then
        iface="eth0"
    fi
    echo "$iface"
}

# ============================================================
# 8. УСТАНОВКА ZAPRET
# ============================================================
install_zapret() {
    info "Установка Zapret (обход DPI-блокировок)..."

    apt update
    apt install -y git gcc make libnetfilter-queue-dev \
        libnfnetlink-dev libnftnl-dev zlib1g-dev libmnl-dev libcap-dev \
        libsystemd-dev iptables ipset expect

    cd /opt || exit 1
    if [ -d "zapret" ]; then
        warn "Директория /opt/zapret уже существует, удаляем..."
        systemctl stop zapret 2>/dev/null || true
        rm -rf zapret
    fi

    git clone https://github.com/bol-van/zapret
    cd zapret || exit 1

    # Определяем основной сетевой интерфейс
    MAIN_IFACE=$(detect_main_iface)
    info "Основной интерфейс: $MAIN_IFACE"

    # Определяем выбор интерфейса (номер в меню)
    # В меню zapret первым идёт NONE/ANY, поэтому +1 к номеру интерфейса
    IFACE_NUM="1"
    local ifaces
    ifaces=$(ls /sys/class/net/ | grep -vE '^(lo)$')
    local num=1
    for if_name in $ifaces; do
        if [ "$if_name" = "$MAIN_IFACE" ]; then
            IFACE_NUM="$((num + 1))"
            break
        fi
        num=$((num + 1))
    done

    # Определяем тип файрволла: nftables для Ubuntu 22.04+, иначе iptables
    FW_CHOICE="2"
    if command -v nft &>/dev/null && nft list ruleset &>/dev/null; then
        FW_CHOICE="2"  # nftables
    else
        FW_CHOICE="1"  # iptables
    fi
    info "Тип файрволла: $([ "$FW_CHOICE" = "2" ] && echo 'nftables' || echo 'iptables')"

    info "Запуск автоматической установки Zapret..."

    expect << EXPECT_SCRIPT
set timeout 300
log_user 1
spawn ./install_easy.sh

# Один блок — ловим ВСЕ вопросы по уникальным ключевым словам
# exp_continue на каждом — ждём следующий вопрос до финала
expect {
    -re {enable ipv6 support} {
        send "N\r"
        exp_continue
    }
    -re {select firewall type} {
        send "$FW_CHOICE\r"
        exp_continue
    }
    -re {select flow offloading} {
        send "1\r"
        exp_continue
    }
    -re {select filtering} {
        send "3\r"
        exp_continue
    }
    -re {tpws socks mode} {
        send "N\r"
        exp_continue
    }
    -re {tpws transparent mode} {
        send "Y\r"
        exp_continue
    }
    -re {edit the options} {
        send "N\r"
        exp_continue
    }
    -re {enable nfqws} {
        send "N\r"
        exp_continue
    }
    -re {LAN interface} {
        send "$IFACE_NUM\r"
        exp_continue
    }
    -re {WAN interface} {
        send "$IFACE_NUM\r"
        exp_continue
    }
    -re {auto download} {
        send "Y\r"
        exp_continue
    }
    -re {get_antizapret} {
        send "2\r"
        exp_continue
    }
    -re {get_refilter} {
        send "1\r"
        exp_continue
    }
    -re {get_reestr} {
        send "3\r"
        exp_continue
    }
    -re {press enter to continue} {
        send "\r"
    }
    -re {starting zapret service} {
        # Финал — сервис стартовал
    }
    timeout {
        puts "\nWARNING: expect timed out"
    }
}

expect eof
EXPECT_SCRIPT

    if [ $? -eq 0 ]; then
        ok "Zapret установлен!"
    else
        warn "Установка завершилась с предупреждениями, проверяем статус..."
    fi

    echo ""
    info "Проверка статуса:"
    systemctl status zapret --no-pager || true
    echo ""
    info "Таймер обновления:"
    systemctl status zapret-list-update.timer --no-pager || true
    echo ""
    info "Управление:"
    echo "  Проверка:    sudo systemctl status zapret"
    echo "  Перезапуск:  sudo systemctl restart zapret"
    echo "  Обновление списка: cd /opt/zapret && sudo ./get_antizapret_domains.sh && sudo systemctl restart zapret"
    echo "  Ручное добавление доменов: sudo nano /opt/zapret/ipset/zapret-hosts-user.txt"
}

# ============================================================
# 9. ОПТИМИЗАЦИЯ СЕРВЕРА (без RemnaNode и Zapret)
# ============================================================
optimize_server() {
    info "Оптимизация сервера..."
    disable_ipv6
    install_bbr
    install_keepalive
    install_fail2ban
    install_ipset
    ok "Оптимизация завершена!"
}

# ============================================================
# 1. УСТАНОВИТЬ ВСЁ ВМЕСТЕ
# ============================================================
install_all() {
    info "Установка всего..."
    disable_ipv6
    install_bbr
    install_keepalive
    install_fail2ban
    install_ipset
    install_remnanode
    install_zapret
    echo ""
    ok "=========================================="
    ok " Всё успешно установлено!"
    ok " RemnaNode:  /opt/remnanode/"
    ok " Zapret:    /opt/zapret/"
    ok "=========================================="
}

# ============================================================
# ТОЧКА ВХОДА
# ============================================================
main() {
    check_root
    ask_geo
    show_menu
    pause
}

main
