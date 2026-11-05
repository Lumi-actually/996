local SceneOptionsMediator  = class('SceneOptionsMediator', framework.Mediator)
SceneOptionsMediator.NAME   = "SceneOptionsMediator"

local optionsUtils = requireUtil("optionsUtils")
local sLen         = string.len
local MMO          = global.MMO
local zeroP        = cc.p(0,0)
local tempP1       = cc.p(0.5, 0)
-- FIXME，special blend is not expected in RTT
local function filterSpecialBlendChild(node, filteredTable)
    local children = node:getChildren()
    for _, child in ipairs(children) do
        if child.getBlendFunc then
            local blendFunc = child:getBlendFunc()
            local compareBlend = MMO.normal_blend_func
            if blendFunc.dst ~= compareBlend.dst and blendFunc.src ~= compareBlend.src then
                if child:isVisible() then
                    filteredTable[#filteredTable + 1] = child
                    child:setVisible(false)
                end
            end
        end
        filterSpecialBlendChild(child, filteredTable)
    end
end

local function rebackSpecialBlendChild(filteredTable)
    for _, node in ipairs(filteredTable) do
        node:setVisible(true)
    end
end

function SceneOptionsMediator:ctor()
    SceneOptionsMediator.super.ctor(self, self.NAME)

    self._dieRT         = nil        -- 死亡RTT，会渲染整个NODE_WORLD
    self._dieFlag       = false
    self._coverRT       = nil        -- 遮罩层RTT，支持重复渲染actor，目前只渲染了主玩家
    self._visitRTTimer  = nil

    self._originWinSize = global.Director:getWinSize()

    if global.isWindows then
        self._windowResizeDirty = false
        self._windowResizedListener = cc.EventListenerCustom:create("glview_window_resized", handler(self, self.onWindowResized))
        global.EventDispatcher:addEventListenerWithFixedPriority(self._windowResizedListener, 1)
    end

    self:Init()
end

function SceneOptionsMediator:Init()
    local noticeTable = global.NoticeTable
    self._noticeMaps = {
        [noticeTable.RefreshMoveInView]                   = function (data) self:onRefreshActorInMove(data) end,
        [noticeTable.RefreshActorSceneOptions]            = function (data) self:onRefreshActorSceneOptions(data) end,
        [noticeTable.RefreshOneActorCloth]                = function (data) self:onRefreshOneActorCloth(data) end,

        [noticeTable.MouseMoveOutActorSide]               = function (data) self:OnMouseMoveOutEvent(data) end,
        [noticeTable.MouseMoveInActorSide]                = function (data) self:OnMouseMoveInEvent(data) end,
        [noticeTable.TargetChange]                        = function (data) self:OnTargetChange(data) end,

        [noticeTable.MainPlayerRevive]                    = function () self:onMainPlayerRevive() end,
        [noticeTable.MainPlayerDie]                       = function () self:onMainPlayerDie() end,
        [noticeTable.BindMainPlayer]                      = function () self:onMainPlayerBinded() end,

        [noticeTable.GameSettingChange]                   = function (data) 
                                                    if data.id == MMO.SETTING_IDX_CAMERA_ZOOM then
                                                        self:onChangeCameraZ()
                                                    end
                                                end,

        [noticeTable.ReleaseMemory]                       = function () self:Cleanup() end,

        [noticeTable.SetChange_AllPlayer]                 = function () self:onOptions_AllPlayer() end,
        [noticeTable.SetChange_OwnSidePlayer]             = function () self:onOptions_OwnSidePlayer() end,
        [noticeTable.SetChange_AllEffect]                 = function () self:onOptions_AllEffect() end,
        [noticeTable.SetChange_SkillEffect]               = function () self:onOptions_SkillEffect() end,
        [noticeTable.SetChange_NormalMonster]             = function () self:onOptions_NormalMonster() end,
        [noticeTable.SetChange_MonsterPet]                = function () self:onOptions_MonsterPet() end,
        [noticeTable.SetChange_SimpleDressPlayer]         = function () self:onOptions_SimpleDressPlayer() end,
        [noticeTable.SetChange_SimpleDressMonster]        = function () self:onOptions_SimpleDressMonster() end,
        [noticeTable.SetChange_SimpleDressMonsterBoss]    = function () self:onOptions_SimpleDressMonsterBoss() end,
        [noticeTable.SetChange_AllHero]                   = function () self:onOptions_AllHero() end,

        [noticeTable.ActorMonsterCaved]                   = function (data) self:onActorMonsterCaved(data) end,
        [noticeTable.ActorMonsterBorn]                    = function (data) self:onActorMonsterBorn(data) end,

        [noticeTable.MainActorChange_OwnSidePlayer]       = function(data) self:OnMainActorChange_OwnSidePlayerOptions(data) end,
    }
end

function SceneOptionsMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return
    {
        noticeTable.RefreshMoveInView,
        noticeTable.RefreshActorSceneOptions,
        noticeTable.RefreshOneActorCloth,

        noticeTable.MouseMoveOutActorSide,
        noticeTable.MouseMoveInActorSide,
        noticeTable.TargetChange,

        noticeTable.MainPlayerRevive,
        noticeTable.MainPlayerDie,
        noticeTable.BindMainPlayer,

        noticeTable.GameSettingChange,

        noticeTable.ReleaseMemory,

        noticeTable.SetChange_AllPlayer,
        noticeTable.SetChange_OwnSidePlayer,
        noticeTable.SetChange_AllEffect,
        noticeTable.SetChange_SkillEffect,
        noticeTable.SetChange_NormalMonster,
        noticeTable.SetChange_MonsterPet,
        noticeTable.SetChange_SimpleDressPlayer,
        noticeTable.SetChange_SimpleDressMonster,
        noticeTable.SetChange_SimpleDressMonsterBoss,
        noticeTable.SetChange_AllHero,

        noticeTable.ActorMonsterCaved,
        noticeTable.ActorMonsterBorn,

        noticeTable.MainActorChange_OwnSidePlayer,
    }
end

function SceneOptionsMediator:handleNotification(notification)
    local noticeID = notification:getName()
    if self._noticeMaps[noticeID] then
        self._noticeMaps[noticeID](notification:getBody())
    end
end

function SceneOptionsMediator:getDieFlag()
    return self._dieFlag
end

function SceneOptionsMediator:setPlayerFeatureVisible(actor)
    local sceneOptionsProxy = global.Facade:retrieveProxy(global.ProxyTable.SceneOptionsProxy)
    local tempFeature = sceneOptionsProxy:GetTempFeatureByJob(actor:GetJobID())
    local optionHide  = optionsUtils:CheckPlayerSimpleDress(actor)
    
    local visible = nil
    if actor:IsHero() then
        visible = optionsUtils:IsMyHero(actor) or actor:GetValueByKey(MMO.HERO_VISIBLE)
    else
        visible = actor:IsHumanoid() or (actor:GetValueByKey(MMO.PLAYER_VISIBLE) and optionsUtils:CheckSamePlayerVisible(actor))
    end

    -- set showID:temporary, for don't loading data
    local fData = {}
    if (not visible or optionHide) and tempFeature then
        fData =         
        {
            actor               = actor,
            showClothID         = tempFeature.clothID,
            showWeaponID        = tempFeature.weaponID,
            showShieldID        = tempFeature.shieldID,
            showWingsID         = tempFeature.wingsID,
            showHairID          = tempFeature.hairID,
            showWeaponEffID     = tempFeature.weaponEffID,
            showShieldEffID     = tempFeature.shieldEffID,
            showLeftWeaponID    = tempFeature.leftWeaponID,
            showLeftWeaponEffID = tempFeature.leftWeaponEffID,
        }
    else
        fData =         
        {
            actor               = actor,
            showClothID         = 0,
            showWeaponID        = 0,
            showShieldID        = 0,
            showWingsID         = 0,
            showHairID          = 0,
            showWeaponEffID     = 0,
            showShieldEffID     = 0,
            showLeftWeaponID    = 0,
            showLeftWeaponEffID = 0,
        }
    end

    global.Facade:sendNotification(global.NoticeTable.SetPlayerFeatureEX, fData)
end

function SceneOptionsMediator:onOptions_AllPlayer()
    local playerVec, nPlayer = global.playerManager:GetAllPlayerInCurrViewField()
    for i = 1, nPlayer do
        local player = playerVec[i]
        if player and not player:IsMainPlayer() then
            optionsUtils:RefreshPlayerVisible(player)
        end
    end
end

function SceneOptionsMediator:onOptions_AllHero()
    local playerVec, nPlayer = global.playerManager:FindAllHeroInCurrViewField()
    for i = 1, nPlayer do
        optionsUtils:RefreshHeroVisible(playerVec[i])
    end
end

function SceneOptionsMediator:onOptions_OwnSidePlayer()
    local playerVec, nPlayer = global.playerManager:GetAllPlayerInCurrViewField()
    for i = 1, nPlayer do
        local player = playerVec[i]
        if player and not player:IsMainPlayer() then
            optionsUtils:RefreshPlayerBVisible(player)
            self:setPlayerFeatureVisible(player)
        end
    end
end

local function setSkillChildsVisible(childs, visible, onlySkillEffect)
    childs = childs or {}
    for i, v in ipairs(childs) do
        if onlySkillEffect then
            if v._IsSkillEffect then
                v:setVisible(visible)
            end
        elseif not v._IsSkillEffect then
            v:setVisible(visible)
        end
    end
end

function SceneOptionsMediator:onOptions_SkillEffect()
    local skill_b_node  = global.sceneGraphCtl:GetSceneNode(MMO.NODE_SKILL_BEHIND)
    local skill_node    = global.sceneGraphCtl:GetSceneNode(MMO.NODE_SKILL)

    local visible       = CHECK_SETTING(MMO.SETTING_IDX_SKILL_EFFECT_SHOW) ~= 1
    local skillchs      = skill_node:getChildren()
    local skillBchs     = skill_b_node:getChildren()
    setSkillChildsVisible(skillchs, visible, true)
    setSkillChildsVisible(skillBchs, visible, true)
end

function SceneOptionsMediator:onOptions_AllEffect()
    local skill_b_node  = global.sceneGraphCtl:GetSceneNode(MMO.NODE_SKILL_BEHIND)
    local skill_node    = global.sceneGraphCtl:GetSceneNode(MMO.NODE_SKILL)

    local visible       = CHECK_SETTING(MMO.SETTING_IDX_EFFECT_SHOW) ~= 1
    local skillchs      = skill_node:getChildren()
    local skillBchs     = skill_b_node:getChildren()
    setSkillChildsVisible(skillchs, visible, false)
    setSkillChildsVisible(skillBchs, visible, false)
end

function SceneOptionsMediator:onOptions_NormalMonster()
    local monsterVec, ncount = global.monsterManager:GetAllMonsterInCurrViewField()
    for i = 1, ncount do
        local monster = monsterVec[i]
        if monster then
            optionsUtils:InitHUDVisibleValue(monster, MMO.MONSTER_VISIBLE)
            optionsUtils:RefreshMonsterVisible(monster)
        end
    end

    local playerVec, nPlayer = global.playerManager:GetAllPlayerInCurrViewField()
    for i = 1, nPlayer do
        local player = playerVec[i]
        if player and player:IsHumanoid() then
            optionsUtils:InitHUDVisibleValue(player, MMO.MONSTER_VISIBLE)
            optionsUtils:RefreshMonsterVisible(player)
        end
    end
end

function SceneOptionsMediator:onOptions_MonsterPet()
    local mainPlayerID = global.gamePlayerController:GetMainPlayerID()
    local monsterVec, ncount = global.monsterManager:GetAllMonsterInCurrViewField()
    for i = 1, ncount do
        local monster = monsterVec[i]
        if monster then
            if mainPlayerID == monster:GetMasterID() then
            else
                optionsUtils:InitHUDVisibleValue(monster, MMO.MONSTER_VISIBLE)
                optionsUtils:RefreshMonsterVisible(monster)
            end
        end
    end
end

function SceneOptionsMediator:onOptions_SimpleDressPlayer()
    local playerVec, nPlayer = global.playerManager:GetAllPlayerInCurrViewField()
    for i = 1, nPlayer do
        local player = playerVec[i]
        if player then
            self:setPlayerFeatureVisible(player)
        end
    end
end

function SceneOptionsMediator:onOptions_SimpleDressMonster()
    local monsterVec, ncount = global.monsterManager:FindAllMonsterInCurrViewField() 
    for i = 1, ncount do
        local monster = monsterVec[i]
        global.Facade:sendNotification( global.NoticeTable.DelayDirtyFeature, monster:GetID())
    end
end

function SceneOptionsMediator:onOptions_SimpleDressMonsterBoss()
    local monsterVec, ncount = global.monsterManager:FindAllMonsterInCurrViewField()
    for i = 1, ncount do
        local monster = monsterVec[i]
        if monster and monster:IsBoss() then
            global.Facade:sendNotification( global.NoticeTable.DelayDirtyFeature, monster:GetID())
        end
    end
end

local CheckFuncActor = {
    [MMO.ACTOR_PLAYER] = function (actor, Init)
        if Init then
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_HPBAR_VISIBLE)
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_MPBAR_VISIBLE)
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_NGBAR_VISIBLE)
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_HMPLabel_VISIBLE)
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_TITLE_VISIBLE)

            global.HUDHPManager:Update(actor)
        else
            -- Hp、Mp
            optionsUtils:RefreshHUDHMpLabelVisible(actor)
        end
        -- 血条
        optionsUtils:CheckHUDHpBarVisible(actor)
        -- 蓝条
        optionsUtils:CheckHUDMpBarVisible(actor)
        -- 内功条
        optionsUtils:CheckHUDNGBarVisible(actor)

        -- 人名、行会、称号、顶戴
        optionsUtils:RefreshLabelVisible(actor)

        if actor:IsHero() then
            if Init then
                optionsUtils:InitHUDVisibleValue(actor, MMO.HERO_VISIBLE)
            end
            optionsUtils:RefreshHeroVisible(actor)
            SceneOptionsMediator:setPlayerFeatureVisible(actor)
        elseif actor:IsHumanoid() then
            if Init then
                optionsUtils:InitHUDVisibleValue(actor, MMO.MONSTER_VISIBLE)
            end
            optionsUtils:RefreshMonsterVisible(actor)
            SceneOptionsMediator:setPlayerFeatureVisible(actor)
        else
            if Init then
                optionsUtils:InitHUDVisibleValue(actor, MMO.PLAYER_VISIBLE)
                optionsUtils:InitHUDVisibleValue(actor, MMO.PLAYER_B_VISIBLE)
            end
            optionsUtils:RefreshPlayerVisible(actor)
            optionsUtils:RefreshPlayerBVisible(actor)
            SceneOptionsMediator:setPlayerFeatureVisible(actor)
        end
    end,
    [MMO.ACTOR_MONSTER] = function (actor, Init)
        if Init then
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_HPBAR_VISIBLE)
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_MPBAR_VISIBLE)
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_HMPLabel_VISIBLE)
            optionsUtils:InitHUDVisibleValue(actor, MMO.HUD_TITLE_VISIBLE)

            optionsUtils:InitHUDVisibleValue(actor, MMO.MONSTER_VISIBLE)

            global.HUDHPManager:Update(actor)
        else
            -- Hp、Mp
            optionsUtils:RefreshHUDHMpLabelVisible(actor)
        end

        -- 血条
        optionsUtils:CheckHUDHpBarVisible(actor)
        -- 蓝条
        optionsUtils:CheckHUDMpBarVisible(actor)
        -- 内功条
        optionsUtils:CheckHUDNGBarVisible(actor)

        -- 人名、行会、称号、顶戴
        optionsUtils:RefreshLabelVisible(actor)

        optionsUtils:RefreshHUDTitleVisible(actor)
        
        -- 怪物
        optionsUtils:RefreshMonsterVisible(actor)
    end,
    [MMO.ACTOR_DROPITEM] = function (actor, Init)
        optionsUtils:RefreshLabelVisible(actor)
    end,
    [MMO.ACTOR_NPC] = function (actor, Init)
        optionsUtils:RefreshLabelVisible(actor)
    end
}

