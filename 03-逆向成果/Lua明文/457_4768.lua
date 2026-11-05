local MainExtraMediator = class("", framework.Mediator)
MainExtraMediator.NAME = "MainExtraMediator"

function MainExtraMediator:ctor()
    MainExtraMediator.super.ctor(self, self.NAME)
end

function MainExtraMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.AddBoxDayBtnToScreen,
        noticeTable.AddTradingBankBtnToScreen,
    }
end

function MainExtraMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeTable.AddBoxDayBtnToScreen == noticeID then
        self:OnAddBoxDayBtnToScreen(data)
    elseif noticeTable.AddTradingBankBtnToScreen == noticeID then
        self:OnAddTradingBankBtnToScreen(data)
    end
end

local function checkPos(widget, parent, pos)
    local touchNodeSize = widget:getContentSize()
    local touchNodeAnchor = widget:getAnchorPoint()
    local worldPos = widget:getWorldPosition()
    local winSize = global.Director:getWinSize()
    local scale = widget:getScale()

    local afterPos = worldPos
    if worldPos.x - touchNodeSize.width*(touchNodeAnchor.x)*scale < 0 then -- 超左边
        afterPos.x = afterPos.x - (worldPos.x - touchNodeSize.width*(touchNodeAnchor.x)*scale)
    end

    if worldPos.x + touchNodeSize.width*(1-touchNodeAnchor.x)*scale > winSize.width then -- 超右边
        afterPos.x = afterPos.x - (worldPos.x + touchNodeSize.width*(1-touchNodeAnchor.x)*scale - winSize.width)
    end

    if worldPos.y + touchNodeSize.height*(1-touchNodeAnchor.y)*scale > winSize.height then -- 超上边
        afterPos.y = afterPos.y - (worldPos.y + touchNodeSize.height*(1-touchNodeAnchor.y)*scale - winSize.height)
    end

    if worldPos.y - touchNodeSize.height*(touchNodeAnchor.y)*scale < 0 then   --超下边
        afterPos.y = afterPos.y - (worldPos.y - touchNodeSize.height*(touchNodeAnchor.y)*scale)
    end

    local nodePos = parent:convertToNodeSpace(afterPos)
    if nodePos.x ~= pos.x or nodePos.y ~= pos.y then
        return nodePos
    end

    return false
end

function MainExtraMediator:OnAddBoxDayBtnToScreen( data )
    if not data.subid or not (data.subid >= 101 and data.subid <= 108) then
        return
    end
    local scale = tonumber(data.scale) and tonumber(data.scale)/100 or 1

    local panel = ccui.Layout:create()
    panel:setContentSize(cc.size(50, 50))
    panel:setAnchorPoint(cc.p(0, 1))
    
    local sfx = global.FrameAnimManager:CreateSFXAnim(5109)
    sfx:Play(0,0,true)
    local offset = cc.p(22*scale, (-42)*scale)
    panel:setTouchEnabled(true)
    panel:addClickEventListener(function ()
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996Main_Open)
    end)

    local attachData = {
        index = data.subid,
        subid = "996OfficalEveryDayPanel",
        content = panel
    }

    local y = 0 - data.y
    panel:setPosition(data.x, y)
    panel:setScale(scale)
    global.Facade:sendNotification(global.NoticeTable.GUIComponentAttachOrDetch, attachData)

    local attachData = {
        index = data.subid,
        subid = "996OfficalEveryDaySfx",
        content = sfx
    }

    sfx:setPosition(data.x + offset.x, y + offset.y)
    global.Facade:sendNotification(global.NoticeTable.GUIComponentAttachOrDetch, attachData)

    local pos = checkPos(panel, GUI:Win_FindParent(data.subid), cc.p(data.x, y))
    if pos then
        panel:setPosition(pos.x, pos.y)
        sfx:setPosition(pos.x + offset.x, pos.y + offset.y)
    end
end

function MainExtraMediator:OnAddTradingBankBtnToScreen( data )
    if not data.subid or not (data.subid >= 101 and data.subid <= 108) then
        return
    end

    if global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac" then
        return
    end

    local btn = ccui.Button:create()
    btn:setAnchorPoint(cc.p(0, 1))
    btn:loadTextureNormal(global.MMO.PATH_RES_PRIVATE.."trading_bank/jiaoyihang.png")
    btn:setTouchEnabled(true)
    btn:ignoreContentAdaptWithSize(false)
    btn:setContentSize(cc.size(data.width, data.height))
    btn:addClickEventListener(function ()
        JUMPTO(35)
    end)

    local attachData = {
        index = data.subid,
        subid = "996OfficalTradingBankBtn",
        content = btn
    }

    local y = 0 - data.y
    btn:setPosition(data.x, y)
    global.Facade:sendNotification(global.NoticeTable.GUIComponentAttachOrDetch, attachData)

    local pos = checkPos(btn, GUI:Win_FindParent(data.subid), cc.p(data.x, y))
    if pos then
        btn:setPosition(pos.x, pos.y)
    end
end

return MainExtraMediator
