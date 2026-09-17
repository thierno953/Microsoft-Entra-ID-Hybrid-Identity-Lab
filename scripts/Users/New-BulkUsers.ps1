[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [string]$ResultPath = ".\Created-Users.csv"
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes "User.ReadWrite.All"

function New-TemporaryPassword {
    $Upper   = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    $Lower   = "abcdefghijkmnopqrstuvwxyz"
    $Numbers = "23456789"
    $Symbols = "!@#$%*-_"
    $All     = $Upper + $Lower + $Numbers + $Symbols

    $Characters = @(
        $Upper[(Get-Random -Maximum $Upper.Length)]
        $Lower[(Get-Random -Maximum $Lower.Length)]
        $Numbers[(Get-Random -Maximum $Numbers.Length)]
        $Symbols[(Get-Random -Maximum $Symbols.Length)]
    )

    1..12 | ForEach-Object {
        $Characters += $All[(Get-Random -Maximum $All.Length)]
    }

    return -join ($Characters | Sort-Object { Get-Random })
}

$Results = foreach ($User in Import-Csv $CsvPath) {
    try {
        $Password = New-TemporaryPassword

        $Parameters = @{
            AccountEnabled    = $true
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            MailNickname      = $User.MailNickname
            GivenName         = $User.GivenName
            Surname           = $User.Surname

            PasswordProfile = @{
                Password                      = $Password
                ForceChangePasswordNextSignIn = $true
            }
        }

        if ($User.Department) {
            $Parameters.Department = $User.Department
        }

        if ($User.JobTitle) {
            $Parameters.JobTitle = $User.JobTitle
        }

        if ($PSCmdlet.ShouldProcess(
            $User.UserPrincipalName,
            "Create Microsoft Entra user"
        )) {
            New-MgUser -BodyParameter $Parameters | Out-Null

            [PSCustomObject]@{
                UserPrincipalName = $User.UserPrincipalName
                TemporaryPassword = $Password
                Status            = "Created"
            }
        }
    }
    catch {
        [PSCustomObject]@{
            UserPrincipalName = $User.UserPrincipalName
            TemporaryPassword = ""
            Status            = "Failed: $($_.Exception.Message)"
        }
    }
}

$Results | Export-Csv `
    -Path $ResultPath `
    -NoTypeInformation `
    -Encoding UTF8

Write-Warning "Protect and delete $ResultPath after use."

$Results