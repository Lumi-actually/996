local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerFWJ = class('gameActorStatePlayerFWJ', gameActorState)

function gameActorStatePlayerFWJ:ctor()
    gameActorStatePlayerFWJ.super.ctor(self)
end

function gameActorStatePlayerFWJ:GetStateID()
    return global.MMO.ACTION_FWJ
end
-----------------------------------------------------------------------------
function gameActorStatePlayerFWJ:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_FWJ)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerFWJ:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_FWJ, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_FWJ_TIME / player:GetMagicSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerFWJ:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerFWJ:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerFWJ
-----------------------------------------------------------------------------

