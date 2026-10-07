# Cybersecurity Portfolio — Daniel Reis

Hands-on cybersecurity projects focused on **Penetration Testing**, **Web Application Security**, **Linux Privilege Escalation**, and **Vulnerability Assessment**.

All projects were executed in a controlled lab environment (self-hosted VPS) following industry-standard methodologies (OWASP, PTES, NIST).

---

## Projects

| # | Project | Focus Area | Status |
|---|---------|-----------|--------|
| 01 | [Network Reconnaissance](01-network-recon/) | Host discovery, port scanning, service enumeration | In Progress |
| 02 | [Web Application Pentest](02-web-pentest/) | OWASP Top 10, SQLi, XSS, authentication bypass | In Progress |
| 03 | [Linux Privilege Escalation](03-linux-privilege-escalation/) | SUID, sudo misconfig, cron abuse, capabilities | In Progress |
| 04 | [OWASP Top 10 Analysis](04-owasp-top-10/) | Injection, Broken Auth, SSRF, Security Misconfiguration | In Progress |
| 05 | [VPS Security Assessment](05-vps-security-assessment/) | Hardening, firewall, SSH, service audit | Completed |
| 06 | [Full Pentest Report](06-final-pentest-report/) | End-to-end engagement against a corporate environment | In Progress |

## Lab Environment

- **Attack Station:** Kali Linux (local notebook)
- **Target Infrastructure:** Self-hosted VPS with Docker-based targets
- **Isolation:** Internal Docker networks, SSH-only access, UFW firewall
- **Targets:** DVWA, OWASP Juice Shop, custom Linux privesc boxes, simulated corporate services (FTP, SMB, DNS, REST API)

## Methodology

Each project follows a structured approach:

1. **Reconnaissance** — passive and active information gathering
2. **Enumeration** — service identification and vulnerability scanning
3. **Exploitation** — controlled proof-of-concept attacks
4. **Post-Exploitation** — privilege escalation and lateral movement
5. **Reporting** — professional documentation with evidence, impact analysis, and remediation

## Tools

| Category | Tools |
|----------|-------|
| Reconnaissance | Nmap, dig, whois, curl, Gobuster |
| Web Testing | Burp Suite, ffuf, Nikto, sqlmap |
| Exploitation | Metasploit, SearchSploit |
| Credential Attacks | John the Ripper, Hashcat, Hydra |
| Post-Exploitation | LinPEAS, manual enumeration |
| Analysis | Wireshark, tcpdump |

## About

Cybersecurity student focused on Penetration Testing and Red Team operations. Building practical experience through hands-on labs and documented assessments.

- **GitHub:** [danielreis-offsec](https://github.com/danielreis-offsec)
- **Focus:** Pentest / Red Team / Web Application Security
