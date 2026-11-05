local mGlobal       = global
local facade        = mGlobal.Facade
local noticeTable   = mGlobal.NoticeTable

local registerTable = 
{
    -- 角色属性初始化
    [noticeTable.PlayerPropertyInited]          = "gamestates/PlayerPropertyInitedCommand",


    -- 断线重连相关
    [noticeTable.Reconnect]                     = "gamestates/ReconnectCommand",


    -- 返回选角
    [noticeTable.LeaveWorld]                    = "gamestates/LeaveWorldCommand",

    -- 释放内存
    [noticeTable.ReleaseMemory]                 = "gamestates/ReleaseMemoryCommand",


    -- 注销world相关
    [noticeTable.UnRegisterWorldController]     = "register/UnRegisterWorldControllerCommand",
    [noticeTable.UnRegisterWorldMediator]       = "register/UnRegisterWorldMediatorCommand",
    [noticeTable.UnRegisterWorldProxy]          = "register/UnRegisterWorldProxyCommand",


    -- 道具相关
    [noticeTable.ItemUpdate]                    = "item/ItemUpdateCommand",
    [noticeTable.TakeOnRequest]                 = "item/TakeOnEquipCommand",
    [noticeTable.TakeOffRequest]                = "item/TakeOffEquipCommand",
    [noticeTable.IntoDropItem]                  = "item/IntoDropItemCommand",
    [noticeTable.IntoDropItem_Hero]             = "item/HeroIntoDropItemCommand",

    --hero
    [noticeTable.HeroTakeOnRequest]                 = "item/HeroTakeOnEquipCommand",
    [noticeTable.HeroTakeOffRequest]                = "item/HeroTakeOffEquipCommand",

    [noticeTable.HeroTakeOffRequestToHumBag]        = "item/HeroTakeOffEquipToHumBagCommand",
    [noticeTable.TakeOnRequestFromHeroBag]          = "item/TakeOnEquipFromHeroBagCommand",
    [noticeTable.TakeOffToHeroBagRequest]          = "item/TakeOffEquipToHeroBagRequestCommand",
    [noticeTable.HeroTakeOnRequestFromHumBag]         = "item/HeroTakeOnEquipFromHumBagCommand",
    

    -- auto
    [noticeTable.AutoFightBegin]                = "auto/AutoFightBeginCommand",
    [noticeTable.AutoFightEnd]                  = "auto/AutoFightEndCommand",
    [noticeTable.AutoMoveBegin]                 = "auto/AutoMoveBeginCommand",
    [noticeTable.AutoMoveEnd]                   = "auto/AutoMoveEndCommand",
    [noticeTable.AutoFindNPC]                   = "auto/AutoFindNPCCommand",
    [noticeTable.AutoFindCollection]            = "auto/AutoFindCollectionCommand",
    [noticeTable.AutoFindDropItem]              = "auto/AutoFindDropItemCommand",
    [noticeTable.AutoPickupBySprite]            = "auto/AutoPickupBySpriteCommand",
    -- actor states
    [noticeTable.ActorEnterIdleAction]          = "actorstates/ActorEnterIdleCommand",
    [noticeTable.ActorEnterWalkAction]          = "actorstates/ActorEnterWalkCommand",
    [noticeTable.ActorEnterRunAction]           = "actorstates/ActorEnterRunCommand",
    [noticeTable.ActorEnterAttackAction]        = "actorstates/ActorEnterAttackCommand",
    [noticeTable.ActorEnterSkillAction]         = "actorstates/ActorEnterSkillCommand",
    
    
    -- input
    [noticeTable.InputIdle]                     = "input/InputIdleCommand",
    [noticeTable.InputLaunch]                   = "input/InputLaunchCommand",
    [noticeTable.InputMove]                     = "input/InputMoveCommand",
    [noticeTable.InputCorpse]                   = "input/InputCorpseCommand",
    [noticeTable.InputMining]                   = "input/InputMiningCommand",
    [noticeTable.PickerChange]                  = "input/PickerChangeCommand",
    
    -- skill
    [noticeTable.RequestSkillPresent]           = "skill/SkillPresentCommand",
    
    -- actor
    [noticeTable.ActorPlayerDie]                = "other/ActorDieCommand",
    [noticeTable.ActorMonsterDie]               = "other/ActorDieCommand",
    [noticeTable.ActorOutOfView]                = "other/ActorOutOfViewCommand",
    [noticeTable.ActorInOfView]                 = "other/ActorInOfViewCommand",
    [noticeTable.DropItemOutOfView]             = "other/DropItemOutOfViewCommand",
    [noticeTable.DropItemInOfView]              = "other/DropItemInOfViewCommand",
    [noticeTable.RefreshDropItem]               = "other/RefreshDropItemCommand",
    [noticeTable.ActorRevive]                   = "other/ActorReviveCommand",
    [noticeTable.ActorMonsterCave]              = "other/MonsterCaveCommand",
    [noticeTable.GamePickSettingChange]         = "other/RefreshDropItemDisplayCommand",
    [noticeTable.ActorFeatureChange]            = "actor/ChangePlayerFeatureCommand",
    [noticeTable.SetPlayerFeature]              = "actor/SetPlayerFeatureCommand",
    [noticeTable.SetPlayerFeatureEX]            = "actor/SetPlayerFeatureEXCommand",
    [noticeTable.ActorSay]                      = "other/ActorSayCommand",
    [noticeTable.RefreshActorBooth]             = "other/RefreshActorBoothCommand",
    [noticeTable.RefreshActorSafeZone]          = "other/RefreshActorSafeZoneCommand",
    [noticeTable.RefreshActorShaBaKeZone]       = "other/RefreshActorShaBaKeZoneCommand",
    [noticeTable.RefreshActorNameColor]         = "other/RefreshActorNameColorCommand",
    [noticeTable.RefreshGuildActorColor]        = "other/RefreshGuildActorColorCommand",

    --实名认证
    [noticeTable.RealNameInfo]                  = "other/RealNameCommand",

    -- scene
    [noticeTable.ChangeScene]                   = "scene/ChangeSceneCommand",
    [noticeTable.ShakeScene]                    = "other/ShakeSceneCommand",
    
    -- HUD
    [noticeTable.RefreshHUDLabel]               = "other/RefreshActorHUDLabelCommand",
    [noticeTable.RefreshHUDTitle]               = "other/RefreshActorHUDTitleCommand",
    [noticeTable.RefreshHUDHP]                  = "other/RefreshActorHUDHPLabelCommand",
    [noticeTable.RefreshActorHP]                = "other/RefreshActorHPCommand",
    
    -- shader
    [noticeTable.GradientNodeShader]            = "shader/GradientShaderCommand",

    -- pay product
    [noticeTable.PayProductRequest]             = "other/CallFCommand",

    [noticeTable.GameSettingInited]             = "other/SettingInitedCommand",
    [noticeTable.GameSettingChange]             = "other/SettingChangeCommand",

    [noticeTable.CloudStorageInit]              = "other/CloudStorageInitCommand",

    [noticeTable.ResolutionSizeChange]           = "other/ResolutionSizeChangeCommand",
    [noticeTable.TradingBank_other_Capture]      = "other/TradingBankCaptureOtherCommand",
    
    -- 刘海屏改变
    [noticeTable.DeviceRotationChanged]         = "other/DeviceRotationChangedCommand",
}

local table_mobile = 
{
    [noticeTable.RequestLaunchSkill]            = "skill/RequestLaunchCommand",
}
local table_pc = 
{
    [noticeTable.RequestLaunchSkill]            = "skill/RequestLaunchCommand-win32",
}
local t = (global.isWinPlayMode and table_pc or table_mobile)
for k, v in pairs(t) do
    registerTable[k] = v
end

return registerTable