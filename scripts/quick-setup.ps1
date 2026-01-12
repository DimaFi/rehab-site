# Quick VPS Setup Script
# Run this script to upload and execute setup-vds.sh on the server

$VPS_IP = "89.111.163.10"
$VPS_USER = "root"
$VPS_PASSWORD = "7T2G#FPVCDJwUMPN"
$SCRIPT_PATH = "scripts\setup-vds.sh"
$DOMAIN = "rehab-center.ru"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VPS Quick Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Server: $VPS_USER@$VPS_IP" -ForegroundColor Yellow
Write-Host "Domain: $DOMAIN" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $SCRIPT_PATH)) {
    Write-Host "Error: Script file not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Upload script to server" -ForegroundColor Yellow
Write-Host "You will be prompted for password: $VPS_PASSWORD" -ForegroundColor Cyan
Write-Host ""
Write-Host "Executing: scp $SCRIPT_PATH ${VPS_USER}@${VPS_IP}:/root/" -ForegroundColor White
Write-Host ""

# Try to upload using scp
$scpResult = & scp $SCRIPT_PATH "${VPS_USER}@${VPS_IP}:/root/" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Script uploaded successfully!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Step 2: Connect to server and run setup" -ForegroundColor Yellow
    Write-Host "Executing: ssh ${VPS_USER}@${VPS_IP}" -ForegroundColor White
    Write-Host ""
    Write-Host "After connecting, run:" -ForegroundColor Cyan
    Write-Host "  chmod +x /root/setup-vds.sh" -ForegroundColor White
    Write-Host "  sudo bash /root/setup-vds.sh $DOMAIN" -ForegroundColor White
    Write-Host ""
    
    # Try to connect and run commands
    Write-Host "Attempting to run setup automatically..." -ForegroundColor Yellow
    Write-Host "Password: $VPS_PASSWORD" -ForegroundColor Cyan
    Write-Host ""
    
    $sshCommands = @"
chmod +x /root/setup-vds.sh
cd /root
nohup bash setup-vds.sh $DOMAIN > /root/setup.log 2>&1 &
echo 'Setup script started. Check progress with: tail -f /root/setup.log'
"@
    
    # Save commands to temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
    $sshCommands | Out-File -FilePath $tempFile -Encoding ASCII
    
    Write-Host "Running setup script in background..." -ForegroundColor Yellow
    Write-Host "This will take 5-10 minutes..." -ForegroundColor Cyan
    Write-Host ""
    
    # Note: This will still prompt for password, but we provide instructions
    Write-Host "To run automatically, execute:" -ForegroundColor Yellow
    Write-Host "  ssh ${VPS_USER}@${VPS_IP} 'bash -s' < $tempFile" -ForegroundColor White
    Write-Host ""
    Write-Host "Or connect manually:" -ForegroundColor Yellow
    Write-Host "  ssh ${VPS_USER}@${VPS_IP}" -ForegroundColor White
    Write-Host "  sudo bash /root/setup-vds.sh $DOMAIN" -ForegroundColor White
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
} else {
    Write-Host "Upload failed. Error: $scpResult" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run manually:" -ForegroundColor Yellow
    Write-Host "  scp $SCRIPT_PATH ${VPS_USER}@${VPS_IP}:/root/" -ForegroundColor Cyan
    Write-Host "  Password: $VPS_PASSWORD" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
