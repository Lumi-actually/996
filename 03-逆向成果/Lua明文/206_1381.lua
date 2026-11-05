local BaseLayer = requireLayerUI("BaseLayer")
local NoticeLayer = class("NoticeLayer", BaseLayer)

function NoticeLayer:ctor()
    NoticeLayer.super.ctor(self)
end

function NoticeLayer.create()
    local layout = NoticeLayer.new()
    if layout:Init() then
        return layout
    end
    return nil
end

function NoticeLayer:Init()
    self.ui = ui_delegate(self)
    return true
end

function NoticeLayer:InitGUI()
    SL:RequireFile(UIConst.LUAFile.LUA_FILE_NOTICE)
    Notice.main()

    self._root = self.ui.Node_notice
end

function NoticeLayer:OnClose(data)
    Notice.close(data)
end

function NoticeLayer:OnAddChild(data)
    local layer = data.child
    local size = layer:getContentSize()
    local anr = layer:getAnchorPoint()
    local pos = layer.getWorldPosition and layer:getWorldPosition() or cc.p(layer:getPosition())

    local viewSize = global.Director:getVisibleSize()
    local ww = viewSize.width
    local hh = viewSize.height

    local x = math.min(math.max(0, pos.x), ww)
    local y = math.min(math.max(0, pos.y), hh)

    local maxX = x + size.width  * (1 - anr.x)
    local maxY = y + size.height * (1 - anr.y)
    
    x = maxX > ww and (x - maxX + ww) or x
    y = maxY > hh and (y - maxY + hh) or y
    layer:setPosition(cc.p(x, y))

    self._root:addChild(layer)
end

return NoticeLayer
