# Nmap Reconnaissance Project - scanme.nmap.org

This project is part of my Reconnaissance practice and demonstration.
The goal was to learn and demonstrate how to use Nmap to discover open ports,
identify services and understand basic network enumeration.

##### This here is the command I used: nmap <scan_type> --top-ports 100 -T4 scanme.nmap.org -oA Scans/\<filename>_$(date +%Y-%m-%d_%H-%M-%S)


## OBJECTIVE:
  - Perform basic network reconnaissance using different Nmap scan techniques.

## TOOLS  USED
 - Nmap
 - Linux Teminal
 - Github (for documentation)
- Environment: Local machine (Linux)

The target used here was scanme.nmap.org,
a publicly available test server provided by the Nmap project for practice purposes.

## SCANS PERFORMED
### 1. Basic Scan
Command used: 'nmap scanme.nmap.org'

The three main purpose of this scan;
- Host Discovery
- Port scanning
- Service detection

It's like looking at the doors and windows of a house from the outside.
You aren't going in yet, just checking on which windows(ports) are open and which ones are closed,
and learn where you might use to enter the house or investigate further.

#### Key Findings
| Port | State | Service |
|------|-------|---------|
|  22  | open  |   SSH   |
|  80  | open  |   HTTP  |
---

#### Only two files are included for this scan: "basic_scan.txt" and a screenshot, under the 'Basic_Scan' folder

### 2. OS Detection
command used: 'namp -O scanme.nmap.org'
The purpose of this scan is to identify the OS running on a target

#### Files Included
- OS_detection.nmap
- OS_detection.gnmap
- OS_detection.xml
- Screenshot (VirtualBoxVM...)
(please refer to the "OS_Detection" folder)

#### Key Findings
- Running: AT&T embeded (85%)
- Aggressive OS guesses: AT&T BGW210 voice gateway (85%)
No exact matches were found. Test conditions were non ideal. Which basically means there was not enough reliable information to accurately identify the OS (Operating System). This is most likely due to the existence of a Firewall (the target is protected).

#### Security Impacts
Knowing the OS helps identify 
- OS specific vulnerabilities
- Possible privillage esscalation paths
- System attack surfaces

### 3. Service Scan
Command used: 'nmap -sV scanme.nmap.org'
The purpose of this scan is to determine the services running on open ports and determine their versions

#### Files Included
- service_scan.nmap
- service_scan.gnamp
- service_scan.xml
- screenshot(VirtualBoxVM...)
(please refer to the "Service_scan" folder)

#### Key Findings

| Port | State | Service | Version | Additional Info |
|------|-------|---------|---------|------------------|
| 22/tcp | Open | SSH | OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13 | Protocol 2.0 |
| 80/tcp | Open | HTTP | Apache httpd 2.4.7 (Ubuntu) | Web server |

**Service Info:**
- OS: Linux
- CPE: cpe:/o:linux:linux_kernel

#### Security Impacts
Service versions can be checked agains vulnerability databases such as
- CVE database
- Exploit DB
- NVD (National Vulnerability Database).
Outdated services may be vulnerable to known exploits

### 4. Aggressive Scan
Command used: 'nmap -A scanme.nmap.org'
This scan combines various scanning *(OS detection, Service detection, TCP SYN scan)* techniques into one command

#### Files Included
- Aggressive_scan.nmap
- Aggressive_scan.gnmap
- Aggressive_scan.xml
- Screenshot (VirtualBoxVM...)
(please refer to the "Aggressive_scan" folder)

#### Key Findings
Open ports      22 80.
Services        SSH HTTP.
OS              Oracle Virtualbox Slirp NAT bridge (94%), AT&T BGW210 voice gateway (92%), QEMU user mode network gateway (90%)


#### Security Impacts
Aggressive scans return deep enumeration that may reveal:
- Vulnerabilities
- Misconfigurations

### Additional Information
- It is recommended to perform scans as a root user (sudo).
-- For example: **sudo -A --top-ports 100 -T4 scanme.nmap.org**
- That way it is more proffessional and the results will be more accurate. And yes, I forgot to do that, but I intend to do better next time. 
- I scanned top 100 ports instead of the default top 1000 port due to my resources beiing limited.

## CONCLUSION
- Basic scan successfully identified open ports that are later analyzed in subsequent scans.
- Service detection scan provided deeper insights neccessary for vulnerability analysis.
- OS detection provides valuable information for targeted vulnerability analysis.
- The aggressive scan provided comprehensive information on the target system.


Author: Shalvin Brandon <br>
Project: Nmap Reconnaissance Scan <br>
Date: 25 Feb 2026








