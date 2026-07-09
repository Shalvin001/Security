# Helpdesk Ticketing System (osTicket)

## 1. Overview

This project simulates a small business IT helpdesk using osTicket, an open-source support ticketing platform, deployed on the home lab server (UBSRV01). The goal was to replicate the full lifecycle of a real IT support operation: department structure, ticket routing, agent workflows, and end-to-end ticket resolution  
osTicket was chosen because it mirrors the real-world tooling used by small IT teams and MSPs, it's open-source with no licensing cost, and it runs on the same LAMP stack skill set that recurs throughout this portfolio.

---

## 2. Tools & Technologies

- **OS:** Ubuntu Server (UBSRV01, 192.168.56.10)
- **Web server:** Apache 2
- **Database:** MySQL 8.4
- **Language:** PHP 8.5.4 (with required extensions: mysqli, gd, mbstring, xml, intl, apcu)
- **Application:** osTicket v1.18.4
- **Client access:** KALI-01 (browser-based access to both the client portal and staff panel)
- **SSH Administration:** Configured SSH on KALI-01 to facilitate secure remote management of UBSRV01

---

## 3. Setup Process

1. Installed Apache, MySQL, and PHP with required extensions on UBSRV01
2. Created a dedicated MySQL database and user (`osticket` / `osadmin`) with privileges scoped to that database only
3. Downloaded osTicket v1.18.4, extracted, and moved the `upload` directory into Apache's web root
4. Set ownership (`www-data:www-data`) and correct permissions (0755 directories, 0644 config file)
5. Ran the web-based installer at `/osticket/setup/`, connecting it to the prepared database
6. Removed the `setup/` directory and locked config file permissions post-install (per osTicket's own security guidance)
7. Configured departments, help topics, and an agent account through the Staff Control Panel
8. Submitted 8 tickets via the client-facing portal using varied fictional requester identities
9. Logged in as the agent to claim, respond to, and resolve tickets through the queue

---

## 4. Architecture & Design Decisions

**Department structure.** Three departments were created to reflect a realistic IT org split: 
- **IT Support** (general queries — password resets, account access, software requests, printers),
- **Network Operations** (connectivity, VPN, network-related issues)  
- **Systems Administration** (server/hardware issues).  
**Help Topic routing.** Seven help topics were mapped to departments to simulate realistic ticket triage:

---

| Help Topic | Department |
|---|---|
| Password Reset | IT Support |
| Account Access Request | IT Support |
| Software Installation Request | IT Support |
| Printer Issue | IT Support |
| Hardware Failure | Systems Administration |
| Network Connectivity Issue | Network Operations |
| VPN/Remote Access Issue | Network Operations |

**Agent design.** A single agent account (John Lanster) was created with **IT Support** as primary department and **Network Operations** granted as extended access. This models a common small-team reality where there is one generalist support tech covering multiple functional areas rather than seperate specialists (more realistic for an SMB than a large enterprise structure with dedicated teams per department).

**Ticket queue realism.** Of the 8 simulated tickets, 5 were fully resolved with agent replies, 1 was replied to but left in-progress (simulating an escalation awaiting third-party, in this case, "ISP input"), and 1 was left open.  

---

## 5. Ticket Simulation Summary

| Ticket | Topic | Status | Outcome |
|---|---|---|---|
| Unable to log into workstation | Password Reset | Resolved | Password reset, temp credential issued |
| New starter needs domain account | Account Access Request | Resolved | Domain account provisioned |
| Need Adobe Acrobat installed | Software Installation | Resolved | Software installed |
| Office printer showing offline | Printer Issue | Resolved | Print spooler restarted, reconnected |
| Server disk space critically low | Hardware Failure | Resolved | Logs cleared; monitoring flagged for follow-up |
| Intermittent internet drops (accounting) | Network Connectivity | In Progress | Escalated to ISP, awaiting response |
| Can't connect to VPN from home | VPN/Remote Access | Resolved | Expired cert config corrected |
| New employee can't access shared drive | Network Connectivity | Open | Unclaimed, sitting in queue |

---

## 6. Screenshots

*(Please click on text to see attached images)*

<details>
  <summary>01. Apache Status</summary>
  <img src="Screenshots/01. ApacheStatus.png" alt="Apache Status">
</details>

<details>
  <summary>02. MySql Status</summary>
  <img src="Screenshots/02. MySqlStatus.png" alt="MySql Status">
</details>

<details>
  <summary>03. Department List</summary>
  <img src="Screenshots/03. DepartmentList.png" alt="Department List">
</details>

<details>
  <summary>04. Help Topics</summary>
  <img src="Screenshots/04. HelpTopics.png" alt="Help Topics">
</details>

<details>
  <summary>05. Agent Access Config</summary>
  <img src="Screenshots/05. AgentAccessConfig.png" alt="Agent Access Config">
</details>

<details>
  <summary>06. Tickets Queue</summary>
  <img src="Screenshots/06. TicketsQueue.png" alt="Tickets Queue">
</details>

<details>
  <summary>07. Resolved Ticket</summary>
  <img src="Screenshots/07. ResolvedTicket.png" alt="Resolved Ticket">
</details>

<details>
  <summary>08. In Progress</summary>
  <img src="Screenshots/08. InProgress.png" alt="In Progress">
</details>

<details>
  <summary>09. Open Tickets</summary>
  <img src="Screenshots/09. OpenTickets.png" alt="Open Tickets">
</details>

<details>
  <summary>10. Client Side</summary>
  <img src="Screenshots/10. ClientSide.png" alt="Client Side">
</details>

<details>
  <summary>11. Client Confirmation Page</summary>
  <img src="Screenshots/11. ClientConfirmationPage.png" alt="Client Confirmation Page">
</details>

---

## 7. Lessons Learned

- **PHP package availability changes across Ubuntu/PHP versions.** `php-imap` was unavailable on this PHP 8.5 install (deprecated upstream). This was resolved by confirming it wasn't required for core ticketing functionality and skipping it, noting the limitation (no automatic ticket-number email delivery to end users) rather than forcing an unnecessary workaround.
- **Bash argument spacing matters more than it seems.** A missing space in `mv source destination` merged two arguments into one invalid path , a small but easy mistake worth double checking on every multi argument command.
- **`sudo` scope isn't inherited across commands.** After using `sudo chown` to hand a directory to `www-data`, subsequent `chmod` calls on that directory required `sudo` again. Normal user permissions no longer applied.
- **NTP sync can silently fail even when the service shows "active."** `systemd-timesyncd` being active doesn't guarantee the clock is actually synchronized — worth checking `timedatectl status` explicitly rather than assuming the service state implies success.
- **Admin accounts exist for exactly this kind of recovery.** Losing an agent's password with no working email/IMAP pipeline isn't a dead end — an administrator can reset any agent's credentials directly through the Staff Control Panel, no email round-trip required.
- **A realistic ticket queue isn't a fully-closed one.** Leaving genuine variation in ticket status (resolved / in-progress / open) demonstrates a working system more convincingly than a portfolio that shows everything neatly solved.

---


**Author:** Shalvin Brandon

