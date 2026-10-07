# Security Assessment Report — VPS Hardening

| Field | Value |
|-------|-------|
| **Target** | Cloud VPS (Kali Linux 2026.1) |
| **Engagement Type** | Infrastructure Security Assessment |
| **Tester** | Daniel Reis |
| **Date** | 2026-10-07 |
| **Version** | 1.0 |
| **Classification** | Portfolio / Educational |

---

## 1. Executive Summary

A security assessment was conducted on a freshly provisioned cloud VPS running Kali Linux 2026.1. The initial configuration presented several significant security weaknesses common in default cloud deployments, including root SSH access, password-based authentication, absence of firewall rules, and no brute-force protection.

Seven findings were identified ranging from High to Low severity. All findings were remediated during the engagement, reducing the attack surface from an exposed default configuration to a hardened, production-grade baseline.

**Overall Risk Rating (Before):** High
**Overall Risk Rating (After):** Low

| Severity | Found | Remediated |
|----------|-------|------------|
| High | 3 | 3 |
| Medium | 2 | 2 |
| Low | 1 | 1 |
| Informational | 1 | 1 |

---

## 2. Scope

### 2.1 In Scope

| Target | Type | Address |
|--------|------|---------|
| Cloud VPS | Linux Server | [REDACTED] |

### 2.2 Rules of Engagement

- Full administrative access (authorized owner)
- Assessment and remediation in the same engagement
- No third-party systems involved

---

## 3. Methodology

Assessment followed a structured approach based on CIS Benchmarks and NIST SP 800-123 (Guide to General Server Security):

1. **Initial Audit** — document default configuration state
2. **Vulnerability Identification** — assess each service and configuration
3. **Remediation** — apply hardening measures
4. **Verification** — confirm each fix is effective
5. **Documentation** — produce findings and evidence

---

## 4. Findings

### 4.1 [FINDING-001] — SSH Root Login Enabled

| Field | Value |
|-------|-------|
| **Severity** | High |
| **CVSS Score** | 7.5 |
| **CWE** | CWE-250 — Execution with Unnecessary Privileges |
| **Affected Asset** | SSH Service (port 22) |
| **Status** | Remediated |

**Description:**

The SSH service was configured with `PermitRootLogin yes`, allowing direct authentication to the root account over the network.

**Impact:**

An attacker who obtains root credentials (via brute force, credential stuffing, or key compromise) gains immediate full system control without any privilege escalation step.

**Evidence:**

Before:
```
$ grep PermitRootLogin /etc/ssh/sshd_config
PermitRootLogin yes
```

**Remediation Applied:**

1. Created a dedicated administrative user (`pentester`) with sudo privileges
2. Copied SSH authorized keys to the new user
3. Set `PermitRootLogin no` in SSH configuration
4. Added `AllowUsers pentester` to restrict SSH access

```
$ grep -E "PermitRootLogin|AllowUsers" /etc/ssh/sshd_config.d/hardening.conf
PermitRootLogin no
AllowUsers pentester
```

---

### 4.2 [FINDING-002] — SSH on Default Port with No Rate Limiting

| Field | Value |
|-------|-------|
| **Severity** | High |
| **CVSS Score** | 7.1 |
| **CWE** | CWE-307 — Improper Restriction of Excessive Authentication Attempts |
| **Affected Asset** | SSH Service (port 22) |
| **Status** | Remediated |

**Description:**

SSH was listening on the default port 22 with no brute-force protection mechanism. Automated scanners constantly probe port 22 on all public IP addresses.

**Impact:**

The server was exposed to automated brute-force and credential stuffing attacks. Combined with password authentication (Finding 003), this significantly increased the probability of unauthorized access.

**Evidence:**

Before:
```
$ ss -tlnp | grep ssh
LISTEN 0 128 0.0.0.0:22 0.0.0.0:* users:(("sshd",...))

$ systemctl status fail2ban
Unit fail2ban.service could not be found.
```

**Remediation Applied:**

1. Changed SSH port from 22 to 2222
2. Installed and configured fail2ban (3 failed attempts = 2-hour ban)
3. Set `MaxAuthTries 3` and `LoginGraceTime 30` in SSH configuration

```
$ grep "^Port" /etc/ssh/sshd_config.d/hardening.conf
Port 2222

$ fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

---

### 4.3 [FINDING-003] — Password Authentication Enabled

| Field | Value |
|-------|-------|
| **Severity** | High |
| **CVSS Score** | 7.5 |
| **CWE** | CWE-521 — Weak Password Requirements |
| **Affected Asset** | SSH Service |
| **Status** | Remediated |

**Description:**

Although key-based authentication was configured, the initial cloud provider setup also retained password authentication as a fallback. The default `kali` user had a known default password.

**Impact:**

Password authentication makes the server vulnerable to brute-force attacks. Default credentials for the `kali` user are publicly documented.

**Remediation Applied:**

1. Confirmed `PasswordAuthentication no` in SSH configuration
2. Set `AuthenticationMethods publickey` to enforce key-only access
3. Removed the default `kali` user account entirely

```
$ grep -E "PasswordAuthentication|AuthenticationMethods" /etc/ssh/sshd_config.d/hardening.conf
PasswordAuthentication no
AuthenticationMethods publickey

