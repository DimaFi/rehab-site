# Auto install on VPS
$VPS_IP = "89.111.163.10"
$VPS_USER = "root"
$VPS_PASSWORD = "7T2G#FPVCDJwUMPN"
$SCRIPT_PATH = "scripts\setup-vds.sh"
$DOMAIN = "rehab-center.ru"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto VPS Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SCRIPT_PATH)) {
    Write-Host "Error: Script file not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Installing Posh-SSH module..." -ForegroundColor Yellow
try {
    Import-Module Posh-SSH -ErrorAction Stop
    Write-Host "Module already installed" -ForegroundColor Green
} catch {
    Write-Host "Installing Posh-SSH module..." -ForegroundColor Yellow
    Install-Module -Name Posh-SSH -Scope CurrentUser -Force -AllowClobber
    Import-Module Posh-SSH
    Write-Host "Module installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 2: Connecting to server..." -ForegroundColor Yellow

$securePassword = ConvertTo-SecureString $VPS_PASSWORD -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($VPS_USER, $securePassword)

try {
    $session = New-SSHSession -ComputerName $VPS_IP -Credential $credential -AcceptKey
    
    if ($session) {
        Write-Host "Connected successfully" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "Step 3: Uploading script to server..." -ForegroundColor Yellow
        $scriptContent = Get-Content -Path $SCRIPT_PATH -Raw -Encoding UTF8
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
        $base64 = [System.Convert]::ToBase64String($bytes)
        
        $uploadCmd = "echo '$base64' | base64 -d > /root/setup-vds.sh && chmod +x /root/setup-vds.sh && echo 'OK'"
        $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $uploadCmd
        
        if ($result.ExitStatus -eq 0) {
            Write-Host "Script uploaded successfully" -ForegroundColor Green
            Write-Host ""
            
            Write-Host "Step 4: Running setup script..." -ForegroundColor Yellow
            Write-Host "This will take 5-10 minutes..." -ForegroundColor Cyan
            Write-Host ""
            
            $runCmd = "cd /root && nohup bash setup-vds.sh $DOMAIN > /root/setup.log 2>&1 & echo 'Started'"
            $runResult = Invoke-SSHCommand -SessionId $session.SessionId -Command $runCmd
            
            if ($runResult.ExitStatus -eq 0) {
                Write-Host "Setup script started!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Monitor progress:" -ForegroundColor Yellow
                Write-Host "  ssh $VPS_USER@$VPS_IP 'tail -f /root/setup.log'" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Check status:" -ForegroundColor Yellow
                Write-Host "  ssh $VPS_USER@$VPS_IP 'ps aux | grep setup-vds'" -ForegroundColor Cyan
            } else {
                Write-Host "Error starting script: $($runResult.Error)" -ForegroundColor Red
            }
        } else {
            Write-Host "Error uploading: $($result.Error)" -ForegroundColor Red
        }
        
        Remove-SSHSession -SessionId $session.SessionId | Out-Null
    } else {
        Write-Host "Failed to connect" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try manual method:" -ForegroundColor Yellow
    Write-Host "  scp $SCRIPT_PATH ${VPS_USER}@${VPS_IP}:/root/" -ForegroundColor Cyan
    Write-Host "  ssh ${VPS_USER}@${VPS_IP}" -ForegroundColor Cyan
    Write-Host "  sudo bash /root/setup-vds.sh $DOMAIN" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
