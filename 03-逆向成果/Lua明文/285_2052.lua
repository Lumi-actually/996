local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerSYZ = class('gameActorStatePlayerSYZ', gameActorState)

function gameActorStatePlayerSYZ:ctor()
    gameActorStatePlayerSYZ.super.ctor(self)
end

function gameActorStatePlayerSYZ:GetStateID()
    return global.MMO.ACTION_SYZ
end
-----------------------------------------------------------------------------
function gameActorStatePlayerSYZ:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt
    
    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_SYZ)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerSYZ:OnEnter(player)    
    self.super.OnEnter(self, player)

    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_SYZ, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_SYZ_TIME / player:GetMagicSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerSYZ:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerSYZ:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerSYZ
-----------------------------------------------------------------------------

