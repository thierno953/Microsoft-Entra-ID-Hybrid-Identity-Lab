#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode,
    [Parameter(Mandatory)][guid]$GroupId,
    [switch]$Transitive
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
Connect-LabGraph -TenantId $TenantId -Scopes @('GroupMember.Read.All','User.ReadBasic.All') -UseDeviceCode:$UseDeviceCode

$segment = [uri]::EscapeDataString($GroupId.ToString())
$relation = if ($Transitive) { 'transitiveMembers' } else { 'members' }
$uri = "https://graph.microsoft.com/v1.0/groups/$segment/$relation"
$data = @(Get-LabGraphCollection -Uri $uri | ForEach-Object {
    [pscustomobject]@{Id=$_['id'];Type=$_['@odata.type'];DisplayName=$_['displayName'];UserPrincipalName=$_['userPrincipalName']}
})
# Non-user objects can have limited properties with these scopes.
Write-LabReport -Data $data -OutputPath $OutputPath
