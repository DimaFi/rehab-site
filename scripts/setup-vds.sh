#!/bin/bash
# Скрипт автоматической настройки VDS для Hugo сайта
# Требует запуск от root пользователя
# Использование: sudo bash setup-vds.sh

set -e  # Остановка при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Конфигурация
DOMAIN_NAME="${1:-rehab-center.ru}"
DEPLOY_USER="deploy"
DEPLOY_PATH="/var/www/rehab-center"
SITE_USER="www-data"
SITE_GROUP="www-data"
NGINX_CONFIG="/etc/nginx/sites-available/rehab-center"
NGINX_ENABLED="/etc/nginx/sites-enabled/rehab-center"
LOG_DIR="/var/log/uptime-check"

# Функция логирования
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "Пожалуйста, запустите скрипт с правами root (sudo)"
        exit 1
    fi
    log_info "Проверка прав root: OK"
}

# Обновление системы
update_system() {
    log_info "Обновление списка пакетов..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get upgrade -y
    log_info "Система обновлена"
}

# Установка базовых пакетов
install_base_packages() {
    log_info "Установка базовых пакетов..."
    apt-get install -y \
        curl \
        wget \
        git \
        ufw \
        fail2ban \
        unattended-upgrades \
        apt-listchanges \
        htop \
        nano \
        rsync \
        openssh-server
    log_info "Базовые пакеты установлены"
}

# Настройка часового пояса
setup_timezone() {
    log_info "Настройка часового пояса (Europe/Moscow)..."
    timedatectl set-timezone Europe/Moscow
    log_info "Часовой пояс установлен: $(timedatectl | grep 'Time zone')"
}

# Создание пользователя для деплоя
create_deploy_user() {
    log_info "Создание пользователя ${DEPLOY_USER}..."
    
    if id "$DEPLOY_USER" &>/dev/null; then
        log_warn "Пользователь ${DEPLOY_USER} уже существует"
    else
        useradd -m -s /bin/bash ${DEPLOY_USER}
        usermod -aG sudo ${DEPLOY_USER}
        log_info "Пользователь ${DEPLOY_USER} создан"
    fi
    
    # Создание директории для SSH ключей
    mkdir -p /home/${DEPLOY_USER}/.ssh
    chmod 700 /home/${DEPLOY_USER}/.ssh
    chown ${DEPLOY_USER}:${DEPLOY_USER} /home/${DEPLOY_USER}/.ssh
}

# Установка Nginx
install_nginx() {
    log_info "Установка Nginx..."
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    log_info "Nginx установлен и запущен"
}

# Установка Certbot для SSL
install_certbot() {
    log_info "Установка Certbot..."
    apt-get install -y certbot python3-certbot-nginx
    log_info "Certbot установлен"
}

# Настройка файрвола UFW
setup_firewall() {
    log_info "Настройка файрвола UFW..."
    
    # Разрешить SSH (важно сделать первым!)
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    
    # Включить файрвол (требует подтверждения, но мы делаем неинтерактивно)
    echo "y" | ufw enable || true
    ufw --force enable
    
    log_info "Файрвол настроен. Открыты порты: 22 (SSH), 80 (HTTP), 443 (HTTPS)"
}

# Создание структуры директорий
create_directories() {
    log_info "Создание структуры директорий..."
    
    # Основная директория сайта
    mkdir -p ${DEPLOY_PATH}
    chown -R ${DEPLOY_USER}:${SITE_GROUP} ${DEPLOY_PATH}
    chmod -R 755 ${DEPLOY_PATH}
    
    # Директория для логов мониторинга
    mkdir -p ${LOG_DIR}
    chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${LOG_DIR}
    chmod -R 755 ${LOG_DIR}
    
    # Директория для временных файлов деплоя
    mkdir -p /tmp/deploy
    chown -R ${DEPLOY_USER}:${DEPLOY_USER} /tmp/deploy
    
    log_info "Директории созданы: ${DEPLOY_PATH}, ${LOG_DIR}"
}

