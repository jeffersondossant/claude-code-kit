<#
  Configura o OmniRoute neste PC: pasta de dados, início automático e primeira execução.
  Use depois de formatar (com os dados já no lugar) ou para refazer a tarefa de inicialização.

  Uso:
    powershell -ExecutionPolicy Bypass -File .\omniroute\scripts\instalar.ps1
    & ...\instalar.ps1 -DataDir "E:\outra\pasta" -SemIniciar

  Se aparecer "Acesso negado", rode num PowerShell aberto como Administrador.
#>
param(
  [string]$DataDir,
  [switch]$SemIniciar
)
. "$PSScriptRoot\lib\comum.ps1"
if (-not $DataDir) { $DataDir = $Script:DataDirPadrao }

Write-Etapa 'Conferindo pré-requisitos'
$npx = Get-Npx
Write-Ok "Node.js: $(node --version)"
if (-not (Test-Path -LiteralPath (Join-Path $DataDir 'storage.sqlite'))) {
  Write-Aviso "Não há banco em $DataDir."
  Write-Aviso "Se você tem o backup cifrado, rode antes: scripts\restaurar.ps1"
  Write-Aviso 'Se continuar, o OmniRoute começa do zero nessa pasta.'
  if ((Read-Host 'Continuar mesmo assim? (s/N)') -notmatch '^[sS]') { exit 1 }
}

Write-Etapa 'Protegendo a pasta de dados'
Set-PastaProtegida $DataDir
Write-Ok "Acesso restrito a você, SYSTEM e Administradores: $DataDir"

Write-Etapa 'Definindo DATA_DIR'
[Environment]::SetEnvironmentVariable('DATA_DIR', $DataDir, 'User')
$env:DATA_DIR = $DataDir
Write-Ok "DATA_DIR = $DataDir (terminais e VS Code abertos depois disto já enxergam)"

Write-Etapa 'Criando a tarefa de início automático'
$cmd = "`$env:DATA_DIR = '$DataDir'; & '$npx' -y omniroute@$($Script:VersaoOmniRoute)"
$acao   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -Command `"$cmd`"" -WorkingDirectory $env:USERPROFILE
$gatilho = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$config = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $Script:NomeTarefa -Action $acao -Trigger $gatilho -Settings $config -Force | Out-Null
Write-Ok "Tarefa '$($Script:NomeTarefa)' inicia o OmniRoute $($Script:VersaoOmniRoute) no logon, sem janela."

if ($SemIniciar) { exit 0 }

Write-Etapa 'Iniciando'
if (Test-OmniRouteNoAr) {
  Write-Aviso "Já existe algo na porta $($Script:PortaOmniRoute). Feche o OmniRoute aberto e rode: Start-ScheduledTask -TaskName $($Script:NomeTarefa)"
} else {
  Start-ScheduledTask -TaskName $Script:NomeTarefa
  for ($i = 0; $i -lt 60 -and -not (Test-OmniRouteNoAr); $i++) { Start-Sleep -Seconds 1 }
  if (Test-OmniRouteNoAr) { Write-Ok "No ar: http://localhost:$($Script:PortaOmniRoute)" }
  else { Write-Aviso 'Não subiu em 60 s. Na primeira vez o npx pode demorar baixando; confira de novo em instantes.' }
}
