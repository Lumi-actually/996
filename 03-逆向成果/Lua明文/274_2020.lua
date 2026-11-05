local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerYTPD = class('gameActorStatePlayerYTPD', gameActorState)
function gameActorStatePlayerYTPD:ctor()
    gameActorStatePlayerYTPD.super.ctor(self)
end

function gameActorStatePlayerYTPD:GetStateID()
    return global.MMO.ACTION_YTPD
end
-----------------------------------------------------------------------------
function gameActorStatePlayerYTPD:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_YTPD)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerYTPD:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_YTPD, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_YTPD_TIME / player:GetMagicSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerYTPD:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerYTPD:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerYTPD
-----------------------------------------------------------------------------

