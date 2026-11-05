local actorSequFrameAnimManager = class("actorSequFrameAnimManager")
local actorSequenceFrameAnim    = require( "animation/actorSequenceFrameAnim" )
local Queue                     = requireUtil( "queue" )

local MMO                       = global.MMO
local rawTempID                 = 9999
local zeroPos                   = cc.p(0, 0)

local next                      = next
local pairs                     = pairs
local clone                     = clone
local tonumber                  = tonumber

local defaultSex                = GUIDefine.DEFAULT_SEX
local male                      = GUIDefine.Sex.MALE
local female                    = GUIDefine.Sex.FEMALE


-------------------------------------------------------------
local AnimDataDesc = class( "AnimDataDesc" )
function AnimDataDesc:ctor()
end

function AnimDataDesc:OnNew(animID, rawAnimID, sex, animType)
    --------- for loading ------------
    self.animID         = animID
    self.rawAnimID      = rawAnimID
    self.animType       = animType
    self.sex            = sex
    self.loadCallback   = nil
    ----------------------------------

    self.timeStamp      = os.time()
    self.loadStateUnit  = {}
    for i = 0, MMO.ANIM_COUNT - 1 do
        self.loadStateUnit[i] = MMO.LOAD_STATE_UNLOADING
    end
    
    -- 
    self.hudTop         = 20
    self.offsetX        = 0
    self.offsetY        = 0
    self.animDelays     = {}          -- with ANIM_ACT * ORIENT ;
    self.animFrameVecs  = {}          -- with ANIM_ACT * ORIENT ;contain cocos obj[]
    self.frameLoaded    = {}
    self.ignoreSync     = false
    self.enlarge        = 1
    self.standPointX    = 0.5
    self.standPointY    = 0.5
    self.blendMode      = 0
    self.hasShadow      = true

    -- OOM 
    self.loadOOMUnit    = {}
end

local InUses = {
    [MMO.LOAD_STATE_LOADING] = 1,
    [MMO.LOAD_STATE_INUSED]  = 1,
    [MMO.LOAD_STATE_FOREVER] = 1,
    [MMO.LOAD_STATE_FAILED]  = 1,
}

function AnimDataDesc:checkIsInUsed()
    for i = 0, MMO.ANIM_COUNT - 1 do
        if InUses[self.loadStateUnit[i]] then
            return true
        end
    end
    return false
end

function AnimDataDesc:setUnused()
    for i = 0, MMO.ANIM_COUNT - 1 do
        if MMO.LOAD_STATE_INUSED == self.loadStateUnit[i] or MMO.LOAD_STATE_FAILED == self.loadStateUnit[i] then
            self.loadStateUnit[i] = MMO.LOAD_STATE_UNUSED
        end
    end

    self.timeStamp = os.time()
end
-------------------------------------------------------------

-------------------------------------------------------------
local AnimDataDescCache = class("AnimDataDescCache")
function AnimDataDescCache:ctor()
    self._cache = {}
end

function AnimDataDescCache:Alloc()
	local notification = table.remove(self._cache) or AnimDataDesc.new()
	return notification
end

function AnimDataDescCache:Recycle(task)
	table.insert(self._cache, task)
end
-------------------------------------------------------------


function actorSequFrameAnimManager:ctor()
    self._animDataMgr           = {}
    self._animRefsMgr           = {}
    self._animLoaders           = {}
    self._animLoadQueue         = Queue.new()
    self._animDescCache         = AnimDataDescCache.new()
    
    self._memoryInfo            = {}
    self._memorySize            = 0
    self._memoryWarning         = 400 * 1024 * 1024
    self._memoryCleanup         = 350 * 1024 * 1024
    
    self._loadingCount          = 0
    self._loadingLimit          = 3
    self._expiredInterval       = 30
    self._forNextUnloadFrame    = 0
    
    self._globalElapsed         = 0
    self._animFrameVecEmpty     = {}
    self._fileExistCache        = {}
end

function actorSequFrameAnimManager:textureMemAdd(texture, filename)
    if not texture then
        return
    end
    if self._memoryInfo[filename] then
        return
    end

    local bpp = texture:getBitsPerPixelForFormat()
    local bytes = texture:getPixelsWide() * texture:getPixelsHigh() * bpp / 8
    self._memoryInfo[filename] = bytes
    self._memorySize = self._memorySize + bytes

    -- log
    -- print("++++++++++++++++ANIM MEMORY ADD", filename, self._memorySize / 1024 / 1024)
end

function actorSequFrameAnimManager:textureMemDel(filename)
    if not self._memoryInfo[filename] then
        return
    end

    local bytes         = self._memoryInfo[filename] or 0
    self._memorySize    = self._memorySize - bytes
    self._memoryInfo[filename] = nil

    -- log
    -- print("----------------ANIM MEMORY DEL", filename, self._memorySize / 1024 / 1024)
end

function actorSequFrameAnimManager:isMemWarning(animType)
    -- PC不限制
    -- if global.isWindows then
    --     return false
    -- end

    -- NPC特效不限制
    if animType == MMO.SFANIM_TYPE_NPC then
        return false
    end

    return self._memorySize >= self._memoryWarning
end

function actorSequFrameAnimManager:checkMemEnough()
    -- 50M 50*1024*1024
    return self._memorySize >= (self._memoryWarning - 52428800)
end

function actorSequFrameAnimManager:setMemWarningInMB(size)
    size = size or 500
    self._memoryWarning = size * 1024 * 1024
    self._memoryCleanup = (size-50) * 1024 * 1024
end

