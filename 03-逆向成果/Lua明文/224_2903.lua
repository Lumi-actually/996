-- 图集类型枚举
local AtlasType = {
    Tiles   = 1,
    SmTiles = 2,
    Objects = 3,
    Max     = 3,
}

local cjson = require("cjson")

-- 各类图集分割配置
local AtlasSplitConfigs = {}
AtlasSplitConfigs[AtlasType.Tiles]   = {}
AtlasSplitConfigs[AtlasType.SmTiles] = {}
AtlasSplitConfigs[AtlasType.Objects] = {}

local function loadSceneConfig(filename)
    if global.FileUtilCtl:isFileExist(filename) then
        local jsonStr  = global.FileUtilCtl:getDataFromFileEx(filename)
        local jsonData = {}
        xpcall(function()
                jsonData = cjson.decode(jsonStr)
            end, 
            function()
                if global.isDebugMode or global.isGMMode then
                    ShowSystemTips(string.format("json文件格式错误: %s", filename))
                end
            end
        )
        for _, v1 in pairs(jsonData) do
            for k2, v2 in pairs(v1) do
                v1[tonumber(k2)] = v2
            end
        end
        for k, v in pairs(jsonData.Tiles) do
            AtlasSplitConfigs[AtlasType.Tiles][k] = v
        end
        for k, v in pairs(jsonData.SmTiles) do
            AtlasSplitConfigs[AtlasType.SmTiles][k] = v
        end
        for k, v in pairs(jsonData.Objects) do
            AtlasSplitConfigs[AtlasType.Objects][k] = v
        end
    end
end
loadSceneConfig("data_config/sceneAtlasSplitConfigs_996.txt")
loadSceneConfig("data_config/sceneAtlasSplitConfigs.txt")


-- 灯光动画偏移
local FrameOffset = {
    [0] = {
        [2723] = cc.p(-53, 110),
    },
    [35] = {
        [2042] = cc.p(-75, 110),
    },
    [12] = {
        [6832] = cc.p(-30, 148),
        [6926] = cc.p(10, 100),
        [6937] = cc.p(-15, 115),
    },
    [17] = {
        [9109] = cc.p(-90, 25)
    },
    [19] = {
        [443] = cc.p(-45, 263),
        -- [443] = cc.p(-50, 110),
        [452] = cc.p(-65, 110),
        [460] = cc.p(-40, 530),
    },
    [20] = {
        [7068] = cc.p(-95, 180),
        [7108] = cc.p(-95, 200),
        [7128] = cc.p(-95, 200),
        [7208] = cc.p(-110, 220),
        [7228] = cc.p(-125, 180),
        [7268] = cc.p(-95, 165),
        [7288] = cc.p(-95, 160),
        [7348] = cc.p(-75, 115),
        [7368] = cc.p(-95, 125),
    },
    [23] = {
        [8895] = cc.p(-40, 65),
        [8901] = cc.p(-5, 200),
        [9110] = cc.p(-15, 65),
    },
}

--有些地图一张obj的尺寸特别大 需要增加屏幕加载的obj高度
local ObjMaxOffsetY = {
    ["sldg"]  = 25,
    ["0"]     = 20,
    ["n0"]    = 20,
    ["3"]     = 20,
    ["n3"]    = 20,
    ["4"]     = 23,
    ["n4"]    = 20,
    ["hero1"] = 20,
}

return {
    AtlasType         = AtlasType,
    AtlasSplitConfigs = AtlasSplitConfigs,
    FrameOffset       = FrameOffset,
    ObjMaxOffsetY     = ObjMaxOffsetY
}

