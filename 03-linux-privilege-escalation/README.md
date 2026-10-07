# Project 03 — Linux Privilege Escalation

## Objective

Gain initial access as a low-privilege user on custom Linux targets and escalate to root through multiple attack vectors.

## Target Environment

- Target Alpha (`10.10.0.10`) — 7 privesc vectors
- Target Bravo (`10.10.0.20`) — 8 privesc vectors including lateral movement

## Skills Demonstrated

- SUID binary exploitation (find, nmap)
- Sudo misconfiguration abuse (vim, tar)
- Cron job exploitation (writable scripts, wildcard injection)
- Linux capabilities abuse (cap_setuid on Python)
- Sensitive file discovery (writable /etc/shadow, exposed SSH keys)
- Credential harvesting (bash_history, config files)
- Lateral movement between users
- PATH hijacking

## Deliverables

- [ ] Target Alpha — all 7 privesc paths documented
- [ ] Target Bravo — full attack chain from webdev to root
- [ ] LinPEAS analysis and manual enumeration comparison
- [ ] Full report following pentest template
