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