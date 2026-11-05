local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerAttack = class('gameActorStatePlayerAttack', gameActorState)
function gameActorStatePlayerAttack:ctor()
    gameActorStatePlayerAttack.super.ctor(self)
end

function gameActorStatePlayerAttack:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_ATTACK)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end

function gameActorStatePlayerAttack:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_ATTACK, player.mOrient, 0)
    end

    local animTime = player:GetAttackStepTime() / player:GetAttackSpeed()
    player.mCurrentActT = animTime
    player.mIsConfirmed = true

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerAttack:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerAttack:ChangeState(newState, player)    
    player.mCurrentState = newState
    return true
end

function gameActorStatePlayerAttack:GetStateID()  
    return global.MMO.ACTION_ATTACK
end

return gameActorStatePlayerAttack