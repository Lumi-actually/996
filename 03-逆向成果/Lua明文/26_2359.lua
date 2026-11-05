local ModuleChooseManager = class("ModuleChooseManager")

function ModuleChooseManager:ctor()
end

function ModuleChooseManager:OpenLayer()
    if not self._layer then
        self._layer = requireLauncher( "logic/ModuleChooseLayer" ).create()
        self._type  = 0
        global.L_GameLayerManager:OpenLayer(self)
    end
end

function ModuleChooseManager:CloseLayer()
    if self._layer then
        self._layer:OnClose()
    end
    global.L_GameLayerManager:CloseLayer(self)
end

function ModuleChooseManager:OnAlreadyUpToDate()
    if not self._layer then
        return nil
    end
    self._layer:OnAlreadyUpToDate()
end

function ModuleChooseManager:OnLoginSuccessResp()
    if not self._layer then
        return nil
    end
    self._layer:OnLoginSuccessResp()
end

function ModuleChooseManager:OnServerRoleInfoResp()
    if not self._layer then
        return nil
    end
    self._layer:UpdateServerRoleInfo()
end

function ModuleChooseManager:UpdateServersWhenRoleInfoGet()
    if not self._layer then
        return nil
    end
    self._layer:UpdateServersWhenRoleInfoGet()
end

function ModuleChooseManager:ShowAnnounce()
    if not self._layer then
        return nil
    end
    self._layer:ShowModuleAnnounce()
end

function ModuleChooseManager:RespModSrvlist(jsonData, showAnnounce)
    if not self._layer then
        return nil
    end
    self._layer:RespModSrvlist(jsonData, showAnnounce)
end

function ModuleChooseManager:OnDownloadResCB(isOK, filename, downloadFlag)
    if not self._layer then
        return nil
    end

    self._layer:OnDownloadResCB(isOK, filename, downloadFlag)
end

function ModuleChooseManager:LaunchModule()
    if not self._layer then
        return nil
    end
    self._layer:LaunchModule()
end

function ModuleChooseManager:OnLastSelectServerResp()
    if not self._layer then
        return nil
    end
    self._layer:OnLastSelectServerResp()
end

function ModuleChooseManager:WriteEnvAndRestart(envStr)
    if not self._layer then
        return nil
    end
    self._layer:WriteEnvAndRestart(envStr)
end


function ModuleChooseManager:UpdateSubModuleName(juheData)
    if not self._layer then
        return nil
    end
    self._layer:UpdateSubModuleName(juheData)
end
return ModuleChooseManager
