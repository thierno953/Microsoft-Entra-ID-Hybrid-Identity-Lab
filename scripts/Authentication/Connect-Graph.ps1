Connect-MgGraph `
-Scopes `
"User.ReadWrite.All",
"Group.ReadWrite.All",
"Directory.ReadWrite.All",
"AuditLog.Read.All",
"RoleManagement.Read.Directory",
"Device.Read.All"

Get-MgContext