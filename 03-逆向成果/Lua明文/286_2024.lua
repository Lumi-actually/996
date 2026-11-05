local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerWJGZ = class('gameActorStatePlayerWJGZ', gameActorState)
function gameActorStatePlayerWJGZ:ctor()
    gameActorStatePlayerWJGZ.super.ctor(self)
end

function gameActorStatePlayerWJGZ:GetStateID()
    return global.MMO.ACTION_WJGZ
end
-----------------------------------------------------------------------------
function gameActorStatePlayerWJGZ:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt
    
    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_WJGZ)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerWJGZ:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_WJGZ, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_WJGZ_TIME / player:GetMagicSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerWJGZ:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerWJGZ:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerWJGZ
-----------------------------------------------------------------------------

