# Samba AD Domain Controller — lab de identidade (CORP.LAB)
# Isolado: usado apenas na rede docker interna lab-ad + portas em 127.0.0.1
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Preseed para evitar prompts interativos do krb5 durante o apt
RUN echo "krb5-config krb5-config/default_realm string CORP.LAB" | debconf-set-selections \
 && echo "krb5-config krb5-config/kerberos_servers string dc01.corp.lab" | debconf-set-selections \
 && echo "krb5-config krb5-config/admin_server string dc01.corp.lab" | debconf-set-selections

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      samba samba-ad-provision samba-dsdb-modules samba-vfs-modules \
      smbclient ldb-tools ldap-utils krb5-user winbind \
      dnsutils iproute2 procps vim-tiny ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY seed.sh       /usr/local/bin/seed.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/seed.sh

# DNS AD(53), Kerberos(88), kpasswd(464), LDAP(389/636), GC(3268/3269), SMB(445), RPC(135)
EXPOSE 53/tcp 53/udp 88/tcp 88/udp 135/tcp 389/tcp 389/udp 445/tcp 464/tcp 464/udp 636/tcp 3268/tcp 3269/tcp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
