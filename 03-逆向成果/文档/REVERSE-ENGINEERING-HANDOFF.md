# 996 引擎传奇手游 — 逆向与本地化总报告

> **用途**：交接文档。读者是接手的 agent / 工程师，读完本文应能独立继续工作，不必重走已排除的弯路。
> **生成时间**：2026-11-05 14:40
> **当前状态**：手机客户端已连上本机自建服务端，可登录、建角、进游戏、移动；剩余一个未决问题（进游戏后持续掉血）。

---

## 0. 一分钟速览

| 维度 | 结论 |
|---|---|
| 目标 | 用 996 引擎（996M2 / 杭州慧跃）在本地搭传奇服务端，用**原生 APK** 在手机上玩 |
| 服务端 | Windows PE x86-64 四进程，六端口，SQL Server 已迁到 **Windows 本机** 的 SQL Server 2025 Express |
| 客户端 | `com.fgcq.a143097`（热血演示版 4.7.2），Cocos2d-x + **LuaJIT** |
| 最大突破 | 用免 root 的 **Frida Gadget** 注入，在 `luaL_loadbuffer` 处 **dump 出 578 个明文 Lua**，彻底绕过加密；并可在内存中等长改写 Lua，实现服务器重定向 |
| 是否已达成目标 | **已达成**：客户端连本机服务端、建角、进游戏、可移动 |
| 未决问题 | 进游戏后持续掉血且完全不回血（见 §9） |

---

## 1. 环境与凭据

### 1.1 本机

```
工作目录        D:\project\新建文件夹\mingyang-mobile
工作子目录      working\996-local\        （文档、工具、截图、服务端）
逆向工作目录    D:\asdk\                 （APK 解包、重打包、Lua dump、安装介质）
本机 LAN IP     192.168.10.178（以太网）
Python          C:\Users\28531\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe
                （已装 frida 16.7.19、capstone、pyelftools）
JDK             D:\asdk\jdk
apktool         D:\asdk\dl\apktool.jar（3.0.3）
Android SDK     D:\asdk\sdk（build-tools 34.0.0，platform-tools 含 adb）
keystore        D:\asdk\repack\dsh.keystore（alias=dsh，store/key 密码均为 android）
```

### 1.2 手机

```
型号        OnePlus PLQ110
系统        Android 16 / SDK 36 / arm64-v8a
序列号      3B15BU003H700000（adb 用这个）
分辨率      1272 x 2800（竖屏原始坐标），横屏时 input tap 仍用显示坐标
包名        com.fgcq.a143097
启动 Activity  org.cocos2dx.cpp.AppActivity
Application    org.cocos2dx.cpp.CQGameApplication
SDK 账号     zq996b / Aa123456
SDK userID   1757008192
角色          舞萝卜（战士，已建，存在于 TBL_CHARACTER）
```

### 1.3 数据库

```
实例       MSSQL17.MSSQLSERVER（默认实例，SQL Server 2025 Express 17.0.1000.7）
地址       127.0.0.1:1433
账号       sa / 996Mir@2026
库         box（39 张表，6 个存储过程）
排序规则   Chinese_PRC_CI_AS（2026-11-05 已改，之前是 SQL_Latin1_General_CP1_CI_AS）
```

> 注意：`sqlcmd.exe` 依赖 ODBC Driver 18，而 18 已被卸载（见 §7），**sqlcmd 现在不可用**。
> 查询请用 PowerShell + `System.Data.Odbc` + `Driver={ODBC Driver 17 for SQL Server}`。

---

## 2. 服务端架构

### 2.1 进程与端口

```
进程       监听端口        作用
DBServer   7201, 7301     DB 网关 / 会话服务（唯一连 SQL 的进程）
M2Server   7400, 8400     游戏主逻辑 / DGate
LoginGate  7000           登录网关（客户端第一跳）
RunGate    7110           游戏网关（进游戏后第二跳）
```

链路：

```
客户端 ──7000──> LoginGate ──7201──> DBServer ──1433──> SQL Server
客户端 ──7110──> RunGate   ──7400──> M2Server ──7301──> DBServer
                                      M2Server ──8400──> DBServer
```

### 2.2 目录

