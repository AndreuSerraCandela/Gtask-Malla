param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceFolder
)

$alCache = Join-Path $WorkspaceFolder '.vscode\.alcache'
$radJson = Join-Path $WorkspaceFolder '.vscode\rad.json'

if (Test-Path $alCache) {
    Get-ChildItem $alCache -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Caché AL limpiada: $alCache"
} else {
    New-Item -ItemType Directory -Path $alCache -Force | Out-Null
    Write-Host "Carpeta .alcache creada vacía"
}

@'
{
    "Added": [],
    "Modified": [],
    "Removed": []
}
'@ | Set-Content $radJson -Encoding UTF8

Write-Host "rad.json reseteado"
Write-Host ""
Write-Host "Siguiente paso en Cursor:"
Write-Host "  1. Ctrl+Shift+P -> AL: Download symbols  (configuración 'local' en launch.json)"
Write-Host "  2. Ctrl+Shift+P -> Developer: Reload Window"
