# Fase 0 — Fundamentos · Registro da Aula

> **Data:** 2026-10-13 **Formato:** aula prática guiada  mais  teste de consolidação ao final. **Resultado:** ✅ Concluída · teste **5,5 / 6**.


## Objetivo da fase

Construir o mapa mental de 4 coisas: **acesso**, **máquina/recursos**, **as 2 zonas** e **portas/serviços**.

> Princípio-guia: *você só monitora bem (NOC) e só detecta/ataca bem (SOC) aquilo que entende primeiro.*


## Ambiente (snapshot da aula)

| Item | Valor |
| - | - |
| Host | `srv2040813` (VPS Hostinger, IP `179.236.252.233`) |
| SO | Ubuntu 26.04.1 LTS · kernel 7.0.0-34-generic |
| Recursos | 15 GiB RAM (≈11 GiB livres) · swap 2 GiB · disco 193 G (14% usado) |
| Acesso | `ssh lab` → usuário `pentester`, porta **2222**, por **chave** (sem senha, sem root) |


> Observação de NOC registrada na aula: `*** System restart required ***` as atualizações automáticas instalaram um kernel novo que só entra em uso após reboot. Um analista monitora "há quanto tempo existe restart pendente".


## Passo a passo

### 0 · Acesso

Entrada como `pentester` (não-root), por chave, na porta 2222. **Por quê não root:** a pratica de menor privilégio reduz estrago de erro humano e a superfície de ataque (**root **desligado no SSH). Eleva-se com **`sudo` **somente se necessário.

### 1 · Máquina e recursos

`grep PRETTY_NAME /etc/os-release; uname -r; uptime -p; free -h; df -h /` Base do NOC: conhecer capacidade do servidor. A ideia de **baseline** (só percebo se uma açao e anormal se sei qual era o estado normal do servidor) , swap enchendo = RAM esgotando → lentidão e risco de OOM killer matar serviços.

### 2 · As 2 zonas (`sudo ufw status`)

O firewall é a **fronteira**. Só o que está `ALLOW` é alcançável pela internet:

| Porta | Função |
| - | - |
| 2222/tcp | SSH admin (acesso real) |
| 2223/tcp | Cowrie SSH — **isca** |
| 2323/tcp | Cowrie Telnet — **isca** |
| 80/tcp | HTTP (nginx) |
| 443/tcp | HTTPS (nginx) |


Tudo mais (Wazuh, Zabbix, Grafana, DVWA, AD) = **zona isolada**. **Jogada do honeypot:** SSH real na 2222 (discreta); portas 22/23 (as "óbvias") redirecionadas às iscas, que gravam o atacante.

### 3 · Serviços escutando (`sudo ss -tlnp`)

Chave de leitura do endereço:

- `0.0.0.0` / `[::]` → escuta em **todas as interfaces**

- `127.0.0.1` / `[::1]` → escuta **só local** (loopback) = isolado

**Conceito central da fase — "escutar ≠ exposto":** Wazuh (1514/1515) e Zabbix (10050/10051) escutam em `0.0.0.0`, mas **não** há `ALLOW` no `ufw` → o firewall bloqueia antes. Exposto de verdade = escuta em todas as interfaces **E** firewall libera. São **duas camadas** → **defesa em profundidade**. Isolamento vem de dois mecanismos: bind em `127.0.0.1` **ou** firewall negando.

### 4 · Contêineres (`sudo docker ps`)

| Contêiner | Papel |
| - | - |
| `dvwa` (127.0.0.1:8090) | **Alvo** web vulnerável |
| `ad-dc01` (127.0.0.1:53/88/389/445/464/636/3268-9) | **Alvo** — Domain Controller `corp.lab` |
| `ad-attacker` (sem portas) | **Máquina de ataque** (nmap, impacket, bloodhound, kerbrute…) |
| `grafana` | **Ferramenta** — painéis NOC/SOC |


Distinção: o **notebook/host** é o posto de comando (de onde se opera via SSH); o **`ad-attacker`** é de onde os ataques partem, por dentro da rede isolada.


## Conceitos consolidados

1. **Menor privilégio** — usuário comum + `sudo` pontual; root desligado.

2. **Duas zonas** — exposta (internet) vs isolada (só por túnel SSH); `ufw` é a fronteira.

3. **Ler portas** — `0.0.0.0` (todas) vs `127.0.0.1` (loopback); escutar não é o mesmo que estar exposto.

4. **Defesa em profundidade** — bind loopback *e/ou* firewall; camadas redundantes.

5. **Honeypot** — porta óbvia (22) é armadilha; acesso real fica discreto (2222).

6. **Regra de ouro** — alvo vulnerável **nunca** com porta na internet; tudo sensível acessado por dentro, via túnel; ataques contidos no ambiente isolado.


## Teste de consolidação (respostas do aluno)

| \# | Pergunta | Avaliação |
| - | - | - |
| 1 | Por que `pentester` e não `root` (1 motivo de segurança + 1 de erro) | ✅ Menor privilégio (segurança) + evitar erro humano |
| 2 | Zona exposta × isolada; quem é a fronteira | ✅ Exposta=internet, isolada=só túnel SSH; firewall é a fronteira |
| 3 | Escutar em `0.0.0.0:9200` basta pra estar exposto? | ✅ Não — o firewall pode bloquear a entrada |
| 4 | Portas 22 / 2222 / 2223: real, isca, por que é esperto | ✅ SSH real 2222; isca na 22 captura o atacante na porta mais varrida |
| 5 | Regra de ouro sobre alvos vulneráveis | ✅ Sem internet; acessados por dentro; ações rodam no isolado |
| 6 | Função de `ad-dc01`, `ad-attacker`, `grafana` | 🟡 `ad-attacker` e `grafana` certos; **faltou nomear `ad-dc01`** (Domain Controller / alvo) |


**Nota: 5,5 / 6.** Domínio sólido do modelo das 2 zonas e da regra de ouro — a base que sustenta todas as próximas fases.


## Comandos-chave

| Comando | Pra quê |
| - | - |
| `ssh lab` | conectar (porta 2222, por chave) |
| `ss -tulnp` / `ss -tlnp` | ver o que está escutando (portas/serviços) |
| `sudo ufw status` | ver o que o firewall libera pra internet |
| `systemctl status <svc>` | estado de um serviço |
| `docker ps` | contêineres em execução (alvos/ferramentas) |
| `free -h` / `df -h /` | memória / disco |



## Próxima fase

**Fase 1 — Hardening 🟢:** abrir o capô das proteções vistas de longe hoje — o *porquê* de SSH (2222, sem senha/root, `MaxAuthTries 3`), `ufw` (default-deny), `fail2ban` (jails/ban) e atualizações automáticas.

