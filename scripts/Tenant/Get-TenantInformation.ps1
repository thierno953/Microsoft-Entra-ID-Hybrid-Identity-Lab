[CmdletBinding()]
param ()

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes "Organization.Read.All"

Get-MgOrganization |
    Select-Object `
        Id,
        DisplayName,
        CreatedDateTime,
        OnPremisesSyncEnabled,
        @{
            Name       = "VerifiedDomains"
            Expression = {
                $_.VerifiedDomains.Name -join ";"
            }
        }