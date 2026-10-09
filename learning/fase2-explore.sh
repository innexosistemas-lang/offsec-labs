#!/usr/bin/env bash
# ============================================================
#  FASE 2 — NOC / MONITORAÇÃO  |  Tour guiado (somente leitura)
#  Rode no NOTEBOOK:   bash fase2-explore.sh
#  Pré-requisito: 'ssh lab' configurado (~/.ssh/config)
#  Mostra a arquitetura do Zabbix sem alterar nada.
#  (Os dashboards em si você abre via túnel — ver fase2-noc.md)
# ============================================================
set -uo pipefail
SSH="ssh -o ConnectTimeout=20 -o ConnectionAttempts=6 -o BatchMode=yes lab"

pause(){ echo; read -rp "   ⏎  [Enter para continuar] "; echo; }
sec(){ echo; echo "============================================================"; echo "  $1"; echo "============================================================"; }

$SSH 'true' 2>/dev/null || { echo "❌ Não conectou no lab. Confira ~/.ssh/config e a chave."; exit 1; }

sec "1) As 4 peças do Zabbix estão no ar?"
$SSH 'for s in zabbix-server zabbix-agent2 mariadb nginx; do printf "   %-16s %s\n" "$s" "$(systemctl is-active $s)"; done; echo "   grafana(docker)  $(sudo docker inspect -f "{{.State.Status}}" grafana 2>/dev/null)"'
echo
echo "   📖 agent2=coleta | server=avalia | mariadb=histórico | nginx=frontend | grafana=vitrine"
pause

sec "2) Portas NOC — e a ligação com a Fase 1"
$SSH 'sudo ss -ltnp | grep -E ":10050|:10051|:8080|:3000" | awk "{print \"   \"\$4}" | sort -u'
echo
echo "   📖 8080(frontend) e 3000(grafana) = 127.0.0.1 -> só por TÚNEL."
echo "      10050/10051 escutam em 0.0.0.0 MAS não estão no ufw -> a internet não alcança."
echo "   ❓ Por que, mesmo 'aberto em todas as interfaces', o 10051 está protegido?"
pause

sec "3) ITENS — o que o Zabbix COLETA"
$SSH 'DBP=$(sudo grep -E "^DBPassword=" /etc/zabbix/zabbix_server.conf | cut -d= -f2); sudo mysql -N -uzabbix -p"$DBP" zabbix -e "SELECT CONCAT(\"   \", i.name, \"  [\", i.key_, \"]\") FROM items i JOIN hosts h ON i.hostid=h.hostid WHERE h.host=\"Zabbix server\" AND i.status=0 AND i.name IN (\"CPU utilization\",\"Memory utilization\",\"Available memory in %\",\"HTTPS (443) disponível\");" 2>/dev/null'
echo
echo "   📖 Item = O QUE coletar: uma KEY + um intervalo. Cada item = uma série no tempo."
echo "   ❓ Qual desses itens vira o trigger de HTTPS?"
pause

sec "4) TRIGGERS — o que vira ALERTA"
$SSH 'DBP=$(sudo grep -E "^DBPassword=" /etc/zabbix/zabbix_server.conf | cut -d= -f2); sudo mysql -N -uzabbix -p"$DBP" zabbix -e "SELECT CONCAT(\"   \", t.description, \"  (prioridade=\", t.priority, \")\") FROM triggers t WHERE t.description LIKE \"%fora do ar%\";" 2>/dev/null'
echo
echo "   📖 Trigger = QUANDO vira problema: expressão + prioridade (0=none .. 5=disaster)."
echo "      HTTPS retorna 1(no ar) ou 0(fora). Virou 0 -> trigger dispara."
pause

sec "5) BASELINE — últimos valores coletados (o 'normal')"
$SSH 'DBP=$(sudo grep -E "^DBPassword=" /etc/zabbix/zabbix_server.conf | cut -d= -f2); sudo mysql -N -uzabbix -p"$DBP" zabbix -e "SELECT CONCAT(\"   \", i.name, \" = \", ROUND(h.value,2)) FROM history h JOIN items i ON h.itemid=i.itemid JOIN hosts ho ON i.hostid=ho.hostid WHERE ho.host=\"Zabbix server\" AND i.name IN (\"CPU utilization\",\"Available memory in %\") AND h.clock > UNIX_TIMESTAMP()-600 ORDER BY h.clock DESC LIMIT 6;" 2>/dev/null || echo "   (sem amostras recentes em history; veja no dashboard)"'
echo
echo "   📖 Esses números SÃO o baseline: a faixa normal de CPU/memória deste host."
echo "      No SOC, desvio brusco disso = sinal pra investigar."
pause

sec "✅ Fim da Fase 2 — NOC/Monitoração"
echo "   Abra os dashboards via túnel (ver fase2-noc.md): Zabbix 8081, Grafana 3000."
echo "   Depois fazemos o teste de consolidação e seguimos pra"
echo "   FASE 3 — HONEYPOT (Cowrie): ler um ataque REAL."
echo
