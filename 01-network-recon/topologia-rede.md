# Topologia da Rede — TechCorp (`10.10.0.0/24`)

Diagrama consolidado do reconhecimento: hosts ativos confirmados por Nmap +
hosts revelados pela transferência de zona DNS + serviços por host.

> Fontes: [varreduras-nmap.md](varreduras-nmap.md) e
> [transferencia-zona-dns.md](transferencia-zona-dns.md).

---

## Diagrama

```mermaid
flowchart TB
    KALI["Kali Linux<br/>estacao de ataque"]
    KALI -->|"SSH + tuneis (autossh)"| GW

    subgraph LAB["Rede TechCorp - 10.10.0.0/24 (bridge Docker 'pentestlab')"]
        direction TB
        GW["10.10.0.1<br/>Gateway / host do lab<br/>SSH:2222 (hardened)"]

        subgraph LIVE["Hosts ativos - confirmados por Nmap"]
            direction LR
            H10["10.10.0.10<br/>Target Alpha<br/>SSH:22"]
            H20["10.10.0.20 - srv-web01<br/>SSH:22 | HTTP:80 Apache"]
            H30["10.10.0.30 - srv-files01 / ns1<br/>FTP:21 anon | SSH:22<br/>DNS:53 | SMB:139,445 | NetBIOS:137"]
            H40["10.10.0.40 - srv-db01<br/>Corp API<br/>HTTP:5000 Werkzeug"]
        end

        subgraph DNSONLY["Revelados pela transferencia de zona - nao vivos no scan"]
            direction LR
            V50["10.10.0.50<br/>vpn"]
            V60["10.10.0.60<br/>mail"]
            V70["10.10.0.70<br/>jenkins"]
            V80["10.10.0.80<br/>gitlab"]
            V90["10.10.0.90<br/>dev"]
            V91["10.10.0.91<br/>staging"]
        end
    end

    GW --- H10
    GW --- H20
    GW --- H30
    GW --- H40
    H30 -.->|"AXFR vaza o mapa"| DNSONLY

    classDef live fill:#1b5e20,stroke:#a5d6a7,color:#fff;
    classDef dns fill:#37474f,stroke:#90a4ae,color:#fff,stroke-dasharray:5 3;
    classDef infra fill:#0d47a1,stroke:#90caf9,color:#fff;
    classDef atk fill:#b71c1c,stroke:#ef9a9a,color:#fff;

    class KALI atk;
    class GW infra;
    class H10,H20,H30,H40 live;
    class V50,V60,V70,V80,V90,V91 dns;
```

**Legenda:** 🟥 estação de ataque · 🟦 infraestrutura/gateway · 🟩 host ativo
(confirmado por Nmap) · ⬛ (tracejado) host só conhecido via DNS, não respondeu
ao scan.

---

## Inventário de Hosts

| IP | Nome(s) DNS | Serviços | Estado | Papel |
|----|-------------|----------|--------|-------|
| 10.10.0.1 | — | SSH:2222 | Ativo | Gateway / host Docker do lab |
| 10.10.0.10 | — | SSH:22 | Ativo | Target Alpha (privesc) |
| 10.10.0.20 | srv-web01 | SSH:22, HTTP:80 | Ativo | Servidor web (Apache) |
| 10.10.0.30 | srv-files01, ns1, intranet, backup, admin | FTP:21, SSH:22, DNS:53, SMB:139/445, NetBIOS:137 | Ativo | Servidor de arquivos + DNS |
| 10.10.0.40 | srv-db01 | HTTP:5000 | Ativo | Corp API (Werkzeug/Flask) |
| 10.10.0.50 | vpn | — | Só DNS | Concentrador VPN |
| 10.10.0.60 | mail | — | Só DNS | Servidor de email |
| 10.10.0.70 | jenkins | — | Só DNS | CI/CD Jenkins |
| 10.10.0.80 | gitlab | — | Só DNS | Repositório GitLab |
| 10.10.0.90 | dev | — | Só DNS | Ambiente de desenvolvimento |
| 10.10.0.91 | staging | — | Só DNS | Ambiente de homologação |

---

## Redes Irmãs (fora do escopo do Projeto 01)

O host do lab também faz bridge para outras duas redes Docker, identificadas
durante o mapeamento mas fora do escopo deste projeto:

- `10.20.0.0/24` — rede `pentestlab-web`
- `10.10.1.0/24` — rede `windows-sim` (ambiente Windows / Active Directory)

---

> **Aviso:** Topologia de ambiente de laboratório controlado e de propriedade do
> testador. Todos os IPs, hostnames e dados são fictícios.
