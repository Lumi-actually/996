local DebugProxy    = requireProxy( "DebugProxy" )
local DataRePortProxy    = class( "DataRePortProxy", DebugProxy )
DataRePortProxy.NAME = global.ProxyTable.DataRePortProxy

local cjson = require("cjson")

local simpleEncryKey = {50,30,20,43}
local stringToByteSimpleDecry = function(byteStr)
    local bytes = cjson.decode(byteStr)
    local newBytes = {}
    local i = 1
    local str = ""
    for k,v in ipairs(bytes) do
        newBytes[k] = v-simpleEncryKey[i]
        if i > #simpleEncryKey then
            i = 1
        end
    end
    local str = string.char(unpack(newBytes))
    return str
end

-- 获取系统版本
local function getWindownVersion()
    if getWindowsVersion then
        local windowVersion = getWindowsVersion()
        local versions = string.split(windowVersion,"_")
        local majorVer = tonumber(versions[1])
        local minorVer = tonumber(versions[2])
        local buildNum = tonumber(versions[3])
        if majorVer >= 10 then
            if buildNum >= 22000 then
                return "Win11"
            end
            return "Win10"
        elseif majorVer >= 6 then
            if minorVer >= 3 then
                return "Win8.1"
            elseif minorVer >= 2 then
                return "Win8"
            elseif minorVer >= 1 then
                return "Win7"
            end
        elseif majorVer >= 5 then            
            return "WinXP"
        end
    end
    return "windows"
end

function DataRePortProxy:ctor()
    DataRePortProxy.super.ctor(self)
    self._infoData = nil
    self._login_game_time = -1
    self._game_duration_schedule_id = -1
    self._is_duration = true
    self:InitData()
end

-- 初始化数据
function DataRePortProxy:InitData()
     local isMac = global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac"
    if not (SL:GetValue("IS_PC_OPER_MODE") or isMac) then
        return
    end

    local LuaBridgeCtl = LuaBridgeCtl:Inst()
    if not LuaBridgeCtl or LuaBridgeCtl:GetModulesSwitch( global.MMO.Modules_Index_Protobuf_Pbc ) ~= 1 then
        return
    end

    -- 读取launch位置的userdata数据
    UserData:Cleanup()
    UserData:setVersionPath("")

    local userData  = UserData:new("data_report")
    local deviceID  = userData:getStringForKey("id")

    -- 统一文件夹//localUserData
    self:InitUserData()
    if not deviceID or deviceID == "" then
        return
    end
    deviceID = stringToByteSimpleDecry(deviceID)

    local appid = global.L_GameEnvManager:GetEnvDataByKey("sdkAppid")
    if not appid then
        return
    end

    local secretKey = global.L_GameEnvManager:GetEnvDataByKey("sdkAppkey")
    if not secretKey then
        return
    end

    local channelid = global.L_GameEnvManager:GetEnvDataByKey("sdkChannel")
    if not channelid then
        return
    end

    local boxID = nil
    if global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1 then
        local boxBoxGameID  = global.L_ModuleManager:GetCurrentModule():GetOperID() or ""
        local boxChannelID  = global.L_GameEnvManager:GetChannelID() or ""
        boxID               = boxBoxGameID .. ":" .. boxChannelID
    end

    self._infoData = {
        ["device"] = {
            type = "pc",
            id = deviceID,
            width = getWindowWidth and getWindowWidth() or 1036,
            height = getWindowHeight and getWindowHeight() or 640,
            model = "pc",
            os = getWindownVersion()
        },
        appid = appid,
        boxid = boxID,
        channel = channelid or "",
        sdk_ver = "1.0.0",
        app_ver = global.L_GameEnvManager:GetAPKVersionName() or "",
        net_type = "UNKNOWN",
    }

end

function DataRePortProxy:GetDeviceInfo()
    return self._infoData or {}
end

--统一文件夹//localUserData
function DataRePortProxy:InitUserData()
    local module        = global.L_ModuleManager:GetCurrentModule()
    local modulePath    = module.GetSubModPath and module:GetSubModPath() or module:GetStabPath()
    local moduleGameEnv = module:GetGameEnv()
    local storagePath   = string.format("%s%s", modulePath, global.MMO.LOCAL_USERDATA)  
    local WritablePath  = global.FileUtilCtl:getWritablePath()
    -- 文件夹创建
    local modulePathDir = WritablePath .. modulePath
    if not global.FileUtilCtl:isDirectoryExist(modulePathDir) then
        global.FileUtilCtl:createDirectory(modulePathDir)
    end
    if not global.FileUtilCtl:isDirectoryExist(WritablePath .. storagePath) then
        global.FileUtilCtl:createDirectory(WritablePath .. storagePath)
    end
    UserData:Cleanup()
    UserData:setVersionPath(storagePath)