function SceneOptionsMediator:onRefreshActorSceneOptions(actor)
    if CheckFuncActor[actor:GetType()] then
        CheckFuncActor[actor:GetType()] (actor, true)
    end
end

function SceneOptionsMediator:onRefreshActorInMove(actor)
    if CheckFuncActor[actor:GetType()] then
        CheckFuncActor[actor:GetType()] (actor)
    end
end

function SceneOptionsMediator:onActorMonsterCaved(data)
    local actor = data.actor
    if not actor then
        return false 
    end
    optionsUtils:CheckHUDHpBarVisible(actor)
    optionsUtils:RefreshHUDHMpLabelVisible(actor)
    optionsUtils:RefreshMonsterVisible(actor)

    optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_NAMELabel_VISIBLE)
    optionsUtils:RefreshHUDLabelNameVisible(actor)
end

function SceneOptionsMediator:onActorMonsterBorn(data)
    local actor = data.actor
    if not actor then
        return false 
    end
    optionsUtils:CheckHUDHpBarVisible(actor)
    optionsUtils:RefreshHUDHMpLabelVisible(actor)
    optionsUtils:RefreshMonsterVisible(actor)

    optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_NAMELabel_VISIBLE)
    optionsUtils:RefreshHUDLabelNameVisible(actor)
