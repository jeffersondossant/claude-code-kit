<#
  Instala a integração Claude Code + Antigravity (agy):
    1. registra este repositório como marketplace local do Claude Code e instala o plugin agy;
    2. grava as regras de delegação e continuidade no CLAUDE.md global do Claude Code;
    3. grava as regras de continuidade no GEMINI.md global do Antigravity
       (ler CLAUDE.md, ANDAMENTO.md e git status no início de cada conversa);
    4. cria no VS Code a tarefa "Continuar no Antigravity" e o atalho Ctrl+Alt+Shift+A;
    5. roda a verificação.
  Os blocos ficam entre marcadores: o resto dos arquivos não muda, e há cópia de segurança antes.

  Uso (na pasta do kit):
    powershell -ExecutionPolicy Bypass -File .\antigravity\scripts\instalar.ps1
    ... -SemRegras      # só plugin e VS Code, sem regras globais
    ... -SemVSCode      # sem tarefa/atalho no VS Code
    ... -RemoverRegras  # tira os blocos do CLAUDE.md e do GEMINI.md globais

  Depois, reinicie o Claude Code (ou rode /reload-plugins no chat).
#>
param([switch]$SemRegras, [switch]$SemVSCode, [switch]$RemoverRegras)
# 'Continue': no PowerShell 5.1, avisos que a CLI escreve no stderr virariam erro fatal com 'Stop'.
# As falhas reais são tratadas pelo $LASTEXITCODE e por throw.
$ErrorActionPreference = 'Continue'
$utf8 = New-Object Text.UTF8Encoding $false
[Console]::OutputEncoding = $utf8
function Write-Etapa([string]$t) { Write-Host "`n> $t" -ForegroundColor Cyan }
function Write-Ok([string]$t)    { Write-Host "  OK  $t" -ForegroundColor Green }
function Write-Aviso([string]$t) { Write-Host "  !!  $t" -ForegroundColor Yellow }

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $raiz 'lib\config.ps1')
$claudeGlobal = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
$geminiGlobal = Join-Path $env:USERPROFILE '.gemini\GEMINI.md'
$nomeTarefa = 'Continuar no Antigravity'
$atalho = 'ctrl+alt+shift+a'

function Copy-Seguranca([string]$arquivo) {
  if (Test-Path -LiteralPath $arquivo) { Copy-Item -LiteralPath $arquivo -Destination "$arquivo.bak-$((Get-Date).ToString('yyyyMMdd-HHmmss'))" }
}

# Grava (ou remove, com conteúdo vazio) um bloco entre marcadores, sem mexer no resto do arquivo
function Set-Bloco([string]$arquivo, [string]$id, [string]$conteudo) {
  $ini = "<!-- claude-code-kit:${id}:inicio (gerado por claude-code-kit; edite no repositório, em antigravity\regras) -->"
  $fim = "<!-- claude-code-kit:${id}:fim -->"
  New-Item -ItemType Directory -Path (Split-Path $arquivo) -Force | Out-Null
  $atual = if (Test-Path -LiteralPath $arquivo) { [IO.File]::ReadAllText($arquivo, $utf8) } else { '' }
  Copy-Seguranca $arquivo
  $padrao = '(?s)\r?\n?' + [regex]::Escape("<!-- claude-code-kit:${id}:inicio") + '.*?' + [regex]::Escape($fim) + '\r?\n?'
  $sem = [regex]::Replace($atual, $padrao, "`r`n").TrimEnd()
  $novo = if ($conteudo) { ($sem + "`r`n`r`n" + $ini + "`r`n" + $conteudo.Trim() + "`r`n" + $fim + "`r`n").TrimStart() } elseif ($sem) { $sem + "`r`n" } else { '' }
  [IO.File]::WriteAllText($arquivo, $novo, $utf8)
}

function Read-Regra([string]$nome) { return [IO.File]::ReadAllText((Join-Path $raiz "antigravity\regras\$nome"), $utf8) }

if ($RemoverRegras) {
  Set-Bloco $claudeGlobal 'agy' ''
  if (Test-Path -LiteralPath $geminiGlobal) { Set-Bloco $geminiGlobal 'continuidade' '' }
  Write-Ok 'Regras removidas do CLAUDE.md e do GEMINI.md globais (cópias de segurança ao lado).'
  exit 0
}

