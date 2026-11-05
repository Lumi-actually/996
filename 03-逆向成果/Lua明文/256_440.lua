local gameActorState = class("gameActorState")

function gameActorState:ctor()
end

function gameActorState:Tick(dt, actor)
end

function gameActorState:ChangeState(newState, actor, isTerminate)
end

function gameActorState:GetStateID()
end

function gameActorState:OnEnter(actor)
end

function gameActorState:OnExit(actor)
end

function gameActorState:OnAnimLoadCompleted(actor, animAct)
end

return gameActorState
