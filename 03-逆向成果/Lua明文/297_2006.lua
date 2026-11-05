local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerJY2 = class('gameActorStatePlayerJY2', gameActorState)
function gameActorStatePlayerJY2:ctor()
    gameActorStatePlayerJY2.super.ctor(self)
end

function gameActorStatePlayerJY2:GetStateID()
    return global.MMO.ACTION_JY2
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJY2:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_JY2)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJY2:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_JY2, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_JY2_TIME / player:GetMagicSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJY2:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJY2:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerJY2
-----------------------------------------------------------------------------

