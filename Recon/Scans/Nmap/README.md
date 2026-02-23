# Nmap Reconnaissance Project - scanme.nmap.org

This project is part of my Reconnaissance practice and demonstration.
The goal was to learn and demonstrate how to use Nmap to discover open ports,
identify services and understand basic network enumeration.

## This here is the command I used: nmap <scan_type> --top-ports 100 T4 -oA scanme.nmap.org Scans/<filename>_$(date +%Y-%m-%d_%H-%M-%S)


## Objective:
  - Perform basic network reconnaissance using different Nmap scan techniques.

## Tools Used
 - Nmap
 - Linux Teminal
 - Github (for documentation)
- Environment: Local machine (Linux)

The target used here was scanme.nmap.org,
a publicly available test server provided by the Nmap project for practice purposes.

## Scans Performed
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
- Port    22    80
- State   open  open
- Service SSH   HTTP

#### Only two files are included for this scan: "basic_scan.txt" and a screenshot, under the 'Basic_Scan' folder

### 2. OS Detection
command used: 'namp -O scanme.nmap.org'
The purpose of this scan is to identify the OS running on a target

#### Key Findings
- Running: AT&T embeded (85%)
- Aggressive OS guesses: AT&T BGW210 voice gateway (85%)
No exact matches were found. Test conditions were non ideal. Which basically means there was not enough reliable information to accurately identify the OS (Operating System). This is most likely due to the existence of a Firewall (the target is protected).

### 3. Service Scan
Command used: 'nmap -sV scanme.nmap.org'
The purpose of this scan is to determine the services running on open ports and determine their versions

#### Key Findings
Service Info: OS: Linux; CPE: cpe:/o: Linux: Linux_kernel






