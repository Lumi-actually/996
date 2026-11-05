local BaseUIMediator = requireMediator("BaseUIMediator")
local CostItemCellMediator = class("CostItemCellMediator", BaseUIMediator)
CostItemCellMediator.NAME = "CostItemCellMediator"

function CostItemCellMediator:ctor()
    CostItemCellMediator.super.ctor(self)
    self._cells = {}
    self._cellIDPool = requireUtil("queue").new()
    self._cellIDCount = 0
end

function CostItemCellMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.AddCostItemCell,
        noticeTable.RmvCostItemCell,
        noticeTable.PlayerMoneyChange,
        noticeTable.Bag_Oper_Data_Delay,
    }
end

function CostItemCellMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local id = notification:getName()
    local data = notification:getBody()

    if noticeTable.AddCostItemCell == id then
        self:OnAddCostItemCell(data)

    elseif noticeTable.RmvCostItemCell == id then
        self:OnRmvCostItemCell(data)

    elseif noticeTable.PlayerMoneyChange == id then
        self:OnPropertyUpdate(data)

    elseif noticeTable.Bag_Oper_Data_Delay == id then
        self:OnPropertyUpdate(data)
    end
end

function CostItemCellMediator:OnAddCostItemCell(cell)
    local cellID = self:GetCellID()
    cell.cellIndex = cellID
    self._cells[cell.cellIndex] = cell
end

function CostItemCellMediator:OnRmvCostItemCell(cell)
    self._cells[cell.cellIndex] = nil
    self:RecycleCellID(cell.cellIndex)
end

function CostItemCellMediator:OnPropertyUpdate(data)
    for k,v in pairs(self._cells) do
        if _DEBUG and tolua.isnull(v) then
            release_print("----------------------------------------")
            release_print(debug.traceback())
            release_print("----------------------------------------")
        end
        if not v._notRefresh then
            v:OnUpdate()
        end
    end
end

function CostItemCellMediator:GetCellID()
    if self._cellIDPool:empty() then
        self._cellIDCount = self._cellIDCount + 1
        return self._cellIDCount
    end
    return self._cellIDPool:pop()
end

function CostItemCellMediator:RecycleCellID(id)
    self._cellIDPool:push(id)
end

return CostItemCellMediator
