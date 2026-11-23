<#
  claude-code-kit: instala e configura tudo no Windows.
    Programas (winget): Git, Node.js LTS, VS Code, Antigravity CLI
    Claude Code (CLI + extensões do VS Code), OmniRoute (pasta de dados protegida, DATA_DIR,
    início automático), login no Antigravity, plugin agy, regras globais, tarefa do VS Code
    e MCP do OmniRoute (somente leitura).
  Serve para começar do zero e para migrar para um PC novo. Pula o que já estiver pronto;
  pode ser executado de novo quantas vezes precisar. No fim, lista o que falta fazer à mão.

  Uso (PowerShell COMO ADMINISTRADOR, na pasta do kit):
    powershell -ExecutionPolicy Bypass -File .\instalar.ps1
    ... -Simular          mostra o que faria, sem instalar nem alterar nada
    ... -EmailGit <e>     e-mail para o git config

  Configuração: config.local.psd1 (criado na 1ª execução a partir do config.exemplo.psd1).
#>
param([switch]$Simular, [string]$EmailGit)

$ErrorActionPreference = 'Continue'
$utf8 = New-Object Text.UTF8Encoding $false
[Console]::OutputEncoding = $utf8
$raiz = $PSScriptRoot
$pendencias = New-Object System.Collections.Generic.List[string]
$etapa = 0

