local BaseUIMediator = requireMediator("BaseUIMediator")
local LoginVersionMediator = class('LoginVersionMediator', BaseUIMediator)
LoginVersionMediator.NAME = "LoginVersionMediator"

function LoginVersionMediator:ctor()
    LoginVersionMediator.super.ctor(self)
end

function LoginVersionMediator:listNotificationInterests()
    local notice = global.NoticeTable
    return
        {
            notice.Layer_Login_Version_Open,
            notice.Layer_Login_Version_Close,
        }
end

function LoginVersionMediator:handleNotification(notification)
    local id = notification:getName()
    local notices = global.NoticeTable
    local data = notification:getBody()
    
    if notices.Layer_Login_Version_Open == id then
        self:Open()

    elseif notices.Layer_Login_Version_Close == id then
        self:Close()

    end
end

function LoginVersionMediator:Open()
    if not self._layer then
        self._layer = requireLayerUI("login_layer/LoginVersionLayer").create()
        self._type = global.UIZ.UI_TOBOX
        
        LoginVersionMediator.super.OpenLayer(self)
    else
        self._layer:setVisible(true)
    end
end

function LoginVersionMediator:Close()
    LoginVersionMediator.super.CloseLayer(self)
end


return LoginVersionMediator