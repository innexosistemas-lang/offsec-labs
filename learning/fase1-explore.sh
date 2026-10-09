#!/usr/bin/env bash
# ============================================================
#  FASE 1 — HARDENING  |  Tour guiado (somente leitura)
#  Rode no NOTEBOOK:   bash fase1-explore.sh
#  Pré-requisito: 'ssh lab' configurado (~/.ssh/config)
#  Nada aqui altera o servidor — é só para ENTENDER as proteções.
# ============================================================
set -uo pipefail
SSH="ssh -o ConnectTimeout=20 -o ConnectionAttempts=6 -o BatchMode=yes lab"

pause(){ echo; read -rp "   ⏎  [Enter para continuar] "; echo; }
sec(){ echo; echo "============================================================"; echo "  $1"; echo "============================================================"; }
run(){ echo "   \$ $2"; echo; $SSH "$2"; }

$SSH 'true' 2>/dev/null || { echo "❌ Não conectou no lab. Confira ~/.ssh/config e a chave."; exit 1; }

sec "1) SSH endurecido — config efetiva"
run x 'sudo sshd -T 2>/dev/null | grep -Ei "^(port|permitrootlogin|passwordauthentication|maxauthtries|allowusers|pubkeyauthentication) "'
echo
echo "   📖 Cada linha corta uma classe de ataque:"
echo "      permitrootlogin no        -> tira o alvo óbvio (root)"
echo "      passwordauthentication no -> mata brute-force/spray (não há senha)"
echo "      allowusers pentester      -> só esse usuário loga (lista de permissão)"
echo "      maxauthtries 3            -> corta quem fica 'chutando' na mesma conexão"
echo "   ❓ PERGUNTE-SE: desligar senha + root elimina QUAIS ataques de vez?"
pause

sec "2) GOTCHA do Ubuntu 26.04 — onde o SSH ESCUTA de verdade"
run x 'echo "sshd -T diz:   port $(sudo sshd -T 2>/dev/null | awk "/^port /{print \$2}")"; echo "mas escuta em:"; sudo ss -ltnp | grep -E "sshd|ssh" | awk "{print \"   \"\$4}"'
echo
echo "   📖 No 26.04 quem define a porta é o ssh.socket (systemd), não o sshd_config."
echo "      Por isso 'sshd -T' mostra 22, mas o serviço escuta na 2222."
echo "   ❓ EXERCÍCIO: como você PROVA em que porta o SSH realmente está?"
pause

sec "3) Firewall ufw — default deny, libera o mínimo"
run x 'sudo ufw status verbose | grep -E "Default|ALLOW" | grep -v v6'
echo
echo "   📖 'Default: deny (incoming)' = nada entra, salvo o que foi liberado."
echo "      2222=SSH | 2223/2323=iscas Cowrie | 80/443=site. Só isso é público."
echo "      Wazuh/Zabbix/Grafana/DVWA/AD NÃO aparecem -> zona isolada (só túnel)."
echo "   ❓ PERGUNTE-SE: por que cada porta aberta é um custo de defesa/monitoração?"
pause

sec "4) fail2ban — quem insiste, leva ban"
run x 'echo "Jails ativas:"; sudo fail2ban-client status | awk -F: "/Jail list/{print \"   \"\$2}"; echo; echo "Jail sshd (limites + bans):"; sudo fail2ban-client get sshd maxretry 2>/dev/null | sed "s/^/   maxretry=/"; sudo fail2ban-client get sshd findtime 2>/dev/null | sed "s/^/   findtime=/"; sudo fail2ban-client get sshd bantime 2>/dev/null | sed "s/^/   bantime=/"; sudo fail2ban-client status sshd | grep -E "Total failed|Currently banned|Banned IP"'
echo
echo "   📖 Jail = filtro (que erro procurar) + ação (banir) + limites."
echo "      Ex.: maxretry falhas em findtime segundos -> ban por bantime segundos."
echo "   ❓ EXERCÍCIO: se um IP falha além do maxretry, QUEM o bloqueia e por quanto tempo?"
pause

sec "5) unattended-upgrades — patch automático"
run x 'echo "estado: $(systemctl is-enabled unattended-upgrades) / $(systemctl is-active unattended-upgrades)"; echo "última execução (log):"; sudo tail -n 2 /var/log/unattended-upgrades/unattended-upgrades.log 2>/dev/null || echo "   (sem log ainda)"'
echo
echo "   📖 Aplica atualizações de SEGURANÇA sozinho. A maioria dos ataques usa"
echo "      falha CONHECIDA e já corrigida — patch em dia fecha essa janela."
echo "   ❓ PERGUNTE-SE: por que isso reduz risco sem depender de alguém lembrar?"
pause

sec "✅ Fim da Fase 1 — Hardening"
echo "   Você revisou: SSH endurecido, o gotcha do socket, ufw default-deny,"
echo "   fail2ban (jails) e patch automático."
echo
echo "   Responda as 5 perguntas ❓ acima. Depois fazemos o teste de consolidação"
echo "   e seguimos para a FASE 2 — NOC/Monitoração (Zabbix + Grafana)."
echo
