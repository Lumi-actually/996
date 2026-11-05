-- 一些全局共享LuaTable，节省多余的NewLuaTable

local M =
{
    AudioPlayTable = {},     -- Audio_Play 共享
    AudioPlayTable1 = {},    -- Audio_Play 共享
    AudioPlayTable2 = {},    -- Audio_Play 共享
    AudioPlayTable3 = {},    -- Audio_Play 共享
    AudioPlayTable4 = {},    -- Audio_Play 共享
}

return M