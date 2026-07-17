Get-MgUser `
-Filter "userType eq 'Guest'" |
Select-Object `
DisplayName,
Mail,
UserPrincipalName