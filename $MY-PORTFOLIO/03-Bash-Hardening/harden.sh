#!/bin/bash

# CIS Aligned Hardening Script
# Usage: ./harden.sh --audit | --remediate

MODE=""
PASS_COUNT=0
FAIL_COUNT=0
FIX_COUNT=0
SKIP_COUNT=0

# --- Argument Parsing ---
if [[ "$1" == "--audit" ]];then
    MODE="audit"
elif [[ "$1" == "--remediate" ]]; then
    MODE="remediate"
else
    echo "Usage: $0 --audit | --remediate"
    exit 1
fi

echo "=== Running in $MODE mode ==="
echo ""

# --- Logging Function ---
log_result(){
    local status="$1"
    local message="$2"
    if [[ "$status" == "PASS" ]]; then
        echo "[PASS] $message"
        ((PASS_COUNT++))
    elif [[ "$status" == "FAIL" ]]; then
        echo "[FAIL] $message"
        ((FAIL_COUNT++))
    elif [[ "$status" == "FIXED" ]]; then
        echo "[FIXED] $message"
        ((FIX_COUNT++))
    elif [[ "$status" == "SKIP" ]]; then
        echo "[SKIP] $message"
        ((SKIP_COUNT++))
fi
}

# --- CHECKS ---

# --- Passwords ---
check_empty_passwords() {
    local empty_users
    empty_users=$(sudo awk -F: '($2 == "") {print$1}' /etc/shadow)

    if [[ -z "$empty_users" ]]; then
        log_result "PASS" "No accounts with empty passwords"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "Accounts with empty passwords found: $empty_users"
        else
            for user in $empty_users; do
                sudo passwd -l "$user" >/dev/null 2>&1
            done
            log_result "FIXED" "Locked accounts with empty passwords: $empty_users"
        fi
    fi
}

check_root_login_locked() {
    local root_status
    root_status=$(sudo passwd -S root | awk '{print $2}')

    if [[ "$root_status" == "L" ]]; then
        log_result "PASS" "Root account is locked from direct login"
    else
        if [[ "$MODE" == "audit" ]]; then
        log_result "FAIL" "Root account is not locked. (Status: $root_status)"
        else
            sudo passwd -l root >/dev/null 2>&1
            log_result "FIXED" "Root account has been locked"
        fi
    fi
}

check_password_aging() {
    local max_days
    max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')

    if [[ -n "$max_days" && "$max_days" -le 90 ]];then
        log_result "PASS" "Password max age is set to $max_days days"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "Password max age is not set or too high (Current: $max_days)"
        else
            sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
            log_result "FIXED" "Password max age set to 90 days"
        fi
    fi
}

# --- ssh config ---

