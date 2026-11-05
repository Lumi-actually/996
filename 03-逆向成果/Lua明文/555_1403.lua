local sequFrameAnimLoader = require( "animation/sequFrameAnimLoader" )
local sequFrameAnimLoaderImpWings = class('sequFrameAnimLoaderImpWings', sequFrameAnimLoader)

local ANIM_RES_PATH = "anim/wings/"

function sequFrameAnimLoaderImpWings:ctor()
    sequFrameAnimLoaderImpWings.super.ctor(self)
end

function sequFrameAnimLoaderImpWings:init()
    sequFrameAnimLoaderImpWings.super.init(self)
end

function sequFrameAnimLoaderImpWings:convertTexFileName( rawAnimID, sex, act )  
    return string.format( "%swings_%04d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpWings:convertPlistFileName( rawAnimID, sex, act )  
    return string.format( "%swings_%04d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpWings:convertTexFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%swings_%04d_%d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpWings:convertPlistFileNameByIdx( rawAnimID, sex, act, idx ) 
    return string.format( "%swings_%04d_%d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpWings:convertFrameName( rawAnimID, sex, act, dir, frameID )
    return string.format( "wings_%04d_%d_%d_%d_%04d.png", rawAnimID, sex, act, dir, frameID )
end


return sequFrameAnimLoaderImpWings
