# Relatório de Avaliação de Segurança — Hardening de VPS

| Campo | Valor |
|-------|-------|
| **Alvo** | VPS em nuvem (Kali Linux 2026.1) |
| **Tipo de Engajamento** | Avaliação de Segurança de Infraestrutura |
| **Testador** | Daniel Reis |
| **Data** | 2026-10-07 |
| **Versão** | 1.0 |
| **Classificação** | Portfólio / Educacional |

---

## 1. Sumário Executivo

Foi conduzida uma avaliação de segurança em uma VPS em nuvem recém-provisionada executando Kali Linux 2026.1. A configuração inicial apresentava diversas fraquezas de segurança significativas, comuns em implantações padrão em nuvem, incluindo acesso SSH como root, autenticação baseada em senha, ausência de regras de firewall e nenhuma proteção contra força bruta.

Foram identificadas sete descobertas, variando de severidade Alta a Baixa. Todas as descobertas foram remediadas durante o engajamento, reduzindo a superfície de ataque de uma configuração padrão exposta para uma baseline endurecida e de nível de produção.

**Classificação de Risco Geral (Antes):** Alta
**Classificação de Risco Geral (Depois):** Baixa

| Severidade | Encontradas | Remediadas |
|------------|-------------|------------|
| Alta | 3 | 3 |
| Média | 2 | 2 |
| Baixa | 1 | 1 |
| Informativa | 1 | 1 |

---

## 2. Escopo

### 2.1 Dentro do Escopo

| Alvo | Tipo | Endereço |
|------|------|----------|
| VPS em nuvem | Servidor Linux | [REMOVIDO] |

### 2.2 Regras de Engajamento

- Acesso administrativo total (proprietário autorizado)
- Avaliação e remediação no mesmo engajamento
- Nenhum sistema de terceiros envolvido

---

## 3. Metodologia

A avaliação seguiu uma abordagem estruturada baseada nos CIS Benchmarks e no NIST SP 800-123 (Guide to General Server Security):

1. **Auditoria Inicial** — documentar o estado da configuração padrão
2. **Identificação de Vulnerabilidades** — avaliar cada serviço e configuração
3. **Remediação** — aplicar medidas de hardening
4. **Verificação** — confirmar que cada correção é efetiva
5. **Documentação** — produzir descobertas e evidências

---

## 4. Descobertas

### 4.1 [DESCOBERTA-001] — Login SSH como Root Habilitado

| Campo | Valor |
|-------|-------|
| **Severidade** | Alta |
| **Nota CVSS** | 7.5 |
| **CWE** | CWE-250 — Execution with Unnecessary Privileges |
| **Ativo Afetado** | Serviço SSH (porta 22) |
| **Status** | Remediado |

**Descrição:**

O serviço SSH estava configurado com `PermitRootLogin yes`, permitindo autenticação direta na conta root pela rede.

**Impacto:**

Um atacante que obtenha as credenciais de root (via força bruta, credential stuffing ou comprometimento de chave) ganha controle total e imediato do sistema, sem qualquer etapa de escalação de privilégios.

**Evidência:**

Antes:
```
$ grep PermitRootLogin /etc/ssh/sshd_config
PermitRootLogin yes
```

**Remediação Aplicada:**

1. Criado um usuário administrativo dedicado (`pentester`) com privilégios de sudo
2. Copiadas as chaves SSH autorizadas para o novo usuário
3. Definido `PermitRootLogin no` na configuração do SSH
4. Adicionado `AllowUsers pentester` para restringir o acesso SSH

```
$ grep -E "PermitRootLogin|AllowUsers" /etc/ssh/sshd_config.d/hardening.conf
PermitRootLogin no
AllowUsers pentester
```

---

### 4.2 [DESCOBERTA-002] — SSH na Porta Padrão sem Limitação de Taxa

| Campo | Valor |
|-------|-------|
| **Severidade** | Alta |
| **Nota CVSS** | 7.1 |
| **CWE** | CWE-307 — Improper Restriction of Excessive Authentication Attempts |
| **Ativo Afetado** | Serviço SSH (porta 22) |
| **Status** | Remediado |

