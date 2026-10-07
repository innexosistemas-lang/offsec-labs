# Pentest Lab —  Modelo de Referência

> **O que é este arquivo:** um modelo de exemplo, sem dados da .
>  Para usar: copie este modelo
> e preencha os valores reais localmente.
>
> ```bash
> cp lab-reference.example.md lab-reference.md   # e edite os <PLACEHOLDERS>
> ```

> **Pré-requisito dos túneis:** se o sshd da VPS tiver `AllowTcpForwarding no`
> (comum em hardening), libere-o só para o usuário do lab com um bloco
> `Match User <USUARIO> → AllowTcpForwarding yes`. Sem isso, `LocalForward`/
> `DynamicForward` são rejeitados e todo acesso via `localhost:*` dá
> "conexão redefinida". Prefira `autossh` ao `ssh -fN`: o `-fN` não reconecta
> e vira túnel-zumbi em links instáveis.

### Exemplo de `~/.ssh/config`

```
Host lab-tunnels
    HostName <VPS_IP>
    User <USUARIO>
    Port <SSH_PORT>
    IdentityFile ~/.ssh/<SUA_CHAVE>
    ServerAliveInterval 15
    ServerAliveCountMax 3
    LocalForward 8080 127.0.0.1:8080
    LocalForward 3000 127.0.0.1:3000
    LocalForward 8888 127.0.0.1:8888
    LocalForward 5000 127.0.0.1:5000
    DynamicForward 1080
    ExitOnForwardFailure yes
```

## VPS

- **IP:** `<VPS_IP>`
- **Porta SSH:** `<SSH_PORT>`
- **Usuário:** `<USUARIO>` (sudo)
- **Auth:** chave SSH 
- **OS:** Kali Linux
- **Recursos:** 4 vCPU, 16 GB RAM, 200 GB disco

## Alvos Web

| Alvo | Acesso local | Credenciais |
|------|-------------|-------------|
| DVWA | http://localhost:8080 | 
| Juice Shop | http://localhost:3000 |
| Corp API | http://localhost:5000 | SQLi bypass
| Target Bravo (Apache) | http://localhost:8888 | webshell

## Alvos Linux (via proxychains)

| Alvo | IP | SSH | Credenciais |
|------|----|----|-------------|
| Target Alpha | 10.10.0.10 | porta 22 | `<USUARIO>` / `<SENHA>` |
| Target Bravo | 10.10.0.20 | porta 22 | `<USUARIO>` / `<SENHA>` |

## Servidor Corporativo (10.10.0.30)

| Serviço | Porta | Detalhe |
|---------|-------|---------|
| FTP | 21 | anonymous login |
| SSH | 22 | `<USUARIO>` / `<SENHA>` |
| DNS | 53 | zone transfer: `dig @10.10.0.X <DOMINIO> AXFR` |
| SMB | 445 | shares com guest / credenciais |
| SNMP | 161/udp | community: `<COMMUNITY>` |

## API Vulnerável (Corp API — `10.10.0.40:5000` / `localhost:5000`)

> Dual-homed: na rede interna `pentestlab` (via proxychains) **e**
> na bridge `pentestlab-web`, que publica a porta da VPS
> para o túnel.

| Endpoint | Vulnerabilidade |
|----------|----------------|
| POST /api/v1/login | SQL Injection |
| GET /api/v1/users/\<id\> | IDOR |
| PUT /api/v1/users/\<id\> | Mass assignment (role) |
| GET /api/v1/debug | Info disclosure (secret key) |
| GET /api/v1/projects/search?q= | SQL Injection |
| JWT | Secret: `<JWT_SECRET>` |

## Ambiente Windows Simulado (rede 10.10.1.x)

| Serviço | Porta | Detalhe |
|---------|-------|---------|
| LDAP | 389 | Enum users, groups, SPNs |
| Kerberos | 88 | Kerberoasting, AS-REP roast |
| SMB | 445 | Domain shares, SYSVOL |
| DNS | 53 | Domain DNS |

Contas de serviço / usuários: ver arquivo real (preencher localmente).
Vulnerabilidades típicas: Kerberoasting, AS-REP Roasting, senhas fracas.

### MSSQL Server (10.10.1.20)

| Serviço | Porta | Credenciais |
|---------|-------|-------------|
| MSSQL | 1433 | `<USUARIO>` / `<SENHA>` |


### File Server 

| Share | Acesso | Conteúdo (lab) |
|-------|--------|----------------|
| Public | Guest | arquivo com senha de wifi |
| IT | credenciais | scripts de deploy, inventário |
| HR | credenciais | PII (employees.csv) |
| Backup | credenciais | hashes NTLM (sam.bak) |

## Redes Docker

| Rede | Subnet | Uso |
|------|--------|-----|
| pentestlab | 10.10.0.0/24 (interna) | Alvos Linux + servidor corporativo (10.10.0.30/40) |
| pentestlab-web | 10.20.0.0/24 (bridge) | DVWA, Juice Shop, corp-api (dual-homed) |
| pentestlab-win | 10.10.1.0/24 (interna) | Ambiente Windows simulado |

> Redes `internal` do Docker **não publicam portas no host** — alvos nelas só
> são alcançáveis via SOCKS/proxychains. Para expor um alvo em `localhost:*`
> pelo túnel, ele precisa estar também na bridge `pentestlab-web`
> (foi o caso do corp-api).


