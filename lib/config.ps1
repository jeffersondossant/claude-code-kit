# Configuração do kit, compartilhada por todos os scripts.
# Carregar com:  . (Join-Path <raiz-do-kit> 'lib\config.ps1')   -> cria $Kit
#
# Ordem: padrões abaixo  ->  config.local.psd1 na raiz do kit (seu, fora do Git).
# Modelo do arquivo local: config.exemplo.psd1. Caminhos aceitam %VARIAVEIS% do Windows.

$__raizKit = Split-Path -Parent $PSScriptRoot

$__cfg = @{
  # Pasta base do ambiente: onde ficam os dados do OmniRoute, os backups e (se quiser) seus projetos
  PastaBase         = '%USERPROFILE%\claude-code'
  # Derivadas da PastaBase quando ficarem vazias
  PastaDadosOmni    = ''     # DATA_DIR do OmniRoute (banco + .env com a chave de criptografia)
  PastaBackups      = ''     # backups cifrados e cópia do histórico do Claude Code
  # OmniRoute
  VersaoOmniRoute   = '3.8.54'
  PortaOmniRoute    = 20128
  NomeTarefa        = 'OmniRoute'
  # Enviar o backup cifrado ao Git? Só faz sentido se o SEU repositório for privado.
  EnviarBackupAoGit = $false
  # Git (perguntados na instalação quando vazios)
  NomeGit           = ''
  EmailGit          = ''
}

$__local = Join-Path $__raizKit 'config.local.psd1'
if (Test-Path -LiteralPath $__local) {
  $__dados = Import-PowerShellDataFile -LiteralPath $__local
  foreach ($__k in $__dados.Keys) {
    if (-not $__cfg.ContainsKey($__k)) { Write-Warning "config.local.psd1: chave desconhecida '$__k' (ignorada)"; continue }
    $__cfg[$__k] = $__dados[$__k]
  }
}

foreach ($__k in @($__cfg.Keys)) {
  if ($__cfg[$__k] -is [string]) { $__cfg[$__k] = [Environment]::ExpandEnvironmentVariables($__cfg[$__k]).TrimEnd('\') }
}
if (-not $__cfg.PastaDadosOmni) { $__cfg.PastaDadosOmni = Join-Path $__cfg.PastaBase 'omniroute' }
if (-not $__cfg.PastaBackups)   { $__cfg.PastaBackups   = Join-Path $__cfg.PastaBase 'backups' }

$__cfg.RaizKit         = $__raizKit
$__cfg.ArquivoLocal    = $__local
$__cfg.TemConfigLocal  = Test-Path -LiteralPath $__local
# Com envio ao Git, o backup fica dentro do repositório (backups/); senão, na PastaBackups
$__cfg.ArquivoBackup   = if ($__cfg.EnviarBackupAoGit) { Join-Path $__raizKit 'backups\omniroute-backup.enc' } else { Join-Path $__cfg.PastaBackups 'omniroute-backup.enc' }
$__cfg.PastaHistorico  = Join-Path $__cfg.PastaBackups 'claude-historico'

$Kit = [pscustomobject]$__cfg
Remove-Variable __raizKit, __cfg, __local, __dados, __k -ErrorAction SilentlyContinue
