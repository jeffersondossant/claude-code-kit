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
$acao   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"$cmd`"" -WorkingDirectory $env:USERPROFILE
# Roda em SEGUNDO PLANO (S4U: seu usuário, sem guardar senha, sem janela na sua sessão).
# Assim o OmniRoute não cai ao bloquear a tela, trocar de usuário ou fechar janelas de terminal:
# no modo "logon interativo", o Windows 11 pode prender o processo a um terminal e encerrá-lo (0xC000013A).
$usuario   = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal -UserId $usuario -LogonType S4U -RunLevel Limited
$gatilhos  = @(
  (New-ScheduledTaskTrigger -AtStartup),                      # liga com o Windows, antes do logon
  (New-ScheduledTaskTrigger -AtLogOn -User $usuario),
  # Vigia: a cada 5 min tenta iniciar; se já estiver rodando, o Windows ignora (MultipleInstances IgnoreNew)
  (New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5))
)
$config = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit 0 -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $Script:NomeTarefa -Action $acao -Trigger $gatilhos -Principal $principal -Settings $config -Force | Out-Null
Write-Ok "Tarefa '$($Script:NomeTarefa)': OmniRoute $($Script:VersaoOmniRoute) em segundo plano, ao ligar o PC, no logon e com vigia a cada 5 min."

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
