local RemoteProxy = requireProxy("RemoteProxy")
local PayProxy = class("PayProxy", RemoteProxy)
PayProxy.NAME = global.ProxyTable.PayProxy

function PayProxy:ctor()
    PayProxy.super.ctor(self)
end

-- 获得道具数量 统一接口
function PayProxy:GetItemCount(itemID, famlilar)
    if not itemID then
        return 0
    end
    
    local count = 0
    if itemID < 100 then
        local MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
        count = MoneyProxy:GetMoneyCountById(itemID, famlilar)
    else
        count = BagData.GetItemCountByIndex(itemID, famlilar)
        count = count + QuickUseData.GetQuickUseItemNum(itemID, famlilar)
    end

    return count
end

return PayProxy