end

function DataRePortProxy:CheckValid()
    if not self._infoData then
        return false
    end

     local isMac = global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac"
    if not (SL:GetValue("IS_PC_OPER_MODE") or isMac) then
        return false
    end

    return true
end

-- 用户登录
function DataRePortProxy:UserLogin()
    if not self:CheckValid() then
        return
    end

    local dataParam = {
        event = {time = os.time(), name = "user_login", type = "track"}
    }

    table.merge(dataParam, self._infoData)
    
    return string.urlencode(cjson.encode(dataParam))
end

-- 用户注册
function DataRePortProxy:UserRegister()
    if not self:CheckValid() then
        return
    end

    local dataParam = {
        event = {time = os.time(), name = "user_register", type = "track"}
    }

    table.merge(dataParam, self._infoData)

    return string.urlencode(cjson.encode(dataParam))
end

-- 创建订单(预支付)
function DataRePortProxy:PrePay()
    if not self:CheckValid() then
        return
    end

    local dataParam = {
        event = {time = os.time(), name = "prepay", type = "track"},
        channel_report = global.L_GameEnvManager:GetEnvDataByKey("channelReportKey")
    }

    table.merge(dataParam, self._infoData)

    return string.urlencode(cjson.encode(dataParam))
end

-- 游戏时长上报状态， 暂停/恢复上报,  断网或者小退就不上报
function DataRePortProxy:SetGameDuration( state )
    self._is_duration = state
end

-- 进入游戏 (直接上报ali)
function DataRePortProxy:GameLogin(data)
    if not self:CheckValid() then
        return
    end

    if not global.L_DataRePort then
        return
    end

    local LoginProxy    = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local serviceVer    = " " .. LoginProxy:GetServiceVer()
    self._login_game_time = os.time()
    local dataParam = {
        event       = {time = os.time(), name = "game_login", type = "track"},
        user        = {id = tostring(data.userId)},
        properities = {
            servid      = tostring(data.zoneId),
            server_name = tostring(data.zoneName),
            role_id     = tostring(data.roleId),
            role_name   = data.roleName,
            role_level  = data.roleLevel,
            job_id      = tostring(data.roleJobId),
            job_name    = tostring(data.roleJobName),
            server_version = string.gsub(serviceVer, "^%S*(.-).%d$", "%1"),
        }
    }

    
    global.L_DataRePort:SendRePortData(dataParam)

    self._game_duration_schedule_id = Schedule(function()
        if self._is_duration then
            self:PlayGame({isScheduleFunc=true})
            if self._login_game_time > 0 then
                self._login_game_time = os.time()
            end
        end
    end, 5 * 60)
end

--游戏时长 (直接上报ali)
function DataRePortProxy:PlayGame(data)
    if not self:CheckValid() then
        return
    end

    if not global.L_DataRePort then
        return
    end

    if self._login_game_time < 0 then
        return
    end

    local AuthProxy         = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local loginProxy        = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local PlayerProperty    = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local AutoProxy         = global.Facade:retrieveProxy( global.ProxyTable.AutoProxy )
    local MapProxy          = global.Facade:retrieveProxy( global.ProxyTable.MapProxy )
    local diffTimes         = os.time() - self._login_game_time
    local isAfk             = 0
    local mapId             = MapProxy and MapProxy:GetMapID() or ""
    if AutoProxy and AutoProxy:IsAFKState() then
        isAfk = 1
    end

    if not data or not data.isScheduleFunc then
        UnSchedule(self._game_duration_schedule_id)
        self._login_game_time = -1
    end
    
    local PShowAttType = GUIFunction:PShowAttType()
    local dataParam = {
        event       = {time = os.time(), name = "game_duration", type = "track"},
        user        = {id = tostring(AuthProxy:GetUID())},
        properities = {
            servid      = tostring(loginProxy:GetSelectedServerId()),
            server_name = tostring(loginProxy:GetSelectedServerName()),
            role_id     = tostring(PlayerProperty:GetRoleUID()),
            role_name   = PlayerProperty:GetName(),
            role_level  = PlayerProperty:GetRoleLevel(),
            times       = diffTimes,
            duration    = diffTimes,
            job_id      = tostring(PlayerProperty:GetRoleJob()),
            job_name    = tostring(PlayerProperty:GetRoleJobName()),
            role_att    = PlayerProperty:GetRoleAttByAttType(PShowAttType.Max_ATK) or 0,
            main_servid = tostring(loginProxy:GetMainSelectedServerId()) or tostring(loginProxy:GetSelectedServerId()),
            main_server_name = tostring(loginProxy:GetMainSelectedServerName()) or tostring(loginProxy:GetSelectedServerName()),
            is_afk = isAfk,
            map_id = mapId,
        }
    }
    global.L_DataRePort:SendRePortData(dataParam)
