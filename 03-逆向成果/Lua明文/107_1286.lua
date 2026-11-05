local CacheWidget = requireUtil("CacheWidget")
local CostItemCell = class("CostItemCell", CacheWidget)

function CostItemCell:ctor()
    CostItemCell.super.ctor(self)
end

function CostItemCell:create(data)
    local layer = CostItemCell.new()
    if layer:Init(data) then
        return layer
    end
    return nil
end

function CostItemCell:Init(data)
    self._itemClass = require(UIConst.LUAFile.LUA_FILE_COSTITEM).new(self, data)

    self:Cleanup()
    -- data update
    self:Update(data)

    return true
end

function CostItemCell:OnEnter()
    -- addTo manager
    global.Facade:sendNotification(global.NoticeTable.AddCostItemCell, self)
end

function CostItemCell:OnExit()
    -- remove
    global.Facade:sendNotification(global.NoticeTable.RmvCostItemCell, self)
end

function CostItemCell:Cleanup()
    self._data = nil

    self:setAnchorPoint({x = 0.5, y = 0.5})
    self:setPositionX(0)
    self:setPositionY(0)
end

function CostItemCell:Update(data)
    self._data = data or {}

    self._notRefresh = self._data and self._data.notRefesh
end

function CostItemCell:OnUpdate()
    if self._itemClass and self._itemClass.OnUpdateShow then
        self._itemClass:OnUpdateShow()
    end

end

return CostItemCell