```
服务端根  D:\project\新建文件夹\mingyang-mobile\working\996-local\server\version\新3端纯净版\服务端\MirServer\
  DBServer\dbsrc.ini      SQL 连接、ServerID、建角开关
  Mir200\Setup.json       M2 的 DB 配置（M2DBIpaddr 等）
  Mir200\!setup.txt       1663 个键：回血/属性/技能/等级参数（GBK 编码）
  Mir200\Envir\           地图、NPC、怪物、脚本、各类白名单
  GCConfig.ini            GameCenter 配置
```

### 2.3 启动顺序（必须遵守）

```
DBServer -> 等 12s -> M2Server -> 等 28s（加载到 ~1000MB）-> RunGate -> 等 4s -> LoginGate -> 等 8s
```

**必须用 WMI 启动**，否则进程会随工具调用被回收：

```powershell
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
  CommandLine = "`"<exe 绝对路径>`""; CurrentDirectory = "<exe 所在目录>" }
```

---

## 3. 客户端结构

### 3.1 技术栈

```
引擎       Cocos2d-x（渲染 Lua 之外的部分）+ LuaJIT（脚本）
脚本位置   assets 内加密存放，运行时解密后交给 LuaJIT
热更新     启动时从官方 CDN 下载资源包（21.56 MB），存 app 私有目录
```

### 3.2 XXTEA 资源容器

```
文件格式：10 字节 sign + XXTEA 密文
APK 内 Lua 的 sign = "XdvFTgd5YA"
服务端列表 sign    = "4meJnPyl"

XXTEA 参数：DELTA = 0x9E3779B9, rounds = 6 + 52/n, key 缓冲按 16 字节读取
（struct.unpack("<4I", key)）
```

四份 `xxtea_decrypt*` 实现字节完全相同（各 76 条指令），偏移见 §5。

### 3.3 关键事实：APK 内的 Lua 是死数据

APK 里 1719 个 sign 为 `XdvFTgd5YA` 的文件**从未被读取**——客户端实际解密的是热更新下载的资源。
所以"攻破 XXTEA 密钥"这条路走不通也不需要：**直接 hook Lua 加载函数 dump 明文**才是正解。

---

## 4. 全部密钥与凭据（已实测）

| 密钥/凭据 | 值 | 来源与用途 | 状态 |
|---|---|---|---|
| APK 资源 sign | `XdvFTgd5YA` | APK 内 Lua 容器标识 | 已确认，但文件是死数据 |
| 服务端列表 sign | `4meJnPyl` | serverlist 容器 | 已确认 |
| **在线 XXTEA key #1** | `34UFXMgtkz` | 运行时抓到，解 modlist 类数据 | **实测有效** |
| **在线 XXTEA key #2** | `wVTx3dT01j` | 运行时抓到，解热更下载资源 | **实测有效** |
| **serverlist DES key** | `v@K#KlYkLlH3BN&3%wM!BM99` | `ModuleChooseLayer:DecodeServerList`，DES-ECB + base64 + 零填充 | 源码确认 |
| modlist 请求签名 key | `shPUZw4ncV5oJ3Hu` | `GameEnvManager:_modlistSignKey` | 源码确认 |
| 数据库 sa | `996Mir@2026` | SQL Server | 有效 |
| SDK 账号 | `zq996b` / `Aa123456` | 996 官方平台账号 | 有效 |

抓密钥的脚本：`working/996-local/tools/frida-996-native.js`（hook 四个 xxtea 函数写 key 到文件）。
线上抓到的原始记录在设备：
`/sdcard/Android/data/com.fgcq.a143097/files/996key.txt`

---

## 5. 客户端关键函数偏移（libMyGame.so, arm64）

基址从 `Process.findModuleByName('libMyGame.so').base` 取，偏移直接加。

```
XXTEA:
  xxtea_decrypt       0xdc9cc4
  xxtea_decrypt_v2    0xdca044
  xxtea_decrypt_v3    0xdca3c4
  xxtea_decrypt_v4    0xdca74c

Lua 加载（LuaJIT，注意 luaL_* 只是包装）:
  lua_loadx           0xae03b0    ← 真正入口
  lua_load            0xae0504
  luaL_loadbufferx    0xae0790
  luaL_loadbuffer     0xae0844    ← 实测被调用，dump 点
  luaL_loadstring     0xae08d8
  cocos2dx_lua_loader 0x7f98cc    （每次加载都会调用，可做纯标记）
```

