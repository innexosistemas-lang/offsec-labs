# Metodologia de Reconhecimento

| Campo | Valor |
|-------|-------|
| **Projeto** | 01 — Reconhecimento de Rede |
| **Ambiente** | Rede corporativa simulada TechCorp (`10.10.0.0/24`) |
| **Testador** | Daniel Reis |
| **Base metodológica** | PTES (Pre-engagement / Intelligence Gathering), OWASP Testing Guide (WSTG-INFO) |

---

## 1. Objetivo

Definir a abordagem estruturada de reconhecimento aplicada ao ambiente TechCorp:
mapear a superfície de ataque, descobrir hosts ativos, portas e serviços, e
enumerar as aplicações expostas antes de qualquer tentativa de exploração.

O reconhecimento é dividido em duas frentes complementares:

- **Recon de rede** — descoberta de hosts, portas e serviços em todo o `/24`.
- **Recon de aplicação** — enumeração de endpoints, tecnologias e pontos de
  entrada em cada serviço web/API identificado.

---

## 2. Fases

### Fase 1 — Reconhecimento Passivo

Coleta de informações sem interagir diretamente com os alvos (ou com interação
mínima e indistinguível de tráfego legítimo).

| Atividade | Ferramentas |
|-----------|-------------|
| Levantamento de escopo e faixas de IP | documentação do lab, `lab-reference.md` |
| Resolução e enumeração de DNS | `dig`, `host`, `nslookup` |
| Identificação de domínios/subdomínios internos | `dig`, respostas de `/health` da aplicação |

### Fase 2 — Descoberta de Hosts (Recon Ativo)

Identificar quais endereços do `/24` estão ativos.

| Atividade | Ferramentas |
|-----------|-------------|
| Varredura de descoberta (ping sweep / ARP) | `nmap -sn 10.10.0.0/24`, `arp-scan` |
| Confirmação de hosts com portas abertas | `nmap -sS` (SYN scan) |

### Fase 3 — Varredura de Portas

Mapear portas abertas em cada host ativo.

| Atividade | Ferramentas |
|-----------|-------------|
| Varredura completa de portas TCP | `nmap -p- -sS` |
| Varredura de portas UDP relevantes | `nmap -sU --top-ports` (SNMP, DNS, etc.) |

### Fase 4 — Enumeração de Serviços

Identificar versões, banners e configurações de cada serviço.

| Serviço | Atividade | Ferramentas |
|---------|-----------|-------------|
| Genérico | Detecção de versão e scripts | `nmap -sV -sC` |
| DNS | Transferência de zona (AXFR) | `dig axfr @<dns> <domínio>` |
| SNMP | Community strings padrão | `snmpwalk`, `onesixtyone` |
| SMB | Enumeração de compartilhamentos | `smbclient`, `enum4linux-ng` |
| FTP | Acesso anônimo | `ftp`, `nmap --script ftp-anon` |
| HTTP/API | Banner e tecnologias | `curl -I`, `whatweb`, `nikto` |

### Fase 5 — Reconhecimento de Aplicação

Para cada serviço web/API, mapear a superfície antes da exploração.

| Atividade | Ferramentas |
|-----------|-------------|
| Banner grabbing / fingerprint do framework | `curl -i` |
| Força bruta de diretórios e endpoints | `gobuster`, `ffuf` |
| Enumeração de endpoints da API | análise manual + `gobuster` |
| Identificação de mecanismos de autenticação | análise de tokens/JWT, headers |

---

## 3. Convenções de Evidência

- Toda saída de comando relevante é salva como arquivo de texto em
  `evidencias-<alvo>/` (ex.: `evidencias-corp_api/desc-001.txt`).
- Cada evidência referencia a descoberta correspondente pelo ID
  (`DESCOBERTA-XXX`).
- Dados sensíveis reais (IP público da VPS, credenciais pessoais) **nunca**
  entram no repositório — apenas dados do ambiente de laboratório simulado.
- Os alvos, hostnames (TechCorp, `srv-api01`) e credenciais documentados são
  fictícios, parte do laboratório controlado.

---

## 4. Status de Execução

| Fase | Alvo | Status |
|------|------|--------|
| 1 — Recon passivo | `10.10.0.0/24` | ⏳ Parcial (domínio interno `techcorp.local` identificado via API) |
| 2 — Descoberta de hosts | `10.10.0.0/24` | ⏳ Pendente (varredura Nmap do `/24`) |
| 3 — Varredura de portas | — | ⏳ Pendente |
| 4 — Enumeração de serviços | DNS / SNMP / SMB / FTP | ⏳ Pendente |
| 5 — Recon de aplicação | Corp API (`10.10.0.40:5000`) | ✅ Concluído |

**Executado até o momento:** reconhecimento completo da **Corp API**
(`10.10.0.40:5000`) — banner grabbing, enumeração de endpoints e força bruta
de diretórios com `gobuster` —, documentado em
[corp-api-recon.md](corp-api-recon.md) e formalizado em
[relatorio-pentest-corp-api.md](relatorio-pentest-corp-api.md).

**Próximos passos:** varredura Nmap de todo o `/24` (itens 2 e 3 da checklist),
transferência de zona DNS no servidor corporativo (`10.10.0.30`) e diagrama de
topologia da rede (item 4).
