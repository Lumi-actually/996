local sequFrameAnimLoader = require( "animation/sequFrameAnimLoader" )
local sequFrameAnimLoaderImpPlayer = class('sequFrameAnimLoaderImpPlayer', sequFrameAnimLoader)

local ANIM_RES_PATH = "anim/player/"

function sequFrameAnimLoaderImpPlayer:ctor()
    sequFrameAnimLoaderImpPlayer.super.ctor(self)
end



function sequFrameAnimLoaderImpPlayer:init()
    sequFrameAnimLoaderImpPlayer.super.init(self)
end


function sequFrameAnimLoaderImpPlayer:convertTexFileName( rawAnimID, sex, act )  
    return string.format( "%splayer_%04d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpPlayer:convertPlistFileName( rawAnimID, sex, act ) 
    return string.format( "%splayer_%04d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act )
end

function sequFrameAnimLoaderImpPlayer:convertTexFileNameByIdx( rawAnimID, sex, act, idx )  
    return string.format( "%splayer_%04d_%d_%d_%d.png", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpPlayer:convertPlistFileNameByIdx( rawAnimID, sex, act, idx ) 
    return string.format( "%splayer_%04d_%d_%d_%d.plist", ANIM_RES_PATH, rawAnimID, sex, act, idx )
end

function sequFrameAnimLoaderImpPlayer:convertFrameName( rawAnimID, sex, act, dir, frameID )
    return string.format( "player_%04d_%d_%d_%d_%04d.png", rawAnimID, sex, act, dir, frameID )
end

return sequFrameAnimLoaderImpPlayer