# Генерация SSH ключей для деплоя
generate_ssh_keys() {
    log_info "Генерация SSH ключей для пользователя ${DEPLOY_USER}..."
    
    SSH_KEY_PATH="/home/${DEPLOY_USER}/.ssh/id_rsa"
    SSH_PUB_KEY_PATH="${SSH_KEY_PATH}.pub"
    
    if [ -f "$SSH_KEY_PATH" ]; then
        log_warn "SSH ключ уже существует. Пропускаем генерацию."
    else
        sudo -u ${DEPLOY_USER} ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "deploy-key-${DOMAIN_NAME}"
        log_info "SSH ключи сгенерированы: ${SSH_KEY_PATH}"
    fi
    
    # Добавление публичного ключа в authorized_keys для локального доступа
    if [ -f "$SSH_PUB_KEY_PATH" ]; then
        cat "$SSH_PUB_KEY_PATH" >> /home/${DEPLOY_USER}/.ssh/authorized_keys
        chmod 600 /home/${DEPLOY_USER}/.ssh/authorized_keys
        chown ${DEPLOY_USER}:${DEPLOY_USER} /home/${DEPLOY_USER}/.ssh/authorized_keys
    fi
    
    log_info "Публичный SSH ключ для GitHub Actions:"
    echo "----------------------------------------"
    cat "$SSH_PUB_KEY_PATH" 2>/dev/null || log_warn "Не удалось прочитать публичный ключ"
    echo "----------------------------------------"
    log_warn "ВАЖНО: Сохраните приватный ключ (${SSH_KEY_PATH}) для добавления в GitHub Secrets!"
}

# Настройка Nginx конфигурации
setup_nginx_config() {
    log_info "Настройка Nginx конфигурации..."
    
    # Удаляем дефолтный конфиг если есть
    if [ -L /etc/nginx/sites-enabled/default ]; then
        rm /etc/nginx/sites-enabled/default
        log_info "Удален дефолтный конфиг Nginx"
    fi
    
    # Создаем конфиг для сайта
    cat > ${NGINX_CONFIG} <<EOF
# Редирект HTTP -> HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN_NAME} www.${DOMAIN_NAME};
    
    # Для Let's Encrypt валидации
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS конфигурация
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN_NAME} www.${DOMAIN_NAME};
    
    root ${DEPLOY_PATH};
    index index.html index.htm;
    
    # SSL сертификаты (будут установлены certbot)
    # ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;
    # include /etc/letsencrypt/options-ssl-nginx.conf;
    # ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Логи
    access_log /var/log/nginx/${DOMAIN_NAME}-access.log;
    error_log /var/log/nginx/${DOMAIN_NAME}-error.log;
    
    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
    
    # Основная локация
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Кеширование статических файлов
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Запрет доступа к скрытым файлам
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

    # Создаем символическую ссылку
    ln -sf ${NGINX_CONFIG} ${NGINX_ENABLED}
    
    # Проверка конфигурации
    if nginx -t; then
        log_info "Конфигурация Nginx валидна"
        systemctl reload nginx
    else
        log_error "Ошибка в конфигурации Nginx!"
        exit 1
    fi
}

# Установка SSL сертификата
setup_ssl() {
    log_info "Настройка SSL сертификата для ${DOMAIN_NAME}..."
    log_warn "Убедитесь, что домен ${DOMAIN_NAME} указывает на IP этого сервера!"
    
    read -p "Введите email для Let's Encrypt (или нажмите Enter для пропуска): " EMAIL
    
    if [ -z "$EMAIL" ]; then
        log_warn "Установка SSL пропущена. Вы можете установить его позже командой:"
        log_warn "certbot --nginx -d ${DOMAIN_NAME} -d www.${DOMAIN_NAME}"
        return
    fi
    
    # Временно отключаем HTTPS редирект для получения сертификата
    # Certbot сам настроит SSL после получения сертификата
    certbot --nginx -d ${DOMAIN_NAME} -d www.${DOMAIN_NAME} \
        --non-interactive \
        --agree-tos \
        --email ${EMAIL} \
        --redirect || {
        log_error "Не удалось установить SSL сертификат. Проверьте, что домен указывает на этот сервер."
        log_warn "Вы можете установить SSL позже командой: certbot --nginx -d ${DOMAIN_NAME}"
        return
    }
    
    # Настройка автоматического обновления сертификатов
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    log_info "SSL сертификат установлен и настроено автоматическое обновление"
}

# Настройка logrotate
setup_logrotate() {
    log_info "Настройка logrotate для логов мониторинга..."
    
    cat > /etc/logrotate.d/uptime-check <<EOF
${LOG_DIR}/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 ${DEPLOY_USER} ${DEPLOY_USER}
}
EOF

    log_info "Logrotate настроен для ${LOG_DIR}"
}

