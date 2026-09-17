[CmdletBinding()]
param (
    [string]$OutputPath
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes `
    "RoleManagement.Read.Directory",
    "Directory.Read.All"

$RoleDefinitions = @{}

Get-MgRoleManagementDirectoryRoleDefinition -All |
    ForEach-Object {
        $RoleDefinitions[$_.Id] = $_.DisplayName
    }

$Results = Get-MgRoleManagementDirectoryRoleAssignment `
    -All `
    -ExpandProperty Principal |
    Select-Object `
        @{
            Name       = "Role"
            Expression = {
                $RoleDefinitions[$_.RoleDefinitionId]
            }
        },
        @{
            Name       = "Principal"
            Expression = {
                $_.Principal.AdditionalProperties.displayName
            }
        },
        PrincipalId,
        DirectoryScopeId

if ($OutputPath) {
    $Results | Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8
}

$Results