end

function SceneOptionsMediator:onRefreshOneActorCloth(actor)
    if actor and actor:IsPlayer() then
        self:setPlayerFeatureVisible(actor)
    end
end

function SceneOptionsMediator:OnMainActorChange_OwnSidePlayerOptions(type)
    local playerVec, nPlayer = global.playerManager:GetAllPlayerInCurrViewField()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    for i = 1, nPlayer do
        local player = playerVec[i]
        if player and not player:IsMainPlayer() then
            if type == MMO.TYPE_GUILD then   -- 同行会
                if mainPlayer and string.len(mainPlayer:GetGuildName())> 0 and mainPlayer:GetGuildName() == player:GetGuildName() then
                    player:SetCampValue("InGuild", true)
                else
                    player:SetCampValue("InGuild", false)
                end

            elseif type == MMO.TYPE_TEAM then -- 同队伍
                local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
                player:SetCampValue("InTeam", TeamProxy:IsTeamMember(player:GetID()))

            elseif type == MMO.TYPE_CAMP then -- 同阵营
                local mainFaction = mainPlayer and mainPlayer:GetFaction()
                if mainFaction and mainFaction > 0 and mainFaction == player:GetFaction() then
                    player:SetCampValue("InCamp", true)
                else
                    player:SetCampValue("InCamp", false)
                end
            end
        end
    end
