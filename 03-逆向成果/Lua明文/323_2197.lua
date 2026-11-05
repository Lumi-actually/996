local npcManager = class("npcManager")

function npcManager:ctor()
    self.mNpcsInCurrViewFieldMap = {}
    self.mNpcsInCurrViewField = {}
    self.mNpcsIndexMap = {}
    self.mNpcCount = 0
end

function npcManager:destory()
end

function npcManager:create()
    local _this = npcManager.new()
    return _this
end

function npcManager:Cleanup()
    self.mNpcsInCurrViewFieldMap = {}
    self.mNpcsInCurrViewField = {}
    self.mNpcsIndexMap = {}
    self.mNpcCount = 0
end

function npcManager:AddNpc(npc)
    if not npc then
        return false
    end

    local npcID = npc:GetID()

    if self.mNpcsInCurrViewFieldMap[npcID] then
        return false
    end

    self.mNpcCount = self.mNpcCount + 1

    local n = self.mNpcCount

    self.mNpcsIndexMap[npcID] = n

    self.mNpcsInCurrViewField[n] = npc

    self.mNpcsInCurrViewFieldMap[npcID] = npc
end

function npcManager:RmvNpc(npcID)
    local npc = self.mNpcsInCurrViewFieldMap[npcID]

    if not npc then
        return false
    end

    self.mNpcsInCurrViewFieldMap[npcID] = nil

    local index = self.mNpcsIndexMap[npcID]

    if index == self.mNpcCount then
        self.mNpcsInCurrViewField[index] = nil
    else
        -- last index --> index
        local lastActor = self.mNpcsInCurrViewField[self.mNpcCount]
        self.mNpcsInCurrViewField[index] = lastActor
        self.mNpcsIndexMap[lastActor:GetID()] = index

        -- reset last value
        self.mNpcsInCurrViewField[self.mNpcCount] = nil
    end

    self.mNpcsIndexMap[npcID] = nil
    self.mNpcCount = self.mNpcCount - 1
end

function npcManager:FindAllNpcIDInCurrViewField()
    local recvVec = {}
    local num = 0

    for i = 1, self.mNpcCount do
        local m = self.mNpcsInCurrViewField[i]
        if m then
            num = num + 1
            recvVec[num] = m:GetID()
        end
    end

    return recvVec, num
end

function npcManager:FindOneNpcInCurrViewFieldById(npcID)
    return self.mNpcsInCurrViewFieldMap[npcID]
end

function npcManager:GetAllNpcInCurrViewField()
    return self.mNpcsInCurrViewField, self.mNpcCount
end

return npcManager