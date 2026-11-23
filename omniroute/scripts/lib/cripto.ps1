# Cifragem do backup com senha, usando só o .NET que já vem no Windows.
#
# Formato do arquivo .enc:
#   "OMRBKP01" (8 bytes) | iterações (4 bytes, little-endian) | salt (16) | IV (16)
#   | dados cifrados (AES-256-CBC, PKCS7) | HMAC-SHA256 (32) de tudo que vem antes
#
# Chaves: PBKDF2-HMAC-SHA256 (600.000 iterações) gera 64 bytes a partir da senha:
# os 32 primeiros cifram (AES) e os 32 últimos autenticam (HMAC).
# O HMAC é conferido antes de decifrar: senha errada ou arquivo adulterado são recusados.

$Script:MagicBackup = [Text.Encoding]::ASCII.GetBytes('OMRBKP01')
$Script:IteracoesPbkdf2 = 600000

function New-BytesAleatorios([int]$Tamanho) {
  $b = New-Object byte[] $Tamanho
  $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
  try { $rng.GetBytes($b) } finally { $rng.Dispose() }
  return ,$b
}

function Get-ChavesDaSenha([Security.SecureString]$Senha, [byte[]]$Salt, [int]$Iteracoes) {
  $texto = ConvertFrom-Segura $Senha
  $kdf = New-Object Security.Cryptography.Rfc2898DeriveBytes($texto, $Salt, $Iteracoes, [Security.Cryptography.HashAlgorithmName]::SHA256)
  try { $k = $kdf.GetBytes(64) } finally { $kdf.Dispose(); $texto = $null }
  return @{ Cifra = $k[0..31]; Mac = $k[32..63] }
}

function Join-Bytes([byte[][]]$Partes) {
  $ms = New-Object IO.MemoryStream
  foreach ($p in $Partes) { $ms.Write($p, 0, $p.Length) }
  return ,$ms.ToArray()
}

function Protect-BytesComSenha([byte[]]$Dados, [Security.SecureString]$Senha) {
  $salt = New-BytesAleatorios 16
  $iv   = New-BytesAleatorios 16
  $k    = Get-ChavesDaSenha $Senha $salt $Script:IteracoesPbkdf2

  $aes = [Security.Cryptography.Aes]::Create()
  $aes.KeySize = 256; $aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'
  $aes.Key = [byte[]]$k.Cifra; $aes.IV = $iv
  $enc = $aes.CreateEncryptor()
  try { $cifrado = $enc.TransformFinalBlock($Dados, 0, $Dados.Length) } finally { $enc.Dispose(); $aes.Dispose() }

  $cab = Join-Bytes @($Script:MagicBackup, [BitConverter]::GetBytes([int]$Script:IteracoesPbkdf2), $salt, $iv)
  $corpo = Join-Bytes @($cab, $cifrado)
  $hmac = New-Object Security.Cryptography.HMACSHA256 (,[byte[]]$k.Mac)
  try { $tag = $hmac.ComputeHash($corpo) } finally { $hmac.Dispose() }
  return ,(Join-Bytes @($corpo, $tag))
}

function Unprotect-BytesComSenha([byte[]]$Arquivo, [Security.SecureString]$Senha) {
  $min = 8 + 4 + 16 + 16 + 16 + 32
  if ($Arquivo.Length -lt $min) { throw 'Arquivo de backup inválido (muito pequeno).' }
  for ($i = 0; $i -lt 8; $i++) {
    if ($Arquivo[$i] -ne $Script:MagicBackup[$i]) { throw 'Este arquivo não é um backup do claude-code-kit (ou do claude-code-setup).' }
  }
  $iter = [BitConverter]::ToInt32($Arquivo, 8)
  $salt = $Arquivo[12..27]
  $iv   = $Arquivo[28..43]
  $fimCorpo = $Arquivo.Length - 32
  $corpo = New-Object byte[] $fimCorpo
  [Array]::Copy($Arquivo, 0, $corpo, 0, $fimCorpo)
  $tag = $Arquivo[$fimCorpo..($Arquivo.Length - 1)]

  $k = Get-ChavesDaSenha $Senha ([byte[]]$salt) $iter
  $hmac = New-Object Security.Cryptography.HMACSHA256 (,[byte[]]$k.Mac)
  try { $esperado = $hmac.ComputeHash($corpo) } finally { $hmac.Dispose() }
  $dif = 0
  for ($i = 0; $i -lt 32; $i++) { $dif = $dif -bor ($esperado[$i] -bxor $tag[$i]) }
  if ($dif -ne 0) { throw 'Senha incorreta ou arquivo de backup corrompido.' }

  $ini = 44
  $aes = [Security.Cryptography.Aes]::Create()
  $aes.KeySize = 256; $aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'
  $aes.Key = [byte[]]$k.Cifra; $aes.IV = [byte[]]$iv
  $dec = $aes.CreateDecryptor()
  try { return ,($dec.TransformFinalBlock($corpo, $ini, $corpo.Length - $ini)) } finally { $dec.Dispose(); $aes.Dispose() }
}
