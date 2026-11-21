# Claude Code Kit

![Windows 11](https://img.shields.io/badge/Windows-11-0078D6) ![PowerShell 5.1](https://img.shields.io/badge/PowerShell-5.1-5391FE) ![Licença MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-green)

*[English version](README.en.md)*

Kit para usar o **Claude Code** no Windows sem ficar parado quando o limite acaba:

- **OmniRoute**: proxy local (`http://localhost:20128`) entre o Claude Code e vários provedores. Inclui:
  - **fallback automático**: Claude → OpenAI/Codex → Gemini;
  - **compressão de tokens** (Lite + RTK);
  - pasta de dados protegida, início automático com o Windows e **backup cifrado** (AES-256);
  - **MCP somente leitura**, para o Claude consultar cota e saúde do proxy.
- **Antigravity (`agy`)**: ajudante com **cota separada** (Google AI Pro). Um plugin do Claude Code delega a ele pesquisa, leitura extensa, segunda opinião e tarefas inteiras.
- **Continuidade**: se todos os modelos esgotarem, **Ctrl+Alt+Shift+A** no VS Code abre o Antigravity no projeto. Ele lê `CLAUDE.md`, `ANDAMENTO.md` e `git status` e continua de onde parou.

Nada pessoal fica neste repositório. Suas contas, chaves e dados ficam na sua máquina, numa pasta que você escolhe, e o backup sai cifrado com uma senha só sua.

## Índice
- [Instalação](#instalação)
- [Como funciona no dia a dia](#como-funciona-no-dia-a-dia)
- [Configuração](#configuração)
- [Segurança](#segurança)
- [Estrutura](#estrutura)
- [Roadmap](#roadmap)
- [Licença](#licença)

## Instalação

**Requisitos:**
- Windows 11 com `winget`;
- assinatura Claude (Pro/Max);
- opcionais: OpenAI/Codex/Gemini API e conta Google com **Google AI Pro**.

1. Baixe o kit:
   ```powershell
   git clone https://gitlab.com/jeffersondossant/claude-code-kit.git "$env:USERPROFILE\claude-code-kit"
   ```
   Sem Git, use **Code → Download ZIP** na página do projeto.
2. Num PowerShell **como Administrador**, na pasta do kit:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\instalar.ps1
   ```
   O script pergunta a pasta base, instala tudo e, no fim, **lista as configurações internas** que faltam (painel do OmniRoute, chave no `settings.json`, compressão e MCP). Use `-Simular` para ver o que ele faria sem mudar nada.
3. Siga a lista do final, com o [**tutorial completo**](docs/TUTORIAL-INSTALACAO.md).

**Só o plugin do Antigravity**, sem o resto do kit: no chat do Claude Code, rode `/plugin marketplace add https://gitlab.com/jeffersondossant/claude-code-kit.git` e depois `/plugin install agy@claude-code-kit`.

## Como funciona no dia a dia

| Situação | O que acontece |
|---|---|
| Uso normal | Claude Code → OmniRoute → Claude |
| Limite do Claude acabou | O OmniRoute passa sozinho para os próximos modelos do combo `claude-pro-fallback` |
| Pesquisa longa, leitura de muitos arquivos, segunda opinião | O Claude delega ao `agy` (cota do Google), avisa e confere o resultado |
| Todos os modelos esgotados | **Ctrl+Alt+Shift+A** abre o Antigravity no projeto, que continua pelo `ANDAMENTO.md` |

Comandos no chat:
- `/agy:perguntar`: pergunta direta;
- `/agy:pesquisar`: pesquisa na web com fontes;
- `/agy:revisar`: segunda opinião sobre as mudanças;
- `/agy:delegar`: entrega a tarefa inteira; altera arquivos, sem commit;
- `/agy:status`: confere instalação, login e resposta.

Todos aceitam `--modelo flash|sonnet|opus|gpt`.

## Configuração

Copie `config.exemplo.psd1` para **`config.local.psd1`**, que fica fora do Git. O `instalar.ps1` faz isso na primeira vez.

| Chave | Padrão | O que é |
|---|---|---|
| `PastaBase` | `%USERPROFILE%\claude-code` | onde ficam os dados do OmniRoute e os backups. Prefira um disco que sobreviva a uma formatação |
| `VersaoOmniRoute` | `3.8.54` | versão fixa do OmniRoute |
| `EnviarBackupAoGit` | `$false` | `$true` só se o **seu** repositório for privado |

Modelos prontos:
- [`omniroute/claude-settings.exemplo.json`](omniroute/claude-settings.exemplo.json): `settings.json` do Claude Code;
- [`omniroute/exemplos/combo-claude-pro-fallback.json`](omniroute/exemplos/combo-claude-pro-fallback.json): combo de fallback.

## Segurança
- **Pasta de dados** com acesso restrito ao seu usuário, SYSTEM e Administradores.
- **Backup cifrado:**
  - AES-256-CBC com HMAC-SHA256 e chave derivada da senha por PBKDF2 (600 mil iterações);
  - senha errada ou arquivo alterado são recusados;
  - o `backup.ps1` **se recusa a enviar** para um repositório público.
- **MCP:** a trava de escopo bloqueia as ferramentas de escrita.
- **Chave `mcp-leitura`:** sem acesso a modelos e aceita só de `127.0.0.1`.
- **`.gitignore`:** bloqueia `.env`, `*.sqlite`, `*.enc`, `settings.json`, `config.local.*` e `ANDAMENTO.md`.
- **O login do Antigravity nunca é usado como API pelo OmniRoute**, o que pode violar os termos do Google: o `agy` é sempre chamado como ele mesmo.

## Estrutura
```
instalar.ps1                     instala e configura tudo (winget, Claude Code, OmniRoute, Antigravity, MCP)
salvar-para-pc-novo.ps1          no PC antigo: copia o histórico do Claude Code e faz o backup
config.exemplo.psd1              modelo do config.local.psd1
lib/config.ps1                   carrega a configuração (usado por todos os scripts)
omniroute/
  scripts/                       instalar, backup, restaurar, proteger-pasta (+ lib: cifragem, cópia do banco)
  claude-settings.exemplo.json   modelo do settings.json do Claude Code
  exemplos/                      combo de fallback de exemplo
antigravity/
  plugin/                        plugin "agy": agente, comandos /agy:*, ponte agy.ps1, status.ps1
  scripts/                       instalar (plugin, regras, VS Code), verificar, continuar
  regras/                        regras do CLAUDE.md e do GEMINI.md globais
docs/TUTORIAL-INSTALACAO.md      tutorial completo
```

## Roadmap
- Testar a instalação completa em outras versões do Windows.
- Opção de revisão automática pelo `agy` ao final das tarefas.

## Licença
[MIT](LICENSE).

OmniRoute, Claude Code e Antigravity são produtos de seus respectivos donos. Este kit apenas os instala e integra.
