local DebugProxy        = requireProxy( "DebugProxy" )
local ColorStyleProxy   = class( "ColorStyleProxy", DebugProxy )
ColorStyleProxy.NAME    = global.ProxyTable.ColorStyleProxy

local tnum   = tonumber

local COLOR_CONFIG = requireConfig("ZTColor")

function ColorStyleProxy:ctor()
    ColorStyleProxy.super.ctor( self )

    self._oriConfig = COLOR_CONFIG
	self._config = COLOR_CONFIG
    self._styleConfig = {}
end

function ColorStyleProxy:onRegister()
    ColorStyleProxy.super.onRegister( self )
end

function ColorStyleProxy:LoadConfig()
	local config = {}
    if SL:IsFileExist("scripts/game_config/cfg_extra_color.lua") then
		config = SL:RequireFile("game_config/cfg_extra_color")
	end
	for id, data in pairs(config) do
		if id > 255 then
			self._config[id] = data
		end
	end
end

function ColorStyleProxy:GetOriConfig()
    return self._oriConfig
end

function ColorStyleProxy:GetConfig()
    return self._config
end

function ColorStyleProxy:GetStyleById(id)
    local config = self._config[id]
	if config and global.isWinPlayMode then
		config.size = global.ConstantConfig.DEFAULT_FONT_SIZE
	end
    return config
end

function ColorStyleProxy:GetTTFConfigById(id)
    local config = self._styleConfig[id]
    if config then
        return config
    end

    local style = self:GetStyleById(id)
    if not style then
        return nil
    end

    config = {
        outlineSize     = style.style or 1,
        outlineColor    = ConvertHexStrToColor3B(style.style_color or "#000000"),
        fontSize        = style.size or 12,
        underline       = style.underline == 1,
        color           = ConvertHexStrToColor3B(style.colour or "#FFFFFF")
    }
    self._styleConfig[id] = config
    return config
end

function ColorStyleProxy:SetStyleById( sender, id )
    if (not sender) or (not id) then
        print( "error : ColorStyleProxy step 1: error sender or id" )
        return sender
    end

    local config = self:GetTTFConfigById(id)
    if (not config) then
        -- print( "error : ColorStyleProxy step 2, config is empty, id:  " .. id )
        return sender
    end

    local labelRenderer = nil
    if sender:getDescription() == "Label" then
        labelRenderer = sender:getVirtualRenderer()
        sender:setFontSize(config.fontSize)
    elseif sender:getDescription() == "Button" then
        labelRenderer = sender:getTitleRenderer()
        
        -- 设置按钮字体大小
        sender:setTitleFontSize( config.fontSize )
        
    end
    
    -- 填充
    if labelRenderer then
        labelRenderer:setTextColor( config.color )

        if global.isWinPlayMode then 
        else
            -- 描边颜色和大小
            labelRenderer:enableOutline(config.outlineColor, config.outlineSize)
            -- 字体大小
            local lastTTFConfig         = labelRenderer:getTTFConfig()
            lastTTFConfig.fontSize      = config.fontSize
            labelRenderer:setTTFConfig( lastTTFConfig )
        end
        

        -- 下划线
        if labelRenderer.underline and ( not tolua.isnull( labelRenderer.underline ) ) then
            labelRenderer.underline:removeFromParent()
            labelRenderer.underline = nil
        end
        if config.underline then
            local underline = UnderLineComponent:create()
            underline:attachToNode( labelRenderer, labelRenderer:getTextColor() )
            labelRenderer.underline = underline
        end
    else
        print( "error : ColorStyleProxy step 3: error renderer" )
    end

    return sender
end

function GET_COLOR_CONFIG( id )
    local proxy = global.Facade:retrieveProxy( global.ProxyTable.ColorStyleProxy )
    return proxy:GetStyleById( id )
end

function GET_COLOR_TTFCONFIG( id )
    local proxy = global.Facade:retrieveProxy( global.ProxyTable.ColorStyleProxy )
    return proxy:GetTTFConfigById( id )
end

function GET_COLOR_BYID( id )
    local proxy = global.Facade:retrieveProxy( global.ProxyTable.ColorStyleProxy )
    local config = proxy:GetStyleById( id )
    if config then
        return config.colour
    end
    
    return "#ffffff"
end

function GET_COLOR_BYID_C3B( id )
    return ConvertHexStrToColor3B( GET_COLOR_BYID(id) )
end

function GET_SIZE_BYID( id )
    local proxy = global.Facade:retrieveProxy( global.ProxyTable.ColorStyleProxy )
    local config = proxy:GetStyleById( id )
    if config then
        return config.size
    end
    
    return 16
end

-- 设置颜色 param sender
function SET_COLOR_STYLE( sender, id )
    id = tonumber(id)
    local proxy = global.Facade:retrieveProxy( global.ProxyTable.ColorStyleProxy )
    return proxy:SetStyleById( sender, id )
end

return ColorStyleProxy