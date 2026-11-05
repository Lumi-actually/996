local RenderTextureManager = class("RenderTextureManager")

local EVENT_AFTER_UPDATE = "director_after_update"
local RenderTextureInfo = require("render/RenderTextureInfo")
local Queue = requireUtil( "queue" )

function RenderTextureManager:ctor()
    self._renderInfos = {}
    self._unUseIDQueue = Queue.new()
    self._updateHandler = cc.EventListenerCustom:create(EVENT_AFTER_UPDATE, handler(self, self.Tick))
    global.EventDispatcher:addEventListenerWithFixedPriority(self._updateHandler, 1)
    --------------RenderTexture部分代码 放在定时器之后执行防止 渲染节点被删了  造成崩溃---------------------------------
end

function RenderTextureManager:destory()
end

function RenderTextureManager:create()
    local _this = RenderTextureManager.new()
    return _this
end

function RenderTextureManager:Cleanup()
    self._renderInfos = {}
    self._unUseIDQueue:clear()
    global.EventDispatcher:removeEventListener(self._updateHandler)
end

function RenderTextureManager:Tick()
    local dt = global.Director:getDeltaTime()
    for id, item in ipairs(self._renderInfos) do
        if not item:IsInvalid() then 
            item:Tick(dt)
        end
    end
end

function RenderTextureManager:AddDrawFuncOnce(data)
    data.count = 1
    data.time = data.time or 0
    return self:AddDrawFunc(data)
end

--{func,time}
function RenderTextureManager:AddDrawFunc(data)
    if not data then 
        return nil
    end
    local id 
    data.count = data.count or -1
    data.time = data.time or 0
    if self._unUseIDQueue:size() > 0 then 
        id =  self._unUseIDQueue:pop()
        data.id = id
        self._renderInfos[id]:Reset(data)
        return id
    end
    id = #self._renderInfos + 1
    data.id = id
    self._renderInfos[id] = RenderTextureInfo.new(data)
    return id
end

function RenderTextureManager:RmvDrawFunc(id)
    self._unUseIDQueue:push(id)
    self._renderInfos[id]:SetInvalid(true)
end

return RenderTextureManager