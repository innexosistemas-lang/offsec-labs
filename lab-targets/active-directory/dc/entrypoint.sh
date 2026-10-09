#!/bin/bash
# Entrypoint do Domain Controller Samba (CORP.LAB)
# - Na primeira execucao: provisiona o dominio e aplica o seed vulneravel.
# - Nas execucoes seguintes: apenas sobe o samba (dados persistidos em volumes).
set -euo pipefail

REALM="${REALM:-CORP.LAB}"
DOMAIN="${DOMAIN:-CORP}"
DC_HOSTNAME="${DC_HOSTNAME:-dc01}"
DC_IP="${DC_IP:-172.30.0.10}"
ADMIN_PASS="${DOMAIN_ADMIN_PASS:?DOMAIN_ADMIN_PASS nao definido}"
DNS_FORWARDER="${DNS_FORWARDER:-1.1.1.1}"

PROV_MARK="/var/lib/samba/.provisioned"

regen_krb5() {
  if [ -f /var/lib/samba/private/krb5.conf ]; then
    cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf
  fi
}

if [ ! -f "$PROV_MARK" ]; then
  echo ">>> [DC] Provisionando dominio ${REALM} (${DOMAIN}) em ${DC_HOSTNAME}.${REALM,,} / ${DC_IP}"
  # Remove smb.conf default do pacote (o provision cria o certo)
  rm -f /etc/samba/smb.conf

  samba-tool domain provision \
    --use-rfc2307 \
    --realm="${REALM}" \
    --domain="${DOMAIN}" \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    --adminpass="${ADMIN_PASS}" \
    --host-name="${DC_HOSTNAME}" \
    --host-ip="${DC_IP}"

  # Ajustes [global] do lab (fraquezas intencionais + compat c/ ferramentas Linux):
  #  - dns forwarder: resolucao externa (lab e isolado, mas inofensivo)
  #  - require strong auth = no: permite simple bind LDAP (ldapsearch/rusthound)
  #  - ntlm auth = yes: habilita NTLM (config legada/fraca, realista)
  if ! grep -q "require strong auth" /etc/samba/smb.conf; then
    awk -v fwd="${DNS_FORWARDER}" '
      1
      /^\[global\]/ && !d {
        print "\tdns forwarder = " fwd
        print "\tldap server require strong auth = no"
        print "\tntlm auth = yes"
        d=1
      }' /etc/samba/smb.conf > /tmp/smb.new && cp /tmp/smb.new /etc/samba/smb.conf && rm -f /tmp/smb.new
  fi

  regen_krb5

  echo ">>> [DC] Aplicando seed vulneravel (usuarios/grupos/OUs/SPN/ACL)..."
  /usr/local/bin/seed.sh || { echo '!!! seed.sh falhou'; exit 1; }

  touch "$PROV_MARK"
  echo ">>> [DC] Provisionamento concluido."
else
  echo ">>> [DC] Dominio ja provisionado — iniciando samba."
  regen_krb5
fi

# resolv.conf aponta p/ o proprio DC (resolucao AD interna)
printf 'search %s\nnameserver 127.0.0.1\n' "${REALM,,}" > /etc/resolv.conf || true

echo ">>> [DC] Subindo samba (foreground)..."
exec samba --foreground --no-process-group --debug-stdout
