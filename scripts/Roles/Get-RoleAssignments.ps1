#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [string]$OutputPath,
    [switch]$UseDeviceCode
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
Connect-LabGraph -TenantId $TenantId -Scopes @('RoleManagement.Read.Directory') -UseDeviceCode:$UseDeviceCode

$definitions = @{}
Get-LabGraphCollection -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions' | ForEach-Object {
    $definitions[$_['id']] = $_['displayName']
}
$data = @(Get-LabGraphCollection -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments' | ForEach-Object {
    [pscustomobject]@{
        AssignmentId=$_['id'];PrincipalId=$_['principalId'];RoleDefinitionId=$_['roleDefinitionId']
        RoleName=$definitions[$_['roleDefinitionId']];DirectoryScopeId=$_['directoryScopeId'];AppScopeId=$_['appScopeId']
    }
})
# Current directory assignments only: no PIM eligibility or group-member expansion.
Write-LabReport -Data $data -OutputPath $OutputPath
