#!/bin/bash
# Скрипт для быстрой загрузки setup-vds.sh на VPS сервер
# Использование: ./upload-setup.sh <IP-адрес-VPS>

set -e

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Проверка аргументов
if [ -z "$1" ]; then
    echo -e "${RED}Ошибка: Укажите IP-адрес VPS${NC}"
    echo "Использование: ./upload-setup.sh <IP-адрес-VPS>"
    echo "Пример: ./upload-setup.sh 123.45.67.89"
    exit 1
fi

VPS_IP="$1"
SCRIPT_PATH="$(dirname "$0")/setup-vds.sh"

# Проверка существования скрипта
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}Ошибка: Файл $SCRIPT_PATH не найден${NC}"
    exit 1
fi

echo -e "${GREEN}Загрузка setup-vds.sh на сервер $VPS_IP...${NC}"

# Загрузка скрипта на сервер
scp "$SCRIPT_PATH" root@$VPS_IP:/root/setup-vds.sh

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Скрипт успешно загружен${NC}"
    echo ""
    echo -e "${YELLOW}Следующие шаги:${NC}"
    echo "1. Подключитесь к серверу:"
    echo "   ssh root@$VPS_IP"
    echo ""
    echo "2. Запустите скрипт:"
    echo "   chmod +x /root/setup-vds.sh"
    echo "   sudo bash /root/setup-vds.sh rehab-center.ru"
else
    echo -e "${RED}✗ Ошибка при загрузке скрипта${NC}"
    exit 1
fi