引擎符号核对方法：`readelf --dyn-syms` 看 `st_value`，与基址相加即真实地址。

---

## 6. 核心绕过手段（三套，均已落地）

### 6.1 实名认证绕过（静态 smali，已验证）

`com/xqhy/login/view/RealNameActivity.smali`，在 `super.onCreate` 之后插入：

```smali
invoke-super {p0, p1}, Lcom/xqhy/lib/base/view/BaseActivity;->onCreate(Landroid/os/Bundle;)V
invoke-virtual {p0}, Lcom/xqhy/login/view/RealNameActivity;->finish()V
return-void
```

`com/xqhy/login/bean/LoginBean.smali`，`getAgeStatus()` 恒返回 1（成年）：

```smali
.method public final getAgeStatus()Ljava/lang/Integer;
    const/4 v0, 0x1
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v0
    return-object v0
.end method
```

> 为什么要静态改：服务端会对提交的身份信息做二次核验（返回 `认证未通过,请提交真实信息`），
> 所以不能靠填假身份证过，只能让实名 Activity 不出现。

### 6.2 免 root Frida Gadget 注入（已验证）

原理：把 gadget 作为普通 .so 塞进 APK，在 `Application.onCreate` 里 `System.loadLibrary`。

**步骤**

1. `apktool d` 解包
2. `smali_classes3/org/cocos2dx/cpp/CQGameApplication.smali` 的 `onCreate()` 顶部插入：
   ```smali
   const-string v0, "gadget"
   invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V
   ```
3. 放三个文件到 `lib/arm64-v8a/`：
   - `libgadget.so`（frida gadget 16.7.19 android-arm64）
   - `libgadget.config.so`（实为 JSON 配置）
   - `libhook.so`（**实为纯文本 JS 脚本**，靠 `.so` 后缀骗过 PM 的解压规则）
4. `AndroidManifest.xml` 的 `<application>` 加 `android:extractNativeLibs="true"`
5. 重新打包 → `zipalign -p 4` → `apksigner sign` → `adb install -r -g --no-incremental`

**gadget 配置**（`libgadget.config.so`）：

```json
{"interaction":{"type":"script","path":"libhook.so"},"runtime":"qjs"}
```

**硬约束（踩过的坑，别重试）**

| 现象 | 原因 | 结论 |
|---|---|---|
| `Java.perform` 一调用连接就断 / SIGSEGV | 该 gadget 构建的 Java bridge 在此机型不可用 | **只用 native hook，别碰 Java bridge** |
| `runtime: "v8"` 时 `script.load()` 报 connection closed | 运行时选择问题 | **必须 `runtime: "qjs"`** |
| `console.log` 收不到 | Android 上 gadget 控制台不可用 | **一切结果写文件**（`/sdcard/Android/data/<pkg>/files/`） |
| gadget 脚本不执行 | `extractNativeLibs` 默认 false + 增量安装不落地 | 加 manifest 标志 + `--no-incremental` |
| `device.resume(pid)` 报 "unable to act on other processes when embedded" | gadget 内嵌模式 | 用 `session.resume()` |
| Frida `File` API 不能建目录 | API 限制 | 需要子目录时先用 `adb shell mkdir -p` 建好 |

### 6.3 内存改写 Lua 实现服务器重定向（已验证）

在 `luaL_loadbuffer` 的 `onEnter` 里对明文 chunk 做 **等长原地字节替换**，引擎无感知。

`ModuleChooseLayer:RespModSrvlist` 里三行：

```lua
v.srvip           = v.i or v.srvip        →  v.srvip         = "192.168.10.178"
v.port            = v.p or v.port         →  v.port            = 7000
v.proxyport       = v.x or v.proxyport    →  v.proxyport       = 7000
```

`LoginProxy:RequestConnectGameServer`（进游戏那条路径，与登录路径代码完全一样，必须靠上下文区分）：

```lua
local ip          = self:GetGameServerIP() or self:GetSelectedServerIp()   ← 用它做锚点
...
local connectPort = tonumber(proxyport or port)  →  tonumber(7110)
```

**两个致命细节**

