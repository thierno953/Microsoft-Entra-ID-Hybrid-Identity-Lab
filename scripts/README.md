## Installation

```PowerShell
Install-Module Microsoft.Graph -Scope CurrentUser
```

`Common/Connect-Graph.ps1`

```PowerShell
function Connect-Graph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$Scopes
    )

    if (-not (Get-Module -ListAvailable Microsoft.Graph.Authentication)) {
        throw "Install Microsoft Graph: Install-Module Microsoft.Graph -Scope CurrentUser"
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $Context = Get-MgContext

    if (-not $Context) {
        Connect-MgGraph -Scopes $Scopes -NoWelcome
        return
    }

    $MissingScopes = $Scopes | Where-Object {
        $_ -notin $Context.Scopes
    }

    if ($MissingScopes) {
        Connect-MgGraph -Scopes $Scopes -NoWelcome
    }
}
```

---

`Users/New-BulkUsers.ps1`

```PowerShell
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
```

`users.csv`

```csv
DisplayName,UserPrincipalName,MailNickname,GivenName,Surname,Department,JobTitle
Jean Dupont,jean.dupont@contoso.onmicrosoft.com,jean.dupont,Jean,Dupont,IT,System Administrator
Marie Martin,marie.martin@contoso.onmicrosoft.com,marie.martin,Marie,Martin,Finance,Accountant
```

Test

```PowerShell
.\scripts\Users\New-BulkUsers.ps1 `
    -CsvPath .\data\users.csv `
    -WhatIf
```

```PowerShell
.\scripts\Users\New-BulkUsers.ps1 `
    -CsvPath .\data\users.csv
```

---

`Users/Get-EntraUsers.ps1`

```PowerShell
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
```

---

`Users/Disable-User.ps1`

```PowerShell
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
```

```PowerShell
.\scripts\Users\Disable-User.ps1 `
    -UserId jean.dupont@contoso.onmicrosoft.com `
    -WhatIf
```

---

`Authentication/Get-MFAStatus.ps1`

```PowerShell
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
```

```PowerShell
.\scripts\Authentication\Get-MFAStatus.ps1 `
    -OutputPath .\output\MFA-Status.csv
```

---

`Devices/Get-HybridJoinedDevices.ps1`

```PowerShell
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
```

```PowerShell
.\scripts\Devices\Get-HybridJoinedDevices.ps1 `
    -OutputPath .\output\Hybrid-Devices.csv
```

---

`Groups/Get-GroupMembers.ps1`

```PowerShell
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
```

---

`Roles/Get-RoleAssignments.ps1`

```PowerShell
[CmdletBinding()]
param (
    [string]$OutputPath
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes `
    "RoleManagement.Read.Directory",
    "Directory.Read.All"

$RoleDefinitions = @{}

Get-MgRoleManagementDirectoryRoleDefinition -All |
    ForEach-Object {
        $RoleDefinitions[$_.Id] = $_.DisplayName
    }

$Results = Get-MgRoleManagementDirectoryRoleAssignment `
    -All `
    -ExpandProperty Principal |
    Select-Object `
        @{
            Name       = "Role"
            Expression = {
                $RoleDefinitions[$_.RoleDefinitionId]
            }
        },
        @{
            Name       = "Principal"
            Expression = {
                $_.Principal.AdditionalProperties.displayName
            }
        },
        PrincipalId,
        DirectoryScopeId

if ($OutputPath) {
    $Results | Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8
}

$Results
```

```PowerShell
.\scripts\Roles\Get-RoleAssignments.ps1 `
    -OutputPath .\output\Role-Assignments.csv
```

---

`Security/Get-SignInLogs.ps1`

```PowerShell
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
```

```PowerShell
.\scripts\Security\Get-SignInLogs.ps1 `
    -Days 7 `
    -OutputPath .\output\SignIn-Logs.csv
```

---

`Security/Get-ConditionalAccessPolicies.ps1`

```PowerShell
[CmdletBinding()]
param (
    [string]$OutputPath
)

. "$PSScriptRoot\..\Common\Connect-Graph.ps1"

Connect-Graph -Scopes "Policy.Read.All"

$Results = Get-MgIdentityConditionalAccessPolicy -All |
    Select-Object `
        Id,
        DisplayName,
        State,
        CreatedDateTime,
        ModifiedDateTime

if ($OutputPath) {
    $Results | Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8
}

$Results
```

---

`Tenant/Get-TenantInformation.ps1`

```PowerShell
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
```
