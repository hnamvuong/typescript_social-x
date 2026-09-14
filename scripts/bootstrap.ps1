$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

Write-Host "==> Checking Docker..."

docker --version | Out-Null
docker compose version | Out-Null

if (-not (Test-Path ".env")) {
    Write-Host "==> Creating .env from .env.example"
    Copy-Item ".env.example" ".env"
}
else {
    Write-Host "==> .env already exists"
}

Write-Host "==> Building images..."
docker compose build

Write-Host "==> Starting services..."
docker compose up -d

Write-Host "==> Current services:"
docker compose ps

Write-Host ""
Write-Host "SocialX is starting:"
Write-Host "Frontend: http://localhost:3000"
Write-Host "Backend:  http://localhost:3001"