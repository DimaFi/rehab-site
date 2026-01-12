# Автоматическая установка скрипта на VPS
# Использование: .\auto-setup-vps.ps1

$VPS_IP = "89.111.163.10"
$VPS_USER = "root"
$VPS_PASSWORD = "7T2G#FPVCDJwUMPN"
$SCRIPT_PATH = "scripts\setup-vds.sh"
$DOMAIN = "rehab-center.ru"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Автоматическая установка на VPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Проверка существования скрипта
if (-not (Test-Path $SCRIPT_PATH)) {
    Write-Host "Ошибка: Файл $SCRIPT_PATH не найден!" -ForegroundColor Red
    Write-Host "Убедитесь, что вы запускаете скрипт из директории rehab-site" -ForegroundColor Yellow
    exit 1
}

Write-Host "Шаг 1: Кодирование скрипта в base64..." -ForegroundColor Yellow
$scriptContent = Get-Content -Path $SCRIPT_PATH -Raw -Encoding UTF8
$bytes = [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
$base64 = [System.Convert]::ToBase64String($bytes)
Write-Host "✓ Скрипт закодирован" -ForegroundColor Green
Write-Host ""

Write-Host "Шаг 2: Создание команды для загрузки на сервер..." -ForegroundColor Yellow

# Создаем команду для выполнения на сервере
$remoteCommand = @"
echo '$base64' | base64 -d > /root/setup-vds.sh && chmod +x /root/setup-vds.sh && echo "Script uploaded and made executable"
"@

Write-Host "✓ Команда подготовлена" -ForegroundColor Green
Write-Host ""

Write-Host "Шаг 3: Подключение к серверу и загрузка скрипта..." -ForegroundColor Yellow
Write-Host "IP: $VPS_IP" -ForegroundColor Cyan
Write-Host "Пользователь: $VPS_USER" -ForegroundColor Cyan
Write-Host ""

# Проверяем, установлен ли модуль Posh-SSH
$poshSSHAvailable = $false
try {
    Import-Module Posh-SSH -ErrorAction Stop
    $poshSSHAvailable = $true
    Write-Host "Используется модуль Posh-SSH" -ForegroundColor Green
} catch {
    Write-Host "Модуль Posh-SSH не установлен, используем стандартный SSH" -ForegroundColor Yellow
    Write-Host "Для автоматической установки выполните: Install-Module -Name Posh-SSH -Scope CurrentUser" -ForegroundColor Yellow
}

if ($poshSSHAvailable) {
    # Используем Posh-SSH для автоматического подключения
    try {
        $securePassword = ConvertTo-SecureString $VPS_PASSWORD -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($VPS_USER, $securePassword)
        
        $session = New-SSHSession -ComputerName $VPS_IP -Credential $credential -AcceptKey
        
        if ($session) {
            Write-Host "✓ Подключение установлено" -ForegroundColor Green
            
            # Загружаем скрипт
            Write-Host "Загрузка скрипта на сервер..." -ForegroundColor Yellow
            $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $remoteCommand
            
            if ($result.ExitStatus -eq 0) {
                Write-Host "✓ Скрипт загружен на сервер" -ForegroundColor Green
                Write-Host ""
                
                Write-Host "Шаг 4: Запуск скрипта настройки..." -ForegroundColor Yellow
                Write-Host "Это может занять 5-10 минут..." -ForegroundColor Cyan
                Write-Host ""
                
                # Запускаем скрипт в фоновом режиме через nohup
                $setupCommand = "cd /root && nohup bash setup-vds.sh $DOMAIN > /root/setup.log 2>&1 &"
                $setupResult = Invoke-SSHCommand -SessionId $session.SessionId -Command $setupCommand
                
                Write-Host "✓ Скрипт запущен в фоновом режиме" -ForegroundColor Green
                Write-Host ""
                Write-Host "Мониторинг выполнения:" -ForegroundColor Yellow
                Write-Host "  tail -f /root/setup.log" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Проверка статуса:" -ForegroundColor Yellow
                Write-Host "  ps aux | grep setup-vds" -ForegroundColor Cyan
                Write-Host ""
                
                Remove-SSHSession -SessionId $session.SessionId | Out-Null
            } else {
                Write-Host "✗ Ошибка при загрузке скрипта" -ForegroundColor Red
                Write-Host $result.Error
            }
        } else {
            Write-Host "✗ Не удалось подключиться к серверу" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Ошибка: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Попробуйте выполнить вручную:" -ForegroundColor Yellow
        Write-Host "  ssh $VPS_USER@$VPS_IP" -ForegroundColor Cyan
    }
} else {
    # Используем стандартный SSH (требует ручного ввода пароля)
    Write-Host "Автоматическая загрузка требует модуль Posh-SSH" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Вариант 1: Установите Posh-SSH и запустите скрипт снова" -ForegroundColor Cyan
    Write-Host "  Install-Module -Name Posh-SSH -Scope CurrentUser" -ForegroundColor White
    Write-Host ""
    Write-Host "Вариант 2: Выполните вручную следующие команды:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Подключитесь к серверу:" -ForegroundColor Yellow
    Write-Host "   ssh $VPS_USER@$VPS_IP" -ForegroundColor White
    Write-Host ""
    Write-Host "2. На сервере выполните:" -ForegroundColor Yellow
    Write-Host "   echo '$($base64.Substring(0, [Math]::Min(100, $base64.Length)))...' | base64 -d > /root/setup-vds.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "Или используйте scp:" -ForegroundColor Yellow
    Write-Host "   scp $SCRIPT_PATH $VPS_USER@${VPS_IP}:/root/" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Затем на сервере:" -ForegroundColor Yellow
    Write-Host "   chmod +x /root/setup-vds.sh" -ForegroundColor White
    Write-Host "   sudo bash /root/setup-vds.sh $DOMAIN" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Готово!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