| 坑 | 后果 | 正解 |
|---|---|---|
| `readUtf8String` 会做 UTF-8 解码，而 Lua 里全是中文注释 | JS 字符串下标 ≠ 内存字节偏移，补丁写到错误位置，Lua 语法崩 | **全程用 `Uint8Array` 按字节 `find`/`set`** |
| `writeUtf8String` 自动追加 `\0` | 覆盖后一个字符 | **`writeByteArray` 写等长字节** |

**定位 bug 的手法是关键**：把打完补丁的 chunk 从内存 dump 出来，和原始 dump 做 `difflib` 对比，
一眼就能看出写到哪去了。

---

## 7. 服务端数据模型

### 7.1 关键表

```
TBL_CHARACTER   69 列，角色主表
  重要列：FLD_ID, FLD_ACCOUNT, FLD_CHARACTER(角色名), FLD_USERID, FLD_MAPNAME, FLD_CX/FLD_CY,
          FLD_SEX, FLD_JOB, FLD_LEVEL, FLD_GAMEGOLD, FLD_DBVERSION, FLD_STATUS,
          FLD_INCREALTH, FLD_INCSPELL, FLD_INCHEALING,
          FLD_Abil(varbinary 3200B), FLD_AbilMax(varbinary 3200B), FLD_BonusAbil(80B),
          FLD_SYSVAR(400B), FLD_UVAR(8000B), FLD_JVAR(2000B), FLD_HumParams(JSON)
TBL_VAR_ROLE / TBL_VAR_OTHER   角色变量 key-value
TBL_ITEM_BAG / TBL_ITEM_BODY / TBL_ITEM_STORAGE   物品
TBL_CONFIG      注册/开关参数（iRegCount, Regis, StartTime, DisableTime ...）
```

### 7.2 存储过程

```
HUM_INFO_ADD      建角色（见下方要点）
HUM_INFO_UPDATE   保存角色
HERO_INFO_ADD / HERO_INFO_UPDATE
PET_INFO_UPDATE
LoadItemVar
```

`HUM_INFO_ADD` 的关键行为：

- 插入基础行后，用 `IIF(mainServerID=0,1,mainServerID) * 2^32 + NEXT VALUE FOR dbo.SeqIden` **覆盖 FLD_USERID**
- 返回码：1=角色名已存在 3=角色数超 6 7=注册限制
- **不初始化等级、属性、饥饿值** ← 这是 §9 问题的根源之一

### 7.3 属性数组格式（已完整解码）

`FLD_Abil` = 当前值数组，`FLD_AbilMax` = 上限数组，**均为 int64 数组，400 个元素**。
索引语义来自客户端 `98_43851.lua` 的 `attTypeTable`（共 141 项）：

```
[0]   LEVEL            [1]   HP              [2]   MP
[3]   Min_ATK          [4]   Max_ATK         [5-6] Min/Max_MAT
[7-8] Min/Max_Daoshu   [9-10] Min/Max_DEF     [11-12] Min/Max_MDF
[13]  Hit_Point        [14]  Speed_Point     [15]  Anti_Magic
[16]  Anti_Posion      [17]  Posion_Recover  [18]  Health_Recover  体力恢复
[19]  Spell_Recover    [20]  Hit_Speed       [21]  Double_Rate
[61]  HP_Recover       [71]  Sec_Recovery_HP [91]  Sec_Recovery_MP
[94]  Weight 负重      [96]  Wear_Weight     [98]  Hand_Weight
[100] Internal_Value   [150] EXP 经验        [151-154] 走/跑/攻/施法间隔(ms)
[159] BagMaxNum        [160] PKPoint         [161] SuperPower 战力
```

读取方法（PowerShell + ODBC 17）：

```powershell
[BitConverter]::ToInt64($blob, $i*8)
```

### 7.4 协议消息号（客户端实测）

```
2001  请求服务器列表        529   服务器列表响应
104   请求服务器信息        530   服务器信息响应
100   请求角色列表          520   角色列表响应
101   请求创建角色          522   创建角色失败（P0 = 错误码）
103   选择角色              20    游戏网关登录
107   未知（出现于流程中）
```

客户端创建角色失败码表（`162_49962.lua:812`）：

```
1 角色名已存在   2 过滤字符   3 超过两个   5 特殊字符   6 长度非法
7 服务器禁止建角  100 不允许建角  102 禁止全英文  103 禁言关键词  999 JSON 格式错误
（4 = 未文档化，实测为服务端内部异常，如 SQL 断连）
```

