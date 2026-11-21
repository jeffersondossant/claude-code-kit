---
description: Entrega uma tarefa inteira ao Antigravity (agy), que pode alterar arquivos do projeto
argument-hint: "[--modelo flash|sonnet|opus] <tarefa>"
allowed-tools: Bash(powershell.exe:*), Bash(git status:*), Bash(git diff:*)
---

Delegue ao Antigravity a tarefa: $ARGUMENTS

1. Se o texto começar com `--modelo <nome>`, use esse modelo. Senão, use `sonnet` para tarefas de código e `flash` para o resto.
2. Antes de rodar, rode `git status --short` e anote o estado, para comparar depois.
3. Monte um prompt autossuficiente: objetivo, arquivos envolvidos, regras do projeto que importam (leia o `CLAUDE.md` do projeto, se houver), critério de pronto. Peça ao agy que **não faça commit nem push** e que termine listando os arquivos alterados.
4. Rode pela ferramenta Bash (timeout 1800000 ms), em **modo edição**, com `-Minutos 30`:
   ```bash
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1" -Modelo <modelo> -Modo edicao -Minutos 30 -Pasta "<pasta atual>" <<'PROMPT_AGY'
   <prompt da tarefa>
   PROMPT_AGY
   ```
5. Depois, rode `git status --short` e `git diff --stat`, confira as mudanças e apresente ao usuário: o que o agy fez, os arquivos alterados e qualquer problema que você notar. Não faça commit.
