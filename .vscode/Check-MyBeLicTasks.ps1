param([int]$Limit = 8)
$envFile = Join-Path (Split-Path $PSScriptRoot -Parent) 'mybelic.local.env'
if (-not (Test-Path $envFile)) {
    Write-Host 'mybelic.local.env no encontrado'
    exit 1
}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z0-9_]+)=(.*)$') {
        Set-Item -Path ("Env:$($matches[1])") -Value $matches[2]
    }
}
if (-not $env:MYBELIC_API_TOKEN) {
    Write-Host 'Falta MYBELIC_API_TOKEN'
    exit 1
}
$base = $env:MYBELIC_API_URL.TrimEnd('/')
$cid = $env:MYBELIC_PYTHON_DEPLOY_CUSTOMER_ID
$uri = "$base/api/v1/admin/customers/$cid/tasks?limit=$Limit"
$r = Invoke-RestMethod -Uri $uri -Headers @{ 'X-MyBeLic-Token' = $env:MYBELIC_API_TOKEN } -TimeoutSec 45
$tasks = @($r.tasks) + @($r.items)
$tasks = $tasks | Where-Object { $_ } | Select-Object -First $Limit
if ($tasks.Count -gt 0) {
    $tasks | Select-Object id, action, status, app_name, version, run_at, created_at, finished_at | Format-Table -AutoSize
} else {
    $r | ConvertTo-Json -Depth 2
}
