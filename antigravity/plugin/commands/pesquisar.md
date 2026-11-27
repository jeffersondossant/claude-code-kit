---
description: Pede ao Antigravity (agy) uma pesquisa na web ou nos arquivos do projeto, com fontes
argument-hint: "[--modelo hydrogen|sonnet|opus] <tema da pesquisa>"
allowed-tools: 'Bash(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1":*)'
---

Peça ao Antigravity uma pesquisa sobre: $ARGUMENTS

1. Se o texto começar com `--modelo <nome>`, use esse modelo; senão, `hydrogen`.
2. Monte um prompt autossuficiente pedindo: pesquisa na web (e, se o tema for do projeto, a leitura dos arquivos relevantes: localize-os antes com Glob/Grep e passe os **caminhos completos**, pois o agy não lista pastas em modo leitura), resposta em português, **fontes com links**, data das informações e um resumo final de 5 linhas no máximo.
   Nunca inclua segredos (`.env`, tokens, chaves) no prompt.
3. Rode pela ferramenta Bash **em segundo plano** (`run_in_background: true`; em primeiro plano a ferramenta espera no máximo 10 min), em modo leitura, com `-Minutos 15`. Use o comando exatamente neste formato (aspas duplas e barras `/` no caminho da ponte), senão a permissão do comando não vale. Espere o aviso de que terminou e leia a saída:
   ```bash
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1" -Modelo <modelo> -Modo leitura -Minutos 15 -Pasta "<pasta atual>" <<'PROMPT_AGY'
   <prompt da pesquisa>
   PROMPT_AGY
   ```
4. Apresente o resultado, deixando claro que veio do Antigravity. Mantenha as fontes. Não acrescente fatos que não estejam na resposta.
