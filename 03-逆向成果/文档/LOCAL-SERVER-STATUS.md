# 996 引擎本地服 — 运行状态与重启手册

最后更新：2026-11-04 21:50（Asia/Shanghai）

---

## 1. 架构（实测确认）

```
Android 模拟器 emulator-5554 (Android 11, x86_64 + ARM 转译)
   │
   │  客户端 com.fgcq.a143097 (热血演示版 4.7.2)
   │    ├─ HTTP(80)  modlist/srvlist  → 走 8888 透明代理 → 官方主机
   │    └─ TCP(8081) 游戏网关          → iptables DNAT 改写
   ▼
10.0.2.2 (Windows 主机回环)
   ├─ 7000  LoginGate.exe
   ├─ 7110  RunGate.exe
   ├─ 7201  DBServer.exe  (Gate)
   ├─ 7301  DBServer.exe  (Session)
   ├─ 7400  M2Server.exe  (IOCP / RunGate 接入)
   ├─ 8400  M2Server.exe  (DGate / DBServer 接入)
   ▼
WSL2 Ubuntu 26.04 ── SQL Server 2022 (sa / 996Mir@2026 / 库 box, 39 张表)
```

服务端全部组件是 **Windows PE x86-64**，必须跑在 Windows 主机，不能跑在 WSL 里。
SQL Server 必须跑在 **WSL 里**（Windows 侧无管理员权限装不了），因此 Windows 进程通过
WSL vNIC 地址（如 `172.25.150.14`）连库。**该地址在 WSL 重启后会变。**

---

## 2. 当前已验证可用的状态

| 项 | 值 / 状态 |
|---|---|
| SQL Server | `Microsoft SQL Server 2022 (RTM-CU27-GDR) 16.0.4305.5`，Developer Edition |
| 数据库 | `box`，39 张表，导入 0 错误 |
| SA 密码 | `996Mir@2026` |
| WSL IP | `172.25.150.14`（会变） |
| 服务端目录 | `working/996-local/server/version/新3端纯净版/服务端/MirServer` |
| M2Server 内存 | ~1045 MB（世界加载完成；作者基准 1016 MB） |
| 六个端口 | 7000/7110/7201/7301/7400/8400 全部 LISTENING |
| DNAT 规则 | `tcp dport 8081 → 10.0.2.2:7000`，已实测跳转到 LoginGate |
| 模组代理 | `tools/modlist-proxy.py` 监听 8888，转发官方 modlist 主机 |
| 客户端登录 | `zq996b` 成功，`userName 1757008192` |
| 实名认证 | 已绕过，`ageStatus1` / `isCertification=true` |
| modlist 签名墙 | 已绕过（代理返回官方原始字节，非伪造） |
| 游戏场景 | 已进入（返回键弹「确定退出游戏吗」） |

---

## 3. 关键配置文件（已改动的）

`MirServer\DBServer\dbsrc.ini`
```ini
ServerPath=D:\project\新建文件夹\mingyang-mobile\working\996-local\server\version\新3端纯净版\服务端\MirServer\DBServer\
[DBSetup]
HeroDBName=box
SQLIP=172.25.150.14      # 原为 47.99.99.32
SQLUSERNAME=sa            # 原为 996m2
SQLPASSWORD=996Mir@2026
SQLPORT=1433
LogDir=D:\...\MirServer\DBServer\\Log\
```

`MirServer\Mir200\Setup.json`（单行 JSON）
```json
{"DGate-Service":{"DataPort":8400,"DataIpaddr":"0.0.0.0","Help":"DB"},
 "Ssid-Service":{"SSIDPort":7301,"SSIDIpaddr":"127.0.0.1","Help":"LoginSvr"},
 "Server":{"ServerName":1881,"ServerId":100,"plateformid":1881,"KuafuServer":0},
 "M2DB-Config":{"M2DBUser":"sa","M2DBPort":1433,"M2DBName":"box",
                "M2DBIpaddr":"172.25.150.14","M2DBPsw":"996Mir@2026"},
 "Iocp-Service":{"IOCPPort":7400,"IOCPIpaddr":"0.0.0.0"}}
```

`MirServer\RunGate\RunGate.ini` — **RunGate 实际读的是这个文件，不是 config.ini**
```ini
[RunGate]
GateAddr=127.0.0.1
GatePort=7110
ServerAddr=127.0.0.1
ServerPort=7400
IpCount=500
ConnectOutTime=2
OpenSSL=0
```

`MirServer\LoginGate\Config.ini` — `GatePort=7000`、`ServerAddr=127.0.0.1`、`ServerPort=7201`

---

## 4. 启动顺序与命令

### 4.1 WSL 侧（SQL Server）

```powershell
# 保活（WSL 空闲会挂起，导致 DB 断连 → DBServer 初始化失败）
# 长期跑一个后台任务，每 10s 探一次 1433
```

```bash
wsl -d Ubuntu -u root -- bash -lc "systemctl start mssql-server; ss -tlnp | grep 1433"
```

### 4.2 Windows 侧（必须用 WMI 启动，否则进程随工具调用被回收）

