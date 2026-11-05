# find-auth-strings.ps1
# 三编码（GBK / UTF-8 / UTF-16LE）字符串定位器，用于在加壳/未加壳的客户端与服务端二进制里
# 找授权、到期、机器码、购买、未开通一类关键词的位置。
#
# 用法：
#   pwsh -File find-auth-strings.ps1 -Root "C:\996M2-lua"
#   pwsh -File find-auth-strings.ps1 -Root "D:\apk\out" -Patterns 授权,过期,license -MaxHits 5 -Json out.json
#
# 说明：
#   - 不做逐字节匹配（9MB 文件会跑到天荒地老），改用"整文件按编码解码 + IndexOf"，毫秒级。
#   - 命中偏移是该编码下的字符下标，不是文件字节偏移；用来回查上下文足够，不要当 RVA 用。
#   - 高熵（加壳）文件几乎不会有明文命中；熵值请用 REA 的 inspect_byte_entropy 单独测。

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [string[]]$Patterns = @(
        '授权', '过期', '到期', '试用', '注册码', '机器码', '序列号', '验证失败',
        '未开通', '购买', '充值', 'vip', 'VIP',
        'license', 'License', 'LICENSE', 'expire', 'Expire', 'trial', 'Trial',
        'auth', 'Auth', 'serial', 'activat', 'unauthor'
    ),

    [string[]]$Include = @('*.exe', '*.dll', '*.drv', '*.ocx', '*.so', '*.dex', '*.js', '*.json', '*.ini', '*.txt', '*.lua', '*.dat', '*.key'),

    [int]$MaxFileMB = 64,
    [int]$MaxHits = 8,
    [int]$ContextChars = 40,
    [switch]$Utf16,
    [string]$Json
)

$ErrorActionPreference = 'Stop'
$limitBytes = $MaxFileMB * 1MB

function Get-EncodingSet {
    param([switch]$WithUtf16)
    $set = [ordered]@{
        GBK  = [System.Text.Encoding]::GetEncoding(936)
        UTF8 = New-Object System.Text.UTF8Encoding($false, $false)
    }
    if ($WithUtf16) {
        $set['UTF16LE'] = [System.Text.Encoding]::Unicode
        $set['UTF16BE'] = [System.Text.Encoding]::BigEndianUnicode
    }
    return $set
}

function Clean-Fragment {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $t = $Text -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', '.'
    $t = $t -replace '\s+', ' '
    return $t.Trim()
}

$encodings = Get-EncodingSet -WithUtf16:$Utf16
$files = Get-ChildItem -Path $Root -Recurse -File -Include $Include -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 0 -and $_.Length -le $limitBytes }

$results = New-Object System.Collections.Generic.List[object]
$scanned = 0
$skipped = 0

foreach ($f in $files) {
    $scanned++
    try {
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    }
    catch {
        $skipped++
        Write-Warning "读取失败，跳过：$($f.FullName) — $($_.Exception.Message)"
        continue
    }

    $fileHits = New-Object System.Collections.Generic.List[object]

    foreach ($encName in $encodings.Keys) {
        $enc = $encodings[$encName]
        try {
            $text = $enc.GetString($bytes)
        }
        catch { continue }

        foreach ($p in $Patterns) {
            $start = 0
            $count = 0
            while ($count -lt $MaxHits) {
                $idx = $text.IndexOf($p, $start, [System.StringComparison]::Ordinal)
                if ($idx -lt 0) { break }
                $from = [Math]::Max(0, $idx - $ContextChars)
                $len = [Math]::Min($ContextChars * 2, $text.Length - $from)
                $fileHits.Add([pscustomobject]@{
                        File    = $f.FullName
                        Size    = $f.Length
                        Encoding= $encName
                        Pattern = $p
                        Offset  = $idx
                        Context = (Clean-Fragment $text.Substring($from, $len))
                    })
                $start = $idx + $p.Length
                $count++
            }
        }
    }

    if ($fileHits.Count -gt 0) {
        Write-Output ""
        Write-Output ("=== {0}  ({1:N0} bytes) ===" -f $f.FullName, $f.Length)
        foreach ($h in $fileHits) {
            Write-Output ("  [{0,-7}] {1,-12} @{2,10}  {3}" -f $h.Encoding, $h.Pattern, $h.Offset, $h.Context)
            $results.Add($h)
        }
    }
}

Write-Output ""
Write-Output ("扫描文件 {0} 个（跳过 {1}），命中 {2} 条。" -f $scanned, $skipped, $results.Count)

if ($Json) {
    $results | ConvertTo-Json -Depth 4 | Set-Content -Path $Json -Encoding UTF8
    Write-Output "命中明细已写入：$Json"
}
