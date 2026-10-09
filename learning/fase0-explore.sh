#!/usr/bin/env bash
# ============================================================
#  FASE 0 — FUNDAMENTOS  |  Tour guiado (somente leitura) do lab
#  Rode no NOTEBOOK:   bash fase0-explore.sh
#  Pré-requisito: 'ssh lab' configurado (~/.ssh/config)
#  Nada aqui altera o servidor — é só para APRENDER o ambiente.
# ============================================================
set -uo pipefail
SSH="ssh -o ConnectTimeout=20 -o ConnectionAttempts=6 -o BatchMode=yes lab"

pause(){ echo; read -rp "   ⏎  [Enter para continuar] "; echo; }
sec(){ echo; echo "============================================================"; echo "  $1"; echo "============================================================"; }
run(){ echo "   \$ $1"; echo; $SSH "$2"; }

sec "0) Conexão com o lab"
run "ssh lab 'whoami; hostname'" 'echo "   -> conectado como $(whoami)@$(hostname) na porta $(echo $SSH_CONNECTION | awk "{print \$4}")"' \
  || { echo "   ❌ Não conectou. Verifique o ~/.ssh/config e a chave."; exit 1; }
echo
echo "   📖 Você entra como 'pentester' (NÃO root), por CHAVE, na porta 2222."
echo "      Root e senha estão desabilitados — isso é parte do hardening."
pause

sec "1) Que máquina é essa? (SO e recursos)"
run "informações de SO/recursos" 'grep PRETTY_NAME /etc/os-release | cut -d= -f2; echo "kernel: $(uname -r)"; uptime -p; free -h | awk "/Mem/{print \"RAM: \"\$3\" usados / \"\$2}"; df -h / | awk "NR==2{print \"Disco: \"\$3\" / \"\$2\" (\"\$5\")\"}"'
echo
echo "   📖 Conhecer SO/recursos é a base do NOC: define o que o servidor aguenta"
echo "      e como mantê-lo saudável (capacidade, atualização, limites)."
echo "   ❓ PERGUNTE-SE: qual a distribuição e quanta RAM/disco tem?"
pause

sec "2) As 2 ZONAS — o que é público vs interno"
run "ufw status (o firewall define o que a internet alcança)" 'sudo ufw status | grep -E "Status|ALLOW"'
echo
echo "   📖 Só o que está 'ALLOW' no ufw é acessível pela INTERNET (zona EXPOSTA):"
echo "      2222=SSH admin | 2223/2323=iscas do honeypot | 80/443=site."
echo "      Todo o resto (Wazuh, Zabbix, Grafana, DVWA, AD) fica na zona ISOLADA,"
echo "      acessível só por TÚNEL SSH. Alvo vulnerável nunca na internet."
echo "   ❓ PERGUNTE-SE: por que só essas portas estão abertas?"
pause

sec "3) Quais SERVIÇOS estão escutando (e ONDE)"
run "portas em escuta" 'sudo ss -tlnp | awk "NR>1{print \$4}" | sort -u'
echo
echo "   📖 Leia o endereço antes do ':porta':"
echo "      0.0.0.0 / [::]      = escuta em TODAS as interfaces"
echo "      127.0.0.1 / [::1]   = escuta SÓ localmente (loopback) = isolado"
echo "   ❓ EXERCÍCIO: ache o SSH (2222) e o DVWA (8090). Qual está só em loopback?"
pause

sec "4) CONTÊINERES — onde vivem os alvos"
run "docker ps" 'sudo docker ps --format "   {{.Names}}  |  {{.Image}}  |  {{.Ports}}"'
echo
echo "   📖 dvwa        = ALVO web vulnerável (127.0.0.1:8090)"
echo "      ad-dc01     = ALVO: controlador de domínio AD (corp.lab)"
echo "      ad-attacker = sua MÁQUINA DE ATAQUE (não é alvo)"
echo "      grafana     = painéis (ferramenta de visualização)"
echo "   ❓ EXERCÍCIO: liste quais contêineres são ALVO e qual é ATACANTE."
pause

sec "✅ Fim da Fase 0 — Fundamentos"
echo "   Você explorou: SO/recursos, as 2 zonas, serviços/portas e os contêineres."
echo
echo "   Responda mentalmente (ou anote) as 4 perguntas ❓ acima."
echo "   Quando estiver confortável com isso, a próxima é a"
echo "   FASE 1 — HARDENING (entender SSH / ufw / fail2ban a fundo)."
echo
