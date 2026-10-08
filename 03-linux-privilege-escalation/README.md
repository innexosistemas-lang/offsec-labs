# Projeto 03 — Escalação de Privilégios no Linux

## Objetivo

Obter acesso inicial como usuário de baixo privilégio em alvos Linux customizados e escalar até root por meio de múltiplos vetores de ataque.

## Ambiente-Alvo

- Alvo Alpha (`10.10.0.10`) — 7 vetores de privesc
- Alvo Bravo (`10.10.0.20`) — 8 vetores de privesc incluindo movimentação lateral

## Habilidades Demonstradas

- Exploração de binários SUID (find, nmap)
- Abuso de sudo mal configurado (vim, tar)
- Exploração de tarefas cron (scripts graváveis, injeção por wildcard)
- Abuso de capabilities do Linux (cap_setuid no Python)
- Descoberta de arquivos sensíveis (/etc/shadow gravável, chaves SSH expostas)
- Coleta de credenciais (bash_history, arquivos de configuração)
- Movimentação lateral entre usuários
- Sequestro de PATH (PATH hijacking)

## Entregáveis

- [ ] Alvo Alpha — todos os 7 caminhos de privesc documentados
- [ ] Alvo Bravo — cadeia de ataque completa de webdev a root
- [ ] Análise com LinPEAS e comparação com enumeração manual
- [ ] Relatório completo seguindo o template de pentest
