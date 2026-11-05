local RemoteProxy = requireProxy("RemoteProxy")
local CloudStorageProxy = class("CloudStorageProxy", RemoteProxy)
CloudStorageProxy.NAME = global.ProxyTable.CloudStorageProxy

local cjson = require("cjson")
--------------------------------------------------------------
--- 数据云存储
--- ！！！注意json格式
--- ！！！无上传成功返回
--- 将数据存储到服务器 上线时在某个消息发下来
--- 本地也会缓存一份数据，可在不经过服务器做逻辑
--- 请求存储云端时不等服务器返回，默认成功
--------------------------------------------------------------
function CloudStorageProxy:ctor()
    CloudStorageProxy.super.ctor(self)

    self._data = {}
    self:Init()


    self._storageTimerID = nil
    self._serverTimerID = nil
end

function CloudStorageProxy:Init()
    self:loadLocalCache()
end

function CloudStorageProxy:loadLocalCache()
    local writablePath  = global.WritablePath
    local LoginProxy    = global.Facade:retrieveProxy( global.ProxyTable.LoginProxy )
    local roleID        = LoginProxy:GetSelectedRoleID()
    local module        = global.L_ModuleManager:GetCurrentModule()
    local modulePath    = module:GetSubModPath()
    local path          = writablePath .. modulePath ..global.MMO.LOCAL_USERDATA.."cloud_storage_cache_" .. roleID

    local jsonStr       = global.FileUtilCtl:getStringFromFile(path)
    if not jsonStr or string.len(jsonStr) == 0 then
        return false
    end
    local jsonData = cjson.decode(jsonStr)
    if not jsonData then
        return false
    end

    -- 
    self._data = jsonData
end

function CloudStorageProxy:storageLocalCache()
    if not self._data then
        return false
    end
    if self._storageTimerID then
        UnSchedule(self._storageTimerID)
        self._storageTimerID = nil
    end

    self._storageTimerID = PerformWithDelayGlobal(function()
        self._storageTimerID = nil

        local writablePath  = global.WritablePath
        local LoginProxy    = global.Facade:retrieveProxy( global.ProxyTable.LoginProxy )
        local roleID        = LoginProxy:GetSelectedRoleID()
        local module        = global.L_ModuleManager:GetCurrentModule()
        local modulePath    = module:GetSubModPath()
        local path          = writablePath .. modulePath .. global.MMO.LOCAL_USERDATA.."cloud_storage_cache_" .. roleID
        
        local jsonStr       = cjson.encode(self._data)
        global.FileUtilCtl:writeStringToFile(jsonStr, path)
    end, 1)
    return true
end

function CloudStorageProxy:getStorage(key)
    return self._data[key]
end

function CloudStorageProxy:setStorage(key, value)
    if type(key) ~= "string" then
        releasePrint("ERRORRRRRRRRRRRRRRRRRRRR setStorage key is string, have to")
        return false
    end

    self._data[key] = value

    self:storageLocalCache()
    self:RequestCloudStorage()
end


function CloudStorageProxy:RespCloudStorage(jsonStr)
    releasePrint("RespCloudStorage===", jsonStr)
    -- 本地有数据时，不使用服务器数据
    if next(self._data) then
        return
    end
    if nil == jsonStr or "" == jsonStr then
        return nil
    end
    local jsonData  = cjson.decode(jsonStr)
    if nil == jsonData then
        return nil
    end
    self._data = jsonData
    
    -- 同步本地缓存
    self:storageLocalCache()


    -- 广播
    global.Facade:sendNotification(global.NoticeTable.CloudStorageInit)
end

function CloudStorageProxy:RequestCloudStorage()
    if self._serverTimerID then
        UnSchedule(self._serverTimerID)
        self._serverTimerID = nil
    end

    self._serverTimerID = PerformWithDelayGlobal(function()
        self._serverTimerID = nil
        
        local jsonStr = cjson.encode(self._data)
        if not jsonStr then
            return nil
        end
        releasePrint("RequestCloudStorage===", jsonStr)

        -- out of buffer size limit
        if string.len(jsonStr) > 4096 then
            return nil
        end

        LuaSendMsg(global.MsgType.MSG_CS_CLOUD_STORAGE_CHANGE, 0, 0, 0, 0, jsonStr, string.len(jsonStr))
    end, 1)
end

function CloudStorageProxy:RegisterMsgHandler()
    CloudStorageProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
end


---------------------------------------------------------------
function GET_CLOUD_DATA(key)
    local CloudStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.CloudStorageProxy)
    return CloudStorageProxy:getStorage(key)
end

function SET_CLOUD_DATA(key, value)
    local CloudStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.CloudStorageProxy)
    CloudStorageProxy:setStorage(key, value)
end

return CloudStorageProxy
