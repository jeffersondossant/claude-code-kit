<#
  Gera o backup cifrado (AES-256 + senha) das chaves e do banco do OmniRoute.
  Grava em <PastaBackups>\omniroute-backup.enc (veja config.local.psd1).
  Com EnviarBackupAoGit = $true, grava em backups\ do repositório e faz commit + push,
  mas SÓ se o repositório remoto for privado (recusa enviar para um repositório público).

  O que entra no backup:
    - <DATA_DIR>\.env e server.env  (chave de criptografia, JWT, API_KEY_SECRET)
    - <DATA_DIR>\storage.sqlite     (provedores, combos, chaves de API; cópia consistente)
    - <DATA_DIR>\backups\           (backups de configuração feitos pelo próprio OmniRoute)
    - %USERPROFILE%\.claude\settings.json (URL e token que o Claude Code usa no OmniRoute)

  Uso:
    powershell -ExecutionPolicy Bypass -File .\omniroute\scripts\backup.ps1
    ... -SemEnviar      # mesmo com EnviarBackupAoGit, só gera o arquivo

  A senha NÃO fica salva em lugar nenhum. Sem ela o backup não abre.
#>
param(
  [string]$DataDir,
  [switch]$SemEnviar
)
. "$PSScriptRoot\lib\comum.ps1"
. "$PSScriptRoot\lib\cripto.ps1"
Add-Type -AssemblyName System.IO.Compression
if (-not $DataDir) { $DataDir = if ($env:DATA_DIR) { $env:DATA_DIR } else { $Script:DataDirPadrao } }

$banco = Join-Path $DataDir 'storage.sqlite'
if (-not (Test-Path -LiteralPath $banco)) { throw "Banco não encontrado: $banco" }
$null = Get-Npx

