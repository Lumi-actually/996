local ResDownloader = class('ResDownloader')

local RETRY_LIMIT       = 3
local DOWNLOAD_MAX      = 3

----------------------
-- task
local DownloadTask = class("DownloadTask")
function DownloadTask:ctor(path, url, isFullURL, downloadCB)
    self.url        = url
    self.path       = path
    self.isFullURL  = isFullURL
    self.downloadCB = downloadCB
end

function DownloadTask:Set(path, url, isFullURL, downloadCB)
    self.url        = url
    self.path       = path
    self.isFullURL  = isFullURL
    self.downloadCB = downloadCB
end

local DownloadTaskCache = class("DownloadTaskCache")
function DownloadTaskCache:ctor()
    self._cache = {}
    for i = 1, 100, 1 do
        table.insert(self._cache, DownloadTask.new())
    end
end

function DownloadTaskCache:Alloc()
	local notification = table.remove(self._cache) or DownloadTask.new()
	return notification
end

function DownloadTaskCache:Recycle(task)
	table.insert(self._cache, task)
end

----------------------
-- downloader
function ResDownloader:ctor()
end

function ResDownloader:Cleanup()
    self._tasks             = {}

    self._retries           = {}
    self._ignores           = {}
    self._ignoreTime        = 0
end

function ResDownloader:CleanupDownloadCount()
    self._downloadCount     = 0
    self._downloadingTasks  = {}
end

function ResDownloader:init()
    local module            = global.L_ModuleManager:GetCurrentModule()
    local modulePath        = module:GetSubModPath()
    local moduleGameEnv     = module:GetGameEnv()
    self._downloadDomain    = moduleGameEnv:GetGMWebResUrl()
    self._gmWebResVer       = moduleGameEnv.GetGMWebResVer and moduleGameEnv:GetGMWebResVer() or ""
    self._storagePath       = global.WritablePath .. modulePath

    -- GM 自定义搜索路径
    local gmCachePath           = global.L_GameEnvManager:GetGMCachePath()
    if global.isWindows and gmCachePath and string.len(gmCachePath) > 0 then
        self._storagePath   = gmCachePath
    end


    self._downloadStamp     = 0
    self._downloadCount     = 0
    self._downloadingTasks  = {}

    self._tasks             = {}

    self._retries           = {}
    self._ignores           = {}
    self._ignoreTime        = 0

    -- 静默下载
    self._downloadLogs      = {}
    self._slientTasks       = {}
    self._silentComplted    = false

    -- GM资源列表
    self._gmResList         = {}

    -- ios文件夹是否存在
    self._iosFolderStatus   = {}

    --
    self._downloadTaskCache = DownloadTaskCache.new()
end

-----------------------------------------------------------------------------
function ResDownloader:initBackgroundRes()
    -- 审核服，不触发
    if global.L_GameEnvManager:IsReview() then
        return false
    end

    -- 静默下载标记
    local userData = UserData:new("silentDownload")
    self._silentComplted = (userData:getStringForKey("silentCompleted", "") == "1")
    if self._silentComplted then
        return false
    end

    local cjson = require("cjson")
    local filePath = "data_config/downloadpack.json"

    if not global.FileUtilCtl:isFileExist(filePath) then
        return false
    end

    local jsonStr = global.FileUtilCtl:getDataFromFileEx(filePath)
    if not jsonStr or jsonStr == "" or jsonStr == filePath then
        return false
    end

    local jsonData = cjson.decode(jsonStr)
    if not jsonData then
        return false
    end

    self._slientTasks = jsonData
end

function ResDownloader:isSilentComplted()
    return self._silentComplted
end

function ResDownloader:checkSlientTask()
    if self:isSilentComplted() then
        return false
    end

    if #self._slientTasks > 0 then
        local silentData = table.remove(self._slientTasks, 1)
        if silentData and silentData ~= "" then
            silentData = string.gsub(tostring(silentData), "\\", "/")
            silentData = string.gsub(tostring(silentData), " ", "")
        end
        return self:download(silentData, function(isOK) end)
    else
        local userData = UserData:new("silentDownload")
        userData:setStringForKey("silentCompleted", "1")
        userData:writeMapDataToFile()
        self._silentComplted = true
    end
    return nil
