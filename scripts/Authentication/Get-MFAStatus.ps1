#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
Connect-LabGraph -TenantId $TenantId -Scopes @('AuditLog.Read.All') -UseDeviceCode:$UseDeviceCode

# Registration/capability report, NOT proof of enforced MFA.
$data = @(Get-LabGraphCollection -Uri 'https://graph.microsoft.com/v1.0/reports/authenticationMethods/userRegistrationDetails' | ForEach-Object {
    [pscustomobject]@{
        Id = $_['id']; UserPrincipalName = $_['userPrincipalName']; DisplayName = $_['userDisplayName']
        IsMfaRegistered = $_['isMfaRegistered']; IsMfaCapable = $_['isMfaCapable']
        IsPasswordlessCapable = $_['isPasswordlessCapable']
        MethodsRegistered = @($_['methodsRegistered']) -join ';'
    }
})
Write-LabReport -Data $data -OutputPath $OutputPath