# Создание systemd сервиса для мониторинга
setup_monitoring_service() {
    log_info "Создание systemd сервиса для мониторинга..."
    
    # Создаем скрипт мониторинга (если его еще нет)
    MONITOR_SCRIPT="/usr/local/bin/uptime-check.sh"
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        cat > ${MONITOR_SCRIPT} <<'SCRIPTEOF'
#!/bin/bash
DOMAIN="${1:-rehab-center.ru}"
LOG_FILE="/var/log/uptime-check/uptime.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Проверка доступности сайта
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${DOMAIN}" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "[${TIMESTAMP}] OK - HTTP ${HTTP_CODE}" >> ${LOG_FILE}
    exit 0
else
    echo "[${TIMESTAMP}] ERROR - HTTP ${HTTP_CODE}" >> ${LOG_FILE}
    # Здесь можно добавить отправку уведомлений (email, telegram и т.д.)
    exit 1
fi
SCRIPTEOF
        chmod +x ${MONITOR_SCRIPT}
    fi
    
    # Создаем systemd service
    cat > /etc/systemd/system/uptime-check.service <<EOF
[Unit]
Description=Uptime Check Service
After=network.target

[Service]
Type=oneshot
User=${DEPLOY_USER}
ExecStart=${MONITOR_SCRIPT} ${DOMAIN_NAME}
StandardOutput=journal
StandardError=journal
EOF

    # Создаем systemd timer
    cat > /etc/systemd/system/uptime-check.timer <<EOF
[Unit]
Description=Run uptime check every 5 minutes
Requires=uptime-check.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Unit=uptime-check.service

[Install]
WantedBy=timers.target
EOF

    # Перезагружаем systemd и запускаем таймер
    systemctl daemon-reload
    systemctl enable uptime-check.timer
    systemctl start uptime-check.timer
    
    log_info "Сервис мониторинга создан и запущен (проверка каждые 5 минут)"
}

# Настройка прав для деплоя
setup_deploy_permissions() {
    log_info "Настройка прав для пользователя ${DEPLOY_USER}..."
    
    # Разрешаем deploy пользователю писать в директорию сайта
    chown -R ${DEPLOY_USER}:${SITE_GROUP} ${DEPLOY_PATH}
    chmod -R 775 ${DEPLOY_PATH}
    
    # Добавляем пользователя в группу www-data для доступа к файлам
    usermod -aG ${SITE_GROUP} ${DEPLOY_USER}
    
    log_info "Права настроены"
}

# Финальная информация
print_summary() {
    log_info "=========================================="
    log_info "Настройка VDS завершена!"
    log_info "=========================================="
    echo ""
    log_info "Домен: ${DOMAIN_NAME}"
    log_info "Пользователь для деплоя: ${DEPLOY_USER}"
    log_info "Путь сайта: ${DEPLOY_PATH}"
    echo ""
    log_info "Следующие шаги:"
    echo "1. Сохраните приватный SSH ключ из /home/${DEPLOY_USER}/.ssh/id_rsa"
    echo "2. Добавьте его в GitHub Secrets как SSH_PRIVATE_KEY"
    echo "3. Если SSL не был установлен, выполните: certbot --nginx -d ${DOMAIN_NAME}"
    echo "4. Проверьте логи мониторинга: tail -f ${LOG_DIR}/uptime.log"
    echo "5. Проверьте статус мониторинга: systemctl status uptime-check.timer"
    echo ""
    log_info "Публичный SSH ключ для добавления в authorized_keys на других серверах:"
    cat /home/${DEPLOY_USER}/.ssh/id_rsa.pub 2>/dev/null || echo "Не найден"
    echo ""
}

# Главная функция
main() {
    log_info "Начало настройки VDS для Hugo сайта"
    log_info "Домен: ${DOMAIN_NAME}"
    echo ""
    
    check_root
    update_system
    install_base_packages
    setup_timezone
    create_deploy_user
    install_nginx
    install_certbot
    setup_firewall
    create_directories
    generate_ssh_keys
    setup_nginx_config
    setup_ssl
    setup_logrotate
    setup_monitoring_service
    setup_deploy_permissions
    print_summary
    
    log_info "Все готово! Система настроена и готова к деплою."
}

# Запуск главной функции
main

