<#
  Continua o trabalho do projeto atual no Antigravity (agy), no próprio terminal.
  Use quando o Claude Code parar de responder (cotas do OmniRoute esgotadas).

  No VS Code: Ctrl+Shift+P -> "Tasks: Run Task" -> "Continuar no Antigravity"
              (ou o atalho Ctrl+Alt+Shift+A)
  No terminal: powershell -ExecutionPolicy Bypass -File <kit>\antigravity\scripts\continuar.ps1

  -Modelo  opus (padrão) | sugerido | hydrogen | hydrogen-rapido | hydrogen-max | sonnet | gpt | <id exato do "agy models">
           "sugerido" usa o apelido da última linha "**Próxima etapa:** <apelido>" do ANDAMENTO.md
           (é o padrão do menu da tarefa do VS Code); sem sugestão válida, usa opus.
  -Pasta   pasta do projeto (padrão: a atual)
  -ApenasModelo  só mostra o modelo escolhido e sai, sem abrir o agy (para teste)

  O agy abre em modo interativo, já instruído a ler o CLAUDE.md, o ANDAMENTO.md e
  o git status e dizer onde o trabalho parou. Comandos e edições pedem sua aprovação.
#>
param(
  [string]$Modelo = 'opus',
  [string]$Pasta = (Get-Location).Path,
  [switch]$ApenasModelo
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object Text.UTF8Encoding $false
[Console]::OutputEncoding = $utf8

$agy = (Get-Command agy -ErrorAction SilentlyContinue).Source
if (-not $agy) { $agy = Join-Path $env:LOCALAPPDATA 'agy\bin\agy.exe' }
if (-not $ApenasModelo -and -not (Test-Path -LiteralPath $agy)) { throw 'Antigravity CLI (agy) não encontrado. Rode antigravity\scripts\verificar.ps1.' }

# Mesmo mapa de apelidos da ponte do plugin
$ponte = Join-Path $PSScriptRoot '..\plugin\scripts\agy.ps1'
$mapa = @{}
foreach ($m in [regex]::Matches((Get-Content -LiteralPath $ponte -Raw), "'([a-z-]+)'\s*=\s*'([^']+)'")) {
  $mapa[$m.Groups[1].Value] = $m.Groups[2].Value
}

$pastaResolvida = (Resolve-Path -LiteralPath $Pasta).Path
Set-Location -LiteralPath $pastaResolvida
$andamento = Join-Path $pastaResolvida 'ANDAMENTO.md'

# Pasta base do ambiente (config.local.psd1). Ela pode ter um CLAUDE.md geral, fora da pasta do projeto.
. (Join-Path $PSScriptRoot '..\..\lib\config.ps1')
$raizAmbiente = ([string]$Kit.PastaBase).TrimEnd('\')
$prefixoBase = $raizAmbiente + '\'
if ($raizAmbiente -match '^[A-Za-z]:$') { $raizAmbiente = $prefixoBase }  # raiz de unidade
$dentroDaBase = $raizAmbiente -and $pastaResolvida.StartsWith($prefixoBase, [StringComparison]::OrdinalIgnoreCase)
$claudeBase = Join-Path $raizAmbiente 'CLAUDE.md'
$temClaudeBase = $dentroDaBase -and (Test-Path -LiteralPath $claudeBase)

$avisos = @()
# "sugerido": o agy grava no ANDAMENTO.md a linha "**Próxima etapa:** <apelido> — ..." (regra do GEMINI.md)
if ($Modelo -eq 'sugerido') {
  $sugestao = $null
  if (Test-Path -LiteralPath $andamento) {
    foreach ($linha in [IO.File]::ReadAllLines($andamento, $utf8)) {
      $r = [regex]::Match($linha, '(?i)\*\*Pr.xima etapa:\*\*\s*`?([a-z0-9][a-z0-9-]*)')
      if ($r.Success) { $sugestao = $r.Groups[1].Value.ToLower() }
    }
  }
  if ($sugestao -and $mapa.ContainsKey($sugestao)) { $Modelo = $sugestao; $avisos += "modelo sugerido no ANDAMENTO.md: $sugestao" }
  elseif ($sugestao -like 'claude-*') { $Modelo = 'opus'; $avisos += "o ANDAMENTO.md sugere voltar ao Claude Code ($sugestao); usando opus no agy" }
  else { $Modelo = 'opus'; $avisos += 'sem sugestão de modelo no ANDAMENTO.md; usando opus' }
}
$idModelo = if ($mapa.ContainsKey($Modelo)) { $mapa[$Modelo] } else { $Modelo }
if ($ApenasModelo) { $avisos | ForEach-Object { Write-Host "  $_" }; Write-Output "$Modelo -> $idModelo"; exit 0 }

if (-not (Test-Path -LiteralPath $andamento)) { $avisos += 'sem ANDAMENTO.md (o agy vai se orientar pelo CLAUDE.md e pelo git)' }
if (-not (Test-Path -LiteralPath (Join-Path $pastaResolvida '.git'))) { $avisos += 'a pasta não é um repositório Git' }

Write-Host ''
Write-Host '  Continuando no Antigravity' -ForegroundColor Cyan
Write-Host "  Projeto: $pastaResolvida"
Write-Host "  Modelo:  $idModelo  (cota do Google AI Pro)"
foreach ($a in $avisos) { Write-Host "  Aviso:   $a" -ForegroundColor Yellow }
Write-Host '  Para sair: /exit ou Ctrl+C. Peça para ele atualizar o ANDAMENTO.md antes de sair.' -ForegroundColor DarkGray
Write-Host ''

# Sem aspas duplas no texto: o PowerShell 5.1 as removeria ao passar para o agy
$prompt = 'Estou continuando um trabalho que o Claude Code começou e não consegue terminar agora (cotas esgotadas). ' +
  'Siga as suas regras de continuidade: leia o CLAUDE.md deste projeto' + $(if ($temClaudeBase) { " (e também o $claudeBase, com as regras gerais do ambiente)" } else { '' }) + ', ' +
  'leia o ANDAMENTO.md se existir, rode git status --short e git log --oneline -5, e me diga em até 5 linhas onde o trabalho parou, ' +
  'o que está pendente e qual o próximo passo que você propõe. Não altere nada antes da minha resposta. ' +
  'Termine este resumo, e cada etapa concluída nesta conversa (não as respostas curtas), com a linha Próxima etapa ' +
  'da seção Escolha de modelo das suas regras globais.'

# Sem --add-dir o agy não pode ler o CLAUDE.md da pasta base (fica fora da pasta do projeto).
# Só se ele existir: a pasta base também guarda os dados do OmniRoute.
$extra = @()
if ($temClaudeBase) { $extra = @('--add-dir', $raizAmbiente) }

& $agy --model $idModelo @extra "-i=$prompt"
exit $LASTEXITCODE
