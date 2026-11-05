local ModuleGameEnv = class("ModuleGameEnv")
local SubMod        = class( "SubMod" )
local Module        = class( "Module" )
local cjson         = require("cjson")


local DefaultVersionChannel = "1"


function ModuleGameEnv:ctor(module)
    self.module         = module

    self.loginData      = nil
    self.serverData     = nil

    self.customData     = nil

    self.refer          = nil
    self.selectedServer = nil
    self.lastservers    = {}

    self.selfip         = nil
    self.isWhitelist    = false
end

function ModuleGameEnv:Cleanup()
    self.loginData      = nil
    self.serverData     = nil

    self.customData     = nil

    self.refer          = nil
    self.selectedServer = nil
    self.lastservers    = {}

    self.roleinfo       = nil
end

function ModuleGameEnv:SetLoginData(data)
    self.loginData = data
end

function ModuleGameEnv:GetLoginData()
    return self.loginData
end

function ModuleGameEnv:SetServerData(data)
    self.serverData = data
end

function ModuleGameEnv:GetServerData()
    return self.serverData
end

function ModuleGameEnv:SetCustomData(data)
    self.customData = data
end

function ModuleGameEnv:GetCustomData()
    return self.customData
end

function ModuleGameEnv:SetCustomUrl(url)
    self.customURL = url
end

function ModuleGameEnv:GetCustomUrl()
    return self.customURL
end

function ModuleGameEnv:SetCustomIsLoaded(b)
    self.isCustomURLLoaded = b
end

function ModuleGameEnv:GetCustomIsLoaded()
    return self.isCustomURLLoaded
end

function ModuleGameEnv:IsNewServerlist()
    return self.isNewServerlist
end

function ModuleGameEnv:SetIsNewServerlist(b)
    self.isNewServerlist = b
end

function ModuleGameEnv:GetCustomDataByKey(key)
    return self.customData and self.customData[key]
end

function ModuleGameEnv:SetCustomDataByKey(key, value)
    if self.customData then 
        self.customData[key] = value
    end
end

function ModuleGameEnv:SetSelfip(ip)
    self.selfip = ip

    if not self.serverData then
        return nil
    end
    local whitelist = self.serverData.whitelist
    local uidWhiteList = self.serverData.uidWhiteList
    if not whitelist and not uidWhiteList then
        return nil
    end
    for _, v in pairs(whitelist or {}) do
        if v == self.selfip then
            self.isWhitelist = true
            break
        end
    end
    
    if not self.isWhitelist then
        local uid = self:GetLoginUid()
        uid = uid and tostring(uid) or nil
        for k,v in pairs(uidWhiteList or {}) do
            if uid and uid == tostring(v) then
                self.isWhitelist = true
                break
            end
        end
    end
end

function ModuleGameEnv:IsWhitelist()
    -- 盒子传入白名单
    if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
        if global.L_GameEnvManager:GetLauncherWhitelist() then
            return true
        end
    end

    return self.isWhitelist
end

function ModuleGameEnv:GetSrvlist(all)
    if not self.serverData then
        return {}
    end
    if all then
        return self.serverData.srvlist
    end

    local isWhitelist = self:IsWhitelist()
    local items = {}
    for _, v in ipairs(self.serverData.srvlist) do
        if not (v.state == 5 and (not isWhitelist)) then
            table.insert(items, v)
        end
    end
    return items
end

function ModuleGameEnv:GetResVersion()
    if not self.serverData or not self.serverData.resVer then
        return "?v=1.1.1"
    end

    return self.serverData.resVer
end

function ModuleGameEnv:GetResDownloadUrl()
    if not self.serverData or not self.serverData.resURL then
        return global.L_GameEnvManager:GetRootDomain()
    end

    return self.serverData.resURL
end

function ModuleGameEnv:GetResDownloadUrl2()
    if not self.serverData or not self.serverData.resURL2 then
        return global.L_GameEnvManager:GetRootDomain2()
    end

    return self.serverData.resURL2
end

