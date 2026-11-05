# patch-hosts.ps1
# 把 996 授权 / 回源域名指向本机，供本地 mock 授权服务使用。
#
# 用法：
#   pwsh -File patch-hosts.ps1 -Domains proxyapp.dhsf.xqhuyu.com,box.996m2.com
#   pwsh -File patch-hosts.ps1 -Restore
#   pwsh -File patch-hosts.ps1 -List
#
# 行为：
#   - 写入前把当前 hosts 备份到同目录 hosts.backup-<时间戳>
#   - 只增删带 "# [996-local]" 标记的行，不动你原有的 hosts 内容
#   - 需要管理员权限（hosts 在 System32\drivers\etc 下）
#
# 注意：域名只是示例。实际域名必须从你自己的抓包里取，别照抄。

[CmdletBinding(DefaultParameterSetName = 'Apply')]
param(
    [Parameter(ParameterSetName = 'Apply', Mandatory = $true)]
    [string[]]$Domains,

    [Parameter(ParameterSetName = 'Apply')]
    [string]$Target = '127.0.0.1',

    [Parameter(ParameterSetName = 'Restore', Mandatory = $true)]
    [switch]$Restore,

    [Parameter(ParameterSetName = 'List', Mandatory = $true)]
    [switch]$List
)

$ErrorActionPreference = 'Stop'
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$marker = '# [996-local]'

if (-not (Test-Path $hostsPath)) { throw "找不到 hosts 文件：$hostsPath" }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

$lines = Get-Content -Path $hostsPath -Encoding ASCII

if ($List) {
    $marked = $lines | Where-Object { $_ -like "*$marker*" }
    if ($marked) { $marked | ForEach-Object { Write-Output $_ } } else { Write-Output '（当前没有 996-local 条目）' }
    return
}

if (-not $isAdmin) { throw '修改 hosts 需要管理员权限，请用管理员身份打开终端后重跑。' }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $PSScriptRoot "hosts.backup-$stamp"
Copy-Item -Path $hostsPath -Destination $backup -Force
Write-Output "已备份 hosts → $backup"

# 先清掉旧标记行
$kept = $lines | Where-Object { $_ -notlike "*$marker*" }

if ($Restore) {
    $kept | Set-Content -Path $hostsPath -Encoding ASCII
    Write-Output "已移除全部 996-local 条目（共 $($lines.Count - $kept.Count) 行）。"
    return
}

$newLines = New-Object System.Collections.Generic.List[string]
foreach ($d in $Domains) {
    $clean = $d.Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) { continue }
    $newLines.Add(("{0}`t{1}	{2}" -f $Target, $clean, $marker))
    Write-Output "指向本机：$clean → $Target"
}

$out = @($kept) + @($newLines)
$out | Set-Content -Path $hostsPath -Encoding ASCII

Write-Output ""
Write-Output "已写入 hosts。验证："
Write-Output "  Resolve-DnsName <域名>"
Write-Output "  ipconfig /flushdns"
Write-Output "还原命令："
Write-Output "  pwsh -File `"$PSCommandPath`" -Restore"
