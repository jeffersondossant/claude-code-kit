---
description: Verifica se o Antigravity (agy) está instalado, logado e respondendo
allowed-tools: 'Bash(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/status.ps1":*)'
---

Rode pela ferramenta Bash (timeout 180000 ms), exatamente neste formato (aspas duplas e barras `/`), senão a permissão do comando não vale:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/status.ps1"
```

Mostre o resultado em poucas linhas. Se algo falhou, explique o próximo passo indicado pelo script.
