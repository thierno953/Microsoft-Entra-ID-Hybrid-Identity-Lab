[CmdletBinding()]
param (
    [string]$OutputPath
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes `
    "User.Read.All",
    "UserAuthenticationMethod.Read.All"

$Results = foreach ($User in Get-MgUser -All) {
    try {
        $Methods = Get-MgUserAuthenticationMethod `
            -UserId $User.Id `
            -All

        $MethodTypes = @(
            $Methods.AdditionalProperties."@odata.type"
        )

        [PSCustomObject]@{
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            MFARegistered     = ($MethodTypes.Count -gt 1)
            Methods           = (
                ($MethodTypes -replace "#microsoft.graph.", "") -join ";"
            )
        }
    }
    catch {
        [PSCustomObject]@{
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            MFARegistered     = "Unknown"
            Methods           = $_.Exception.Message
        }
    }
}

if ($OutputPath) {
    $Results | Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8
}

$Results