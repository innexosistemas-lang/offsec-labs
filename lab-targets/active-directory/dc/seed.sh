#!/bin/bash
# seed.sh — popula CORP.LAB com objetos realistas + fraquezas intencionais p/ treino.
# Cenarios cobertos: Kerberoasting (SPN), AS-REP Roasting (no-preauth),
# Password Spraying (politica fraca), e abuso de ACL (GenericAll) p/ BloodHound.
set -uo pipefail

SAMDB="/var/lib/samba/private/sam.ldb"
BASE="DC=corp,DC=lab"
run() { echo "  \$ $*"; "$@" || echo "    (aviso: comando retornou nao-zero — seguindo)"; }

echo "== [seed] 1/7 Politica de senha FRACA (misconfig realista) =="
run samba-tool domain passwordsettings set \
    --complexity=off --min-pwd-length=1 --history-length=0 \
    --min-pwd-age=0 --max-pwd-age=0

echo "== [seed] 2/7 Unidades Organizacionais (OUs) =="
for ou in "OU=Corp,${BASE}" \
          "OU=IT,OU=Corp,${BASE}" \
          "OU=Finance,OU=Corp,${BASE}" \
          "OU=Servers,OU=Corp,${BASE}" \
          "OU=ServiceAccounts,OU=Corp,${BASE}"; do
  run samba-tool ou create "$ou"
done

echo "== [seed] 3/7 Grupos =="
run samba-tool group add "IT Support"
run samba-tool group add "Helpdesk"
run samba-tool group add "Finance Team"
run samba-tool group add "Server Admins"

echo "== [seed] 4/7 Usuarios (senhas fracas de proposito) =="
# Usuarios comuns (alvos de spraying)
run samba-tool user create jdoe     'Summer2025'   --userou="OU=IT,OU=Corp"      --given-name=John   --surname=Doe
run samba-tool user create asmith   'Welcome1'     --userou="OU=Finance,OU=Corp" --given-name=Alice  --surname=Smith
run samba-tool user create rwilson  'Password123'  --userou="OU=Finance,OU=Corp" --given-name=Robert --surname=Wilson
run samba-tool user create kjones   'Autumn2024'   --userou="OU=IT,OU=Corp"      --given-name=Karen  --surname=Jones
# Alvo final (Domain Admin) do caminho de ACL
run samba-tool user create tadams   'Winter2023!'  --userou="OU=IT,OU=Corp"      --given-name=Tom    --surname=Adams

# Contas de servico com SPN -> Kerberoasting
run samba-tool user create svc_sql    'Password1'   --userou="OU=ServiceAccounts,OU=Corp" --description="SQL Server service account"
run samba-tool user create svc_backup 'Backup2020!' --userou="OU=ServiceAccounts,OU=Corp" --description="Backup service account"

echo "== [seed] 5/7 Membros de grupos (inclui caminho privilegiado) =="
run samba-tool group addmembers "Helpdesk"          jdoe,kjones
run samba-tool group addmembers "IT Support"        "Helpdesk"      # grupo aninhado
run samba-tool group addmembers "Finance Team"      asmith,rwilson
run samba-tool group addmembers "Domain Admins"     tadams          # alvo final = DA
run samba-tool group addmembers "Backup Operators"  svc_backup      # builtin privilegiado

echo "== [seed] 6/7 Kerberoasting (SPNs) + AS-REP Roasting (no preauth) =="
# SPNs -> qualquer usuario autenticado consegue o TGS e cracka offline
run samba-tool spn add "MSSQLSvc/dc01.corp.lab:1433" svc_sql
run samba-tool spn add "CIFS/backup.corp.lab"        svc_backup

# AS-REP roasting: liga DONT_REQ_PREAUTH (UAC 512 + 4194304 = 4194816) no kjones
KJONES_DN="$(ldbsearch -H "$SAMDB" "(samAccountName=kjones)" dn 2>/dev/null | awk '/^dn: /{sub(/^dn: /,"");print;exit}')"
if [ -n "${KJONES_DN:-}" ]; then
  cat > /tmp/asrep.ldif <<EOF
dn: ${KJONES_DN}
changetype: modify
replace: userAccountControl
userAccountControl: 4194816
EOF
  run ldbmodify -H "$SAMDB" /tmp/asrep.ldif
  rm -f /tmp/asrep.ldif
else
  echo "    (aviso: DN de kjones nao encontrado — AS-REP nao aplicado)"
fi

echo "== [seed] 7/7 Abuso de ACL: Helpdesk --GenericAll--> tadams (Domain Admin) =="
# Caminho BloodHound: jdoe -> Helpdesk -> GenericAll -> tadams -> Domain Admins
HELP_SID="$(ldbsearch -H "$SAMDB" "(samAccountName=Helpdesk)" objectSid 2>/dev/null | awk '/^objectSid: /{print $2;exit}')"
TADAMS_DN="$(ldbsearch -H "$SAMDB" "(samAccountName=tadams)" dn 2>/dev/null | awk '/^dn: /{sub(/^dn: /,"");print;exit}')"
if [ -n "${HELP_SID:-}" ] && [ -n "${TADAMS_DN:-}" ]; then
  run samba-tool dsacl set --objectdn="${TADAMS_DN}" --sddl="(A;;GA;;;${HELP_SID})"
else
  echo "    (aviso: SID/DN ausente — ACL GenericAll nao aplicada) HELP_SID=${HELP_SID:-} TADAMS_DN=${TADAMS_DN:-}"
fi

echo "== [seed] concluido =="
echo "   Usuarios:  $(samba-tool user list 2>/dev/null | tr '\n' ' ')"