end

function SceneOptionsMediator:onMainPlayerBinded()
    self:onChangeCameraZ()

    if not self._coverRT then
        local uiNode = global.sceneGraphCtl:GetSceneNode(MMO.NODE_UI)
        uiNode:setLocalZOrder(1)

        local rootNode = global.sceneGraphCtl:GetSceneNode(MMO.NODE_MAP_OBJ)
        local size     = global.Director:getWinSize()
        local renderTexture = cc.RenderTexture:create(size.width, size.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, 35056)
        self._originWinSize = size
        -- renderTexture camera mask is USER1
        renderTexture:setCameraMask(cc.CameraFlag.USER1, true)
        renderTexture:setKeepMatrix(true)
        rootNode:addChild(renderTexture)

        local rt_sprite = renderTexture:getSprite()
        rt_sprite:setAnchorPoint(cc.p(0.5, 0.5))
        rt_sprite:setOpacity(128)

        self._coverRT = renderTexture
        self._coverRT:retain()
    end

    if nil == self._visitRTTimer then
        self._visitRTTimer = global.RenderTextureManager:AddDrawFunc({func = handler(self, self.visitRenderTexture) , time = 0})
    end

    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if mainPlayer then
        global.HUDHPManager:UpdateNow(mainPlayer)
    end
