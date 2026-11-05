local DebugProxy   = requireProxy( "DebugProxy" )
local ModelConfigProxy = class( "ModelConfigProxy", DebugProxy )
ModelConfigProxy.NAME   = global.ProxyTable.ModelConfigProxy


function ModelConfigProxy:ctor()
    ModelConfigProxy.super.ctor(self)

    self._config = {}
    self._atlasSplitConfigs = {}
end


function ModelConfigProxy:GetConfig( id )
    return self._config[id]
end

function ModelConfigProxy:RetrieveConfig()
    return self._config
end

function ModelConfigProxy:Reload()
    self._config = {}
    self._atlasSplitConfigs = {}

    self:ReloadConfig()
    self:LoadSplitConfigs()
end

function ModelConfigProxy:LoadConfig()

    local act_interval_map = {
        [0]  = "idle_interval",
        [1]  = "walk_interval",
        [2]  = "attack_interval",
        [3]  = "magic_interval",
        [4]  = "die_interval",
        [5]  = "run_interval",

        [7]  = "stuck_interval",
        [8]  = "sitdown_interval",
        [9]  = "born_interval",
        [10] = "mining_interval",
        [11] = "ready_interval",
        [12] = "changeshape_interval",
        [13] = "die_interval",

        [17] = "idle_interval",
        [18] = "walk_interval",
        [19] = "run_interval",
        [20] = "stuck_interval",
        [21] = "die_interval",

        [22] = "magic_interval",
        [23] = "magic_interval",
        [24] = "magic_interval",
        [25] = "magic_interval",
        [26] = "magic_interval",
        [27] = "magic_interval",
        [28] = "magic_interval",
        [29] = "magic_interval",
        [30] = "magic_interval",
        [31] = "magic_interval",
        [32] = "magic_interval",
        [33] = "magic_interval",
        [34] = "magic_interval",

        [41] = "run_interval",
        [42] = "walk_interval",
        [43] = "attack_interval",
        [44] = "attack_interval",
        [45] = "attack_interval",
        [46] = "attack_interval",
        [47] = "attack_interval",
        [48] = "magic_interval",
        [49] = "magic_interval",
        [50] = "attack_interval",
        [51] = "attack_interval",
    }

    local empty_key = {
        "idle_interval",
        "walk_interval",
        "attack_interval",
        "magic_interval",
        "die_interval",
        "run_interval",
        "stuck_interval",
        "sitdown_interval",
        "born_interval",
        "mining_interval",
        "ready_interval",
        "changeshape_interval",
        "enlarge",
        "hud_top",
    }

    local function fixItem(value)
        for i, v in ipairs(empty_key) do
            if value[v] == 0 then
                value[v] = nil
            end
        end

        value.dir      = tonumber(value.dir) or 8
        value.interval = {}
        value.frame    = {}
        for act = 0, global.MMO.ANIM_COUNT - 1 do
            value.interval[act] = tonumber(value[act_interval_map[act]]) or global.MMO.ANIM_DEFAULT_INTERVAL
        end

        if global.isWinPlayMode then
            value.offsetx = value.pc_offsetx or value.offsetx
            value.offsety = value.pc_offsety or value.offsety
            value.enlarge = value.pc_enlarge or value.enlarge
        end
        return value
    end

    -- 先加载996基础配置
    local config = requireGameConfig("cfg_model_info_996")
    for _, value in pairs( config ) do
        self._config[GetFrameAnimConfigID( value.id, value.sex, value.type )] = fixItem(value)
    end

    -- 
    local config = requireGameConfig("cfg_model_info")
    for _, value in pairs( config ) do
        self._config[GetFrameAnimConfigID( value.id, value.sex, value.type )] = fixItem(value)
    end
end

function ModelConfigProxy:ReloadConfig()
    package.loaded["game_config/cfg_model_info_996"] = nil
    package.loaded["game_config/cfg_model_info"] = nil
    self:LoadConfig()
end

function ModelConfigProxy:GetSplitAtlas( animID, act )
    local configs = self._atlasSplitConfigs[animID]
    if not configs then
        return nil
    end
    return configs[act]
end

function ModelConfigProxy:LoadSplitConfigs()
    local animType  = nil
    local sex       = nil
    local rawAnimID = nil
    local act       = nil
    local count     = nil

    local function LoadConfig(filePath)
        if global.FileUtilCtl:isFileExist(filePath) then
            local animID    = nil
            local function callback(dataTable)
                if #dataTable <= 0 then
                    return nil
                end
                
                animType    = tonumber(dataTable[1])
                rawAnimID   = tonumber(dataTable[2])
                sex         = tonumber(dataTable[3])
                act         = tonumber(dataTable[4])
                count       = tonumber(dataTable[5])
    
                if nil == animType or nil == rawAnimID or nil == sex or nil == sex or nil == act or nil == count then
                    return nil
                end
    
                animID      = GetFrameAnimConfigID(rawAnimID, sex, animType)
                if self._atlasSplitConfigs[animID] == nil then self._atlasSplitConfigs[animID] = {} end
                self._atlasSplitConfigs[animID][act] = count
            end
            LoadTxt(filePath, ",", callback)
        end
    end
    self._atlasSplitConfigs = {}
    LoadConfig("data_config/ModelAtlasSplitConfigs_996.txt")
    LoadConfig("data_config/ModelAtlasSplitConfigs.txt")
    LoadConfig("data_config/modelAtlasSplitConfigs_996.txt")
    LoadConfig("data_config/modelAtlasSplitConfigs.txt")
end

function ModelConfigProxy:onRegister()
    ModelConfigProxy.super.onRegister(self)
end

function ModelConfigProxy:RequestUpdateConfig()
    LuaSendMsg(global.MsgType.MSG_CS_UPDATE_MODEL_CONFIG)
end

return ModelConfigProxy