---

## 8. 客户端工作流与端口语义

```
启动 → SDK 登录（原生 PasswordLoginActivity，走官方 API）
     → 启动器（Lua）→ 公告 → 选线路 → 启动
     → 连接 LoginGate(7000)：2001 列表 / 104 服务器信息 / 100 角色列表 / 101 建角 / 103 选角
     → 连接 RunGate(7110)：20 游戏网关登录 → 进入场景
```

**关键**：登录与进游戏两条路径的代码完全一样，都是

```lua
local connectPort = tonumber(proxyport or port)
```

官方靠一个 **代理中继（proxyport=12002）** 在两阶段复用同一端口。自建服务端没有这个中继，
所以必须**分别**打补丁：登录 → 7000，进游戏 → 7110。只改一个就会出现「建角成功但进游戏超时」。

---

## 9. 未决问题：进游戏后持续掉血且完全不回血

### 9.1 已确认的事实

| 项 | 证据 |
|---|---|
| 完全不回血 | `FLD_Abil[18] Health_Recover = 0`，`[61] HP_Recover = 0`，`[71] Sec_Recovery_HP = 0` |
| 调 `HpPlayBase/HpPlaySpeed` 无效 | 回血被 `Health_Recover` 门控，属性为 0 时参数不起作用 |
| 不在中毒状态 | `FLD_STATUS = 0` |
| 递增字段正常 | `FLD_INCREALTH/INCSPELL/INCHEALING = 0` |
| 无地图伤害事件 | `Envir\MapEvent.txt` 是空文件 |
| 无脚本扣血 | Envir 全目录无任何 HP 修改命令 |
| `fight5` 不是伤害标志 | 41 张图都有（含测试屋），比奇省反而没有 |
| 属性本身正常 | HP 9/19、MP 14/15、等级 1、经验 0/10 |

### 9.2 强烈怀疑：引擎饥饿系统

`M2Server.exe` 符号：

```
nHungerPoint            饥饿值
m_nHungerStatus         饥饿状态
m_dwDecHungerPointTick  饥饿递减定时器
CmdHunger               GM 命令（Command.ini: Hunger=Hunger，等级 10）
```

饥饿值**不在属性数组**（141 项全核对）、**不在数据库**（FLD_SYSVAR/UVAR/JVAR 全 0），
说明是纯内存态。新角色由 `HUM_INFO_ADD` 创建时未初始化 → 恒为 0 → 持续扣血。

### 9.3 下一步验证（只读，不改任何东西）

1. 角色进游戏站着不动
2. 每 5 秒读一次 `TBL_CHARACTER.FLD_Abil[1]`（当前 HP）与 `FLD_UPDATEDATETIME`
3. 算出掉血速率，比对饥饿扣血的标准速率即可确认

### 9.4 可选修复方向（待确认后实施）

- 建角时初始化饥饿值（改 `HUM_INFO_ADD` 或引擎侧配置）
- 给角色 GM 权限，进游戏用 `@Hunger` 命令补满（`Envir\AdminList.txt` 当前为空）
- 定位并修正 `Health_Recover` 为 0 的原因（正常角色应为非 0）

---

## 10. 构建与部署流程

### 10.1 重新打包客户端（约 3.5 分钟）

```powershell
$env:JAVA_HOME='D:\asdk\jdk'
& 'D:\asdk\jdk\bin\java.exe' -Xmx6g -jar 'D:\asdk\dl\apktool.jar' b `
    'D:\asdk\repack\src' -o 'D:\asdk\repack\patched-unsigned.apk'
```

### 10.2 签名与安装（约 30 秒）

```powershell
$bt='D:\asdk\sdk\build-tools\34.0.0'; $R='D:\asdk\repack'
& "$bt\zipalign.exe" -f -p 4 "$R\patched-unsigned.apk" "$R\patched-aligned.apk"
& "$bt\apksigner.bat" sign --ks "$R\dsh.keystore" --ks-pass pass:android `
    --key-pass pass:android --ks-key-alias dsh --out "$R\client-gadget-vN.apk" "$R\patched-aligned.apk"
& 'D:\asdk\sdk\platform-tools\adb.exe' -s 3B15BU003H700000 install -r -g "$R\client-gadget-vN.apk"
```

