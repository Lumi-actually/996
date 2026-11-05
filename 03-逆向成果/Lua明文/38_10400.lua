local LoadingLayer = class("LoadingLayer", function ()
    return cc.Layer:create()
end)

local function GetByteSize( byteSize )

    if byteSize >= 1024 * 1024 then
        return string.format("%.2fM", byteSize / 1024 / 1024)
    end
    return string.format("%.2fKB", byteSize / 1024)
end

function LoadingLayer:ctor()
    self._isCheckVersion = false
    self._loadingType = 0   -- 0.  1.自定义资源zip  2.自定义资源
    self._isForceLoad = false
    self._isDetails   = false
    self._downSpeed   = 0
    self._downSpeedNew= 0
    self._downSchID   = nil
    self._isShowSpeed = global.L_GameEnvManager:GetEnvDataByKey("pc_close_secoend_tips") == 1 or global.L_GameEnvManager:GetEnvDataByKey("asset_speed_enable") == 1 or false
end

function LoadingLayer.create(...)
    local layer = LoadingLayer.new()
    if layer:Init(...) then
        return layer
    end
    return nil
end

function LoadingLayer:Init(data)
    local layoutName = global.IS_PORTRAIT and "loading/res_sync_portrait" or "loading/res_sync"
    self._root = CreateExport_launcher(layoutName)
    if not self._root then
        return false
    end
    self:addChild(self._root)
    self.ui = ui_delegate(self._root)


    local visibleSize = cc.Director:getInstance():getVisibleSize()
    self.ui.Panel_1:setContentSize({width = visibleSize.width, height = visibleSize.height})

    -- 背景图适配
    local contentSize = self.ui.Image_1:getContentSize()
    if visibleSize.width > contentSize.width or visibleSize.height > contentSize.height then
        self.ui.Image_1:setContentSize(visibleSize)
    end

    self.ui.Image_bar:setVisible(false)
    self.ui.LoadingBar_percent:setVisible(false)
    self.ui.LoadingBar_percent:setPercent(0)
    self.ui.Text_percent:setString("获取版本信息...")

    -- 检测版本/更新进度
    if data then
        self._isDetails   = data.isDetails or false
        self._loadingType = data.loadingType or 0
        self._isCheckVersion = data.isCheckVersion

        if true == data.isCheckVersion then
            local formatStr     = "获取版本信息..."
            if self._loadingType == 1 then
                formatStr       = "比对自定义资源包..."
            elseif self._loadingType == 2 then
                formatStr       = "比对自定义资源..."
            end
            self.ui.Text_percent:setString(formatStr)
        end

        if true == data.delay then
            self._root:setVisible(false)
            local sequence = cc.Sequence:create(cc.DelayTime:create(1.5), cc.Show:create())
            self._root:runAction(sequence)
        end
    end

    self._isForceLoad = tonumber(global.L_GameEnvManager:GetEnvDataByKey("loadCancleClose")) == 1
    if self._isForceLoad or global.L_GameEnvManager:GetEnvDataByKey("pc_close_secoend_tips") == 1 then
        global.L_NativeBridgeManager:GN_IsCan_Windown_Close_State({state=0})
    end

    -- 
    self:UpdateGMRes()
    self:ShowGameNameAndAuthor()
    
    return true
end

function LoadingLayer:UpdateDetailPercent(percent, totalSize)
    local formatStr     = "已下载 %s/%s 下载速度 %s/s    请等待..."
    if self._loadingType == 1 then
        formatStr       = "已下载 %s/%s 下载速度 %s/s    下载自定义资源包..."
    elseif self._loadingType == 2 then
        formatStr       = "已下载 %s/%s 下载速度 %s/s    下载自定义资源..."
    end

    local speed = math.max((percent-self._downSpeed)/100 * totalSize, 1024)

    self.ui.Image_bar:setVisible(true)
    self.ui.LoadingBar_percent:setVisible(true)
    self.ui.LoadingBar_percent:setPercent(percent)
    self.ui.Text_percent:setString(string.format(formatStr, GetByteSize( percent/100 * totalSize ), GetByteSize(totalSize), GetByteSize(speed)))

    if self._downSpeedNew <= 0 then
        self._downSpeedNew = percent
    end

    if percent >= 100 then
        if self._downSchID then
            self.ui.Text_percent:stopAllActions()
            self._downSchID = nil
        end
        self.ui.Text_percent:runAction( cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            self.ui.Text_percent:setString("正在释放资源...")
        end)))
        return
    end

    if not self._downSchID then
        local sequence = cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            if self._downSpeedNew <= 0 then
                return
            end
            self._downSpeed = self._downSpeedNew
            self._downSpeedNew = 0
        end))
        local action = cc.RepeatForever:create(sequence)
        self.ui.Text_percent:runAction(action)
    end
end

function LoadingLayer:UpdatePercent(percent, totalSize)
    if self._isDetails and totalSize and self._isShowSpeed then
        self:UpdateDetailPercent(percent, totalSize)
        return
    end

    local formatStr     = "%s%% 请等待..."
    if self._loadingType == 1 then
        formatStr       = "%s%% 下载自定义资源包..."
    elseif self._loadingType == 2 then
        formatStr       = "%s%% 下载自定义资源..."
    end

    self.ui.Image_bar:setVisible(true)
    self.ui.LoadingBar_percent:setVisible(true)
    self.ui.LoadingBar_percent:setPercent(percent)

    if totalSize then
        formatStr = formatStr .. "%s/%s"
        self.ui.Text_percent:setString(string.format(formatStr, percent, GetByteSize(percent/100 * totalSize), GetByteSize(totalSize)))
    else
        self.ui.Text_percent:setString(string.format(formatStr, percent))
    end

    if percent >= 100 then
        if self._downSchID then
            self.ui.Text_percent:stopAllActions()
            self._downSchID = nil
        end

        self.ui.Text_percent:runAction( cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            self.ui.Text_percent:setString("正在释放资源...")
        end)))
    end
