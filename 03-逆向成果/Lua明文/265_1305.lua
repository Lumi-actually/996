local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerMining = class('gameActorStatePlayerMining', gameActorState)
function gameActorStatePlayerMining:ctor()
    gameActorStatePlayerMining.super.ctor(self)
end

function gameActorStatePlayerMining:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT-dt

    if player.mCurrentActT <= 0.00001 then 
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_MINING)
        end
    end
end

function gameActorStatePlayerMining:OnEnter(player)    
    local animTime      = player:GetAttackStepTime() / player:GetAttackSpeed()
    player.mCurrentActT = animTime

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerMining:OnExit(player)  
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerMining:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState

    return true
end

function gameActorStatePlayerMining:GetStateID()  
    return global.MMO.ACTION_MINING
end

return gameActorStatePlayerMining