$ id kali
id: 'kali': no such user
```

---

### 4.4 [FINDING-004] — No Firewall Configured

| Field | Value |
|-------|-------|
| **Severity** | Medium |
| **CVSS Score** | 5.3 |
| **CWE** | CWE-284 — Improper Access Control |
| **Affected Asset** | Network Perimeter |
| **Status** | Remediated |

**Description:**

No host-based firewall was configured. All services bound to 0.0.0.0 were accessible from the public internet.

**Impact:**

Any service started on the VPS (intentionally or not) would be immediately exposed to the internet, increasing the attack surface.

**Remediation Applied:**

Installed and configured UFW with a default-deny incoming policy:

```
$ ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
2222/tcp                   ALLOW IN    Anywhere    # SSH-hardened
```

---

### 4.5 [FINDING-005] — No Automatic Security Updates

| Field | Value |
|-------|-------|
| **Severity** | Medium |
| **CVSS Score** | 5.0 |
| **CWE** | CWE-1104 — Use of Unmaintained Third Party Components |
| **Affected Asset** | Operating System |
| **Status** | Remediated |

**Description:**

The system had no mechanism for automatic security patch installation. Critical vulnerabilities in installed packages would remain unpatched until manually updated.

**Impact:**

Known CVEs in system packages could be exploited if patches are not applied promptly.

**Remediation Applied:**

Installed `unattended-upgrades` with daily security update checks:

```
$ cat /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
```

---

### 4.6 [FINDING-006] — Unnecessary Default User Account

| Field | Value |
|-------|-------|
| **Severity** | Low |
| **CVSS Score** | 3.1 |
| **CWE** | CWE-798 — Use of Hard-coded Credentials |
| **Affected Asset** | User Accounts |
| **Status** | Remediated |

**Description:**

The default `kali` user (UID 1000) was present with sudo group membership. Default Kali installations use well-known credentials for this account.

**Remediation Applied:**

Removed the user and its home directory:

```
$ userdel -r kali
```

---

### 4.7 [FINDING-007] — SSH Information Disclosure

| Field | Value |
|-------|-------|
| **Severity** | Informational |
| **CVSS Score** | 0.0 |
| **CWE** | CWE-200 — Exposure of Sensitive Information |
| **Affected Asset** | SSH Service |
| **Status** | Remediated |

**Description:**

SSH exposed unnecessary features that could aid reconnaissance: X11 forwarding was enabled, and TCP forwarding was unrestricted.

**Remediation Applied:**

Disabled unnecessary SSH features:

```
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
```

---

## 5. Remediation Summary

| ID | Finding | Severity | Remediation | Status |
|----|---------|----------|-------------|--------|
| 001 | SSH Root Login | High | Disabled, created admin user | Done |
| 002 | Default Port / No Rate Limit | High | Port 2222, fail2ban | Done |
| 003 | Password Authentication | High | Key-only, removed default user | Done |
| 004 | No Firewall | Medium | UFW default-deny | Done |
| 005 | No Auto Updates | Medium | unattended-upgrades | Done |
| 006 | Default User Account | Low | Removed `kali` user | Done |
| 007 | SSH Info Disclosure | Info | Disabled X11/TCP forwarding | Done |

---

## 6. Conclusion

The VPS was successfully hardened from a default, high-risk state to a secured baseline configuration. All seven identified findings were remediated. The server now implements defense-in-depth with:

- **Authentication:** key-only, non-root, single authorized user
- **Network:** firewall with default-deny, non-standard SSH port
- **Monitoring:** fail2ban for brute-force detection and automated response
- **Maintenance:** automatic security updates enabled

### Recommendations for Ongoing Security

1. Review fail2ban logs periodically for attack patterns
2. Monitor `unattended-upgrades` logs for failed updates
3. Perform periodic configuration audits against CIS benchmarks
4. Consider implementing log forwarding to a central SIEM

---

## Appendix A — Tools Used

| Tool | Purpose |
|------|---------|
| Nmap / ss | Port and service discovery |
| UFW | Host-based firewall management |
| fail2ban | Brute-force prevention |
| ssh-keygen | Key pair generation |
| systemctl | Service management and auditing |

## Appendix B — Configuration Files

- `/etc/ssh/sshd_config.d/hardening.conf` — SSH hardening
- `/etc/fail2ban/jail.local` — Fail2ban SSH jail
- `/etc/apt/apt.conf.d/20auto-upgrades` — Automatic updates
