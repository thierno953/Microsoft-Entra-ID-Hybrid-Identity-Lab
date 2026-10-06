#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode,
    [datetimeoffset]$Since = ([datetimeoffset]::UtcNow.AddDays(-1)),
    [datetimeoffset]$Until = ([datetimeoffset]::UtcNow),
    [switch]$FailuresOnly
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
Connect-LabGraph -TenantId $TenantId -Scopes @('AuditLog.Read.All','Policy.Read.All') -UseDeviceCode:$UseDeviceCode

$start = $Since.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$end = $Until.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
if ($Since -ge $Until) { throw 'Since must be earlier than Until.' }
$filter = "createdDateTime ge $start and createdDateTime lt $end"
if ($FailuresOnly) { $filter += ' and status/errorCode ne 0' }
$uri = 'https://graph.microsoft.com/v1.0/auditLogs/signIns?$filter=' + [uri]::EscapeDataString($filter)
# Raw JSON preserves authentication details and applied CA policy results.
$data = @(Get-LabGraphCollection -Uri $uri)
Write-LabReport -Data $data -OutputPath $OutputPath -Format Json
