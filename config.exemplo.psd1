# Copie este arquivo para "config.local.psd1" (na mesma pasta) e ajuste.
# O config.local.psd1 fica fora do Git. Chaves omitidas usam o padrão.
# Caminhos aceitam variáveis do Windows, como %USERPROFILE%.
@{
  # Pasta base do ambiente. Dentro dela ficam:
  #   omniroute\   dados do OmniRoute (banco + .env com a chave de criptografia) = DATA_DIR
  #   backups\     backups cifrados e cópia do histórico do Claude Code
  # Prefira um disco que sobreviva a uma formatação do Windows (ex.: 'D:\claude-code').
  PastaBase = '%USERPROFILE%\claude-code'

  # (opcional) Sobrescrever as pastas derivadas
  # PastaDadosOmni = 'D:\claude-code\omniroute'
  # PastaBackups   = 'E:\backups\claude-code'

  # Versão fixa do OmniRoute (evita que o npx troque de versão sozinho)
  VersaoOmniRoute = '3.8.54'

  # Enviar o backup cifrado ao Git (commit + push)? Use $true SÓ se o seu repositório for PRIVADO.
  # O backup.ps1 se recusa a enviar para um repositório público.
  EnviarBackupAoGit = $false

  # Git (se vazios, a instalação pergunta)
  NomeGit  = ''
  EmailGit = ''
}
