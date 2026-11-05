--[[
    author:yzy
    time:2022-04-20 11:16:04
    desc: 怪物石头状态,  就是置灰  设置SetStoneMode   停在动画第一帧
]]
local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntityStoneMode = class("BuffEntityStoneMode", BuffEntityAnim)

function BuffEntityStoneMode:ctor(data)
    BuffEntityStoneMode.super.ctor(self, data)
    self._autoRemove = false                    --强制不自动移除    
end

function BuffEntityStoneMode:OnEnter()
    BuffEntityStoneMode.super.OnEnter(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        self:disable()
        return false
    end

    if actor:IsMonster() then
        actor:SetStoneMode(true)
        actor:StopAnimToFrame(1)
    else
        self:disable()
        return false
    end

end

function BuffEntityStoneMode:OnExit()
    BuffEntityStoneMode.super.OnExit(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return nil
    end

    if actor:IsMonster() then
        actor:SetStoneMode(false)
        actor:StopAnimToFrame(nil)
    end

end


return BuffEntityStoneMode