-- avoid memory leak
collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

-- init randomseed
        
local socket = require "socket"
math.randomseed( tonumber(tostring(socket.gettime() * 10000):reverse():sub(1,6)) )

-- init cocos constant
requireLauncher( "init/Cocos2dConstants" )

-- init functions
requireLauncher( "init/functions" )

-- init global
requireLauncher( "config/global" )

-- init util
requireLauncher( "init/util" )

-- init multiVersion
global.L_MultiVersionData = requireLauncher("logic/MultiVersionData")

-- init native bridge manager
global.L_NativeBridgeManager = requireLauncher( "logic/NativeBridgeManager" ):new()

-- init game env manager
global.L_GameEnvManager = requireLauncher( "logic/GameEnvManager" ):new()

-- init module manager
global.L_ModuleManager = requireLauncher( "logic/ModuleManager" ):new()

-- init game layer manager
global.L_GameLayerManager = requireLauncher( "logic/GameLayerManager" ):new()

-- init loading manager
global.L_LoadingBarManager = requireLauncher( "logic/LoadingBarManager" ):new()

-- init loading manager
global.L_LoadingManager = requireLauncher( "logic/LoadingManager" ):new()

-- init loading manager
global.L_LoadingPlayManager = requireLauncher( "logic/LoadingPlayManager" ):new()

-- init system tips manager
global.L_SystemTipsManager = requireLauncher( "logic/SystemTipsManager" ):new()

-- init module choose manager
global.L_ModuleChooseManager = requireLauncher( "logic/ModuleChooseManager" ):new()

global.L_CommonTipsManager = requireLauncher( "logic/CommonTipsManager" ):new()

-- gm assets
global.L_HotUpdateGMAssets = requireLauncher( "logic/HotUpdateGMAssets" ):new()


-------------------------------------------------------------
----- init data report
global.L_DataRePort = requireLauncher("logic/DataRePort"):new()

global.L_GameEnvManager:launch()

