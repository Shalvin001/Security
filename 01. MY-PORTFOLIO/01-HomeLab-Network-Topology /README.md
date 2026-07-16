# Home Lab Network Build & Documentation

---

## Overview

This project documents the design and build of an isolated virtual home lab network, created as the foundation for a self-directed cybersecurity skills-building path. The lab consists of five virtual machines spanning Windows and Linux server/client environments, networked together on a fully isolated internal segment within VirtualBox.

The goal of this project was to design and document a network the way an entry-level SOC analyst or sysadmin would be expected to, with a defined IP scheme, documented traffic flows, a deliberate security posture, and reasoning behind every architectural decision (including the decisions *not* to add certain components yet).

This lab serves as the foundation for the rest of the portfolio series as each subsequent project is set to build on top of this environment.

## Objectives

- Build a 5-node virtual network using VirtualBox, isolated from the host's network
- Design and document an IP addressing scheme
- Produce a clear network topology diagram
- Document the security posture of the lab, including host-based firewall configuration
- Establish a reusable environment for future projects (Active Directory, vulnerability scanning, SIEM, etc.)

## Tools & Environment

| Component            | Detail                                                                     |
| -------------------- | -------------------------------------------------------------------------- |
| Hypervisor           | Oracle VirtualBox                                                          |
| Host Machine         | HP ProBook 640 G3, Windows 11, 8/256 GB                                    |
| Diagramming          | draw.io (diagrams.net)                                                     |
| VM Operating Systems | Windows Server 2022, Windows 10, Ubuntu Server, Ubuntu Desktop, Kali Linux |

---

## Network Architecture

### Topology Diagram
<img width="915" height="599" alt="Home Lab Net Topology drawio" src="https://github.com/user-attachments/assets/384c5e23-d627-4d1d-adf8-048746c8edaa" />


---
### Design Summary

The lab uses two separate, network paths per VM rather than a single shared connection. This separation is the core architectural decision behind the design:

- **LabNet (VirtualBox Internal Network) - In Green** — a software-only network created entirely inside the host, with no path to the host's real network or the internet. All VM-to-VM traffic stays contained here.
- **NAT (per-VM) - In Blue** — a second adapter on each VM that allows **outbound-only internet access** for patching and software installation (`apt update`, Windows Update, tool downloads). NAT translation means VMs can reach out, but nothing external can reach in.

This mirrors a basic version of network segmentation as practiced in production environments — separating a sensitive internal segment from general internet-facing infrastructure, based on purpose rather than physical location.

---
### IP Addressing Table

| Hostname | OS | Role | IP Address (LabNet) | Host-Based Firewall |
|---|---|---|---|---|
| **UBSRV01** | Ubuntu Server | Application / Service Host | 192.168.56.10 | UFW |
|**WIN-DC01** | Windows Server 2022 | Domain Controller | 192.168.56.11 | Windows Defender Firewall |
| **UBDSK01** | Ubuntu Desktop | Analyst Workstation | 192.168.56.12 | UFW |
| **WIN10-CL]** | Windows 10 | Domain Client / Test Workstation | 192.168.56.13 | Windows Defender Firewall |
| **KALI01** | Kali Linux | Security Testing | 192.168.56.14 | UFW |

*Subnet: **192.168.56.0/24**, assigned via VirtualBox Internal Network ("LabNet").*

---
### Data Flow

**LabNet traffic (VM-to-VM):**
`VM NIC → VirtualBox Internal Network virtual switch → Destination VM NIC`

This traffic never leaves the host machine. It is the path used for all inter-VM activity in this and future projects, e.g domain authentication, vulnerability scans, log forwarding, and simulated attack traffic.

**NAT traffic (VM-to-Internet):**
`VM NIC → VirtualBox NAT engine → Host's network adapter → Router → ISP → Internet`

This path exists solely to allow each VM to patch and install software independently. It is outbound-only by default, thus nothing on the internet can initiate a connection into a VM through this path.

---
## Security Posture

No dedicated firewall appliance (e.g. pfSense) is deployed in this lab. This was a deliberate scope decision rather than an oversight. A dedicated firewall VM would be a meaningful addition to my network but for a resource-constrained host, I had to improvise.

Network security is currently handled at two levels:

