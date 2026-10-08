# Portfólio de Segurança Cibernética — Daniel Reis

Projetos práticos de segurança cibernética com foco em **Teste de Intrusão (Pentest)**, **Segurança de Aplicações Web**, **Escalação de Privilégios no Linux** e **Avaliação de Vulnerabilidades**.

Todos os projetos foram executados em um ambiente de laboratório controlado (VPS própria) seguindo metodologias padrão da indústria (OWASP, PTES, NIST).

---

## Projetos

| # | Projeto | Área de Foco | Status |
|---|---------|--------------|--------|
| 01 | [Reconhecimento de Rede](01-network-recon/) | Descoberta de hosts, varredura de portas, enumeração de serviços | Concluído |
| 02 | [Pentest de Aplicação Web](02-web-pentest/) | OWASP Top 10, SQLi, XSS, bypass de autenticação | Em andamento |
| 03 | [Escalação de Privilégios no Linux](03-linux-privilege-escalation/) | SUID, sudo mal configurado, abuso de cron, capabilities | Em andamento |
| 04 | [Análise do OWASP Top 10](04-owasp-top-10/) | Injeção, Autenticação Quebrada, SSRF, Configuração Insegura | Em andamento |
| 05 | [Avaliação de Segurança de VPS](05-vps-security-assessment/) | Hardening, firewall, SSH, auditoria de serviços | Concluído |
| 06 | [Relatório Completo de Pentest](06-final-pentest-report/) | Engajamento ponta a ponta contra um ambiente corporativo | Em andamento |

## Ambiente de Laboratório

- **Estação de Ataque:** Kali Linux (notebook local)
- **Infraestrutura-Alvo:** VPS própria com alvos baseados em Docker
- **Isolamento:** Redes Docker internas, acesso somente via SSH, firewall UFW
- **Alvos:** DVWA, OWASP Juice Shop, máquinas Linux de privesc customizadas, serviços corporativos simulados (FTP, SMB, DNS, API REST)

## Metodologia

Cada projeto segue uma abordagem estruturada:

1. **Reconhecimento** — coleta de informações passiva e ativa
2. **Enumeração** — identificação de serviços e varredura de vulnerabilidades
3. **Exploração** — ataques de prova de conceito controlados
4. **Pós-Exploração** — escalação de privilégios e movimentação lateral
5. **Relatório** — documentação profissional com evidências, análise de impacto e remediação

## Ferramentas

| Categoria | Ferramentas |
|-----------|-------------|
| Reconhecimento | Nmap, dig, whois, curl, Gobuster |
| Testes Web | Burp Suite, ffuf, Nikto, sqlmap |
| Exploração | Metasploit, SearchSploit |
| Ataques a Credenciais | John the Ripper, Hashcat, Hydra |
| Pós-Exploração | LinPEAS, enumeração manual |
| Análise | Wireshark, tcpdump |

## Sobre

Estudante de segurança cibernética com foco em Teste de Intrusão e operações de Red Team. Construindo experiência prática por meio de laboratórios hands-on e avaliações documentadas.

- **GitHub:** [danielreis-offsec](https://github.com/danielreis-offsec)
- **Foco:** Pentest / Red Team / Segurança de Aplicações Web
