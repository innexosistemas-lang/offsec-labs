# Transferência de Zona DNS — `techcorp.local` (`10.10.0.30`)

| Campo | Valor |
|-------|-------|
| **Alvo** | `10.10.0.30` (BIND 9.18 — `ns1.techcorp.local`) |
| **Zona** | `techcorp.local` |
| **Testador** | Daniel Reis |
| **Data** | 2026-10-08 |

> Evidência bruta em [evidencias-dns/axfr-techcorp.txt](evidencias-dns/axfr-techcorp.txt).

---

## [DESCOBERTA] — Transferência de Zona DNS (AXFR) Permitida sem Restrição

| Campo | Valor |
|-------|-------|
| **Severidade** | Média |
| **Nota CVSS** | 5.3 (estimativa base v3.1) |
| **CWE** | CWE-200 (Exposure of Sensitive Information), CWE-16 (Configuration) |
| **Ativo Afetado** | Servidor DNS `10.10.0.30:53` (ISC BIND 9.18.49) |
| **Status** | Aberto |

### Descrição

O servidor DNS autoritativo de `techcorp.local` permite a transferência de zona
(operação **AXFR**) a partir de qualquer cliente, sem restrição por IP ou TSIG.
A transferência de zona deveria ser permitida apenas para servidores DNS
secundários autorizados; aberta a qualquer um, ela expõe o mapa completo da
rede interna.

### Evidência

```
$ dig axfr techcorp.local @10.10.0.30

techcorp.local.             86400 IN SOA   ns1.techcorp.local. admin.techcorp.local. 2024010101 ...
techcorp.local.             86400 IN NS    ns1.techcorp.local.
admin.techcorp.local.       86400 IN CNAME srv-files01.techcorp.local.
backup.techcorp.local.      86400 IN A     10.10.0.30
dev.techcorp.local.         86400 IN A     10.10.0.90
gitlab.techcorp.local.      86400 IN A     10.10.0.80
intranet.techcorp.local.    86400 IN A     10.10.0.30
jenkins.techcorp.local.     86400 IN A     10.10.0.70
mail.techcorp.local.        86400 IN A     10.10.0.60
ns1.techcorp.local.         86400 IN A     10.10.0.30
srv-db01.techcorp.local.    86400 IN A     10.10.0.40
srv-files01.techcorp.local. 86400 IN A     10.10.0.30
srv-web01.techcorp.local.   86400 IN A     10.10.0.20
staging.techcorp.local.     86400 IN A     10.10.0.91
vpn.techcorp.local.         86400 IN A     10.10.0.50
;; XFR size: 16 records
```

### Mapa da Rede Revelado

| Nome DNS | IP | Observação | Vivo no scan Nmap? |
|----------|-----|-----------|--------------------|
| `ns1` / `srv-files01` / `intranet` / `backup` | 10.10.0.30 | Servidor DNS + arquivos (`SRV-FILES01`) | ✅ |
| `admin` (CNAME) | → srv-files01 | Alias administrativo | ✅ |
| `srv-web01` | 10.10.0.20 | Servidor web (Apache) | ✅ |
| `srv-db01` | 10.10.0.40 | Host da Corp API — o nome revela o papel de banco | ✅ |
| `vpn` | 10.10.0.50 | Concentrador VPN | ❌ (só no DNS) |
| `mail` | 10.10.0.60 | Servidor de email | ❌ (só no DNS) |
| `jenkins` | 10.10.0.70 | CI/CD Jenkins | ❌ (só no DNS) |
| `gitlab` | 10.10.0.80 | Repositório GitLab | ❌ (só no DNS) |
| `dev` | 10.10.0.90 | Ambiente de desenvolvimento | ❌ (só no DNS) |
| `staging` | 10.10.0.91 | Ambiente de homologação | ❌ (só no DNS) |

### Impacto

O ping sweep inicial (`nmap -sn`) encontrou apenas 5 hosts vivos. A transferência
de zona revelou **6 hosts adicionais** (`vpn`, `mail`, `jenkins`, `gitlab`,
`dev`, `staging`) que não respondiam ao scan — expandindo significativamente a
superfície de ataque conhecida sem qualquer varredura ativa adicional.

Os nomes dos hosts também **vazam a função** de cada sistema, direcionando
ataques futuros a alvos de alto valor:

- `jenkins` / `gitlab` — infraestrutura de CI/CD, alvos clássicos para execução
  de código, roubo de credenciais e comprometimento da cadeia de build.
- `vpn` — ponto de acesso remoto.
- `dev` / `staging` — ambientes não-produtivos, tipicamente menos endurecidos.
- `srv-db01` — identifica o host de banco de dados.

### Recomendação

1. Restringir a transferência de zona apenas aos secundários autorizados:
   ```
   allow-transfer { <IP_do_secundario>; };
   ```
   ou desabilitar completamente (`allow-transfer { none; };`) se não houver
   secundários.
2. Preferir autenticação por **TSIG** para transferências legítimas.
3. Evitar nomes de host que revelem a função do sistema em zonas internas
   expostas.

### Referências

- [CWE-200](https://cwe.mitre.org/data/definitions/200.html)
- [ISC BIND — `allow-transfer`](https://bind9.readthedocs.io/en/latest/reference.html)

---

## Próximos Passos

Os 6 hosts recém-descobertos (`10.10.0.50`, `.60`, `.70`, `.80`, `.90`, `.91`)
não estavam vivos durante a varredura. Quando estiverem online, varrer de forma
direcionada:

```
sudo nmap -sS -sV -sC -Pn 10.10.0.50 10.10.0.60 10.10.0.70 10.10.0.80 10.10.0.90 10.10.0.91
```

Prioridade sugerida: `jenkins` (.70) e `gitlab` (.80) pelo alto valor em CI/CD.

---

> **Aviso:** Teste executado em ambiente de laboratório controlado e de
> propriedade do testador. Domínio, hostnames e IPs são fictícios.
