release_print( [[

*********************************************
Hello, World, This is Lua. By Launcher
*********************************************
]])

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
  local msgStr = tostring( msg )
  local trace  = debug.traceback()

  release_print("----------------------------------------")
  release_print("LUA ERROR: " .. msgStr .. "\n")
  release_print(trace)
  release_print("----------------------------------------")

  -- bugly report
  if cc.PLATFORM_OS_ANDROID == global.Platform then
    buglyAddUserValue( "LastMVCNotice", tostring( g_lastMVCNotice ) ) 

    if global.BuglyLogs then
      for index, value in pairs( global.BuglyLogs ) do
        buglyLog( 1, tostring( index ), tostring( value ) ) 
      end
    end
    
    buglyReportLuaException( msgStr, trace, false )
  else
    release_print( "LastMVCNotice:" .. tostring( g_lastMVCNotice ) ) 

    if global.BuglyLogs then
      for index, value in pairs( global.BuglyLogs ) do
        release_print( tostring( index ) .. ":" .. tostring( value ) ) 
      end
    end

  end
end

local function loadFilenameLookups()
  local filename = "helloWorld.txt"
  local fileUtil = cc.FileUtils:getInstance()
  if not fileUtil:isFileExist(filename) then
    return nil
  end
  fileUtil:loadFilenameLookup(filename)
end

function requireLauncher(path)
  return require( path .. "_launcher" )
end

local function Init()
  requireLauncher( "init/init" )
end

local function main()
  loadFilenameLookups()
  Init()
end

xpcall(main, __G__TRACKBACK__)
