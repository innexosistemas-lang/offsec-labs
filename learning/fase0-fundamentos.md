# Fase 0 — Fundamentos 🟢

> **Meta:** ficar confortável no ambiente do lab **antes** de qualquer ferramenta ou ataque.
> A base de tudo: Linux, SSH, portas/serviços e as 2 zonas do lab.

## Por que começar aqui
Você só monitora bem (NOC) e só detecta/ataca bem (SOC) aquilo que **entende primeiro**.
Esta fase constrói o mapa mental do ambiente.

## Como fazer
No **notebook**, rode o tour guiado (somente leitura, não altera nada):

```bash
bash fase0-explore.sh
```

Ele te leva por 5 passos, explicando cada um. Vá sem pressa.

## O que você precisa entender ao final

1. **Acesso** — você entra como `pentester` (não-root), por **chave**, na porta **2222**. Root e senha estão desligados.
2. **SO e recursos** — qual distribuição, kernel, RAM e disco (base de capacidade/NOC).
3. **As 2 zonas:**
   - **Exposta** (no `ufw`): SSH 2222, iscas 2223/2323, site 80/443.
   - **Isolada** (só por túnel SSH): Wazuh, Zabbix, Grafana, DVWA, AD.
4. **Leitura de portas:** `0.0.0.0`/`[::]` = todas as interfaces; `127.0.0.1` = só local (loopback = isolado).
5. **Contêineres:** `dvwa` e `ad-dc01` são **alvos**; `ad-attacker` é a **máquina de ataque**; `grafana` é ferramenta.

## Exercícios (responda/anote)
- [ ] Qual a distro e quanta RAM tem a VPS?
- [ ] Quais portas estão abertas pra internet — e por que só essas?
- [ ] Entre SSH (2222) e DVWA (8090), qual escuta só em loopback?
- [ ] Quais contêineres são alvo e qual é atacante?

## Comandos-chave aprendidos
| Comando | Pra que serve |
|---|---|
| `ssh lab` | conectar no servidor (porta 2222, por chave) |
| `ss -tulnp` | ver o que está escutando (portas/serviços) |
| `sudo ufw status` | ver o que o firewall libera pra internet |
| `systemctl status <svc>` | estado de um serviço |
| `docker ps` | contêineres em execução (alvos/ferramentas) |
| `free -h` / `df -h /` | memória / disco |

## Próxima fase
**Fase 1 — Hardening:** entender a fundo SSH (2222, sem senha/root), `ufw` e `fail2ban` — o "porquê" de cada proteção.
