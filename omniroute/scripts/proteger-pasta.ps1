<#
  Restringe o acesso à pasta de dados do OmniRoute (chaves e banco) a:
  você, SYSTEM e o grupo Administradores. Remove "Usuários" e "Usuários autenticados".

  Uso:
    powershell -ExecutionPolicy Bypass -File .\omniroute\scripts\proteger-pasta.ps1
    & ...\proteger-pasta.ps1 -Pasta "E:\outra\pasta"
#>
param([string]$Pasta)
. "$PSScriptRoot\lib\comum.ps1"
if (-not $Pasta) { $Pasta = if ($env:DATA_DIR) { $env:DATA_DIR } else { $Script:DataDirPadrao } }

Set-PastaProtegida $Pasta
Write-Ok "Protegida: $Pasta"
(Get-Acl -LiteralPath $Pasta).Access | Select-Object IdentityReference, FileSystemRights, IsInherited | Format-Table -AutoSize
