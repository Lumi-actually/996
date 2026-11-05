local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerTSZ = class('gameActorStatePlayerTSZ', gameActorState)
function gameActorStatePlayerTSZ:ctor()
    gameActorStatePlayerTSZ.super.ctor(self)
end

function gameActorStatePlayerTSZ:GetStateID()
    return global.MMO.ACTION_TSZ
end
-----------------------------------------------------------------------------
function gameActorStatePlayerTSZ:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_TSZ)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerTSZ:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_TSZ, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_TSZ_TIME / player:GetAttackSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerTSZ:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerTSZ:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerTSZ
-----------------------------------------------------------------------------

