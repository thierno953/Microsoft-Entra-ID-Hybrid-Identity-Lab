[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$GroupId,

    [string]$OutputPath
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes "GroupMember.Read.All"

$Results = Get-MgGroupMemberAsUser `
    -GroupId $GroupId `
    -All `
    -Property Id,DisplayName,UserPrincipalName |
    Select-Object `
        Id,
        DisplayName,
        UserPrincipalName

if ($OutputPath) {
    $Results | Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8
}

$Results