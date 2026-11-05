local sequFrameAnimLoader = require( "animation/sequFrameAnimLoader" )
local sequFrameAnimLoaderImpMonster = class('sequFrameAnimLoaderImpMonster', sequFrameAnimLoader)

local ANIM_RES_PATH = "anim/monster/"

function sequFrameAnimLoaderImpMonster:ctor()
    sequFrameAnimLoaderImpMonster.super.ctor(self)
end


function sequFrameAnimLoaderImpMonster:init()
    sequFrameAnimLoaderImpMonster.super.init(self)
end

function sequFrameAnimLoaderImpMonster:convertTexFileName( rawAnimID, sex, act )  
    return string.format( "%smonster_%04d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpMonster:convertPlistFileName( rawAnimID, sex, act )  
    return string.format( "%smonster_%04d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpMonster:convertTexFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%smonster_%04d_%d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpMonster:convertPlistFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%smonster_%04d_%d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpMonster:convertFrameName( rawAnimID, sex, act, dir, frameID )
    return string.format( "monster_%04d_%d_%d_%d_%04d.png", rawAnimID, sex, act, dir, frameID )
end

return sequFrameAnimLoaderImpMonster
