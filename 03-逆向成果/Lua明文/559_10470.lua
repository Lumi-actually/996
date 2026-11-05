local sequFrameAnimLoader = require( "animation/sequFrameAnimLoader" )
local sequFrameAnimLoaderImpSkill = class('sequFrameAnimLoaderImpSkill', sequFrameAnimLoader)

local ANIM_RES_PATH ="anim/effect/"


function sequFrameAnimLoaderImpSkill:ctor()
    sequFrameAnimLoaderImpSkill.super.ctor(self)
end

function sequFrameAnimLoaderImpSkill:init()
    sequFrameAnimLoaderImpSkill.super.init(self)
end

function sequFrameAnimLoaderImpSkill:convertTexFileName( rawAnimID, sex, dir ) 
    return string.format( "%ssfx_%04d_%d.png", ANIM_RES_PATH, rawAnimID, dir )
end

function sequFrameAnimLoaderImpSkill:convertPlistFileName( rawAnimID, sex, dir )  
    return string.format( "%ssfx_%04d_%d.plist", ANIM_RES_PATH, rawAnimID, dir )
end

function sequFrameAnimLoaderImpSkill:convertTexFileNameByIdx( rawAnimID, sex, dir, idx )  
    return string.format( "%ssfx_%04d_%d_%d.png", ANIM_RES_PATH, rawAnimID, dir, idx )
end