**Descrição:**

O SSH estava escutando na porta padrão 22 sem nenhum mecanismo de proteção contra força bruta. Scanners automatizados sondam constantemente a porta 22 em todos os endereços IP públicos.

**Impacto:**

O servidor estava exposto a ataques automatizados de força bruta e credential stuffing. Combinado com a autenticação por senha (Descoberta 003), isso aumentava significativamente a probabilidade de acesso não autorizado.

**Evidência:**

Antes:
```
$ ss -tlnp | grep ssh
LISTEN 0 128 0.0.0.0:22 0.0.0.0:* users:(("sshd",...))

$ systemctl status fail2ban
Unit fail2ban.service could not be found.
```

**Remediação Aplicada:**

1. Alterada a porta SSH de 22 para 2222
2. Instalado e configurado o fail2ban (3 tentativas falhas = banimento de 2 horas)
3. Definidos `MaxAuthTries 3` e `LoginGraceTime 30` na configuração do SSH

```
$ grep "^Port" /etc/ssh/sshd_config.d/hardening.conf
Port 2222

$ fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- Journal matches:  _SYSTEMD_UNIT=ssh.service + _COMM=sshd
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

---

### 4.3 [DESCOBERTA-003] — Autenticação por Senha Habilitada

| Campo | Valor |
|-------|-------|
| **Severidade** | Alta |
| **Nota CVSS** | 7.5 |
| **CWE** | CWE-521 — Weak Password Requirements |
| **Ativo Afetado** | Serviço SSH |
| **Status** | Remediado |

**Descrição:**

Embora a autenticação baseada em chave estivesse configurada, a configuração inicial do provedor de nuvem também mantinha a autenticação por senha como alternativa (fallback). O usuário padrão `kali` possuía uma senha padrão conhecida.

**Impacto:**

A autenticação por senha torna o servidor vulnerável a ataques de força bruta. As credenciais padrão do usuário `kali` são publicamente documentadas.

**Remediação Aplicada:**

1. Confirmado `PasswordAuthentication no` na configuração do SSH
2. Definido `AuthenticationMethods publickey` para impor acesso somente por chave
3. Removida completamente a conta de usuário padrão `kali`

```
$ grep -E "PasswordAuthentication|AuthenticationMethods" /etc/ssh/sshd_config.d/hardening.conf
PasswordAuthentication no
AuthenticationMethods publickey

