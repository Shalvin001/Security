# Project 3: CIS-Aligned Bash Hardening Script

## 1. Overview

This is a bash hardening project that uses a Bash script (`harden.sh`) that audits and remediates Ubuntu systems against a subset of the CIS Ubuntu Benchmark. It targets two nodes in the home lab — **UBSRV01** (server) and **UBDSK01** (desktop) — using a single, portable script rather than two separate versions.

The script runs in one of two modes, passed as a command line flag:

- `--audit` — checks the system against 14 CIS-aligned controls and reports PASS/FAIL for each. Makes no changes.
- `--remediate` — runs the same checks, but automatically fixes what it can. A small number of checks intentionally never auto-fix.  

Never blindly apply changes without first showing what would change.

<details>
  <summary>UBSRV01 Audit</summary>
  
  <img src="Screenshots/01. UBSRV01 Full Audit.png" alt="UBSRV01 Screenshot" width="100%">
</details>

---

## 2. Tools & Technologies

- **Bash** (argument parsing, functions, conditionals, string/array handling)
- **CIS Ubuntu Benchmark** (control reference)
- Linux utilities used inside the script: `awk`, `grep`, `sed`, `stat`, `find`, `systemctl`, `ss`, `ufw`, `passwd`, `dpkg`
- **VirtualBox** lab environment (UBSRV01, UBDSK01, KALI01 - all on the LabNet internal network from Project 1)
- **SSH key-based authentication** (`ssh-keygen`, `ssh-copy-id`) — set up as a prerequisite before hardening SSH itself

---

## 3. Constraints

- **8GB RAM host (HP ProBook 640 G3):** required care not to run too many VMs simultaneously while testing across UBSRV01, UBDSK01, and KALI01.
- **Risk of SSH lockout** — disabling SSH password authentication is a genuinely dangerous default to automate. This constraint directly shaped the script's design.

---

## 4. Architecture & Design Decisions

### 4.1 Dual-mode design (`--audit` / `--remediate`)
Every check function follows the same pattern: test current state → if correct, log PASS → if incorrect, log FAIL (audit mode) or apply a fix and log FIXED (remediate mode). This is enforced structurally, not just by convention, so no check can silently "fix" something while claiming to only audit.

### 4.2 Safety-first sequencing
Two decisions in particular were made specifically to avoid locking myself out of the lab:

- **SSH key-based auth was set up on both client machines (UBDSK01, KALI01) *before* the script was allowed to disable SSH password authentication.** Disabling password auth without a working key first would have cut off remote access entirely.

<details>
  <summary>Click to view the Screenshot</summary>
  
  <img src="Screenshots/07. SSH Keygen.png" alt="SSH key generation Screenshot" width="100%">
</details>

- **UFW is explicitly allowed to permit SSH *before* the firewall is enabled**, inside the same remediation step — not as two separate steps a user could run out of order. A default-deny firewall enabled without an SSH allow rule first would have blocked the very connection being used to run the script.
<details>
  <summary>Click to view the Screenshot</summary>
  
  <img src="Screenshots/06. UFW checks.png" alt="UFW Checks Screenshot" width="100%">
</details>


### 4.3 Host-aware logic (one script, two machines)
Rather than maintain two separate scripts, `harden.sh` reads `hostname` at runtime. The "Unused Services" check (avahi, cups, bluetooth) is only meaningful on a server profile while a desktop legitimately needs printing and network discovery. On UBDSK01, this check is skipped automatically and logged as `[SKIP]`, rather than incorrectly failing or disabling services the desktop needs.

### 4.4 Checks that intentionally never auto-remediate
Two checks — **listening ports** and **world-writable files** — only ever report PASS/FAIL, even in `--remediate` mode. Automatically closing a port or changing a file's permissions without knowing what depends on it risks breaking a legitimate service. These are designed to surface findings for manual human review, matching how a real SOC analyst would triage rather than blindly automate.

<details>
  <summary>Click to access the script file</summary>

  [View harden.sh](./harden.sh)
</details>

---

## 5. CIS-Aligned Control Coverage (14 checks, 7 sections)

| # | Section | Checks |
|---|---------|--------|
| 1 | Accounts & Authentication | No empty passwords · Root login locked · Password max age ≤ 90 days |
| 2 | SSH Hardening | Root SSH login disabled · Password auth disabled · Idle session timeout set |
| 3 | Firewall / Network Exposure | UFW active (SSH allowed first) · Listening ports flagged for review |
| 4 | File Permissions | `/etc/passwd`, `/etc/shadow`, `/etc/gshadow` permissions · World-writable files flagged |
| 5 | Logging & Auditing | `rsyslog` running · `auditd` installed and running |
| 6 | Updates & Patching | `unattended-upgrades` installed and configured |
| 7 | Unused Services | Unnecessary services (avahi, cups, bluetooth) — server-only, skipped on desktop |

---

## 6. Reproduction Steps

```bash
# On the target machine (UBSRV01 or UBDSK01):
mkdir -p ~/Project3-hardening
cd ~/Project3-hardening
nano harden.sh
# (paste/type script contents)
chmod +x harden.sh

# Always audit first:
./harden.sh --audit

# Then remediate:
./harden.sh --remediate

# Re-run audit to confirm idempotency:
./harden.sh --audit
```

To deploy to a second machine:
```bash
scp harden.sh shalvin254@<target-ip>:~/Project3-hardening/
```

<details>
  <summary>Script View from nano editor</summary></summary>
  
  <img src="Screenshots/02. Nano View.png" alt="Script Nano View" width="100%">
</details>

---

<details>
  <summary>Click to view UBDSK01 Audit</summary>
  
  <img src="Screenshots/06. UBDSK01 last audit.png" alt="Audit Screenshot" width="100%">
</details>

---


<details>
  <summary>UBDSK01 Audit & Remediate</summary>
  
  <img src="Screenshots/06. UFW checks.png" alt="UFW Screenshot" width="100%">
</details>

---

## 8. Lessons Learned

- **Bash's `[[ ]]` test syntax is whitespace-sensitive** — missing a single space (`"audit"]]` vs `"audit" ]]`) produces a cryptic "command not found" error rather than an obvious syntax complaint. Hand-typing the script surfaced this directly.
- **A single missing `elif` (using `if` instead) silently breaks control flow** rather than immediately erroring. This took a `bash -n` syntax check plus visual comparison to catch.
- **Kali Linux does not run SSH by default**, unlike Ubuntu Server/Desktop — this caused a "connection refused" during file transfer that a quick `systemctl status ssh` diagnosed immediately.
- **Order-of-operations matters for safety-critical automation.** Setting up SSH keys before disabling password auth, and allowing SSH before enabling a default-deny firewall, aren't just good practice — skipping either step would have caused a real lockout in this lab.
- **Not every "auto-fix" should be automatic.** Deliberately leaving listening-ports and world-writable-files checks as report-only, rather than auto-remediating, reflects how important it is for manual confirmation.  

---

**Author: Shalvin** 