function actorSequFrameAnimManager:isMemCleanup()
    -- PC不限制
    -- if global.isWindows then
    --     return false
    -- end
    
    return self._memorySize >= self._memoryCleanup
end

local BlendFunc = {
    [1] = function (anim)
        anim:setBlendFunc(MMO.add_blend_func)           -- add
    end,
    [2] = function (anim)
        anim:setBlendFunc(MMO.screen_blend_func)        -- screen
    end,
    [3] = function (anim)
        anim:setBlendFunc(MMO.overlying_blend_func)     -- 叠加
    end,
    [4] = function (anim)
        anim:setBlendFunc(MMO.ALPHA_PREMULTIPLIED)      -- 无
    end,
    [-1] = function (anim)
        anim:setBlendFunc(MMO.normal_blend_func)
    end,
}
function actorSequFrameAnimManager:setBlendFunc(anim, blendType)
    if not anim then
        return false
    end
    return (BlendFunc[blendType] or BlendFunc[-1])(anim)
end

function actorSequFrameAnimManager:Init()
    print( "init FrameAnimManager" )

    local playerAnimLoader  = require( "animation/sequFrameAnimLoaderImpPlayer" )
    local weaponAnimLoader  = require( "animation/sequFrameAnimLoaderImpWeapon" )
    local shieldAnimLoader  = require( "animation/sequFrameAnimLoaderImpShield" )
    local wingsAnimLoader   = require( "animation/sequFrameAnimLoaderImpWings" )
    local hairAnimLoader    = require( "animation/sequFrameAnimLoaderImpHair" )
    local monsterAnimLoader = require( "animation/sequFrameAnimLoaderImpMonster" )
    local npcAnimLoader     = require( "animation/sequFrameAnimLoaderImpNpc" )
    local skillAnimLoader   = require( "animation/sequFrameAnimLoaderImpSkill" )

    self._animLoaders[MMO.SFANIM_TYPE_PLAYER]  = playerAnimLoader.new()
    self._animLoaders[MMO.SFANIM_TYPE_WEAPON]  = weaponAnimLoader.new()
    self._animLoaders[MMO.SFANIM_TYPE_SHIELD]  = shieldAnimLoader.new()
    self._animLoaders[MMO.SFANIM_TYPE_WINGS]   = wingsAnimLoader.new()
    self._animLoaders[MMO.SFANIM_TYPE_HAIR]    = hairAnimLoader.new()
    self._animLoaders[MMO.SFANIM_TYPE_MONSTER] = monsterAnimLoader.new()
    self._animLoaders[MMO.SFANIM_TYPE_NPC]     = npcAnimLoader.new()
    self._animLoaders[MMO.SFANIM_TYPE_SKILL]   = skillAnimLoader.new()


    for i = 1, MMO.SFANIM_TYPE_NUM do
        self._animDataMgr[i] = {}
        self._animRefsMgr[i] = {}
    end


    --------------------------------------- Player ---------------------------------------
    self:InitTemporaryPlayer(male, MMO.SFANIM_TYPE_PLAYER)
    self:InitTemporaryPlayer(female, MMO.SFANIM_TYPE_PLAYER)

    -- --------------------------------------- Weapon ---------------------------------------
    -- self:InitTemporaryPlayer(male, MMO.SFANIM_TYPE_WEAPON)
    -- self:InitTemporaryPlayer(female, MMO.SFANIM_TYPE_WEAPON)
    
    --------------------------------------- Hair ---------------------------------------
    -- self:InitTemporaryPlayer(male, MMO.SFANIM_TYPE_HAIR)
    -- self:InitTemporaryPlayer(female, MMO.SFANIM_TYPE_HAIR)

    -- --------------------------------------- Shield ---------------------------------------
    -- self:InitTemporaryPlayer(male, MMO.SFANIM_TYPE_SHIELD)
    -- self:InitTemporaryPlayer(female, MMO.SFANIM_TYPE_SHIELD)

    -- --------------------------------------- Wings ---------------------------------------
    -- self:InitTemporaryPlayer(male, MMO.SFANIM_TYPE_WINGS)
    -- self:InitTemporaryPlayer(female, MMO.SFANIM_TYPE_WINGS)

    --------------------------------------- Monster ---------------------------------------
    -- self:InitTemporaryMonster()

    --------------------------------------- NPC ---------------------------------------
    -- self:InitTemporaryNpc()

    --------------------------------------- Skill ---------------------------------------
    -- self:InitTemporarySFX()
    
    --------------------------------------- Empty Temp ---------------------------------------
    if global.FileUtilCtl:isFileExist("res/public/0.png") then
        self:InitEmptyFrameVec()
    else
        global.ResDownloader:download("res/public/0.png", function(isOK)
            if isOK then
                self:InitEmptyFrameVec()
            end
        end) 
    end
end

function actorSequFrameAnimManager:InitEmptyFrameVec()
    local spriteFrame = cc.SpriteFrame:create("res/public/0.png", cc.rect(0, 0, 1, 1))
    for i = 1, 6 do
        local animFrame = cc.AnimationFrame:create( spriteFrame, 1, {} )
        animFrame:retain()
        table.insert(self._animFrameVecEmpty, animFrame)
    end
end


