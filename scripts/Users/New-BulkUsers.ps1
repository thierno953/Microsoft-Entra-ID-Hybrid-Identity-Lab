#requires -Version 7.2
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [Parameter(Mandatory)][string]$CsvPath,
    [switch]$EnableAccounts,
    [switch]$UseDeviceCode
)
. (Join-Path $PSScriptRoot '../Common/Connect-Graph.ps1')
$rows = @(Import-Csv -LiteralPath $CsvPath)
if ($rows.Count -eq 0) { throw 'Empty CSV.' }
$required = @('DisplayName','UserPrincipalName','MailNickname','GivenName','Surname','Department','JobTitle')
foreach ($column in $required) {
    if ($column -notin $rows[0].PSObject.Properties.Name) { throw "Missing CSV column: $column" }
}
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($row in $rows) {
    if ([string]::IsNullOrWhiteSpace($row.DisplayName) -or $row.UserPrincipalName -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$' -or $row.MailNickname -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Invalid row for UPN: $($row.UserPrincipalName)"
    }
    if (!$seen.Add($row.UserPrincipalName)) { throw "Duplicate CSV UPN: $($row.UserPrincipalName)" }
}
Connect-LabGraph -TenantId $TenantId -Scopes @('User.Read.All','Organization.Read.All') -UseDeviceCode:$UseDeviceCode
$domains = @(Get-LabGraphCollection -Uri 'https://graph.microsoft.com/v1.0/organization' | ForEach-Object {
    foreach ($domain in $_['verifiedDomains']) { $domain['name'] }
})
foreach ($row in $rows) {
    if ($row.UserPrincipalName.Split('@')[1] -notin $domains) { throw "UPN domain not verified in tenant: $($row.UserPrincipalName)" }
}
foreach ($row in $rows) {
    $filter = "userPrincipalName eq '" + $row.UserPrincipalName.Replace("'", "''") + "'"
    $existing = @(Get-LabGraphCollection -Uri ('https://graph.microsoft.com/v1.0/users?$select=id&$filter=' + [uri]::EscapeDataString($filter)))
    if ($existing.Count -gt 0) {
        [pscustomobject]@{UserPrincipalName=$row.UserPrincipalName;Status='SkippedExisting';Id=$existing[0]['id']}
        continue
    }
    if (!$PSCmdlet.ShouldProcess($row.UserPrincipalName, "Create cloud-only user; enabled: $EnableAccounts")) { continue }
    Connect-LabGraph -TenantId $TenantId -Scopes @('User.Read.All','Organization.Read.All','User.ReadWrite.All') -UseDeviceCode:$UseDeviceCode
    # Per-user random password is never written to disk or printed.
    # Default disabled account: establish a separate approved onboarding/reset process.
    $password = 'Aa1!' + [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
    $body = @{
        accountEnabled=[bool]$EnableAccounts;displayName=$row.DisplayName;userPrincipalName=$row.UserPrincipalName
        mailNickname=$row.MailNickname;givenName=$row.GivenName;surname=$row.Surname
        passwordProfile=@{password=$password;forceChangePasswordNextSignIn=$true}
    }
    if ($row.Department) { $body.department=$row.Department }
    if ($row.JobTitle) { $body.jobTitle=$row.JobTitle }
    try {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/users' -Body ($body | ConvertTo-Json -Depth 5) -ContentType 'application/json' -OutputType Hashtable
        [pscustomobject]@{UserPrincipalName=$row.UserPrincipalName;Status='Created';Id=$created['id'];AccountEnabled=[bool]$EnableAccounts}
    } catch {
        # Stop at first failed mutation; earlier successful creations are not rolled back.
        throw "Creation failed for $($row.UserPrincipalName). Earlier creations remain. $($_.Exception.Message)"
    } finally {
        $body.passwordProfile.password=$null
        $password=$null
    }
}