end

function SceneOptionsMediator:onMainPlayerRevive()
    if not self._dieFlag then
        return false
    end

    if self._dieRT then
        local rootNode = global.sceneGraphCtl:GetSceneNode(MMO.NODE_ROOT)
        local worldRootNode = global.sceneGraphCtl:GetSceneNode(MMO.NODE_GAME_WORLD)

        self._dieRT:setVisible(false)

        worldRootNode:retain()
        self._dieRT:removeChild(worldRootNode, false)
        rootNode:addChild(worldRootNode, -1)  -- lowest than UI
        worldRootNode:release()
        worldRootNode:setCameraMask(cc.CameraFlag.USER1, true)
    end

    self._dieFlag = false
end

function SceneOptionsMediator:onMainPlayerDie()
    if self._dieFlag then
        return false
    end

    if not self._dieRT then
        local rootNode = global.sceneGraphCtl:GetSceneNode(MMO.NODE_ROOT)
        local size     = global.Director:getWinSize()
        local renderTexture = cc.RenderTexture:create(size.width, size.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)

        rootNode:addChild(renderTexture)

        -- renderTexture camera mask is DEFAULT
        renderTexture:setKeepMatrix(true)
        renderTexture:setClearColor(cc.c4f(0, 0, 0, 0))
        renderTexture:setClearFlags(gl.COLOR_BUFFER_BIT)
        renderTexture:setAnchorPoint(cc.p(0, 0))

        local rt_sprite = renderTexture:getSprite()
        rt_sprite:setAnchorPoint(cc.p(0, 0))
        Shader_Grey(rt_sprite)

        self._dieRT = renderTexture
        self._dieRT:retain()
    end

    if self._dieRT then
        local rootNode = global.sceneGraphCtl:GetSceneNode(MMO.NODE_ROOT)
        local worldRootNode = global.sceneGraphCtl:GetSceneNode(MMO.NODE_GAME_WORLD)
        self._dieRT:setVisible(true)
        self._dieRT:setLocalZOrder(-1) -- lowest than UI

        worldRootNode:retain()
        rootNode:removeChild(worldRootNode, false)
        self._dieRT:addChild(worldRootNode)
        worldRootNode:release()
    end

    if nil == self._visitRTTimer then
        self._visitRTTimer = global.RenderTextureManager:AddDrawFunc({func = handler(self, self.visitRenderTexture) , time = 0})
    end

    self._dieFlag = true
