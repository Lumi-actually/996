local sceneEffectManager = class("sceneEffectManager")

function sceneEffectManager:ctor()
    self.mFireAudioFlag = false
    self.mSceneEffectInCurrViewField = {}
    self.mSceneEffectMapXYInCurrViewField = {}
end

function sceneEffectManager:destory()
end

function sceneEffectManager:create()
    local _this = sceneEffectManager.new()
    return _this
end

function sceneEffectManager:Cleanup()
    self.mFireAudioFlag = false

    self.mSceneEffectInCurrViewField = {}
    self.mSceneEffectMapXYInCurrViewField = {}
end

function sceneEffectManager:AddSceneEffect(effect)
    if nil == effect then return -1 end

    self.mSceneEffectInCurrViewField[effect:GetID()] = effect  

    local  p = {}
    p.x = effect:GetMapX()
    p.y = effect:GetMapY()
    p.point = 65536 * p.y + p.x
    self.mSceneEffectMapXYInCurrViewField[p.point] = effect

    self:CheckFireAudio( effect, true )

    return 1
end

function sceneEffectManager:RmvSceneEffect(effectID)
    local it = self.mSceneEffectInCurrViewField[effectID]
    if nil == it then
        return -1
    end
    local  effect = it
    self.mSceneEffectInCurrViewField[effectID] = nil 

    local   p = {}

    p.x = effect:GetMapX()
    p.y = effect:GetMapY()
    p.point = 65536 * p.y + p.x
    local itMapXY = self.mSceneEffectMapXYInCurrViewField[p.point]
    if nil == itMapXY then
        return -2
    end
    self.mSceneEffectMapXYInCurrViewField[p.point] = nil

    self:CheckFireAudio( effect, false )

    return 1
end

function sceneEffectManager:FindSceneEffectInCurrViewField(recvVec)
    for k,v in pairs(self.mSceneEffectInCurrViewField) do
        table.insert(recvVec, v) 
    end
end

function sceneEffectManager:FindSceneEffectInMapXY(X, Y)
    local   p = {}
    p.x = X
    p.y = Y
    p.point = 65536 * p.y + p.x

    local itMapXY = self.mSceneEffectMapXYInCurrViewField[p.point]
    if nil == itMapXY then
        return nil
    end

    return itMapXY  
end

function sceneEffectManager:IsExistedFireInMapXY(X, Y)
    local effect = self:FindSceneEffectInMapXY( X, Y )
    if not effect then
        return false
    end

    return (effect:GetEffectType() == global.MMO.EFFECT_TYPE_FIRE)
end

function sceneEffectManager:CheckFireAudio(effect, isAdd)
    if (not effect) or global.MMO.EFFECT_TYPE_FIRE ~= effect:GetEffectType() then
        return
    end

    if isAdd and not self.mFireAudioFlag then    -- play fire audio
        self.mFireAudioFlag = true
        return 
    end


    if (not isAdd) and self.mFireAudioFlag then    -- stop fire audio
        local isExistFire = false
        for k,v in pairs(self.mSceneEffectInCurrViewField) do
            local  m = v
            if global.MMO.EFFECT_TYPE_FIRE == m:GetEffectType() then
                isExistFire = true
                break
            end
        end

        if not isExistFire then
            self.mFireAudioFlag = false
        end
    end
end

return sceneEffectManager
