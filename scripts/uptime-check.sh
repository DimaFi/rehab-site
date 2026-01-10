#!/bin/bash
# Скрипт проверки доступности сайта
# Используется для мониторинга и может быть запущен через systemd timer или cron
#
# Использование:
#   ./uptime-check.sh [domain] [log_file]
#
# Примеры:
#   ./uptime-check.sh rehab-center.ru
#   ./uptime-check.sh rehab-center.ru /var/log/uptime-check.log

set -e

# Параметры по умолчанию
DOMAIN="${1:-rehab-center.ru}"
LOG_FILE="${2:-/var/log/uptime-check/uptime.log}"
TIMEOUT=10
RETRY_COUNT=3
RETRY_DELAY=2

# Создаем директорию для логов если не существует
LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR"

# Функция логирования
log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    
    # Также выводим в stdout для systemd journal
    echo "[${level}] ${message}"
}

# Функция проверки HTTP доступности
check_http() {
    local url=$1
    local http_code
    
    # Пробуем получить HTTP код ответа
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time ${TIMEOUT} \
        --connect-timeout 5 \
        --retry ${RETRY_COUNT} \
        --retry-delay ${RETRY_DELAY} \
        --location \
        "${url}" 2>/dev/null || echo "000")
    
    echo "$http_code"
}

# Функция проверки HTTPS
check_https() {
    check_http "https://${DOMAIN}"
}

# Функция проверки HTTP (fallback)
check_http_fallback() {
    check_http "http://${DOMAIN}"
}

# Основная функция проверки
main() {
    local https_code
    local http_code
    local status="OK"
    local exit_code=0
    
    log_message "INFO" "Проверка доступности сайта: ${DOMAIN}"
    
    # Проверяем HTTPS
    https_code=$(check_https)
    
    # Проверяем HTTP только если HTTPS не работает
    if [ "$https_code" != "200" ] && [ "$https_code" != "301" ] && [ "$https_code" != "302" ]; then
        log_message "WARN" "HTTPS недоступен (код: ${https_code}), проверяю HTTP..."
        http_code=$(check_http_fallback)
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            log_message "WARN" "HTTP доступен (код: ${http_code}), но HTTPS не работает"
            status="WARNING"
            exit_code=1
        else
            log_message "ERROR" "Сайт недоступен! HTTPS: ${https_code}, HTTP: ${http_code}"
            status="ERROR"
            exit_code=2
        fi
    else
        log_message "INFO" "Сайт доступен через HTTPS (код: ${https_code})"
        status="OK"
        exit_code=0
    fi
    
    # Дополнительная проверка времени отклика
    response_time=$(curl -s -o /dev/null -w "%{time_total}" \
        --max-time ${TIMEOUT} \
        "https://${DOMAIN}" 2>/dev/null || echo "0")
    
    if [ "$exit_code" -eq 0 ]; then
        log_message "INFO" "Время отклика: ${response_time}s, Статус: ${status}"
    fi
    
    # Здесь можно добавить отправку уведомлений при ошибках
    # Например, через email, Telegram бот, Slack webhook и т.д.
    if [ "$exit_code" -ne 0 ]; then
        # Пример отправки через mail (если настроен postfix)
        # echo "Сайт ${DOMAIN} недоступен! Код ответа: ${https_code}" | mail -s "Алерт: сайт недоступен" admin@example.com
        
        # Пример отправки через Telegram (требует настройки)
        # TELEGRAM_BOT_TOKEN="your_bot_token"
        # TELEGRAM_CHAT_ID="your_chat_id"
        # MESSAGE="⚠️ Алерт: сайт ${DOMAIN} недоступен! Код ответа: ${https_code}"
        # curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        #     -d chat_id=${TELEGRAM_CHAT_ID} \
        #     -d text="${MESSAGE}" > /dev/null 2>&1 || true
        
        log_message "ERROR" "Требуется внимание администратора!"
    fi
    
    exit $exit_code
}

# Запуск
main "$@"

