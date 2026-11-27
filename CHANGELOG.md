# Changelog

## 0.4.0 — 2026-11-26
- Porte do `claude-code-setup` 0.7.7 e 0.8.2 a 0.8.8. Plugin `agy` 0.2.1 → 0.3.0.
- **Ponte `agy.ps1`:**
  - valida `-Minutos` (inteiro de 1 a 60, padrão 9), `-Pasta` (precisa existir), `-ArquivoPrompt` e `-Modelo`, com mensagens claras;
  - espera até `Minutos × 60 + 20` s, para caber nos 600 s da ferramenta Bash em primeiro plano;
  - no tempo esgotado, `taskkill /T` encerra também os processos filhos;
  - o `--add-dir` da pasta base só entra no modo leitura (no modo edição daria escrita aos projetos vizinhos);
  - no modo edição, o prompt avisa que não há terminal nem leitura fora da pasta (antes o agy tentava, a ação era negada e ele terminava sem resposta).
- **Comandos `/agy:*`:** o `allowed-tools` libera só a ponte (`${CLAUDE_PLUGIN_ROOT}/scripts/agy.ps1`) ou o `status.ps1`, e não mais qualquer `powershell.exe`. Testado com `claude -p` só com o plugin do kit: `/agy:status` e `/agy:perguntar` rodaram sem pedir permissão. `/agy:pesquisar` e `/agy:delegar` rodam em segundo plano (pediam mais que os 10 min da ferramenta). `/agy:delegar`: com erro 429 em `sonnet`/`opus`, refazer com `hydrogen`.
- **Continuar no Antigravity:** a tarefa do VS Code (Ctrl+Alt+Shift+A) mostra um menu de modelo. A opção "sugerido" lê a última linha `**Próxima etapa:** <apelido>` do `ANDAMENTO.md` (sem ela, `opus`). `continuar.ps1` ganha `-Modelo sugerido` e `-ApenasModelo` (teste).
- `regras/gemini-global.md`: seção "Escolha de modelo" (tabela de apelidos e formato da linha Próxima etapa) e exceção para pedidos vindos da ponte (pulam a rotina de início e o `ANDAMENTO.md`, que ali seriam negados).
- `omniroute/claude-settings.exemplo.json`: `availableModels` (opus, sonnet, `claude-sonnet-5-5`, haiku e os 3 combos), que esconde e bloqueia o Fable; sai o `ANTHROPIC_DEFAULT_FABLE_MODEL`.
- **Combos de exemplo:** sem o OpenRouter (mistura modelos pagos aos gratuitos; um teste em massa no painel gerou cobrança) e sem o Haiku 4.5. `claude-rapido-fallback` começa pelo Haiku 5.5. Ficam 14, 13 e 6 modelos. README e tutorial atualizados.

## 0.3.1 — 2026-11-26
- Correções da revisão do Antigravity (Gemini 4 Hydrogen) sobre a 0.3.0. Plugin `agy` 0.2.0 → 0.2.1.
- `agy.ps1`: lê a saída do `agy` de forma assíncrona, então o tempo limite (`-Minutos`) passa a valer mesmo se o `agy` travar; pedido acima de 32 mil caracteres (limite da linha de comando do Windows) dá mensagem clara em vez de exceção.
- `regras/delegacao.md`: nova regra "Sessão fora do OmniRoute" (na aba Code do app desktop, `haiku`/`sonnet` dos subagentes e o subagente `agy` dão 404; usar Glob/Grep/Read direto e os comandos `/agy:*`).
- Comandos `/agy:perguntar`, `/agy:pesquisar` e `/agy:delegar` repetem a proibição de enviar segredos; `/agy:revisar` orienta a passar caminhos em vez de colar diffs grandes.

## 0.3.0 — 2026-11-26
- Porte do `claude-code-setup` 0.8.0: **Gemini 4 Hydrogen** no plugin `agy` (0.1.0 → 0.2.0). Apelidos `hydrogen` (high, novo padrão), `hydrogen-max` e `hydrogen-rapido`; `flash` e `flash-rapido` continuam. Agente, comandos, `status.ps1` e `continuar.ps1` atualizados.
- `antigravity/regras/delegacao.md`: nova seção "Escolha de modelo e economia de tokens" (escada Haiku → Sonnet → Opus → `agy`, subagentes simples com `model: haiku`, linha "Próxima etapa" no fim de cada etapa, troca do modelo principal só com a validação do usuário).

## 0.2.4 — 2026-11-23
- Espelho público no GitHub criado em `https://github.com/jeffersondossant/claude-code-kit`, mantendo o GitLab como origem e os dois repositórios sincronizados.
- `README.md`: instalação e marketplace do plugin agora mostram o GitHub como endereço principal e o GitLab como alternativa equivalente.

## 0.2.3 — 2026-11-23
- `omniroute/scripts/backup.ps1`: o backup é gravado em `.tmp` e só no fim vira o definitivo (`[IO.File]::Replace` com `[NullString]::Value`, porque `$null` falha no PowerShell 5.1). Se algo falhar, o backup anterior fica intacto.
- `instalar.ps1`: `try/catch/finally` apaga a pasta temporária com as chaves mesmo se o `restaurar.ps1` falhar.
- `omniroute/scripts/lib/cripto.ps1`: `Dispose` do `CreateEncryptor`/`CreateDecryptor`. Formato, algoritmo e derivação de chave inalterados (backups antigos continuam legíveis).

