local Behavior = require("bt/Behavior")
local BehaviorSelector  = class("BehaviorSelector", Behavior)

local BehaviorTurn      = require("bt/BehaviorTurn")
local BehaviorMove      = require("bt/BehaviorMove")
local BehaviorDig       = require("bt/BehaviorDig")
local BehaviorCorpse    = require("bt/BehaviorCorpse")
local BehaviorMining    = require("bt/BehaviorMining")
local BehaviorLaunch    = require("bt/BehaviorLaunch")
local BehaviorKLaunch   = require("bt/BehaviorKLaunch")

local facade            = global.Facade
local BehaviorConfig    = global.BehaviorConfig

function BehaviorSelector:ctor(data)
    BehaviorSelector.super.ctor(self, data)
    self._behaviors = {}
    self._nBehavior = 0
end

function BehaviorSelector:Init()
    self._behaviors = {
        BehaviorKLaunch.new(),
        BehaviorTurn.new(),
        BehaviorMove.new(),
        BehaviorDig.new(),
        BehaviorCorpse.new(),
        BehaviorMining.new(),
        BehaviorLaunch.new()
    }

    self._nBehavior = #self._behaviors

    self._autoCtl = facade:retrieveMediator("AutoController")
end

function BehaviorSelector:Process(player, actCompleted)
    local playerID = player:GetID()

    -- 摆摊
    if SL:GetValue("STALL_MY_TRADING_STATUS") then
        if actCompleted ~= global.MMO.ACTION_IDLE then
            facade:sendNotification(global.NoticeTable.ActorEnterIdleAction, playerID)
        end
        return nil
    end

    -- 野蛮等待
    if actCompleted == global.MMO.ACTION_DASH_WAITING then
        facade:sendNotification(global.NoticeTable.ActorEnterIdleAction, playerID)
        return nil
    end

    -- 野蛮失败
    if actCompleted == global.MMO.ACTION_DASH_FAIL then
        facade:sendNotification(global.NoticeTable.ActorEnterIdleAction, playerID)
        return nil
    end
    
    -- behavior
    local status       = BehaviorConfig.BTSTATUS_Failure
    local currBehavior = nil

    for i = 1, self._nBehavior do
        local behavior = self._behaviors[i]
        status = behavior:Update(player, actCompleted)

        if status == BehaviorConfig.BTSTATUS_Success or status == BehaviorConfig.BTSTATUS_Running then
            currBehavior = behavior
            break
        end
    end

    -- 这儿做个处理，释放技能可能需要走位，不等下一帧，当前帧生效
    if currBehavior and currBehavior:GetType() == BehaviorConfig.BehaviorType.BehaviorLaunch then
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        local pathPoints = inputProxy:GetCurrPathPoint()
        if pathPoints > 0 and inputProxy:GetLaunchSkillID() ~= nil then
            local behavior = self._behaviors[3]
            status = behavior:Update(player, actCompleted)

            if status == BehaviorConfig.BTSTATUS_Success or status == BehaviorConfig.BTSTATUS_Running then
                currBehavior = behavior
            end
        end
    end

    -- auto
    if status == BehaviorConfig.BTSTATUS_Failure then
        if self._autoCtl then
            self._autoCtl:stateBegin(player, actCompleted)
        end
    else
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        autoProxy:ForceCheckAutoFindItemBehavior(actCompleted, currBehavior and currBehavior:GetType())
    end

    -- 自动战斗选择后，会产生新的行为，再遍历一次
    if status == BehaviorConfig.BTSTATUS_Failure then
        for i = 1, self._nBehavior do
            local behavior = self._behaviors[i]
            status = behavior:Update(player, actCompleted)

            if status == BehaviorConfig.BTSTATUS_Success or status == BehaviorConfig.BTSTATUS_Running then
                currBehavior = behavior
                break
            end
        end
    end

    -- 这儿做个处理，释放技能可能需要走位，不等下一帧，当前帧生效
    if currBehavior and currBehavior:GetType() == BehaviorConfig.BehaviorType.BehaviorLaunch then
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        local pathPoints = inputProxy:GetCurrPathPoint()
        if pathPoints > 0 and inputProxy:GetLaunchSkillID() ~= nil then
            local behavior = self._behaviors[3]
            status = behavior:Update(player, actCompleted)

            if status == BehaviorConfig.BTSTATUS_Success or status == BehaviorConfig.BTSTATUS_Running then
                currBehavior = behavior
            end
        end
    end

    -- idle
    if status == BehaviorConfig.BTSTATUS_Failure then
        if actCompleted ~= global.MMO.ACTION_IDLE then
            facade:sendNotification(global.NoticeTable.ActorEnterIdleAction, playerID)
        end
    end
end

return BehaviorSelector
