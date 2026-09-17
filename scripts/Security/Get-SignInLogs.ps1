[CmdletBinding()]
param (
    [ValidateRange(1, 30)]
    [int]$Days = 7,

    [string]$OutputPath
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes "AuditLog.Read.All"

$StartDate = (Get-Date).ToUniversalTime().AddDays(-$Days)
$FilterDate = $StartDate.ToString("yyyy-MM-ddTHH:mm:ssZ")

$Results = Get-MgAuditLogSignIn `
    -Filter "createdDateTime ge $FilterDate" `
    -All |
    Select-Object `
        CreatedDateTime,
        UserDisplayName,
        UserPrincipalName,
        AppDisplayName,
        IpAddress,
        @{
            Name       = "ErrorCode"
            Expression = {
                $_.Status.ErrorCode
            }
        },
        ConditionalAccessStatus

if ($OutputPath) {
    $Results | Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8
}

$Results