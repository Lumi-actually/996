local CustomCache = class("CustomCache")
local Queue = requireUtil( "queue" )

function CustomCache:ctor()
    self._sfxCache = {}
    self._nodeCache = nil
    self._imageCache = {}
end

function CustomCache:resetWidget(node)
    node:retain()
    if node:getParent() then 
        node:removeFromParent()
    end
    node:setScale(1)
    node:setName("")
    node:setTag(-1)
    node:setPosition(cc.p(0,0))
    node:setAnchorPoint(cc.p(0.5,0.5))
    node:setOpacity(255)
    node:setVisible(true)
end

function CustomCache:GetImage(path)
    if not path or (path == "") then 
        return nil
    end 
    if not self._imageCache[path] then
        self._imageCache[path] = Queue.new()
    end
    local img = nil
    if self._imageCache[path]:size() == 0 then 
        img = ccui.ImageView:create(path)
        img._CachePath = path
    else
        img = self._imageCache[path]:pop()
        img:autorelease()
        img:removeAllChildren()
    end
    return img
end

function CustomCache:RmImage(img)
    local path = img._CachePath
    if self._imageCache[path] then 
        if self._imageCache[path]:size() >= 10 then
            if img:getParent() then 
                img:removeFromParent()
            end
        else
            self:resetWidget(img)
            self._imageCache[path]:push(img)
        end 
    end
end

function CustomCache:GetSFXAnim(id)
    if not id then 
        return nil
    end 
    if not self._sfxCache[id] then
        self._sfxCache[id] = Queue.new()
    end
    local sfx = nil
    if self._sfxCache[id]:size() == 0 then 
        sfx = global.FrameAnimManager:CreateSFXAnim(id)
        sfx._ChacheId = id
    else
        sfx = self._sfxCache[id]:pop()
        sfx:autorelease()
        sfx:removeAllChildren()
    end
    return sfx
end
function CustomCache:RmSFXAnim(sfx)
    local id = sfx._ChacheId
    sfx:Stop()
    sfx:SetAnimEventCallback(nil)
    if self._sfxCache[id] then 
        if  self._sfxCache[id]:size() >= 10 then
            if sfx:getParent() then 
                sfx:removeFromParent()
            end
        else
            self:resetWidget(sfx)
            self._sfxCache[id]:push(sfx)
        end 
    end
end

function CustomCache:GetNode()
    if not self._nodeCache then
        self._nodeCache = Queue.new()
    end
    local node = nil
    if self._nodeCache:size() == 0 then 
        node = cc.Node:create()
    else
        node = self._nodeCache:pop()
        node:autorelease()
        node:removeAllChildren()
    end
    return node
end

function CustomCache:RmNode(node)
    node:setContentSize(0,0)
    if self._nodeCache then 
        if  self._nodeCache:size() >= 300 then
            if node:getParent() then 
                node:removeFromParent()
            end
        else
            self:resetWidget(node)
            self._nodeCache:push(node)
        end 
    end
end

function CustomCache:Clear()
    local node
    for k,vec in pairs(self._imageCache) do
        for i = 1,vec:size() do
            node = vec:pop()
            node:release()
        end
    end
    self._imageCache = {}

    local sfx = nil
    for k,vec in pairs(self._sfxCache) do
        for i = 1,vec:size() do
            node = vec:pop()
            node:release()
        end
    end
    self._sfxCache = {}
    if self._nodeCache then 
        for i = 1,self._nodeCache:size() do
            node = self._nodeCache:pop()
            node:release()
        end
    end
    self._nodeCache = nil
end

return CustomCache
