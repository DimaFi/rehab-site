# Простой скрипт для загрузки и запуска setup-vds.sh на сервере
# Использование: .\run-setup-on-server.ps1

$VPS_IP = "89.111.163.10"
$VPS_USER = "root"
$VPS_PASSWORD = "7T2G#FPVCDJwUMPN"
$SCRIPT_PATH = "scripts\setup-vds.sh"
$DOMAIN = "rehab-center.ru"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Загрузка и запуск скрипта на VPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Проверка существования скрипта
if (-not (Test-Path $SCRIPT_PATH)) {
    Write-Host "Ошибка: Файл $SCRIPT_PATH не найден!" -ForegroundColor Red
    exit 1
}

Write-Host "Вариант 1: Использовать scp (требует ввода пароля вручную)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Выполните в PowerShell:" -ForegroundColor Cyan
Write-Host "  scp $SCRIPT_PATH ${VPS_USER}@${VPS_IP}:/root/" -ForegroundColor White
Write-Host ""
Write-Host "Пароль: $VPS_PASSWORD" -ForegroundColor Yellow
Write-Host ""
Write-Host "Затем подключитесь к серверу:" -ForegroundColor Cyan
Write-Host "  ssh ${VPS_USER}@${VPS_IP}" -ForegroundColor White
Write-Host ""
Write-Host "И выполните:" -ForegroundColor Cyan
Write-Host "  chmod +x /root/setup-vds.sh" -ForegroundColor White
Write-Host "  sudo bash /root/setup-vds.sh $DOMAIN" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Или используйте автоматический вариант:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Читаем содержимое скрипта
$scriptContent = Get-Content -Path $SCRIPT_PATH -Raw -Encoding UTF8

# Экранируем специальные символы для передачи через SSH
$escapedContent = $scriptContent -replace '"', '\"' -replace '\$', '\$' -replace '`', '\`'

# Создаем команду для выполнения на сервере
$remoteCommand = @"
cat > /root/setup-vds.sh <<'SCRIPTEOF'
$scriptContent
SCRIPTEOF
chmod +x /root/setup-vds.sh
echo "Script uploaded successfully"
"@

Write-Host "Команда для выполнения на сервере (скопируйте и вставьте после подключения):" -ForegroundColor Yellow
Write-Host ""
Write-Host $remoteCommand -ForegroundColor White
Write-Host ""

# Пытаемся использовать sshpass если доступен, или создаем инструкцию
Write-Host "Для автоматического выполнения установите sshpass или используйте ручной метод выше" -ForegroundColor Yellow
