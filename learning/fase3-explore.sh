#!/usr/bin/env bash
# ============================================================
#  FASE 3 — HONEYPOT (Cowrie)  |  Tour guiado (somente leitura)
#  Rode no NOTEBOOK:   bash fase3-explore.sh
#  Pré-requisito: 'ssh lab' configurado (~/.ssh/config)
#  Lê os logs de ataque REAL do Cowrie. Não altera nada.
# ============================================================
set -uo pipefail
SSH="ssh -o ConnectTimeout=20 -o ConnectionAttempts=6 -o BatchMode=yes lab"
pause(){ echo; read -rp "   ⏎  [Enter para continuar] "; echo; }
sec(){ echo; echo "============================================================"; echo "  $1"; echo "============================================================"; }

$SSH 'true' 2>/dev/null || { echo "❌ Não conectou no lab."; exit 1; }

sec "0) Cowrie está capturando?"
$SSH 'echo "   servico: $(systemctl is-active cowrie)"; echo "   arquivos de log:"; sudo ls /opt/cowrie/cowrie/var/log/cowrie/cowrie.json* | sed "s/^/     /"'
echo "   📖 Cowrie emula um shell nas iscas 2223/2323; o iptables manda a 22/23 pra ele."
pause

sec "1..N) Panorama do ataque (IPs, credenciais, comandos, downloads, IOCs)"
# roda a análise como root no servidor (python3; jq não existe lá)
$SSH 'sudo python3 -' <<'PYEOF'
import json, glob, collections
files=sorted(glob.glob("/opt/cowrie/cowrie/var/log/cowrie/cowrie.json*"))
evt=collections.Counter(); ip=collections.Counter(); creds=collections.Counter()
cmds=collections.Counter(); dl=collections.Counter(); cli=collections.Counter()
scmd=collections.defaultdict(list); sip={}
for f in files:
    with open(f,encoding="utf-8",errors="replace") as fh:
        for ln in fh:
            ln=ln.strip()
            if not ln: continue
            try: e=json.loads(ln)
            except Exception: continue
            k=e.get("eventid","?"); evt[k]+=1
            s=e.get("session"); a=e.get("src_ip")
            if a and s: sip[s]=a
            if k=="cowrie.session.connect" and a: ip[a]+=1
            elif k=="cowrie.login.success": creds[(e.get("username"),e.get("password"))]+=1
            elif k=="cowrie.command.input":
                c=(e.get("input") or "").strip()
                if c:
                    cmds[c]+=1
                    if s: scmd[s].append(c)
            elif k.startswith("cowrie.session.file_"):
                dl[e.get("url") or e.get("shasum") or "?"]+=1
            elif k=="cowrie.client.version": cli[e.get("version") or "?"]+=1
print("== TOP 8 IPs atacantes =="); [print(f"  {v:>6}  {a}") for a,v in ip.most_common(8)]
print("\n== TOP 10 credenciais (user/senha) =="); [print(f"  {v:>5}  {u} / {p}") for (u,p),v in creds.most_common(10)]
print("\n== TOP 12 comandos pos-login =="); [print(f"  {v:>5}  {c[:80]}") for c,v in cmds.most_common(12)]
print("\n== clientes SSH (bot vs humano?) =="); [print(f"  {v:>5}  {c}") for c,v in cli.most_common(6)]
if scmd:
    b=max(scmd,key=lambda s:len(scmd[s]))
    print(f"\n== SESSAO MAIS ATIVA {b} (ip {sip.get(b,'?')}, {len(scmd[b])} cmds) ==")
    [print(f"  {i:>2}. {c[:100]}") for i,c in enumerate(scmd[b][:25],1)]
PYEOF
echo
echo "   ❓ O IP que mais atacou usa cliente humano ou bot? Que família o padrão lembra?"
pause

sec "✅ Fim da Fase 3 — Honeypot"
echo "   Você leu um ataque de botnet REAL: brute-force -> recon -> caça a diretório"
echo "   -> drop de payload -> persistência. Próxima: FASE 4 — SIEM (Wazuh)."
echo
