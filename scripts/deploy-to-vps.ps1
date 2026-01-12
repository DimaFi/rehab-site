# Автоматическая загрузка и запуск setup-vds.sh на VPS
# Использование: .\deploy-to-vps.ps1

$VPS_IP = "89.111.163.10"
$VPS_USER = "root"
$VPS_PASSWORD = "7T2G#FPVCDJwUMPN"
$SCRIPT_PATH = "scripts\setup-vds.sh"
$DOMAIN = "rehab-center.ru"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Автоматическая установка на VPS" -ForegroundColor Cyan
Write-Host "IP: $VPS_IP" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Проверка существования скрипта
if (-not (Test-Path $SCRIPT_PATH)) {
    Write-Host "Ошибка: Файл $SCRIPT_PATH не найден!" -ForegroundColor Red
    exit 1
}

Write-Host "Шаг 1: Подготовка скрипта..." -ForegroundColor Yellow
$scriptContent = Get-Content -Path $SCRIPT_PATH -Raw -Encoding UTF8
$bytes = [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
$base64 = [System.Convert]::ToBase64String($bytes)
Write-Host "✓ Скрипт подготовлен ($($scriptContent.Length) символов)" -ForegroundColor Green
Write-Host ""

Write-Host "Шаг 2: Загрузка скрипта на сервер..." -ForegroundColor Yellow

# Создаем команду для загрузки и запуска
$uploadCommand = @"
echo '$base64' | base64 -d > /root/setup-vds.sh && chmod +x /root/setup-vds.sh && echo 'Script uploaded successfully'
"@

# Пытаемся использовать ssh с передачей пароля через expect или plink
# Для Windows лучше использовать plink (PuTTY) если доступен
$plinkPath = "plink.exe"
$sshPath = "ssh.exe"

if (Get-Command $plinkPath -ErrorAction SilentlyContinue) {
    Write-Host "Используется PuTTY plink" -ForegroundColor Green
    
    # Создаем временный файл с командой
    $tempCmdFile = [System.IO.Path]::GetTempFileName()
    $uploadCommand | Out-File -FilePath $tempCmdFile -Encoding ASCII
    
    # Выполняем команду через plink
    $plinkArgs = "-ssh", "-pw", $VPS_PASSWORD, "${VPS_USER}@${VPS_IP}", "-m", $tempCmdFile
    $result = & $plinkPath $plinkArgs 2>&1
    
    Remove-Item $tempCmdFile -ErrorAction SilentlyContinue
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Скрипт загружен на сервер" -ForegroundColor Green
    } else {
        Write-Host "✗ Ошибка при загрузке: $result" -ForegroundColor Red
        exit 1
    }
} else {
    # Используем стандартный SSH (требует ручного ввода пароля)
    Write-Host "PuTTY plink не найден. Используйте ручной метод:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Загрузите скрипт через scp:" -ForegroundColor Cyan
    Write-Host "   scp $SCRIPT_PATH ${VPS_USER}@${VPS_IP}:/root/" -ForegroundColor White
    Write-Host "   Пароль: $VPS_PASSWORD" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "2. Или выполните на сервере одну команду (скопируйте полностью):" -ForegroundColor Cyan
    Write-Host ""
    
    # Разбиваем base64 на части для удобства копирования
    $chunkSize = 2000
    $chunks = @()
    for ($i = 0; $i -lt $base64.Length; $i += $chunkSize) {
        $chunk = $base64.Substring($i, [Math]::Min($chunkSize, $base64.Length - $i))
        $chunks += $chunk
    }
    
    Write-Host "BASE64_SCRIPT='$base64'" -ForegroundColor White
    Write-Host "echo `$BASE64_SCRIPT | base64 -d > /root/setup-vds.sh && chmod +x /root/setup-vds.sh" -ForegroundColor White
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Шаг 3: Запуск скрипта настройки..." -ForegroundColor Yellow
Write-Host "Это может занять 5-10 минут..." -ForegroundColor Cyan
Write-Host ""

# Запускаем скрипт в фоновом режиме
$runCommand = "cd /root && nohup bash setup-vds.sh $DOMAIN > /root/setup.log 2>&1 & echo 'Setup script started. PID: $!'"

if (Get-Command $plinkPath -ErrorAction SilentlyContinue) {
    $tempRunFile = [System.IO.Path]::GetTempFileName()
    $runCommand | Out-File -FilePath $tempRunFile -Encoding ASCII
    
    $runArgs = "-ssh", "-pw", $VPS_PASSWORD, "${VPS_USER}@${VPS_IP}", "-m", $tempRunFile
    $runResult = & $plinkPath $runArgs 2>&1
    
    Remove-Item $tempRunFile -ErrorAction SilentlyContinue
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Скрипт настройки запущен!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Мониторинг выполнения:" -ForegroundColor Yellow
        Write-Host "  ssh ${VPS_USER}@${VPS_IP} 'tail -f /root/setup.log'" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Проверка статуса:" -ForegroundColor Yellow
        Write-Host "  ssh ${VPS_USER}@${VPS_IP} 'ps aux | grep setup-vds'" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Ошибка при запуске: $runResult" -ForegroundColor Red
    }
} else {
    Write-Host "Для автоматического запуска установите PuTTY (plink.exe)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Или выполните вручную на сервере:" -ForegroundColor Cyan
    Write-Host "  ssh ${VPS_USER}@${VPS_IP}" -ForegroundColor White
    Write-Host "  sudo bash /root/setup-vds.sh $DOMAIN" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Готово!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
