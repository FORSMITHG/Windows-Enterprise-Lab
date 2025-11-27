<#
.SYNOPSIS
Configures baseline OU layout, GPOs, and DHCP after DC promotion.

.DESCRIPTION
- Creates standardized OU structure
- Deploys baseline Group Policies
- Optionally configures DHCP scope
#>

Import-Module ActiveDirectory
Import-Module GroupPolicy

$Domain = (Get-ADDomain).DNSRoot
$RootDN = (Get-ADDomain).DistinguishedName

Write-Host "Configuring OU structure..." -ForegroundColor Yellow

$OUList = @(
    "OU=Workstations,$RootDN",
    "OU=Servers,$RootDN",
    "OU=ServiceAccounts,$RootDN",
    "OU=Groups,$RootDN",
    "OU=Policies,$RootDN"
)

foreach ($OU in $OUList) {
    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$OU)" -ErrorAction SilentlyContinue)) {
        $OUName = $OU.Split(",")[0].Replace("OU=", "")
        New-ADOrganizationalUnit -Name $OUName -Path ($RootDN) -ProtectedFromAccidentalDeletion $true
        Write-Host "Created OU: $OUName" -ForegroundColor Green
    }
}

Write-Host "`nDeploying baseline GPOs..." -ForegroundColor Yellow

$GPOs = @(
    @{ Name="Baseline-Servers"; Comment="Baseline member server configuration"; Link="OU=Servers,$RootDN" },
    @{ Name="Baseline-Workstations"; Comment="Baseline workstation configuration"; Link="OU=Workstations,$RootDN" },
    @{ Name="Security-Hardening"; Comment="Core security settings"; Link=$RootDN }
)

foreach ($g in $GPOs) {
    if (-not (Get-GPO -Name $g.Name -ErrorAction SilentlyContinue)) {
        $New = New-GPO -Name $g.Name -Comment $g.Comment
        New-GPLink -Name $New.DisplayName -Target $g.Link -Enforced:$false
        Write-Host "Created + Linked GPO: $($g.Name)" -ForegroundColor Green
    }
}

Write-Host "`nChecking DHCP role..." -ForegroundColor Yellow

if (Get-WindowsFeature DHCP | Where-Object {$_.InstallState -eq "Installed"}) {
    Write-Host "Configuring DHCP scope..." -ForegroundColor Yellow
    
    Add-DhcpServerv4Scope -Name "LabScope" -StartRange 10.10.10.50 -EndRange 10.10.10.200 -SubnetMask 255.255.255.0
    Set-DhcpServerv4OptionValue -DnsServer 10.10.10.10 -Router 10.10.10.1 -DnsDomain $Domain

    Write-Host "DHCP scope configured successfully" -ForegroundColor Green
} else {
    Write-Host "DHCP not installed — skipping DHCP configuration" -ForegroundColor DarkGray
}

Write-Host "`nBaseline configuration complete!" -ForegroundColor Cyan
