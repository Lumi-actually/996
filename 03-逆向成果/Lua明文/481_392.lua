local RemoteProxy    = requireProxy("RemoteProxy")
local QuickUseProxy = class("QuickUseProxy", RemoteProxy)
QuickUseProxy.NAME = global.ProxyTable.QuickUseProxy
require("GUIData/QuickUseData")

--数据全部来自背包
function QuickUseProxy:ctor()
    QuickUseProxy.super.ctor(self)
    if QuickUseData.Init then 
        QuickUseData.Init()
    end
end

return QuickUseProxy