function actorSequFrameAnimManager:Cleanup()
    for i = 1, MMO.SFANIM_TYPE_NUM do
        local datas = self._animDataMgr[i]
        if nil == datas then break end
        for k, animDataDesc in pairs(datas) do
            if self._animLoaders[i] then
                self._animLoaders[i]:unloadSequAnim( animDataDesc )
            end
        end


        -- may be unnecessary
        local animRefs = self._animRefsMgr[i]
        for animID, anims in pairs( animRefs ) do
            for _, item in pairs( anims ) do
                item.animInst:Cleanup()
            end
        end


        if self._animLoaders[i] then
            self._animLoaders[i]:Cleanup()
            self._animLoaders[i] = nil
        end

        self._animDataMgr[i] = {}
        self._animRefsMgr[i] = {}
    end

    for k, v in pairs(self._animFrameVecEmpty) do
        v:release()
    end
    self._animFrameVecEmpty = {}

    -- cleanup loading
    self._animLoadQueue:reset()
    self._loadingCount = 0

    self._fileExistCache = {}
end

function actorSequFrameAnimManager:RecoverLoadingState()
    for i = 1, MMO.SFANIM_TYPE_NUM do
        local loader = self._animLoaders[i]
        local animDataMgr = self._animDataMgr[i]
        if loader and animDataMgr then
            loader:Cleanup()

            for _, animDataDesc in pairs(animDataMgr) do
                for act = 0, MMO.ANIM_COUNT - 1 do
                    if animDataDesc.loadStateUnit[act] == MMO.LOAD_STATE_LOADING then
                        animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_UNLOADING
                    end
                end
            end
        end
    end

    self._animLoadQueue:reset()
    self._loadingCount = 0
end

function actorSequFrameAnimManager:refreshAnimData( animDataDesc, act )
    -- Mark animation data has loaded.
    local animID      = animDataDesc.animID
    local rawAnimID   = animDataDesc.rawAnimID
    local sex         = animDataDesc.sex
    local animType    = animDataDesc.animType
    local animDataMgr = self._animDataMgr[animType]
    local animRefsMgr = self._animRefsMgr[animType]

    -- connect to sequence animation
    local seqFrmAnims   = animRefsMgr[animID]

    local anim = nil
    for k,v in pairs( seqFrmAnims ) do
        anim = v.animInst

        -- 刷新属性
        self:refreshAnimAttr(anim)

        if anim:CheckCurrUnit( act ) then
            -- reset play
            anim:resetAnimPlay(act)
        end

        if v.extCB then
            v.extCB( animID, anim, animType )
        end
    end
end

function actorSequFrameAnimManager:loadAnimDataError( animDataDesc, act )
    -- Mark animation data has loaded.
    local animID      = animDataDesc.animID
    local rawAnimID   = animDataDesc.rawAnimID
    local sex         = animDataDesc.sex
    local animType    = animDataDesc.animType
    local animRefsMgr = self._animRefsMgr[animType]

    -- connect to sequence animation
    local seqFrmAnims = animRefsMgr[animID]
    local anim = nil
    for k,v in pairs( seqFrmAnims ) do
        anim = v.animInst
        anim:onAnimationLoadError( animID, anim )
    end
end

local animTypeName = { "player", "monster", "npc", "sfx", "sfx", "weapon", "shield", "wings", "hair" }
local loadErrorMsg = { "LOAD_SPRITES_ERROR", "LOAD_TEX_ERROR", "CONFIG_ERROR" }
function actorSequFrameAnimManager:onAnimDataLoadCompleted( animDataDesc, act, loadcode )
    if loadcode ~= MMO.ANIM_LOAD_SUCCESS then
        local lastLoadState = animDataDesc.loadStateUnit[act]

        if self:IsReferenced( animDataDesc.animType, animDataDesc.rawAnimID, animDataDesc.sex ) then
            -- LOADING --> FAILED
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_FAILED
        else
            -- LOADING --> UNUSED
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_UNUSED
        end

        -- load error, OOM, record, need refresh again
        animDataDesc.loadOOMUnit[act] = lastLoadState == MMO.ANIM_LOAD_OOM

        -- load error
        self:loadAnimDataError( animDataDesc, act )
    else
        if self:IsReferenced( animDataDesc.animType, animDataDesc.rawAnimID, animDataDesc.sex ) then
            -- LOADING --> INUSED
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_INUSED
        else
            -- LOADING --> UNUSED
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_UNUSED
        end

        -- oom flag
        animDataDesc.loadOOMUnit[act] = nil

        local animID        = animDataDesc.animID
        local animType      = animDataDesc.animType
        local config        = self:GetAnimConfig( animID, animType )
        self:setAnimDataDescByConfig(animDataDesc, config)

        -- refresh sequence animations that were associated by animation data.
        self:refreshAnimData( animDataDesc, act )
    end
end

local SharedPoint = {}
function actorSequFrameAnimManager:refreshAnimAttr( anim )
    -- set blend func
    self:setBlendFunc( anim, anim:GetBlendMode() )

    -- set anchor point
    SharedPoint.x = anim:GetStandPointX()
    SharedPoint.y = anim:GetStandPointY()
    anim:setAnchorPoint(SharedPoint)

    -- set position
    anim:setPosition(anim:getTurePosition())
end

function actorSequFrameAnimManager:cloneTemporaryAnimDesc( animDataDesc, tempAnimDataDesc )
    if tempAnimDataDesc then
        animDataDesc.hasShadow      = tempAnimDataDesc.hasShadow
        animDataDesc.blendMode      = tempAnimDataDesc.blendMode
        animDataDesc.standPointX    = tempAnimDataDesc.standPointX
        animDataDesc.standPointY    = tempAnimDataDesc.standPointY
        animDataDesc.ignoreSync     = tempAnimDataDesc.ignoreSync
        animDataDesc.hudTop         = tempAnimDataDesc.hudTop
        animDataDesc.boxWidth       = tempAnimDataDesc.width
        animDataDesc.boxHeight      = tempAnimDataDesc.height
        animDataDesc.offsetX        = tempAnimDataDesc.offsetX
        animDataDesc.offsetY        = tempAnimDataDesc.offsetY
        animDataDesc.animDelays     = clone(tempAnimDataDesc.animDelays)
        for k, v in pairs(tempAnimDataDesc.animFrameVecs) do
            animDataDesc.animFrameVecs[k] = v
        end
    end
