#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
Connect-LabGraph -TenantId $TenantId -Scopes @('Device.Read.All') -UseDeviceCode:$UseDeviceCode

$uri = 'https://graph.microsoft.com/v1.0/devices?$filter=trustType%20eq%20%27ServerAd%27&$select=id,deviceId,displayName,trustType,accountEnabled,operatingSystem,operatingSystemVersion,onPremisesSyncEnabled,approximateLastSignInDateTime'
$data = @(Get-LabGraphCollection -Uri $uri | ForEach-Object { [pscustomobject]$_ })
# ServerAd identifies hybrid device records; this does not validate a user's PRT.
Write-LabReport -Data $data -OutputPath $OutputPath
