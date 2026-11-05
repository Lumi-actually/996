local GameSizeChangedCommand = class('GameSizeChangedCommand', framework.SimpleCommand)

function GameSizeChangedCommand:ctor()
end

function GameSizeChangedCommand:execute(note)
    --debug
    print("OnGameSizeChanged")

    -- for 减少获取游戏屏幕尺寸的次数
    G_GameScreenSize = nil
end

return GameSizeChangedCommand