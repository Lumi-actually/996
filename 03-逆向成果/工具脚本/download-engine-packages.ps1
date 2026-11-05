# download-engine-packages.ps1
# 从 996 引擎官方接口拉取多端引擎包（服务端 + 各端客户端）。
#
# 来源：996m2.com 前端调用的 managerapi 接口，非猜测地址：
#   GET https://managerapi.dhsf.xqhuyu.com/api/WebsiteLog/getEngine
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File download-engine-packages.ps1
#   powershell -ExecutionPolicy Bypass -File download-engine-packages.ps1 -OutDir D:\x -Skip client-pc
#
# 特性：curl 断点续传（-C -）、失败重试、按 Content-Length 校验大小、SHA-256 落盘到 manifest.json。

[CmdletBinding()]
param(
    [string]$OutDir = 'D:\project\新建文件夹\mingyang-mobile\downloads\996-engine',
    [string[]]$Skip = @(),
    [string]$Api = 'https://managerapi.dhsf.xqhuyu.com/api/WebsiteLog/getEngine'
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# 目标：多端版（type=1）是唯一同时含 Windows 服务端与安卓客户端的线
$targets = @(
    @{ name = 'engine-multiplatform'; url = 'https://996box-static.oss-accelerate.aliyuncs.com/offical/static/app/1779353415000_4FARj.zip'; file = 'engine-multiplatform.zip'; desc = '996传奇引擎多端版 引擎下载 181MB' }
    @{ name = 'version-pack';       url = 'https://996box-static.oss-accelerate.aliyuncs.com/offical/static/app/1754556555000_Jfxzk.zip';   file = 'version-pack.zip';       desc = '996传奇引擎多端版 版本下载 256MB' }
    @{ name = 'client-android';     url = 'https://static.dhsf.huiyuehz.com/Package/promote/57e449b0ec916028fb7912ea6299e8b0.apk?v=1755227736'; file = 'client-android.apk';     desc = '996 安卓客户端 139MB' }
    @{ name = 'client-pc';          url = 'https://996box-static.oss-accelerate.aliyuncs.com/offical/static/app/1753782511000_85F6K.rar';   file = 'client-pc.rar';          desc = '996 多端 PC 客户端 124MB' }
    @{ name = 'hub';                url = 'https://996box-static.oss-accelerate.aliyuncs.com/offical/static/app/1779353368000_zemTE.zip';   file = 'hub.zip';                desc = '996 HUB 6.8MB' }
)

# 先把官方接口的原始清单存一份，作为来源凭据
try {
    $h = @{ 'User-Agent' = 'Mozilla/5.0 Chrome/120'; 'Referer' = 'https://www.996m2.com/' }
    $raw = (Invoke-WebRequest -Uri $Api -Headers $h -UseBasicParsing -TimeoutSec 25).Content
    [IO.File]::WriteAllText((Join-Path $OutDir 'engine-list.json'), $raw, [Text.UTF8Encoding]::new($false))
    Write-Host "[api] 引擎清单已保存 engine-list.json"
} catch {
    Write-Warning "[api] 清单接口失败（不影响下载）：$($_.Exception.Message)"
}

$manifest = @()
foreach ($t in $targets) {
    if ($Skip -contains $t.name) { Write-Host "[skip] $($t.name)"; continue }
    $dest = Join-Path $OutDir $t.file
    Write-Host ""
    Write-Host "[get ] $($t.desc)"
    Write-Host "       → $dest"

    # -C - 断点续传；--retry 断流重试；先取 Content-Length 做断言
    $head = & curl.exe -sI --max-time 25 $t.url 2>$null
    $expect = $null
    foreach ($line in $head) {
        if ($line -match '(?i)^content-length:\s*(\d+)') { $expect = [int64]$Matches[1]; break }
    }
    if ($expect) { Write-Host ("       期望 {0:N0} 字节" -f $expect) }

    & curl.exe -L -C - --retry 5 --retry-delay 3 --retry-all-errors `
        --connect-timeout 20 --max-time 3600 -sS -o $dest $t.url
    $curlExit = $LASTEXITCODE

    if (-not (Test-Path $dest)) {
        Write-Warning "       下载失败（curl exit $curlExit），跳过"
        continue
    }
    $size = (Get-Item $dest).Length
    $sha = (Get-FileHash -Path $dest -Algorithm SHA256).Hash
    $ok = (-not $expect) -or ($size -eq $expect)
    Write-Host ("       实际 {0:N0} 字节  {1}  sha256={2}" -f $size, ($(if ($ok) { '大小匹配' } else { '大小不符!' })), $sha)

    $manifest += [pscustomobject]@{
        name   = $t.name
        desc   = $t.desc
        url    = $t.url
        file   = $t.file
        bytes  = $size
        expect = $expect
        sizeOk = $ok
        sha256 = $sha
        curlExit = $curlExit
    }
}

$manifestPath = Join-Path $OutDir 'manifest.json'
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8
Write-Host ""
Write-Host "清单已写入：$manifestPath"
$manifest | Format-Table name, @{n='MB';e={[math]::Round($_.bytes/1MB,1)}}, sizeOk -AutoSize
