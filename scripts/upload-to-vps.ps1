# PowerShell скрипт для загрузки setup-vds.sh на VPS
# Использование: .\upload-to-vps.ps1

$VPS_IP = "89.111.163.10"
$VPS_USER = "root"
$SCRIPT_PATH = "scripts\setup-vds.sh"
$REMOTE_PATH = "/root/setup-vds.sh"

Write-Host "Загрузка setup-vds.sh на сервер $VPS_IP..." -ForegroundColor Green

# Проверка существования файла
if (-not (Test-Path $SCRIPT_PATH)) {
    Write-Host "Ошибка: Файл $SCRIPT_PATH не найден!" -ForegroundColor Red
    Write-Host "Убедитесь, что вы запускаете скрипт из директории rehab-site" -ForegroundColor Yellow
    exit 1
}

# Загрузка файла на сервер
try {
    scp $SCRIPT_PATH "${VPS_USER}@${VPS_IP}:${REMOTE_PATH}"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Скрипт успешно загружен на сервер" -ForegroundColor Green
        Write-Host ""
        Write-Host "Следующие шаги:" -ForegroundColor Yellow
        Write-Host "1. Подключитесь к серверу:" -ForegroundColor Cyan
        Write-Host "   ssh ${VPS_USER}@${VPS_IP}" -ForegroundColor White
        Write-Host ""
        Write-Host "2. Сделайте скрипт исполняемым:" -ForegroundColor Cyan
        Write-Host "   chmod +x ${REMOTE_PATH}" -ForegroundColor White
        Write-Host ""
        Write-Host "3. Запустите скрипт:" -ForegroundColor Cyan
        Write-Host "   sudo bash ${REMOTE_PATH} rehab-center.ru" -ForegroundColor White
    } else {
        Write-Host "✗ Ошибка при загрузке скрипта" -ForegroundColor Red
        Write-Host "Проверьте подключение к серверу и пароль" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "Ошибка: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Убедитесь, что:" -ForegroundColor Yellow
    Write-Host "- Установлен OpenSSH клиент (обычно встроен в Windows 10/11)" -ForegroundColor White
    Write-Host "- Вы можете подключиться к серверу: ssh ${VPS_USER}@${VPS_IP}" -ForegroundColor White
    exit 1
}
