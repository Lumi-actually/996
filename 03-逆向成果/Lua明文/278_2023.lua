local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerHSQJ = class('gameActorStatePlayerHSQJ', gameActorState)

function gameActorStatePlayerHSQJ:ctor()
    gameActorStatePlayerHSQJ.super.ctor(self)
end

function gameActorStatePlayerHSQJ:GetStateID()
    return global.MMO.ACTION_HSQJ
end
-----------------------------------------------------------------------------
function gameActorStatePlayerHSQJ:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_HSQJ)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerHSQJ:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_HSQJ, player.mOrient, 0)
    end 

    local animTime      = global.MMO.DEFAULT_HSQJ_TIME / player:GetAttackSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerHSQJ:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerHSQJ:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end
return gameActorStatePlayerHSQJ
-----------------------------------------------------------------------------

