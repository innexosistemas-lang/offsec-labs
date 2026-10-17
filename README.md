# Offsec-Labs

> Laboratório prático pessoal para desenvolver e **evidenciar** habilidades de **NOC** (monitoramento e disponibilidade de infraestrutura) e **SOC** (detecção e resposta a incidentes).

![status](https://img.shields.io/badge/status-ativo-brightgreen) ![labs](https://img.shields.io/badge/labs-8-blue) ![foco](https://img.shields.io/badge/foco-NOC%20%7C%20SOC-purple)

## Objetivo

Este portfólio documenta um ambiente de estudo que cobre as duas pontas de um centro de operações:

- **NOC (Network Operations Center):** manter serviços **no ar e saudáveis** — monitoramento de disponibilidade, métricas, alertas de indisponibilidade, hardening e atualização.

- **SOC (Security Operations Center):** **detectar e responder** a atividade maliciosa — coleta de logs, SIEM, regras de detecção, correlação, resposta automática e caça a ameaças (threat hunting).

Cada componente do laboratório é um exercício isolado, com o propósito de demonstrar hard skills, publicado aqui no GitHub.


## Trilhas de estudo

### Trilha NOC — "manter no ar e enxergar"

1. **vps-hardening** — base de um servidor confiável.

2. **nginx-site-tls** — publicar serviço com TLS e proteção básica.

3. **[zabbix-noc](https://github.com/innexosistemas-lang/zabbix-noc)** — monitorar disponibilidade/recursos e alertar quando algo cai.

4. **[security-scripts](https://github.com/innexosistemas-lang/security-scripts)** — automação de verificações periódicas.

*Habilidades:* Linux, redes/portas, TLS, monitoramento, SLAs/alertas, automação.

### Trilha SOC — "detectar e responder"

1. **cowrie-honeypot** — ver como atacantes reais agem.

2. **[wazuh-soc](https://github.com/innexosistemas-lang/wazuh-soc)** — montar o SIEM e escrever regras.

3. **[attack-detection-web](https://github.com/innexosistemas-lang/attack-detection-web)** — fechar o ciclo ataque ↔ detecção (web).

4. **[active-directory](https://github.com/innexosistemas-lang/active-directory)** — detecção de ataques de identidade (AD).

*Habilidades:* análise de logs, SIEM, regras de correlação, MITRE ATT&CK, threat hunting, resposta automática.


## Padrão de documentação de cada repositório

Cada lab tem seu próprio repositório, com pastas organizadas conforme o tipo de trabalho:

| Lab | Estrutura |
| - | - |
| [zabbix-noc](https://github.com/innexosistemas-lang/zabbix-noc) | `docker/` · `dashboards/` · `incidentes/` |
| [wazuh-soc](https://github.com/innexosistemas-lang/wazuh-soc) | `install/` · `rules/` · `triagem/` |
| [attack-detection-web](https://github.com/innexosistemas-lang/attack-detection-web) | `casos/<técnica-MITRE>/` |
| [active-directory](https://github.com/innexosistemas-lang/active-directory) | README com administração, ataque e detecção |
| [security-scripts](https://github.com/innexosistemas-lang/security-scripts) | scripts Python + instruções de uso |

**Regras comuns a todos os labs:**

- Configurações publicadas **sem segredos** (placeholders no lugar de credenciais).

- Evidências (prints, saídas de comando, logs) **anonimizadas** quando necessário.

- Cada `README.md` traz, no mínimo: **objetivo**, **ambiente**, **roteiro/implementação**, **estrutura de pastas** e, quando houver, as **técnicas MITRE ATT&CK** envolvidas.

*Documento gerado como visão geral do laboratório. Cada laboratório possui (ou possuirá) seu próprio README detalhado no respectivo repositório.*
