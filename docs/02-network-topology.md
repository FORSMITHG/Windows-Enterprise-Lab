# Network Topology

## Default Lab Network

The lab simulates a small enterprise with a single subnet and domain controller.

| Component | Hostname | IP Address     | Role |
|----------|----------|----------------|-----|
| Domain Controller | DC01 | 10.10.10.10 | AD DS, DNS, DHCP (optional) |

- Subnet: `10.10.10.0/24`
- Gateway: `10.10.10.1`
- DNS: DC01

This provides a clean baseline for authentication, naming, and centralized management.

---

## Active Directory

- Forest: `lab.gnt`
- Domain: `lab.gnt`
- NetBIOS: `LAB`
- Default site: `Default-First-Site-Name`

---

## Organizational Unit (OU) Structure

Automatically created:

```
LAB.gnt
├── Workstations
├── Servers
├── ServiceAccounts
├── Groups
└── Policies
```

This structure supports:
- Least privilege separation
- Tidy GPO assignment linked to OU function
- Scalability for future roles and services

---

## DHCP (Optional)

If DHCP is enabled in the deployment script:

- Scope: `10.10.10.50` – `10.10.10.200`
- Options set:
  - Default Gateway: `10.10.10.1`
  - DNS Server: `10.10.10.10`
  - DNS Domain: `lab.gnt`

---

## Future Network Expansions (Optional)

Possible advanced enterprise layouts:

| VLAN | Purpose |
|------|---------|
| 10 | Servers |
| 20 | Endpoints / Workstations |
| 30 | Management |
| 40 | Lab / Testing |
| 50 | Security / Tools |

Firewall and routing rules can be layered into separate repos.

---

## Diagram (Future Add)

```
[Router/Firewall]
       │
  10.10.10.0/24
       │
     [DC01]
      AD DS
      DNS
      DHCP (opt)
```

A Visio / draw.io version will be added later.
