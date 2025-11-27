param(
    [string]$DomainName = "lab.gnt",
    [string]$DnsServer = "10.10.10.10",
    [string]$DhcpServer = "DC01",
    [string]$ExpectedScopeNetwork = "10.10.10.0",
    [int]$ExpectedScopePrefix = 24,
    [string[]]$ExpectedOUs = @(
        "OU=Workstations,OU=LAB,DC=lab,DC=gnt",
        "OU=Servers,OU=LAB,DC=lab,DC=gnt",
        "OU=Service Accounts,OU=LAB,DC=lab,DC=gnt"
    ),
    [string[]]$ExpectedGpos = @(
        "LAB-Baseline-Domain",
        "LAB-Baseline-Servers",
        "LAB-Baseline-Workstations"
    ),
    [string]$ReportPath = ".\ADLabValidation-{0}.html" -f (Get-Date -Format "yyyyMMdd_HHmmss")
)

$results = @()

function Add-Result {
    param(
        [string]$Category,
        [string]$Check,
        [string]$Status,
        [string]$Details
    )
    $results += [pscustomobject]@{
        Category = $Category
        Check    = $Check
        Status   = $Status
        Details  = $Details
    }
}

Import-Module ActiveDirectory -ErrorAction SilentlyContinue
Import-Module DnsServer -ErrorAction SilentlyContinue
Import-Module DhcpServer -ErrorAction SilentlyContinue
Import-Module GroupPolicy -ErrorAction SilentlyContinue

function Test-ADDomainObject {
    try {
        $domain = Get-ADDomain -Identity $DomainName -ErrorAction Stop
        Add-Result -Category "AD DS" -Check "Domain reachable" -Status "Pass" -Details ("Domain SID {0}" -f $domain.DomainSID)
    } catch {
        Add-Result -Category "AD DS" -Check "Domain reachable" -Status "Fail" -Details $_.Exception.Message
        return
    }

    try {
        $dc = (Get-ADDomainController -Discover -Service PrimaryDC -ErrorAction Stop)
        Add-Result -Category "AD DS" -Check "Primary DC online" -Status "Pass" -Details ("Primary DC {0}" -f $dc.HostName)
    } catch {
        Add-Result -Category "AD DS" -Check "Primary DC online" -Status "Fail" -Details $_.Exception.Message
    }

    try {
        $fsmo = Get-ADForest -Identity $DomainName -ErrorAction Stop
        $roles = $fsmo.FSMORoles -join ", "
        Add-Result -Category "AD DS" -Check "FSMO roles holders" -Status "Pass" -Details $roles
    } catch {
        Add-Result -Category "AD DS" -Check "FSMO roles holders" -Status "Fail" -Details $_.Exception.Message
    }
}

function Test-Dns {
    if (-not (Get-Module DnsServer)) {
        Add-Result -Category "DNS" -Check "DnsServer module" -Status "Fail" -Details "DnsServer module not available"
        return
    }

    try {
        $zones = Get-DnsServerZone -ComputerName $DnsServer -ErrorAction Stop
        $primaryZone = $zones | Where-Object { $_.ZoneName -eq $DomainName -and $_.ZoneType -eq "Primary" }
        if ($primaryZone) {
            Add-Result -Category "DNS" -Check "Primary zone" -Status "Pass" -Details ("Zone {0} on {1}" -f $DomainName,$DnsServer)
        } else {
            Add-Result -Category "DNS" -Check "Primary zone" -Status "Fail" -Details ("Zone {0} not found on {1}" -f $DomainName,$DnsServer)
        }
    } catch {
        Add-Result -Category "DNS" -Check "Primary zone" -Status "Fail" -Details $_.Exception.Message
    }

    try {
        $record = Resolve-DnsName -Server $DnsServer -Name $DomainName -Type SOA -ErrorAction Stop
        Add-Result -Category "DNS" -Check "SOA record" -Status "Pass" -Details ("SOA host {0}" -f $record.NameHost)
    } catch {
        Add-Result -Category "DNS" -Check "SOA record" -Status "Fail" -Details $_.Exception.Message
    }

    try {
        $dcRecord = Resolve-DnsName -Server $DnsServer -Name ("dc01.{0}" -f $DomainName) -ErrorAction Stop
        $ips = ($dcRecord | Where-Object { $_.QueryType -eq "A" }).IPAddress -join ", "
        if ($ips) {
            Add-Result -Category "DNS" -Check "DC A record" -Status "Pass" -Details ("dc01 IP {0}" -f $ips)
        } else {
            Add-Result -Category "DNS" -Check "DC A record" -Status "Fail" -Details "No A record for DC01"
        }
    } catch {
        Add-Result -Category "DNS" -Check "DC A record" -Status "Fail" -Details $_.Exception.Message
    }
}