```powershell
$R='D:\project\新建文件夹\mingyang-mobile\working\996-local\server\version\新3端纯净版\服务端\MirServer'
function Launch($exe,$wd){
  (Invoke-CimMethod -ClassName Win32_Process -MethodName Create `
     -Arguments @{ CommandLine="`"$exe`""; CurrentDirectory=$wd }).ProcessId
}
Launch "$R\DBServer\DBServer.exe" "$R\DBServer"     # 等 12s，应看到 7201 + 7301
Launch "$R\Mir200\M2Server.exe"  "$R\Mir200"        # 等 20~60s，应看到 8400，随后 7400
Launch "$R\RunGate\RunGate.exe"  "$R\RunGate"       # 7110
Launch "$R\LoginGate\LoginGate.exe" "$R\LoginGate"  # 7000
```

判定成功的标志：
- DBServer 窗口日志出现 `172.25.150.14 - box SQL数据库[1]连接成功..`、`会话服务启动完成[7301]`、`GatePort 7201 ok`
- M2Server 窗口出现 `DBManager服务启动完成[8400]`，内存涨到 ~1000 MB

### 4.3 模拟器侧

```powershell
$env:ANDROID_AVD_HOME='D:\asdk\avd'          # 必须设，否则 -list-avds 为空
D:\asdk\sdk\emulator\emulator.exe -avd cq30 -no-snapshot-load -no-boot-anim
adb root
adb shell "iptables -t nat -A OUTPUT -p tcp --dport 8081 -j DNAT --to-destination 10.0.2.2:7000"
adb shell "nohup /data/local/tmp/frida-server16 -l 0.0.0.0 >/data/local/tmp/frida.log 2>&1 &"
```

启动客户端必须走 frida spawn（直接 `am start` 会 `overflowed sigaltstack` 启动失败）：

```powershell
$py='C:\Users\28531\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe'
$T='...\working\996-local\tools'
& $py "$T\frida-run.py" --package com.fgcq.a143097 --script "$T\frida-noop.js"     --seconds 1500 --out "$T\frida-noop.log"
# 20s 后
& $py "$T\frida-run.py" --package com.fgcq.a143097 --attach --script "$T\frida-996-age-hooks.js" --seconds 1500 --out "$T\frida-age.log"
```

---

## 5. 踩过的坑（避免重走）

| 现象 | 真因 | 处理 |
|---|---|---|
| `SQL Server 不存在或访问被拒绝`（DBNETLIB） | Windows 侧用古董 ODBC 驱动 `SQLSRV32.dll`；WSL 空闲挂起导致 1433 不可达 | 保活 WSL；驱动本身可用，不必替换 |
| DBServer 只开 7201 不开 7301 | DB 失败后 `uThread_SysVarDB` 日志线程访问违例，初始化半途终止 | 干净重启进程 |
| `LuaFunc/LuaCond 加载失败 Code=-1` | 包内本就没有该脚本，**非故障** | 忽略 |
| `Log Socket Err:10049` | 作者成功日志里同样存在，日志 socket 噪声 | 忽略 |
| M2Server 卡在 517 MB、7400/8400 不开 | DB/会话未通，世界初始化停摆 | DB 通了之后自涨到 1045 MB |
| 进程活不过一次工具调用 | 随工具调用进程树被回收 | 用 WMI `Win32_Process.Create` 启动 |
| `mssql-server.deb` 报 `lzma error` | aria2 续传预分配了文件长度但未完成，`.aria2` 控制文件仍在 | 续传补完并校验 SHA-256 |
| `liblber-2.5.so.0` 缺失 / `OPENLDAP_2.5 not found` | Ubuntu 26.04 是 OpenLDAP 2.6，版本符号节点不同，软链接无效 | 取 jammy 的 `libldap-2.5-0` 放进 `/opt/mssql/lib/`（在其 RUNPATH 内） |
| GameCenter 弹「启动失败」 | 它自己走 ADODB 连库，与 DBServer 的 ODBC 不同路；当时 WSL 断 | 放弃 GUI 编排，手工按序拉起 |
| 客户端 `am start` 起不来 | `overflowed sigaltstack`（ARM 转译层） | 必须 frida spawn 暂停进程启动 |
| Lua `connect` 钩子完全无效 | 客户端网络跑在 Frida 注入不了的进程（子进程 attach 直接 signal 11） | 改用 iptables DNAT，内核级、与进程无关 |
| 改 `ResServerlist.txt_212342` 被还原 | 客户端会重新拉取并覆盖缓存 | 不要依赖改缓存文件 |

---

## 6. 当前唯一阻塞点（客户端）

登录成功后，客户端进入游戏场景但停在 996M2 加载页：

```
[LUA-print] paramJson.sdata: nil
[LUA-print] Http Request Code:0
[LUA-print] request roleinfo error: step 1, http callback！ failed
```

- `Http Request Code:0` 在 144 ms 内返回，且**网络钩子记录到零次 `connect`/`getaddrinfo`**
  → URL 在构造时就是非法的，源头是 `sdata` 为空
- 44 个启动器 Lua（`files/mod_launcher/stab/scripts/logic/`，明文）中**没有** `roleinfo`/`sdata`
- 整个 APK（14054 条目）里也搜不到 `request roleinfo` 字面量，只有 Java 符号 `setRoleInfo`
  （`classes2.dex`、`classes3.dex`）
- 结论：该逻辑用运行时拼串生成，且游戏主 Lua 不在设备上（尚未下载/在加密包内）

### 已排除的假设（不要重复走）

- **`setRoleInfo` 与本题无关**：它是网易易盾反外挂的符号，
  归属 `com.xqhy.security.SDKSecurityManager` 与 `com.netease.htprotect.HTProtect`，
  与 roleinfo 的 HTTP 请求没有关系
- **启动器 Lua 里没有这段逻辑**：APK 内 `assets/mod_launcher/` 共 52 个 `.lua`、
  设备上热更后 44 个 `.lua`，全部 grep 过 `paramJson`/`sdata`/`roleinfo`/`SDKLoginCallback`，零命中

### 硬约束：Frida 无法 hook 客户机 ARM64 代码

应用跑在 `libndk_translation` 的 ARM64 转译环境里：

- `Process.findModuleByName('libMyGame.so')` 返回 null（模块不在宿主 linker 命名空间）
- 所有针对宿主 `libc` 的 `connect`/`getaddrinfo` 钩子对该客户端完全无效
  （ARM 代码走的是客户机侧 bionic，直接系统调用）
- 直连子进程（如 pid 7205）会让 frida loader 段错误（signal 11）

**但 Frida 仍可读写宿主进程内存**，这条可用：`tools/frida-996-mem-scan.js`
扫描 `rw-` 区间找明文标记并 dump 周边字节。已成功命中：

```
paramJson.sdata: nil
Http Request Code:0
xsdc_212342_roleinfoNew1757008192      # roleinfo 结果的本地缓存键（前缀取自 srvRoot）
{"deviceRotation":1}
```

### 游戏 Lua 是加密的（这是当前真正的技术阻塞）

- APK 内 `assets/mod_fgcq/stab/scripts/` 有 **1719 个 `.lua`**，全部为同一格式：
  `58 64 76 46 54 67 64 35 59 41`（ASCII `XdvFTgd5YA`，10 字节 sign）+ XXTEA 密文
- `libMyGame.so`（ARM64，21.8 MB）导出 `luaL_loadbuffer`/`luaL_loadbufferx`/`luaL_loadstring`，
  含 `xxtea`/`XXTEA` 符号，但**不含** `roleinfo`/`sdata` 明文
- `assets/{arm64-v8a,armeabi-v7a,x86,x86_64}/vfs.dat`（4.1~4.5 MB）完全加密，无任何明文
- **密钥未取到**：`docs/frida-996-key.log` 为 0 字节（那次 dump 也是被转译层挡住的）

### 密钥回收：已用 `.dynsym` + capstone 把算法完全对齐，但候选全部失败

`.dynsym` 有 39,898 个导出符号，XXTEA 相关全部可定位：

```
xxtea_decrypt                       @ 0xdc9cc4   （包装：keylen≤15 时补零到 16 字节）
worker（真正实现）                  @ 0xdc9d90
  sum = DELTA * (6 + 52/words)      DELTA=0x9E3779B9，其 6 倍=0xB54CDA56 ✓
  字节↔字：小端；words = ceil(len/4)；末字补零
cocos2d::FileUtils::addXXTEAKeyAndSign      @ 0xd18e84
                        ...V2 / V3 / V4     @ 0xd190b0 / 0xd192dc / 0xd19670
LuaBridgeCtl::SetXXTEAKeyGM(std::string)    @ 0x723abc
  └ 与硬编码 sign 配对："W]GuV|i"(8) / "F#W]GuV|i"(9)
LuaBridgeCtl::initXXTeaAndLookups           @ 0x72202c
  └ 引用 4 个 10 字符串（疑似 V1–V4 的 sign）：
    '#$EVH]wd{j'  'QvnHJr3kl6'  'gFDh#tD !z'  'HtfVDwt%IQ'
```

算法实现已与二进制逐条对齐，**解密器本身没有问题**；问题在密钥形态。已穷举：

| 候选来源 | 数量 | 结果 |
|---|---|---|
| `.so` 内全部 16 字节可打印窗口 | 551,507 | 全败 |
| sign 常量 ±2 KB 内 16 字节窗口 | 8,357 | 全败 |
| 只读区可疑串的「短串+补零」形态 | 1,031 | 全败 |
| sign 常量 ±32 KB 内 16 字节窗口 | 65,521 | 全败 |
| 进程堆全部可打印 16 字节串（扫 3.19 GB） | 473,585 | 全败 |
| 堆可打印串 + 「短串+补零」形态（扫 2.91 GB） | 600,007 | 全败 |

**验证器经验（重要）**：不能用「前缀若干字节可打印」当判据——60 万候选里会稳定冒出约 5~6 个假阳性。
正确判据是 `\x1bLua` 字节码魔数（资源若为预编译字节码）或完整 Lua 源码语法特征。

### 已备好但当前环境跑不动的能力

- `tools/frida-996-mem-scan.js` / `frida-996-sign-scan.js` / `frida-996-wide-scan.js`：
  扫宿主进程内存找明文标记并 dump（已验证有效，命中 `paramJson.sdata`、
  `xsdc_212342_roleinfoNew<uid>`、sign 常量等）
- `tools/frida-996-keyheap.js`：O(n) 采集堆内全部可打印 16 字节串与「短串+补零」形态
  （实测扫完 3 GB 内存仅需数十秒）
- `tools/so-keyhunt.py`：capstone 驱动的只读引用解析（adrp+add / ldr 指针 → 字符串）
- `tools/xxtea-key-recover.py`：XXTEA 解密 + 候选遍历框架

### Ghidra 静态反编译成果（2026-11-04 夜）

> 安装：`D:\asdk\ghidra_12.1.4_PUBLIC`（需 JDK 21 → 已装 `D:\asdk\jdk-21.0.13+9`）
> 项目：`D:\asdk\ghproj\MirGame`（分析完成，384 秒）
> 输出：`D:\asdk\ghidra-out\decomp.txt`（7 个函数的 C 代码，56 KB）
> 脚本：`D:\asdk\ghscripts\DecompTargets.java`

**一、字符串混淆方案完全破解**

```c
// initXXTeaAndLookups 内：每个字面量都是 push_back(src[i] ^ xorKey)
// xorKey 是全局数据符号 vaddr=0x14bc020，初始值 0x10 (16)
```

按 XOR 0x10 解出四个 10 字符串：

| 混淆串 | 解码后 |
|---|---|
| `#$EVH]wd{j` | `34UFXMgtkz` |
| `QvnHJr3kl6` | `Af~XZb#{|&` |
| `gFDh#tD !z` | `wVTx3dT01j` |
| `HtfVDwt%IQ` | **`XdvFTgd5YA`** ← mod 资源的 sign |

第四个正好等于 `assets/mod_fgcq/**/*.lua` 的 10 字节文件头，
**证明这些 Lua 就是由该函数注册的 key/sign 对加密的**。
另有 `"W]GuV|i`→`2GMWeFly`、`F#W]GuV|i`→`V3GMWeFly`、以及 serverlist 用的 `4meJnPyl`。

**二、Lua 侧密钥派生规则**

```c
// LuaBridgeCtl::SetXXTEAKeyGM(std::string input)
key = input + "2Gm" + input;
sign = "\"W]GuV|i"(8B) ；V3 变体用 "F#W]GuV|i"(9B)
```

**三、四个 xxtea 变体都是标准 XXTEA**

`xxtea_decrypt` / `_v2` / `_v3` / `_v4` 只是包装，内部 worker 分别在
`0xdc9d90` / `0xdca110` / `0xdca4a8` / `0xdca818`，全部为
`sum = DELTA*(6 + 52/words)`、`DELTA=0x9E3779B9`、字节↔字小端、`words=ceil(len/4)`。
算法无差异，问题只在密钥值。

**四、注册点与调用图（已完整解析）**

```
initXXTeaAndLookups:  addXXTEAKeyAndSign   V1   (两对)
                      addXXTEAKeyAndSignV2       call @ 0x8226d0
                      addXXTEAKeyAndSignV4       call @ 0x8229c0
SetXXTEAKeyGM:        addXXTEAKeyAndSignV3       call @ 0x8240d0
```

`LuaBridgeCtl::SetXXTEAKeyGM(std::string)` 的**真实调用者只有一个**：
`lua_mmorpg_lua_bridge_ctl_LuaBridgeCtl_SetXXTEAKeyGM`（@ `0x8360d8`，Lua 绑定）。
即密钥字符串来自 Lua 运行时，而不是 C++ 里的字面量。

**五、四个 xxtea 变体是同一份实现**

v1 worker（`0xdc9d90`）与 v4 worker（`0xdca818`）**76 条指令逐条完全相同**
（归一化立即数后 diff 差异数 = 0）。算法问题可以彻底排除。

**仍未解决**：`XdvFTgd5YA` 配对的 key 具体值。已排除的候选：

- init 函数内全部 79 个十六进制立即数还原串（330 组合）
- `.so` 全量可打印串 + XOR 0x10 变换（11.4 万组合）
- 进程堆内全部可打印 16 字节串与短串补零形态（107 万组合）
- mod 标识按 `input+"2Gm"+input` 规则派生（122 组合）

**下一步**：写 Ghidra 脚本对 `0x8229c0`（V4 注册点）的两个 `std::string` 参数做
栈槽回溯，还原其真实内容；或在 `xxtea_decrypt` 入口下运行时断点读 `x2`。

**确证：读取路径与密钥用法（`FileUtils::getDataFromFile` @ `0xe0b53c`）**

```c
for (pair : fileUtils->_xxteaKeyAndSign) {
    if (strncmp(pair.sign, data, signLen) != 0) continue;
    out = xxtea_decrypt(data + signLen, size - signLen, pair.key, keyLen, &outLen);
}
```

与假设完全一致。**1719 个 mod Lua 全部带 `XdvFTgd5YA` 头，但用四个解码串中的任意一个作 key 都解不开**
（1719 × 4 全量验证，0 命中）。说明与 `XdvFTgd5YA` 配对的 key 是**运行时拼装**出来的
（类似 `SetXXTEAKeyGM` 里 `key = input + "2Gm" + input` 那种规则），Ghidra 未能化简出该拼装。

**新线索（可能绕开整个 XXTEA 问题）**

设备上 `files/mod_launcher/stab/` 下的启动器脚本是**明文**，且 `mod_launcher_project.manifest`
显示热更资源是**普通 zip**（带 md5/size，例如 `29f680edf8908bcee6f9e5a77d24264b.zip` 94,447 B）。
即热更通道下发未加密压缩包。引擎用的是标准 Cocos `AssetsManagerEx`
（`.so` 里 `project.manifest` / `version.manifest` / `cocos2dx-update-temp-package.zip` 都在），
但 CDN 上按 `resURL + <mod>/<路径>/project.manifest` 探测全部 404 —— 说明 manifest 基址来自运行时配置。

**已恢复的运行时配置（`ResModlist.txt_143097`，2275 B）**

```
resURL  = https://cdn996.dhsf.xqhuyu.com/dhsf/cq2/
resURL2 = https://cdn996.dhsf.huiyuehz.com/dhsf/cq2/
resVer  = ?v=20261104143221
modData[0].subMod[0] = { id: xsdc_212342, game_signkey: 9d2fb256de15cb42149f4ffb1093ae0c,
                         xk: 'ōшěσēξφ♀āèшδτじδずξюě♂', xkDomain: http://server.zqdjy.cn }
```

`game_signkey` 已试过 hex16 / ASCII 截断 / 反序 / `+"2Gm"+` 变体，**不是 XXTEA 密钥**。

**Java 层注入实验（2026-11-05 凌晨）**

目标：在 Java→C++ 的桥接处给登录回调 payload 注入 `sdata`，绕开 XXTEA。

| 方法 | 能否 hook |
|---|---|
| `AndroidNDKHelper.SendMessageWithParameters(String, JSONObject)` | ❌ `unable to allocate free page(s) near address` |
| `java.lang.StringBuilder.append`（boot 类，作对照） | ❌ 同样错误 |
| `AndroidNDKHelper.SetNDKReceiver` / `ReceiveCppMessage` / `CPPNativeCallHandler` | ✅ |
| `SDKLoginManager.login` / `callbackLoginSuccess` / `callbackChangeSuccess` | ✅ |

结论：蹦床页分配失败是**按方法**发生的，不是全局禁止。

`callbackLoginSuccess` 的唯一参数是 `com.xqhy.login.bean.LoginBean`，该 bean 的 27 个方法里
**没有** `sdata`（只有 userName/token/uid/ageStatus/mobile/userAuth 等）；
`SDKLoginResultBean` 有 81 个方法，含 `getAppParams/setAppParams`（可疑载体）。

**重要再判断**：`paramJson.sdata: nil` 很可能是**正常现象**（新账号没有角色记录），
`request roleinfo error: step 1` 也许只是告警而非阻塞原因。真正的阻塞需要先在
**能跑通的客户端**上对照一次才能确定——这又回到需要一个可调试环境。

### 下一步候选

1. **在真正的 ARM64 调试环境下断点取密钥**（唯一可靠的路）：
   于 `xxtea_decrypt` @ `0xdc9cc4` 或 worker @ `0xdc9d90` 下断点，直接读 `x2` 指向的 16 字节。
   当前 x86_64 模拟器 + libndk_translation 做不到（见上一节硬约束）
2. 客户端数据只有 **7.1 MB**（仅启动器资源），**游戏本体资源从未下载**；
   即便绕过 roleinfo，后续仍需一次大体积资源下载
3. 若只要"能在手机上玩"，可换真机 / arm64 模拟器（Frida 可正常 hook），
   现有 spawn+attach 工具链、Lua dump 钩子、内存扫描脚本都能直接生效

---

## 6.5 arm64 模拟器结论 + 免 root 注入方案（2026-11-05 凌晨）

**arm64 模拟器在 x86_64 主机上不可用（已彻底验证）**

- 已装 `system-images;android-30;google_apis;arm64-v8a`（system.img 3.08 GB），AVD `arm30` 建好
- `emulator.exe` 直接拒绝：`Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host`
- 绕过启动器、直接调 `qemu\windows-x86_64\qemu-system-aarch64.exe` 可以过架构门
  （日志出现 `Target arch = 'arm64'`、`-machine type=ranchu -cpu cortex-a57`、`Starting QEMU main loop`），
  但 QEMU 在宿主侧初始化阶段静默退出，**一条内核日志都没有**（`-show-kernel` 也无输出）
- 补建 `snapshots/default_boot` 目录、给 `qemu\windows-x86_64` 加 `lib`/`lib64` 目录联接后依旧

**改走免 root 路线：frida-gadget 重打包（已完成）**

| 步骤 | 结果 |
|---|---|
| frida-gadget 16.7.19 android-arm64 | `D:\asdk\dl\frida-gadget-16.7.19-android-arm64.so`（24.6 MB） |
| apktool 3.0.3 | `D:\asdk\dl\apktool.jar` |
| 解码原包 | 32,369 文件 / 336 MB → `D:\asdk\repack\src` |
| 注入 | `CQGameApplication.onCreate()` 开头插入 `System.loadLibrary("gadget")` |
| gadget 配置 | `lib/arm64-v8a/libgadget.config.so`：`listen 0.0.0.0:27042, on_load=resume` |
| 重打包 + 签名 | **`D:\asdk\repack\client-gadget.apk`（146.7 MB，v1/v2/v3 签名全部校验通过）** |

**在本机 x86 模拟器上验证的结果**：`libgadget.so` 确实被加载进进程（`/proc/<pid>/maps` 可见），
`ndk_translation: Initialized NDK translation (aarch64)` 也正常，
但 gadget 的 ARM64 运行时在转译环境下无法启动，27042 不监听。
**说明重打包流程本身正确，只差原生 ARM64 环境。**

**v2：改用 gadget 的 script 交互（零时序风险，推荐）**

listen 模式默认 `on_load=wait`，但若配成 `resume` 会在我们连上之前就跑完 `main.lua` 的解密。
所以 v2 改成 script 模式，gadget 在**程序入口点之前**自动加载脚本：

```
lib/arm64-v8a/libgadget.config.so   69 B   {"interaction":{"type":"script","path":"libhook.so"},"runtime":"qjs"}
lib/arm64-v8a/libgadget.so          25.8 MB
lib/arm64-v8a/libhook.so            3.1 KB  ← JS 载荷伪装成 .so（包管理器只解压 lib*.so）
```

`libhook.so` 里挂 `xxtea_decrypt`/`_v2`/`_v3`/`_v4`（偏移 `0xdc9cc4/0xdca044/0xdca3c4/0xdca74c`）
与 `luaL_loadbuffer(0xae0844)`/`luaL_loadbufferx(0xae0790)`，命中时：
- `console.log("FRIDA996 KEY <fn> <hex>")` → 进 logcat
- 同时追加写入 `/sdcard/Android/data/com.fgcq.a143097/files/996key.txt`

成品：**`D:\asdk\repack\client-gadget-v2.apk`（146.7 MB，v1/v2/v3 签名通过）**

**真机上怎么用（v2，无需连客户端）**

```powershell
adb install -r D:\asdk\repack\client-gadget-v2.apk
adb logcat -c
adb shell am start -n com.fgcq.a143097/org.cocos2dx.cpp.AppActivity
adb logcat | Select-String FRIDA996          # 启动瞬间即可看到 KEY
adb pull /sdcard/Android/data/com.fgcq.a143097/files/996key.txt
```

拿到密钥后：

```powershell
python tools\xxtea-decrypt-all.py --key-hex <32位十六进制> --out D:\asdk\lua-decrypted
```

`xxtea-decrypt-all.py` 已验证过：错误密钥时严格报 `0 / 1719`，不会误判。

（listen 模式的 `frida-gadget-run.py` 与 `frida-996-keydump-native.js` 仍保留，
需要在真机上做进一步动态调试时可用。）

---

## 6.6 真机实测结果（OnePlus PLQ110 / Android 16 / arm64）

**免 root 注入成功。** 手机上安装 `client-gadget-v3.apk` 后：

```
I DSHPROBE: application onCreate reached
D nativeloader: Load .../lib/arm64/libgadget.so ... : ok
I DSHPROBE: libgadget loaded
```

gadget 正常加载，`libhook.so` 脚本自动执行，**已经抓到第一把 XXTEA 密钥**：

```
/sdcard/Android/data/com.fgcq.a143097/files/996key.txt
xxtea_decrypt 33345546584d67746b7a000000000000
             = "34UFXMgtkz" + 6 个零字节    ← sign 4meJnPyl 那一对（serverlist/config）
```

关键实现要点（踩过的坑）：

| 坑 | 现象 | 解法 |
|---|---|---|
| `extractNativeLibs` 默认 false | lib 在 APK 内，gadget 找不到同目录 config | manifest 加 `android:extractNativeLibs="true"` |
| `adb install` 默认 Incremental | lib 不解压 | 用 `--no-incremental`，或 update-install 用 `-r` |
| `console.log` 在 app 进程里丢失 | logcat 看不到 FRIDA996 | 脚本改写 `/sdcard/Android/data/<pkg>/files/996key.txt` |
| Java 钩子在 `Application.onCreate` 早期挂 | **SIGSEGV，进程直接死** | 延后挂载（v5 试过 6s 仍然崩，需改为 listen 模式由 PC 侧控制） |

**真机比模拟器走得远得多**：能过隐私协议、能 `Http Request Code:200`、能进游戏主界面（模拟器上是 `Code:0`）。

**当前唯一的门：实名认证**

- 弹窗来自 `com.xqhy.login.view.RealNameActivity`（**注意不是** `com.xqhy.security.view.RealNameActivity`，之前 hook 错了包名）
- 填入校验位合法的合成身份证 `110101199001010015` + 乱填姓名 → 服务端返回：
  `extra_info=认证未通过,请提交真实信息`
- 说明 SDK 走第三方实名核验，合成身份过不去

**下一步（v6 方案，可免重复打包）**

把 gadget 配置从 script 模式改成 **listen 模式 + `on_load: wait`**：

```json
{"interaction":{"type":"listen","address":"127.0.0.1","port":27042,"on_load":"wait"},"runtime":"v8"}
```

这样进程一启动就停在 `Application.onCreate`，由 PC 侧 `frida-gadget-run.py` 连上去加载脚本并继续。
好处是**脚本改动不用重新打包 APK**（每次重打包要 5 分钟），Java 钩子也能在进程暂停状态下安全安装，
并且可以现场试 `com.xqhy.login.view.RealNameActivity` 的正确 hook 方式。

**v6 listen 模式实测（重要结论）**

配置 `{"interaction":{"type":"listen","address":"127.0.0.1","port":27042,"on_load":"wait"},"runtime":"qjs"}`：

| 步骤 | 结果 |
|---|---|
| 启动后进程停在 `Application.onCreate` | ✅ `Frida: Listening on 127.0.0.1 TCP port 27042` |
| PC 侧 `adb forward` + 连接 | ✅ |
| 纯原生脚本（6 个钩子） | ✅ `module libMyGame.so base=0x77a1014000`，全部挂上 |
| `session.resume()` 放行 | ✅（`device.resume(pid)` 对自身无效：`unable to act on other processes when embedded`） |
| **只要脚本里碰 `Java`（`Java.perform`）** | ❌ 连接立即断开 / 进程崩溃 |

**结论：这个 gadget 构建的 Java bridge 不可用，原生钩子稳定。** 因此绕过实名不能走 Frida Java 钩子，
要改成**静态改 smali**：

1. `com.xqhy.login.view.RealNameActivity.onCreate` 开头插入 `invoke-virtual {p0}, ...->finish()V`
2. `com.xqhy.login.bean.LoginBean.getAgeStatus` 改成 `const/4 v0, 0x1` + `return v0`
3. `libhook.so` 保持纯原生（抓 XXTEA 密钥），不再掺 Java

另外确认：**实名核验在服务端**，合成身份证 `110101199001010015` 被拒（`认证未通过,请提交真实信息`），
所以只能从客户端逻辑上跳过，不能靠填假数据。

---

## 6.7 真机全流程打通（2026-11-05 中午）

**v7/v8 静态补丁后，客户端在真机上完整跑通：隐私协议 → 登录 → 进启动器 → 选线路 → 启动 → 下载自定义资源 21.56 MB → 进入「创建人物」界面。**

两处 smali 补丁（`D:\asdk\repack\src`，已固化在 `client-gadget-v7.apk` / `v8`）：

```smali
# com/xqhy/login/view/RealNameActivity.smali
invoke-super {p0, p1}, Lcom/xqhy/lib/base/view/BaseActivity;->onCreate(Landroid/os/Bundle;)V
invoke-virtual {p0}, Lcom/xqhy/login/view/RealNameActivity;->finish()V   # ← 新增
return-void                                                              # ← 新增

# com/xqhy/login/bean/LoginBean.smali
.method public final getAgeStatus()Ljava/lang/Integer;
    const/4 v0, 0x1
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v0
    return-object v0
.end method
```

**已捕获的两把真实密钥**（`/sdcard/Android/data/com.fgcq.a143097/files/996key.txt`）：

```
xxtea_decrypt    33345546584d67746b7a000000000000   = "34UFXMgtkz" + 零填充   (serverlist/config)
xxtea_decrypt_v2 7756547833645430316a000000000000   = "wVTx3dT01j" + 零填充   (下载资源)
```

注意：这两把都**解不开** APK 里 sign 为 `XdvFTgd5YA` 的 1719 个 Lua——客户端解的是热更下载的资源，
APK 内那份是旧版本，实际从未被读取。

**下一步：拿 mod 的 Lua 明文（不必再攻密钥）**

引擎解密后必然把明文交给 Lua 虚拟机。已挂的 `luaL_loadbuffer(0xae0844)` / `luaL_loadbufferx(0xae0790)`
**从未触发**，因为这是 LuaJIT，引擎直接走更底层入口。补挂这两个即可：

```
lua_loadx  0x00ae03b0
lua_load   0x00ae0504
```

在 `onEnter` 里 `args[0]=lua_State*, args[1]=buf, args[2]=size` 把明文写文件，即可拿到全部脚本源码。

---

## 6.8 Lua 明文全部拿到（2026-11-05 中午，决定性突破）

给 `libhook.so` 补上 LuaJIT 的真实入口后，**引擎解密后的明文全部被 dump 出来**：

```
# hooked lua_loadx @ 0x77a07c53b0
# hooked lua_load @ 0x77a07c5504
# hooked luaL_loadbufferx @ 0x77a07c5790
# hooked luaL_loadbuffer @ 0x77a07c5844
# hooked cocos2dx_lua_loader
1 size=1623  head=72656c656173655f  ("release_")  from=luaL_loadbuffer
2 size=1918  head=2d2d2061766f6964  ("-- avoid")
3 size=19619 head=0d0a6363203d2063  ("cc = c")
...
577 size=625  head=6c6f63616c207569
```

**成果：578 个明文 Lua 文件，7.2 MB，已拉到 `D:\asdk\luadump\`。**

踩坑记录：Frida 的 `File` API **不能创建目录**，`luadump/` 必须先用
`adb shell mkdir -p /sdcard/Android/data/com.fgcq.a143097/files/luadump` 建好，否则只能拿到 chunk 日志没有文件。

### 从 Lua 里读出的关键情报

| 情报 | 位置 | 值 |
|---|---|---|
| 服务器列表解密 | `34_139536.lua:3307` `ModuleChooseLayer:DecodeServerList` | **base64 → DES-ECB，zero padding** |
| DES 密钥 | 同上 | `v@K#KlYkLlH3BN&3%wM!BM99` |
| modlist URL 组装 | `17_65862.lua:563` | `string.format(originUrl, channelId) .. "?type=getaway&time=..&sign=MD5(key=..&time=..)"` |
| URL 来源 | `16_47491.lua:161` | `paramJson.srvlist`（由 SDK 回调提供） |
| modlist 解码 | `17_65862.lua:541` | `decodeModlistXXTEA(response)` → 密钥很可能就是已抓到的 `34UFXMgtkz` |

### 指向自己的服务器：完整路线

1. 用 `34UFXMgtkz` 解开官方 modlist 密文（或直接改客户端缓存的 2275 B 明文 JSON），把
   `modData[0].srvlist` 改成 `http://192.168.10.178/serverlist_%s.txt`
2. 用 DES-ECB(`v@K#KlYkLlH3BN&3%wM!BM99`) + base64 造一份 serverlist，条目指向
   `192.168.10.178:7000`（LoginGate）
3. 在本机起一个 HTTP 服务托管这两个文件
4. 改客户端里 `GetModInfoURL()` 的默认值指向本机（改 Lua 后以**明文**放回 APK 的
   `assets/mod_fgcq/stab/scripts/` —— `getDataFromFile` 只在文件头匹配 sign 时才解密，
   不匹配就原样返回，所以明文 Lua 可以直接用）
5. 重打包安装，客户端就会连我们自己的六个端口

---

## 6.9 客户端已连上本机服务端（2026-11-05 13:04，目标达成）

**手机上的客户端已经连到我们自己的 996 服务端：**

```
[LUA-print] {"serverName":"演示版",...,"port":7000,...,"ip":"192.168.10.178",...} ____selectServer
[LUA-print] tcp connect to:  192.168.10.178 7000 true
[LUA-print] <- step 2. 529 handle_MSG_SC_RESPONSE_SERVER_LIST
[LUA-print] GN_onUserIDUpdated {"userID":"1757008192","srvID":14522294}
[LUA-print] -> step 3. 104 RequestServerInfo
[LUA-print] <- step 4. 530 handle_MSG_SC_RESPONSE_SERVER_INFO
[LUA-print] -> step 5. 100 RequestRoleInfo

netstat: TCP 192.168.10.178:7000  192.168.10.106:43180  ESTABLISHED  (LoginGate 8812)
```

手机 `192.168.10.106` → 本机 LoginGate `192.168.10.178:7000`，协议握手走到**发角色列表请求**这一步
（正是模拟器上卡死的那一步，现在服务端有响应了）。

### 实现方式：内存里改 Lua，不碰加密文件

`libhook.so` 在 `luaL_loadbuffer` 里对 `ModuleChooseLayer:RespModSrvlist` 的源码做**等长原地替换**：

```lua
v.srvip           = v.i or v.srvip      →  v.srvip         = "192.168.10.178"
v.port            = v.p or v.port       →  v.port            = 7000
v.proxyport       = v.x or v.proxyport  →  v.proxyport       = 7000
```

（`connectPort = tonumber(proxyport or port)`，官方 `proxyport` 是 12002，不改就会连错端口。）

**两个必须记住的坑（都踩过）**

| 坑 | 后果 | 正确做法 |
|---|---|---|
| `readUtf8String` 会解码 UTF-8，而 Lua 里有大量中文注释 | JS 下标 ≠ 字节偏移，补丁写到错误位置，Lua 语法崩 | 全程用 `Uint8Array` 按字节 `find` + `set` |
| `writeUtf8String` 自动追加 `\0` | 覆盖下一个字符 | 用 `writeByteArray` 写等长字节 |

### 当前卡点：数据库里没有账号/角色

```
box 库 39 张表，无任何 Account/Login 表；TBL_CHARACTER 行数 = 0
存储过程：HERO_INFO_ADD/UPDATE, HUM_INFO_ADD/UPDATE, LoadItemVar, PET_INFO_UPDATE
```

客户端 `RequestRoleInfo` 发出后服务端没有回包（客户端提示「连接服务器超时 100 -> 520 / 527」）。

**服务端侧完整证据链（DBServer debug 日志）**

```
>>>CheckAccount Msg 1757008192/... IP 192.168.10.106
GM 0 sLoginID 1757008192 ... sChannel 143097
>>OnMsg 104,msg:96 ...
>>OnMsg 100,msg:144 ...
QueryChr 1757008192/1/14522294/143097/212342/GOIOSEEEDYMCY8OABLN5PVBGDP7OFRRN
```

`QueryChr` 已被解析并执行，之后就再无输出、也没有回包，且 SQL 侧无报错。

**排查过程中排除掉的**

| 怀疑点 | 结论 |
|---|---|
| WSL 挂起导致 DB 断连 | 确实发生过一次（1433 连接为空、M2 掉到 582 MB），重启链路并加保活后恢复；但重测后现象不变，**不是本因** |
| 端口分工（`proxyport` vs `port`） | 源码里两处连接都用 `connectPort = tonumber(proxyport or port)`，官方 12002 是代理中继；本地都指向 LoginGate 7000 时握手能走通，故不是卡点 |
| M2Server 状态 | 1044 MB、`EnvirThread` 正常、6686 怪物已加载，`Session:0` 符合当前无人在线 |

**下一步**：创建账号记录。方向有两个——
1. 用 `GameCenter.exe` 的数据库初始化/账号管理功能（它可能负责建 `TBL_ACCOUNT` 这类表）；
2. 直接给 `1757008192` 造一条账号记录（需先确认引擎读的是哪张表，可用 SQL 事件会话抓它执行的 SELECT）。

## 6.10 角色列表通了，建角色返回码 4（2026-11-05 13:15）

重启服务端链路（DBServer 重连 SQL）后，同一套流程走通：

```
-> step 5. 100 RequestRoleInfo
<- step 6. 520 handle_MSG_SC_RESPOINSE_ROLE_INFO     ← 服务端正常回包
```

客户端进入**创建人物界面**（连着本机服务端，`7000 ESTABLISHED`）。

点提交建角色：

```
-> step 6.1 101 RequestCreateRole
   {"server_name":14522294,"sex":0,"account":"1757008192","secsdk":"0",
    "job":0,"sdkid":"143097","chr":"寇煞爺"}
<- step 6.2 522 handle_MSG_SC_CREATE_ROLE_FAIL 4
```

**客户端源码里的失败码表**（`162_49962.lua:812` 附近）：

```
1   角色名称已存在
2   角色名称存在过滤字符
3   创建角色超过两个
5   角色名称存在特殊字符
6   角色名称长度小于2或大于16字节
7   服务器禁止创建角色（代理设置）
100 服务器不允许创建角色
102 服务器禁止创建全英文名称
103 角色名称存在禁言关键词
999 创建错误时传 Json 格式错误
```

**返回码 4 不在表内**（未文档化）。两个最可能的成因：

1. **`server_name` 不匹配**：客户端传 `14522294`（serverlist 里的 `d` 字段），而
   `dbsrc.ini` 里 `ServerID=100`；建角处理器可能按服务器 ID 校验。
2. 账号记录缺失导致 `HUM_INFO_ADD` 失败（但 520 角色查询能过，所以可能性较低）。

**下一步验证顺序**：先把 `dbsrc.ini` 的 `ServerID` 改成 `14522294`（或把客户端 JSON 里的
`server_name` 改掉）再试建角色；若仍为 4，则直接手工调 `HUM_INFO_ADD` 看 SQL 报错。

## 6.11 建角色失败的真正原因：SQL 连接反复掉线（2026-11-05 13:19）

DBServer 的 `error_*.txt` 里两条异常把根因说清楚了（都是同一句）：

```
[Exception]TUserGate.QueryChr Error 1757008192/...,  
  [FireDAC][Phys][ODBC][Microsoft][ODBC SQL Server Driver]通讯链接失败

[Exception]TDM.AddChr Error 
  [FireDAC][Phys][ODBC][Microsoft][ODBC SQL Server Driver]通讯链接失败
```

即：**不是账号缺失，也不是服务器 ID 不匹配**，而是 FireDAC 到 SQL Server 的 ODBC 连接已经断了。
角色查询（520）那次能成功，是因为当时连接还活着；几秒后连接死掉，建角色（AddChr）就失败，
服务端返回未文档化的错误码 4。

**关键行为特征**

| 现象 | 说明 |
|---|---|
| DBServer 只在启动时建立连接 | 记录里 4 条 `:1433 ESTABLISHED` 出现在刚启动后 |
| 连接断掉后不自愈 | 之后再无 `:1433` 连接，所有 DB 操作都抛"通讯链接失败" |
| WSL 侧 SQL 本身健康 | `wsl` 内 `sqlcmd` 查询正常，从 Windows `Test-NetConnection 172.25.150.14:1433` 为 True |
| WSL IP 未变 | 仍是 `172.25.150.14` |

**结论**：WSL2 的网络 NAT / 发行版挂起会让长连接被静默回收，而 DBServer 不做重连。

**三种解决方向（按推荐度）**

1. **把 SQL Server 挪出 WSL**：装到 Windows 本机（或独立虚拟机）。这是根治——长连接不再经过 WSL 的 NAT 层。
2. **给 FireDAC 开 TCP keepalive**：在 DBServer 侧设置连接参数让空闲连接保持活跃（需要改连接串/驱动参数）。
3. **临时规避**：每次开玩前重启 DBServer，让连接重新建立，并在连接存活期内完成登录+建角。

## 6.12 SQL Server 迁出 WSL（2026-11-05 13:50，已完成）

**架构变化**：数据库从 WSL 里的 SQL Server 2022 迁到 Windows 本机的 SQL Server 2025 Express，
彻底绕开 WSL2 NAT 会静默回收长连接的问题。

| 项 | 旧 | 新 |
|---|---|---|
| 位置 | WSL Ubuntu (`172.25.150.14:1433`) | Windows 本机 (`127.0.0.1:1433`) |
| 版本 | SQL Server 2022 CU27 | SQL Server 2025 Express (17.0.1000.7) |
| 实例 | — | `MSSQL17.MSSQLSERVER`（默认实例） |
| 库 | `box` | `box`（从 .bak 还原，版本 989→998 自动升级） |

**改动的三处配置**（原文件备份为 `*.dshbak`）：

```
DBServer\dbsrc.ini   SQLIP=127.0.0.1
Mir200\Setup.json    "M2DBIpaddr":"127.0.0.1"
GCConfig.ini         SQLServerAddr=127.0.0.1
```

### 迁移中踩到的坑：ODBC Driver 18 强制加密

还原完成后 DBServer 仍连不上库，逐个驱动实测定位：

```
[OK]   ODBC Driver 17 for SQL Server
[FAIL] ODBC Driver 18 for SQL Server
       ERROR [08001] SSL 提供程序: The certificate chain was issued by an
       authority that is not trusted.
[OK]   SQL Server（旧驱动）
```

FireDAC 自动选版本最新的驱动（18），而 ODBC 18 默认强制加密且不信任 SQL Server 的自签名证书。
**解决**：卸载 ODBC Driver 18（产品码 `{9B7F3981-E3B5-4323-949B-56F5CC5D94E2}`），FireDAC 回落到 17。

副作用：`sqlcmd.exe`（ODBC 18 版本）随之失效，需要时用 PowerShell + ODBC 17 代替。

### 验证结果

```
SQL Server 服务 : Running
1433 连接数     : 26 条 ESTABLISHED（持续稳定，不再掉线）
服务端进程      : DBServer 111MB / M2Server 984MB / RunGate 44MB / LoginGate 26MB
六端口          : 7000 7110 7201 7301 7400 8400 全部 LISTENING
box 库          : 39 张表，TBL_CHARACTER 0 行（经 ODBC 17 验证）
```

### WSL 清理

已卸载并删除：`mssql-server`、`mssql-tools18`、`msodbcsql18`、`unixodbc*`、
`/opt/mssql`（1.3 GB）、`/opt/mssql-tools18`、`/var/opt/mssql`（157 MB）、
`/etc/profile.d/99-clash-proxy.sh`、微软 apt 源与 keyring。

WSL 复查：无 sqlcmd、无 /opt/mssql、1433 不再监听。
WSL 网络配置已从 `networkingMode=mirrored` 复原为 `nat`。

## 6.13 中文名乱码修复 + 掉血机制定位（2026-11-05 14:30）

### 中文名乱码：数据库排序规则错误

**根因**：`box` 库的排序规则是 `SQL_Latin1_General_CP1_CI_AS`（代码页 1252），
引擎按 GBK 写入的中文被驱动转换成 `?` 落库。

**修复步骤**

```sql
ALTER DATABASE [box] COLLATE Chinese_PRC_CI_AS;            -- 库级
-- 108 个 varchar/char 列逐列 ALTER COLUMN ... COLLATE Chinese_PRC_CI_AS
-- 有索引的 3 列需要先删索引再改，然后重建：
DROP INDEX IX_TBL_CHARACTER_FLD_ACCOUNT   ON TBL_CHARACTER;
DROP INDEX IX_TBL_CHARACTER_FLD_CHARACTER ON TBL_CHARACTER;
DROP INDEX IX_TBL_CHARACTER_FLD_REALACCOUNT ON TBL_CHARACTER;
ALTER TABLE TBL_CHARACTER ALTER COLUMN FLD_CHARACTER varchar(50) COLLATE Chinese_PRC_CI_AS NULL;
-- ... 改完重建同名索引
UPDATE TBL_CHARACTER SET FLD_CHARACTER = 0xCEE8C2DCB2B7 WHERE FLD_ID = 1;  -- 舞萝卜 的 GBK 字节
```

**验证**：`SELECT FLD_CHARACTER` → `舞萝卜`，`DATALENGTH=6` ✓

注意：ODBC 用 Latin1 显示成 `ÎèÂÜ²·` 是正常的——说明字节就是 GBK 的 `CEE8 C2DC B2B7`。

### 掉血机制：引擎的饥饿系统

引擎 `M2Server.exe` 里的符号直接说明了机制：

```
nHungerPoint            -- 饥饿值
m_nHungerStatus         -- 饥饿状态
m_dwDecHungerPointTick  -- 饥饿值递减定时器
CmdHunger               -- GM 命令（Command.ini: Hunger=Hunger，等级 10）
```

`HUM_INFO_ADD` 建角时只写基础行，**不初始化饥饿值**，新角色 Hunger=0，引擎每个 tick 扣血，
直到死亡。属性本身是正常的（从 `FLD_AbilMax` 解出的 int64 数组：等级 1、MaxHP 19），
而 `FLD_Abil` 里当前 HP 已经掉到 9，符合持续失血。

**已做的兜底**（`!setup.txt`，原文件备份 `!setup.txt.dshbak2`）：

```ini
HpPlayBase=75     -> 500      # 每次回血量
HpPlaySpeed=6000  -> 2000     # 回血间隔(ms)
```

回血速率从 12.5 HP/s 提升到 250 HP/s，远高于饥饿扣血速率。

**根治方案（可选）**：建角时初始化饥饿值，或把角色加入 `Envir\AdminList.txt` 成为 GM，
用 `@Hunger` 命令回满。

---

## 7. 易失状态清单（重启后必须重建）

1. WSL 的 vNIC IP → 变了就要改 `dbsrc.ini` 的 `SQLIP` 和 `Setup.json` 的 `M2DBIpaddr`
2. 模拟器上的 iptables DNAT 规则
3. 设备上的 frida-server 进程
4. 客户端必须用 frida spawn 启动
5. `Modlist` 代理（`tools/modlist-proxy.py` 监听 8888）必须运行
6. WSL 保活任务必须运行

---

## 8. 工具清单（`working/996-local/tools/`）

| 文件 | 作用 |
|---|---|
| `modlist-proxy.py` | 8888 透明代理，转发官方 modlist/srvlist（绕过签名墙） |
| `frida-run.py` | spawn / attach 运行器，支持 `--pid`（纯 attach，不 resume） |
| `frida-noop.js` | 空载荷，仅用于让 spawn 顶住启动期 |
| `frida-996-age-hooks.js` | 实名绕过（4 个钩子，已验证） |
| `frida-996-connect-redirect.js` | 网络钩子 v2（支持 AF_INET6 / v4-mapped），当前仅作诊断用 |
| `frida-996-roleinfo-probe.js` | Java 符号探测（未完成） |
| `diag-java.js` | Java 桥健康检查 |
| `local-996-srv.py` | 旧版本地配置服务（已被代理取代） |