end

function actorSequFrameAnimManager:setAnimDataDescByConfig( animDataDesc, config )
    if config then
        animDataDesc.offsetX        = config.offsetx or 0
        animDataDesc.offsetY        = config.offsety or 0
        animDataDesc.ignoreSync     = tonumber(config.ignoreSync) == 1
        animDataDesc.standPointX    = config.stand_pos_x or 0.5
        animDataDesc.standPointY    = config.stand_pos_y or 0.5
        animDataDesc.blendMode      = config.blendmode or 0
        animDataDesc.hasShadow      = config.shadow ~= 1
        animDataDesc.hudTop         = config.hud_top
        animDataDesc.boxWidth       = config.width
        animDataDesc.boxHeight      = config.height
    end
end

function actorSequFrameAnimManager:createSequFrmAnimAsync( rawAnimID, sex, animType, act, extCB, immediate )
    rawAnimID = tonumber(rawAnimID)
    animType = tonumber(animType)
    sex = tonumber(sex)
    if not rawAnimID or not sex then
        return nil
    end

    local animLoader  = self._animLoaders[animType]
    local animDataMgr = self._animDataMgr[animType]
    local animRefsMgr = self._animRefsMgr[animType]
    if not animDataMgr or not animRefsMgr or not animLoader then
        return nil
    end

    local newAnim  = actorSequenceFrameAnim.new()

    -- convert animID
    local animID        = self:KEY_ID_SEX( rawAnimID, sex, animType )
    local config        = self:GetAnimConfig( animID, animType )
    local isNeedLoad    = false
    local animDataDesc  = animDataMgr[animID]
    if nil == animDataDesc then
        -- Animation Data dose not exist
        isNeedLoad = true

        animDataDesc           = self._animDescCache:Alloc()
        animDataDesc:OnNew(animID, rawAnimID, sex, animType)
        animDataMgr[animID]    = animDataDesc

        -- find temporary
        local tempID           = self:GetAnimTemporaryID( animType, sex )
        local tempAnimDataDesc = animDataMgr[tempID]
        self:cloneTemporaryAnimDesc(animDataDesc, tempAnimDataDesc)

        -- load anim data desc
        if animType == MMO.SFANIM_TYPE_SKILL or not tempAnimDataDesc then
            self:setAnimDataDescByConfig(animDataDesc, config)
        end
    else
        -- UNUSED --> INUSED
        if MMO.LOAD_STATE_UNUSED == animDataDesc.loadStateUnit[act] then
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_INUSED
        end

        -- if in unloading, begin load
        if MMO.LOAD_STATE_UNLOADING == animDataDesc.loadStateUnit[act] then
            isNeedLoad = true
        end

        -- load failed,  try again
        if MMO.LOAD_STATE_FAILED == animDataDesc.loadStateUnit[act] then
            isNeedLoad = true
        end

        -- load anim data desc
        self:setAnimDataDescByConfig(animDataDesc, config)
    end

    -- enlarge 不等加载成功，均使用配置表真正的缩放，
    if config then
        animDataDesc.enlarge = config and config.enlarge or 1
    end

    -- bind animation data
    newAnim:SetAnimDataDesc(animDataDesc)

    -- reset position
    newAnim:setPosition(zeroPos)
    
    -- set scale
    newAnim:setScale(newAnim:GetEnlarge())

    ----------------------------------------------------------
    self:refreshAnimAttr(newAnim)

    -- to reference map
    if not animRefsMgr[animID] then animRefsMgr[animID] = {} end
    local refIndex      = #animRefsMgr[animID] + 1
    newAnim.refIndex    = refIndex
    local animRef       = {}
    animRef.animInst    = newAnim
    animRef.extCB       = extCB
    animRefsMgr[animID][refIndex] = animRef

    -- load
    if isNeedLoad then
        self:loadSequFrmAnimUnit( animDataDesc, act, immediate )
    end

    return newAnim
end

