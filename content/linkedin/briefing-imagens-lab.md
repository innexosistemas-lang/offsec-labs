# Briefing de Imagens — Post do Lab (LinkedIn)

> **Objetivo:** criar um **carrossel de 5 slides** que acompanhe o post do lab de Cibersegurança.
> **Mensagem central:** "montei um lab SOC/NOC completo e estou aprendendo construindo — da base pra cima."
> **Você executa as imagens;** este arquivo é o roteiro (texto exato, layout, paleta).

---

## Especificações gerais

| Item | Recomendação |
|---|---|
| Formato | Carrossel (PDF ou PNGs sequenciais) |
| Dimensão | **1080 × 1350 px** (4:5 vertical — ocupa mais a tela no feed) |
| Nº de slides | 5 (capa + 3 de conteúdo + fechamento) |
| Ferramentas sugeridas | **Canva** (capa/layout), **Excalidraw** ou **draw.io** (diagramas) |
| Fonte | Uma sans-serif de peso forte pra títulos (ex.: Inter, Montserrat, Poppins) + mesma família regular no corpo |
| Regra de ouro visual | Pouco texto por slide; 1 ideia por imagem; respiro (margens generosas) |

### Paleta sugerida (tema "blue team / dark")
| Uso | Cor | Hex |
|---|---|---|
| Fundo | Grafite escuro | `#0D1117` |
| Texto principal | Branco gelo | `#E6EDF3` |
| Destaque / acento | Verde terminal | `#2EA043` |
| Alerta / zona exposta | Âmbar/vermelho | `#F0883E` / `#F85149` |
| Zona isolada / confiável | Azul | `#388BFD` |
| Linhas/secundário | Cinza | `#30363D` |

> Dica: fundo escuro com acento verde "terminal" comunica tema de segurança na hora e tem ótimo contraste no feed.

### ⚠️ Segurança (ler antes de usar screenshots reais)
Se for usar print do Grafana/Wazuh/Zabbix como imagem: **borre ou remova** IP público, hostname real (`srv2040813`), usuários e qualquer token/URL. O texto do post não expõe o endereço do lab — as imagens também não devem.

---

## Slide 1 — Capa (gancho)

- **Objetivo:** parar o scroll. Título grande + subtítulo curto.
- **Texto:**
  - Título: `MONTEI MEU LABORATÓRIO DE CIBERSEGURANÇA`
  - Subtítulo: `SOC + NOC · Ataque ↔ Defesa · tudo num servidor Linux`
  - Rodapé pequeno: `→ arrasta pro lado`
- **Visual:** fundo escuro; um ícone de cadeado 🔒 ou terminal `>_` como elemento gráfico; acento verde no título.
- **Layout:** título centralizado no terço superior; subtítulo abaixo; seta de arraste no canto inferior.

---

## Slide 2 — A arquitetura: as 2 zonas (slide mais importante)

- **Objetivo:** mostrar o conceito que estrutura o lab. Este é o slide que demonstra entendimento.
- **Título:** `UMA REGRA DE OURO: ALVO VULNERÁVEL NUNCA NA INTERNET`
- **Diagrama (desenhar em Excalidraw/draw.io):**

```
                 🌐 INTERNET
                      │
          ┌───────────▼───────────┐
          │   FIREWALL (default-deny)   ← a fronteira
          └───────────┬───────────┘
      ┌───────────────┴───────────────┐
      │                               │
┌─────▼─────────┐             ┌────────▼──────────┐
│  ZONA EXPOSTA │             │   ZONA ISOLADA     │
│  (âmbar)      │             │   (azul)           │
│               │             │  só via túnel SSH  │
│ • SSH admin   │             │ • SIEM (Wazuh)     │
│ • Honeypot    │             │ • NOC (Zabbix)     │
│ • Site HTTPS  │             │ • Grafana          │
│               │             │ • DVWA (alvo)      │
│               │             │ • Active Directory │
└───────────────┘             └────────────────────┘
```

- **Visual:** zona exposta em âmbar, zona isolada em azul, firewall como barra no meio. Seta de "túnel SSH" entrando na zona isolada a partir de um ícone de laptop ("eu").
- **Legenda curta no rodapé:** `O firewall é a fronteira. O que não é liberado, não existe pra internet.`

---

## Slide 3 — A stack (o que está rodando)

- **Objetivo:** mostrar amplitude técnica de forma escaneável.
- **Título:** `O QUE ESTÁ NO AR`
- **Conteúdo:** grade de 5 blocos, cada um com ícone + nome + 1 linha:
  - 🛡️ **Hardening** — SSH por chave, firewall default-deny, fail2ban
  - 🍯 **Honeypot (Cowrie)** — captura ataques reais de SSH/Telnet
  - 📊 **NOC (Zabbix + Grafana)** — monitoração e painéis
  - 🚨 **SIEM (Wazuh)** — logs, regras e alertas mapeados ao MITRE ATT&CK
  - 🎯 **Ataque ↔ Defesa** — DVWA + Active Directory isolado
- **Layout:** 5 cards verticais ou grade 2+2+1; ícone à esquerda, texto à direita; bastante respiro.

---

## Slide 4 — O aprendizado: "escutar ≠ exposto"

- **Objetivo:** mostrar profundidade de raciocínio (não só "liguei ferramentas").
- **Título:** `UM SERVIÇO "ESCUTANDO" NÃO É UM SERVIÇO "EXPOSTO"`
- **Conteúdo (comparação visual lado a lado):**
  - Esquerda: `127.0.0.1:porta` → ícone de cadeado → `só local (loopback)`
  - Direita: `0.0.0.0:porta` → `escuta em todas as interfaces` → **MAS** → `o firewall ainda pode bloquear`
- **Faixa de destaque embaixo:** `DEFESA EM PROFUNDIDADE = onde ele escuta + o que o firewall libera`
- **Visual:** duas colunas; usar a cor azul (seguro/loopback) e âmbar (atenção) pra diferenciar.

---

## Slide 5 — Fechamento + CTA

- **Objetivo:** reforçar a postura de aprendizado e chamar interação.
- **Texto:**
  - Título: `ESTUDANDO DA BASE PRA CIMA`
  - Frase de efeito: `"Só se monitora e se defende bem aquilo que se entende primeiro."`
  - CTA: `Também mantém um lab em casa? Bora trocar ideia. 👇`
- **Visual:** fundo escuro, frase de efeito em destaque (itálico ou aspas grandes), acento verde no CTA. Pode repetir o ícone da capa pra fechar o ciclo visual.

---

## Checklist antes de postar
- [ ] Nenhuma imagem mostra IP público, `srv2040813`, usuários ou tokens
- [ ] Texto curto e legível no celular (teste reduzindo a 40% do tamanho)
- [ ] Paleta e fonte consistentes nos 5 slides
- [ ] Slide 1 tem gancho forte (é o que decide o clique)
- [ ] Ordem: capa → arquitetura → stack → conceito → fechamento

---

## Opcional — 6º slide (prova real)
Se quiser uma imagem "de prova", um print **sanitizado** de um painel do Grafana (SOC/Wazuh ou NOC/Zabbix) com dados borrados funciona bem como última imagem. Mostra que não é só teoria — está rodando de verdade.