end

function LoadingLayer:UpdateGMRes()
    local directoryPath = global.FileUtilCtl:getWritablePath()
    local loadingData   = global.L_GameEnvManager:GetGMLoadingData()
    if loadingData and loadingData.bg_name and global.FileUtilCtl:isFileExist(directoryPath .. loadingData.bg_name) then
        self.ui.Image_1:loadTexture(directoryPath .. loadingData.bg_name)
        self.ui.Image_1:ignoreContentAdaptWithSize(true)
    end
    if loadingData and loadingData.bar_bg_name and global.FileUtilCtl:isFileExist(directoryPath .. loadingData.bar_bg_name) then
        self.ui.Image_bar:loadTexture(directoryPath .. loadingData.bar_bg_name)
        self.ui.Image_bar:ignoreContentAdaptWithSize(true)
    end
    if loadingData and loadingData.bar_name and global.FileUtilCtl:isFileExist(directoryPath .. loadingData.bar_name) then
        self.ui.LoadingBar_percent:loadTexture(directoryPath .. loadingData.bar_name)
        self.ui.LoadingBar_percent:ignoreContentAdaptWithSize(true)
    end
end

function LoadingLayer:CloseLayer()
    if self._isForceLoad and global.L_GameEnvManager:GetEnvDataByKey("pc_close_secoend_tips") ~= 1 then
        global.L_NativeBridgeManager:GN_IsCan_Windown_Close_State({state=1})
    end

    if self._downSchID then
        self.ui.Text_percent:stopAllActions()
        self._downSchID = nil
    end
end

function LoadingLayer:ShowGameNameAndAuthor()
    if not global.L_ModuleManager or not global.L_ModuleManager:GetCurrentModule() then
        releasePrint("can not find current module!!")
        return
    end
    if not global.isBoxLogin then 
        return 
    end
    local Panel_launch = ccui.Layout:create()
    Panel_launch:ignoreContentAdaptWithSize(false)
    Panel_launch:setClippingEnabled(false)
    Panel_launch:setBackGroundColorOpacity(102)
    Panel_launch:setTouchEnabled(true);
    Panel_launch:setLayoutComponentEnabled(true)
    Panel_launch:setName("Panel_launch")
    Panel_launch:setTag(25)
    Panel_launch:setCascadeColorEnabled(true)
    Panel_launch:setCascadeOpacityEnabled(true)
    Panel_launch:setAnchorPoint(0.5000, 0.5000)
    Panel_launch:setPosition(567.8864, 313.0880)
    local layout = ccui.LayoutComponent:bindLayoutComponent(Panel_launch)
    layout:setPositionPercentXEnabled(true)
    layout:setPositionPercentYEnabled(true)
    layout:setPositionPercentX(0.4999)
    layout:setPositionPercentY(0.4892)
    layout:setPercentWidth(1.0000)
    layout:setPercentHeight(1.0000)
    layout:setSize({width = 1136.0000, height = 640.0000})
    layout:setLeftMargin(-0.1136)
    layout:setRightMargin(0.1135)
    layout:setTopMargin(6.9120)
    layout:setBottomMargin(-6.9120)
    self.ui.nativeUI:addChild(Panel_launch)
    local curModule = global.L_ModuleManager:GetCurrentModule()
    local curSubModule = curModule:GetCurrentSubMod()
    local modGameEnv    = curSubModule:GetGameEnv()
    local loadingShowName = modGameEnv:GetCustomDataByKey("loadingShowName") or ""
    if global.isWindows then 
        loadingShowName = modGameEnv:GetCustomDataByKey("boxPcLoadingShowName") or ""
    end 
    local loadingAuthor = global.L_GameEnvManager:GetEnvDataByKey("loadingAuthor") or ""
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local loadingShowNameLabelPos = cc.p(100, visibleSize.height - 70)
    local loadingShowNameLabel = ccui.Text:create()
    loadingShowNameLabel:setFontName("fonts/font.ttf")
    loadingShowNameLabel:setFontSize(36)
    loadingShowNameLabel:setAnchorPoint(0,0)
    loadingShowNameLabel:setString(loadingShowName)
    loadingShowNameLabel:setPosition(loadingShowNameLabelPos)
    loadingShowNameLabel:enableOutline(cc.c3b(0x19,0x13,0x0D), 2)
    Panel_launch:addChild(loadingShowNameLabel)

    local loadingAuthorLabel = ccui.Text:create()
    loadingAuthorLabel:setFontName("fonts/font.ttf")
    loadingAuthorLabel:setFontSize(20)
    loadingAuthorLabel:setAnchorPoint(0, 1)
    loadingAuthorLabel:setString(loadingAuthor)
    loadingAuthorLabel:setPosition( loadingShowNameLabelPos.x, loadingShowNameLabelPos.y - 15)
    loadingAuthorLabel:setTextColor(cc.c3b(0x9A,0x9B,0x9B))
    loadingAuthorLabel:enableOutline(cc.c3b(0x19,0x13,0x0D), 2)
    Panel_launch:addChild(loadingAuthorLabel)
end
return LoadingLayer
