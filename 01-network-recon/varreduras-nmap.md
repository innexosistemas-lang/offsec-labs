# Varreduras com Nmap — Rede TechCorp (`10.10.0.0/24`)

| Campo | Valor |
|-------|-------|
| **Alvo** | Rede corporativa simulada TechCorp — `10.10.0.0/24` |
| **Testador** | Daniel Reis |
| **Data** | 2026-10-08 |
| **Ferramenta** | Nmap 7.99 |
| **Ponto de origem** | VPS/host do laboratório (`10.10.0.1`), com acesso direto à bridge Docker do `/24` |

> Metodologia em [metodologia-recon.md](metodologia-recon.md). Saídas brutas em
> [evidencias-nmap/](evidencias-nmap/).

---

## 1. Comandos Executados

| # | Objetivo | Comando | Evidência |
|---|----------|---------|-----------|
| 1 | Descoberta de hosts | `nmap -sn 10.10.0.0/24` | [01-host-discovery.txt](evidencias-nmap/01-host-discovery.txt) |
| 2 | Versão de serviços (top 1000 TCP) | `nmap -sV 10.10.0.0/24` | [02-sv-scan.txt](evidencias-nmap/02-sv-scan.txt) |
| 3 | Todas as portas TCP + scripts | `sudo nmap -sS -sV -sC -p- -T4 10.10.0.10 10.10.0.20 10.10.0.30 10.10.0.40` | [03-full-ports-scripts.txt](evidencias-nmap/03-full-ports-scripts.txt) |
| 4 | Portas UDP (top 50) | `sudo nmap -sU --top-ports 50 -T4 10.10.0.10 10.10.0.20 10.10.0.30 10.10.0.40` | [04-udp-scan.txt](evidencias-nmap/04-udp-scan.txt) |

---

## 2. Hosts Descobertos

5 hosts ativos no `/24` (varredura das 256 endereços):

| Host | Papel | Portas TCP abertas | Portas UDP abertas |
|------|-------|--------------------|--------------------|
| `10.10.0.1` | Gateway / host do lab (a própria VPS) | 2222 (SSH) | — |
| `10.10.0.10` | Target Alpha (privesc) | 22 (SSH) | — |
| `10.10.0.20` | Target Bravo (web + privesc) | 22 (SSH), 80 (HTTP) | — |
| `10.10.0.30` | Servidor corporativo de arquivos (`SRV-FILES01`) | 21 (FTP), 22 (SSH), 53 (DNS), 139/445 (SMB) | 53 (DNS), 137 (NetBIOS-NS) |
| `10.10.0.40` | Corp API | 5000 (HTTP/Werkzeug) | — |

A varredura completa das 65535 portas TCP confirmou que **não há serviços além
dos listados** em nenhum dos quatro alvos (sem portas altas ocultas).

---

## 3. Resultados por Host

### 3.1 `10.10.0.10` — Target Alpha

```
22/tcp open ssh OpenSSH 9.2p1 Debian 2+deb12u10 (protocol 2.0)
```

Apenas SSH exposto. Superfície de rede mínima — o vetor esperado é **acesso
inicial por credenciais** (ex.: reuso das credenciais extraídas da Corp API) e
posterior **escalação de privilégios local** (escopo do Projeto 03).

### 3.2 `10.10.0.20` — Target Bravo

```
22/tcp open ssh  OpenSSH 9.2p1 Debian 2+deb12u10
80/tcp open http Apache httpd 2.4.68 ((Debian))
|_http-title: Apache2 Debian Default Page: It works
```

SSH + Apache exibindo a página padrão do Debian. A página "It works" sugere
**conteúdo web ainda não mapeado** → candidato a força bruta de diretórios
(`gobuster`/`ffuf`) para localizar a aplicação real (possível webshell/entrada
para o Projeto 02/03).

### 3.3 `10.10.0.30` — Servidor Corporativo `SRV-FILES01`

```
21/tcp  open ftp         vsftpd 3.0.3
22/tcp  open ssh         OpenSSH 9.2p1 Debian 2+deb12u10
53/tcp  open domain      ISC BIND 9.18.49-1~deb12u2 (Debian Linux)
139/tcp open netbios-ssn Samba smbd 4
445/tcp open netbios-ssn Samba smbd 4
53/udp  open domain
137/udp open netbios-ns
```

Host mais exposto da rede. Achados relevantes dos scripts:

- **FTP anônimo permitido** (`ftp-anon: Anonymous FTP login allowed (FTP code 230)`),
  com os diretórios `internal/` e `pub/` → acesso direto a arquivos sem credencial.
- **SMB** (Samba 4) como `SRV-FILES01`; assinatura de mensagens habilitada mas
  **não obrigatória** → enumerar compartilhamentos (`smbclient -L`, `enum4linux-ng`).
- **DNS BIND 9.18** servindo a zona interna → candidato a **transferência de zona
  (AXFR)** (item 3 da checklist do projeto).
- **NetBIOS-NS (137/udp)** ativo → enumeração de nomes NetBIOS.

### 3.4 `10.10.0.40` — Corp API

```
5000/tcp open http Werkzeug httpd 3.1.9 (Python 3.11.17)
```

Única porta: a API Flask/Werkzeug. Já avaliada em detalhe — ver
[relatorio-pentest-corp-api.md](relatorio-pentest-corp-api.md).

### 3.5 `10.10.0.1` — Gateway / Host do Lab

```
2222/tcp open ssh OpenSSH 10.2p1 Debian 5 (protocol 2.0)
```

É a própria VPS (host Docker). SSH na porta **2222** e demais portas
filtradas/sem resposta — coerente com o hardening documentado no
[Projeto 05](../05-vps-security-assessment/report.md). Fora do escopo de ataque
do engajamento interno.

---

## 4. Análise e Observações

- **Segmentação mínima no `/24`:** a superfície concentra-se em três alvos
  "úteis" (`.20` web, `.30` arquivos/DNS, `.40` API) mais um host só-SSH (`.10`).
- **SSH homogêneo:** `.10`, `.20` e `.30` rodam OpenSSH 9.2p1 (Debian 12) — sem
  vulnerabilidade de versão conhecida relevante; o vetor é credencial, não exploit.
- **SNMP ausente:** apesar de o escopo do README citar enumeração SNMP com
  community padrão, **161/udp está fechado em todos os hosts** — não há serviço
  SNMP nesta rede. Achado registrado para corrigir a expectativa do escopo.
- **Maior exposição em `.30`:** FTP anônimo + SMB + DNS concentram o risco de
  exposição de dados e de enumeração de rede neste host.

---

## 5. Próximos Passos (derivados das varreduras)

| Alvo | Ação | Projeto/Item |
|------|------|--------------|
| `10.10.0.30` | Transferência de zona DNS (AXFR) no BIND | Item 3 deste projeto |
| `10.10.0.30` | Enumerar FTP anônimo (`internal/`, `pub/`) e shares SMB | Projeto 02 / recon |
| `10.10.0.20` | Força bruta de diretórios no Apache (conteúdo oculto) | Projeto 02 |
| `10.10.0.10/.20` | Testar reuso das credenciais da Corp API via SSH | Projeto 03 |
| Rede | Diagrama de topologia consolidado | Item 4 deste projeto |

---

> **Aviso:** Varreduras executadas em ambiente de laboratório controlado e de
> propriedade do testador. Todos os alvos, hostnames (`SRV-FILES01`, TechCorp) e
> dados são fictícios e não correspondem a sistemas reais.
