local RemoteProxy = requireProxy("RemoteProxy")
local GoldBoxProxy = class("GoldBoxProxy", RemoteProxy)
GoldBoxProxy.NAME = global.ProxyTable.GoldBoxProxy

function GoldBoxProxy:ctor()
    GoldBoxProxy.super.ctor(self)
    self._config        = {} --宝箱数据
    self._itemShow      = {}
    self._boxData       = {}
    self._totalopenTime = 1 --总的开启次数
    self._openTime      = 0 --开启次数
end

function GoldBoxProxy:RandomConfig(config)
    -- body
    local data = {}
    local index = 1
    while #config~=0 do
        local n=math.random(1,#config)
        if config[n]~=nil then
            if config[n].Index == 0 then
                data[0] = config[n]
                table.remove(config,n)

            else
                data[index]=config[n]
                table.remove(config,n)
                index=index+1
            end
        end
    end
    return data
end

--获取开启总次数
function GoldBoxProxy:GetTotalOpenTime()
    return self._totalopenTime
end

--获取开启次数
function GoldBoxProxy:GetOpenTime()
    -- body
    return self._openTime
end

--设置开启次数
function GoldBoxProxy:SetOpenTime(openTime)
    -- body
    self._openTime = openTime
end

--获取物品信息
function GoldBoxProxy:GetItemShow(index)
    -- body
    -- dump(self._itemShow)
    return self._itemShow[index]
end

function GoldBoxProxy:CheckHaveOpenTime()
    -- body
    releasePrint("可重摇次数 === ",self._totalopenTime)
    releasePrint("已重摇次数 === ",self._openTime)
    if self._totalopenTime - self._openTime >=1 then
        return true
    else 
        return false
    end
end

function GoldBoxProxy:SetBoxItemData(data)
    self._boxData = data
end

function GoldBoxProxy:SetRefreshBoxItemData(data)
    self._newBoxData = data
end

function GoldBoxProxy:RequsetOpenBoxAgain()
    LuaSendMsg( global.MsgType.MSG_SC_OPEN_TREASUREBOX_AGAIN)
end

function GoldBoxProxy:RequsetGetBoxReward()
    LuaSendMsg( global.MsgType.MSG_SC_TREASUREBOX_REWARD)
end

function GoldBoxProxy:ResponsGetBoxItemInfo(msg)
    -- body
    releasePrint("===========MSG_CS_TREASUREBOX_INFO===============")
    local msgheader = msg:GetHeader()
    local data = ParseRawMsgToJson(msg)
    if msgheader.param1 == 1 then
        -- dump(data)
        if self._boxData and next(self._boxData)~=nil then
            -- dump(self._boxData)
            local bagdata = {
                    storage = {
                        MakeIndex = self._boxData.MakeIndex,
                        state = 1
                    }
                }
            
            SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, bagdata)
            self._boxData = {}
        end
        if msgheader.param2 == 0 then 
            self._totalopenTime = 1
        else
            self._totalopenTime = msgheader.param2
        end
        self._config = self:RandomConfig(data)
        SL:onLUAEvent(LUA_EVENT_TREASUREBOX_DATA_REFRESH, self._config)
    elseif msgheader.param1 == 2 then
        if msgheader.recog == 0 then
            self._openTime = self._openTime+1
            local rewardindex = 1
            for k,v in pairs(self._config) do
                if msgheader.param2 == v.Index then
                    rewardindex = k
                end
            end
            SL:onLUAEvent(LUA_EVENT_GOLD_BOX_OPEN_ANIM, rewardindex)
        end
    elseif msgheader.param1 == 3 then
        if msgheader.recog == 0 then
            self._boxData = {}
            self._openTime = 0
            UIOperator:CLoseGoldBox()
            if self._newBoxData and next(self._newBoxData) then
                self._boxData = self._newBoxData
                self._newBoxData = nil
            end
        end
    end
end

function GoldBoxProxy:onRegister()
    GoldBoxProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler( msgType.MSG_CS_TREASUREBOX_INFO,handler( self, self.ResponsGetBoxItemInfo))
end

return GoldBoxProxy