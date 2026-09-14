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

Write-Host "==> Synchronizing backend dependencies..."
docker compose exec -T backend npm ci

Write-Host "==> Synchronizing frontend dependencies..."
docker compose exec -T frontend npm ci

Write-Host "==> Waiting for services..."

$maxAttempts = 30

for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    $servicesJson = docker compose ps --format json
    $servicesText = $servicesJson -join "`n"

    if ($servicesText -match '"Health":"unhealthy"') {
        Write-Host "One or more services are unhealthy."
        docker compose ps
        exit 1
    }

    if ($servicesText -notmatch '"Health":"starting"') {
        break
    }

    if ($attempt -eq $maxAttempts) {
        Write-Host "Timed out waiting for services."
        docker compose ps
        exit 1
    }

    Start-Sleep -Seconds 2
}

Write-Host "==> Applying database migrations..."
docker compose exec -T backend npx prisma migrate deploy

Write-Host "==> Generating Prisma Client..."
docker compose exec -T backend npx prisma generate

Write-Host "==> Current services:"
docker compose ps

Write-Host ""
Write-Host "SocialX development environment is ready."
Write-Host "Frontend: http://localhost:3000"
Write-Host "Backend:  http://localhost:3001"