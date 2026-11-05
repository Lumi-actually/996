local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankFrameMediator = class("TradingBankFrameMediator", BaseUIMediator)
TradingBankFrameMediator.NAME = "TradingBankFrameMediator"
local cjson = require("cjson")
function TradingBankFrameMediator:ctor()
    TradingBankFrameMediator.super.ctor(self)
end

function TradingBankFrameMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable

    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "TradingBankFrameMediator", handler(self, self.InitTradingBankStatus))

    return
    {
        noticeTable.Layer_TradingBankFrame_Open,
        noticeTable.Layer_TradingBankFrame_Close,
    }
end

function TradingBankFrameMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local id = notification:getName()
    local data = notification:getBody()

    if noticeTable.Layer_TradingBankFrame_Open == id then
        self:OpenLayer(data)
    elseif noticeTable.Layer_TradingBankFrame_Close == id then
        self:CloseLayer()
    end
end

function TradingBankFrameMediator:InitTradingBankStatus()
    if not global.OtherTradingBank then
        local TradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.TradingBankProxy)
        TradingBankProxy:getTradingBankStatus({}, function(success, response, code)
            local isOpen = false
            if success then
                local data = cjson.decode(response)
                if data and data.code == 200 and data.data and data.data.status == 0 then
                    isOpen = true
                end
            end
            if TradingBankProxy then
                TradingBankProxy:setOpenStatus(isOpen)
            end
        end, true, true)
    end
end

function TradingBankFrameMediator:OpenLayer(data)
    if not (self._layer) then
        if global.DesignSize_Win.width < global.MMO.TradingBankDesignSize.width or global.DesignSize_Win.height < global.MMO.TradingBankDesignSize.height then
            self:setResolution({ width = 1136, height = 640 })
        end
        local path    = "trading_bank_layer/TradingBankFrameLayer"
        self._layer   = requireLayerUI(path).create(data and data.id)
        self._type    = global.UIZ.UI_NORMAL
        self._escClose = true
        self._GUI_ID = UIConst.LAYERID.TradingBankFrame
        TradingBankFrameMediator.super.OpenLayer(self)

        if self._layer and self._layer._ui then
            GUI:Win_SetDrag(self._layer, self._layer._ui.PMainUI)
            GUI:setMouseEnabled(self._layer._ui.PMainUI, true)
        end
    else
        if data then
            if self._layer:getCurPageID() == data.id then
                self:CloseLayer()
            else
                self._layer:changPage(data.id)
            end
        end
    end
end

function TradingBankFrameMediator:CloseLayer()
    if self._layer then
        self._layer:OnClose()
    end
    TradingBankFrameMediator.super.CloseLayer(self)
    if global.DesignSize_Win.width < global.MMO.TradingBankDesignSize.width or global.DesignSize_Win.height < global.MMO.TradingBankDesignSize.height then
        self:setResolution(global.DesignSize_Win)
    end
end

function TradingBankFrameMediator:setResolution(size)
    if not global.isWindows or not global.isWinPlayMode then
        return false
    end

    local glview = global.Director:getOpenGLView()
    glview:setFrameSize(size.width, size.height)
    glview:setFrameZoomFactor(global.DeviceZoom_Win)

    local data = {}
    data.rType = global.DesignPolicy
    data.size = size
    global.Facade:sendNotification(global.NoticeTable.ChangeResolution, data)
end

return TradingBankFrameMediator