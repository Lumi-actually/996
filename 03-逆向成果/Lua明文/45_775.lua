-- avoid memory leak
collectgarbage("setpause", 100)
collectgarbage("setstepmul", 200)

-- 处理环境变量有搜索路径的问题
if global.isWindows then
    package.path = string.split(package.path, ";")[1] .. ";./?.lua;"
end

-- init cocos2d-x
require("cocos/init")

-- init global
require("init/initGlobal")

-- init util
require("init/initUtil")

-- init network
require("init/initNetwork")

-- init gui
require("GUI/init")

-- init framework
require("init/initFramework")

G_ActorUtils = require("util/actorUtils")

-- startup game
local StartUpCommand = requireCommand("gamestates/StartUpCommand")
global.Facade:registerCommand(global.NoticeTable.StartUp, StartUpCommand)
global.Facade:sendNotification(global.NoticeTable.StartUp)
