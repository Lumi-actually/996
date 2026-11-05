local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerAssassinUnknown = class('gameActorStatePlayerAssassinUnknown', gameActorState)
function gameActorStatePlayerAssassinUnknown:ctor()
    gameActorStatePlayerAssassinUnknown.super.ctor(self)
end

function gameActorStatePlayerAssassinUnknown:GetStateID()
    return global.MMO.ACTION_ASSASSIN_UNKNOWN
end
-----------------------------------------------------------------------------
function gameActorStatePlayerAssassinUnknown:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_ASSASSIN_UNKNOWN)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerAssassinUnknown:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_ASSASSIN_UNKNOWN, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_ASSASSIN_UNKNOWN_TIME / player:GetAttackSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerAssassinUnknown:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerAssassinUnknown:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerAssassinUnknown
-----------------------------------------------------------------------------

