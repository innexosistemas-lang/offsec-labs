# Fase 3 — Honeypot (Cowrie) 🟠

> **Meta:** ler um **ataque real** por dentro e fazer **análise de log**.
> Até agora você olhou o host de dentro (saúde/config). Aqui você lê a **mente do atacante**.

## O que é um honeypot
- Um **chamariz** (decoy) de propósito "vulnerável", feito pra **ser atacado** — e que
  **registra tudo** que o atacante faz.
- **Cowrie** é um honeypot de **média interação**: ele *emula* um shell Linux/IoT. O atacante
  acha que entrou num servidor real, mas está numa jaula — **nunca toca o sistema de verdade**.
- No seu lab: Cowrie escuta nas iscas **2223 (SSH)** e **2323 (Telnet)**; o iptables redireciona
  quem bate na **22/23** (as portas "famosas") pra elas. Hostname falso: `srv-web-01`.

## Por que é seguro (e por que isso valida a Fase 1)
- O atacante "loga" e "roda comandos", mas o Cowrie só **simula** as respostas e **grava**.
  Downloads vão pra uma pasta isolada; nada executa de verdade.
- É a materialização da **regra de ouro**: o alvo exposto é uma **isca controlada**; o SSH
  real (2222) continua endurecido e separado. Você *convida* o ataque pra um lugar seguro.

## Como ler os dados
- Log principal: `/opt/cowrie/cowrie/var/log/cowrie/cowrie.json` (um JSON por linha; rotaciona
  por dia: `cowrie.json.AAAA-MM-DD`).
- Eventos-chave (`eventid`):
  | eventid | significa |
  |---|---|
  | `cowrie.session.connect` | alguém conectou (IP de origem) |
  | `cowrie.login.failed` / `.success` | tentativa de credencial (usuário/senha) |
  | `cowrie.command.input` | **comando digitado** depois de "entrar" ← o ouro |
  | `cowrie.session.file_download` | tentou **baixar** um arquivo (malware) |
  | `cowrie.client.version` | banner do cliente SSH do atacante (pista de atribuição) |
- `jq` NÃO está instalado no VPS → use **`python3`** pra agregar (ver fase3-explore.sh).
- Replay de sessão (assistir o atacante digitar): `cowrie-env/bin/playlog var/lib/cowrie/tty/<arquivo>`.

## Anatomia de um ataque de botnet (o que você capturou)
A maioria dos ataques é **automática** (botnet estilo **Mirai/Gafgyt** mirando IoT). O padrão:
1. **Brute-force** de credenciais **default** (root/admin, admin/admin123, root/123456,
   `xmhdipc`, `telecomadmin/admintelecom` — senhas de fábrica de câmeras/DVRs/roteadores).
2. **Recon**: `/bin/busybox` (existe?), `/bin/busybox HISILICON`/`PBOC` (que tipo de device é?).
3. **Caça a diretório gravável**: `echo > /tmp/.b && sh /tmp/.b && cd /tmp/` repetido em
   /tmp, /var, /dev, /mnt... procurando onde conseguir **escrever** o payload.
4. **Drop + execução**: `chmod +x .d; ./.d; ./dvrHelper selfrep` (dvrHelper = variante Mirai;
   `selfrep` = auto-replicar pra outros dispositivos).
5. **Anti-concorrência**: escreve um script (`.k`) via `echo -ne "\x.."` (byte a byte, pra
   driblar filtro de download) que varre `/proc` e **mata outros malwares** no device.

## Pistas de atribuição (IOCs)
- **Cliente SSH `libssh_0.9.5`** em massa = **script/bot**, não humano (humano usaria OpenSExH/PuTTY).
- **Dicionário de senhas** = assinatura do Mirai.
- **Strings `dvrHelper`, `HISILICON`, `PBOC`** = família de botnet de IoT/DVR.
- Técnica `echo -ne "\x.."` = escrever binário/script **inline**, sem baixar (evasão).

## O que você precisa entender ao final
1. O que é honeypot e por que o Cowrie é seguro (emulação + isolamento).
2. Como o redirect 22→2223 transforma a porta "famosa" em isca.
3. Ler a cadeia de um ataque: conexão → brute-force → recon → caça a dir → drop → persistência.
4. Tirar **IOCs** dos dados (IP, credencial, hash de malware, string de família).
5. Por que o volume é quase todo **bot automático**, não humano.

## Exercícios
- [ ] Qual o IP que mais atacou e quantas conexões? O cliente SSH dele é humano ou bot? Como sabe?
- [ ] Liste 3 credenciais default testadas e diga a que tipo de device elas pertencem.
- [ ] Na sessão mais ativa, descreva em 3 frases o que o atacante tentou fazer, em ordem.
- [ ] O que a técnica `echo -ne "\x.."` tenta evitar?

## Próxima fase
**Fase 4 — SIEM (Wazuh):** decoders→regras→alertas, correlação, MITRE ATT&CK.
