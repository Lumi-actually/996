local RemoteProxy = requireProxy( "RemoteProxy" )
local ItemTipsProxy   = class( "ItemTipsProxy", RemoteProxy )
ItemTipsProxy.NAME = global.ProxyTable.ItemTipsProxy

--调用场景
ItemTipsProxy.posType =
{
    from_guild_storage_bagLayer     = 1,   --行会仓库中的背包
    from_guild_storageLayer         = 2,   --行会仓库中的仓库
}

function ItemTipsProxy:ctor()

    self._newSuitConfig = {}    --新的套装属性表数据

    ItemTipsProxy.super.ctor(self)
end

function ItemTipsProxy:onRegister()
    ItemTipsProxy.super.onRegister( self )
end

function ItemTipsProxy:onRegister()
    ItemTipsProxy.super.onRegister( self )
end

function ItemTipsProxy:LoadConfig()
    local fileName = "cfg_suitex.lua"
    if global.FileUtilCtl:isFileExist("scripts/game_config/" .. fileName) then
        local newConfig = requireGameConfig(fileName)
        for _, v in ipairs(newConfig) do
            self._newSuitConfig[v.suitid] = self._newSuitConfig[v.suitid] or {}
            table.insert(self._newSuitConfig[v.suitid], v)
        end
    end
end

-- 获取新的套装属性表数据
function ItemTipsProxy:GetNewSuitConfigById( suitid )
    return self._newSuitConfig[suitid] or {}
end

-- 自定义属性映射att表属性ID
--[[    cusid  自定义id
        mappingid 映射id
        type 类型(0=数值 1=百分比 2=万分比)
--]]
function ItemTipsProxy:LoadCustAbilConfig()
    local GameConfigMgrProxy = global.Facade:retrieveProxy(global.ProxyTable.GameConfigMgrProxy)
    local config = GameConfigMgrProxy:getConfigByKey("cfg_cusabilmapping") or {}
    
    self._custAbilConfig = config
    self._custAbilMap = {}
    for i = 1, #config do
        if config[i] and next(config[i]) then
            local custId = config[i].cusid 
            if custId then 
                self._custAbilMap[custId] = {id = config[i].mappingid, type = config[i].type, showCustomName = config[i].showcustname == 1}
            end
        end
    end
end


function ItemTipsProxy:GetCustAbilMap()
    return self._custAbilMap or {}
end

return ItemTipsProxy
