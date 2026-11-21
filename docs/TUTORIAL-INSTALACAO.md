# Tutorial de instalação: claude-code-kit

Monta no Windows o ambiente completo:
**VS Code → Claude Code → OmniRoute (fallback, compressão, backup cifrado, MCP) → Antigravity (Gemini Pro)**.

Testado com: Windows 11 Pro, Git 2.56, Node.js 26, VS Code 1.147, Claude Code 2.1.328, OmniRoute 3.8.54 e Antigravity CLI 1.5.14.

> **Como ler:** cada etapa termina com uma ✅ **conferência**. Só avance quando ela der certo.
> 🛡️ = PowerShell **como Administrador** (menu Iniciar → digite *PowerShell* → *Executar como administrador*).
> Os comandos com `.\` rodam **na pasta do kit** (`cd` até ela antes).

## ⚡ Caminho rápido

1. **Contas** que você vai usar: veja a [etapa 0](#0-antes-de-começar).
2. **Baixe o kit**, em qualquer pasta:
   - com Git: `git clone https://gitlab.com/jeffersondossant/claude-code-kit.git "$env:USERPROFILE\claude-code-kit"`
   - sem Git: na página do projeto no GitLab, use **Code → Download ZIP** e extraia.
3. 🛡️ **Rode o instalador** na pasta do kit:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\instalar.ps1
   ```
   Na primeira vez ele pergunta a **pasta base**, onde ficam os dados do OmniRoute e os backups. Prefira um disco que sobreviva a uma formatação do Windows, como `D:\claude-code`. A resposta fica gravada em `config.local.psd1`.

   Depois o instalador:
   - instala Git, Node.js LTS, VS Code e Antigravity CLI pelo `winget`, e o Claude Code com as extensões do VS Code;
   - prepara o OmniRoute: pasta protegida, `DATA_DIR` e início automático;
   - abre o `agy` para você fazer o login;
   - instala o plugin `agy`, as regras globais e o atalho do VS Code;
   - registra o MCP somente leitura.

   Ele pula o que já estiver pronto e pode ser repetido à vontade. Para ver tudo sem executar nada, use `-Simular`.
4. **Configurações internas**, que o instalador lista no final:
   - painel do OmniRoute ([etapa 3C](#3c-configurar-o-omniroute-pelo-painel));
   - chave no `settings.json` ([etapa 4](#4-ligar-o-claude-code-ao-omniroute));
   - compressão e chave do MCP ([etapa 5](#5-compressão-de-tokens-e-mcp-do-omniroute));
   - primeiro backup ([etapa 7](#7-backup-e-migração-para-outro-pc)).

O restante deste tutorial explica cada etapa e como fazê-la à mão.

## Índice
0. [Antes de começar](#0-antes-de-começar)
1. [Ferramentas básicas](#1-ferramentas-básicas)
2. [Claude Code](#2-claude-code)
3. [OmniRoute](#3-omniroute)
4. [Ligar o Claude Code ao OmniRoute](#4-ligar-o-claude-code-ao-omniroute)
5. [Compressão de tokens e MCP do OmniRoute](#5-compressão-de-tokens-e-mcp-do-omniroute)
6. [Antigravity (Gemini Pro)](#6-antigravity-gemini-pro)
7. [Backup e migração para outro PC](#7-backup-e-migração-para-outro-pc)
8. [Conferência final](#8-conferência-final)
9. [Problemas comuns](#9-problemas-comuns)

---

## 0. Antes de começar

**Contas** (use as que você tiver; o combo de fallback se adapta):
| O quê | Para quê |
|---|---|
| Assinatura Claude (Pro/Max) | provedor principal do OmniRoute ("Claude Code", via OAuth) |
| OpenAI / Codex / Gemini API (opcionais) | provedores de reserva do combo de fallback |
| Conta Google com **Google AI Pro** | Antigravity (`agy`), com cota separada |

**Configuração do kit:** copie `config.exemplo.psd1` para `config.local.psd1` e ajuste. O `instalar.ps1` faz isso por você na primeira vez.
| Chave | Padrão | O que é |
|---|---|---|
| `PastaBase` | `%USERPROFILE%\claude-code` | pasta do ambiente (dados do OmniRoute e backups) |
| `PastaDadosOmni` | `<PastaBase>\omniroute` | `DATA_DIR` do OmniRoute: banco + `.env` com a chave de criptografia |
| `PastaBackups` | `<PastaBase>\backups` | backups cifrados e cópia do histórico do Claude Code |
| `VersaoOmniRoute` | `3.8.54` | versão fixa: o `npx` não troca sozinho |
| `EnviarBackupAoGit` | `$false` | `$true` só se o **seu** repositório for **privado** |

O `config.local.psd1` fica **fora do Git**.

---

## 1. Ferramentas básicas

O `instalar.ps1` faz isso. Para fazer à mão:
```powershell
winget install --id Git.Git -e
```
```powershell
winget install --id OpenJS.NodeJS.LTS -e
```
```powershell
winget install --id Microsoft.VisualStudioCode -e
```
**Feche e abra o PowerShell** e configure o Git:
```powershell
git config --global user.name "Seu Nome"; git config --global user.email "seu-email@exemplo.com"
```
✅ `git --version; node --version; code --version` mostram versões.

---

## 2. Claude Code

```powershell
npm install -g @anthropic-ai/claude-code
```
```powershell
code --install-extension anthropic.claude-code
```
```powershell
code --install-extension ms-ceintl.vscode-language-pack-pt-br
```
**Não configure nada ainda.** Na etapa 4 o Claude Code passa a usar o OmniRoute.

✅ `claude --version` responde, e a extensão **Claude Code** (Anthropic) aparece no VS Code.

---

## 3. OmniRoute

### 3.0 Como ele fica instalado
| Peça | Onde | Quem cuida |
|---|---|---|
| Programa | baixado pelo `npx` (`omniroute@<versão>`) para o cache do npm; sem instalação global | `npx` |
| Versão | `VersaoOmniRoute` no `config.local.psd1` | você |
| Dados (banco + `.env` com a chave de criptografia) | `PastaDadosOmni`, com acesso restrito; variável de usuário `DATA_DIR` | `omniroute\scripts\instalar.ps1` |
| Início automático | tarefa agendada `OmniRoute` (no logon, sem janela) | `omniroute\scripts\instalar.ps1` |
| Painel | http://localhost:20128 | você |
| Backup cifrado | `PastaBackups\omniroute-backup.enc` | `omniroute\scripts\backup.ps1` |

O `omniroute\scripts\instalar.ps1` faz, em ordem:
1. confere o Node.js e se já há banco; se não houver, pede confirmação;
2. **protege a pasta**: acesso só para você, SYSTEM e Administradores;
3. grava a variável **`DATA_DIR`**;
4. cria a tarefa **`OmniRoute`**: `npx -y omniroute@<versão>`, no logon, reiniciando até 3 vezes se falhar;
5. inicia a tarefa e espera a porta 20128 responder, por até 60 s.

Na primeira vez o `npx` baixa o programa: isso leva de 2 a 3 minutos e mostra vários `npm warn`, que são normais.

### 3A. Preparar e ligar
🛡️ Se você usou o `instalar.ps1` da raiz, esta etapa já foi feita.
```powershell
powershell -ExecutionPolicy Bypass -File .\omniroute\scripts\instalar.ps1
```
Na primeira execução o OmniRoute cria, na `PastaDadosOmni`:
- o `.env`, com a **chave de criptografia** (`STORAGE_ENCRYPTION_KEY`), o `JWT_SECRET` e o `API_KEY_SECRET`;
- o banco `storage.sqlite`.

**Nunca apague nem edite o `.env`:** sem ele o banco não pode ser decifrado.

✅ http://localhost:20128 abre a tela de login.

### 3B. Já tem um backup cifrado?
Se você tem um `omniroute-backup.enc` de outra instalação, restaure **antes** de configurar o painel. Provedores, combos, chaves e compressão voltam juntos.
```powershell
powershell -ExecutionPolicy Bypass -File .\omniroute\scripts\restaurar.ps1 -Arquivo "<caminho>\omniroute-backup.enc"
```
Depois, rode o 🛡️ `.\omniroute\scripts\instalar.ps1` de novo e pule para a [etapa 4](#4-ligar-o-claude-code-ao-omniroute).

### 3C. Configurar o OmniRoute pelo painel

**3C.1 Primeiro login e senha**
1. Entre com a senha padrão **`CHANGEME`**, que aparece como dica na tela.
2. Em **Configurações → Segurança**, preencha *Senha Atual*, *Nova Senha* e *Confirmar Nova Senha*, e clique em **Atualizar Senha**.
3. Mantenha **Exigir login** e **Proteção de força bruta de login** ligados. Se quiser mais segurança, ative a *Autenticação em dois fatores*.

**3C.2 Provedores** (menu **Provedores**: **Assistente de integração**, ou abra o provedor e clique em **Adicionar**):
| Provedor no painel | Tipo | Como conectar |
|---|---|---|
| **Claude Code** | OAuth | **Adicionar** → login da sua conta Claude (Pro/Max) → autorize. O token é renovado sozinho. |
| **OpenAI Codex** | OAuth | **Adicionar** → login da conta ChatGPT/Codex. |
| **OpenAI** | Chave de API | **Adicionar** → chave de platform.openai.com. |
| **Gemini (Google AI Studio)** | Chave de API | **Adicionar** → chave do Google AI Studio. |
| **Antigravity / Antigravity CLI** | — | **Deixe desativado.** O Gemini Pro é usado pelo `agy` diretamente (etapa 6). Usar o login do Google como API pelo OmniRoute pode violar os termos do Google. |

Clique em **Testar** em cada um. Os que funcionarem aparecem como *conectado*.

**3C.3 Combo de fallback** (menu **Combinações → Criar Combo**):
- nome **`claude-pro-fallback`**, estratégia **priority**: tenta o 1º modelo; se falhar ou esgotar, o 2º; e assim por diante;
- comece pelos modelos da sua assinatura Claude e termine pelos de reserva. Um exemplo completo está em [`omniroute/exemplos/combo-claude-pro-fallback.json`](../omniroute/exemplos/combo-claude-pro-fallback.json);
- só aparecem modelos de provedores conectados.

✅ `(Invoke-RestMethod http://localhost:20128/api/v1/combos).data | % { $_.name; $_.models.model }` mostra o combo e a ordem.

**3C.4 Chave do Claude Code** (**Gerenciador API → Criar Chave de API**):
- nome **`Claude-Code`**, política padrão;
- **copie a chave**, que só aparece uma vez. Você vai usá-la na etapa 4.

**3C.5 Retenção** (**Configurações → General → Configurações de Retenção**). Os padrões guardam:
- chamadas: 7 dias;
- turnos de conversa e auditoria: 30 dias;
- histórico de uso: 365 dias.

Prazos maiores deixam o banco e o backup maiores.

**3C.6 Segurança de rede (recomendado).** O OmniRoute escuta em `0.0.0.0`, ou seja, aceita conexões da sua rede. Escolha uma das proteções:
- **Configurações → Segurança → Proteção de Endpoint da API**: exigir chave. O Claude Code já envia a chave `Claude-Code`;
- ou **Controle de Acesso por IP** → *Lista de Permissão* `127.0.0.1` e `::1`.

---

## 4. Ligar o Claude Code ao OmniRoute

O Claude Code fala com o OmniRoute pelas variáveis do `%USERPROFILE%\.claude\settings.json`. O `instalar.ps1` copia o [modelo](../omniroute/claude-settings.exemplo.json) para lá, se o arquivo ainda não existir. Abra-o e troque `COLE_AQUI_A_CHAVE_Claude-Code_DO_OMNIROUTE` pela chave da etapa 3C.4:
```powershell
notepad "$env:USERPROFILE\.claude\settings.json"
```
| Chave | Valor | Por quê |
|---|---|---|
| `ANTHROPIC_BASE_URL` | `http://localhost:20128` | manda tudo para o OmniRoute |
| `ANTHROPIC_AUTH_TOKEN` | chave `Claude-Code` | autentica no OmniRoute |
| `ANTHROPIC_MODEL` e `model` | **`claude-pro-fallback`** | **único modelo com fallback automático** |
| `ANTHROPIC_DEFAULT_*_MODEL` | `cc/...` | opções da lista do VS Code; cada uma vai **só para aquele modelo**, sem fallback |
| `cleanupPeriodDays` | `36500` | **não apagar o histórico de conversas** (o padrão apaga após 30 dias). Não use `0`, que em algumas versões significa não guardar nada. |

Reinicie o VS Code. Se o seletor de modelos mostrar outro modelo, digite `/model claude-pro-fallback` no chat. O aviso "doesn't recognize the model" é inofensivo.

✅ No chat, "responda apenas OK" funciona, e a requisição aparece no painel em *Início → Requisições recentes*.

---

## 5. Compressão de tokens e MCP do OmniRoute

### 5.1 Compressão (painel → **Contexto**)
1. **Configurações de compressão:**
   - interruptor **Compressão de prompt** ligado;
   - **Leve** e **RTK** (nível *Mínima*) ligados;
   - **Homem das cavernas** e **Desduplicação de sessão** desligados;
   - **Zona ativa alinhada ao cache** ligada;
   - *Preservar prompt do sistema* = **Sempre**.
2. **Combos de Engines:**
   - crie o combo nomeado **`claude-code-seguro`** com as etapas `lite` e `rtk` (*minimal*);
   - em **Perfil ativo**, selecione esse combo. O resumo deve mostrar "Executa: lite → rtk".

   Sem o combo nomeado, o RTK não roda: o OmniRoute o trata como compressão "com perda" e exige autorização explícita.

✅ Depois de algum uso, *Contexto → RTK* mostra "Tokens filtrados" maior que zero.

### 5.2 MCP somente leitura
1. **Chave `mcp-leitura`** (*Gerenciador API → Criar Chave de API*):
   - marque **Acesso de gerenciamento**, **Custo próprio** e **Cota de conta compartilhada**;
   - em *Personalizar política*:
     - **Geral → IPs permitidos**: `127.0.0.1` e `::1`;
     - **Modelos**: *Restringir*, sem nenhuma regra;
     - **Combos**: *Restringir*, sem nenhum, e **Combos automáticos** desligado;
   - crie a chave e **copie-a**.
2. Grave a chave numa variável do Windows. Ela não aparece na tela:
   ```powershell
   $s = Read-Host 'Cole a chave mcp-leitura' -AsSecureString; [Environment]::SetEnvironmentVariable('OMNIROUTE_API_KEY', [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)), 'User'); Remove-Variable s
   ```
3. O `instalar.ps1` já registra o MCP. Para registrar à mão, use o **Git Bash**, porque o PowerShell engole o `--`. Troque os caminhos e a versão pelos seus:
   ```bash
   claude mcp add omniroute --scope user \
     -e 'DATA_DIR=C:\Users\voce\claude-code\omniroute' -e OMNIROUTE_BASE_URL=http://localhost:20128 \
     -e OMNIROUTE_MCP_ENFORCE_SCOPES=true -e 'OMNIROUTE_MCP_SCOPES=read:*' \
     -- 'C:\Program Files\nodejs\npx.cmd' -y omniroute@3.8.54 --mcp
   ```

As ferramentas de escrita (trocar combo, limpar cache) ficam **bloqueadas** pela trava de escopo.

✅ `claude mcp get omniroute` mostra **✔ Connected**. No chat, "o OmniRoute está saudável?" é respondido.

---

## 6. Antigravity (Gemini Pro)

1. **Instale e entre na conta:**
   ```powershell
   winget install --id Google.AntigravityCLI -e
   ```
   - Rode `agy` uma vez e entre com a conta do **Google AI Pro**. Saia com `/exit`.
   - Se o comando `agy` não for encontrado, rode `& "$env:LOCALAPPDATA\agy\bin\agy.exe" install` e abra outro terminal.
2. **Integração com o Claude Code:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\antigravity\scripts\instalar.ps1
   ```
   O script:
   - grava `CLAUDE_KIT_PASTA_BASE` e instala o plugin `agy@claude-code-kit`, com os comandos `/agy:perguntar`, `/agy:pesquisar`, `/agy:revisar`, `/agy:delegar`, `/agy:status` e o subagente;
   - grava as regras no `CLAUDE.md` global: idioma, delegação e `ANDAMENTO.md`;
   - grava as regras de continuidade no `GEMINI.md` global;
   - cria a tarefa **Continuar no Antigravity** no VS Code, com o atalho **Ctrl+Alt+Shift+A**.

   Só o plugin, sem o resto do kit: `/plugin marketplace add https://gitlab.com/jeffersondossant/claude-code-kit.git` e `/plugin install agy@claude-code-kit`.

✅ `.\antigravity\scripts\verificar.ps1` termina em **"Tudo certo."**, e `/agy:perguntar qual a capital da Austrália?` responde.

**Continuidade:** quando todos os modelos do OmniRoute esgotarem e o chat parar, aperte **Ctrl+Alt+Shift+A**. O `agy` abre no projeto, lê `CLAUDE.md`, `ANDAMENTO.md` e o `git status`, e continua o trabalho. Na 1ª vez em cada projeto ele pergunta se você confia na pasta: responda *Yes, I trust this folder*.

---

## 7. Backup e migração para outro PC

**Backup cifrado** (AES-256, com senha). Faça após mudar provedores, combos ou chaves:
```powershell
powershell -ExecutionPolicy Bypass -File .\omniroute\scripts\backup.ps1
```
- Grava `PastaBackups\omniroute-backup.enc` com o banco, o `.env` e o seu `settings.json`. **Guarde uma cópia fora do PC.** Sem a senha, o backup não abre.
- Com `EnviarBackupAoGit = $true`, ele também faz commit e push, mas **recusa** se o repositório remoto for público.

**Migrar para um PC novo:**
1. **No PC antigo:** `.\salvar-para-pc-novo.ps1` copia o histórico do Claude Code, que fica no C:, para a `PastaBackups` e atualiza o backup.
2. **Leve para o PC novo** a pasta base e o kit, com o mesmo caminho, ou o mesmo disco com a mesma letra. Ajuste o `config.local.psd1` se o caminho mudar.
3. **No PC novo**, 🛡️ `.\instalar.ps1`. Ele devolve o histórico, extrai o `settings.json` do backup (pede a senha) e reconfigura tudo.

**Perdeu a pasta de dados?** Use `.\omniroute\scripts\restaurar.ps1 -Arquivo <backup.enc>` e depois 🛡️ `.\omniroute\scripts\instalar.ps1`.

---

## 8. Conferência final

| Item | Como conferir | Esperado |
|---|---|---|
| OmniRoute no ar | `Invoke-WebRequest http://localhost:20128 -UseBasicParsing` | 200 |
| Inicia com o Windows | `Get-ScheduledTask -TaskName OmniRoute` | `Ready` |
| Pasta de dados | `[Environment]::GetEnvironmentVariable('DATA_DIR','User')` | sua `PastaDadosOmni` |
| Modelo do Claude Code | chat do VS Code | `claude-pro-fallback` |
| Histórico | `(Get-Content "$env:USERPROFILE\.claude\settings.json" -Raw \| ConvertFrom-Json).cleanupPeriodDays` | `36500` |
| Compressão | painel → *Contexto → Combos de Engines* | perfil `claude-code-seguro` |
| MCP | `claude mcp get omniroute` | ✔ Connected |
| Antigravity | `.\antigravity\scripts\verificar.ps1` | Tudo certo |

---

## 9. Problemas comuns

| Sintoma | Causa | Solução |
|---|---|---|
| OmniRoute "zerado", sem provedores | Surgiu `%USERPROFILE%\.omniroute`, que ele prefere quando o `DATA_DIR` não está definido | Confira o `DATA_DIR` (etapa 3) e reinicie o OmniRoute |
| "STORAGE_ENCRYPTION_KEY is not set" | OmniRoute lendo uma pasta sem o `.env` | Mesmo caso acima |
| `Register-ScheduledTask: Acesso negado` | A tarefa foi criada antes como Administrador | Rode o instalador 🛡️ como Administrador |
| "a execução de scripts foi desabilitada" | Política de execução do Windows | `powershell -ExecutionPolicy Bypass -File ...` |
| Chat para quando acaba o limite do Claude | Modelo da lista (`cc/...`) escolhido | `/model claude-pro-fallback` |
| Todos os modelos esgotados | Cotas acabaram | **Ctrl+Alt+Shift+A**, que abre o Antigravity no projeto |
| Conversas antigas sumindo | `cleanupPeriodDays` ausente (o padrão apaga após 30 dias) | Etapa 4 |
| Acentos quebrados nos scripts | `.ps1` salvo sem BOM (PowerShell 5.1) | Salvar como **UTF-8 com BOM** |
| `claude mcp add` reclama de `-y` | O PowerShell engoliu o `--` | Rode no **Git Bash** |
| MCP responde 401 | Falta a `OMNIROUTE_API_KEY` | Etapa 5.2 e reiniciar o VS Code |
| `/agy:*` não aparece | Plugin não carregado | Reinicie o VS Code ou use `/reload-plugins` |
| O `agy` volta vazio em modo leitura | O `agy` tentou usar o terminal, que é negado no modo `plan` | A ponte explica o motivo; passe os caminhos dos arquivos no pedido |
| Primeira execução lenta, com muitos `npm warn` | O `npx` está baixando o OmniRoute | Normal; espere 2 a 3 minutos |
| Teste com `claude -p` dentro do app Claude Desktop ignora o OmniRoute | O app injeta `ANTHROPIC_BASE_URL` | Teste num terminal normal |
