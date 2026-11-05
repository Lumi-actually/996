local sequFrameAnimLoader = require( "animation/sequFrameAnimLoader" )
local sequFrameAnimLoaderImpShield = class('sequFrameAnimLoaderImpShield', sequFrameAnimLoader)

local ANIM_RES_PATH = "anim/shield/"

function sequFrameAnimLoaderImpShield:ctor()
    sequFrameAnimLoaderImpShield.super.ctor(self)
end

function sequFrameAnimLoaderImpShield:init()
    sequFrameAnimLoaderImpShield.super.init(self)
end

function sequFrameAnimLoaderImpShield:convertTexFileName( rawAnimID, sex, act )  
    return string.format( "%sshield_%04d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpShield:convertPlistFileName( rawAnimID, sex, act )  
    return string.format( "%sshield_%04d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpShield:convertTexFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%sshield_%04d_%d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpShield:convertPlistFileNameByIdx( rawAnimID, sex, act, idx ) 
    return string.format( "%sshield_%04d_%d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpShield:convertFrameName( rawAnimID, sex, act, dir, frameID )
    return string.format( "shield_%04d_%d_%d_%d_%04d.png", rawAnimID, sex, act, dir, frameID )
end


return sequFrameAnimLoaderImpShield
