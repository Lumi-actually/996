local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerAssassinSY = class('gameActorStatePlayerAssassinSY', gameActorState)
function gameActorStatePlayerAssassinSY:ctor()
    gameActorStatePlayerAssassinSY.super.ctor(self)
end

function gameActorStatePlayerAssassinSY:GetStateID()
    return global.MMO.ACTION_ASSASSIN_SY
end
-----------------------------------------------------------------------------
function gameActorStatePlayerAssassinSY:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_ASSASSIN_SY)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerAssassinSY:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_ASSASSIN_SY, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_ASSASSIN_SY_TIME / player:GetAttackSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerAssassinSY:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerAssassinSY:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerAssassinSY
-----------------------------------------------------------------------------