end

function SceneOptionsMediator:visitRenderTexture()
    local camera = global.gameCameraController:GetViewCamera()
    if not camera then
        return false
    end

    local viewIndex = 0
    global.Director:pushProjectionMatrix(viewIndex)
    camera:apply()
    global.Director:loadProjectionMatrix(camera:getViewProjectionMatrix(), viewIndex)

    local player = global.gamePlayerController:GetMainPlayer()
    if player and self._coverRT then
        self._coverRT:beginWithClear(0, 0, 0, 0)
        local playerNode = player:GetNode()
        local filteredTable = {}
        filterSpecialBlendChild(playerNode, filteredTable)

        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        local currMouseOverTargetID = inputProxy:GetMouseOverTargetID()
        if currMouseOverTargetID then
            local targetActor = global.actorManager:GetActor(currMouseOverTargetID)
            if targetActor then
                local targetNode = targetActor:GetNode()
                filterSpecialBlendChild(targetNode, filteredTable)
                targetNode:visit()
            end
        end

        playerNode:visit()

        rebackSpecialBlendChild(filteredTable)
        self._coverRT:endToLua()

        -- follow USER1'camera
        self._coverRT:setPosition(camera:getPosition())

        -- keep scale
        local screenScaleX = 1
        local screenScaleY = 1
        if not global.isWinPlayMode then
            local currSize = global.Director:getWinSize()
            screenScaleX = currSize.width / self._originWinSize.width
            screenScaleY = currSize.height / self._originWinSize.height
        end
        -- print("screen scale:", screenScaleX, screenScaleY, currSize.width, currSize.height, self._originWinSize.width, self._originWinSize.height)
        local viewScaleX, viewScaleY = CalcCameraZoom(camera)
        self._coverRT:setScaleX(viewScaleX * screenScaleX)
        self._coverRT:setScaleY(viewScaleY * screenScaleY)
    end

    if self._dieFlag and self._dieRT then
        self._dieRT:beginWithClear(0, 0, 0, 0)
        local world_root = global.sceneGraphCtl:GetSceneNode(MMO.NODE_GAME_WORLD)
        world_root:visit()
        self._dieRT:endToLua()
    end

    camera:restore()
    global.Director:popProjectionMatrix(viewIndex)
