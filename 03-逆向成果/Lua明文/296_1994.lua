local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerJY = class('gameActorStatePlayerJY', gameActorState)

function gameActorStatePlayerJY:ctor()
    gameActorStatePlayerJY.super.ctor(self)
end

function gameActorStatePlayerJY:GetStateID()
    return global.MMO.ACTION_JY
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJY:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_JY)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJY:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_JY, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_JY_TIME / player:GetMagicSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJY:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJY:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerJY
-----------------------------------------------------------------------------

