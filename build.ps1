# Build index.html dari src.html: minify CSS + sembunyikan markup & script dari "View Source"
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = [IO.File]::ReadAllText("$dir\src.html", [Text.Encoding]::UTF8)

$head = [regex]::Match($src, '(?s)^.*?</head>').Value
$body = [regex]::Match($src, '(?s)<body>(.*?)<script>').Groups[1].Value
$js   = [regex]::Match($src, '(?s)<script>(.*?)</script>').Groups[1].Value

# minify CSS di head
$head = [regex]::Replace($head, '(?s)<style>(.*?)</style>', {
  param($m)
  $c = $m.Groups[1].Value
  $c = [regex]::Replace($c, '\s*\n\s*', '')
  $c = [regex]::Replace($c, '\s*([{};,>])\s*', '$1')
  '<style>' + $c + '</style>'
})
$head = [regex]::Replace($head, '>\s+<', '><')

# hapus komentar & whitespace di markup body
$body = [regex]::Replace($body, '(?s)<!--.*?-->', '')
$body = [regex]::Replace($body, '>\s+<', '><').Trim()
# hapus komentar JS lalu rapatkan baris
$js = [regex]::Replace($js, '(?m)^\s*//.*$', '')
$js = [regex]::Replace($js, '/\*.*?\*/', '')
$js = [regex]::Replace($js, '\s*\n\s*', "`n").Trim()

function B64($s){ [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s)) }
$hb = B64 $body
$hj = B64 $js

$loader = "<script>(function(a,b){var u=function(s){return decodeURIComponent(escape(atob(s)))};document.body.innerHTML=u(a);new Function(u(b))()})('$hb','$hj')</script>"
$out = $head + '<body>' + $loader + '<noscript>Aktifkan JavaScript untuk melihat halaman ini.</noscript></body></html>'
[IO.File]::WriteAllText("$dir\index.html", $out, (New-Object Text.UTF8Encoding $false))
"index.html: {0:N1} KB" -f ((Get-Item "$dir\index.html").Length/1KB)