> `-r` 保留数据（登录态、热更资源），不必每次重登。

### 10.3 查看 hook 结果（无需 root）

```powershell
adb -s 3B15BU003H700000 shell "cat /sdcard/Android/data/com.fgcq.a143097/files/996chunks.txt"
adb -s 3B15BU003H700000 shell "ls /sdcard/Android/data/com.fgcq.a143097/files/luadump | wc -l"
```

---

## 11. 已排除的路线（不要重走）

| 路线 | 结论 |
|---|---|
| x86 主机跑 arm64 AVD | 模拟器 37.2.13 直接拒绝；绕过架构门后 QEMU 初始化即静默退出 |
| Frida 通过 adb 直连手机进程 | 未 root 无法 attach |
| Frida Java bridge | 本 gadget 构建在此机型不可用，一用就崩 |
| 暴力还原 XXTEA 密钥（171 万候选） | 方向错误：APK 内的加密 Lua 是死数据，线上用的是热更资源 |
| 改 hosts / iptables 把官方域名指到本地 | 未 root 做不到 |
| 服务端列表用官方加密格式下发 | 不需要：直接内存改 Lua 更简单 |
| 只把 `port`/`proxyport` 都改成 LoginGate 端口 | 建角能过、进游戏必超时（见 §8） |
| 调 `HpPlayBase` 提升回血 | 被 `Health_Recover=0` 门控，无效 |
| SQL Server 跑在 WSL 里 | NAT 会静默回收长连接，DBServer 不重连 → 建角/查角随机失败 |

---

## 12. 资产清单

| 资产 | 路径 | 说明 |
|---|---|---|
| **Lua 明文全集** | `D:\asdk\luadump\` | 578 个文件 / 7.2 MB，全部 mod 脚本 |
| 客户端解包源码 | `D:\asdk\repack\src\` | apktool 解码 + 全部补丁 |
| 当前可用 APK | `D:\asdk\repack\client-gadget-v14.apk` | 过实名 + 服务器重定向 + 游戏网关 7110 |
| APK 版本链 | `client-gadget-v1…v14.apk` | 每版对应一次改动 |
| Frida 脚本集 | `working\996-local\tools\*.js` | 30+ 个：密钥抓取、内存扫描、Lua dump、连接重定向 |
| 逆向辅助脚本 | 同上 `*.py` | xxtea 系列、apk 深检、so 搜索 |
| 真机截图 | `working\996-local\docs\phone-01…62.png` | 全流程证据 |
| 抓包样本 | `docs\ResModlist.txt_143097`、`docs\ResServerlist.txt_212342` | 官方加密原文 |
| 库备份 | `D:\asdk\sqlbackup_box.bak` | 604 KB，可还原 |
| SQL 安装介质 | `D:\asdk\sqlmedia\SQLEXPR_x64_CHS.exe` | 718 MB |
| 配置备份 | 服务端目录下 `*.dshbak`、`!setup.txt.dshbak2` | 改动前原件 |

---

## 12.5 PC 端逆向进展（2026-11-05 15:20，未完成）

官方包 `downloads\996-engine\client-pc.rar` 内含两套 PC 客户端：Cocos 版（780 KB 启动器）与
**Delphi 版（124 MB，正式端）**。服务端是 Delphi 引擎，配套的是后者。

### 结构与关键事实

```
官方展示.exe   9.9 MB   启动器壳（32 位 Delphi）
官方展示.dat  34 MB     加密载荷，熵 8.00（完全加密，静态无解）
单机登录器配置器/  MakeLauncher.exe + gamelist.txt + 单机测试.exe/.dat + patch.zip ...
```

| 项 | 结论 |
|---|---|
| 管理员要求 | 清单里 `requireAdministrator`；改成 `asInvoker` 后可普通权限运行（Frida 才能附加） |
| 载荷运行位置 | 解密后映射在 **exe 自己的地址空间，基址 0x400000，约 24 MB** |
| 字符串编码 | 全部 **UTF-16**（不是 GBK） |
| 网络行为 | 只发一个请求：`GET http://cdnwd.dhsf.xqhuyu.com/client/RemoteConfig/CrossPC/version.dat` |
| `version.dat` | 940 字节，`;++++JCode----` 头 + base64 行；用 curl 可直接下载 |
| `gamelist.txt` | 明文，格式 `编号=分组\|标题\|名称\|IP\|端口\|展开\|微端URL`，默认 `127.0.0.1\|7000` |

