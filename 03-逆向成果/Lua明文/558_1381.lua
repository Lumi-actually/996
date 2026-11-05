local sequFrameAnimLoader = require( "animation/sequFrameAnimLoader" )
local sequFrameAnimLoaderImpNpc = class('sequFrameAnimLoaderImpNpc', sequFrameAnimLoader)

local ANIM_RES_PATH               ="anim/npc/"

function sequFrameAnimLoaderImpNpc:ctor()
    sequFrameAnimLoaderImpNpc.super.ctor(self)
end

function sequFrameAnimLoaderImpNpc:init()
    sequFrameAnimLoaderImpNpc.super.init(self)
end

function sequFrameAnimLoaderImpNpc:convertTexFileName( rawAnimID, sex, act )  
    return string.format( "%snpc_%04d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpNpc:convertPlistFileName( rawAnimID, sex, act )  
    return string.format( "%snpc_%04d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpNpc:convertTexFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%snpc_%04d_%d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpNpc:convertPlistFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%snpc_%04d_%d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpNpc:convertFrameName( rawAnimID, sex, act, dir, frameID )
    return string.format( "npc_%04d_%d_%d_%d_%04d.png", rawAnimID, sex, act, dir, frameID )
end

return sequFrameAnimLoaderImpNpc

