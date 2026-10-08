# Projeto 01 — Reconhecimento de Rede

## Objetivo

Realizar o reconhecimento de rede contra um ambiente corporativo simulado para mapear a superfície de ataque, identificar hosts ativos, portas abertas, serviços em execução e possíveis pontos de entrada.

## Ambiente-Alvo

- Rede corporativa simulada (TechCorp): `10.10.0.0/24`
- Servidor DNS com vulnerabilidade de transferência de zona
- Múltiplos serviços: FTP, SMB, SSH, HTTP, SNMP, API REST

## Habilidades Demonstradas

- Descoberta de hosts e mapeamento de rede
- Varredura de portas e enumeração de serviços (Nmap)
- Enumeração de DNS e exploração de transferência de zona
- Enumeração de SNMP com community strings padrão
- Enumeração de compartilhamentos SMB
- Enumeração de acesso anônimo a FTP
- Documentação da superfície de ataque

## Entregáveis

- [x] [Documentação da metodologia de reconhecimento](metodologia-recon.md)
- [x] [Resultados e análise das varreduras com Nmap](rede/varreduras-nmap.md)
- [x] [Evidência da transferência de zona DNS](rede/transferencia-zona-dns.md)
- [x] [Diagrama da topologia de rede](rede/topologia-rede.md)
- [x] [Relatório completo seguindo o template de pentest](corp-api/relatorio-pentest-corp-api.md) — Corp API (`10.10.0.40`)

> Todos os entregáveis do Projeto 01 concluídos. Os 6 hosts revelados pela
> transferência de zona (`.50`–`.91`) ficam como alvos para os próximos projetos
> quando estiverem online.
