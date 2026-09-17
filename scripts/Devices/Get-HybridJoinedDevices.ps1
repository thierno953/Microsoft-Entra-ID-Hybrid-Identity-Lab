[CmdletBinding()]
param (
    [string]$OutputPath
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes "Device.Read.All"

$Results = Get-MgDevice `
    -All `
    -Property DisplayName,DeviceId,OperatingSystem,
              OperatingSystemVersion,TrustType,
              AccountEnabled,ApproximateLastSignInDateTime |
    Where-Object {
        $_.TrustType -eq "ServerAd"
    } |
    Select-Object `
        DisplayName,
        DeviceId,
        OperatingSystem,
        OperatingSystemVersion,
        AccountEnabled,
        ApproximateLastSignInDateTime

if ($OutputPath) {
    $Results | Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8
}

$Results