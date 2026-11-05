local sequFrameAnimLoader = require( "animation/sequFrameAnimLoader" )
local sequFrameAnimLoaderImpWeapon = class('sequFrameAnimLoaderImpWeapon', sequFrameAnimLoader)

local ANIM_RES_PATH = "anim/weapon/"

function sequFrameAnimLoaderImpWeapon:ctor()
    sequFrameAnimLoaderImpWeapon.super.ctor(self)
end

function sequFrameAnimLoaderImpWeapon:init()  
    sequFrameAnimLoaderImpWeapon.super.init(self)
end

function sequFrameAnimLoaderImpWeapon:convertTexFileName( rawAnimID, sex, act )  
    return string.format( "%sweapon_%04d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpWeapon:convertPlistFileName( rawAnimID, sex, act )  
    return string.format( "%sweapon_%04d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpWeapon:convertTexFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%sweapon_%04d_%d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpWeapon:convertPlistFileNameByIdx( rawAnimID, sex, act, idx ) 
    return string.format( "%sweapon_%04d_%d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpWeapon:convertFrameName( rawAnimID, sex, act, dir, frameID )
    return string.format( "weapon_%04d_%d_%d_%d_%04d.png", rawAnimID, sex, act, dir, frameID )
end


return sequFrameAnimLoaderImpWeapon
