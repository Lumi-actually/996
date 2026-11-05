local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerAssassinSmite = class('gameActorStatePlayerAssassinSmite', gameActorState)
function gameActorStatePlayerAssassinSmite:ctor()
    gameActorStatePlayerAssassinSmite.super.ctor(self)
end

function gameActorStatePlayerAssassinSmite:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_ASSASSIN_SMITE)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end

function gameActorStatePlayerAssassinSmite:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_ASSASSIN_SMITE, player.mOrient, 0)
    end

    local animTime      = global.MMO.DEFAULT_ASSASSIN_ATTACK_TIME / player:GetAttackSpeed()
    player.mCurrentActT = animTime
    player.mIsConfirmed  = true

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerAssassinSmite:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerAssassinSmite:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState

    return true
end

function gameActorStatePlayerAssassinSmite:GetStateID()  
    return global.MMO.ACTION_ASSASSIN_ATTACK
end

return gameActorStatePlayerAssassinSmite