end

function ResDownloader:initGMResList()
    local cjson = require("cjson")
    local filePath = "data_config/webres.json"

    if not global.FileUtilCtl:isFileExist(filePath) then
        return false
    end

    local jsonStr = global.FileUtilCtl:getDataFromFileEx(filePath)
    if not jsonStr or jsonStr == "" or jsonStr == filePath then
        return false
    end

    local jsonData = cjson.decode(jsonStr)
    if not jsonData then
        return false
    end

    -- 下载列表
    for _, v in ipairs(jsonData) do
        self._gmResList[v] = 1
    end
end

-----------------------------------------------------------------------------
function ResDownloader:Tick(dt)
    local currTime = os.time()
    if self._downloadCount < DOWNLOAD_MAX or currTime - self._downloadStamp > 10 then
        self._downloadStamp = currTime

        -- 
        while true do
            local downloadR = self:checkDownloadTask()
            if downloadR >= 0 then
                break
            end
        end
    end

    self._ignoreTime = self._ignoreTime + dt
    if self._ignoreTime >= 600 then
        self._ignoreTime = 0
        self:cleanupAllIgnored()
        self:cleanupAllRetries()
    end
end

-----------------------------------------------------------------------------
-- download logic
function ResDownloader:download(path, downloadCB)
    if not path or path == "" then
        print("downloader param error")
        downloadCB(false, path)
        return false
    end

    -- FIXME: create folder
    if global.isIOS then
        local folder = GetFileInfoByFilePath(path)
        if string.len(folder) > 0 then
            if not self._iosFolderStatus[folder] then
                local dirPath = self._storagePath .. folder
                if not global.FileUtilCtl:isDirectoryExist(dirPath) then
                    global.FileUtilCtl:createDirectory(dirPath)
                end
                self._iosFolderStatus[folder] = true
            end
        end
    end

    local resUrl = self._downloadDomain and self._downloadDomain .. path or nil
    local downloadTask = self._downloadTaskCache:Alloc()
    downloadTask:Set(path, resUrl, false, downloadCB)
    self:pushTask(downloadTask)

    return true
end

function ResDownloader:downloadEx(path, url, downloadCB)
    if not path or path == "" or not url or url == "" then
        print("downloader param error")
        downloadCB(false, path)
        return false
    end

    -- FIXME: create folder
    if global.isIOS then
        local folder = GetFileInfoByFilePath(path)
        if string.len(folder) > 0 then
            if not self._iosFolderStatus[folder] then
                local dirPath = self._storagePath .. folder
                if not global.FileUtilCtl:isDirectoryExist(dirPath) then
                    global.FileUtilCtl:createDirectory(dirPath)
                end
                self._iosFolderStatus[folder] = true
            end
        end
    end
    local downloadTask = self._downloadTaskCache:Alloc()
    downloadTask:Set(path, url, true, downloadCB)
    self:pushTask(downloadTask)

    return true
end

function ResDownloader:pushTask(task)
    table.insert(self._tasks, task)
end

function ResDownloader:insertTask(task)
    table.insert(self._tasks, 1, task)
end

function ResDownloader:popTask()
    if #self._tasks > 0 then
        return table.remove(self._tasks, 1)
    end
    return nil
end

function ResDownloader:isIgnored(path)
    return self._ignores[path] == 1
end

function ResDownloader:cleanupAllIgnored()
    self._ignores = {}
end

function ResDownloader:isDownloading(path)
    for _, v in ipairs(self._downloadingTasks) do
        if path == v.path then
            return true
        end
    end
    return false
end

function ResDownloader:isOutRetries(task)
    return self._retries[task.path] == RETRY_LIMIT
end

function ResDownloader:getRetries(task)
    return self._retries[task.path] or 0
end

function ResDownloader:cleanupAllRetries()
    self._retries = {}
end

function ResDownloader:isGMRes(path)
    return self._gmResList[path] == 1
end