Write-Etapa 'Conferindo pré-requisitos'
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { throw 'CLI "claude" não encontrada. Instale o Claude Code e rode de novo.' }
$agy = (Get-Command agy -ErrorAction SilentlyContinue).Source
if (-not $agy -and -not (Test-Path (Join-Path $env:LOCALAPPDATA 'agy\bin\agy.exe'))) {
  throw 'Antigravity CLI (agy) não encontrado. Instale em https://antigravity.google, faça o login rodando "agy" e rode de novo.'
}
Write-Ok 'claude e agy encontrados'

Write-Etapa 'Pasta base do ambiente'
# A ponte do plugin (plugin\scripts\agy.ps1) lê esta variável para dar ao agy acesso ao CLAUDE.md da pasta base
[Environment]::SetEnvironmentVariable('CLAUDE_KIT_PASTA_BASE', $Kit.PastaBase, 'User')
$env:CLAUDE_KIT_PASTA_BASE = $Kit.PastaBase
Write-Ok "CLAUDE_KIT_PASTA_BASE = $($Kit.PastaBase)"

Write-Etapa 'Plugin do Claude Code'
$mkts = claude plugin marketplace list 2>&1 | Out-String
if ($mkts -match 'claude-code-kit') {
  claude plugin marketplace update claude-code-kit 2>&1 | Out-Host
} else {
  claude plugin marketplace add $raiz 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao registrar o marketplace local.' }
}
$plugins = claude plugin list 2>&1 | Out-String
if ($plugins -match 'agy@claude-code-kit') {
  claude plugin update agy@claude-code-kit 2>&1 | Out-Host
} else {
  claude plugin install agy@claude-code-kit --scope user 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar o plugin agy.' }
}
Write-Ok 'plugin agy@claude-code-kit instalado'

if (-not $SemRegras) {
  Write-Etapa 'Regras globais'
  Set-Bloco $claudeGlobal 'agy' (Read-Regra 'delegacao.md')
  # Instrução base do usuário: responder em português (fica no topo, fora dos blocos gerenciados)
  $linhaIdioma = 'Responda sempre em Português do Brasil.'
  $txtGlobal = [IO.File]::ReadAllText($claudeGlobal, $utf8)
  if ($txtGlobal -notmatch [regex]::Escape($linhaIdioma)) {
    [IO.File]::WriteAllText($claudeGlobal, $linhaIdioma + "`r`n`r`n" + $txtGlobal.TrimStart(), $utf8)
    Write-Ok 'Instrução de idioma (PT-BR) acrescentada no topo'
  }
  Write-Ok "Claude Code: $claudeGlobal"
  Set-Bloco $geminiGlobal 'continuidade' (Read-Regra 'gemini-global.md')
  Write-Ok "Antigravity: $geminiGlobal"
}