function ModuleGameEnv:GetSceneDownloadUrl()
    if not self.serverData or not self.serverData.sceneURL then
        return self:GetResDownloadUrl()
    end

    return self.serverData.sceneURL
end

function ModuleGameEnv:GetSceneDownloadVer()
    if not self.serverData or not self.serverData.sceneResVer then
        return self:GetResVersion()
    end

    return self.serverData.sceneResVer
end

function ModuleGameEnv:GetGMResURL()
    if not self.serverData or not self.serverData.gmResURL then
        return nil
    end

    return self.serverData.gmResURL
end

function ModuleGameEnv:GetGMResURL2()
    if not self.serverData or not self.serverData.gmResURL2 then
        return nil
    end

    return self.serverData.gmResURL2
end

function ModuleGameEnv:GetGMResVer()
    if not self.serverData or not self.serverData.gmResVer then
        return nil
    end

    return self.serverData.gmResVer
end

function ModuleGameEnv:GetGMWebResUrl()
    if not self.serverData or not self.serverData.gmWebResURL then
        return nil
    end

    return self.serverData.gmWebResURL
end

function ModuleGameEnv:GetGMWebResVer()
    if not self.serverData or not self.serverData.gmWebResVer then
        return nil
    end

    return self.serverData.gmWebResVer
end

function ModuleGameEnv:GetGMInitResURL()
    if not self.serverData or not self.serverData.gmInitResURL then
        return nil
    end

    return self.serverData.gmInitResURL
end

function ModuleGameEnv:GetGMInitResURL2()
    if not self.serverData or not self.serverData.gmInitResURL2 then
        return nil
    end

    return self.serverData.gmInitResURL2
end

function ModuleGameEnv:GetGMInitResVer()
    if not self.serverData or not self.serverData.gmInitResVer then
        return nil
    end

    return self.serverData.gmInitResVer
end

function ModuleGameEnv:SetRefer(refer)
    self.refer = refer
end

function ModuleGameEnv:GetRefer()
    return self.refer
end

function ModuleGameEnv:GetServerByID(srvid)
    local srvlist = self:GetSrvlist()
    for k, v in pairs(srvlist) do
        if tostring(v.serverId) == tostring(srvid) then
            return v
        end
    end
    return nil
end

function ModuleGameEnv:SetSelectedServer(server)
    self.selectedServer = server
end

function ModuleGameEnv:GetSelectedServer()
    return self.selectedServer
end

function ModuleGameEnv:GetSelectedServerUrlSuffix()
    if not self.selectedServer or not self.selectedServer.urlSuffix then
        return DefaultVersionChannel
    end

    return self.selectedServer.urlSuffix
end

function ModuleGameEnv:GetLastservers()
    return self.lastservers
end

-- 先行服资源版本 修改下载资源地址
function ModuleGameEnv:GetSelectedServerGmurlsuffix()
    if not self.selectedServer or not self.selectedServer.gmurlsuffix then
        return
    end

    return self.selectedServer.gmurlsuffix
end

