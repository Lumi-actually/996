local playerManager = class("playerManager")

function playerManager:ctor()
    self.mPlayersInCurrViewFieldMap = {}
    self.mPlayersInCurrViewField = {}
    self.mPlayersIndexMap = {}
    self.mPlayerCount = 0
end

function playerManager:destory()
end

function playerManager:create()
    local _this = playerManager.new()
    return _this
end

function playerManager:Cleanup()
    self.mPlayersInCurrViewFieldMap = {}
    self.mPlayersInCurrViewField = {}
    self.mPlayersIndexMap = {}
    self.mPlayerCount = 0
end

function playerManager:GetPlayerCount()
    return self.mPlayerCount
end

function playerManager:AddPlayer(player)
    if not player then
        return false
    end

    local playerID = player:GetID()

    if self.mPlayersInCurrViewFieldMap[playerID] then
        return false
    end

    self.mPlayerCount = self.mPlayerCount + 1

    local n = self.mPlayerCount

    self.mPlayersIndexMap[playerID] = n

    self.mPlayersInCurrViewField[n] = player

    self.mPlayersInCurrViewFieldMap[playerID] = player
end

function playerManager:RmvPlayer(playerID)
    local player = self.mPlayersInCurrViewFieldMap[playerID]

    if not player then
        return false
    end

    self.mPlayersInCurrViewFieldMap[playerID] = nil

    local index = self.mPlayersIndexMap[playerID]

    if index == self.mPlayerCount then
        self.mPlayersInCurrViewField[index] = nil
    else
        -- last index --> index
        local lastActor = self.mPlayersInCurrViewField[self.mPlayerCount]
        self.mPlayersInCurrViewField[index] = lastActor
        self.mPlayersIndexMap[lastActor:GetID()] = index

        -- reset last value
        self.mPlayersInCurrViewField[self.mPlayerCount] = nil
    end

    self.mPlayersIndexMap[playerID] = nil
    self.mPlayerCount = self.mPlayerCount - 1
end

function playerManager:FindAllPlayerIDInCurrViewField()
    local recvVec = {}
    local num = 0
    for i = 1, self.mPlayerCount do
        local m = self.mPlayersInCurrViewField[i]
        if m then
            if m:IsMainPlayer() then 
            else
                num = num + 1
                recvVec[num] = m:GetID()
            end
        end
    end

    return recvVec, num
end

function playerManager:FindAllPlayerInCurrViewField(noMainPlayer)
    if noMainPlayer == nil then 
        noMainPlayer = true 
    end

    local recvVec = {}
    local num = 0
    for i = 1, self.mPlayerCount do
        local m = self.mPlayersInCurrViewField[i]
        if m then
            if noMainPlayer and m:IsMainPlayer() then 
            else
                num = num + 1
                recvVec[num] = m
            end
        end 
    end

    return recvVec, num
end

function playerManager:FindAllHeroInCurrViewField()
    local recvVec = {}
    local num = 0

    for i = 1, self.mPlayerCount do
        local m = self.mPlayersInCurrViewField[i]
        if m and m:IsHero() then
            num = num + 1
            recvVec[num] = m
        end   
    end

    return recvVec, num
end

function playerManager:FindAllHeroIDInCurrViewField()
    local recvVec = {}
    local num = 0

    for i = 1, self.mPlayerCount do
        local m = self.mPlayersInCurrViewField[i]
        if m and m:IsHero() then
            num = num + 1
            recvVec[num] = m:GetID()
        end   
    end

    return recvVec, num
end

function playerManager:FindAllHumanoidIDInCurrViewField()
    local recvVec = {}
    local num = 0

    for i = 1, self.mPlayerCount do
        local m = self.mPlayersInCurrViewField[i]
        if m and m:IsHumanoid() then
            num = num + 1
            recvVec[num] = m:GetID()
        end
    end

    return recvVec, num
end

function playerManager:FindOnePlayerInCurrViewFieldById(playerID)
    return self.mPlayersInCurrViewFieldMap[playerID]
end

function playerManager:GetAllPlayerInCurrViewField()
    return self.mPlayersInCurrViewField, self.mPlayerCount
end

return playerManager
