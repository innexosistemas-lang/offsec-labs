# Fase 2 — NOC / Monitoração 🟡

> **Meta:** aprender a enxergar o **"normal"** de um host (baseline).
> No SOC você só detecta o *anormal* depois de conhecer o *normal*. É aqui que ele nasce.
> Ferramentas: **Zabbix** (coleta + alerta) e **Grafana** (visualização).

## A virada mental desta fase
- Fase 1 endureceu o host (o "normal **seguro**", estático).
- Fase 2 passa a **observar** o host ao longo do tempo (o "normal **operacional**", dinâmico):
  CPU, memória, serviços no ar. Isso é a função do **NOC** (Network Operations Center):
  vigiar disponibilidade e saúde.
- Baseline = a faixa de valores considerada normal. Sem ele, um alerta não tem sentido
  ("CPU 80%" é problema? Só se o normal for 20%).

## Arquitetura do Zabbix (4 peças)
```
[zabbix-agent2]  --coleta-->  [zabbix-server]  --grava-->  [MariaDB]
   (no host)                   (processa/avalia)             (histórico)
                                     |
                                     v
                              [frontend web]  <--  você (via túnel SSH)
```
- **agent2** (porta 10050): roda no host, coleta as métricas quando o server pede.
- **server** (porta 10051): pede os dados, avalia as regras, dispara problemas.
- **MariaDB**: guarda o histórico (base do baseline/tendências).
- **frontend** (nginx 127.0.0.1:8080): a tela. Isolado → só por túnel.

> 🔗 Liga com a Fase 1: 10050/10051 escutam em `0.0.0.0`, **mas não estão no ufw** →
> continuam bloqueados da internet. O ufw é o portão; o default-deny protege mesmo um
> serviço que "abriu em todas as interfaces".

## Os 2 conceitos-chave do Zabbix
- **Item** = *o que* coletar. Tem uma **key** (ex.: `system.cpu.util`) e um **intervalo**
  (`delay`, ex.: 1m). Cada item vira uma série temporal no histórico.
- **Trigger** = *quando* isso vira **problema**. É uma expressão + uma **prioridade**
  (Not classified→Disaster). Ex.: "HTTPS (443) fora do ar" com prioridade **High(4)**.
- **Template**: um pacote de itens+triggers reaproveitável (o "Linux by Zabbix agent"
  já traz CPU, memória, disco, etc. prontos).

## Itens reais no seu lab (host "Zabbix server")
| Item | key | intervalo |
|---|---|---|
| CPU utilization | `system.cpu.util` | (agendado) |
| Memory utilization | `vm.memory.utilization` | (agendado) |
| Available memory in % | `vm.memory.size[pavailable]` | 1m |
| HTTPS (443) disponível | `net.tcp.service[https,127.0.0.1,443]` | 1m |

Trigger custom: **"HTTPS (443) fora do ar em {HOST.NAME}"** — prioridade **High**, habilitado.
(Quando o item HTTPS retorna 0 = porta fora do ar → trigger dispara.)

## Grafana — a camada de visualização
- Zabbix já mostra gráficos, mas o **Grafana** unifica fontes num painel só.
- Datasource **Zabbix** → http://127.0.0.1:8080/api_jsonrpc.php (usuário `Admin`, A maiúsculo!).
- Dashboard **"NOC — Zabbix"** (uid `lab-noc-zabbix`): HTTPS 443, CPU, memória.
- Por que ter os dois: Zabbix = motor (coleta/alerta); Grafana = vitrine (um lugar só pra
  NOC *e* SOC — na Fase 4 o Grafana também lê o Wazuh).

## Como acessar (no notebook)
```bash
# Zabbix:
ssh -L 8081:127.0.0.1:8080 lab      # depois: http://localhost:8081  (user Admin)
# Grafana:
ssh -L 3000:127.0.0.1:3000 lab      # depois: http://localhost:3000
```

## O que você precisa entender ao final
1. O que é **baseline** e por que o NOC/SOC depende dele.
2. As 4 peças do Zabbix e o fluxo agent→server→DB→frontend.
3. Diferença **item** (o que coleta) × **trigger** (quando alerta).
4. Por que 10050/10051 abertos em 0.0.0.0 ainda assim não são acessíveis da internet.
5. Papel do Grafana vs Zabbix.

## Exercícios
- [ ] No Grafana, abra "NOC — Zabbix". Qual o valor atual de CPU e memória? Esse é o baseline.
- [ ] Qual item vira o trigger de HTTPS? O que o valor 1 e o 0 significam?
- [ ] Se eu parasse o nginx, qual item mudaria e qual trigger dispararia?
- [ ] Por que o frontend do Zabbix está em 127.0.0.1 e não em 0.0.0.0?

## Próxima fase
**Fase 3 — Honeypot (Cowrie):** ler um ataque **real**, análise de log.