Write-Etapa "Lendo dados de $DataDir"
$tmp = Join-Path $DataDir '.backup-tmp'   # dentro da pasta protegida, nunca no C:\Temp
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  $copia = Join-Path $tmp 'storage.sqlite'
  & node "$PSScriptRoot\lib\snapshot-sqlite.mjs" $banco $copia
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao copiar o banco.' }
  Write-Ok 'Cópia consistente do banco'

  $itens = [ordered]@{ 'dados/storage.sqlite' = $copia }
  foreach ($f in '.env', 'server.env') {
    $p = Join-Path $DataDir $f
    if (Test-Path -LiteralPath $p) { $itens["dados/$f"] = $p }
  }
  $pBackups = Join-Path $DataDir 'backups'
  if (Test-Path -LiteralPath $pBackups) {
    Get-ChildItem -LiteralPath $pBackups -Recurse -File | ForEach-Object {
      $rel = $_.FullName.Substring($DataDir.TrimEnd('\').Length + 1) -replace '\\', '/'
      $itens["dados/$rel"] = $_.FullName
    }
  }
  $claude = Join-Path $env:USERPROFILE '.claude\settings.json'
  if (Test-Path -LiteralPath $claude) { $itens['claude/settings.json'] = $claude }
  else { Write-Aviso 'settings.json do Claude Code não encontrado; seguindo sem ele.' }

  if (-not $itens.Contains('dados/.env')) { Write-Aviso '.env não encontrado: sem ele o banco não pode ser decifrado na restauração!' }

  # Monta o ZIP em memória (nada em texto puro fica gravado fora da pasta protegida)
  $ms = New-Object IO.MemoryStream
  $zip = New-Object IO.Compression.ZipArchive($ms, [IO.Compression.ZipArchiveMode]::Create, $true)
  foreach ($nome in $itens.Keys) {
    $e = $zip.CreateEntry($nome, [IO.Compression.CompressionLevel]::Optimal)
    $s = $e.Open(); try { $b = [IO.File]::ReadAllBytes($itens[$nome]); $s.Write($b, 0, $b.Length) } finally { $s.Dispose() }
    Write-Ok $nome
  }
  $manifesto = @{
    criadoEm = (Get-Date).ToString('s'); computador = $env:COMPUTERNAME
    versaoOmniRoute = $Script:VersaoOmniRoute; dataDirOriginal = $DataDir; itens = @($itens.Keys)
  } | ConvertTo-Json
  $e = $zip.CreateEntry('manifesto.json')
  $s = $e.Open(); try { $b = [Text.Encoding]::UTF8.GetBytes($manifesto); $s.Write($b, 0, $b.Length) } finally { $s.Dispose() }
  $zip.Dispose()
  $bytesZip = $ms.ToArray(); $ms.Dispose()
} finally {
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Etapa 'Cifrando'
Write-Host '  Escolha uma senha forte e guarde-a FORA deste PC (gerenciador de senhas ou papel).'
$senha = Read-SenhaBackup -Confirmar
$cifrado = Protect-BytesComSenha $bytesZip $senha
[Array]::Clear($bytesZip, 0, $bytesZip.Length)

# Confere que abre com a mesma senha antes de substituir o backup anterior
$teste = Unprotect-BytesComSenha $cifrado $senha
if ($teste.Length -le 0) { throw 'Falha na verificação do backup.' }
[Array]::Clear($teste, 0, $teste.Length)

New-Item -ItemType Directory -Path (Split-Path $Script:ArquivoBackup) -Force | Out-Null
[IO.File]::WriteAllBytes($Script:ArquivoBackup, $cifrado)
Write-Ok ("Backup gravado e conferido: {0} ({1:N0} KB)" -f $Script:ArquivoBackup, ($cifrado.Length / 1KB))

if ($SemEnviar -or -not $Kit.EnviarBackupAoGit) {
  if (-not $Kit.EnviarBackupAoGit) { Write-Host '  Guarde também uma cópia FORA deste PC (nuvem, pendrive). Ela só abre com a senha.' -ForegroundColor DarkGray }
  exit 0
}

Write-Etapa 'Enviando ao Git (EnviarBackupAoGit = $true)'
$ErrorActionPreference = 'Continue'   # avisos do git no stderr não são erros
$git = 'git'
# Trava: nunca enviar para um repositório público. Se o remoto responde SEM credenciais, ele é público.
$remoto = & $git -C $Script:RaizRepo remote get-url origin 2>$null
if (-not $remoto) { throw 'O repositório não tem remoto "origin". Desligue EnviarBackupAoGit ou configure o remoto.' }
$envAntes = $env:GIT_TERMINAL_PROMPT; $env:GIT_TERMINAL_PROMPT = '0'
& $git -c credential.helper= ls-remote --heads $remoto 2>$null | Out-Null
$publico = ($LASTEXITCODE -eq 0)
$env:GIT_TERMINAL_PROMPT = $envAntes
if ($publico) { throw "O repositório $remoto é PÚBLICO (acessível sem login). Envio do backup cancelado; ele continua em $Script:ArquivoBackup." }
& $git -C $Script:RaizRepo add -f -- 'backups/omniroute-backup.enc'
$staged = & $git -C $Script:RaizRepo diff --cached --name-only
$proibidos = $staged | Where-Object { $_ -ne 'backups/omniroute-backup.enc' -and $_ -match '\.env|\.sqlite|settings\.json' }
if ($proibidos) { throw "Arquivo sensível no commit, envio cancelado: $proibidos" }
if (-not $staged) { Write-Ok 'Backup idêntico ao último enviado; nada a fazer.'; exit 0 }
& $git -C $Script:RaizRepo commit -q -m "Backup cifrado do OmniRoute ($((Get-Date).ToString('yyyy-MM-dd HH:mm')))" -- 'backups/omniroute-backup.enc'
& $git -C $Script:RaizRepo push -q
if ($LASTEXITCODE -ne 0) { throw 'O push falhou. O commit ficou local; rode "git push" na pasta do projeto.' }
Write-Ok 'Enviado.'
