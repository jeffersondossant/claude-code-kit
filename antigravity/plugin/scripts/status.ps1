<#
  Saúde do Antigravity CLI (agy) para o plugin: instalado, logado, apelidos de modelo
  válidos e uma resposta real pela ponte agy.ps1. Fica dentro do plugin para funcionar
  mesmo quando o plugin é instalado sozinho (de um repositório remoto).
  Usado por /agy:status e pelo antigravity\scripts\verificar.ps1.

  -SemTesteReal   não gasta cota (pula a pergunta de teste)
  Código de saída = número de problemas encontrados.
#>
param([switch]$SemTesteReal)
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding $false
$falhas = 0
function Write-Ok([string]$t)    { Write-Host "  OK    $t" -ForegroundColor Green }
function Write-Falha([string]$t, [string]$como) { Write-Host "  FALHA $t" -ForegroundColor Red; if ($como) { Write-Host "        -> $como" -ForegroundColor Yellow }; $script:falhas++ }

$ponte = Join-Path $PSScriptRoot 'agy.ps1'

Write-Host "`nAntigravity CLI" -ForegroundColor Cyan
$agy = (Get-Command agy -ErrorAction SilentlyContinue).Source
if (-not $agy) { $agy = Join-Path $env:LOCALAPPDATA 'agy\bin\agy.exe' }
if (Test-Path -LiteralPath $agy) {
  Write-Ok "instalado: $agy (versão $((& $agy --version 2>$null | Select-Object -First 1)))"
} else {
  Write-Falha 'agy não encontrado' 'Instale: winget install --id Google.AntigravityCLI -e  (ou https://antigravity.google)'
  exit 1
}

$j = Start-Job { param($a) & $a models 2>$null | Out-String } -ArgumentList $agy
$modelos = if (Wait-Job $j -Timeout 60) { Receive-Job $j } else { Stop-Job $j; '' }
Remove-Job $j -Force
$ids = @($modelos -split "`r?`n" | Where-Object { $_ -match '\S' } | ForEach-Object { ($_ -split "`t")[0].Trim() })
if ($ids.Count -gt 0) { Write-Ok "logado: $($ids.Count) modelos disponíveis" }
else { Write-Falha 'não consegui listar os modelos (sem login ou sem rede)' 'Rode "agy" num terminal e faça o login com a conta do Google AI Pro.' }

if ($ids.Count -gt 0) {
  $apelidos = [regex]::Matches((Get-Content -LiteralPath $ponte -Raw), "'([a-z-]+)'\s*=\s*'([^']+)'")
  foreach ($m in $apelidos) {
    $ap = $m.Groups[1].Value; $id = $m.Groups[2].Value
    if ($ids -contains $id) { Write-Ok "apelido $ap -> $id" }
    else { Write-Falha "apelido $ap -> $id não existe mais" "Atualize o mapa em plugin\scripts\agy.ps1. Disponíveis: $($ids -join ', ')" }
  }
}

if (-not $SemTesteReal -and $ids.Count -gt 0) {
  $r = 'Responda apenas a palavra PRONTO.' | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ponte -Modelo hydrogen-rapido -Minutos 2 2>&1 | Out-String
  if ($r -match 'PRONTO') { Write-Ok 'resposta real do agy pela ponte do plugin' }
  else { Write-Falha "o agy não respondeu como esperado: $($r.Trim())" 'Veja a mensagem acima; tente "agy" no terminal.' }
}
exit $falhas
