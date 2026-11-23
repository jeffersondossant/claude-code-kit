# Changelog

## 0.1.4 — 2026-11-23
- Tutorial: **troca proativa de conta aos 95%** com os pontos de corte por conta do OmniRoute (Quota Preflight). As assinaturas são puladas antes do erro de limite.

## 0.1.3 — 2026-11-21
- **Regra do `ANDAMENTO.md` reforçada (obrigatória, sem exceção)** no `CLAUDE.md` e no `GEMINI.md` globais instalados pelo kit:
  - ler antes de agir e atualizar na mesma resposta sempre que algo for concluído, decidido, ficar pendente ou for configurado fora do repositório;
  - atualizar antes de cada commit;
  - estrutura fixa, com a "Situação atual" reescrita (não diário).
  - Saiu a exceção para tarefas de um passo.

## 0.1.2 — 2026-11-21
- Combo de exemplo com **17 modelos**: assinaturas (Claude, Codex) → gratuitos (NVIDIA NIM: Kimi K3.1 Pro, Nemotron 3 Ultra, GLM 5.3 Flash, MiniMax M3.1 Flash; Gemini; OpenRouter `:free`) → OpenAI paga por último. Todos testados numa tarefa real do Claude Code com ferramentas.
- Tutorial: critério para provedores gratuitos (~60 mil tokens por requisição + ferramentas; Groq gratuito não aguenta), "Importar de /models" e como limitar o gasto da OpenAI (créditos pré-pagos, sem recarga automática). O orçamento do OmniRoute bloqueia a chave inteira, por isso não é usado para isso.

## 0.1.1 — 2026-11-21
- **A tarefa `OmniRoute` roda em segundo plano** (S4U, sem janela), liga com o Windows e no logon, e tem um **vigia a cada 5 minutos**. Antes, rodando "no logon", o Windows 11 podia prender o PowerShell oculto a uma janela de terminal, e fechar essa janela ou bloquear a tela derrubava o servidor (`0xC000013A`).
- Tutorial atualizado (tarefa, conferência e problemas comuns).

## 0.1.0 — 2026-11-21
Primeira versão pública. Derivada do repositório pessoal `claude-code-setup` (0.5.0), sem nenhum dado pessoal e sem o histórico dele.

- **Configuração** por `config.local.psd1` (só dados, fora do Git), lida por `lib/config.ps1`: pasta base, pasta de dados do OmniRoute, backups, versão do OmniRoute, envio do backup ao Git, nome e e-mail do Git.
- **`instalar.ps1`** único: winget (Git, Node.js LTS, VS Code, Antigravity CLI), Claude Code e extensões, `settings.json` (do backup ou do modelo), OmniRoute, login do agy, plugin, regras e MCP. Pula o que já existe, tem `-Simular` e lista as configurações internas que faltam.
- **Plugin `agy` portátil**: comandos e agente usam `${CLAUDE_PLUGIN_ROOT}`; `/agy:status` usa `plugin/scripts/status.ps1`, que fica dentro do plugin; a pasta base vem de `CLAUDE_KIT_PASTA_BASE`.
- **Backup cifrado** fora do repositório por padrão. Com `EnviarBackupAoGit`, o envio é recusado se o repositório for público.
- Exemplo de combo de fallback em `omniroute/exemplos/`.
- Tutorial genérico, `README.en.md` e licença MIT.
