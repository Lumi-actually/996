# phone-keygrab.ps1
#
# 在真机上安装带 Frida Gadget 的客户端，抓取 XXTEA 密钥。
# 用法（管理员或普通 PowerShell 均可）：
#     powershell -ExecutionPolicy Bypass -File .\phone-keygrab.ps1
#
# 前提：
#   1. 手机已开启「开发者选项 → USB 调试」，并在弹窗里点「允许」授权本电脑
#   2. 用数据线连上电脑
#
# 注意：安装的是重新签名的包，与原版签名冲突，脚本会先卸载原版（会清掉该应用本地数据）。

$ErrorActionPreference = 'Stop'

$adb    = 'D:\asdk\sdk\platform-tools\adb.exe'
$apk    = 'D:\asdk\repack\client-gadget-v2.apk'
$pkg    = 'com.fgcq.a143097'
$act    = 'org.cocos2dx.cpp.AppActivity'
$keyTxt = "/sdcard/Android/data/$pkg/files/996key.txt"

if (-not (Test-Path $adb)) { throw "找不到 adb：$adb" }
if (-not (Test-Path $apk)) { throw "找不到 APK：$apk" }

Write-Host '=== 1. 检查设备 ===' -ForegroundColor Cyan
& $adb start-server | Out-Null
$devices = & $adb devices
$devices | ForEach-Object { Write-Host "  $_" }
$online = $devices | Where-Object { $_ -match '\sdevice\s*$' }
if (-not $online) {
    Write-Host ''
    Write-Host '没有检测到已授权的设备。请检查：' -ForegroundColor Yellow
    Write-Host '  · 手机是否弹出「允许 USB 调试」并点了允许（没弹就拔插一次）'
    Write-Host '  · 开发者选项里的 USB 调试是否真的打开'
    Write-Host '  · 数据线是数据线，不是纯充电线'
    Write-Host '  · 状态是 unauthorized 时，手机上重新授权后重跑本脚本'
    exit 1
}

$model = (& $adb shell getprop ro.product.model) -join ''
$abi   = (& $adb shell getprop ro.product.cpu.abi) -join ''
$rel   = (& $adb shell getprop ro.build.version.release) -join ''
Write-Host ("  机型={0}  Android={1}  ABI={2}" -f $model.Trim(), $rel.Trim(), $abi.Trim())
if ($abi -notmatch 'arm64') {
    Write-Host '  警告：这台设备不是 arm64，gadget 只放了 arm64-v8a，可能加载失败。' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '=== 2. 卸载原版（签名冲突，必须） ===' -ForegroundColor Cyan
& $adb uninstall $pkg 2>&1 | ForEach-Object { Write-Host "  $_" }

Write-Host ''
Write-Host '=== 3. 安装 patched 包（约 147 MB，可能要 1-3 分钟） ===' -ForegroundColor Cyan
$sw = [Diagnostics.Stopwatch]::StartNew()
& $adb install -r $apk 2>&1 | ForEach-Object { Write-Host "  $_" }
$sw.Stop()
Write-Host ("  耗时 {0:N0} 秒" -f $sw.Elapsed.TotalSeconds)

Write-Host ''
Write-Host '=== 4. 清日志并启动客户端 ===' -ForegroundColor Cyan
& $adb logcat -c 2>$null
& $adb shell am start -n "$pkg/$act" 2>&1 | ForEach-Object { Write-Host "  $_" }

Write-Host ''
Write-Host '=== 5. 抓 FRIDA996 日志（30 秒） ===' -ForegroundColor Cyan
$logFile = Join-Path (Get-Location) 'phone-frida996.log'
$job = Start-Job -ScriptBlock {
    param($adb, $pkg)
    & $adb logcat -v time 2>&1 | Where-Object { $_ -match 'FRIDA996|frida|gadget|UnsatisfiedLink|FATAL' }
} -ArgumentList $adb, $pkg
Start-Sleep -Seconds 30
$lines = Receive-Job $job
Stop-Job $job; Remove-Job $job -Force
$lines | Out-File -FilePath $logFile -Encoding utf8
$lines | Select-Object -First 60 | ForEach-Object { Write-Host "  $_" }

Write-Host ''
Write-Host '=== 6. 尝试拉取密钥文件 ===' -ForegroundColor Cyan
& $adb pull $keyTxt 'D:\asdk\996key.txt' 2>&1 | ForEach-Object { Write-Host "  $_" }
if (Test-Path 'D:\asdk\996key.txt') {
    Write-Host '  密钥文件内容：' -ForegroundColor Green
    Get-Content 'D:\asdk\996key.txt' | ForEach-Object { Write-Host "    $_" }
}

Write-Host ''
Write-Host '=== 结果 ===' -ForegroundColor Cyan
$keys = $lines | Select-String -Pattern 'FRIDA996 KEY'
if ($keys) {
    Write-Host '抓到密钥了：' -ForegroundColor Green
    $keys | ForEach-Object { Write-Host "  $_" }
    Write-Host ''
    Write-Host '下一步执行：'
    Write-Host '  python tools\xxtea-decrypt-all.py --key-hex <上面的32位十六进制> --out D:\asdk\lua-decrypted'
} else {
    Write-Host '没抓到 FRIDA996 日志。把下面这个文件发给我：' -ForegroundColor Yellow
    Write-Host "  $logFile"
    Write-Host '我再判断是 gadget 没加载、被反调试拦了，还是需要换注入点。'
}
