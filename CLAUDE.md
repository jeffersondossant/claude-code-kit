# CLAUDE.md — Claude Code Kit

Responda sempre em **Português do Brasil**.

## Sobre
Kit **público** (MIT) para o Claude Code no Windows: OmniRoute (fallback, compressão, backup cifrado, MCP somente leitura) e Antigravity (plugin `agy`, continuidade pelo VS Code). Veja o `README.md`.

## Como rodar
```powershell
powershell -ExecutionPolicy Bypass -File .\instalar.ps1 -Simular
powershell -ExecutionPolicy Bypass -File .\antigravity\scripts\verificar.ps1 -SemTesteReal
claude plugin validate .
```

## Regras do projeto
- **Nada pessoal no repositório**:
  - nenhum caminho de máquina, nome de usuário, e-mail, conta ou chave;
  - caminhos saem do `lib\config.ps1`, que lê o `config.local.psd1` (fora do Git);
  - antes de cada commit, procure `sk-`, `AIza`, e-mails, IPs e caminhos absolutos.
- **Plugin `agy`**: ele pode ser instalado sozinho (de um repositório remoto), então nunca depende de arquivos fora de `antigravity/plugin/`. Use `${CLAUDE_PLUGIN_ROOT}` nos comandos e no agente; a pasta base vem da variável `CLAUDE_KIT_PASTA_BASE`.
- **PowerShell 5.1**:
  - os `.ps1` ficam em **UTF-8 com BOM**;
  - para passar texto livre a programas externos, use a montagem de argumentos da `agy.ps1`, porque o 5.1 remove aspas;
  - não use `$ErrorActionPreference = 'Stop'` com programas que escrevem avisos no stderr (git, claude, npm).
- **Criptografia** (`omniroute/scripts/lib/cripto.ps1`): manter a leitura dos backups antigos (cabeçalho `OMRBKP01`).
- **Antigravity**: nunca montar proxy/roteador que use o login do `agy` como API do Claude Code (termos do Google).
- Antes de mover ou apagar arquivos, mostrar o plano e pedir confirmação. Commit e push só quando o usuário pedir.
- A cada mudança: atualizar `README.md` (e `README.en.md` se mudar algo visível) e `CHANGELOG.md`.

## Relação com o repositório pessoal
Este kit nasceu do `claude-code-setup` (privado, do autor). Melhorias genéricas: fazer **aqui** e portar para o pessoal.

## Publicação
GitLab: `https://gitlab.com/jeffersondossant/claude-code-kit` (público).
