local DebugProxy        = requireProxy("DebugProxy")
local SceneOptionsProxy = class("SceneOptionsProxy", DebugProxy)
SceneOptionsProxy.NAME  = global.ProxyTable.SceneOptionsProxy
local tonumber          = tonumber

function SceneOptionsProxy:ctor()
    self._temporaryFeature = {}

    SceneOptionsProxy.super.ctor(self)
end

function SceneOptionsProxy:LoadConfig()
    local temp = SL:GetValue("GAME_DATA","HumanPaperback") or SL:GetValue("GAME_DATA","unkown_model")
    if temp then
        local slices = G_GetSplitArray(temp, "|")
        for i, slice in ipairs(slices) do
            local feature = {}
            local slices2 = G_GetSplitArray(slice, "#")
            feature.clothID     = tonumber(slices2[1])
            feature.weaponID    = tonumber(slices2[2])
            feature.shieldID    = 9999
            feature.wingsID     = 9999
            feature.hairID      = 9999
            feature.weaponEffID = 9999
            feature.shieldEffID = 9999
            feature.leftWeaponID  = 9999
            feature.leftWeaponEff = 9999
            self._temporaryFeature[i] = feature
        end
    end
end

function SceneOptionsProxy:GetTempFeatureByJob(job)
    if job >= GUIDefine.Job.FIGHTER and job <= GUIDefine.Job.TAOIST then
        return self._temporaryFeature[job + 1]
    end
    return self._temporaryFeature[job]
end

function SceneOptionsProxy:onRegister()
    SceneOptionsProxy.super.onRegister(self)
end


return SceneOptionsProxy
