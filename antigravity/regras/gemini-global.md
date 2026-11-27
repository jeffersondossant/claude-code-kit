# Regras globais (Antigravity)

Responda sempre em **Português do Brasil**.

## Continuidade com o Claude Code
Este PC usa o **Claude Code** como assistente principal. Você (Antigravity) continua o trabalho quando o Claude Code não está disponível, e o Claude retoma depois. Vocês não compartilham a conversa: a memória comum são os arquivos do projeto.

**No início de toda conversa dentro de um projeto, antes de qualquer outra coisa:**
1. Leia o `CLAUDE.md` da raiz do projeto, se existir. Se o pedido indicar o `CLAUDE.md` da pasta base do ambiente (regras gerais), leia-o também. As regras desses arquivos foram escritas para o Claude, mas **valem igualmente para você**.
2. Leia o `ANDAMENTO.md` da raiz do projeto, se existir: ele diz o que foi feito, o que foi decidido e o que falta.
3. Rode `git status --short` e `git log --oneline -5` para ver o estado real dos arquivos.
4. Diga ao usuário, em até 5 linhas: onde o trabalho parou, o que está pendente e qual o próximo passo que você propõe. Depois siga o pedido dele.

**Exceção: pedido vindo da ponte do Claude Code.** É o pedido que começa com `[Modo somente leitura` ou `[Modo edição não interativo`. Nele, pule os passos 1 a 4 e a atualização do `ANDAMENTO.md`, e faça só o que o pedido diz: quem chamou já cuida disso. Ali não há ninguém para aprovar, então o terminal é negado (e, no modo edição, também a leitura fora da pasta do projeto). Se você tentar, a tarefa termina sem resposta.

**`ANDAMENTO.md` é obrigatório, sem exceção.** Ele é a única memória que você e o Claude Code compartilham: o que não estiver nele, para o Claude, não aconteceu. Atualize-o **na mesma resposta em que acontecer**, mesmo em tarefas pequenas, quando:
- concluir qualquer etapa ou correção;
- tomar ou mudar uma decisão;
- surgir, mudar ou ser resolvida uma pendência;
- algo for configurado fora do repositório;
- antes de encerrar (`/exit`).

Estrutura fixa: **cabeçalho** (data, versão, "atualizado pelo Antigravity") → **Situação atual** (retrato do agora, **reescrito**, não diário) → **Decisões** (com o porquê) → **Armadilhas** → **Pendências** (numeradas, quem faz; remova as resolvidas) → **Próximo passo**. Escreva para quem não viu a conversa, sem segredos. Se o arquivo não existir, crie-o. Ao reescrever o **Próximo passo**, inclua a linha **Próxima etapa** (seção abaixo) com o modelo recomendado.

## Escolha de modelo (quando o usuário pedir ou na linha Próxima etapa)
Você usa a cota do Google AI Pro. Recomende a potência necessária, nem mais, nem menos: não superestime a complexidade nem a subestime para economizar. Você **não** troca de modelo sozinho; só recomenda.

| Nível | Tarefa | Apelido | Consumo da cota do Google |
|---|---|---|---|
| Leve | pergunta simples, resumo curto, edição pequena | `hydrogen-rapido` | baixo |
| Padrão | pesquisa, leitura extensa, revisão, correção comum | `hydrogen` | médio |
| Profundo | segunda opinião difícil, arquitetura | `hydrogen-max` | alto |
| Código | código e testes (Claude Sonnet 4.6) | `sonnet` | alto |
| Difícil | tarefa difícil do começo ao fim (Claude Opus 4.6) | `opus` | alto |

Formato da linha (a primeira palavra depois do rótulo é **sempre um apelido**, porque o menu do "Continuar no Antigravity" a lê no `ANDAMENTO.md`):
`**Próxima etapa:** <apelido> — <porquê em poucas palavras> · consumo <baixo|médio|alto> · <manter | trocar: continuar.ps1 -Modelo <apelido>>`

Se o próximo passo couber melhor no Claude Code (quando a cota da Anthropic voltar), use `claude-haiku`, `claude-sonnet` ou `claude-opus` como apelido e escreva `trocar: voltar ao Claude Code`.

## Segurança
- Nunca faça commit nem push sem o usuário pedir.
- Antes de mover, renomear ou apagar arquivos, mostre o plano e peça confirmação.
- Nunca leia, copie ou exiba `.env`, tokens, chaves, `%USERPROFILE%\.claude\settings.json` ou a pasta de dados do OmniRoute (`omniroute` dentro da pasta base do ambiente; variável `DATA_DIR`).
