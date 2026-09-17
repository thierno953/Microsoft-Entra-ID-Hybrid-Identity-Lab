<#
.SYNOPSIS
Creates Microsoft Entra ID users from a CSV file.

.REQUIRED PERMISSION
User.ReadWrite.All
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [string]$ResultPath = ".\Created-Users.csv"
)

$ErrorActionPreference = "Stop"

function New-TemporaryPassword {
    $Upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    $Lower = "abcdefghijkmnopqrstuvwxyz"
    $Numbers = "23456789"
    $Symbols = "!@#$%*-_"
    $All = $Upper + $Lower + $Numbers + $Symbols

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

# Microsoft Graph module
if (-not (Get-Module -ListAvailable Microsoft.Graph.Users)) {
    throw "Install the module: Install-Module Microsoft.Graph.Users -Scope CurrentUser"
}

Import-Module Microsoft.Graph.Users

if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "User.ReadWrite.All" -NoWelcome
}

$Users = Import-Csv -Path $CsvPath

$RequiredColumns = @(
    "DisplayName",
    "UserPrincipalName",
    "MailNickname",
    "GivenName",
    "Surname"
)

foreach ($Column in $RequiredColumns) {
    if ($Column -notin $Users[0].PSObject.Properties.Name) {
        throw "Missing CSV column: $Column"
    }
}

$Results = foreach ($User in $Users) {
    try {
        $Upn = $User.UserPrincipalName.Trim()
        $EscapedUpn = $Upn.Replace("'", "''")

        $ExistingUser = Get-MgUser `
            -Filter "userPrincipalName eq '$EscapedUpn'" `
            -ErrorAction Stop

        if ($ExistingUser) {
            Write-Warning "User already exists: $Upn"

            [PSCustomObject]@{
                DisplayName       = $User.DisplayName
                UserPrincipalName = $Upn
                TemporaryPassword = ""
                Status            = "Skipped"
            }

            continue
        }

        $TemporaryPassword = New-TemporaryPassword

        $Parameters = @{
            AccountEnabled    = $true
            DisplayName       = $User.DisplayName.Trim()
            UserPrincipalName = $Upn
            MailNickname      = $User.MailNickname.Trim()
            GivenName         = $User.GivenName.Trim()
            Surname           = $User.Surname.Trim()

            PasswordProfile   = @{
                Password                      = $TemporaryPassword
                ForceChangePasswordNextSignIn = $true
            }
        }

        if ($User.Department) {
            $Parameters.Department = $User.Department.Trim()
        }

        if ($User.JobTitle) {
            $Parameters.JobTitle = $User.JobTitle.Trim()
        }

        if ($PSCmdlet.ShouldProcess($Upn, "Create Entra ID user")) {
            New-MgUser -BodyParameter $Parameters | Out-Null
            Write-Host "Created: $Upn" -ForegroundColor Green

            [PSCustomObject]@{
                DisplayName       = $User.DisplayName
                UserPrincipalName = $Upn
                TemporaryPassword = $TemporaryPassword
                Status            = "Created"
            }
        }
    }
    catch {
        Write-Error "Failed to create $($User.UserPrincipalName): $($_.Exception.Message)"

        [PSCustomObject]@{
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            TemporaryPassword = ""
            Status            = "Failed"
        }
    }
}

$Results | Export-Csv `
    -Path $ResultPath `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host "`nResults saved to: $ResultPath" -ForegroundColor Cyan
Write-Warning "The results file contains temporary passwords. Protect or delete it after use."