function Test-Dhcp {
    if (-not (Get-Module DhcpServer)) {
        Add-Result -Category "DHCP" -Check "DhcpServer module" -Status "Fail" -Details "DhcpServer module not available"
        return
    }

    try {
        $server = Get-DhcpServerv4Scope -ComputerName $DhcpServer -ErrorAction Stop
        $scope = $server | Where-Object { $_.Network -eq $ExpectedScopeNetwork -and $_.PrefixLength -eq $ExpectedScopePrefix }
        if ($scope) {
            Add-Result -Category "DHCP" -Check "Scope exists" -Status "Pass" -Details ("Scope {0}/{1} {2}" -f $scope.Network,$scope.PrefixLength,$scope.Name)
            if ($scope.State -eq "Active") {
                Add-Result -Category "DHCP" -Check "Scope state" -Status "Pass" -Details "Scope is Active"
            } else {
                Add-Result -Category "DHCP" -Check "Scope state" -Status "Fail" -Details ("Scope state {0}" -f $scope.State)
            }
        } else {
            Add-Result -Category "DHCP" -Check "Scope exists" -Status "Fail" -Details ("Expected scope {0}/{1} not found on {2}" -f $ExpectedScopeNetwork,$ExpectedScopePrefix,$DhcpServer)
        }
    } catch {
        Add-Result -Category "DHCP" -Check "Scopes" -Status "Fail" -Details $_.Exception.Message
    }
}

function Test-OUs {
    if (-not (Get-Module ActiveDirectory)) {
        Add-Result -Category "OU Structure" -Check "ActiveDirectory module" -Status "Fail" -Details "ActiveDirectory module not available"
        return
    }

    foreach ($ou in $ExpectedOUs) {
        try {
            $obj = Get-ADOrganizationalUnit -Identity $ou -ErrorAction Stop
            Add-Result -Category "OU Structure" -Check $ou -Status "Pass" -Details ("Found {0}" -f $obj.DistinguishedName)
        } catch {
            Add-Result -Category "OU Structure" -Check $ou -Status "Fail" -Details $_.Exception.Message
        }
    }
}

function Test-Gpos {
    if (-not (Get-Module GroupPolicy)) {
        Add-Result -Category "GPOs" -Check "GroupPolicy module" -Status "Fail" -Details "GroupPolicy module not available"
        return
    }

    $all = Get-GPO -All -ErrorAction SilentlyContinue
    if (-not $all) {
        Add-Result -Category "GPOs" -Check "Any GPOs" -Status "Fail" -Details "No GPOs returned from domain"
        return
    }

    foreach ($gpoName in $ExpectedGpos) {
        $gpo = $all | Where-Object { $_.DisplayName -eq $gpoName }
        if ($gpo) {
            Add-Result -Category "GPOs" -Check $gpoName -Status "Pass" -Details ("GPO ID {0}" -f $gpo.Id)
        } else {
            Add-Result -Category "GPOs" -Check $gpoName -Status "Fail" -Details "GPO not found"
        }
    }
}

function Test-DomainReplication {
    if (-not (Get-Module ActiveDirectory)) {
        Add-Result -Category "AD DS" -Check "Replication summary" -Status "Fail" -Details "ActiveDirectory module not available"
        return
    }

    try {
        $rep = Get-ADReplicationSummary -ErrorAction Stop
        $fails = $rep | Where-Object { $_.FailsRecent -gt 0 -or $_.FailsTotal -gt 0 }
        if ($fails) {
            Add-Result -Category "AD DS" -Check "Replication summary" -Status "Fail" -Details "Replication failures detected"
        } else {
            Add-Result -Category "AD DS" -Check "Replication summary" -Status "Pass" -Details "No replication failures detected"
        }
    } catch {
        Add-Result -Category "AD DS" -Check "Replication summary" -Status "Fail" -Details $_.Exception.Message
    }
}

Write-Host ""
Write-Host "Starting Windows Enterprise Lab validation for $DomainName" -ForegroundColor Cyan
Write-Host ""

Test-ADDomainObject
Test-DomainReplication
Test-Dns
Test-Dhcp
Test-OUs
Test-Gpos

Write-Host ""
Write-Host "Validation summary:" -ForegroundColor Cyan
$results | Sort-Object Category,Check | Format-Table -AutoSize

$overallFail = $results | Where-Object { $_.Status -eq "Fail" }

$results |
    Sort-Object Category,Check |
    ConvertTo-Html -Title "Windows Enterprise Lab Validation" -PreContent "<h1>Windows Enterprise Lab Validation</h1><h3>Domain: $DomainName</h3><h4>Generated: $(Get-Date)</h4>" |
    Set-Content -Path $ReportPath

Write-Host ""
Write-Host ("Report written to {0}" -f (Resolve-Path $ReportPath)) -ForegroundColor Yellow

if ($overallFail) {
    Write-Host ""
    Write-Host "One or more checks failed." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "All checks passed." -ForegroundColor Green
    exit 0
}
