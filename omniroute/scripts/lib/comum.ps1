# Configuração e funções compartilhadas pelos scripts do OmniRoute (claude-code-kit).
# Carregado com:  . "$PSScriptRoot\lib\comum.ps1"

$ErrorActionPreference = 'Stop'

# ---- Configuração -----------------------------------------------------------
# Vem de lib\config.ps1 (padrões + config.local.psd1). Edite o config.local.psd1, não este arquivo.
# lib -> scripts -> omniroute -> raiz do kit
. (Join-Path $PSScriptRoot '..\..\..\lib\config.ps1')
$Script:RaizRepo        = $Kit.RaizKit
$Script:DataDirPadrao   = $Kit.PastaDadosOmni    # DATA_DIR do OmniRoute
$Script:VersaoOmniRoute = $Kit.VersaoOmniRoute   # versão fixa (o npx não troca sozinho)
$Script:NomeTarefa      = $Kit.NomeTarefa
$Script:PortaOmniRoute  = $Kit.PortaOmniRoute
$Script:ArquivoBackup   = $Kit.ArquivoBackup

# ---- Utilitários ------------------------------------------------------------
function Write-Etapa([string]$Texto) { Write-Host "`n> $Texto" -ForegroundColor Cyan }
function Write-Ok([string]$Texto)    { Write-Host "  OK  $Texto" -ForegroundColor Green }
function Write-Aviso([string]$Texto) { Write-Host "  !!  $Texto" -ForegroundColor Yellow }

function Get-Npx {
  $npx = (Get-Command npx.cmd -ErrorAction SilentlyContinue).Source
  if (-not $npx) { throw 'Node.js não encontrado. Instale em https://nodejs.org (versão LTS) e rode de novo.' }
  return $npx
}

function Test-OmniRouteNoAr {
  return [bool](Get-NetTCPConnection -LocalPort $Script:PortaOmniRoute -State Listen -ErrorAction SilentlyContinue)
}

# Restringe a pasta ao usuário atual, SYSTEM e Administradores.
# Administradores (SID fixo S-1-5-32-544) fica para que, depois de formatar,
# o novo usuário administrador consiga retomar o acesso à pasta no D:.
function Set-PastaProtegida([string]$Pasta) {
  if (-not (Test-Path -LiteralPath $Pasta)) { New-Item -ItemType Directory -Path $Pasta | Out-Null }
  $eu = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
  & icacls $Pasta /inheritance:r /grant:r "*${eu}:(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' /Q | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "icacls falhou ao proteger $Pasta (código $LASTEXITCODE)." }
  # Faz os arquivos e subpastas herdarem a nova regra
  & icacls (Join-Path $Pasta '*') /reset /T /C /Q | Out-Null
}

function Read-SenhaBackup([switch]$Confirmar) {
  $s1 = Read-Host 'Senha do backup' -AsSecureString
  if ($s1.Length -lt 12) { throw 'Use uma senha com pelo menos 12 caracteres (uma frase longa é o ideal).' }
  if ($Confirmar) {
    $s2 = Read-Host 'Repita a senha' -AsSecureString
    if ((ConvertFrom-Segura $s1) -cne (ConvertFrom-Segura $s2)) { throw 'As senhas não conferem.' }
  }
  return $s1
}

function ConvertFrom-Segura([Security.SecureString]$Segura) {
  $p = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Segura)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($p) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($p) }
}