end

function SceneOptionsMediator:onChangeCameraZ()
    if global.isWinPlayMode then
        return
    end
    local value = CHECK_SETTING(MMO.SETTING_IDX_CAMERA_ZOOM)
    value = tonumber(value)
    if value and value > 0 and value <= 4 then
        local camera = global.gameCameraController:GetViewCamera()
        if not camera then
            return
        end

        camera:setPositionZ(MMO.CAMERA_Z_DEFAULT / value)

        local size = global.Director:getWinSize()
        local scaleX, scaleY = CalcCameraZoom( camera )
        size.width  = math.ceil(size.width  * scaleX)
        size.height = math.ceil(size.height * scaleY)

        global.gameCameraController:SetViewSize(size)

        if not self._refCameraFontScale then 
            self._refCameraFontScale = true
            performWithDelay(camera, function()
                self._refCameraFontScale = false
                global.HUDManager:refCameraFontScale()
            end, 0.1)
        end
        
    end
end

function SceneOptionsMediator:onWindowResized(eventCustom)
    if not self._windowResizeDirty then
        self._windowResizeDirty = true

        local function delayFunc()
            self._windowResizeDirty = false
            global.Facade:sendNotification(global.NoticeTable.ResolutionSizeChange, { onlyAdapt = true })
        end
        PerformWithDelayGlobal(delayFunc, 0.5)
    end
end

function SceneOptionsMediator:Cleanup(notCleanListener)
    if self._visitRTTimer then
        global.RenderTextureManager:RmvDrawFunc(self._visitRTTimer)
        self._visitRTTimer = nil
    end

    if self._dieRT then
        self._dieRT:removeFromParent()
        self._dieRT:release()
        self._dieRT = nil
    end

    if self._coverRT then
        self._coverRT:removeFromParent()
        self._coverRT:release()
        self._coverRT = nil
    end

    if self._windowResizedListener and not notCleanListener then
        global.EventDispatcher:removeEventListener(self._windowResizedListener)
        self._windowResizedListener = nil
    end
end

