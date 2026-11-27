---
description: Faz uma pergunta direta ao Antigravity (agy) e mostra a resposta
argument-hint: "[--modelo hydrogen|hydrogen-rapido|sonnet|opus|gpt] <pergunta>"
allowed-tools: 'Bash(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1":*)'
---

Envie a pergunta abaixo ao Antigravity e mostre a resposta ao usuário.

Pergunta: $ARGUMENTS

1. Se a pergunta começar com `--modelo <nome>`, use esse modelo e retire a opção do texto. Senão, use `hydrogen`.
   Nunca inclua segredos (`.env`, tokens, chaves) no prompt.
2. Rode pela ferramenta Bash (timeout 600000 ms), em modo leitura, na pasta atual do projeto. Use o comando exatamente neste formato (aspas duplas e barras `/` no caminho da ponte), senão a permissão do comando não vale:
   ```bash
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1" -Modelo <modelo> -Modo leitura -Pasta "<pasta atual>" <<'PROMPT_AGY'
   <pergunta, com o contexto mínimo para ser entendida fora desta conversa>
   PROMPT_AGY
   ```
3. Mostre a resposta indicando que veio do Antigravity (e o modelo). Se houver erro, mostre-o e sugira `/agy:status`.
