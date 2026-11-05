-- 技能CD计算 耦合度较高，且计算频繁，相关逻辑放在这直接处理，不采用Notification方式
local CalcSkillCDMediator = class("CalcSkillCDMediator", framework.Mediator)
CalcSkillCDMediator.NAME = "CalcSkillCDMediator"

local mmax = math.max
local noticeTable = global.NoticeTable

function CalcSkillCDMediator:ctor()
    CalcSkillCDMediator.super.ctor(self, self.NAME)
    global.CalcSkillCDMediator = self
    
    self._firstTick = {}
    self._needTick = false
end

function CalcSkillCDMediator:listNotificationInterests()
    return {
        noticeTable.SkillEnterCD,
        noticeTable.PlayerPropertyInited
    }
end

function CalcSkillCDMediator:handleNotification(notification)
    local id = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.SkillEnterCD == id then
        local curCDTime = notification:getType()
        self:OnSkillEnterCD(data, curCDTime)

    elseif noticeTable.PlayerPropertyInited == id then
        self:Init()
    end
end

function CalcSkillCDMediator:Init()
    self._skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
end

function CalcSkillCDMediator:Tick(dt)
    if not self._needTick then
        return
    end

    if not self._skillProxy then
        return
    end
    
    local endDirty = true
    
    -- tick
    local function tick(skill)
        if skill.isCD then
            endDirty = false

            if self._firstTick[skill.id] then
                self._firstTick[skill.id] = nil
            else
                skill.curTime = skill.curTime - dt
                skill.curTime = mmax(skill.curTime, 0)
    
                if skill.curTime == 0 then
                    self:OnSkillExitCD(skill.id)
                    self._skillProxy:UpdatePlayerSkillCD(skill.id)
                else
                    local percent = skill.curTime / skill.maxTime * 100
                    SLBridge:onLUAEvent(LUA_EVENT_SKILL_CD_CHANGE, {id = skill.id, percent = percent, time = skill.curTime})
                end
            end
        end
    end

    local _, skills, nSkill = self._skillProxy:GetSkills()
    for i = 1, nSkill do
        tick(skills[i])
    end
    
    -- end timer
    if endDirty and not self._skillProxy:UpdateContinueSkillCD(dt) then
        self._needTick = false
    end
end

function CalcSkillCDMediator:OnSkillEnterCD(skillID, curCDTime)
    local player = global.gamePlayerController:GetMainPlayer()
    if not player then
        return nil
    end
    if not self._skillProxy then
        return
    end
    local config = self._skillProxy:FindConfigBySkillID(skillID)
    if not config then
        return
    end
    local skill = self._skillProxy:GetSkillByID(skillID)
    if not skill then
        return
    end

    -- globalCD
    local attackglobalCD    = SL:GetValue("GAME_DATA","attackglobalCD") or 900
    local magicglobalCD     = SL:GetValue("GAME_DATA","magicglobalCD") or 1000
    local globalCD          = (config.action == 1 and magicglobalCD or attackglobalCD) * 0.001

    -- skillCD
    local attackCD          = (player:GetAttackStepTime() / player:GetAttackSpeed())
    local magicCD           = (player:GetMagicStepTime() / player:GetMagicSpeed())
    local launchCD          = (config.action == 1 and magicCD or attackCD)

    launchCD                = math.max(globalCD, launchCD)
    local maxTime           = math.max(launchCD, skill.DelayTime*0.001)

    -- 
    skill.maxTime           = maxTime
    skill.curTime,isDouble  = self._skillProxy:GetDoubleSkillCDTime(skillID, skill.maxTime )
    skill.curTime           = curCDTime or skill.curTime    -- 强行进CD时改当前CD
    skill.isCD              = skill.curTime > 0

    -- notice
    if skill.isCD then
        SLBridge:onLUAEvent(LUA_EVENT_SKILL_CD_CHANGE, {id = skillID, percent = skill.curTime / skill.maxTime * 100, time = skill.curTime})
    end
    
    -- check global CD
    local function checkGlobalCD(skill)
        local config        = self._skillProxy:FindConfigBySkillID(skill.MagicID)
        local globalCD      = (config.action == 1 and magicglobalCD or attackglobalCD) * 0.001
        globalCD            = math.max(math.min(maxTime, globalCD), launchCD)

        if self._skillProxy:IsNeedEnterGlobalCD(skill.MagicID) and globalCD > 0 and (not skill.isCD or (skill.isCD and skill.curTime < globalCD)) then
            skill.isCD      = true
            skill.maxTime   = globalCD
            if not isDouble or skill.MagicID ~= skillID then
                skill.curTime = skill.maxTime
            end

            SLBridge:onLUAEvent(LUA_EVENT_SKILL_CD_CHANGE, {id = skill.MagicID, percent = 100, time = skill.curTime})

            self._firstTick[skill.id] = true
        end
    end

    local _, skills, nSkill = self._skillProxy:GetSkills()
    for i = 1, nSkill do
        checkGlobalCD(skills[i])
    end

    self._firstTick[skill.id] = true
    self._needTick = true
end

function CalcSkillCDMediator:OnSkillExitCD(skillID)
    if not self._skillProxy then
        return
    end
    local skill = self._skillProxy:GetSkillByID(skillID)
    if not skill then
        return
    end
    
    skill.isCD = false
    skill.maxTime = 0
    skill.curTime = skill.maxTime

    SLBridge:onLUAEvent(LUA_EVENT_SKILL_CD_CHANGE, {id = skillID, percent = 0, time = 0})
end

return CalcSkillCDMediator
