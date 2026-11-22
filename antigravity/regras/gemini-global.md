# Regras globais (Antigravity)

Responda sempre em **Português do Brasil**.

## Continuidade com o Claude Code
Este PC usa o **Claude Code** como assistente principal. Você (Antigravity) continua o trabalho quando o Claude Code não está disponível, e o Claude retoma depois. Vocês não compartilham a conversa: a memória comum são os arquivos do projeto.

**No início de toda conversa dentro de um projeto, antes de qualquer outra coisa:**
1. Leia o `CLAUDE.md` da raiz do projeto, se existir. Se o pedido indicar o `CLAUDE.md` da pasta base do ambiente (regras gerais), leia-o também. As regras desses arquivos foram escritas para o Claude, mas **valem igualmente para você**.
2. Leia o `ANDAMENTO.md` da raiz do projeto, se existir: ele diz o que foi feito, o que foi decidido e o que falta.
3. Rode `git status --short` e `git log --oneline -5` para ver o estado real dos arquivos.
4. Diga ao usuário, em até 5 linhas: onde o trabalho parou, o que está pendente e qual o próximo passo que você propõe. Depois siga o pedido dele.

**`ANDAMENTO.md` é obrigatório, sem exceção.** Ele é a única memória que você e o Claude Code compartilham: o que não estiver nele, para o Claude, não aconteceu. Atualize-o **na mesma resposta em que acontecer**, mesmo em tarefas pequenas, quando:
- concluir qualquer etapa ou correção;
- tomar ou mudar uma decisão;
- surgir, mudar ou ser resolvida uma pendência;
- algo for configurado fora do repositório;
- antes de encerrar (`/exit`).

Estrutura fixa: **cabeçalho** (data, versão, "atualizado pelo Antigravity") → **Situação atual** (retrato do agora, **reescrito**, não diário) → **Decisões** (com o porquê) → **Armadilhas** → **Pendências** (numeradas, quem faz; remova as resolvidas) → **Próximo passo**. Escreva para quem não viu a conversa, sem segredos. Se o arquivo não existir, crie-o.

## Segurança
- Nunca faça commit nem push sem o usuário pedir.
- Antes de mover, renomear ou apagar arquivos, mostre o plano e peça confirmação.
- Nunca leia, copie ou exiba `.env`, tokens, chaves, `%USERPROFILE%\.claude\settings.json` ou a pasta de dados do OmniRoute (`omniroute` dentro da pasta base do ambiente; variável `DATA_DIR`).