### 定位到的校验代码（载荷基址 0x400000）

```
0x638DD2  mov byte ptr [ebx+0x179], 1     构造函数把标志默认置 1
0x63FF4C  mov byte ptr [eax+0x179], dl    setter，dl = 校验结果
0xA875FF  cmp byte ptr [eax+0x179], 0     判定点 #1
0xA87620  cmp byte ptr [eax+0x179], 0     判定点 #2（后面接 "列表被劫持" 提示）
0xA869DC  cmp dword ptr [ebp+0xC], 0x58   错误码分支（显示 "获取区服列表异常！code=%d"）
```

### 已验证有效的运行时补丁

在 `0xA87620` 处把 `[eax+0x179]` 强制写 1（eax 即为对象指针）：

- 效果：界面从 **"获取区服列表失败，可能列表被劫持！"** 变成 **"尝试获取区服列表，请稍等！"**
- 且实测确认 `InternetReadFile` **成功读到 940 字节**
- 说明「劫持判定」这一层已绕过

实现见 `D:\asdk\patch-license4.js`（配合 `run-patch.py` 使用，脚本从进程一启动就每 100 ms 重试挂钩，
必须先于校验生效）。

### 结论（2026-11-05 16:10）：PC 端已打通，且**不需要任何逆向**

**关键**：配套 PC 客户端就在服务端版本包里，以前一直没发现。

```
downloads\996-engine\version-pack.zip
  └── 新3端纯净版\客户端\
        ├── 996M2_Client.exe   1.4 MB   启动器
        ├── game.exe           4.1 MB   游戏本体
        ├── env.json           配置（明文）
        ├── _update.zip        43 MB    启动器运行时
        └── 一堆 DLL（cocos2d / ffmpeg / curl ...）
```

解包后直接运行 `996M2_Client.exe` → 启动器显示线路「工具测试服1区」→ 点启动 → **直接进游戏**。

**为什么开箱即用**：官方 modlist 里的服务器列表本身就是指向本机：

```json
// modlist: http://list.dhsf.xqhuyu.com/testmodlist/modlist_2002397226_1.txt  (明文 JSON)
"modData":[{"id":"mod_fgcq","srvlist":"https://list.dhsf.xqhuyu.com/testserverlist/serverlist_2002397226_1.txt"}]

// serverlist  (明文 JSON)
"serverData":[{"port":"7000","srvip":"127.0.0.1","srvname":"工具测试服1区","state":"3"}]
```

`srvip=127.0.0.1`、`port=7000` —— 正是我们的 LoginGate；进游戏后连 RunGate 7110，也是我们的。

**验证证据（2026-11-05 16:09）**：

```
TCP 127.0.0.1:51254 → 127.0.0.1:7110  ESTABLISHED  pid=26384
M2Server: 消息记录:老霍[3 345:342] -> 5277,0,0,0,0,[...]
游戏画面：角色「老霍」在盟重省 345:342，HP 18/19，等级 1，FPS 60
```

### 之前走的弯路（保留记录，供后续参考）

早期用的是 `downloads\996-engine\client-pc.rar` 里的 **Delphi 版**演示客户端
（`官方展示.exe`，Build 20230378，2023 年构建），它与 2025-08 的服务端引擎**协议不匹配**：

- 状态检测正常：`55 AA 55 AA ...` 36 字节包收发正常
- 登录连接异常：客户端首包只发 `0x00` 一个字节，网关判为非法包直接断开
  （客户端显示 `服务器已断开连接 Code: 0` / `10053`）

排查过程中确认过的结论（都已验证，不必重查）：

| 结论 | 依据 |
|---|---|
| 不是端口问题 | 7000 连通、心跳正常 |
| 不是账号问题 | `box` 库无账号表，DBServer 不校验密码 |
| 不是授权问题 | `官方展示.exe` 无授权校验，`单机测试.exe` 才有 `Key.lic` 校验（code=77） |
| 是客户端版本问题 | 2023 客户端 vs 2025 服务端，登录封包格式不同 |

### 踩到的坑（PC 端）

