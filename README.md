# Windows Enterprise Lab

Automated Windows Server lab for building an enterprise-style environment with Active Directory, DNS, DHCP and baseline Group Policy.

This lab is designed for home or test environments that simulate a small/medium business network.

## Features
- Automated deployment of a new AD forest and domain
- DNS and DHCP configuration for a lab subnet
- Opinionated OU structure for workstations, servers and service accounts
- Baseline GPOs for security and operations
- Repeatable deployment for consistent testing

## Lab Goals
- Practice domain design, GPO management and operational tasks
- Test hardening and configuration changes safely
- Provide a foundation for additional labs (VPN, SIEM, cloud integration)

## Topology
- 1 x Domain Controller (DC01)
- Optional member servers or Windows clients
- Single lab subnet (default: `10.10.10.0/24`)
- Domain: `lab.gnt`

More details in:  
`docs/02-network-topology.md`

## Requirements
- Hyper-V, VMware or Proxmox
- Windows Server 2019 or 2022 ISO
- Local admin rights on DC01
- PowerShell 5.1+ or PowerShell 7

## Quick Start

1. Deploy a new Windows Server VM
2. Assign static IP and rename to `DC01`
3. Copy the `scripts` folder to `C:\Lab`
4. Run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
cd C:\Lab
.\Deploy-ADDomain.ps1
```

5. After reboot, log in as the new domain admin and run:

```powershell
cd C:\Lab
.\PostDeploy-Baseline.ps1
```

6. Review documentation in the `docs` folder

## Customization
Change default settings in:

- `scripts/Deploy-ADDomain.ps1`
- `scripts/PostDeploy-Baseline.ps1`

## Next Steps
- Join member servers and clients
- Add remote access (VPN)
- Add logging + SIEM tools
- Integrate Azure Entra ID / Intune
- Expand VLANs + firewall rules in future repos