---------------------------------------------
-- download
function ResDownloader:checkDownloadTask()
    -- empty task
    local task = self:popTask()
    if not task then
        self:checkSlientTask()
        return 0
    end

    -- check param
    if not task.path or "" == task.path then
        task.downloadCB(false, task.path)
        self._downloadTaskCache:Recycle(task)
        return -1
    end

    -- check ignore
    if self:isIgnored(task.path) then
        task.downloadCB(false, task.path)
        self._downloadTaskCache:Recycle(task)
        return -1
    end

    -- check out retries
    if self:isOutRetries(task) then
        task.downloadCB(false, task.path)
        self._downloadTaskCache:Recycle(task)
        return -1
    end

    -- is exist
    if global.FileUtilCtl:isFileExist(task.path) then
        task.downloadCB(true, task.path)
        self._downloadTaskCache:Recycle(task)
        return -1
    end

    -- check downloading
    if self:isDownloading(task.path) then
        self:insertTask(task)
        return 1
    end

    -- download count
    self._downloadCount = self._downloadCount + 1
    table.insert(self._downloadingTasks, task)

    --
    if task.isFullURL then
        -- 下载自定义资源
        self:downloadGMRes(task)
    elseif task.url and self:isGMRes(task.path) then
        -- 是gm资源
        self:downloadGMRes(task)
    else
        self:downloadRes(task)
    end

    return 1
end

function ResDownloader:downloadGMRes(task)
    -- download gmres
    -- print("download begin    ---GM", task.path)
    if global.HttpDownloader.AsyncDownloadFullURL and self._gmWebResVer ~= "" then
        local url = task.url .. self._gmWebResVer
        local path = self._storagePath .. task.path
        global.HttpDownloader:AsyncDownloadFullURL(url, path,
            function(isOK)
                PerformWithDelayGlobal(function()
                    self:downloadCallback(isOK, task)
                end,0)
            end,
            0
        )
    else
        local url = task.url
        local path = self._storagePath .. task.path
        global.HttpDownloader:AsyncDownloadEasy(url, path,
            function(isOK)
                PerformWithDelayGlobal(function()
                    self:downloadCallback(isOK, task)
                end,0)
            end,
            0
        )
    end
end

function ResDownloader:downloadRes(task)
    -- print("download begin    +++EX", task.path)
    global.HttpDownloader:AsyncDownloadEx(task.path, function(isOK)
        PerformWithDelayGlobal(function()
            self:downloadCallback(isOK, task)
        end,0)
    end)
end

function ResDownloader:downloadCallback(isOK, task)
    -- print("download complete ***  ", task.path, isOK)

    -- 总下载数量--
    self._downloadCount = self._downloadCount - 1
    self._downloadCount = math.max(self._downloadCount, 0)

    -- 当前任务 移除
    for i, v in ipairs(self._downloadingTasks) do
        if v.path == task.path then
            table.remove(self._downloadingTasks, i)
            break
        end
    end

    if isOK then
        task.downloadCB(isOK)
        self._downloadTaskCache:Recycle(task)
    else
        self:removeFile(task.path)
        self:insertTask(task)

        self._retries[task.path] = self._retries[task.path] or 0
        self._retries[task.path] = self._retries[task.path] + 1
        if self:isOutRetries(task) then
            print("download failed!!! it will be ignored", task.path)
            self._ignores[task.path] = 1
        end
    end
end

function ResDownloader:removeFile(filePath)
    if not global.FileUtilCtl:isFileExist(filePath) then
        return
    end
    local fullPath = global.FileUtilCtl:fullPathForFilename(filePath)
    if not (fullPath ~= "" and string.find(fullPath, global.FileUtilCtl:getWritablePath())) then
        return
    end

    global.FileUtilCtl:removeFile(fullPath)
    global.FileUtilCtl:purgeCachedEntries()
end
-- download
---------------------------------------------

function ResDownloader:storageLog(taskName, log)
    self._downloadLogs[taskName] = log
end

function ResDownloader:getDownloadLogs()
    return self._downloadLogs
end

return ResDownloader
