---
description: Verifica se o Antigravity (agy) está instalado, logado e respondendo
allowed-tools: Bash(powershell.exe:*)
---

Rode pela ferramenta Bash (timeout 180000 ms):

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/status.ps1"
```

Mostre o resultado em poucas linhas. Se algo falhou, explique o próximo passo indicado pelo script.