function SceneOptionsMediator:OnMouseMoveInEvent(actorID)
    if not global.isWinPlayMode then
        return false
    end 

    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    inputProxy:SetMouseOverTargetID(actorID)

    if not actorID then
        return false
    end

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end

    if actor:IsDropItem() then
        local worldPosX, worldPosY = World2Screen(actor:GetNode():convertToWorldSpace(zeroP))
        worldPosY = worldPosY + 20
        ShowWorldTips(actor:GetName(), cc.p(worldPosX, worldPosY), tempP1)
    elseif actor:IsMonster() then
        if optionsUtils:ActorIsDie(actor) then
            optionsUtils:SetHMPLabelVisible(actor, false)
            optionsUtils:SetHUDLabelNameVisible(actor:GetID(), false)
        else
            if not actor:IsNoShowName() then
                optionsUtils:SetHUDLabelNameVisible(actor:GetID(), true)
            end
            if not actor:IsNoShowHPBar() then
                local isForceShow = tonumber(SL:GetValue("GAME_DATA", "monster_force_show_hp")) ~= 0
                if isForceShow then
                    actor:SetKeyValue(global.MMO.HUD_PC_MOUSE_SHOW, true)
                    optionsUtils:RefreshHUDHMpLabelVisible(actor)
                end
            end
        end
    elseif actor:IsPlayer() then
        if actor:GetHorseCopilotID() then
            return false
        end
        actor:SetKeyValue(global.MMO.HUD_PC_MOUSE_SHOW, true)
        local hudParam = G_ActorUtils.GetActorAttr(actor, global.MMO.ACTOR_ATTR_HUDPARAM)
        if hudParam and next(hudParam) then
            global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel,  actorID)
        end
    end
end

function SceneOptionsMediator:OnMouseMoveOutEvent(actorID)
    if not global.isWinPlayMode then
        return false
    end 

    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    inputProxy:SetMouseOverTargetID(nil)

    if not actorID then
        return false
    end

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        if global.actorPickerController:GetLastMouseInDropItem() then
            HideMouseOverTips()
        end
        return false
    end

    if actor:IsDropItem() then
        HideMouseOverTips()
    elseif actor:IsMonster() then
        if optionsUtils:ActorIsDie(actor) then
            optionsUtils:SetHMPLabelVisible(actor, false)
            optionsUtils:SetHUDLabelNameVisible(actor:GetID(), false)
        else
            actor:SetKeyValue(global.MMO.HUD_PC_MOUSE_SHOW, false)
            optionsUtils:RefreshHUDHMpLabelVisible(actor)
            optionsUtils:RefreshHUDLabelNameVisible(actor)
        end
    elseif actor:IsPlayer() then
        actor:SetKeyValue(global.MMO.HUD_PC_MOUSE_SHOW, false)
        local hudParam = G_ActorUtils.GetActorAttr(actor, global.MMO.ACTOR_ATTR_HUDPARAM)
        if hudParam and next(hudParam) then
            global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel, actorID)
        end
    end
end

function SceneOptionsMediator:OnTargetChange(data)
    -- 选中目标显示详细信息，只在手机端生效
    if global.isWinPlayMode then
        return false
    end

    local targetID = data.targetID

    -- 是同一个目标
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local currMouseOverTargetID = inputProxy:GetMouseOverTargetID()
    if currMouseOverTargetID == targetID then
        return false
    end

    -- 上次清空
    if currMouseOverTargetID then
        inputProxy:SetMouseOverTargetID(nil)
        local lastActor = global.actorManager:GetActor(currMouseOverTargetID)
        if lastActor and lastActor:IsPlayer() then
            lastActor:SetKeyValue(global.MMO.HUD_PC_MOUSE_SHOW, false)
            local hudParam = G_ActorUtils.GetActorAttr(lastActor, MMO.ACTOR_ATTR_HUDPARAM)
            if hudParam and next(hudParam) then
                global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel, lastActor:GetID())
            end
        end
    end

    -- 当前显示
    if targetID then
        inputProxy:SetMouseOverTargetID(targetID)
        local actor = global.actorManager:GetActor(targetID)
        if actor and actor:IsPlayer() then
            actor:SetKeyValue(global.MMO.HUD_PC_MOUSE_SHOW, true)
            local hudParam = G_ActorUtils.GetActorAttr(actor, MMO.ACTOR_ATTR_HUDPARAM)
            if hudParam and next(hudParam) then
                global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel, actor:GetID())
            end
        end
    end
end

return SceneOptionsMediator