## 0.2.2 — 2026-11-23
- Rodapé "Comandos para agora": legendas corrigidas em `antigravity/regras/delegacao.md`. `/model opusplan` não tira do modo Plano; quem entra e sai é o `Shift+Tab`. O `/model opusplan` ficou só depois de `/model claude-pro-fallback`, para voltar à divisão automática.

## 0.2.1 — 2026-11-23
- **Rodapé "Comandos para agora"**: regra nova em `antigravity/regras/delegacao.md`. O Claude fecha as respostas úteis com 2 a 4 comandos escolhidos pelo contexto atual, cada um com uma legenda curta, a partir de uma tabela de contextos (para não inventar comandos). Omitido em respostas curtas e sem repetição em sequência.

## 0.2.0 — 2026-11-23
- **Cada trabalho no modelo certo (`opusplan`)**, para poupar a cota do Opus:
  - modo Plano → `claude-pro-fallback` (Opus primeiro);
  - execução e subagentes → `claude-sonnet-fallback` (sem Opus);
  - tarefas de fundo → `claude-rapido-fallback` (Haiku e gratuitos, sem pagos).
  
  Todos com fallback. O modelo de `settings.json` usa `opusplan`, os `ANTHROPIC_DEFAULT_OPUS/SONNET/HAIKU_MODEL` apontam para os combos e `CLAUDE_CODE_SUBAGENT_MODEL` = `sonnet`.
- Exemplos `omniroute/exemplos/combo-claude-sonnet-fallback.json` e `combo-claude-rapido-fallback.json`.
- Tutorial: etapa 3C.3a (combos por papel e o cuidado com a regra de roteamento por chave, que deve valer só para `cc/*`), tabela da etapa 4 e conferência pela coluna *Combinação* dos Logs.

## 0.1.4 — 2026-11-23
- Tutorial: **troca proativa de conta aos 95%** com os pontos de corte por conta do OmniRoute (Quota Preflight). As assinaturas são puladas antes do erro de limite.

## 0.1.3 — 2026-11-21
- **Regra do `ANDAMENTO.md` reforçada (obrigatória, sem exceção)** no `CLAUDE.md` e no `GEMINI.md` globais instalados pelo kit:
  - ler antes de agir e atualizar na mesma resposta sempre que algo for concluído, decidido, ficar pendente ou for configurado fora do repositório;
  - atualizar antes de cada commit;
  - estrutura fixa, com a "Situação atual" reescrita (não diário).
  - Saiu a exceção para tarefas de um passo.

## 0.1.2 — 2026-11-21
- Combo de exemplo com **17 modelos**: assinaturas (Claude, Codex) → gratuitos (NVIDIA NIM: Kimi K3.1 Pro, Nemotron 3 Ultra, GLM 5.3 Flash, MiniMax M3.1 Flash; Gemini; OpenRouter `:free`) → OpenAI paga por último. Todos testados numa tarefa real do Claude Code com ferramentas.
- Tutorial: critério para provedores gratuitos (~60 mil tokens por requisição + ferramentas; Groq gratuito não aguenta), "Importar de /models" e como limitar o gasto da OpenAI (créditos pré-pagos, sem recarga automática). O orçamento do OmniRoute bloqueia a chave inteira, por isso não é usado para isso.

## 0.1.1 — 2026-11-21
- **A tarefa `OmniRoute` roda em segundo plano** (S4U, sem janela), liga com o Windows e no logon, e tem um **vigia a cada 5 minutos**. Antes, rodando "no logon", o Windows 11 podia prender o PowerShell oculto a uma janela de terminal, e fechar essa janela ou bloquear a tela derrubava o servidor (`0xC000013A`).
- Tutorial atualizado (tarefa, conferência e problemas comuns).

## 0.1.0 — 2026-11-21
Primeira versão pública. Derivada do repositório pessoal `claude-code-setup` (0.5.0), sem nenhum dado pessoal e sem o histórico dele.

- **Configuração** por `config.local.psd1` (só dados, fora do Git), lida por `lib/config.ps1`: pasta base, pasta de dados do OmniRoute, backups, versão do OmniRoute, envio do backup ao Git, nome e e-mail do Git.
- **`instalar.ps1`** único: winget (Git, Node.js LTS, VS Code, Antigravity CLI), Claude Code e extensões, `settings.json` (do backup ou do modelo), OmniRoute, login do agy, plugin, regras e MCP. Pula o que já existe, tem `-Simular` e lista as configurações internas que faltam.
- **Plugin `agy` portátil**: comandos e agente usam `${CLAUDE_PLUGIN_ROOT}`; `/agy:status` usa `plugin/scripts/status.ps1`, que fica dentro do plugin; a pasta base vem de `CLAUDE_KIT_PASTA_BASE`.
- **Backup cifrado** fora do repositório por padrão. Com `EnviarBackupAoGit`, o envio é recusado se o repositório for público.
- Exemplo de combo de fallback em `omniroute/exemplos/`.
- Tutorial genérico, `README.en.md` e licença MIT.
