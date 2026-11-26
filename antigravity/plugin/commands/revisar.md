---
description: Pede ao Antigravity (agy) uma segunda opinião sobre as mudanças atuais ou um arquivo
argument-hint: "[--modelo hydrogen|hydrogen-max|sonnet|opus] [arquivo ou foco da revisão]"
allowed-tools: Bash(powershell.exe:*), Bash(git diff:*), Bash(git status:*)
---

Peça ao Antigravity uma revisão. Foco indicado pelo usuário: $ARGUMENTS

1. Se o texto começar com `--modelo <nome>`, use esse modelo; senão, `hydrogen`.
2. Descubra o que revisar:
   - Se um arquivo foi indicado, revise esse arquivo.
   - Senão, use as mudanças não enviadas: `git status --short` e `git diff` (e `git diff --cached`). Se não houver mudanças, pergunte ao usuário o que revisar.
3. Monte um prompt autossuficiente: objetivo das mudanças (resuma a partir desta conversa), o diff e os **caminhos completos** dos arquivos alterados (o agy lê arquivos pelo caminho, mas não lista pastas nem roda comandos em modo leitura). Peça: erros de lógica, riscos de segurança, casos não tratados e melhorias, **em ordem de gravidade**, cada um com arquivo e linha. Peça para não reescrever o código inteiro.
   Nunca inclua segredos (`.env`, tokens, chaves) no prompt.
   Se o diff passar de ~25 mil caracteres, não cole: liste os caminhos completos dos arquivos (dentro da pasta do projeto; o agy não lê pastas temporárias) e peça para lê-los. No Windows, a linha de comando aceita no máximo ~32 mil caracteres.
4. Rode pela ferramenta Bash (timeout 600000 ms), em modo leitura:
   ```bash
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1" -Modelo <modelo> -Modo leitura -Pasta "<pasta atual>" <<'PROMPT_AGY'
   <prompt da revisão>
   PROMPT_AGY
   ```
5. Mostre os apontamentos do Antigravity e, para cada um, diga se você concorda e por quê. Não aplique correções sem o usuário pedir.