if (-not $SemVSCode) {
  Write-Etapa 'VS Code: tarefa e atalho'
  $pastaUser = Join-Path $env:APPDATA 'Code\User'
  if (-not (Test-Path -LiteralPath $pastaUser)) {
    Write-Aviso "VS Code não encontrado ($pastaUser). Pulando."
  } else {
    $script = Join-Path $raiz 'antigravity\scripts\continuar.ps1'
    $tarefa = [ordered]@{
      label = $nomeTarefa
      detail = 'Abre o agy neste projeto, lendo CLAUDE.md, ANDAMENTO.md e git status (claude-code-kit)'
      type = 'process'
      command = 'powershell.exe'
      args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script, '-Pasta', '${workspaceFolder}', '-Modelo', '${input:modeloAgy}')
      options = [ordered]@{ cwd = '${workspaceFolder}' }
      presentation = [ordered]@{ reveal = 'always'; focus = $true; panel = 'dedicated'; clear = $true }
      problemMatcher = @()
    }
    # Menu de escolha do modelo, mostrado pelo VS Code antes de abrir o agy (Esc cancela a tarefa)
    $entradaModelo = [ordered]@{
      id = 'modeloAgy'
      type = 'pickString'
      description = 'Com qual modelo continuar no Antigravity? (Esc cancela)'
      default = 'sugerido'
      options = @(
        [ordered]@{ label = 'sugerido no ANDAMENTO.md (linha Próxima etapa; sem ela, opus)'; value = 'sugerido' }
        [ordered]@{ label = 'hydrogen-rapido · leve: pergunta simples, edição curta · consumo baixo'; value = 'hydrogen-rapido' }
        [ordered]@{ label = 'hydrogen · padrão: pesquisa, leitura, revisão · consumo médio'; value = 'hydrogen' }
        [ordered]@{ label = 'hydrogen-max · profundo: decisão difícil · consumo alto'; value = 'hydrogen-max' }
        [ordered]@{ label = 'sonnet · código (Claude 4.6 pela cota do Google) · consumo alto'; value = 'sonnet' }
        [ordered]@{ label = 'opus · tarefa difícil do começo ao fim · consumo alto'; value = 'opus' }
      )
    }
    $tasksJson = Join-Path $pastaUser 'tasks.json'
    $ok = $true
    if (Test-Path -LiteralPath $tasksJson) {
      $txt = [IO.File]::ReadAllText($tasksJson, $utf8)
      try { $cfg = ($txt -replace '(?m)^\s*//.*$', '') | ConvertFrom-Json } catch { $cfg = $null }
      if (-not $cfg) { $ok = $false; Write-Aviso "Não consegui ler $tasksJson (tem comentários ou formato especial). Acrescente a tarefa à mão; veja o README." }
      else {
        $lista = @($cfg.tasks | Where-Object { $_ -and $_.label -ne $nomeTarefa }) + [pscustomobject]$tarefa
        $cfg | Add-Member -NotePropertyName tasks -NotePropertyValue $lista -Force
        $entradas = @($cfg.inputs | Where-Object { $_ -and $_.id -ne 'modeloAgy' }) + [pscustomobject]$entradaModelo
        $cfg | Add-Member -NotePropertyName inputs -NotePropertyValue $entradas -Force
        Copy-Seguranca $tasksJson
        [IO.File]::WriteAllText($tasksJson, ($cfg | ConvertTo-Json -Depth 10), $utf8)
      }
    } else {
      [IO.File]::WriteAllText($tasksJson, ([ordered]@{ version = '2.0.0'; tasks = @([pscustomobject]$tarefa); inputs = @([pscustomobject]$entradaModelo) } | ConvertTo-Json -Depth 10), $utf8)
    }
    if ($ok) { Write-Ok "Tarefa '$nomeTarefa' em $tasksJson" }

    $keysJson = Join-Path $pastaUser 'keybindings.json'
    $atalhoObj = [pscustomobject][ordered]@{ key = $atalho; command = 'workbench.action.tasks.runTask'; args = $nomeTarefa }
    if (Test-Path -LiteralPath $keysJson) {
      $txt = [IO.File]::ReadAllText($keysJson, $utf8)
      try { $lista = ($txt -replace '(?m)^\s*//.*$', '') | ConvertFrom-Json } catch { $lista = $null }
      if ($null -eq $lista -and $txt.Trim() -notmatch '^\[\s*\]$' -and $txt.Trim()) { Write-Aviso "Não consegui ler $keysJson. Atalho não criado; use Ctrl+Shift+P -> Tasks: Run Task." }
      else {
        $outros = @($lista | Where-Object { $_ -and -not ($_.command -eq 'workbench.action.tasks.runTask' -and $_.args -eq $nomeTarefa) })
        $conflito = $outros | Where-Object { $_.key -eq $atalho }
        if ($conflito) { Write-Aviso "O atalho $atalho já está em uso no seu keybindings.json; mantive o seu. Use Ctrl+Shift+P -> Tasks: Run Task." }
        else {
          Copy-Seguranca $keysJson
          [IO.File]::WriteAllText($keysJson, (ConvertTo-Json -InputObject @($outros + $atalhoObj) -Depth 5), $utf8)
          Write-Ok "Atalho Ctrl+Alt+Shift+A em $keysJson"
        }
      }
    } else {
      [IO.File]::WriteAllText($keysJson, (ConvertTo-Json -InputObject @($atalhoObj) -Depth 5), $utf8)
      Write-Ok "Atalho Ctrl+Alt+Shift+A em $keysJson"
    }
  }
}

Write-Etapa 'Verificando'
& (Join-Path $PSScriptRoot 'verificar.ps1')
Write-Host "`nReinicie o Claude Code (ou rode /reload-plugins no chat) para carregar plugin e regras." -ForegroundColor Green
