Get-MgAuditLogSignIn `
-Filter "status/errorCode ne 0" `
-Top 100 |
Select-Object `
UserPrincipalName,
CreatedDateTime,
IPAddress,
@{
Name="ErrorCode"
Expression={$_.Status.ErrorCode}
} |
Export-Csv `
".\FailedLogins.csv" `
-NoTypeInformation