1. **Isolation by design** — LabNet is a VirtualBox Internal Network, meaning it has no route to the host's physical network or the internet unless explicitly bridged (it isn't).
2. **Host-based firewalls** — every VM has its native firewall (Windows Defender Firewall or UFW) enabled and documented per node in the IP addressing table above.

A dedicated firewall may be considered in a later phase of this path, once the lab's scope grows to include scenarios (e.g. simulated external attacks, honeypot traffic) where perimeter segmentation between zones adds real value.

---

## Reproduction Steps

1. Install Oracle VirtualBox on the host machine.
2. Download ISOs for: Windows Server 2022, Windows 10, Ubuntu Server, Ubuntu Desktop, Kali Linux.
3. Create each VM in VirtualBox with the following per-VM network configuration:
   - **Adapter 1:** Internal Network, name: `LabNet`
   - **Adapter 2:** NAT
4. Install each OS and assign static IPs within LabNet matching the addressing table above.
5. Enable and confirm the native firewall is active on each VM (Windows Defender Firewall / UFW).
6. Verify isolation: confirm VMs can reach each other over LabNet but that LabNet has no route to the host's external network.
7. Verify NAT: confirm each VM can reach the internet (e.g. `ping 8.8.8.8` or `apt update`) independently of LabNet.
8. Document the final topology in draw.io and export as an image for this README.

#### Network Configuration
You may come through some IP addressing challenges during the assigning of IP for Linux Distros.
This was my solution:  
  
**Ubuntu Server**  
- Opened netplan config with `sudo nano /etc/netplan/00-installer-config.yaml`
- Chagned dhcp4 and dhcp6 to false and added static IP `192.168.56.10/24` under addresses
- Applied with `sudo netplan apply` and verified with `ip a`  


**Ubuntu Desktop**  
This one is similar to Ubuntu Server:  
- Opened netplan config with `sudo nano /etc/netplan/00-installer-config.yaml`
- Chagned dhcp4 and dhcp6 to false and added static IP `192.168.56.12/24` under addresses
- Applied with `sudo netplan apply` and verified with `ip a`  


**Kali Linux**  
- Created a new static profile using  
  ```sudo nmcli connection add type ethernet ifname enp0s3 con-name "LabNet" ipv4.method manual ipv4.addresses 192.168.56.14/24```
- Brought it up with `sudo nmcli connection up "LabNet"`

---
## Constraints & Design Decisions

- **Hardware constraint:** The host machine has **8GB RAM**, which limits how many VMs can run simultaneously. VMs are run selectively per project rather than all five concurrently.
- **No dedicated firewall appliance** — addressed under Security Posture above.
- **NAT scope** — NAT is intentionally limited to outbound traffic only, to preserve LabNet's isolation while still allowing practical patching.

---

## Forward-Looking Connections

This lab is the foundation for the rest of the portfolio series:

- **Active Directory Lab** — Windows Server 2022 becomes the Domain Controller, Windows 10 joins as a domain client.
- **Vulnerability Scanning (Nessus)** — all LabNet VMs serve as scan targets (run selectively of course).
- **Python Log Analysis** — logs generated by LabNet VMs are analyzed and mapped to MITRE ATT&CK.
- **GoPhish Phishing Simulation** — campaigns are run against test accounts on the Windows VMs.
- **Wazuh SIEM Capstone** — all five VMs are connected as agents reporting to a Wazuh manager on Ubuntu Server, with Kali used to generate detectable test events.

---
## Lessons Learned
- Internal Network (LabNet) has no DHCP server. Every VM requires a manually configured static IP.
- On Ubuntu Desktop, running `sudo nano 00-installer-config.yaml` without a full path silently creates a copy file in the home directory leaving the real config untouched. Ensure you use the full path or change your working directory to where the files is (that way, it's not a must to use the full path).
- Ubuntu Desktop's NetworkManager and netplan can conflict when both define the same interface accross seperate files. The fix is editing the original installer file as the single source and removing the auto generated NM file.
- Kali linux uses Network Manager with no netplan. If an adapter has no existing profile, it must be created with `nmcli connection add` rather than editing an existing file.
- Always verify the correct adapter before editing by matchhing MAC addresses between `ip a` output and VirtualBox networ settings.

---

**Author:** Shalvin Brandon
