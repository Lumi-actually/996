

local BehaviorConfig = 
{
    BTSTATUS_Invalid    = 0,    -- 初始状态
    BTSTATUS_Running    = 1,    -- 运行
    BTSTATUS_Success    = 2,    -- 成功
    BTSTATUS_Failure    = 3,    -- 失败
    BTSTATUS_Aborted    = 4,    -- 终止
}

BehaviorConfig.BehaviorType = 
{
    BehaviorBase        = 0,    -- 基础
    BehaviorKLaunch     = 1,    -- 服务器触发的施法
    BehaviorTurn        = 2,    -- 转向
    BehaviorMove        = 3,    -- 移动
    BehaviorDig         = 4,    -- 挖掘
    BehaviorCorpse      = 5,    -- 挖尸体
    BehaviorMining      = 6,    -- 挖矿
    BehaviorLaunch      = 7,    -- 施法
}

return BehaviorConfig
