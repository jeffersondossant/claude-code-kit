# Changelog

## 0.1.0 — 2026-11-21
Primeira versão pública. Derivada do repositório pessoal `claude-code-setup` (0.5.0), sem nenhum dado pessoal e sem o histórico dele.

- **Configuração** por `config.local.psd1` (só dados, fora do Git), lida por `lib/config.ps1`: pasta base, pasta de dados do OmniRoute, backups, versão do OmniRoute, envio do backup ao Git, nome e e-mail do Git.
- **`instalar.ps1`** único: winget (Git, Node.js LTS, VS Code, Antigravity CLI), Claude Code e extensões, `settings.json` (do backup ou do modelo), OmniRoute, login do agy, plugin, regras e MCP. Pula o que já existe, tem `-Simular` e lista as configurações internas que faltam.
- **Plugin `agy` portátil**: comandos e agente usam `${CLAUDE_PLUGIN_ROOT}`; `/agy:status` usa `plugin/scripts/status.ps1`, que fica dentro do plugin; a pasta base vem de `CLAUDE_KIT_PASTA_BASE`.
- **Backup cifrado** fora do repositório por padrão. Com `EnviarBackupAoGit`, o envio é recusado se o repositório for público.
- Exemplo de combo de fallback em `omniroute/exemplos/`.
- Tutorial genérico, `README.en.md` e licença MIT.
