local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerJLB = class('gameActorStatePlayerJLB', gameActorState)

function gameActorStatePlayerJLB:ctor()
    gameActorStatePlayerJLB.super.ctor(self)
end

function gameActorStatePlayerJLB:GetStateID()
    return global.MMO.ACTION_JLB
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJLB:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_JLB)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJLB:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_JLB, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_JLB_TIME / player:GetMagicSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJLB:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerJLB:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerJLB
-----------------------------------------------------------------------------

