param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceFolder,
    [switch]$CopyOnly
)

$destFolder = 'C:\apps\Malla'
$appJsonPath = Join-Path $WorkspaceFolder 'app.json'
$appJson = Get-Content $appJsonPath -Raw | ConvertFrom-Json
$appFileName = "$($appJson.publisher)_$($appJson.name)_$($appJson.version).app"
$sourcePath = Join-Path $WorkspaceFolder $appFileName
$packageCache = Join-Path $WorkspaceFolder '.alpackages'

if (-not $CopyOnly) {
    $alcExe = $env:ALC_PATH
    if ([string]::IsNullOrWhiteSpace($alcExe) -or -not (Test-Path $alcExe)) {
        $extensionRoots = @(
            (Join-Path $env:USERPROFILE '.cursor\extensions'),
            (Join-Path $env:USERPROFILE '.vscode\extensions')
        )
        foreach ($root in $extensionRoots) {
            if (-not (Test-Path $root)) { continue }
            $found = Get-ChildItem -Path $root -Filter 'ms-dynamics-smb.al-*' -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { Join-Path $_.FullName 'bin\win32\alc.exe' } |
                Where-Object { Test-Path $_ } |
                Select-Object -First 1
            if ($found) {
                $alcExe = $found
                break
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($alcExe) -or -not (Test-Path $alcExe)) {
        Write-Error 'No se encontró alc.exe. Compila con Ctrl+Shift+B (AL: Package) y ejecuta la tarea "Copiar .app a Malla", o define la variable de entorno ALC_PATH.'
        exit 1
    }

    Write-Host "Compilando con: $alcExe"
    $assemblyPaths = @(
        (Join-Path $WorkspaceFolder '.netpackages'),
        'C:\Windows\assembly',
        'C:\net'
    ) | Where-Object { Test-Path $_ }
    $assemblyArg = ($assemblyPaths | ForEach-Object { $_ }) -join ';'
    if ($assemblyArg) {
        & $alcExe /project:$WorkspaceFolder /packagecachepath:$packageCache /assemblyprobingpaths:$assemblyArg
    } else {
        & $alcExe /project:$WorkspaceFolder /packagecachepath:$packageCache
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "La compilación falló (código $LASTEXITCODE)."
        exit $LASTEXITCODE
    }
}

if (-not (Test-Path $sourcePath)) {
    Write-Error "No se encontró $appFileName en $WorkspaceFolder. Revisa app.json o compila antes de copiar."
    exit 1
}

if (-not (Test-Path $destFolder)) {
    New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
}

Copy-Item -Path $sourcePath -Destination $destFolder -Force
Write-Host "Copiado: $appFileName -> $destFolder"