function sequFrameAnimLoaderImpSkill:convertPlistFileNameByIdx( rawAnimID, sex, dir, idx ) 
    return string.format( "%ssfx_%04d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, dir, idx )
end

function sequFrameAnimLoaderImpSkill:convertFrameName( rawAnimID, sex, act, dir, frameID )
    return string.format( "sfx_%04d_%d_%04d.png", rawAnimID, dir, frameID )
end

function sequFrameAnimLoaderImpSkill:animResTextureLoad( animDataDesc, dir )
    -- 下载中，等待......
    local loadingID = self:UNITE_ID( animDataDesc.animID, dir )
    local downloadDesc = self._animDataInDownloading[loadingID]
    if downloadDesc then
        return
    end

    local animID = animDataDesc.animID
    local modelProxy = global.Facade:retrieveProxy( global.ProxyTable.ModelConfigProxy )
    local config = modelProxy:GetConfig( animID )
    if nil == config then
        self:animResConfigFailed(animDataDesc, dir)
        return
    end

    -- calc temporary ID
    local temporaryID = global.FrameAnimManager:GetAnimTemporaryID(animDataDesc.animType, animDataDesc.sex)

    -- out of memory
    if global.FrameAnimManager:isMemWarning(animDataDesc.animType) and animDataDesc.animID ~= temporaryID then
        self:animResMemoryWarning(animDataDesc, dir)
        return
    end

    -- check loading
    local atlasCount = modelProxy:GetSplitAtlas( animID, dir )
    if atlasCount then
        local addSpriteFramesCount = 0
        local isLoadSuccess = true
        local function addSpriteFramesCB(tex, plistOK)
            addSpriteFramesCount = addSpriteFramesCount-1
            
            if not plistOK or nil == tex then
                isLoadSuccess = false
            end
            
            if addSpriteFramesCount == 0 then
                self:animResTextureLoadCB( animDataDesc, dir, isLoadSuccess, isLoadSuccess, config )
            end
        end

        for idx = 0, atlasCount-1 do
            addSpriteFramesCount = addSpriteFramesCount+1

            local texFile = self:convertTexFileNameByIdx( animDataDesc.rawAnimID, animDataDesc.sex, dir, idx )
            local plistFile = self:convertPlistFileNameByIdx( animDataDesc.rawAnimID, animDataDesc.sex, dir, idx )
            if not global.SpriteFrameCache:isSpriteFramesWithFileLoaded(plistFile) then
                local function addImageCallback( tex, plistOK )
                    -- for memory record
                    global.FrameAnimManager:textureMemAdd(tex, texFile)
                    addSpriteFramesCB(tex, texFile)
                end
                global.SpriteFrameCache:addSpriteFramesWithFileAsync( plistFile, texFile, addImageCallback )
            else
                addSpriteFramesCB(true, true)
            end
        end
    else
        local texFile = self:convertTexFileName( animDataDesc.rawAnimID, animDataDesc.sex, dir )
        local plistFile = self:convertPlistFileName( animDataDesc.rawAnimID, animDataDesc.sex, dir )
        if not global.SpriteFrameCache:isSpriteFramesWithFileLoaded(plistFile) then
            local function addImageCallback( tex, plistOK )
                -- for memory record
                global.FrameAnimManager:textureMemAdd(tex, texFile)
                
                self:animResTextureLoadCB( animDataDesc, dir, tex, plistOK, config )
            end
            global.SpriteFrameCache:addSpriteFramesWithFileAsync( plistFile, texFile, addImageCallback )
        else
            self:animResTextureLoadCB( animDataDesc, dir, true, true, config )
        end
    end
end

function sequFrameAnimLoaderImpSkill:animResTextureLoadCB( animDataDesc, dir, tex, plistOK, config )
    if not plistOK or nil == tex then
        -- remove anim texture
        self:removeTextureCache(animDataDesc, dir)

        -- except temporary
        local temporaryID = global.FrameAnimManager:GetAnimTemporaryID(animDataDesc.animType, animDataDesc.sex)
        if animDataDesc.animID ~= temporaryID then
            -- remove texture
            local modelProxy = global.Facade:retrieveProxy( global.ProxyTable.ModelConfigProxy )
            local atlasCount = modelProxy:GetSplitAtlas( animDataDesc.animID, dir )
            if atlasCount and atlasCount > 1 then
                for idx = 0, atlasCount-1 do
                    -- del plist
                    local plistFile = self:convertPlistFileNameByIdx( animDataDesc.rawAnimID, animDataDesc.sex, dir, idx )
                    self:OnLoadFileError(plistFile)

                    -- del png
                    local texFile = self:convertTexFileNameByIdx( animDataDesc.rawAnimID, animDataDesc.sex, dir, idx )
                    self:OnLoadFileError(texFile)
                end
            else
                -- del plist
                local plistFile = self:convertPlistFileName( animDataDesc.rawAnimID, animDataDesc.sex, dir )
                self:OnLoadFileError(plistFile)

                -- del png
                local texFile = self:convertTexFileName( animDataDesc.rawAnimID, animDataDesc.sex, dir )
                self:OnLoadFileError(texFile)
            end
        end
    else
        -- creat sprite frame
        self:createAnimation( animDataDesc, dir, config )
    end
    
    -- notify
    if not plistOK then
        self:notifyCaller( animDataDesc, dir, global.MMO.ANIM_LOAD_FRAME )
    elseif nil == tex then
        self:notifyCaller( animDataDesc, dir, global.MMO.ANIM_LOAD_TEX )
    else
        self:notifyCaller( animDataDesc, dir, global.MMO.ANIM_LOAD_SUCCESS )
    end

    -- on load finish notice
    self:OnLoadingFinish()
end

function sequFrameAnimLoaderImpSkill:releaseCocosAnim( animDataDesc, act, actionDir  )
    local animIndex    = GetFrameAnimIndex( act, actionDir )
    local animFrameVec = animDataDesc.animFrameVecs[animIndex]
    if animFrameVec then
        for _, animFrame in ipairs( animFrameVec ) do
            if not tolua.isnull(animFrame) then
                animFrame:release()
            end
        end
    end
    animDataDesc.animFrameVecs[animIndex] = nil
end

function sequFrameAnimLoaderImpSkill:unloadSequAnim( animDataDesc )
    local animCount = global.MMO.ORIENT_LU
    local act       = global.MMO.ANIM_DEFAULT

    for dir = 0, animCount do
        if true == animDataDesc.frameLoaded[dir] then
            -- step1 cocos anim
            self:releaseCocosAnim( animDataDesc, act, dir )
            
            -- remove anim texture
            self:removeTextureCache(animDataDesc, dir)

            animDataDesc.frameLoaded[dir] = nil
        end
    end
end

function sequFrameAnimLoaderImpSkill:createAnimation( animDataDesc, dir, config )
    local animID   = animDataDesc.animID
    local sex      = animDataDesc.sex

    local frameName   = ""
    local spriteFrame = nil
    local animFrame   = nil
    local act         = global.MMO.ANIM_DEFAULT
    local animIndex   = GetFrameAnimIndex( act, dir )


    local animFrameVec = {}
    local animFrameCnt = 0

    for xy = 0, 100 do
        frameName = self:convertFrameName( animDataDesc.rawAnimID, sex, act, dir, xy )
        spriteFrame = global.SpriteFrameCache:getSpriteFrame( frameName, true )
        if spriteFrame then
            animFrame = cc.AnimationFrame:create( spriteFrame, 1, {} )
            animFrame:retain()

            animFrameCnt = animFrameCnt + 1
            animFrameVec[animFrameCnt] = animFrame
        else
            config.frame[act] = xy + 1
            break
        end
    end

    animDataDesc.animFrameVecs[animIndex]   = animFrameCnt > 0 and animFrameVec or nil
    animDataDesc.animDelays[animIndex]      = config.interval[act] or global.MMO.ANIM_DEFAULT_INTERVAL
    animDataDesc.frameLoaded[dir]           = true
end

function sequFrameAnimLoaderImpSkill:removeTextureCache(animDataDesc, dir)
    local modelProxy = global.Facade:retrieveProxy( global.ProxyTable.ModelConfigProxy )
    local config     = modelProxy:GetConfig( animDataDesc.animID )
    if not config then
        return 
    end

    local atlasCount = modelProxy:GetSplitAtlas( animDataDesc.animID, dir )
    if atlasCount and atlasCount > 1 then
        for idx = 0, atlasCount-1 do
            local texFile = self:convertTexFileNameByIdx( animDataDesc.rawAnimID, animDataDesc.sex, dir, idx )
            local plistFile = self:convertPlistFileNameByIdx( animDataDesc.rawAnimID, animDataDesc.sex, dir, idx )
            if global.SpriteFrameCache:isSpriteFramesWithFileLoaded( plistFile ) then
                global.SpriteFrameCache:removeSpriteFramesFromFile( plistFile )
                global.TextureCache:removeTextureForKey( texFile )
    
                -- for memory record
                global.FrameAnimManager:textureMemDel(texFile)
            end
        end
    else
        local texFile = self:convertTexFileName( animDataDesc.rawAnimID, animDataDesc.sex, dir )
        local plistFile = self:convertPlistFileName( animDataDesc.rawAnimID, animDataDesc.sex, dir )
        if global.SpriteFrameCache:isSpriteFramesWithFileLoaded( plistFile ) then
            global.SpriteFrameCache:removeSpriteFramesFromFile( plistFile )
            global.TextureCache:removeTextureForKey( texFile )
    
            -- for memory record
            global.FrameAnimManager:textureMemDel(texFile)
        end
    end
end

return sequFrameAnimLoaderImpSkill
