local BaseUIMediator = requireMediator("BaseUIMediator")
local LoginServerMediator = class("LoginServerMediator", BaseUIMediator)
LoginServerMediator.NAME = "LoginServerMediator"

local HUDFilePath = global.MMO.PATH_RES_PRIVATE .. "hud/actor_hud"

function LoginServerMediator:ctor()
    LoginServerMediator.super.ctor(self)

    self._sfxcache = {}
    self._fontcache = {}
    self._textureCache = {}
    self._spriteFrameCache = {}
end

function LoginServerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.EnterLogin,
        noticeTable.LeaveRole,
        noticeTable.EndGameState,
    }
end

function LoginServerMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeTable.EnterLogin == noticeID then
        self:OnEnterLogin()

    elseif noticeTable.LeaveRole == noticeID then
        self:OnLeaveRole()
        
    elseif noticeTable.EndGameState == noticeID then
        self:OnEndGameState()

    end
end

function LoginServerMediator:OnEnterLogin()
    local animID = {4121, 4127, 4123, 4129, 4125, 4131, 4122, 4128, 4124, 4130, 4126, 4132}
    for k, v in pairs(animID) do
        local anim = global.FrameAnimManager:CreateSFXAnim(v)
        anim:retain()
        self._sfxcache[v] = anim
    end

    -- 预加载资源
    self._textureCache[HUDFilePath] = global.TextureCache:addImage(HUDFilePath .. ".png")
    self._textureCache[HUDFilePath]:retain()
    global.SpriteFrameCache:addSpriteFrames(HUDFilePath .. ".plist")
    local filelist = {9990, 9991, 9992, 9993, 9994, 9995, 9996, 9999}
    for i, v in ipairs(filelist) do
        local filename = string.format("actor_hud_%s.png", v)
        local spriteFrame = global.SpriteFrameCache:getSpriteFrame(filename)
        self._spriteFrameCache[filename] = spriteFrame
        self._spriteFrameCache[filename]:retain()
    end
end

function LoginServerMediator:OnLeaveRole()
    -- role anim cache
    for k, v in pairs(self._sfxcache) do
        v:autorelease()
    end
    self._sfxcache = {}

    -- open door cache
    local index = 0
    local path = string.format(global.MMO.PATH_RES_PRIVATE .. "login/open_door/%02d.png", index)
    while global.FileUtilCtl:isFileExist(path) do
        global.TextureCache:removeTextureForKey(path)

        index = index + 1
        path = string.format(global.MMO.PATH_RES_PRIVATE .. "login/open_door/%02d.png", index)
    end
end

function LoginServerMediator:OnEndGameState()
    for _, label in pairs(self._fontcache) do
        label:release()
    end
    self._fontcache = {}

    -- 纹理
    for k, texture in pairs(self._textureCache) do
        texture:release()
    end
    self._textureCache = {}
    
    -- 精灵帧
    for k, spriteFrame in pairs(self._spriteFrameCache) do
        spriteFrame:release()
    end
    self._spriteFrameCache = {}

    for k, v in pairs(self._sfxcache) do
        v:autorelease()
    end
    self._sfxcache = {}
end

function LoginServerMediator:onRegister()
    -----------------------------------------------------------------------------
    local function cacheFontAtlas( _fontSize, _outlineSize )
        local config =
        {
            fontFilePath         = global.MMO.PATH_FONT2,
            fontSize             = _fontSize,
            glyphs               = cc.GLYPHCOLLECTION_DYNAMIC,
            distanceFieldEnabled = false,
            outlineSize          = _outlineSize
        }

        local label = cc.Label:createWithTTF( config, "for cache")

        -- never release(warning, it will be repeated create)
        label:retain()
        table.insert(self._fontcache, label)
    end

    cacheFontAtlas( 16, 0 )

    cacheFontAtlas( 10, 1 )
    cacheFontAtlas( 14, 1 )
    cacheFontAtlas( 15, 1 )
    cacheFontAtlas( 16, 1 )
    cacheFontAtlas( 18, 1 )
    cacheFontAtlas( 20, 1 )
    cacheFontAtlas( 25, 1 )

    cacheFontAtlas( 18, 2 )

    cacheFontAtlas( 16, 3 )
    cacheFontAtlas( 18, 3 )
    cacheFontAtlas( 20, 3 )

    cacheFontAtlas( 18, 4 )


    --先加载一下bmpfont
    local fontZtPath = global.MMO.PATH_ST_FONT 
    cc.Label:createWithBMFont(fontZtPath,"")
end

return LoginServerMediator