$ id kali
id: 'kali': no such user
```

---

### 4.4 [DESCOBERTA-004] — Nenhum Firewall Configurado

| Campo | Valor |
|-------|-------|
| **Severidade** | Média |
| **Nota CVSS** | 5.3 |
| **CWE** | CWE-284 — Improper Access Control |
| **Ativo Afetado** | Perímetro de Rede |
| **Status** | Remediado |

**Descrição:**

Nenhum firewall baseado em host estava configurado. Todos os serviços vinculados a 0.0.0.0 ficavam acessíveis a partir da internet pública.

**Impacto:**

Qualquer serviço iniciado na VPS (intencionalmente ou não) ficaria imediatamente exposto à internet, aumentando a superfície de ataque.

**Remediação Aplicada:**

Instalado e configurado o UFW com uma política padrão de negação para entrada (default-deny):

```
$ ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
2222/tcp                   ALLOW IN    Anywhere    # SSH-hardened
```

---

### 4.5 [DESCOBERTA-005] — Sem Atualizações de Segurança Automáticas

| Campo | Valor |
|-------|-------|
| **Severidade** | Média |
| **Nota CVSS** | 5.0 |
| **CWE** | CWE-1104 — Use of Unmaintained Third Party Components |
| **Ativo Afetado** | Sistema Operacional |
| **Status** | Remediado |

**Descrição:**

O sistema não possuía mecanismo para instalação automática de patches de segurança. Vulnerabilidades críticas em pacotes instalados permaneceriam sem correção até serem atualizadas manualmente.

**Impacto:**

CVEs conhecidas em pacotes do sistema poderiam ser exploradas caso os patches não fossem aplicados prontamente.

**Remediação Aplicada:**

Instalado o `unattended-upgrades` com verificações diárias de atualizações de segurança:

```
$ cat /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
```

---

### 4.6 [DESCOBERTA-006] — Conta de Usuário Padrão Desnecessária

| Campo | Valor |
|-------|-------|
| **Severidade** | Baixa |
| **Nota CVSS** | 3.1 |
| **CWE** | CWE-798 — Use of Hard-coded Credentials |
| **Ativo Afetado** | Contas de Usuário |
| **Status** | Remediado |

**Descrição:**

O usuário padrão `kali` (UID 1000) estava presente com participação no grupo sudo. Instalações padrão do Kali usam credenciais conhecidas para essa conta.

**Remediação Aplicada:**

Removido o usuário e seu diretório home:

```
$ userdel -r kali
```

---

### 4.7 [DESCOBERTA-007] — Divulgação de Informações pelo SSH

| Campo | Valor |
|-------|-------|
| **Severidade** | Informativa |
| **Nota CVSS** | 0.0 |
| **CWE** | CWE-200 — Exposure of Sensitive Information |
| **Ativo Afetado** | Serviço SSH |
| **Status** | Remediado |

**Descrição:**

O SSH expunha recursos desnecessários que poderiam auxiliar o reconhecimento: o encaminhamento X11 estava habilitado e o encaminhamento TCP era irrestrito.

**Remediação Aplicada:**

Desabilitados recursos desnecessários do SSH:

```
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
```

---

## 5. Resumo de Remediação

| ID | Descoberta | Severidade | Remediação | Status |
|----|------------|------------|------------|--------|
| 001 | Login SSH como Root | Alta | Desabilitado, criado usuário admin | Concluído |
| 002 | Porta Padrão / Sem Limite de Taxa | Alta | Porta 2222, fail2ban | Concluído |
| 003 | Autenticação por Senha | Alta | Somente chave, removido usuário padrão | Concluído |
| 004 | Sem Firewall | Média | UFW default-deny | Concluído |
| 005 | Sem Atualizações Automáticas | Média | unattended-upgrades | Concluído |
| 006 | Conta de Usuário Padrão | Baixa | Removido usuário `kali` | Concluído |
| 007 | Divulgação de Informações SSH | Info | Desabilitado encaminhamento X11/TCP | Concluído |

---

## 6. Conclusão

A VPS foi endurecida com sucesso, de um estado padrão de alto risco para uma configuração baseline segura. Todas as sete descobertas identificadas foram remediadas. O servidor agora implementa defesa em profundidade com:

- **Autenticação:** somente por chave, sem root, um único usuário autorizado
- **Rede:** firewall com default-deny, porta SSH não padrão
- **Monitoramento:** fail2ban para detecção de força bruta e resposta automatizada
- **Manutenção:** atualizações de segurança automáticas habilitadas

### Recomendações para Segurança Contínua

1. Revisar periodicamente os logs do fail2ban em busca de padrões de ataque
2. Monitorar os logs do `unattended-upgrades` em busca de atualizações com falha
3. Realizar auditorias periódicas de configuração contra os CIS benchmarks
4. Considerar a implementação de encaminhamento de logs para um SIEM central

---

## Apêndice A — Ferramentas Utilizadas

| Ferramenta | Finalidade |
|------------|------------|
| Nmap / ss | Descoberta de portas e serviços |
| UFW | Gerenciamento de firewall baseado em host |
| fail2ban | Prevenção de força bruta |
| ssh-keygen | Geração de par de chaves |
| systemctl | Gerenciamento e auditoria de serviços |

## Apêndice B — Arquivos de Configuração

- `/etc/ssh/sshd_config.d/hardening.conf` — Hardening do SSH
- `/etc/fail2ban/jail.local` — Jail SSH do fail2ban
- `/etc/apt/apt.conf.d/20auto-upgrades` — Atualizações automáticas
