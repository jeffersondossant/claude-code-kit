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

## Continuidade: `ANDAMENTO.md`

Quando os modelos do OmniRoute se esgotam, o usuário continua o trabalho no Antigravity pelo VS Code: *Ctrl+Shift+P → Tasks: Run Task → Continuar no Antigravity*, ou `Ctrl+Alt+Shift+A`. O Antigravity não vê esta conversa; ele lê o `CLAUDE.md`, o `ANDAMENTO.md` e o `git status`. Por isso:
- **No início de uma conversa num projeto**, se existir `ANDAMENTO.md` na raiz, leia-o antes de agir: o trabalho pode ter avançado no Antigravity. Confira também o `git status`.
- **Em tarefas com mais de uma etapa**, mantenha o `ANDAMENTO.md` na raiz do projeto, atualizando-o ao concluir cada etapa, sem esperar o fim. Seções: data da última atualização, situação atual, decisões tomadas (com o motivo), pendências e próximo passo. Escreva para quem não viu a conversa, com caminhos e comandos concretos.
- Tarefas de um passo só não precisam de `ANDAMENTO.md`.
- O `ANDAMENTO.md` não leva segredos.
