local sequFrameAnimLoader = require( "animation/sequFrameAnimLoader" )
local sequFrameAnimLoaderImpHair = class('sequFrameAnimLoaderImpWeapon', sequFrameAnimLoader)

local ANIM_RES_PATH = "anim/hair/"

function sequFrameAnimLoaderImpHair:ctor()
    sequFrameAnimLoaderImpHair.super.ctor(self)
end

function sequFrameAnimLoaderImpHair:init()  
    sequFrameAnimLoaderImpHair.super.init(self)
end

function sequFrameAnimLoaderImpHair:convertTexFileName( rawAnimID, sex, act )  
    return string.format( "%shair_%04d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpHair:convertPlistFileName( rawAnimID, sex, act )  
    return string.format( "%shair_%04d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpHair:convertTexFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%shair_%04d_%d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpHair:convertPlistFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%shair_%04d_%d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpHair:convertFrameName( rawAnimID, sex, act, dir, frameID )
    return string.format( "hair_%04d_%d_%d_%d_%04d.png", rawAnimID, sex, act, dir, frameID )
end


return sequFrameAnimLoaderImpHair
