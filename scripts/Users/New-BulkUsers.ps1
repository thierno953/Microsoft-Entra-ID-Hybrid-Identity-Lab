# ===================================================================
# Microsoft Entra ID - Bulk User Creation
# Microsoft Graph PowerShell
# ===================================================================

# Required module
Import-Module Microsoft.Graph.Users

# Connect to Microsoft Graph
Connect-MgGraph `
    -Scopes "User.ReadWrite.All"

# CSV file location
$CsvPath = "$PSScriptRoot\Users.csv"

# Import users
$Users = Import-Csv -Path $CsvPath

foreach ($User in $Users) {

    $PasswordProfile = @{
        Password                      = $User.Password
        ForceChangePasswordNextSignIn = $true
    }

    $UserParams = @{
        AccountEnabled    = [System.Convert]::ToBoolean($User.AccountEnabled)

        DisplayName       = $User.DisplayName
        UserPrincipalName = $User.UserPrincipalName
        MailNickname      = $User.MailNickname

        GivenName         = $User.GivenName
        Surname           = $User.Surname

        JobTitle          = $User.JobTitle
        Department        = $User.Department

        UsageLocation     = $User.UsageLocation

        PasswordProfile   = $PasswordProfile
    }

    try {

        New-MgUser `
            -BodyParameter $UserParams `
            -ErrorAction Stop

        Write-Host "[SUCCESS] Created user: $($User.UserPrincipalName)" `
            -ForegroundColor Green

    }

    catch {

        Write-Host "[FAILED] Could not create user: $($User.UserPrincipalName)" `
            -ForegroundColor Red

        Write-Host $_.Exception.Message
    }
}

Disconnect-MgGraph