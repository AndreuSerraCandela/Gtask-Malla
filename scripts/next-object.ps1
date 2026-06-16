param(
    [ValidateSet(
        "page", "table", "tabledata", "codeunit", "report", "query", "enum",
        "xmlport", "dataport", "pageextension", "tableextension", "reportextension",
        "enumextension", "permissionset", "permissionsetextension", "controladdin", "interface"
    )]
    [string]$Type = "page",
    [Parameter(Mandatory = $true)]
    [string]$Extension,
    [string]$Name = "TBD",
    [string]$ReservedBy = "cursor",
    [string]$BaseUrl = "https://objetos.malla.es",
    [switch]$Json
)

$qs = @{
    extension   = $Extension
    name        = $Name
    reserved_by = $ReservedBy
}
if (-not $Json) {
    $qs.format = "plain"
}

$query = ($qs.GetEnumerator() | ForEach-Object {
    "{0}={1}" -f [uri]::EscapeDataString($_.Key), [uri]::EscapeDataString([string]$_.Value)
}) -join "&"

# URL tipo ?page&extension=Malla (tipo como clave de query sin valor)
$uri = "{0}/api/objects/next?{1}&{2}" -f $BaseUrl.TrimEnd("/"), $Type, $query

try {
    $response = Invoke-WebRequest -Uri $uri -Method Get -UseBasicParsing
    if ($Json) {
        $response.Content | Write-Output
    } else {
        $response.Content.Trim() | Write-Output
    }
    exit 0
} catch {
    $body = $_.Exception.Response
    if ($body -and $body.GetResponseStream()) {
        $reader = New-Object System.IO.StreamReader($body.GetResponseStream())
        $reader.ReadToEnd() | Write-Error
    } else {
        Write-Error $_
    }
    exit 1
}
