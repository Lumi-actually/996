local BaseUIMediator = requireMediator("BaseUIMediator")
local LoginRoleLockMediator = class('LoginRoleLockMediator', BaseUIMediator)
LoginRoleLockMediator.NAME = "LoginRoleLockMediator"

function LoginRoleLockMediator:ctor()
    LoginRoleLockMediator.super.ctor(self)
end

function LoginRoleLockMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return
    {
        noticeTable.Layer_Login_RoleLock_Open,
        noticeTable.Layer_Login_RoleLock_Close,
    }
end

function LoginRoleLockMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.Layer_Login_RoleLock_Open == noticeID then
        self:Open(data)

    elseif noticeTable.Layer_Login_RoleLock_Close == noticeID then
        self:Close()
    end
end

function LoginRoleLockMediator:Open(data)
    if not self._layer then
        self._layer = requireLayerUI("login_layer/LoginRoleLockLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        LoginRoleLockMediator.super.OpenLayer(self)
    else 
        self:OnUpdateRoles()
    end
end

function LoginRoleLockMediator:Close()
    if self._layer then
        local TradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.TradingBankProxy)
        TradingBankProxy:removeLayer(self._layer)
        local OtherTradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
        OtherTradingBankProxy:removeLayer(self._layer)
        if global.OtherTradingBankH5 then 
            local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
            local roleData = loginProxy:GetAllRoleInfo()
            local lock = false
            for i, v in ipairs(roleData) do
                if v.LockChar and (v.LockChar == 1 or v.LockChar == 3)  then 
                    lock = true 
                    break
                end
            end
            if lock then 
                OtherTradingBankProxy:dismissBackToView()
            end
        end
    end
    LoginRoleLockMediator.super.CloseLayer(self)
end



function LoginRoleLockMediator:OnUpdateRoles()
    if self._layer then
        self._layer:OnUpdateRoles()
    end
end


return LoginRoleLockMediator