function Write-Etapa([string]$t) { $script:etapa++; Write-Host "`n[$script:etapa] $t" -ForegroundColor Cyan }
function Write-Ok([string]$t)    { Write-Host "    OK  $t" -ForegroundColor Green }
function Write-Pula([string]$t)  { Write-Host "    --  $t" -ForegroundColor DarkGray }
function Write-Aviso([string]$t) { Write-Host "    !!  $t" -ForegroundColor Yellow }
function Write-Faz([string]$t)   { if ($Simular) { Write-Host "    (simulação) faria: $t" -ForegroundColor Magenta } else { Write-Host "    ... $t" } }
function Update-Path { $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') }
function Test-Comando([string]$c) { Update-Path; return [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Install-Winget([string]$id, [string]$comando, [string]$nome) {
  if (Test-Comando $comando) { Write-Pula "$nome já instalado"; return }
  Write-Faz "winget install $id"
  if ($Simular) { return }
  winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent
  if (Test-Comando $comando) { Write-Ok "$nome instalado" } else { Write-Aviso "${nome}: o comando '$comando' ainda não aparece. Feche e abra o PowerShell (como Administrador) e rode este script de novo." }
}

Write-Host "`n=== claude-code-kit: instalação ===" -ForegroundColor White
if ($Simular) { Write-Host '(modo simulação: nada será instalado nem alterado)' -ForegroundColor Magenta }

# ---------------------------------------------------------------------------
Write-Etapa 'Conferindo o básico e a configuração'
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin -and -not $Simular) { Write-Host '    Rode este script num PowerShell aberto COMO ADMINISTRADOR.' -ForegroundColor Red; exit 1 }
if ($admin) { Write-Ok 'PowerShell como Administrador' } else { Write-Aviso 'não está como Administrador (ok só na simulação)' }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Host '    winget não encontrado. Atualize o "Instalador de Aplicativo" pela Microsoft Store.' -ForegroundColor Red; exit 1 }
Write-Ok 'winget disponível'

$cfgLocal = Join-Path $raiz 'config.local.psd1'
if (-not (Test-Path -LiteralPath $cfgLocal)) {
  $padrao = Join-Path $env:USERPROFILE 'claude-code'
  Write-Host '    Ainda não há config.local.psd1. Onde guardar os dados do ambiente (OmniRoute, backups)?' -ForegroundColor Yellow
  Write-Host '    Dica: um disco que sobreviva a uma formatação do Windows, ex.: D:\claude-code' -ForegroundColor DarkGray
  $base = if ($Simular) { '' } else { Read-Host "    Pasta base (Enter = $padrao)" }
  if (-not $base) { $base = $padrao }
  $modelo = [IO.File]::ReadAllText((Join-Path $raiz 'config.exemplo.psd1'), $utf8)
  $modelo = $modelo -replace "PastaBase = '[^']*'", ("PastaBase = '" + $base.TrimEnd('\').Replace("'", "''") + "'")
  Write-Faz "criar config.local.psd1 com PastaBase = $base"
  if (-not $Simular) { [IO.File]::WriteAllText($cfgLocal, $modelo, $utf8) }
} else { Write-Pula 'config.local.psd1 já existe' }
. (Join-Path $raiz 'lib\config.ps1')
if ($Simular -and -not $Kit.TemConfigLocal) { Write-Host '    (simulação: usando os padrões)' -ForegroundColor Magenta }
Write-Ok "pasta base: $($Kit.PastaBase)"
if (-not (Test-Path -LiteralPath $Kit.PastaBase)) {
  Write-Faz "criar a pasta $($Kit.PastaBase)"
  if (-not $Simular) { New-Item -ItemType Directory -Path $Kit.PastaBase -Force | Out-Null }
}

# ---------------------------------------------------------------------------
Write-Etapa 'Programas (winget)'
Install-Winget 'Git.Git'                    'git'  'Git'
Install-Winget 'OpenJS.NodeJS.LTS'          'node' 'Node.js LTS'
Install-Winget 'Microsoft.VisualStudioCode' 'code' 'VS Code'
Install-Winget 'Google.AntigravityCLI'      'agy'  'Antigravity CLI'
if (-not (Test-Comando 'agy') -and (Test-Path "$env:LOCALAPPDATA\agy\bin\agy.exe")) {
  Write-Faz 'agy install (configurar PATH)'
  if (-not $Simular) { & "$env:LOCALAPPDATA\agy\bin\agy.exe" install | Out-Null; Update-Path }
}

# ---------------------------------------------------------------------------
Write-Etapa 'Git'
if (Test-Comando 'git') {
  $nomeGit = git config --global user.name
  if ($nomeGit) { Write-Pula "user.name = $nomeGit" }
  else {
    $n = $Kit.NomeGit
    if (-not $n -and -not $Simular) { $n = Read-Host '    Seu nome para o Git (Enter para pular)' }
    if ($n) { Write-Faz 'git config --global user.name'; if (-not $Simular) { git config --global user.name $n } }
    else { $pendencias.Add('Configurar o nome do Git: git config --global user.name "Seu Nome"') }
  }
  if (git config --global user.email) { Write-Pula 'user.email já configurado' }
  else {
    if (-not $EmailGit) { $EmailGit = $Kit.EmailGit }
    if (-not $EmailGit -and -not $Simular) { $EmailGit = Read-Host '    Seu e-mail para o Git (Enter para pular)' }
    if ($EmailGit) { Write-Faz 'git config --global user.email'; if (-not $Simular) { git config --global user.email $EmailGit } }
    else { $pendencias.Add('Configurar o e-mail do Git: git config --global user.email "seu-email"') }
  }
} else { Write-Aviso 'Git indisponível nesta sessão; rode o script de novo depois.' }

# ---------------------------------------------------------------------------
Write-Etapa 'Claude Code (CLI e extensões do VS Code)'
if (Test-Comando 'claude') { Write-Pula 'Claude Code CLI já instalado' }
elseif (Test-Comando 'npm') { Write-Faz 'npm install -g @anthropic-ai/claude-code'; if (-not $Simular) { npm install -g @anthropic-ai/claude-code; Update-Path } }
else { Write-Aviso 'npm indisponível; rode o script de novo depois de reabrir o PowerShell.' }
if (Test-Comando 'code') {
  $exts = @(code --list-extensions 2>$null)
  foreach ($e in 'anthropic.claude-code', 'ms-ceintl.vscode-language-pack-pt-br') {
    if ($exts -contains $e) { Write-Pula "extensão $e" } else { Write-Faz "code --install-extension $e"; if (-not $Simular) { code --install-extension $e --force | Out-Null } }
  }
} else { Write-Aviso 'VS Code indisponível nesta sessão; rode o script de novo depois.' }

# ---------------------------------------------------------------------------
Write-Etapa 'Histórico de conversas do Claude Code (migração de PC)'
$claudeDir = Join-Path $env:USERPROFILE '.claude'
$histOrigem = Join-Path $Kit.PastaHistorico 'projects'
if (Test-Path -LiteralPath $histOrigem) {
  Write-Faz "copiar $histOrigem -> $claudeDir\projects (sem sobrescrever o que for mais novo)"
  if (-not $Simular) { robocopy $histOrigem (Join-Path $claudeDir 'projects') /E /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null; Write-Ok 'histórico restaurado' }
} else { Write-Pula 'sem cópia de histórico (só existe se você rodou salvar-para-pc-novo.ps1 no PC antigo)' }

# ---------------------------------------------------------------------------
Write-Etapa 'settings.json do Claude Code (liga o Claude Code ao OmniRoute)'
$settings = Join-Path $claudeDir 'settings.json'
if (Test-Path -LiteralPath $settings) { Write-Pula 'settings.json já existe' }
elseif (Test-Path -LiteralPath $Kit.ArquivoBackup) {
  if (Get-NetTCPConnection -LocalPort $Kit.PortaOmniRoute -State Listen -ErrorAction SilentlyContinue) {
    Write-Aviso 'OmniRoute já está no ar; o restaurar.ps1 exige que ele esteja parado. Pare-o e rode o script de novo.'
  } else {
    $tmp = Join-Path $env:TEMP 'omniroute-extrair'
    Write-Faz "extrair o settings.json do backup cifrado $($Kit.ArquivoBackup) (pede a SENHA DO BACKUP)"
    if (-not $Simular) {
      & (Join-Path $raiz 'omniroute\scripts\restaurar.ps1') -DataDir $tmp
      Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path -LiteralPath $settings) { Write-Ok 'settings.json restaurado; cópia temporária das chaves apagada' }
    }
  }
} else {
  Write-Faz 'copiar o modelo omniroute\claude-settings.exemplo.json para %USERPROFILE%\.claude\settings.json'
  if (-not $Simular) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    Copy-Item (Join-Path $raiz 'omniroute\claude-settings.exemplo.json') $settings
  }
  $pendencias.Add("Colar a chave Claude-Code do OmniRoute no $settings (campo ANTHROPIC_AUTH_TOKEN) - tutorial, etapa 4")
}
if ((Test-Path -LiteralPath $settings) -and -not $Simular) {
  $t = [IO.File]::ReadAllText($settings)
  if ($t -notmatch '"cleanupPeriodDays"') {
    [IO.File]::WriteAllText($settings, [regex]::Replace($t, '^\s*\{', "{`r`n    `"cleanupPeriodDays`":  36500,", 1), $utf8)
    Write-Ok 'histórico de conversas sem limpeza automática (cleanupPeriodDays 36500)'
  } else { Write-Pula 'cleanupPeriodDays já configurado' }
} elseif ($Simular) { Write-Faz 'garantir "cleanupPeriodDays": 36500 no settings.json' }

# ---------------------------------------------------------------------------
Write-Etapa 'OmniRoute (pasta de dados protegida, DATA_DIR, início automático)'
$novoOmni = -not (Test-Path -LiteralPath (Join-Path $Kit.PastaDadosOmni 'storage.sqlite'))
if ($novoOmni) { Write-Host "    Instalação nova do OmniRoute em $($Kit.PastaDadosOmni) (o script vai pedir confirmação)." -ForegroundColor Yellow }
Write-Faz 'omniroute\scripts\instalar.ps1'
if (-not $Simular) { & (Join-Path $raiz 'omniroute\scripts\instalar.ps1') }
if ($novoOmni) {
  $pendencias.Add('Painel do OmniRoute (http://localhost:20128): trocar a senha CHANGEME, conectar os provedores, criar os combos claude-pro-fallback, claude-sonnet-fallback e claude-rapido-fallback e a chave Claude-Code - tutorial, etapa 3C')
  $pendencias.Add('Compressão: Contexto -> Configurações de compressão e Combos de Engines (claude-code-seguro) - tutorial, etapa 5.1')
  $pendencias.Add('Primeiro backup cifrado: powershell -ExecutionPolicy Bypass -File .\omniroute\scripts\backup.ps1')
}

# ---------------------------------------------------------------------------
Write-Etapa 'Login no Antigravity'
if (Test-Comando 'agy') {
  $j = Start-Job { agy models 2>$null | Out-String }
  $mods = if (Wait-Job $j -Timeout 60) { Receive-Job $j } else { Stop-Job $j; '' }
  Remove-Job $j -Force
  if ($mods -match 'gemini') { Write-Pula 'agy já está logado' }
  elseif ($Simular) { Write-Faz 'abrir o agy para login com a conta do Google AI Pro' }
  else {
    Write-Host '    Vai abrir o agy numa janela nova. Faça o login com a conta do Google AI Pro e saia com /exit.' -ForegroundColor Yellow
    Start-Process powershell -ArgumentList '-NoExit', '-Command', 'agy' -WorkingDirectory $env:USERPROFILE
    Read-Host '    Tecle Enter aqui depois de fazer o login'
  }
} else { $pendencias.Add('Instalar o Antigravity CLI: winget install --id Google.AntigravityCLI -e, e rodar este script de novo') }

# ---------------------------------------------------------------------------
Write-Etapa 'Antigravity no Claude Code (plugin, regras globais, tarefa do VS Code)'
Write-Faz 'antigravity\scripts\instalar.ps1'
if (-not $Simular -and (Test-Comando 'claude') -and (Test-Comando 'agy')) { & (Join-Path $raiz 'antigravity\scripts\instalar.ps1') }
elseif (-not $Simular) { $pendencias.Add('Rodar antigravity\scripts\instalar.ps1 (faltava claude ou agy)') }

# ---------------------------------------------------------------------------
Write-Etapa 'MCP do OmniRoute (somente leitura)'
if (Test-Comando 'claude') {
  $mcp = claude mcp list 2>&1 | Out-String
  if ($mcp -match '(?m)^omniroute') { Write-Pula 'MCP omniroute já registrado' }
  else {
    Write-Faz 'claude mcp add omniroute (escopo usuário, read:*)'
    if (-not $Simular) {
      $npx = (Get-Command npx.cmd -ErrorAction SilentlyContinue).Source
      $a = @('mcp', 'add', 'omniroute', '--scope', 'user',
             '-e', "DATA_DIR=$($Kit.PastaDadosOmni)", '-e', "OMNIROUTE_BASE_URL=http://localhost:$($Kit.PortaOmniRoute)",
             '-e', 'OMNIROUTE_MCP_ENFORCE_SCOPES=true', '-e', 'OMNIROUTE_MCP_SCOPES=read:*',
             '--', $npx, '-y', "omniroute@$($Kit.VersaoOmniRoute)", '--mcp')
      & claude @a
    }
  }
}
if (-not [Environment]::GetEnvironmentVariable('OMNIROUTE_API_KEY', 'User')) {
  $pendencias.Add('Criar a chave mcp-leitura no painel e gravá-la em OMNIROUTE_API_KEY - tutorial, etapa 5.2')
}

# ---------------------------------------------------------------------------
Write-Host "`n=== Instalação concluída ===" -ForegroundColor White
if (-not $Simular) {
  Write-Host 'Verificação do Antigravity:' -ForegroundColor Cyan
  & (Join-Path $raiz 'antigravity\scripts\verificar.ps1') -SemTesteReal
}
Write-Host "`nFalta fazer à mão (configurações internas):" -ForegroundColor Yellow
$pendencias.Add('Reiniciar o VS Code e, no chat do Claude Code, conferir o modelo: /model opusplan')
$pendencias.Add('Na 1ª vez do Ctrl+Alt+Shift+A em cada projeto, responder "Yes, I trust this folder" no agy')
$i = 0; foreach ($p in $pendencias) { $i++; Write-Host "  $i. $p" }
Write-Host "`nDetalhes: docs\TUTORIAL-INSTALACAO.md" -ForegroundColor DarkGray
