# Deployment Runbook

This runbook documents the full process for deploying the Windows Enterprise Lab environment, validating success, and preparing for expansion.

---

## Phase 1: Base VM Provisioning

1. Deploy a new Windows Server VM (2019 or 2022)
2. Assign a static IP address on your lab subnet  
   - Example: `10.10.10.10/24`
3. Set DNS server to itself  
   - `10.10.10.10`
4. Rename the server to `DC01`
5. Reboot to apply hostname changes
6. Install all Windows Updates

---

## Phase 2: Domain Deployment Script

1. Copy the `scripts` folder from this repo to:  
   `C:\Lab`

2. Open **PowerShell as Administrator** and run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
cd C:\Lab
.\Deploy-ADDomain.ps1
```

3. The script will:
   - Install AD DS and DNS roles
   - (Optional) Install DHCP
   - Promote server to a domain controller
   - Create a new forest and DNS zones

4. The server will **automatically reboot**

---

## Phase 3: Baseline Configuration Script

1. Log in as the new domain admin account (created by script)
2. Run the post-deployment script:

```powershell
cd C:\Lab
.\PostDeploy-Baseline.ps1
```

3. The script will:
   - Create OU structure
   - Create and link baseline Group Policies
   - Configure core security and operational settings

---

## Phase 4: Validation Checklist

After scripts complete, verify:

| Component | Validation | Status |
|----------|------------|--------|
| Active Directory | Users & Computers opens without errors | |
| DNS | Forward and reverse lookup zones created | |
| DHCP | Scope deployed + correct settings (if enabled) | |
| OU Structure | Matches repository documentation | |
| Group Policy | Baseline GPOs exist and are linked | |

Join a workstation to the domain to confirm policy inheritance.

---

## Baselining Snapshot

After validation:

- Take a **checkpoint** in Hyper-V
- Or **VM snapshot** in Proxmox / VMware

This snapshot becomes your **clean lab restore point**.

---

## Expansion Targets

Recommended follow-up labs:

- Remote access (OpenVPN / WireGuard)
- Sysmon + event forwarding + SIEM platform
- M365 hybrid identity (Entra Connect)
- Intune device enrollment + compliance
- Windows Defender / Endpoint hardening
- Additional AD DS sites + VLAN segmentation

Document and track each phase as separate repos for portfolio strength.

---

## Notes

This lab is designed for **learning and testing only** — not production use.