function actorSequFrameAnimManager:resetSequFrmAnimAsync( anim, rawAnimID, sex, animType, act, extCB, immediate )
    rawAnimID = tonumber(rawAnimID)
    animType = tonumber(animType)
    sex = tonumber(sex)
    if not anim or not rawAnimID or not sex then
        return nil
    end

    local animLoader  = self._animLoaders[animType]
    local animDataMgr = self._animDataMgr[animType]
    local animRefsMgr = self._animRefsMgr[animType]
    if not animDataMgr or not animRefsMgr or not animLoader then
        return nil
    end
    
    -- remove from reference map
    local refIndex          = anim.refIndex
    local lastAnimDataDesc  = anim:GetAnimDataDesc()
    local lastAnimID        = lastAnimDataDesc.animID
    animRefsMgr[lastAnimID][refIndex] = nil

    self:CheckSequAnimUnused(anim)

    -- convert animID
    local animID            = self:KEY_ID_SEX( rawAnimID, sex, animType )
    local config            = self:GetAnimConfig( animID, animType )
    local isNeedLoad        = false
    local animDataDesc      = animDataMgr[animID]
    if nil == animDataDesc then
        -- Animation Data dose not exist
        isNeedLoad = true

        animDataDesc           = self._animDescCache:Alloc()
        animDataDesc:OnNew( animID, rawAnimID, sex, animType )
        animDataMgr[animID]    = animDataDesc

        -- find temporary
        local tempID           = self:GetAnimTemporaryID( animType, sex )
        local tempAnimDataDesc = animDataMgr[tempID]
        self:cloneTemporaryAnimDesc(animDataDesc, tempAnimDataDesc)

        -- load anim data desc
        if animType == MMO.SFANIM_TYPE_SKILL or not tempAnimDataDesc then
            self:setAnimDataDescByConfig(animDataDesc, config)
        end
    else
        -- UNUSED --> INUSED
        if MMO.LOAD_STATE_UNUSED == animDataDesc.loadStateUnit[act] then
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_INUSED
        end

        -- if in unloading, begin load
        if MMO.LOAD_STATE_UNLOADING == animDataDesc.loadStateUnit[act] then
            isNeedLoad = true
        end

        -- load failed,  try again
        if MMO.LOAD_STATE_FAILED == animDataDesc.loadStateUnit[act] then
            isNeedLoad = true
        end
        
        -- load anim data desc
        self:setAnimDataDescByConfig(animDataDesc, config)
    end

    -- enlarge 不等加载成功，均使用配置表真正的缩放，
    if config then
        animDataDesc.enlarge = config and config.enlarge or 1
    end
    
    -- bind animation data
    anim:SetAnimDataDesc(animDataDesc)

    -- reset position 0
    anim:setPosition(zeroPos)

    -- set scale
    anim:setScale(anim:GetEnlarge())

    ----------------------------------------------------------
    self:refreshAnimAttr(anim)

    -- to reference map
    if not animRefsMgr[animID] then animRefsMgr[animID] = {} end
    local refIndex      = #animRefsMgr[animID] + 1
    anim.refIndex       = refIndex
    local animRef       = {}
    animRef.animInst    = anim
    animRef.extCB       = extCB
    animRefsMgr[animID][refIndex] = animRef

    -- load
    if isNeedLoad then
        self:loadSequFrmAnimUnit( animDataDesc, act, immediate )
    end

    return anim
end

function actorSequFrameAnimManager:loadSequFrmAnimUnit( animDataDesc, act, immediate )
    -- 1.check load flag
    if( MMO.LOAD_STATE_UNLOADING ~= animDataDesc.loadStateUnit[act] and MMO.LOAD_STATE_FAILED ~= animDataDesc.loadStateUnit[act] ) then
        return
    end

    -- 2.record load state
    animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_LOADING

    -- 3.loading
    local function loadCallback( loadAct, loadcode )
        self:onAnimDataLoadCompleted( animDataDesc, loadAct, loadcode )
    end
    animDataDesc.loadCallback = loadCallback
    self:loadAnim( animDataDesc, act, immediate )
end

function actorSequFrameAnimManager:loadAnim( animDataDesc, act, immediate )
    local animType = animDataDesc.animType
    if animType <= 0 or animType > MMO.SFANIM_TYPE_NUM then
        return 
    end

    local animLoader = self._animLoaders[animType]

    -- 立即下载
    animLoader:downloadSequAnim( animDataDesc, act )

    if not immediate then
        local loadDesc = {
            animDataDesc = animDataDesc,
            animLoader   = animLoader,
            act          = act,
        }
        self._animLoadQueue:push( loadDesc )
    else
        animLoader:loadSequAnim( animDataDesc, act )
    end
end

function actorSequFrameAnimManager:KEY_ID_SEX( id, sex, animType )
    return GetFrameAnimConfigID( id, sex, animType )
end

-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorPlayerAnim( clothID, sex, act, extCB, immediate )
    return self:createSequFrmAnimAsync( clothID, sex, MMO.SFANIM_TYPE_PLAYER, act, extCB, immediate )
end                                                                      
function actorSequFrameAnimManager:ResetActorPlayerAnim( anim, clothID, sex, act, extCB, immediate )
    return self:resetSequFrmAnimAsync( anim, clothID, sex, MMO.SFANIM_TYPE_PLAYER, act, extCB, immediate )
end  
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorPlayerWeaponAnim( weaponID, sex, act, extCB, immediate )
    return self:createSequFrmAnimAsync( weaponID, sex, MMO.SFANIM_TYPE_WEAPON, act, extCB, immediate )
