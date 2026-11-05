local TableViewEx = class("TableViewEx", function() return ccui.Layout:create() end)

function TableViewEx:ctor(data)
    self._tableView = nil
    self._data = nil
end

--[[
    @desc: tableView参数
    --@data: {
        size = cc.size(xx, xx), --视图大小, 必须有
        scrollViewDidScroll = function(view) end, --滚动时点击事件
        cellSizeForTable = function(view, idx) end, --子视图大小 view是tableview, idx是每个子项的索引, 必须有
        tableCellAtIndex = function(view, idx) end, --获取子视图, 必须有
        numberOfCellsInTableView = function(view) end, 子视图数目  返回的个数是tableview的高度/单个子项的高度+1, 必须有
        tableCellTouched = function(view, cell) end, --触摸列表项cell的回调
        direction = 0 or 1 --方向设置0水平 1竖直
    }
    @return: TableViewEx
]]
function TableViewEx.create(data)
    local cell = TableViewEx.new()
    if cell and cell:Init(data) then
        return cell
    end

    return nil
end

function TableViewEx:Init(data)
    if not data.size or not data.cellSizeForTable or not data.tableCellAtIndex or not data.numberOfCellsInTableView then
        return nil
    end
    self._data = data
    self._cColor = cc.c4b(200, 200, 200, 255)
    --@RefType[luaIde#cc.TableView]
    self._tableView = cc.TableView:create(self._data.size or cc.size(100, 66))
    self:addChild(self._tableView)
    --设置滚动方向  SCROLLVIEW_DIRECTION_VERTICAL是垂直滚动   SCROLLVIEW_DIRECTION_HORIZONTAL 是水平滚动
    self._tableView:setDirection(self._data.direction or cc.SCROLLVIEW_DIRECTION_VERTICAL)   
    --竖直从上往下排列  
    self._tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    --设置代理
    self._tableView:setDelegate()
    -- 自定义函数
    self._tableView.scrollToCell = function(tv, index, animated)
        self:scrollToCell(index, animated)
    end
    self:registerScriptHandler()
    return true
end

--添加回调函数
function TableViewEx:registerScriptHandler()
    --滚动时回调 
    self._tableView:registerScriptHandler(
        handler(self, self._data.scrollViewDidScroll or self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL
    )
    --列表项的尺寸
    self._tableView:registerScriptHandler(
        handler(self, self._data.cellSizeForTable or self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX
    )
    --创建列表项  
    self._tableView:registerScriptHandler(
        handler(self, self._data.tableCellAtIndex or self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX
    )
    --列表项的数量
    self._tableView:registerScriptHandler(
        handler(self, self._data.numberOfCellsInTableView or self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW
    )
    --触摸列表项cell的回调
    self._tableView:registerScriptHandler(self._data.tableCellTouched or self.tableCellTouched, cc.TABLECELL_TOUCHED)
    --加载tableView的所有列表数据
    -- self._tableView:reloadData()
end

--滚动时点击事件
function TableViewEx:scrollViewDidScroll(view)

end

--子视图大小 view是tableview, idx是每个子项的索引
function TableViewEx:cellSizeForTable(view, idx)
    return 100, 66
end

--子视图数目  返回的个数是tableview的高度/单个子项的高度+1
function TableViewEx:numberOfCellsInTableView(view)
    return 1
end

--触摸列表项cell的回调
function TableViewEx:tableCellTouched(cell)
    
end

--[[
    往cell里加入的控件不要有裁剪内容的选择项，否则会显示不正确
]]
--获取子视图
function TableViewEx:tableCellAtIndex(view, idx)   
    local index = idx + 1
    local cell = view:dequeueCell()
    if not cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end 

    return cell
end

--@return [luaIde#cc.TableViewCell]
function TableViewEx:cellAtIndex(index)
    return self._tableView:cellAtIndex(index)
end

function TableViewEx:removeCellAtIndex(index)
    self._tableView:removeCellAtIndex(index)
end

function TableViewEx:reloadData()
    self._tableView:reloadData()
end

function TableViewEx:reloadDataEx()
    local oldOffset = self:getContentOffset()
    self._tableView:reloadData()

    local offset = self:getContentOffset()
    local dir = self:getDirection()
    local off1 = dir == cc.SCROLLVIEW_DIRECTION_VERTICAL and oldOffset.y or oldOffset.x
    local off2 = dir == cc.SCROLLVIEW_DIRECTION_VERTICAL and offset.y or offset.x
    if off1 ~= off2 then
        self:setContentOffset(oldOffset)
    end
end

function TableViewEx:getContentOffset()
    return self._tableView:getContentOffset()
end

function TableViewEx:setContentOffset(point, animated)
    return self._tableView:setContentOffset(point, animated)
end

function TableViewEx:getViewSize()
    return self._tableView:getViewSize()
end

function TableViewEx:setViewSize(size)
    return self._tableView:setViewSize(size)
end

function TableViewEx:scrollToCell(index, animated)
    local point = self._tableView:getContentOffset()
    local cell = self._tableView:cellAtIndex(index)
    local size = cc.size(self._data.cellSizeForTable())
    local direction = self._tableView:getDirection()
    if direction == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then
        point.x = -((index - 1) * size.width)
    else
        index = self._data.numberOfCellsInTableView() - index + 1
        point.y = self:getViewSize().height - (index * size.height)
    end

    -- 检查偏移量是否越界  
    local maxInset = self._tableView:maxContainerOffset();  
    local minInset = self._tableView:minContainerOffset();  
    point.x = cc.clampf(point.x ,minInset.x,maxInset.x)
    point.y = cc.clampf(point.y ,minInset.y,maxInset.y)
    self:setContentOffset(point, animated)
end

--[[
    @desc: 
    --@color: c4b格式
]]
function TableViewEx:SetBackColor(color)
    self._cColor = color or self._cColor
    if self._backColor then
        self._backColor:removeSelf()
    end
    self._backColor = cc.LayerColor:create(self._cColor)
    self._backColor:setContentSize(self:getViewSize())
    self._backColor:addTo(self, -1)
end

function TableViewEx:GetBackColor()
    return self._cColor
end

function TableViewEx:setContentSize(size)
    self:setViewSize(size)

    if self._backColor then
        self._backColor:setContentSize(size)
    end
end

function TableViewEx:getContentSize()
    return self:getViewSize()
end

function TableViewEx:setDirection( direction )
    self._data.direction = direction
    self._tableView:setDirection(self:getDirection())
    self._tableView:reloadData()
end

function TableViewEx:getDirection()
    return self._data.direction or cc.SCROLLVIEW_DIRECTION_VERTICAL
end

function TableViewEx:getDirectionEx()
    return ({[cc.SCROLLVIEW_DIRECTION_VERTICAL] = 1, [cc.SCROLLVIEW_DIRECTION_HORIZONTAL] = 2})[self:getDirection()] or 1
end

function TableViewEx:setVerticalFillOrder( order )
    self._tableView:setVerticalFillOrder(order)
end

function TableViewEx:setTableCellAtIndexHandler( func )
    self._data.tableCellAtIndex = func
    self:registerScriptHandler()
end

function TableViewEx:setTableCellTouchedHandler( func )
    self._data.tableCellTouched = func
    self:registerScriptHandler()
end

function TableViewEx:setTableViewScrollHandler( func )
    self._data.scrollViewDidScroll = func
    self:registerScriptHandler()
end

function TableViewEx:setTableViewCellsNumHandler( func )
    if type(func) == "number" then
        self._data.numberOfCellsInTableView = function ()
            return func
        end
    else
        self._data.numberOfCellsInTableView = func
    end

    local oldOffset = self:getContentOffset()
    self:registerScriptHandler()
end

function TableViewEx:setTouchEnabled(bool)
    self._tableView:setTouchEnabled(bool)
end

function TableViewEx:getCellSize()
    local size = {width = 0, height = 0}
    if self._data.cellSizeForTable then
        size.width, size.height = self._data.cellSizeForTable()
    else
        size.width, size.height = self.cellSizeForTable()
    end
        
    return size
end

function TableViewEx:getTotalCellNums()
    local func = self._data.numberOfCellsInTableView or self.numberOfCellsInTableView
    return func()
end

function TableViewEx:addMouseScrollEvent(call_scrolling)
    local function __OnMouseScroll(sender)
        if not GetWidgetVisible(self) then
            return false
        end
        if not call_scrolling or type(call_scrolling) ~= "function" then
            return false
        end

        local mousePosX = sender:getCursorX()
        local mousePosY = sender:getCursorY()
        local isInSide  = global.mouseEventController:CheckNodePos(self, {x = mousePosX, y = mousePosY})
        if not isInSide then
            return false
        end
        local scrollX  = sender:getScrollX()
        local scrollY  = sender:getScrollY()
        call_scrolling({widget = self, x = scrollX, y = scrollY})
    end
    local listener = cc.EventListenerMouse:create()
    listener:registerScriptHandler(__OnMouseScroll, cc.Handler.EVENT_MOUSE_SCROLL)
    global.EventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function TableViewEx:unregisterScriptHandler()
    self._tableView:unregisterScriptHandler(cc.SCROLLVIEW_SCRIPT_SCROLL)
    self._tableView:unregisterScriptHandler(cc.TABLECELL_SIZE_FOR_INDEX)
    self._tableView:unregisterScriptHandler(cc.TABLECELL_SIZE_AT_INDEX)
    self._tableView:unregisterScriptHandler(cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self._tableView:unregisterScriptHandler(cc.TABLECELL_TOUCHED)
end

return TableViewEx
