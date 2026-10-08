<h1 align="center">🛡️ Portfólio de Segurança Ofensiva</h1>
<p align="center"><strong>Daniel Reis</strong> · Pentest · Red Team · Segurança de Aplicações Web</p>

<p align="center">
  <img src="https://img.shields.io/badge/Foco-Penetration%20Testing-red?style=for-the-badge" alt="Pentest">
  <img src="https://img.shields.io/badge/-Red%20Team-black?style=for-the-badge" alt="Red Team">
  <img src="https://img.shields.io/badge/-Web%20AppSec-blueviolet?style=for-the-badge" alt="Web AppSec">
  <img src="https://img.shields.io/badge/-Vuln%20Assessment-teal?style=for-the-badge" alt="Vuln Assessment">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Kali%20Linux-557C94?style=flat&logo=kalilinux&logoColor=white" alt="Kali">
  <img src="https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black" alt="Linux">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/OWASP-000000?style=flat&logo=owasp&logoColor=white" alt="OWASP">
  <img src="https://img.shields.io/badge/Burp%20Suite-FF6633?style=flat&logo=burpsuite&logoColor=white" alt="Burp">
  <img src="https://img.shields.io/badge/Wireshark-1679A7?style=flat&logo=wireshark&logoColor=white" alt="Wireshark">
</p>

---

Projetos práticos de segurança ofensiva cobrindo o ciclo de um engajamento — do
**reconhecimento** à **exploração**, **pós-exploração** e **relatório
profissional**. Cada projeto é documentado com metodologia, evidências e
remediação, no formato de um entregável real de pentest.

> Todos os testes foram executados em **ambiente de laboratório controlado e de
> propriedade própria** (VPS com alvos em Docker), seguindo metodologias padrão
> da indústria (**OWASP**, **PTES**, **NIST**). Alvos, hostnames e dados são
> fictícios.

---

## 📂 Projetos

| # | Projeto | Área de Foco | Status |
|---|---------|--------------|:------:|
| 01 | [**Reconhecimento de Rede**](01-network-recon/) | Descoberta de hosts, varredura de portas, enumeração de serviços | ![](https://img.shields.io/badge/-conclu%C3%ADdo-success) |
| 02 | [Pentest de Aplicação Web](02-web-pentest/) | OWASP Top 10, SQLi, XSS, bypass de autenticação | ![](https://img.shields.io/badge/-em%20andamento-yellow) |
| 03 | [Escalação de Privilégios no Linux](03-linux-privilege-escalation/) | SUID, sudo mal configurado, abuso de cron, capabilities | ![](https://img.shields.io/badge/-em%20andamento-yellow) |
| 04 | [Análise do OWASP Top 10](04-owasp-top-10/) | Injeção, Autenticação Quebrada, SSRF, Configuração Insegura | ![](https://img.shields.io/badge/-em%20andamento-yellow) |
| 05 | [**Avaliação de Segurança de VPS**](05-vps-security-assessment/) | Hardening, firewall, SSH, auditoria de serviços | ![](https://img.shields.io/badge/-conclu%C3%ADdo-success) |
| 06 | [Relatório Completo de Pentest](06-final-pentest-report/) | Engajamento ponta a ponta contra ambiente corporativo | ![](https://img.shields.io/badge/-em%20andamento-yellow) |

---

## ⭐ Destaque

**[Relatório de Pentest — Corp API](01-network-recon/corp-api/relatorio-pentest-corp-api.md)**

Teste de intrusão completo contra uma API REST (Flask/Werkzeug), documentado no
padrão profissional: sumário executivo, escopo, metodologia, **8 descobertas
(5 críticas)** com CVSS/CWE, evidências, impacto e remediação.

Destaques técnicos: SQL Injection com bypass de autenticação, IDOR, mass
assignment para escalação de privilégios, forja de tokens JWT via secret key
exposta e senhas armazenadas em texto puro.

---

## 🧪 Ambiente de Laboratório

| | |
|---|---|
| **Estação de ataque** | Kali Linux (notebook local) |
| **Infraestrutura-alvo** | VPS própria hospedando alvos em Docker |
| **Isolamento** | Redes Docker internas, acesso somente via SSH, firewall UFW |
| **Alvos** | DVWA, OWASP Juice Shop, máquinas Linux de privesc, serviços corporativos simulados (FTP, SMB, DNS, API REST) |

---

## 🔄 Metodologia

```
Reconhecimento → Enumeração → Exploração → Pós-Exploração → Relatório
```

1. **Reconhecimento** — coleta de informações passiva e ativa
2. **Enumeração** — identificação de serviços e varredura de vulnerabilidades
3. **Exploração** — ataques de prova de conceito controlados
4. **Pós-Exploração** — escalação de privilégios e movimentação lateral
5. **Relatório** — documentação com evidências, análise de impacto e remediação

---

## 🧰 Stack de Ferramentas

| Categoria | Ferramentas |
|-----------|-------------|
| 🔍 Reconhecimento | Nmap · dig · whois · curl · Gobuster |
| 🌐 Testes Web | Burp Suite · ffuf · Nikto · sqlmap |
| 💥 Exploração | Metasploit · SearchSploit |
| 🔑 Ataques a Credenciais | John the Ripper · Hashcat · Hydra |
| ⬆️ Pós-Exploração | LinPEAS · enumeração manual |
| 📊 Análise | Wireshark · tcpdump |

---

## 👤 Sobre

Estudante de segurança cibernética com foco em **Teste de Intrusão** e operações
de **Red Team**, construindo experiência prática por meio de laboratórios
hands-on e avaliações documentadas no formato de entregáveis reais.

<p align="center">
  <a href="https://github.com/danielreis-offsec">
    <img src="https://img.shields.io/badge/GitHub-danielreis--offsec-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub">
  </a>
</p>
