# Windows Enterprise Lab

Automated Windows Server lab for building an enterprise-style environment with Active Directory, DNS, DHCP and baseline Group Policy.

This lab is designed for home or test environments that simulate a small/medium business network.

## Features

- Automated deployment of a new AD forest and domain
- DNS and DHCP configuration for a lab subnet
- Opinionated OU structure for workstations, servers and service accounts
- Baseline GPOs for security and operations
- Repeatable process documented as a runbook

## Lab Goals

- Practice domain design, GPO management and operational tasks
- Test hardening, configuration changes and new tools safely
- Provide a foundation for VPN, SIEM and cloud-integration labs

## Topology

- 1 x Domain Controller (DC01)
- Optional additional member servers or Windows clients
- Single lab subnet (default 10.10.10.0/24)
- Single AD forest and domain (default lab.gnt)

Details and variations are in `docs/02-network-topology.md`.

## Requirements

- Hyper-V, VMware or Proxmox lab host
- Windows Server 2019 or 2022 ISO
- Local admin access to the server that will become DC01
- PowerShell 5.1+ or PowerShell 7 with remoting

## Quick Start

1. Build a clean Windows Server VM and assign:
   - Static IP on your lab subnet
   - Hostname: `DC01` (or change in config section of the scripts)

2. Copy the `scripts` folder to `C:\Lab` on DC01.

3. Start an elevated PowerShell session and run:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope Process
   cd C:\Lab
   .\Deploy-ADDomain.ps1
