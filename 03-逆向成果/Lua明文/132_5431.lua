local GameStateController = class('GameStateController', framework.Mediator)
GameStateController.NAME  = "GameStateController"

local gameStateActive = require( "gamestates/gameStateActive" )
local gameStateInit   = require( "gamestates/gameStateInit" )
local gameStateLogin  = require( "gamestates/gameStateLogin" )
local gameStateRole   = require( "gamestates/gameStateRole" )
local gameStateWorld  = require( "gamestates/gameStateWorld" )

function GameStateController:ctor()
    GameStateController.super.ctor( self, self.NAME )

    local glview = global.Director:getOpenGLView()
    local framesize = glview:getFrameSize()
    self._framesizeOriWidth  = framesize.width
    self._framesizeOriHeight = framesize.height

    self:Init()
end

function GameStateController:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.ChangeGameState,
        noticeTable.EndGameState,
    }
end


function GameStateController:handleNotification(notification)
    local noticeID = notification:getName()
    local notices  = global.NoticeTable
    local data     = notification:getBody()

    if notices.ChangeGameState == noticeID then
        self:ChangeGameState( data )

    elseif notices.EndGameState == noticeID then
        self:OnEndGameState()
    end

end

function GameStateController:Init()
    local mmo = global.MMO

    self._gameStates  = {}
    self._currStateID = nil
    self._currState   = nil

    self._gameStates[mmo.GAME_STATE_ACTIVE] = gameStateActive.new()
    self._gameStates[mmo.GAME_STATE_INIT]   = gameStateInit.new()
    self._gameStates[mmo.GAME_STATE_LOGIN]  = gameStateLogin.new()
    self._gameStates[mmo.GAME_STATE_ROLE]   = gameStateRole.new()
    self._gameStates[mmo.GAME_STATE_WORLD]  = gameStateWorld.new()
end

function GameStateController:ChangeGameState( newStateID )
    if newStateID == self._currStateID then
        return
    end

    
    local newState = self._gameStates[newStateID]
    if nil == newState then
        return
    end

    local lastState = self._currState
    if self._currState then
        self._currState:onExit()
    end

    self._currState = newState
    self._currStateID = newStateID

    if lastState then
        print( lastState:getStateType(), "-->", self._currState:getStateType() )
    else
        print( "none -->", self._currState:getStateType() )
    end

    newState:onEnter()
end

function GameStateController:ChangeAppStateCB(appState, p1, p2)
    if 0 == appState then
        self:OnGameSuspend()

    elseif 1 == appState then
        self:OnGameResumed()

    elseif 2 == appState then
        -- self:OnGameSizeChanged()
        self:OnScreenSizeChanged(p1, p2)

    end
end

function GameStateController:OnGameSuspend()
    global.Facade:sendNotification( global.NoticeTable.GameSuspend )
end

function GameStateController:OnGameResumed()
    global.Facade:sendNotification( global.NoticeTable.GameResumed )
end

function GameStateController:OnGameSizeChanged()
    global.Facade:sendNotification( global.NoticeTable.GameSizeChanged )

end

function GameStateController:OnScreenSizeChanged(width, height)
    release_print("GameStateController:OnScreenSizeChanged()==============")
    release_print(width, self._framesizeOriWidth)
    release_print(height, self._framesizeOriHeight)

    if self._framesizeOriWidth == width and self._framesizeOriHeight == height then
        return 
    end 

    if self._framesizeOriWidth == height and self._framesizeOriHeight == width then
        return 
    end 

    local frameFactor   = width / height
    local designPolicy  = cc.ResolutionPolicy.FIXED_HEIGHT
    if frameFactor > 1.8 then       -- 17:9 = 1.889
        designPolicy = cc.ResolutionPolicy.FIXED_HEIGHT
    else                            -- 16:9 = 1.778
        designPolicy = cc.ResolutionPolicy.FIXED_WIDTH
    end

    local glview = global.Director:getOpenGLView()
    glview:setFrameSize(width, height)
    local width = global.DesignSize_Oth.width
    local height = global.DesignSize_Oth.height
    if global.isWinPlayMode and (width > global.MMO.RESOLUTION_WIDTH or height > global.MMO.RESOLUTION_HEIGHT) then
        width = global.MMO.RESOLUTION_WIDTH
        height = global.MMO.RESOLUTION_HEIGHT
    end

    self._framesizeOriWidth  = width
    self._framesizeOriHeight = height
    
    glview:setDesignResolutionSize(width, height, designPolicy)
    global.Facade:sendNotification(global.NoticeTable.ResolutionSizeChange, {onlyAdapt = true})
end

function GameStateController:GetCurrentState()
    return self._currStateID
end

function GameStateController:OnEndGameState()
    if self._currState then
        self._currState:onEnd()
        self._currState = nil
        self._currStateID = nil
    end
end

function GameStateController:onRegister()
    GameStateController.super.onRegister( self )

    -- stateMgr
    if not global.gameStateCtl then
        global.gameStateCtl = gameStateMgr:Inst()
    end

    global.gameStateCtl:RegisterLuaHandler( handler( self, self.ChangeAppStateCB ) )
end

function GET_GAME_STATE()
    local stateCtl = global.Facade:retrieveMediator( GameStateController.NAME )
    return stateCtl:GetCurrentState()
end

return GameStateController
