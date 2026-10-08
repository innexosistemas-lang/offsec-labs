# Projeto 04 — Análise do OWASP Top 10

## Objetivo

Demonstrar o entendimento prático de cada categoria do OWASP Top 10 (2021) por meio de exploração e remediação hands-on no ambiente de laboratório.

## Cobertura do OWASP Top 10

| # | Categoria | Alvo no Laboratório |
|---|-----------|---------------------|
| A01 | Controle de Acesso Quebrado | IDOR e mass assignment na API |
| A02 | Falhas Criptográficas | Credenciais em texto puro em arquivos FTP/config |
| A03 | Injeção | SQLi no login e na busca da API |
| A04 | Design Inseguro | Enumeração previsível de usuários |
| A05 | Configuração Insegura | Community SNMP padrão, transferência de zona DNS, FTP anônimo |
| A06 | Componentes Vulneráveis | Vulnerabilidades conhecidas do DVWA e Juice Shop |
| A07 | Falhas de Autenticação | Senhas fracas, segredo fraco de JWT |
| A08 | Falhas de Integridade de Software | Scripts de cron graváveis |
| A09 | Falhas de Registro (Logging) | Ausência de monitoramento nos alvos |
| A10 | SSRF | Desafios de SSRF do Juice Shop |

## Entregáveis

- [ ] Um exploit documentado por categoria do OWASP
- [ ] Orientação de remediação para cada descoberta
- [ ] Mapeamento entre as descobertas do laboratório e o impacto no mundo real
- [ ] Relatório completo seguindo o template de pentest
