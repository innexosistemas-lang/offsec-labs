# Caixa atacante do lab AD — roda na rede lab-ad, usa o DC como DNS.
# Ferramentas: Impacket, BloodHound.py, kerbrute, ldap/smb clients, john.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN echo "krb5-config krb5-config/default_realm string CORP.LAB" | debconf-set-selections \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-pip pipx \
      ldap-utils krb5-user smbclient libsasl2-modules-gssapi-mit \
      dnsutils iputils-ping netcat-openbsd nmap curl ca-certificates \
      john \
 && rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.local/bin:${PATH}"
RUN pipx install impacket \
 && pipx install bloodhound \
 && pipx runpip impacket install "setuptools<81"   # OpenSSL3/setuptools84 removem pkg_resources

# kerbrute (enum de usuarios / password spraying via Kerberos)
RUN curl -fsSL -o /usr/local/bin/kerbrute \
      https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_amd64 \
 && chmod +x /usr/local/bin/kerbrute

# rusthound-ce: coletor BloodHound (Rust) — funciona contra o LDAP do Samba
RUN curl -fsSL -o /tmp/rh.tgz \
      https://github.com/g0h4n/RustHound-CE/releases/download/v2.5.24/rusthound-ce-Linux-gnu-x86_64.tar.gz \
 && tar -C /tmp -xzf /tmp/rh.tgz \
 && install -m0755 "$(find /tmp -maxdepth 2 -name 'rusthound-ce' -type f | head -1)" /usr/local/bin/rusthound-ce \
 && rm -rf /tmp/rh.tgz

# Ferramentas do lab: extrator de ccache->hashcat, cracker RC4 e wrapper de Kerberoasting
COPY ccache2hashcat.py kerbcrack.py kerberoast.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ccache2hashcat.py /usr/local/bin/kerbcrack.py /usr/local/bin/kerberoast.sh

# krb5.conf apontando p/ o realm do lab
RUN printf '%s\n' \
  '[libdefaults]' \
  '    default_realm = CORP.LAB' \
  '    dns_lookup_realm = false' \
  '    dns_lookup_kdc = true' \
  '[realms]' \
  '    CORP.LAB = {' \
  '        kdc = dc01.corp.lab' \
  '        admin_server = dc01.corp.lab' \
  '    }' \
  '[domain_realm]' \
  '    .corp.lab = CORP.LAB' \
  '    corp.lab = CORP.LAB' \
  > /etc/krb5.conf

COPY users.txt passwords.txt /opt/lists/
WORKDIR /root
