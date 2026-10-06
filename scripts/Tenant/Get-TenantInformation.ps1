#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
Connect-LabGraph -TenantId $TenantId -Scopes @('Organization.Read.All') -UseDeviceCode:$UseDeviceCode

$data = @(Get-LabGraphCollection -Uri 'https://graph.microsoft.com/v1.0/organization')
Write-LabReport -Data $data -OutputPath $OutputPath -Format Json
