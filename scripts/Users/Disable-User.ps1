#requires -Version 7.2
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$UserId,
    [switch]$RevokeSessions,
    [switch]$UseDeviceCode
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
# Resolve the target using read-only scopes first, including under -WhatIf.
Connect-LabGraph -TenantId $TenantId -Scopes @('User.Read.All') -UseDeviceCode:$UseDeviceCode
$id = [uri]::EscapeDataString($UserId)
$uri = 'https://graph.microsoft.com/v1.0/users/' + $id + '?$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSyncEnabled,onPremisesImmutableId'
$user = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType Hashtable
if ($user['onPremisesSyncEnabled'] -eq $true -or $user['onPremisesImmutableId']) {
    throw 'Synchronized or previously linked identity: review and disable in on-premises AD instead.'
}
$context = Get-MgContext
if ($context.Account -and $user['userPrincipalName'] -eq $context.Account) { throw 'Refusing to disable the signed-in account.' }
if ($PSCmdlet.ShouldProcess($user['userPrincipalName'], "Disable cloud-only account; revoke sessions: $RevokeSessions")) {
    $scopes = @('User.Read.All','User.EnableDisableAccount.All')
    if ($RevokeSessions) { $scopes += 'User.RevokeSessions.All' }
    Connect-LabGraph -TenantId $TenantId -Scopes $scopes -UseDeviceCode:$UseDeviceCode
    Invoke-MgGraphRequest -Method PATCH -Uri ('https://graph.microsoft.com/v1.0/users/' + $user['id']) -Body '{"accountEnabled":false}' -ContentType 'application/json' | Out-Null
    if ($RevokeSessions) {
        try {
            $result = Invoke-MgGraphRequest -Method POST -Uri ('https://graph.microsoft.com/v1.0/users/' + $user['id'] + '/revokeSignInSessions') -OutputType Hashtable
            if ($result['value'] -ne $true) { throw 'Graph did not confirm session revocation.' }
        } catch { throw "Account disabled, but session revocation failed: $($_.Exception.Message)" }
    }
    $verify = Invoke-MgGraphRequest -Method GET -Uri ('https://graph.microsoft.com/v1.0/users/' + $user['id'] + '?$select=id,userPrincipalName,accountEnabled') -OutputType Hashtable
    if ($verify['accountEnabled'] -ne $false) { throw 'Disable verification failed.' }
    [pscustomobject]@{Id=$verify['id'];UserPrincipalName=$verify['userPrincipalName'];AccountEnabled=$verify['accountEnabled'];SessionRevocationRequested=[bool]$RevokeSessions}
}