function ModuleGameEnv:ReadLastServers()
    if not self.serverData then
        return nil
    end

    --只针对美杜莎云游戏，根据安卓层传过来的区服id进行显示
    local lastServerID = global.L_NativeBridgeManager:getLastServerID()
    if lastServerID then
        self.selectedServer = self:GetServerByID(lastServerID)
    end

    -- 盒子传入的
    local launcherSrvid = global.L_GameEnvManager:GetLauncherSrvID()
    if not self.selectedServer and launcherSrvid then
        self.selectedServer = self:GetServerByID(launcherSrvid)
    end
    
    -- 上次选择
    if not self.selectedServer then
        local userData = UserData:new(self.module:GetID() .. "_data")
        local jsonStr  = userData:getStringForKey("lastservers", "")
        if jsonStr and string.len(jsonStr) > 0 then
            local jsonData  = cjson.decode(jsonStr) or {}
            local lastsrvid = jsonData[1]
            if not self.selectedServer and lastsrvid and lastsrvid ~= "" then
                self.selectedServer = self:GetServerByID(lastsrvid)
            end
            if jsonData and jsonData[3] then 
                jsonData[3] = nil
            end
            self.lastservers = jsonData
        else
            self.lastservers = {}
        end
    end
    if not self.lastservers or #self.lastservers == 0 then 
        local items = self:GetHasRoleSrvItems(true)
        if items and items[1] then 
            self.lastservers[1] = items[1].serverId
            if not self.selectedServer and self.lastservers[1] and self.lastservers[1] ~= "" then
                self.selectedServer = self:GetServerByID(self.lastservers[1])
            end
        end
        if items and items[2] then 
            self.lastservers[2] = items[2].serverId
        end
    end

    -- 推荐服
    if not self.selectedServer and self.refer then
        self.selectedServer = self:GetServerByID(self.refer)
    end

    -- 最后一个服务器
    if not self.selectedServer then
        local srvlist = self:GetSrvlist()
        self.selectedServer = srvlist[#srvlist]
    end
end

function ModuleGameEnv:SaveLastServers()
    if not self.serverData then
        return nil
    end

    -- 已选择存储到本地
    local lastserversN = {}
    table.insert(lastserversN, self.selectedServer.serverId)
    for i, v in ipairs(self.lastservers) do
        if v ~= self.selectedServer.serverId and #lastserversN < 2 then
            table.insert(lastserversN, v)
        end
    end

    local userData = UserData:new(self.module:GetID() .. "_data")
    local jsonStr  = cjson.encode(lastserversN)
    userData:setStringForKey("lastservers", jsonStr)
    userData:writeMapDataToFile()
end

function ModuleGameEnv:RequestRoleInfo(func)
    if nil == self.module:GetOperID() then
        return false
    end
    local uid = self:GetLoginUid()
    if uid == nil then 
        return 
    end
    local downUrl  = ""
    local RoleRecordDoamin = self:GetCustomDataByKey("RoleRecordDoamin")
    if RoleRecordDoamin and string.len(RoleRecordDoamin) > 0 then
        downUrl    = RoleRecordDoamin
    end
    
    if downUrl and string.len(downUrl) > 0 then
        downUrl = string.format("%s/user_server/game_%s/user_%s.txt?time=%s", downUrl, self.module:GetOperID(), uid, os.time()) 
        -- http数据请求回调
        local function callback(success, response)
            if not success then
                if func then 
                    func()
                end
                release_print("request roleinfo error: step 1, http callback！ failed")
                return false
            end
            local jsonData = cjson.decode(response)
    
            -- json decode error
            if not jsonData then
                if func then 
                    func()
                end
                release_print("request roleinfo error: step 2, http callback！ json decode error")
                return false
            end

            dump(jsonData)
            if func then 
                func(jsonData)
            end
        end
        HTTPRequest(downUrl, callback)
    end

    return true
end

function ModuleGameEnv:UploadRoleInfo()
    if nil == self.module:GetOperID() then
        return false
    end

    local uid = self:GetLoginUid()
    local token = self:GetLoginToken()
    if nil == uid then
        return false
    end

    if nil == token then 
        return false
    end

    if not self.roleinfo then
        return nil
    end
    if type(self.roleinfo) ~= "table" then
        return nil
    end

    if uid then
        local jsonStr           = cjson.encode(self.roleinfo)
        local upLoadUrl  = ""
        local RoleRecordUpLoadDoamin = self:GetCustomDataByKey("RoleRecordUpLoadDoamin")
        if RoleRecordUpLoadDoamin and string.len(RoleRecordUpLoadDoamin) > 0 then
            upLoadUrl    = RoleRecordUpLoadDoamin
        end
        if upLoadUrl and string.len(upLoadUrl) > 0 then
            upLoadUrl = string.format("%s/api/user/upload_play_history",upLoadUrl)  
            local HTTPRequestPostFile = function(url, callback, data)
                local httpRequest = cc.XMLHttpRequest:new()
                httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
                httpRequest.timeout = 100000 -- 10 s
                httpRequest:open("POST", url)
                if callback then
                    local function HttpResponseCB()
                        local code = httpRequest.status
                        local success = code >= 200 and code < 300
                        local response = httpRequest.response
                        callback(success,code,response)
                        releasePrint("Http Request Code:" .. tostring(code))
                    end
                    httpRequest:setRequestHeader("Content-type", "multipart/form-data, boundary=upload_ymyzt")
                    httpRequest:setRequestHeader("x-token", token or "")
                    httpRequest:registerScriptHandler(HttpResponseCB)
                end
                httpRequest:send(data)
            end
            local filename = string.format("user_%s.txt", uid)  
            local body =   "--upload_ymyzt\r\n"..
            "content-disposition: form-data; name=\"game_id\"\r\n"..
            "\r\n" .. 
            self.module:GetOperID().."\r\n"..
            "--upload_ymyzt\r\n"..
            'content-disposition: form-data; name="file"; filename="'..filename..'"\r\n' ..
            "Content-Type: text/plain\r\n" ..
            "\r\n" ..
            jsonStr.."\r\n" ..
            "--upload_ymyzt--\r\n"
            
            HTTPRequestPostFile(upLoadUrl,function(success,code,response) 
                dump({success,code,response},"HTTPRequestPostFile___")
            
            end,body)
        end
        
    end
    
    return true
end

function ModuleGameEnv:GetRoleInfoByServerID(serverID)
    if not self.roleinfo then
        return 0
    end
    serverID = tostring(serverID)
    if not self.roleinfo[serverID] then 
        return 0
    end

    if type(self.roleinfo[serverID]) ~= "table" then 
        return 0
    end

    return tonumber(self.roleinfo[serverID].count) or 0
end

function ModuleGameEnv:GetRoleinfo()
    return self.roleinfo
end

function ModuleGameEnv:SetRoleinfo(roleInfo)
    self.roleinfo = roleInfo
end

function ModuleGameEnv:SetRoleCountByServerID(serverID, count)
    if not self.roleinfo then
        self.roleinfo = {}
    end
    serverID = tostring(serverID)
    self.roleinfo[serverID] = {count = count , time = os.time()}
    self:savelocalRoleinfo()
    self:UploadRoleInfo()
end

function ModuleGameEnv:GetHasRoleSrvItems(largerSort)
    local srvlist = self:GetSrvlist()
    if not srvlist then 
        return nil
    end
    local srvById = {}
    for i, v in ipairs(srvlist) do
        srvById[tostring(v.serverId)] = v
    end
    local items = {}
    local roleCount
    local srvId 
    local roleinfo = self:GetRoleinfo()
    if not roleinfo then 
        return nil
    end

    local roleInfoVec = {}
    for srvId, v in pairs(roleinfo) do
        if type(v) ~= "table" then 
            v = {}
        end 
        table.insert(roleInfoVec,{serverID = srvId , count = v.count or 0, time =  v.time or 0})
    end

    table.sort(roleInfoVec, function (a ,b)
        if largerSort then 
            return a.time > b.time
        else
            return a.time < b.time
        end
    end)

    for i, v in ipairs(roleInfoVec) do
        roleCount = tonumber(v.count) or 0
        srvId = tostring(v.serverID) or ""
        if roleCount > 0 and srvById[srvId] then 
            table.insert(items, srvById[srvId] )
        end
    end

    return items
end

-- function ModuleGameEnv:checkLocalRoleinfo()
--     if nil == global.L_GameEnvManager:GetChannelID() then
--         return false
--     end
--     if nil == self.module:GetOperID() then
--         return false
--     end

--     local uid = self:GetLoginUid()
--     if nil == uid then
--         return false
--     end

--     if nil == global.L_ModuleManager:GetLauncherModuleID() then
--         return false
--     end

--     -- 本地数据超时，不再使用
--     local launcherModID     = global.L_ModuleManager:GetLauncherModuleID()
--     local userData          = UserData:new(launcherModID .. "_data")
--     local srvlistTimeout    = tonumber(self:GetCustomDataByKey("srvlistTimeout"))
--     local lastUnixtime      = userData:getIntegerForKey("last_unixtime", 0)
--     local currUnixtime      = os.time()
--     if nil == lastUnixtime or 0 == lastUnixtime or (srvlistTimeout and currUnixtime - lastUnixtime > srvlistTimeout) then
--         -- 重置本地上次拉取时间戳
--         userData:setIntegerForKey("last_unixtime", currUnixtime)
--         userData:writeMapDataToFile()
--         return false
--     end

--     -- 本地读取
--     self:readLocalRoleinfo()

--     -- 本地有数据
--     if self.roleinfo then
--         global.L_ModuleChooseManager:OnServerRoleInfoResp()
--         return true
--     end
--     return false
-- end

function ModuleGameEnv:savelocalRoleinfo()
    if not self.roleinfo then
        return nil
    end
    if type(self.roleinfo) ~= "table" then
        return nil
    end

    if nil == self.module:GetOperID() then
        return false
    end

    local uid = self:GetLoginUid()
    if not uid then 
        return false
    end
    uid = tostring(uid)
    if uid and string.len(uid) > 0 then
        local fileUtil          = cc.FileUtils:getInstance()
        local filename          = self.module:GetID() .. "_roleinfoNew" .. uid
        local localStoragePath  = fileUtil:getWritablePath() .. filename
    
        local jsonStr           = cjson.encode(self.roleinfo)
        fileUtil:writeStringToFile(jsonStr, localStoragePath)
    end
end

function ModuleGameEnv:readLocalRoleinfo()
    self.roleinfo   = nil
    local uid = self:GetLoginUid()
    if not uid then 
        return nil
    end
    uid = tostring(uid)
    if nil == self.module:GetOperID() then
        return nil
    end
    if uid and string.len(uid) > 0 then
        local fileUtil          = cc.FileUtils:getInstance()
        local filename          = self.module:GetID() .. "_roleinfoNew" .. uid
        local localStoragePath  = fileUtil:getWritablePath() .. filename

        if fileUtil:isFileExist(localStoragePath) then
            local jsonStr       = fileUtil:getDataFromFileEx(localStoragePath)
            if jsonStr and jsonStr ~= "" then
                self.roleinfo   = cjson.decode(jsonStr)
            end
        end
    end
end

function ModuleGameEnv:GetLoginUid()
    local uid = global.L_NativeBridgeManager:GetUsername()
    if nil == uid then
        --盒子uid
        local boxuid = global.L_GameEnvManager:GetEnvDataByKey("uid")
        local boxtoken = nil
        
        if boxtoken == nil or boxtoken == "" then
            boxtoken = global.L_GameEnvManager:GetEnvDataByKey("new_boxtoken")
        end
        if boxtoken == nil or boxtoken == "" then
            boxtoken = global.L_GameEnvManager:GetEnvDataByKey("token")
        end
        if boxuid and boxtoken then 
            uid = boxuid
        end

        if not uid then 
            --pc 联运
            local PCPlatform        = global.L_GameEnvManager:GetEnvDataByKey("PCPlatform")
            local user_id           = global.L_GameEnvManager:GetEnvDataByKey("user_id")
            local token             = global.L_GameEnvManager:GetEnvDataByKey("token")
            if PCPlatform and user_id and token then 
                uid = user_id
            end 
        end
    end
    
    return uid
end

function ModuleGameEnv:GetLoginToken()
    local token = global.L_NativeBridgeManager:GetPassword()
    if nil == token then
        local boxuid = global.L_GameEnvManager:GetEnvDataByKey("uid")
        local boxtoken = nil
        if boxtoken == nil or boxtoken == "" then
            boxtoken = global.L_GameEnvManager:GetEnvDataByKey("new_boxtoken")
        end
        if boxtoken == nil or boxtoken == "" then
            boxtoken = global.L_GameEnvManager:GetEnvDataByKey("token")
        end
        if boxuid and boxtoken then 
            token = boxtoken
        end
        if not token then 
            --pc 联运
            local PCPlatform        = global.L_GameEnvManager:GetEnvDataByKey("PCPlatform")
            local user_id           = global.L_GameEnvManager:GetEnvDataByKey("user_id")
            local PCtoken             = global.L_GameEnvManager:GetEnvDataByKey("token")
            if PCPlatform and user_id and PCtoken then 
                token = PCtoken
            end 
        end
    end
    return token
end
-------------------------------------------------------------
-- sub module
function SubMod:ctor(info, id, name, operid, Sign, xk, platformId)
    self.info           = info
    self.id             = id or ""
    self.name           = name or ""
    self.operid         = operid or ""
    self.Sign           = Sign or false
    self.xk             = decodeXK(xk)
    self.gameEnv        = ModuleGameEnv.new(self)

    self.originVer      = ""
    self.cacheVer       = ""
    self.remoteVer      = ""

    self.platformId     = platformId
end

function SubMod:GetSubModInfo()
    return self.info
end

function SubMod:GetID()
    return self.id
end

function SubMod:GetName()
    return self.name
end

function SubMod:GetOperID()
    return self.operid
end

function SubMod:GetGameEnv()
    return self.gameEnv
end

function SubMod:GetIsSign()
    return self.Sign and self.Sign == 1
end

function SubMod:GetXK()
    return self.xk
end

function SubMod:GetPlatformID()
    return self.platformId
end

function SubMod:SetRemoteVersion(remoteVer)
    self.remoteVer = remoteVer
end

function SubMod:GetRemoteVersion()
    return self.remoteVer
end

-------------------------------------------------------------
-- module
function Module:ctor( id, name, version, suffix, info, subMod, Sign, refer)
    self.id      = id or ""
    self.name    = name or ""
    self.version = version or global.VersionName.default
    self.suffix  = suffix
    self.modInfo = info
    self.refer   = refer

    self.originVer = ""
    self.cacheVer  = ""
    self.remoteVer = ""

    -- 
    self.currentSubMod  = nil
    self.subMods        = {}
    if subMod then
        for i, v in ipairs(subMod) do
            self.subMods[i] = SubMod.new(v, v.id, v.name, v.operid, Sign, v.xk, v.platformId)
        end
    end
end

function Module:GetID()
    return self.id
end

function Module:GetName()
    return self.name
end

function Module:GetModInfo()
    return self.modInfo
end

function Module:GetRefer()
    return self.refer
end

function Module:SetVersion( version )
    self.version = version
end

function Module:GetVersion()
    return self.version
end

function Module:IsStab()
    return self.version == global.VersionName.stab
end

function Module:IsBeta()
    return self.version == global.VersionName.beta
end

function Module:IsAlpha()
    return self.version == global.VersionName.alpha
end

function Module:GetSuffix()
    return self.suffix
end

function Module:GetReferSubModID()
    return self.modInfo.refer
end

function Module:GetSubMods()
    return self.subMods
end

function Module:GetSubModByID(id)
    for _, subMod in pairs(self.subMods) do
        if subMod:GetID() == id then
            return subMod
        end
    end
    return nil
end

function Module:RegisterSubMod(subModID)
    local subMod = self:GetSubModByID(subModID)
    if not subMod then
        releasePrint("can't find subMod, by RegisterSubMod", subModID)
        return false
    end

    -- set current submod
    self.currentSubMod = subMod

    return true
end

function Module:GetCurrentSubMod()
    return self.currentSubMod
end

function Module:GetOperID()
    return self.currentSubMod:GetOperID()
end

function Module:GetGameEnv()
    return self.currentSubMod:GetGameEnv()
end

-- 模块可写根路径(writable_path/mod_xxxx/)
function Module:GetRootWritablePath()
    return string.format( "%s%s/", cc.FileUtils:getInstance():getWritablePath(), getNewFoldername(tostring(self.id)) )
end

-- 模块 当前版本 访问路径(mod_xxxx/beta/suffix/  mod_xxxx/beta/)
function Module:GetPath()
    local basePath = string.format( "%s/%s/", getNewFoldername(tostring(self.id)), getNewFoldername(tostring(self.version)) )
    local newPath = self.suffix and string.format( "%s/%s/", basePath, tostring(self.suffix) ) or basePath
    return newPath
end

-- 模块 stab 访问路径(mod_launcher/stab/suffix/)
function Module:GetStabPath()
    local basePath = string.format( "%s/%s/", getNewFoldername(tostring(self.id)), getNewFoldername(global.VersionName.stab) )
    local newPath = self.suffix and string.format( "%s/%s/", basePath, tostring(self.suffix) ) or basePath
    return newPath
end

-- 模块 beta 访问路径(mod_xxxx/beta/suffix/  mod_xxxx/beta/)
function Module:GetBetaPath()
    local basePath = string.format( "%s/%s/", getNewFoldername(tostring(self.id)), getNewFoldername(global.VersionName.beta) )
    local newPath = self.suffix and string.format( "%s/%s/", basePath, tostring(self.suffix) ) or basePath
    return newPath
end

-- 模块 stab 访问路径(mod_xxxx/subMod/)
function Module:GetSubModPath()
    local subMod = self:GetCurrentSubMod()
    if not subMod then
        releasePrint("can't find subMod")
        return self:GetStabPath()
    end

    return string.format( "%s/%s/", getNewFoldername(tostring(self.id)), getNewFoldername(subMod:GetID()) )
end

-- 模块 当前版本 远端访问路径(remote_path/mod_launcher/channel/beta/suffix/)
function Module:GetRemotePath( channel )
    if not channel or channel == "" then
        channel = DefaultVersionChannel
    end
    if self.suffix then
        return string.format( "%s/%s/%s/%s/", tostring(self.id), channel, tostring(self.version), tostring(self.suffix) )
    else
        return string.format( "%s/%s/%s/", tostring(self.id), channel, tostring(self.version) )
    end
end

-- 模块 stab 远端访问路径(remote_path/mod_launcher/channel/stab/suffix/)
function Module:GetRemoteStabPath( channel )
    if not channel or channel == "" then
        channel = DefaultVersionChannel
    end
    if self.suffix then
        return string.format( "%s/%s/%s/%s/", tostring(self.id), channel, global.VersionName.stab, tostring(self.suffix) )
    else
        return string.format( "%s/%s/%s/", tostring(self.id), channel, global.VersionName.stab )
    end
end

function Module:GetVersionFileName()
    return string.format( "%s_%s", tostring(self.id), "version.manifest" )
end

function Module:GetManifestFileName()
    return string.format( "%s_%s", tostring(self.id), "project.manifest" )
end

function Module:GetOriginVersion()
    if "" ~= self.originVer then
        return self.originVer
    end

    local OriginVersionPath = string.format( "%s%s", self:GetPath(), self:GetVersionFileName())
    if global.FileUtilCtl:isFileExist( OriginVersionPath ) then
        local strBuffer = global.FileUtilCtl:getDataFromFileEx( OriginVersionPath )
        local jsonData = cjson.decode(strBuffer)
        if jsonData then
            self.originVer = jsonData.version
        end
    end

    if "" == self.originVer then
        self.originVer = "0.0.0"
    end

    return self.originVer
end

function Module:GetCacheVersion()
    if "" ~= self.cacheVer then
        return self.cacheVer
    end

    local cacheVersionFile = self:GetManifestFileName()
    local writePath        = global.FileUtilCtl:getWritablePath()
    local modulePath       = self:GetPath()
    local cacheVersionPath = string.format( "%s%s%s", writePath, tostring( modulePath ), cacheVersionFile )
    if global.FileUtilCtl:isFileExist( cacheVersionPath ) then
        local strBuffer = global.FileUtilCtl:getDataFromFileEx( cacheVersionPath )
        local jsonData = cjson.decode(strBuffer)
        if jsonData then
            self.cacheVer = jsonData.version
        end
    end

    if "" == self.cacheVer then
        self.cacheVer = "0.0.0"
    end

    return self.cacheVer
end

function Module:SetRemoteVersion( ver )
    self.remoteVer = ver
end

function Module:GetRemoteVersion()
    return self.remoteVer
end

function Module:GetAllVersionForDisplay()
    return string.format("%s/%s/%s", tostring(self:GetOriginVersion()), tostring(self:GetCacheVersion()), tostring(self:GetRemoteVersion()))
end

return Module
