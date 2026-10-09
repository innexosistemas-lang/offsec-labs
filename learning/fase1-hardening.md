# Fase 1 — Hardening 🟢

> **Meta:** entender o *porquê* de cada camada de proteção do servidor.
> Hardening = reduzir a **superfície de ataque** e encarecer a vida do atacante.
> É a base de segurança do NOC e o ponto de partida do SOC.

## Por que isso é a base
Um analista NOC/SOC precisa saber **o que é o "normal e seguro"** de um host antes de
detectar o anormal. Hardening é esse normal: menos portas, menos formas de entrar,
atualização automática e bloqueio de quem insiste. Tudo isso **já está construído** no
VPS — nesta fase você aprende a *ler e justificar* cada decisão.

## Os 4 pilares (e o porquê de cada um)

### 1. SSH endurecido
A porta de entrada do admin. Cada ajuste remove uma classe de ataque:
| Ajuste | O que faz | Por que importa |
|---|---|---|
| **Porta 2222** (não 22) | muda a porta padrão | tira você do "ruído" dos bots que varrem a 22 o dia todo; a 22 virou **isca** (Cowrie) |
| `PermitRootLogin no` | root não loga por SSH | o alvo mais óbvio (usuário que sempre existe) fica inalcançável |
| `PasswordAuthentication no` | só chave, sem senha | mata **brute-force** e **password spray** de raiz: não há senha pra adivinhar |
| `AllowUsers pentester` | só esse usuário loga | lista de permissão: qualquer outro login é recusado antes de tentar |
| `MaxAuthTries 3` | 3 tentativas por conexão | corta sessões que ficam "chutando" credenciais |

> ⚠️ **Gotcha Ubuntu 26.04 (socket activation):** `sshd -T` mostra `port 22`, mas o SSH
> escuta mesmo na **2222**. Quem define a porta é o **`ssh.socket`** (systemd), não o
> `sshd_config`. Confira com `ss -ltnp | grep ssh`, não confie só no `sshd -T`.

### 2. Firewall `ufw` — default deny
Regra de ouro: **nega tudo, libera o mínimo.**
- `Default: deny (incoming)` → nada entra, a menos que explicitamente liberado.
- Liberado p/ internet: `2222` (SSH admin), `2223/2323` (iscas Cowrie), `80/443` (site).
- Wazuh/Zabbix/Grafana/DVWA/AD **nunca** entram no ufw → só por **túnel SSH** (isolados).
- Pensamento NOC: "cada porta aberta é uma porta que alguém precisa defender e monitorar".

### 3. `fail2ban` — bloqueio automático
Lê os logs, e quem falha demais leva **ban** temporário no firewall.
- Conceito de **jail**: um filtro (que erro procurar) + uma ação (banir) + limites
  (`maxretry`, `findtime`, `bantime`).
- Jail `sshd`: X falhas em Y tempo → IP banido por Z tempo.
- Também há jails de nginx (bad-request, botsearch, http-auth, limit-req).
- Por que importa mesmo com senha desligada: reduz ruído, barra scanners e protege
  outros serviços (web).

### 4. `unattended-upgrades` — patch automático
- Aplica **atualizações de segurança** sozinho.
- Por quê: a maioria dos comprometimentos usa falha **conhecida e já corrigida**.
  Patch em dia fecha essa janela sem depender de alguém lembrar.

## Como fazer (no notebook)
Rode o tour guiado read-only (não altera nada):

```bash
bash fase1-explore.sh
```

## O que você precisa entender ao final
1. Nomear os 5 ajustes de SSH e **o ataque que cada um corta**.
2. Explicar `default deny` e por que só 5 portas estão abertas.
3. Explicar o que é uma **jail** do fail2ban (filtro + ação + limites).
4. Por que patch automático fecha a janela mais explorada na prática.
5. O gotcha do socket activation: quem realmente manda na porta do SSH.

## Exercícios (responda/anote)
- [ ] Desliguei senha e root no SSH. Que dois ataques isso elimina de vez?
- [ ] A 22 está "aberta" pra internet? Pra onde vai quem bate nela?
- [ ] Se um IP erra a chave 10 vezes, o que acontece — e qual componente faz isso?
- [ ] `sshd -T` diz `port 22`. O SSH está na 22? Como provo o contrário?
- [ ] Por que Wazuh/Zabbix não aparecem no `ufw status`?

## Comandos-chave
| Comando | Pra que serve |
|---|---|
| `sudo sshd -T` | config efetiva do SSH (cuidado com a porta no 26.04) |
| `ss -ltnp \| grep ssh` | em que porta o SSH **realmente** escuta |
| `sudo ufw status verbose` | política do firewall + portas liberadas |
| `sudo fail2ban-client status` | lista de jails ativas |
| `sudo fail2ban-client status sshd` | falhas/bans da jail do SSH |
| `systemctl is-active unattended-upgrades` | patch automático ligado? |

## Próxima fase
**Fase 2 — NOC/Monitoração:** Zabbix + Grafana — aprender o "normal"/baseline de um host.
