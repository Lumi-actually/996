local ChangeResolutionCommand = class('ChangeResolutionCommand', framework.SimpleCommand)

function ChangeResolutionCommand:ctor()
    self.director     = global.Director
    self.glView       = self.director:getOpenGLView();
end

function ChangeResolutionCommand:execute(notification)
    local data = notification:getBody()
    -- debug
    -- print( "ChangeResolutionCommand,Size:" .. data.size.width .. "," .. data.size.height .. ",Type:" .. data.rType )
    local width = data.size.width
    local height = data.size.height
    if global.isWinPlayMode and (width > global.MMO.RESOLUTION_WIDTH or height > global.MMO.RESOLUTION_HEIGHT) then
        width = global.MMO.RESOLUTION_WIDTH
        height = global.MMO.RESOLUTION_HEIGHT
    end
    self.glView:setDesignResolutionSize( width, height, data.rType );
    G_GameScreenSize = nil
end


return ChangeResolutionCommand