| 现象 | 原因 |
|---|---|
| 启动器要求管理员，`subprocess` 启动报 WinError 740 | 清单里有 `requireAdministrator`；改成 `asInvoker` 才能注入，但**原生 Delphi 客户端会因此静默退出**（需要管理员初始化） |
| `frida.attach` 报 `VirtualAllocEx returned 0x5` | Delphi 版游戏本体有内存保护（能 `taskkill` 但无法注入）；**Cocos 版没有这个保护** |
| 自绘登录框敲不进字 | 登录框是 owner-drawn（`TFrmMain` 无子窗口），`SendInput`/`keybd_event` 均无效，只能人工输入 |
| LoginGate 改端口无效 | `Config.ini` 的 `GatePort` 和命令行参数都被忽略，端口固定 7000 |

### 服务端包内也没有配套 PC 客户端（旧结论，已作废）

~~我查了整个 server 目录，只有 MirServer、ServerPVP.exe、GUI编辑器.exe 这些服务端工具，
没有任何 PC 客户端文件。~~

**已作废**：客户端在 `downloads\996-engine\version-pack.zip` 的 `新3端纯净版\客户端\` 里，
不在 server 工作目录里，当时只查了工作目录。

### 复现命令

```powershell
# 1) 复制配置器并去掉管理员清单
python D:\asdk\patch-manifest.py          # 生成 test_noadmin.exe（等长替换为 asInvoker）
copy 单机测试.dat test_noadmin.dat         # 载荷需同名

# 2) 带补丁运行并截图
python D:\asdk\run-patch.py test_noadmin.exe D:\asdk\patch-license4.js 30 D:\asdk\shotc
```

---

## 13. 登录机制问答（重要，交给接手方）

**问：登录时可以随便填账号密码吗？**

**答：不能。** 登录分两层：

1. **SDK 登录（客户端原生 `PasswordLoginActivity`）** —— 走 **996 官方 API（`iss: apiv2`）在线校验**，
   校验通过后下发 **JWT**。实测抓到的 token payload：

   ```json
   {"sub":"1757008192","sub_source":"996","sdk_gameid":212342,"idcard":1,"iss":"apiv2",
    "pwd":"Co9FkvQ+095d1Th/qT7TFhBc/d/2jdYw...","exp":1794459823,"iat":1793855023,
    "refresh_exp":1794459823,"dId":"c59c0cabd17af741697a247ec760e24c","jti":"e7F1l0Q9s8xe8kC6"}
   ```

   账号密码错 → 官方接口拒绝 → 拿不到 userID → 进不到游戏。所以当前必须用真实可用的
   996 平台账号（`zq996b`）。

2. **游戏服登录（LoginGate/DBServer）** —— **只解析 token 里的 userID，不校验签名**。
   服务端日志里的 `CheckAccount Msg 1757008192/...` 与 `sLoginID 1757008192` 就是这个值，
   角色表的 `FLD_ACCOUNT` 也等于它。

**推论（对后续工作有用）**：

- 官方真服会校验 token 签名，但**自建服务端不会**——所以只要能绕过客户端 SDK 登录那一层，
  用任意 userID 都能进自建服。
- 绕过 SDK 的可行点：hook/替换 `GN_onUserIDUpdated` 的入参（Lua 侧 `16_47491.lua:597`
  的 `NativeBridgeManager:GN_onUserIDUpdated`），或直接伪造 userID 缓存。
- 登录页有「免密登录」入口，通常复用已缓存的 token —— 一次成功登录后可免输密码重进。
- 结论：**目前需要真实账号；若要做完全离线客户端，必须在客户端侧伪造 userID，而不是改服务端。**

---

## 14. 给接手 agent 的行动建议（按优先级）

1. **先读 §9**，用只读方式（每 5 秒读 DB 的 HP）确认掉血速率，坐实饥饿假设
2. 确认后再决定修复点：建角初始化饥饿 / GM `@Hunger` / 修正 `Health_Recover`
3. 若要做完全离线：按 §13 推论在客户端伪造 userID，去掉对 996 官方 API 的依赖
4. 任何改动前先备份（现有备份命名规范：`原文件名.dshbak` / `.dshbak2`）
5. 改服务端配置后必须按 §2.3 顺序重启对应进程；改 APK 按 §10 重打包
6. **不要碰 Java bridge**，不要试图在 WSL 里跑 SQL Server，不要再暴力爆破 XXTEA
