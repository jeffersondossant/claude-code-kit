<#
  Rode NO PC ANTIGO, antes de migrar para um PC novo (levando o disco da pasta base,
  ou copiando a pasta base para lá).
  Copia para a pasta de backups do kit o que fica no C: e não está em nenhum backup:
    - histórico de conversas do Claude Code (%USERPROFILE%\.claude\projects)
  E atualiza o backup cifrado do OmniRoute (pede a senha), para levar o settings.json atual.

  Uso (na pasta do kit):
    powershell -ExecutionPolicy Bypass -File .\salvar-para-pc-novo.ps1
    ... -SemBackup    # só copia o histórico
#>
param([switch]$SemBackup)
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding $false
. (Join-Path $PSScriptRoot 'lib\config.ps1')
$destino = $Kit.PastaHistorico
$origem = Join-Path $env:USERPROFILE '.claude\projects'

Write-Host "`n> Histórico de conversas do Claude Code" -ForegroundColor Cyan
if (Test-Path -LiteralPath $origem) {
  robocopy $origem (Join-Path $destino 'projects') /E /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
  $n = (Get-ChildItem -LiteralPath (Join-Path $destino 'projects') -Recurse -File -Filter *.jsonl -ErrorAction SilentlyContinue).Count
  Write-Host "  OK  $n conversas copiadas para $destino\projects" -ForegroundColor Green
  Write-Host '      (contêm o que foi conversado e trechos de arquivos; mantenha essa pasta fora do Git)' -ForegroundColor DarkGray
} else { Write-Host "  --  nada em $origem" -ForegroundColor DarkGray }

if (-not $SemBackup) {
  Write-Host "`n> Backup cifrado do OmniRoute (pede a senha do backup)" -ForegroundColor Cyan
  & (Join-Path $PSScriptRoot 'omniroute\scripts\backup.ps1')
}
Write-Host "`nPronto. Leve a pasta base ($($Kit.PastaBase)) e o kit para o PC novo e rode instalar.ps1 como Administrador." -ForegroundColor Green
