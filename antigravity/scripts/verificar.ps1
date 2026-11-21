<#
  Verifica a integração Claude Code + Antigravity (agy):
  agy instalado e logado, modelos dos apelidos disponíveis, resposta real,
  plugin instalado no Claude Code e regras no CLAUDE.md global.

  Uso:
    powershell -ExecutionPolicy Bypass -File .\antigravity\scripts\verificar.ps1
    ... -SemTesteReal     # não gasta cota (pula a pergunta de teste)
#>
param([switch]$SemTesteReal)
$ErrorActionPreference = 'Continue'
$utf8 = New-Object Text.UTF8Encoding $false
[Console]::OutputEncoding = $utf8
$falhas = 0
function Write-Ok([string]$t)    { Write-Host "  OK    $t" -ForegroundColor Green }
function Write-Falha([string]$t, [string]$como) { Write-Host "  FALHA $t" -ForegroundColor Red; if ($como) { Write-Host "        -> $como" -ForegroundColor Yellow }; $script:falhas++ }
function Write-Aviso([string]$t) { Write-Host "  AVISO $t" -ForegroundColor Yellow }

# Parte do agy: fica no plugin (plugin\scripts\status.ps1), também usada por /agy:status
$status = Join-Path $PSScriptRoot '..\plugin\scripts\status.ps1'
$argsStatus = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $status)
if ($SemTesteReal) { $argsStatus += '-SemTesteReal' }
& powershell.exe @argsStatus
$falhas += [int]$LASTEXITCODE

Write-Host "`nClaude Code" -ForegroundColor Cyan
if (Get-Command claude -ErrorAction SilentlyContinue) {
  $lista = claude plugin list 2>&1 | Out-String
  if ($lista -match 'agy@claude-code-kit') { Write-Ok 'plugin agy@claude-code-kit instalado' }
  else { Write-Falha 'plugin agy não instalado' 'Rode antigravity\scripts\instalar.ps1' }
} else { Write-Aviso 'CLI "claude" não encontrada no PATH; não deu para conferir o plugin.' }

$global = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
if ((Test-Path -LiteralPath $global) -and (Select-String -LiteralPath $global -Pattern 'claude-code-kit:agy:inicio' -SimpleMatch -Quiet)) {
  Write-Ok 'regras de delegação presentes no CLAUDE.md global'
} else { Write-Aviso 'regras de delegação ausentes no CLAUDE.md global (a delegação automática não acontece; os comandos /agy:* funcionam)' }

Write-Host "`nContinuidade" -ForegroundColor Cyan
$gemini = Join-Path $env:USERPROFILE '.gemini\GEMINI.md'
if ((Test-Path -LiteralPath $gemini) -and (Select-String -LiteralPath $gemini -Pattern 'claude-code-kit:continuidade:inicio' -SimpleMatch -Quiet)) {
  Write-Ok 'GEMINI.md global: o agy lê CLAUDE.md, ANDAMENTO.md e git status ao começar'
} else { Write-Aviso 'GEMINI.md global sem as regras de continuidade (rode antigravity\scripts\instalar.ps1)' }
$tasks = Join-Path $env:APPDATA 'Code\User\tasks.json'
if ((Test-Path -LiteralPath $tasks) -and (Select-String -LiteralPath $tasks -Pattern 'Continuar no Antigravity' -SimpleMatch -Quiet)) {
  Write-Ok 'VS Code: tarefa "Continuar no Antigravity" (Ctrl+Alt+Shift+A)'
} else { Write-Aviso 'VS Code sem a tarefa "Continuar no Antigravity" (rode antigravity\scripts\instalar.ps1)' }

Write-Host ''
if ($falhas) { Write-Host "$falhas problema(s) encontrado(s)." -ForegroundColor Red; exit 1 }
Write-Host 'Tudo certo.' -ForegroundColor Green
