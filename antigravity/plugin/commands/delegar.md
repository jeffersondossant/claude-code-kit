---
description: Entrega uma tarefa inteira ao Antigravity (agy), que pode alterar arquivos do projeto
argument-hint: "[--modelo hydrogen|sonnet|opus] <tarefa>"
allowed-tools:
  - 'Bash(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1":*)'
  - Bash(git status:*)
  - Bash(git diff:*)
---

Delegue ao Antigravity a tarefa: $ARGUMENTS

1. Se o texto começar com `--modelo <nome>`, use esse modelo. Senão, use `sonnet` para tarefas de código e `hydrogen` para o resto. Se a saída trouxer erro 429 de cota (Claude e GPT têm cota semanal própria no Antigravity), refaça com `hydrogen`.
2. Antes de rodar, rode `git status --short` e anote o estado, para comparar depois.
3. Monte um prompt autossuficiente: objetivo, arquivos envolvidos, regras do projeto que importam (leia o `CLAUDE.md` do projeto, se houver), critério de pronto. Peça ao agy que **não faça commit nem push** e que termine listando os arquivos alterados.
   No modo edição o agy **não usa o terminal e não lê nada fora da pasta do projeto** (as duas ações são negadas e ele termina sem resposta). Então não peça para rodar comandos (testes, `git`, `bash -n`: rode você antes e informe o resultado no prompt) e cite só arquivos de dentro da pasta, pelo caminho, sem `CLAUDE.md` de pastas acima.
   Nunca inclua segredos (`.env`, tokens, chaves) no prompt.
4. Rode pela ferramenta Bash **em segundo plano** (`run_in_background: true`; em primeiro plano a ferramenta espera no máximo 10 min), em **modo edição**, com `-Minutos 30`. Use o comando exatamente neste formato (aspas duplas e barras `/` no caminho da ponte), senão a permissão do comando não vale. Espere o aviso de que terminou e leia a saída:
   ```bash
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1" -Modelo <modelo> -Modo edicao -Minutos 30 -Pasta "<pasta atual>" <<'PROMPT_AGY'
   <prompt da tarefa>
   PROMPT_AGY
   ```
5. Depois, rode `git status --short` e `git diff --stat`, confira as mudanças e apresente ao usuário: o que o agy fez, os arquivos alterados e qualquer problema que você notar. Não faça commit.
