<#
  Restaura as chaves e o banco do OmniRoute a partir do backup cifrado.
  Use quando a pasta de dados foi perdida (disco com falha, PC novo etc.).

  Uso:
    powershell -ExecutionPolicy Bypass -File .\omniroute\scripts\restaurar.ps1
    & ...\restaurar.ps1 -DataDir "E:\omniroute"      # restaurar em outra pasta
    & ...\restaurar.ps1 -Substituir                  # já existe banco lá: guarda o atual e substitui

  Depois rode scripts\instalar.ps1 para criar o início automático.
#>
param(
  [string]$Arquivo,
  [string]$DataDir,
  [switch]$Substituir
)
. "$PSScriptRoot\lib\comum.ps1"
. "$PSScriptRoot\lib\cripto.ps1"
Add-Type -AssemblyName System.IO.Compression
if (-not $Arquivo) { $Arquivo = $Script:ArquivoBackup }
if (-not $DataDir) { $DataDir = $Script:DataDirPadrao }
if (-not (Test-Path -LiteralPath $Arquivo)) { throw "Backup não encontrado: $Arquivo (copie o omniroute-backup.enc para lá, ou informe -Arquivo <caminho>)." }

if (Test-OmniRouteNoAr) { throw "O OmniRoute está rodando (porta $($Script:PortaOmniRoute)). Feche-o antes de restaurar." }

$existente = Join-Path $DataDir 'storage.sqlite'
if (Test-Path -LiteralPath $existente) {
  if (-not $Substituir) { throw "Já existe um banco em $DataDir. Para trocar por este backup, rode de novo com -Substituir." }
  $guarda = "$DataDir.antes-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
  Write-Aviso "Guardando a pasta atual em $guarda"
  Rename-Item -LiteralPath $DataDir -NewName (Split-Path $guarda -Leaf)
}

Write-Etapa 'Decifrando'
$senha = Read-SenhaBackup
$zipBytes = Unprotect-BytesComSenha ([IO.File]::ReadAllBytes($Arquivo)) $senha
Write-Ok 'Senha correta, arquivo íntegro'

Write-Etapa "Gravando em $DataDir"
Set-PastaProtegida $DataDir   # protege ANTES de gravar os segredos
$ms = New-Object IO.MemoryStream (,$zipBytes)
$zip = New-Object IO.Compression.ZipArchive($ms, [IO.Compression.ZipArchiveMode]::Read)
$settingsClaude = $null
try {
  foreach ($e in $zip.Entries) {
    if ($e.FullName -eq 'manifesto.json') {
      $r = New-Object IO.StreamReader($e.Open()); $man = $r.ReadToEnd() | ConvertFrom-Json; $r.Dispose()
      Write-Ok "Backup de $($man.criadoEm) ($($man.computador), OmniRoute $($man.versaoOmniRoute))"
      continue
    }
    if ($e.FullName -like 'dados/*') {
      $rel = $e.FullName.Substring(6) -replace '/', '\'
      if ($rel -match '(^|\\)\.\.(\\|$)') { throw "Caminho inválido no backup: $($e.FullName)" }
      $destino = Join-Path $DataDir $rel
    } elseif ($e.FullName -eq 'claude/settings.json') {
      $settingsClaude = $e; continue
    } else { continue }
    New-Item -ItemType Directory -Path (Split-Path $destino) -Force | Out-Null
    $s = $e.Open(); $f = [IO.File]::Create($destino)
    try { $s.CopyTo($f) } finally { $f.Dispose(); $s.Dispose() }
    Write-Ok $rel
  }

  if ($settingsClaude) {
    Write-Etapa 'Configuração do Claude Code'
    $pasta = Join-Path $env:USERPROFILE '.claude'
    New-Item -ItemType Directory -Path $pasta -Force | Out-Null
    $alvo = Join-Path $pasta 'settings.json'
    if (Test-Path -LiteralPath $alvo) {
      $alvo = Join-Path $pasta 'settings.restaurado.json'
      Write-Aviso "Já existe um settings.json; o do backup foi salvo como $alvo para você comparar."
    }
    $s = $settingsClaude.Open(); $f = [IO.File]::Create($alvo)
    try { $s.CopyTo($f) } finally { $f.Dispose(); $s.Dispose() }
    Write-Ok $alvo
  }
} finally {
  $zip.Dispose(); $ms.Dispose(); [Array]::Clear($zipBytes, 0, $zipBytes.Length)
}
& icacls (Join-Path $DataDir '*') /reset /T /C /Q | Out-Null

Write-Host "`nRestaurado. Próximo passo:" -ForegroundColor Green
Write-Host "  & `"$PSScriptRoot\instalar.ps1`" -DataDir `"$DataDir`""