end
function actorSequFrameAnimManager:ResetActorPlayerWeaponAnim( anim, weaponID, sex, act, extCB, immediate )
    return self:resetSequFrmAnimAsync( anim, weaponID, sex, MMO.SFANIM_TYPE_WEAPON, act, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorPlayerHairAnim( hairID, sex, act, extCB, immediate )
    return self:createSequFrmAnimAsync( hairID, sex, MMO.SFANIM_TYPE_HAIR, act, extCB, immediate )
end
function actorSequFrameAnimManager:ResetActorPlayerHairAnim( anim, hairID, sex, act, extCB, immediate )
    return self:resetSequFrmAnimAsync( anim, hairID, sex, MMO.SFANIM_TYPE_HAIR, act, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorPlayerShieldAnim( shieldID, sex, act, extCB, immediate )
    return self:createSequFrmAnimAsync( shieldID, sex, MMO.SFANIM_TYPE_SHIELD, act, extCB, immediate )
end
function actorSequFrameAnimManager:ResetActorPlayerShieldAnim( anim, shieldID, sex, act, extCB, immediate )
    return self:resetSequFrmAnimAsync( anim, shieldID, sex, MMO.SFANIM_TYPE_SHIELD, act, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorPlayerWingsAnim( wingsID, sex, act, extCB, immediate )
    return self:createSequFrmAnimAsync( wingsID, sex, MMO.SFANIM_TYPE_WINGS, act, extCB, immediate )
end
function actorSequFrameAnimManager:ResetActorPlayerWingsAnim( anim, wingsID, sex, act, extCB, immediate )
    return self:resetSequFrmAnimAsync( anim, wingsID, sex, MMO.SFANIM_TYPE_WINGS, act, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorMountPlayerAnim( mountID, sex, act, extCB, immediate )
    return self:createSequFrmAnimAsync( mountID, sex, MMO.SFANIM_TYPE_MOUNT_PLAYER, act, extCB, immediate )
end
function actorSequFrameAnimManager:ResetActorMountPlayerAnim( anim, mountID, sex, act, extCB, immediate )
    return self:resetSequFrmAnimAsync( anim, mountID, sex, MMO.SFANIM_TYPE_MOUNT_PLAYER, act, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorMountBodyAnim( mountID, act, extCB, immediate )
    return self:createSequFrmAnimAsync( mountID, MMO.SFANIM_TYPE_MOUNT_BODY, act, extCB, immediate )
end
function actorSequFrameAnimManager:ResetActorMountBodyAnim( anim, mountID, act, extCB, immediate )
    return self:resetSequFrmAnimAsync( anim, mountID, MMO.SFANIM_TYPE_MOUNT_BODY, act, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorMountHeadAnim( mountID, act, extCB, immediate )
    return self:createSequFrmAnimAsync( mountID, defaultSex, MMO.SFANIM_TYPE_MOUNT_HEAD, act, extCB, immediate )
end
function actorSequFrameAnimManager:ResetActorMountHeadAnim( anim, mountID, act, extCB, immediate )
    return self:resetSequFrmAnimAsync( anim, mountID, defaultSex, MMO.SFANIM_TYPE_MOUNT_HEAD, act, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorMonsterAnim( monsterID, act, extCB, sex, immediate )
    return self:createSequFrmAnimAsync( monsterID, sex or defaultSex, MMO.SFANIM_TYPE_MONSTER, act, extCB, immediate )
end
function actorSequFrameAnimManager:ResetActorMonsterAnim( anim, monsterID, act, extCB, sex, immediate )
    return self:resetSequFrmAnimAsync( anim, monsterID, sex or defaultSex, MMO.SFANIM_TYPE_MONSTER, act, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateActorNpcAnim( npcID, extCB, immediate )
    return self:createSequFrmAnimAsync( npcID, defaultSex, MMO.SFANIM_TYPE_NPC, MMO.ANIM_DEFAULT, extCB, immediate )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateSkillEffAnim( skillID, dir, extCB, immediate )
    dir = dir or MMO.ORIENT_U
    local ret = self:createSequFrmAnimAsync( skillID, defaultSex, MMO.SFANIM_TYPE_SKILL, dir, extCB, immediate )
    return ret
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CreateSFXAnim( sfxID, dir, extCB, immediate)
    dir = dir or MMO.ORIENT_U
    local ret = self:createSequFrmAnimAsync( sfxID, defaultSex, MMO.SFANIM_TYPE_SKILL, dir, extCB, immediate )
    return ret
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:LoadAnimUnit( animID, animType, unitID )
    if animType < 0 or animType > MMO.SFANIM_TYPE_NUM then
        return nil
    end

    if 0 > unitID or unitID > MMO.ANIM_COUNT then
        return nil
    end

    local animDataMgr = self._animDataMgr[animType]
    local animDataDesc = animDataMgr[animID]
    if animDataDesc then
        self:loadSequFrmAnimUnit( animDataDesc, unitID, false )
    end
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CheckSequAnimUnused(anim)
    local animDataDesc  = anim:GetAnimDataDesc()
    local animID        = animDataDesc.animID
    local animType      = animDataDesc.animType
    local rawAnimID     = animDataDesc.rawAnimID
    local animRefsMgr = self._animRefsMgr[animType]
    local animDataMgr = self._animDataMgr[animType]
    local seqFrmAnims = animRefsMgr[ animID ]

    if rawAnimID ~= rawTempID and nil == next(seqFrmAnims) then
        -- mark unused 
        animDataDesc:setUnused()

        local rawAnimID = animDataDesc.rawAnimID
        local sex = animDataDesc.sex
        -- print( string.format( "reset,  anim is unused:[type:%d][rawAnimID:%d][sex:%d]", animType, rawAnimID, sex ) )
    end
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:RemoveSequAnim( anim )
    -- Mark animation data has loaded.
    local animDataDesc  = anim:GetAnimDataDesc()
    local animID        = animDataDesc.animID
    local animType      = animDataDesc.animType
    local rawAnimID     = animDataDesc.rawAnimID
    local animRefsMgr   = self._animRefsMgr[animType]
    local seqFrmAnims   = animRefsMgr[ animID ]

    local refIndex = anim.refIndex
    seqFrmAnims[refIndex] = nil

    if rawAnimID ~= rawTempID and nil == next(seqFrmAnims) then
        -- mark unused 
        animDataDesc:setUnused()

        local rawAnimID = animDataDesc.rawAnimID
        local sex = animDataDesc.sex
        -- print( string.format( "remove, anim is unused:[type:%d][rawAnimID:%d][sex:%d]", animType, rawAnimID, sex ) )
    end
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:Tick(dt)
    self._globalElapsed = self._globalElapsed + dt

    -- Check unsued animation data periodically
    if self._forNextUnloadFrame <= 0 then
        self:unloadExpiredAnimData()
        self._forNextUnloadFrame = 10
    end
    if self._forNextUnloadFrame > 0 then
        self._forNextUnloadFrame = self._forNextUnloadFrame - 1
    end

    if self._animLoadQueue:size() > 0 and self:CheckAbleLoading() == true then
        local loadDesc      = self._animLoadQueue:pop()
        local animLoader    = loadDesc.animLoader
        local animDataDesc  = loadDesc.animDataDesc
        local referenced    = self:IsReferenced( animDataDesc.animType, animDataDesc.rawAnimID, animDataDesc.sex )
        if referenced then
            animLoader:loadSequAnim( animDataDesc, loadDesc.act )
        else
            animDataDesc.loadStateUnit[loadDesc.act] = MMO.LOAD_STATE_UNLOADING
        end
    end
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:CheckAbleLoading()
    return self._loadingCount < self._loadingLimit
end
function actorSequFrameAnimManager:GetLoadingCount()
    return self._loadingCount
end
function actorSequFrameAnimManager:AddLoadingCount()
    self._loadingCount = self._loadingCount + 1
end
function actorSequFrameAnimManager:DecLoadingCount()
    if self._loadingCount > 0 then
        self._loadingCount = self._loadingCount - 1
    end
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:IS_EXPIRED( intvl )            
    return self._expiredInterval <= intvl
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:unloadExpiredAnimData()
    local currTime    = os.time()
    local animDataMgr = nil

    for i = 1, MMO.SFANIM_TYPE_NUM do
        animDataMgr = self._animDataMgr[i]
        for k, animDataDesc in pairs(animDataMgr) do
            if not animDataDesc:checkIsInUsed() then
                if self:IS_EXPIRED( currTime - animDataDesc.timeStamp ) then
                    -- unload
                    print(string.format("Anim data is EXPIRED, ID[%d] TYPE[%s]", animDataDesc.rawAnimID, animTypeName[i]))
                    self._animLoaders[i]:unloadSequAnim( animDataDesc )

                    -- 回收
                    animDataMgr[k] = nil
                    self._animDescCache:Recycle(animDataDesc)

                    -- reload OOM ANIM
                    if self:checkMemEnough() then
                        for animType, animDataMgr in pairs(self._animDataMgr) do
                            for animID, vAnimDataDesc in pairs(animDataMgr) do
                                if next(vAnimDataDesc.loadOOMUnit) then
                                    for act, _ in pairs(vAnimDataDesc.loadOOMUnit) do
                                        vAnimDataDesc.loadOOMUnit[act] = nil
                                        self:loadAnim(vAnimDataDesc, act)
                                        break
                                    end
                                end
                            end
                        end
                    end

                    -- unload one
                    return
                end
            end
        end
    end
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:unloadUnusedAnimData()
    local animDataMgr = nil
    for i = 1, MMO.SFANIM_TYPE_NUM do
        animDataMgr = self._animDataMgr[i]
        for k, animDataDesc in pairs(animDataMgr) do
            if not animDataDesc:checkIsInUsed() then
                -- unload
                print(string.format("Anim data is UNUSED, ID[%d] TYPE[%s]", animDataDesc.rawAnimID, animTypeName[i]))
                self._animLoaders[i]:unloadSequAnim( animDataDesc )
                animDataMgr[k] = nil             

                -- unload one
                return true
            end
        end
    end
    return false
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:unloadUnusedAnimDataByTypeID(sfxType, sfxID)
    local animDataMgr = self._animDataMgr[sfxType]
    if not animDataMgr then
        return false
    end

    for k, animDataDesc in pairs(animDataMgr) do
        if sfxID == animDataDesc.rawAnimID and (not animDataDesc:checkIsInUsed()) then
            -- unload
            print(string.format("Anim data is UNUSED, ID[%d] TYPE[%s]", sfxID, animTypeName[sfxType]))
            self._animLoaders[sfxType]:unloadSequAnim( animDataDesc )
            animDataMgr[k] = nil             
            break
        end
    end
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:unloadAllUnusedAnimData()
    while true do
        if (not self:unloadUnusedAnimData()) then
            break
        end
    end
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:GetAnimTemporaryID( animType, sex )
    sex = nil == sex and defaultSex or sex
    return self:KEY_ID_SEX( rawTempID, sex, animType )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:GetAnimConfig( animID, animType )
    if animType < 0 or animType > MMO.SFANIM_TYPE_NUM then
        return nil
    end

    return self._animLoaders[animType]:getConfig( animID )
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:GetAnimTotalDuration( rawAnimID, animType, action, sex )
    local ret    = 0.51 -- default value
    sex          = nil == sex and defaultSex or sex
    rawAnimID    = nil == rawAnimID and self:GetAnimTemporaryID( animType, sex ) or rawAnimID
    local animID = self:KEY_ID_SEX( rawAnimID, sex, animType )
    local config = self:GetAnimConfig( animID, animType )
    if not config then  -- get temporary config
        config = self:GetAnimConfig( self:GetAnimTemporaryID( animType, sex ), animType )
    end

    if config then
        local interval = config.interval[action]
        local frame = config.frame[action]
        if interval and frame then
            ret = interval * frame
        end
    end

    return ret
end
-----------------------------------------------------------------------------
function actorSequFrameAnimManager:IsLoaded( animType, rawAnimID, sex )
    if animType <= 0 or animType > MMO.SFANIM_TYPE_NUM then
        return false
    end

    local animID = self:KEY_ID_SEX( rawAnimID, sex, animType )


    local itr = self._animRefsMgr[animType][animID]
    if itr == nil then
        return false
    end

    return true
end

function actorSequFrameAnimManager:IsReferenced( animType, rawAnimID, sex )
    if animType <= 0 or animType > MMO.SFANIM_TYPE_NUM then
        return false
    end

    local animID = self:KEY_ID_SEX( rawAnimID, sex, animType )

    local seqFrmAnims = self._animRefsMgr[animType][animID]
    if seqFrmAnims and next(seqFrmAnims) ~= nil then
        return true
    end

    return false
end

function actorSequFrameAnimManager:IsNeedOffset( rawAnimID )
    return (rawAnimID < 4000 or rawAnimID >= 5000)
end

function actorSequFrameAnimManager:unloadUnusedInOOM()
    if not self:isMemCleanup() then
        return false
    end
    
    self:unloadUnusedAnimData()
    return true
end

function actorSequFrameAnimManager:getGlobalElapsed()
    return self._globalElapsed
end

function actorSequFrameAnimManager:getAnimFrameVecEmpty()
    return self._animFrameVecEmpty
end

function actorSequFrameAnimManager:InitTemporaryPlayer(sex, animType)
    local animDataMgr = self._animDataMgr[animType]
    local animLoader  = self._animLoaders[animType]
    local animID      = self:KEY_ID_SEX( rawTempID, sex, animType )
    local config      = self:GetAnimConfig( animID, animType )

    local animDataDesc    = self._animDescCache:Alloc()
    animDataDesc:OnNew( animID, rawTempID, sex, animType )
    animDataMgr[animID]   = animDataDesc
    self:setAnimDataDescByConfig(animDataDesc, config)

    for act = 0, 7 do
        if config.interval[act] then
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_FOREVER
            animLoader:downloadSequAnim( animDataDesc, act )
            animLoader:loadSequAnim( animDataDesc, act )
            self:loadSequFrmAnimUnit( animDataDesc, act, true)
        end
    end
end

function actorSequFrameAnimManager:InitTemporaryMonster()
    local sex         = male
    local animType    = MMO.SFANIM_TYPE_MONSTER
    local animDataMgr = self._animDataMgr[animType]
    local animLoader  = self._animLoaders[animType]
    local animID      = self:KEY_ID_SEX( rawTempID, sex, animType )
    local config      = self:GetAnimConfig( animID, animType )

    local animDataDesc    = self._animDescCache:Alloc()
    animDataDesc:OnNew( animID, rawTempID, sex, animType )
    animDataMgr[animID]   = animDataDesc
    self:setAnimDataDescByConfig(animDataDesc, config)

    for act = MMO.ACTION_IDLE, MMO.ACTION_IDLE_LOCK do
        if config.interval[act] then
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_FOREVER
            animLoader:downloadSequAnim( animDataDesc, act )
            animLoader:loadSequAnim( animDataDesc, act )
            self:loadSequFrmAnimUnit( animDataDesc, act, true)
        end
    end
end

local tempACTNPC = {
    MMO.ANIM_IDLE,
    MMO.ACTION_BORN
}
function actorSequFrameAnimManager:InitTemporaryNpc()
    local sex         = male
    local animType    = MMO.SFANIM_TYPE_NPC
    local animDataMgr = self._animDataMgr[animType]
    local animLoader  = self._animLoaders[animType]
    local animID      = self:KEY_ID_SEX( rawTempID, sex, animType )
    local config      = self:GetAnimConfig( animID, animType )

    local animDataDesc    = self._animDescCache:Alloc()
    animDataDesc:OnNew( animID, rawTempID, sex, animType )
    animDataMgr[animID]   = animDataDesc
    self:setAnimDataDescByConfig(animDataDesc, config)

    for index, act in ipairs(tempACTNPC) do
        if config.interval[act] then
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_FOREVER
            animLoader:downloadSequAnim( animDataDesc, act )
            animLoader:loadSequAnim( animDataDesc, act )
            self:loadSequFrmAnimUnit( animDataDesc, act, true)
        end
    end
end

local tempACTSFX = {
    MMO.ANIM_IDLE,
}
function actorSequFrameAnimManager:InitTemporarySFX()
    local sex         = male
    local animType    = MMO.SFANIM_TYPE_SKILL
    local animDataMgr = self._animDataMgr[animType]
    local animLoader  = self._animLoaders[animType]
    local animID      = self:KEY_ID_SEX( rawTempID, sex, animType )
    local config      = self:GetAnimConfig( animID, animType )

    local animDataDesc    = self._animDescCache:Alloc()
    animDataDesc:OnNew( animID, rawTempID, sex, animType )
    animDataMgr[animID]   = animDataDesc
    self:setAnimDataDescByConfig(animDataDesc, config)

    for index, act in ipairs(tempACTSFX) do
        if config.interval[act] then
            animDataDesc.loadStateUnit[act] = MMO.LOAD_STATE_FOREVER
            animLoader:downloadSequAnim( animDataDesc, act )
            animLoader:loadSequAnim( animDataDesc, act )
            self:loadSequFrmAnimUnit( animDataDesc, act, true)
        end
    end
end

function actorSequFrameAnimManager:IsFileExist(filePath)
    if self._fileExistCache[filePath] == nil then
        self._fileExistCache[filePath] = global.FileUtilCtl:isFileExist(filePath)
    end
    return self._fileExistCache[filePath]
end

function actorSequFrameAnimManager:SetFileIsExist(filePath, exist)
    self._fileExistCache[filePath] = exist
end

return actorSequFrameAnimManager