end

-- 创建角色 (直接上报ali)
function DataRePortProxy:CreateRole(data)
    if not self:CheckValid() then
        return
    end

    if not global.L_DataRePort then
        return
    end

    local dataParam = {
        event       = {time = os.time(), name = "create_role", type = "track"},
        user        = {id = tostring(data.userId)},
        properities = {
            servid      = tostring(data.zoneId),
            server_name = tostring(data.zoneName),
            role_id     = tostring(data.roleId),
            role_name   = data.roleName,
            role_level  = data.roleLevel,
            job_id      = tostring(data.roleJobId),
            job_name    = tostring(data.roleJobName)
        } 
    }
    global.L_DataRePort:SendRePortData(dataParam)
end

-- 任务数据 (直接上报ali)
function DataRePortProxy:RoleTask(data)
    if not self:CheckValid() then
        return
    end

    if not data or not data.taskid then
        return
    end
    
    local starTime = 0
    local endTime = 0
    if data.flag == 0 or data.flag == 2 or data.flag == 3 then
        endTime = os.time()
    else
        return
    end

    if not global.L_DataRePort then
        return
    end

    local taskName          = ""
    local headData          = data.oldHead or data.head
    if headData and headData.content then
        taskName = headData.content
    end
    taskName                = string.gsub(taskName,"<font .->","")  --替换<font *****>
    taskName                = string.gsub(taskName,"</font>","")    --替换</font>

    local AuthProxy         = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local loginProxy        = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local PlayerProperty    = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local dataParam = {
        event       = {time = os.time(), name = "role_task", type = "track"},
        user        = {id = tostring(AuthProxy:GetUID())},
        properities = {
            servid      = tostring(loginProxy:GetSelectedServerId()),
            server_name = tostring(loginProxy:GetSelectedServerName()),
            role_id     = tostring(PlayerProperty:GetRoleUID()),
            role_name   = PlayerProperty:GetName(),
            role_level  = PlayerProperty:GetRoleLevel(),
            task_id     = data.taskid,
            task_name   = taskName,
            start_time  = starTime,
            end_time    = endTime,
            flag        = data.flag,
        }
    }

    global.L_DataRePort:SendRePortData(dataParam)
end

-- 自定义数据上报 (直接上报ali)
function DataRePortProxy:ReportCustomEvent(data)
    if not self:CheckValid() then
        return
    end

    if not data then
        return
    end

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local dataParam = {
        event       = {time = os.time(), name = data.event_name or "", type = "track"},
        properities = data.map,
        user_id     = tostring(AuthProxy:GetUID()),
    }

    global.L_DataRePort:SendRePortData(dataParam)
end

-- 主界面按钮/图片点击上报
function DataRePortProxy:MainUIClickEvent(data)
    if not self:CheckValid() then
        return
    end

    if not data then
        return
    end
    
    local AuthProxy         = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local loginProxy        = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local PlayerProperty    = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local PShowAttType      = GUIFunction:PShowAttType()
    local dataParam = {
        event       = {time = os.time(), name = "click_xmb", type = "track"},
        user        = {id = tostring(AuthProxy:GetUID())},
        properities = {
            servid      = tostring(loginProxy:GetSelectedServerId()),
            server_name = tostring(loginProxy:GetSelectedServerName()),
            job_id      = tostring(PlayerProperty:GetRoleJob()),
            job_name    = tostring(PlayerProperty:GetRoleJobName()),
            role_id     = tostring(PlayerProperty:GetRoleUID()),
            role_name   = PlayerProperty:GetName(),
            role_level  = PlayerProperty:GetRoleLevel(),
            consumable_grade = PlayerProperty:GetRoleReinLv(),
            role_att    = PlayerProperty:GetRoleAttByAttType(PShowAttType.Max_ATK) or 0,
            main_id     = data.index or "",
            node_id     = data.id or "",
            func_tag    = data.link or "",
        }
    }

    global.L_DataRePort:SendRePortData(dataParam)
end

return DataRePortProxy