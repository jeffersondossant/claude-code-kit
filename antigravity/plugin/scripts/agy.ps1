<#
  Ponte entre o Claude Code e o Antigravity CLI (agy) no Windows.

  Recebe o prompt pela entrada padrão (ou -ArquivoPrompt), chama "agy -p" e
  devolve a resposta. Monta a linha de comando com o escape correto do Windows,
  porque o PowerShell 5.1 remove aspas dos argumentos passados a outros programas.

  Uso (pelo Bash do Claude Code):
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File agy.ps1 -Modelo hydrogen -Modo leitura <<'EOF'
    texto do pedido
    EOF

  -Modelo   hydrogen (padrão) | hydrogen-rapido | hydrogen-max | flash | flash-rapido | sonnet | opus | gpt | <id exato do "agy models">
  -Modo     leitura (padrão: só lê e pesquisa) | edicao (pode alterar arquivos)
  -Pasta    pasta de trabalho do agy (padrão: a atual; precisa existir)
  -Minutos  tempo máximo, de 1 a 60 (padrão: 9). A ponte espera até Minutos*60 + 20 s.
            A ferramenta Bash do Claude Code espera no máximo 600 s em primeiro plano:
            com mais de 9 minutos, rode o comando em segundo plano (run_in_background).
#>
param(
  [string]$Modelo = 'hydrogen',
  [ValidateSet('leitura', 'edicao')][string]$Modo = 'leitura',
  [string]$Pasta = (Get-Location).Path,
  [string]$Minutos = '9',
  [string]$ArquivoPrompt
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object Text.UTF8Encoding $false
[Console]::OutputEncoding = $utf8
[Console]::InputEncoding = $utf8

# Validação dos parâmetros, com mensagens claras (em vez de exceções do .NET)
if ($Minutos -notmatch '^\d{1,3}$' -or [int]$Minutos -lt 1 -or [int]$Minutos -gt 60) {
  [Console]::Error.WriteLine("agy.ps1: -Minutos deve ser um número inteiro de 1 a 60 (recebido: '$Minutos')."); exit 2
}
$min = [int]$Minutos
if ([string]::IsNullOrWhiteSpace($Pasta) -or -not (Test-Path -LiteralPath $Pasta -PathType Container)) {
  [Console]::Error.WriteLine("agy.ps1: a pasta de trabalho não existe: '$Pasta' (-Pasta)."); exit 2
}
if ($ArquivoPrompt -and -not (Test-Path -LiteralPath $ArquivoPrompt -PathType Leaf)) {
  [Console]::Error.WriteLine("agy.ps1: arquivo do prompt não encontrado: '$ArquivoPrompt' (-ArquivoPrompt)."); exit 2
}
if ([string]::IsNullOrWhiteSpace($Modelo) -or $Modelo.StartsWith('-')) {
  [Console]::Error.WriteLine("agy.ps1: modelo inválido: '$Modelo' (-Modelo)."); exit 2
}

# Apelidos -> ids do "agy models" (confira com antigravity\scripts\verificar.ps1)
$apelidos = @{
  'hydrogen'        = 'gemini-4-hydrogen-high'
  'hydrogen-rapido' = 'gemini-4-hydrogen-low'
  'hydrogen-max'    = 'gemini-4-hydrogen-xhigh'
  'flash'        = 'gemini-3.8-flash-high'
  'flash-rapido' = 'gemini-3.8-flash-low'
  'sonnet'       = 'claude-sonnet-4-6'
  'opus'         = 'claude-opus-4-6-thinking'
  'gpt'          = 'gpt-oss-120b-medium'
}
$idModelo = if ($apelidos.ContainsKey($Modelo)) { $apelidos[$Modelo] } else { $Modelo }
$modoAgy = if ($Modo -eq 'edicao') { 'accept-edits' } else { 'plan' }

if ($ArquivoPrompt) { $prompt = [IO.File]::ReadAllText($ArquivoPrompt, $utf8) }
else { $prompt = [Console]::In.ReadToEnd() }
$prompt = $prompt.Trim()
if (-not $prompt) { [Console]::Error.WriteLine('agy.ps1: prompt vazio (envie pela entrada padrão ou -ArquivoPrompt).'); exit 2 }

$agy = (Get-Command agy -ErrorAction SilentlyContinue).Source
if (-not $agy) { $agy = Join-Path $env:LOCALAPPDATA 'agy\bin\agy.exe' }
if (-not (Test-Path -LiteralPath $agy)) { [Console]::Error.WriteLine('agy.ps1: Antigravity CLI (agy) não encontrado. Rode antigravity\scripts\verificar.ps1.'); exit 3 }

# Regras de aspas do Windows (CommandLineToArgvW): barras antes de aspas são dobradas
function ConvertTo-ArgumentoWindows([string]$a) {
  if ($a -and $a -notmatch '[\s"]') { return $a }
  $sb = New-Object Text.StringBuilder; [void]$sb.Append('"'); $barras = 0
  foreach ($c in $a.ToCharArray()) {
    if ($c -eq '\') { $barras++; continue }
    if ($c -eq '"') { [void]$sb.Append('\' * ($barras * 2 + 1)); [void]$sb.Append('"') }
    else { [void]$sb.Append('\' * $barras); [void]$sb.Append($c) }
    $barras = 0
  }
  [void]$sb.Append('\' * ($barras * 2)); [void]$sb.Append('"')
  return $sb.ToString()
}

# No modo plan (leitura) o agy não grava arquivos, mas também não pode usar o terminal:
# sem alguém para aprovar, o comando é negado e a resposta volta vazia. Orientamos a usar
# as ferramentas de leitura/busca de arquivos e a pesquisa na web.
if ($Modo -eq 'leitura') {
  $prompt = "[Modo somente leitura: NÃO use run_command/terminal (será negado) nem crie ou altere arquivos. Leia arquivos com read_file, pelos caminhos informados no pedido; você não consegue listar pastas, então se precisar de um arquivo que não foi informado, diga qual. Para informações externas, use search_web. Responda direto, sem plano de implementação. Se não conseguir verificar algo, diga claramente que não conseguiu: nunca invente nomes de arquivos, números ou fatos.]`n`n$prompt"
} else {
  # No modo edição o terminal também é negado (ninguém aprova), e o agy desiste sem resposta se tentar.
  $prompt = "[Modo edição não interativo: você pode ler e alterar arquivos do projeto, mas NÃO use run_command/terminal (será negado e a tarefa termina sem resposta). Não rode testes, git, bash -n nem verificadores: trabalhe lendo e editando arquivos, pelos caminhos informados no pedido, e só dentro da pasta do projeto (fora dela a leitura também é negada). O que só desse para conferir no terminal, liste no fim como a conferir. Termine sempre com uma resposta em texto.]`n`n$prompt"
}

$argumentos = @('--model', $idModelo, '--mode', $modoAgy, '--output-format', 'json', '--print-timeout', "$($min * 60)s")
# A pasta base do ambiente pode ter um CLAUDE.md geral, fora da pasta do projeto: sem --add-dir
# o agy não pode lê-lo. O instalador grava a pasta base na variável de usuário CLAUDE_KIT_PASTA_BASE.
# Só no modo leitura: no modo edição isso daria ao agy acesso de escrita aos projetos vizinhos.
$raizAmbiente = $env:CLAUDE_KIT_PASTA_BASE
if (-not $raizAmbiente) { $raizAmbiente = [Environment]::GetEnvironmentVariable('CLAUDE_KIT_PASTA_BASE', 'User') }
$pastaCheia = [IO.Path]::GetFullPath($Pasta)
if ($Modo -eq 'leitura' -and $raizAmbiente) {
  $raizAmbiente = $raizAmbiente.TrimEnd('\')
  if ($pastaCheia.StartsWith($raizAmbiente + '\', [StringComparison]::OrdinalIgnoreCase)) { $argumentos += @('--add-dir', $raizAmbiente) }
}
$argumentos += "-p=$prompt"
$psi = New-Object Diagnostics.ProcessStartInfo
$psi.FileName = $agy
$psi.Arguments = ($argumentos | ForEach-Object { ConvertTo-ArgumentoWindows $_ }) -join ' '
# O Windows limita a linha de comando a 32.767 caracteres (CreateProcess); acima disso o Start quebra.
if ($psi.Arguments.Length -gt 32000) {
  [Console]::Error.WriteLine("agy.ps1: pedido grande demais para a linha de comando do Windows ($($psi.Arguments.Length) de 32000 caracteres). " +
    'Não cole diffs ou arquivos inteiros: passe os caminhos completos dos arquivos (dentro da pasta do projeto) e peça para o agy lê-los.')
  exit 2
}
$psi.WorkingDirectory = $Pasta
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.StandardOutputEncoding = $utf8
$psi.StandardErrorEncoding = $utf8
$psi.CreateNoWindow = $true

$proc = [Diagnostics.Process]::Start($psi)
# Leitura assíncrona das duas saídas: com ReadToEnd() síncrono, um agy travado prenderia o script
# antes do WaitForExit, e o tempo limite nunca dispararia.
$tarefaErro = $proc.StandardError.ReadToEndAsync()
$tarefaSaida = $proc.StandardOutput.ReadToEndAsync()
if (-not $proc.WaitForExit(($min * 60 + 20) * 1000)) {
  # taskkill /T encerra também os processos filhos do agy (Kill() do .NET 4 mata só o principal)
  & taskkill.exe /PID $proc.Id /T /F *> $null
  if (-not $proc.HasExited) { $proc.Kill() }
  [Console]::Error.WriteLine("agy.ps1: o agy não respondeu em $min min."); exit 124
}
$proc.WaitForExit()  # garante o fim das leituras assíncronas
$saida = $tarefaSaida.Result
$erro = $tarefaErro.Result

# Saída JSON: {"status","response","denied_actions":[{"action","display_name"}], ...}
$json = $null
try { $json = $saida | ConvertFrom-Json } catch { }
if ($json) {
  if ($json.response) { [Console]::Out.Write(([string]$json.response).TrimEnd() + "`n") }
  $negadas = @($json.denied_actions | Where-Object { $_ } | ForEach-Object { if ($_.display_name) { $_.display_name } else { $_.action } }) | Select-Object -Unique
  if ($negadas) {
    $dica = if ($Modo -eq 'leitura') { 'No modo leitura o agy não pode usar o terminal nem alterar arquivos. Reformule pedindo leitura/busca de arquivos ou pesquisa na web; se a tarefa exigir terminal ou edição, use -Modo edicao (só com autorização do usuário).' } else { 'No modo edição não interativo o agy não usa o terminal e só lê e grava dentro da pasta do projeto. Informe só arquivos da pasta, ou rode o comando você mesmo.' }
    [Console]::Error.WriteLine("agy.ps1: o agy tentou usar ($($negadas -join ', ')) e a ação foi negada. $dica")
  }
  if (-not $json.response) {
    [Console]::Error.WriteLine("agy.ps1: o agy terminou sem texto de resposta (status $($json.status)).")
    if ($proc.ExitCode -eq 0) { exit 4 }
  }
} else {
  [Console]::Out.Write($saida)
}
if ($proc.ExitCode -ne 0) {
  [Console]::Error.WriteLine("agy.ps1: agy saiu com código $($proc.ExitCode) (modelo $idModelo).")
  if ($erro) { [Console]::Error.WriteLine($erro.Trim()) }
}
exit $proc.ExitCode
