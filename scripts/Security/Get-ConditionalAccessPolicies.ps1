#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
Connect-LabGraph -TenantId $TenantId -Scopes @('Policy.Read.All') -UseDeviceCode:$UseDeviceCode

$data = @(Get-LabGraphCollection -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies')
# Configuration export, not a runtime enforcement test.
Write-LabReport -Data $data -OutputPath $OutputPath -Format Json
