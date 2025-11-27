<#
.SYNOPSIS
Automates deployment of a new Windows Server Active Directory domain controller.

.DESCRIPTION
- Installs AD DS & DNS
- Optional DHCP installation (user prompt)
- Promotes server to a new forest
- Sets static DNS and networking configuration if needed
#>

$DomainName = Read-Host "Enter the FQDN for the new domain (default: lab.gnt)"
if ([string]::IsNullOrWhiteSpace($DomainName)) { $DomainName = "lab.gnt" }

$NetBIOS = $DomainName.Split('.')[0].ToUpper()

Write-Host "`nDomain Name: $DomainName" -ForegroundColor Cyan
Write-Host "NetBIOS Name: $NetBIOS" -ForegroundColor Cyan

$SafeModePwd = Read-Host "Enter a Safe Mode (DSRM) password" -AsSecureString

# Install Required Roles
Write-Host "`nInstalling AD DS and DNS..." -ForegroundColor Yellow
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

# Optional DHCP
$addDHCP = Read-Host "Do you want DHCP installed? (Y/N)"
if ($addDHCP -match "^[Yy]") {
    Write-Host "Installing DHCP..." -ForegroundColor Yellow
    Install-WindowsFeature DHCP -IncludeManagementTools
    Write-Host "DHCP will be configured after promotion." -ForegroundColor Green
}

# Promote to Domain Controller
Write-Host "`nPromoting server to Domain Controller..." -ForegroundColor Yellow
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetBIOS `
    -SafeModeAdministratorPassword $SafeModePwd `
    -InstallDNS `
    -Force

# Server will reboot automatically after promotion
