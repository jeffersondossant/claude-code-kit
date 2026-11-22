# Claude Code Kit

*[Versão em português](README.md). Scripts and the full tutorial are in Portuguese.*

A Windows kit to keep **Claude Code** working when your usage limit runs out:

- **OmniRoute**: a local proxy (`http://localhost:20128`) between Claude Code and several providers. It includes:
  - **automatic fallback**: Claude → Codex → free tiers (NVIDIA NIM, Gemini, OpenRouter) → paid OpenAI last;
  - **token compression** (Lite + RTK);
  - a protected data folder, auto-start with Windows and an **encrypted backup** (AES-256);
  - a **read-only MCP server**, so Claude can check quota and proxy health.
- **Antigravity (`agy`)**: a helper with a **separate quota** (Google AI Pro). A Claude Code plugin delegates research, large reads, second opinions and whole tasks to it.
- **Continuity**: if every model is exhausted, **Ctrl+Alt+Shift+A** in VS Code opens Antigravity in the project. It reads `CLAUDE.md`, `ANDAMENTO.md` (handoff notes) and `git status`, then picks up where Claude stopped.

Nothing personal lives in this repository. Your accounts, keys and data stay on your machine, in a folder you choose, and the backup is encrypted with a password only you know.

## Install

**Requirements:**
- Windows 11 with `winget`;
- a Claude Pro/Max subscription;
- optional: ChatGPT (Codex) subscription, **free** NVIDIA NIM and OpenRouter accounts, Gemini API (AI Studio), OpenAI API and a Google account with **Google AI Pro**.

1. Get the kit:
   ```powershell
   git clone https://gitlab.com/jeffersondossant/claude-code-kit.git "$env:USERPROFILE\claude-code-kit"
   ```
   No Git? Use **Code → Download ZIP** on the project page.
2. In an **Administrator** PowerShell, inside the kit folder:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\instalar.ps1
   ```
   It asks for a base folder, then installs and configures everything:
   - Git, Node.js LTS, VS Code and the Antigravity CLI, via `winget`;
   - Claude Code;
   - OmniRoute;
   - the `agy` plugin, the global rules and the VS Code shortcut;
   - the read-only MCP server.

   At the end it **lists the remaining manual steps**: the OmniRoute dashboard, the API key in `settings.json`, compression and the MCP key. Add `-Simular` for a dry run.
3. Follow that list with the [full tutorial](docs/TUTORIAL-INSTALACAO.md) (Portuguese).

**Antigravity plugin only:** in Claude Code, run `/plugin marketplace add https://gitlab.com/jeffersondossant/claude-code-kit.git`, then `/plugin install agy@claude-code-kit`.

**Plugin commands:**
| Command | What it does |
|---|---|
| `/agy:perguntar` | ask |
| `/agy:pesquisar` | research with sources |
| `/agy:revisar` | review your changes |
| `/agy:delegar` | hand off a task (edits files, never commits) |
| `/agy:status` | health check |

## Configuration
Copy `config.exemplo.psd1` to **`config.local.psd1`**. It is git-ignored, and the installer creates it on first run.

| Key | Default | Meaning |
|---|---|---|
| `PastaBase` | `%USERPROFILE%\claude-code` | base folder for OmniRoute data and backups |
| `VersaoOmniRoute` | `3.8.54` | pinned OmniRoute version |
| `EnviarBackupAoGit` | `$false` | `$true` only if **your** repository is private |

## Security notes
- **Data folder:** OmniRoute's data folder is restricted to your user, SYSTEM and Administrators.
- **Encrypted backup:** AES-256-CBC with HMAC-SHA256, and the key derived from your password by PBKDF2 (600k iterations). `backup.ps1` refuses to push to a public repository.
- **MCP:** scope enforcement blocks every write tool.
- **The Antigravity login is never used as an API through OmniRoute**, which could break Google's terms. `agy` is always invoked as itself.

## License
[MIT](LICENSE). OmniRoute, Claude Code and Antigravity belong to their respective owners; this kit only installs and wires them together.
