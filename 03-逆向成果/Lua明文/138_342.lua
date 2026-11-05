local ShutdownGameCommand = class('ShutdownGameCommand', framework.SimpleCommand)

function ShutdownGameCommand:ctor()
end

function ShutdownGameCommand:execute(note)
    --debug
    release_print( "ShutdownGameCommand" )

    if global.isWindows then
        global.Director:endToLua()
    end
end

return ShutdownGameCommand
