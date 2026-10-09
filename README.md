# Offsec-Labs 

> Laboratório prático pessoal para desenvolver e **evidenciar** habilidades de **NOC** (monitoramento e disponibilidade de infraestrutura) e **SOC** (detecção e resposta a incidentes) 

![status](https://img.shields.io/badge/status-ativo-brightgreen) ![labs](https://img.shields.io/badge/labs-9-blue) ![foco](https://img.shields.io/badge/foco-NOC%20%7C%20SOC-purple)


## Objetivo

Este portfólio documenta um ambiente de estudo que cobre as duas pontas de um centro de operações:

- **NOC (Network Operations Center):** manter serviços **no ar e saudáveis**  monitoramento de disponibilidade, métricas, alertas de indisponibilidade, hardening e atualização.

- **SOC (Security Operations Center):** **detectar e responder** a atividade maliciosa, coleta de logs, SIEM, regras de detecção, correlação, resposta automática e caça a ameaças (threat hunting).

Cada componente do laboratório é um exercício isolado que que tem o proposito de demonstrar hardskills que serão publicados aqui no GitHub.


## Infraestrutura do Lab

| Item | Detalhe |
| - | - |
| Host | VPS, Ubuntu 26.04 LTS, 4 vCPU / 16 GB RAM |
| Acesso | SSH por chave na porta 2222 (root desabilitado) |
| Exposição | IP público 24/7 (ataques reais chegam de verdade) |
| Contêineres | Docker (alvos vulneráveis isolados) |


**Políticas **


- Nada de senhas, chaves ou tokens no repositório (`.gitignore` cobre `*.key`, `*.pem`, `id_rsa*`, `.env`, `credentials.txt`).

- Configs publicadas são **sanitizadas** (placeholders no lugar de credenciais).

- Evidências com IPs/usuários sensíveis são anonimizadas quando necessário.




### Arquitetura : 1 host, 2 zonas separadas

```
                             INTERNET
                                │
         ┌──────────────────────┴───────────────────────┐
         │  ZONA EXPOSTA (liberada no firewall)         │
         │   • Hardening do host  (SSH 2222)            │
         │   • Honeypot Cowrie   (isca nas portas 22/23)│
         │   • Site nginx + HTTPS (80/443)              │
         │   • Scripts de auditoria (cron)              │
         └──────────────────────┬───────────────────────┘
                                │  (mesmo host — acesso só por túnel SSH)
   ┌────────────────────────────┴──────────────────────── ──────┐
   │ ZONA ISOLADA (somente 127.0.0.1 / redes internas Docker)   │
   │  MONITORAÇÃO/SIEM                 ALVOS (treino)           │
   │    • Wazuh (SIEM)                 • DVWA (web vulnerável)  │
   │    • Zabbix (NOC)                 • AD Samba `corp.lab`    │
   │    • Grafana (Dashboard)              + máquina atacante   │
   └────────────────────────────────────────────────────────────┘
```


## Trilhas de estudo

### Trilha NOC — "manter no ar e enxergar"

1. **vps-hardening** — base de um servidor confiável.

2. **nginx-site-tls** — publicar serviço com TLS e proteção básica.

3. **zabbix-noc** — monitorar disponibilidade/recursos e alertar quando algo cai.

4. **security-scripts** — automação de verificações periódicas.

*Habilidades:* Linux, redes/portas, TLS, monitoramento, SLAs/alertas, automação.

### Trilha SOC — "detectar e responder"

1. **cowrie-honeypot** — ver como atacantes reais agem.

2. **wazuh-soc** — montar o SIEM e escrever regras.

3. **attack-detection-web** — fechar o ciclo ataque↔detecção (web).

4. **active-directory** — detecção de ataques de identidade (AD).

*Habilidades:* análise de logs, SIEM, regras de correlação, MITRE ATT&CK, threat hunting, resposta automática.


## Padrão de documentação de cada repositório

Para manter tudo **padronizado**, cada pasta de laboratório segue este modelo:

```
<lab>/
├── README.md          # objetivo, passo a passo, resultados, lições
├── configs/           # arquivos de configuração SEM segredos
├── evidence/          # prints de alertas, saídas de comando, logs anonimizados
└── diagram.(md|png)   # diagrama do fluxo (opcional)
```

**Estrutura sugerida do `README.md` de cada lab:**

1. **Objetivo** — o que o lab ensina (e qual skill NOC/SOC).

2. **Ambiente** — onde roda, pré-requisitos.

3. **Implementação** — passos e trechos de config.

4. **Validação / Evidências** — como foi testado + prints.

5. **Detecção / Monitoração** — o que o SIEM/NOC mostra.

6. **Lições & MITRE** — o que foi aprendido, técnicas mapeadas.


## ▶️ Acesso ao ambiente (referência)

```
ssh lab                                   # administração (porta 2222, por chave)
ssh -L 8444:127.0.0.1:5601 lab            # Wazuh  → https://localhost:8444
ssh -L 8081:127.0.0.1:8080 lab            # Zabbix → http://localhost:8081
ssh -L 8091:127.0.0.1:8090 lab            # DVWA   → http://localhost:8091
docker exec -it ad-attacker bash          # máquina de ataque do lab de AD
```


*Documento gerado como visão geral do laboratório. Cada laboratório possui (ou possuirá) seu próprio README detalhado na respectiva pasta.*

