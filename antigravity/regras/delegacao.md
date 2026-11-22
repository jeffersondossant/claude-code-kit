## Antigravity (agy): ajudante com cota separada

O Antigravity CLI (`agy`) usa a cota do Google AI Pro, separada da Anthropic. Ele é chamado pelo subagente `agy` (plugin `agy@claude-code-kit`) ou pelos comandos `/agy:perguntar`, `/agy:pesquisar`, `/agy:revisar`, `/agy:delegar` e `/agy:status`.

Delegue ao subagente `agy` **sem esperar o usuário pedir** quando:
- **Pesquisa longa na web**: comparar opções, documentação atual, versões, preços. Peça as fontes.
- **Leitura extensa**: entender ou resumir muitos arquivos ou um projeto grande antes de agir.
- **Segunda opinião**: decisões de arquitetura, segurança ou mudanças grandes antes de aplicar.
- **Cota apertada**: se uma ferramenta ou subagente seu falhar por limite ou cota (429, "usage limit", "rate limit"), avise o usuário e passe a tarefa ao `agy` com o modelo `sonnet` ou `opus`, em modo edição só se o usuário autorizar. (Se o próprio chat ficar sem resposta, quem continua é o usuário, pela tarefa "Continuar no Antigravity" do VS Code; veja abaixo.)

Regras:
- Diga ao usuário quando delegar e qual modelo usou. Confira o resultado antes de apresentá-lo como certo.
- Tarefas simples e rápidas continuam com você: delegar tem custo de tempo.
- O `agy` não altera arquivos, a não ser que o usuário peça para delegar a tarefa inteira (`/agy:delegar` ou pedido explícito).
- Nunca envie ao `agy` senhas, tokens, chaves, `.env`, `settings.json` ou a pasta de dados do OmniRoute.
- Revisão pelo `agy` ao final das tarefas: **só quando o usuário pedir** (`/agy:revisar` ou "pede pro agy revisar").

## `ANDAMENTO.md`: memória do projeto (OBRIGATÓRIO, sem exceção)

O usuário troca de ferramenta a qualquer momento: este chat, o Claude Code no VS Code, o Antigravity (`Ctrl+Alt+Shift+A`), outro PC. Nenhuma delas vê as conversas das outras. A **única memória compartilhada** é o `ANDAMENTO.md` na raiz de cada projeto. Se algo não está lá, para a próxima conversa **não aconteceu**.

**Ao começar** qualquer conversa num projeto: leia o `ANDAMENTO.md` (e rode `git status` e `git log --oneline -5`) **antes de agir**. O trabalho pode ter avançado em outra ferramenta. Se não existir, crie-o na primeira mudança.

**Atualize SEMPRE, na mesma resposta em que acontecer**, sem esperar o fim da conversa e mesmo em tarefas pequenas, quando:
- concluir qualquer etapa, tarefa ou correção;
- tomar ou mudar uma decisão;
- surgir, mudar ou ser resolvida uma pendência (inclusive "o usuário precisa fazer X");
- algo for instalado, configurado ou alterado fora do repositório (painel, variáveis, tarefas agendadas, contas);
- **antes de cada commit**: o `ANDAMENTO.md` atualizado vai no mesmo commit;
- antes de encerrar a conversa ou quando a cota estiver acabando.

**Estrutura fixa**:
1. **Cabeçalho**: data da última atualização, versão e quem atualizou (Claude Code ou Antigravity).
2. **Situação atual**: um **retrato do agora**, **reescrito** a cada atualização. Não é diário: nada de empilhar "fiz X, depois Y"; o histórico vai para o `CHANGELOG.md` e para o Git.
3. **Decisões tomadas**, cada uma com o **porquê**.
4. **Armadilhas já resolvidas**: o que deu errado e como evitar.
5. **Pendências**: numeradas, com data quando houver, dizendo quem faz (usuário ou Claude). Remova as resolvidas.
6. **Próximo passo**: o que a próxima conversa deve fazer primeiro.

Escreva para quem **não viu a conversa**: caminhos, comandos e nomes concretos. **Nunca** inclua segredos (senhas, tokens, chaves, conteúdo de `.env`).
