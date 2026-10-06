#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
Connect-LabGraph -TenantId $TenantId -Scopes @('User.Read.All') -UseDeviceCode:$UseDeviceCode

$uri = 'https://graph.microsoft.com/v1.0/users?$select=id,displayName,userPrincipalName,accountEnabled,userType,department,jobTitle,onPremisesSyncEnabled,onPremisesImmutableId'
$data = @(Get-LabGraphCollection -Uri $uri | ForEach-Object { [pscustomobject]$_ })
Write-LabReport -Data $data -OutputPath $OutputPath
