#requires -Version 7.2
# Dot-source this file, then call Connect-LabGraph.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Connect-LabGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$TenantId,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$Scopes,
        [switch]$UseDeviceCode
    )
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $context = Get-MgContext
    if ($context -and ($context.TenantId -ne $TenantId.ToString() -or $context.AuthType -ne 'Delegated')) {
        Disconnect-MgGraph | Out-Null
        $context = $null
    }
    $missing = @($Scopes | Where-Object { !$context -or $_ -notin $context.Scopes })
    if (!$context -or $missing.Count -gt 0) {
        $parameters = @{
            TenantId = $TenantId.ToString()
            Scopes = $Scopes
            ContextScope = 'Process'
            NoWelcome = $true
        }
        if ($UseDeviceCode) { $parameters.UseDeviceAuthentication = $true }
        Connect-MgGraph @parameters | Out-Null
    }
    $context = Get-MgContext
    if (!$context -or $context.TenantId -ne $TenantId.ToString() -or $context.AuthType -ne 'Delegated') {
        throw 'Unexpected Microsoft Graph authentication context.'
    }
    foreach ($scope in $Scopes) {
        if ($scope -notin $context.Scopes) { throw "Missing scope: $scope" }
    }
}

function Get-LabGraphCollection {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Uri)
    while ($Uri) {
        # Validate server-provided next links before forwarding the bearer token.
        $parsed = [uri]$Uri
        if ($parsed.Scheme -ne 'https' -or $parsed.Host -ne 'graph.microsoft.com' -or $parsed.Port -ne 443) {
            throw 'Only the public Microsoft Graph HTTPS endpoint is supported.'
        }
        $page = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType Hashtable -ErrorAction Stop
        if (!$page.ContainsKey('value')) { throw 'Expected a Graph collection response.' }
        foreach ($item in $page['value']) { $item }
        $Uri = if ($page.ContainsKey('@odata.nextLink')) { [string]$page['@odata.nextLink'] } else { $null }
    }
}

function Write-LabReport {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][object[]]$Data,
        [string]$OutputPath,
        [ValidateSet('Csv','Json')][string]$Format = 'Csv'
    )
    if (!$OutputPath) { $Data; return }
    $absolute = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    $parent = Split-Path -Parent $absolute
    if (!(Test-Path -LiteralPath $parent -PathType Container)) { throw "Output directory does not exist: $parent" }
    if (Test-Path -LiteralPath $absolute) { throw "Output file already exists: $absolute" }
    if ($Format -eq 'Json') {
        ConvertTo-Json -InputObject @($Data) -Depth 30 | Set-Content -LiteralPath $absolute -Encoding utf8
    } elseif (@($Data).Count -gt 0) {
        $Data | Export-Csv -LiteralPath $absolute -NoTypeInformation -Encoding utf8 -NoClobber
    } else {
        Set-Content -LiteralPath $absolute -Value '' -Encoding utf8
    }
    Write-Verbose "Report written: $absolute"
}
