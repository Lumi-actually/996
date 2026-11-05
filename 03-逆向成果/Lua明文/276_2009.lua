local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerSJS = class('gameActorStatePlayerSJS', gameActorState)

function gameActorStatePlayerSJS:ctor()
    gameActorStatePlayerSJS.super.ctor(self)
end

function gameActorStatePlayerSJS:GetStateID()
    return global.MMO.ACTION_SJS
end
-----------------------------------------------------------------------------
function gameActorStatePlayerSJS:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_SJS)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerSJS:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_SJS, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_SJS_TIME / player:GetAttackSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerSJS:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerSJS:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerSJS
-----------------------------------------------------------------------------

