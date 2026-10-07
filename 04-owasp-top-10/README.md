# Project 04 — OWASP Top 10 Analysis

## Objective

Demonstrate practical understanding of each OWASP Top 10 (2021) category through hands-on exploitation and remediation in the lab environment.

## OWASP Top 10 Coverage

| # | Category | Lab Target |
|---|----------|-----------|
| A01 | Broken Access Control | API IDOR, mass assignment |
| A02 | Cryptographic Failures | Plaintext credentials in FTP/config files |
| A03 | Injection | SQLi in API login and search |
| A04 | Insecure Design | Predictable user enumeration |
| A05 | Security Misconfiguration | SNMP default community, DNS zone transfer, FTP anonymous |
| A06 | Vulnerable Components | DVWA, Juice Shop known vulns |
| A07 | Auth Failures | Weak passwords, JWT weak secret |
| A08 | Software Integrity Failures | Writable cron scripts |
| A09 | Logging Failures | No monitoring on targets |
| A10 | SSRF | Juice Shop SSRF challenges |

## Deliverables

- [ ] One documented exploit per OWASP category
- [ ] Remediation guidance for each finding
- [ ] Mapping between lab findings and real-world impact
- [ ] Full report following pentest template
