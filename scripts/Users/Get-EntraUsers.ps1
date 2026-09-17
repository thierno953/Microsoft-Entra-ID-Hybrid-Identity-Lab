[CmdletBinding()]
param (
    [string]$OutputPath
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes "User.Read.All"

$Results = Get-MgUser `
    -All `
    -Property Id,DisplayName,UserPrincipalName,AccountEnabled,
              UserType,Department,JobTitle,OnPremisesSyncEnabled |
    Select-Object `
        DisplayName,
        UserPrincipalName,
        AccountEnabled,
        UserType,
        Department,
        JobTitle,
        OnPremisesSyncEnabled,
        Id

if ($OutputPath) {
    $Results | Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8
}

$Results