check_ssh_root_login() {
    local setting
    setting=$(grep -i "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')

    if [[ "$setting" == "no" ]]; then
        log_result "PASS" "SSH root login is disabled"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "SSH root login is not disabled (current: ${setting:-not set})"
        else
            sudo sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
            echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config >/dev/null
            log_result "FIXED" "SSH root login has been disabled"
        fi
    fi
}

check_ssh_password_auth() {
    local setting
    setting=$(grep -i "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')

    if [[ "$setting" == "no" ]]; then
        log_result "PASS" "SSH password authentication is disabled"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "SSH password authentication is not disabled (current: ${setting:-not set})"
        else
            sudo sed -i '/^PasswordAuthentication/d' /etc/ssh/sshd_config
            echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config >/dev/null
            log_result "FIXED" "SSH password authentication has been disabled"
        fi
    fi
}

check_ssh_idle_timeout() {
    local setting
    setting=$(grep -i "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')

    if [[ -n "$setting" && "$setting" -le 300 && "$setting" -gt 0 ]]; then
        log_result "PASS" "SSH idle timeout is set to $setting seconds"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "SSH idle timeout is not set or too high (current: ${setting:-not set})"
        else
            sudo sed -i '/^ClientAliveInterval/d' /etc/ssh/sshd_config
            echo "ClientAliveInterval 300" | sudo tee -a /etc/ssh/sshd_config >/dev/null
            log_result "FIXED" "SSH idle timeout set to 300 seconds"
        fi
    fi
}

# ---- Reload SSH service if in remediate mode ----
reload_ssh_if_needed() {
    if [[ "$MODE" == "remediate" ]]; then
        if sudo systemctl reload ssh 2>/dev/null; then
            log_result "FIXED" "SSH service reloaded to apply changes"
        elif sudo systemctl try-reload-or-restart ssh 2>/dev/null; then
            log_result "FIXED" "SSH service reloaded via socket activation"
        else
            log_result "FAIL" "Could not reload SSH service — verify changes manually"
        fi
    fi
}

# --- Firewall Configuration ---

check_ufw_active() {
    local status
    status=$(sudo ufw status | head -1 | awk '{print $2}')

    if [[ "$status" == "active" ]]; then
        log_result "PASS" "UFW firewall is active"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "UFW firewall is not active"
        else
            sudo ufw allow ssh >/dev/null 2>&1
            sudo ufw --force enable >/dev/null 2>&1
            log_result "FIXED" "UFW firewall enabled (SSH explicitly allowed first)"
        fi
    fi
}

check_listening_ports() {
    local ports
    ports=$(sudo ss -tulnp | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -un)

    if [[ -n "$ports" ]]; then
        log_result "FAIL" "Listening ports found (review manually): $(echo $ports | tr '\n' ' ')"
    else
        log_result "PASS" "No unexpected listening ports found"
    fi
}

# --- File Permissions config ---

check_file_permissions() {
    local passwd_perm shadow_perm gshadow_perm
    passwd_perm=$(stat -c "%a" /etc/passwd)
    shadow_perm=$(stat -c "%a" /etc/shadow)
    gshadow_perm=$(stat -c "%a" /etc/gshadow)

    local issues=""
    [[ "$passwd_perm" != "644" ]] && issues="passwd:$passwd_perm "
    [[ "$shadow_perm" -gt 640 ]] && issues="${issues}shadow:$shadow_perm "
    [[ "$gshadow_perm" -gt 640 ]] && issues="${issues}gshadow:$gshadow_perm "

    if [[ -z "$issues" ]]; then
        log_result "PASS" "Critical account files have correct permissions"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "Incorrect permissions found: $issues"
        else
            sudo chmod 644 /etc/passwd
            sudo chmod 640 /etc/shadow
            sudo chmod 640 /etc/gshadow
            log_result "FIXED" "Corrected permissions on passwd/shadow/gshadow"
        fi
    fi
}

check_world_writable_files() {
    local files
    files=$(sudo find /etc /usr /bin /sbin -xdev -type f -perm -0002 2>/dev/null)

    if [[ -z "$files" ]]; then
        log_result "PASS" "No world-writable files found in system directories"
    else
        log_result "FAIL" "World-writable files found (review manually): $(echo $files | tr '\n' ' ')"
    fi
}

# --- Logging & Auditing ---

check_rsyslog_running() {
    if systemctl is-active --quiet rsyslog; then
        log_result "PASS" "rsyslog is installed and running"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "rsyslog is not running"
        else
            sudo apt-get install -y rsyslog >/dev/null 2>&1
            sudo systemctl enable --now rsyslog >/dev/null 2>&1
            log_result "FIXED" "rsyslog installed and started"
        fi
    fi
}

check_auditd_running() {
    if systemctl is-active --quiet auditd; then
        log_result "PASS" "auditd is installed and running"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "auditd is not running"
        else
            sudo apt-get install -y auditd >/dev/null 2>&1
            sudo systemctl enable --now auditd >/dev/null 2>&1
            log_result "FIXED" "auditd installed and started"
        fi
    fi
}

# --- Updates & Patching ---

check_unattended_upgrades() {
    if systemctl is-active --quiet unattended-upgrades || dpkg -l | grep -q "^ii.*unattended-upgrades"; then
        local enabled
        enabled=$(grep -r "Unattended-Upgrade::Allowed-Origins" /etc/apt/apt.conf.d/ 2>/dev/null | wc -l)
        if [[ "$enabled" -gt 0 ]]; then
            log_result "PASS" "Automatic security updates are configured"
        else
            if [[ "$MODE" == "audit" ]]; then
                log_result "FAIL" "unattended-upgrades installed but not configured"
            else
                sudo dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1
                log_result "FIXED" "Automatic security updates configured"
            fi
        fi
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "unattended-upgrades is not installed"
        else
            sudo apt-get install -y unattended-upgrades >/dev/null 2>&1
            sudo dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1
            log_result "FIXED" "unattended-upgrades installed and configured"
        fi
    fi
}

# --- Unused Services ---

check_unused_services() {
    local this_host
    this_host=$(hostname)

    if [[ "$this_host" != "UBSRV01" ]]; then
        log_result "SKIP" "Unused-services check skipped (server-only, running on $this_host)"
        return
    fi

    local unnecessary_services=("avahi-daemon" "cups" "bluetooth")
    local found=""

    for svc in "${unnecessary_services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            found="$found$svc "
        fi
    done

    if [[ -z "$found" ]]; then
        log_result "PASS" "No unnecessary services are running"
    else
        if [[ "$MODE" == "audit" ]]; then
            log_result "FAIL" "Unnecessary services running: $found"
        else
            for svc in $found; do
                sudo systemctl disable --now "$svc" >/dev/null 2>&1
            done
            log_result "FIXED" "Disabled unnecessary services: $found"
        fi
    fi
}

# --- Run Checks ---
check_empty_passwords
check_root_login_locked
check_password_aging
# ---
check_ssh_root_login
check_ssh_password_auth
check_ssh_idle_timeout
reload_ssh_if_needed
# ---
check_ufw_active
check_listening_ports
# ---
check_file_permissions
check_world_writable_files
# ---
check_rsyslog_running
check_auditd_running
# ---
check_unattended_upgrades
# ---
check_unused_services


# --- Summary ---
echo ""
echo "=== Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Fixed: $FIX_COUNT"
echo "Skipped: $SKIP_COUNT"
