[CmdletBinding(
    SupportsShouldProcess,
    ConfirmImpact = "High"
)]
param (
    [Parameter(Mandatory)]
    [string]$UserId
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes "User.ReadWrite.All"

if ($PSCmdlet.ShouldProcess(
    $UserId,
    "Disable Microsoft Entra user"
)) {
    Update-MgUser `
        -UserId $UserId `
        -AccountEnabled:$false
}