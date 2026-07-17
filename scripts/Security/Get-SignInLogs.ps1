Get-MgAuditLogSignIn `
-Top 50 |
Select-Object `
UserPrincipalName,
CreatedDateTime,
IPAddress,
Status