
local actorUtils = {}

local optionsUtils = requireUtil("optionsUtils")

local nameBuffIndex = 0
local sexBuffIndex = nameBuffIndex + 201
local jobBuffIndex = sexBuffIndex + 1 
local masterIDBuffIndex = jobBuffIndex + 1 
local pkcampIDBuffIndex = masterIDBuffIndex + 8
local flagStateBuffIndex = pkcampIDBuffIndex + 8 
local raceServerBuffIndex = flagStateBuffIndex + 8 
local rangeCanFindMeBuffIndex = raceServerBuffIndex + 2
local colorBuffIndex = rangeCanFindMeBuffIndex + 1 
local titleBuffIndex = colorBuffIndex + 1 
local ownerIDBuffIndex = titleBuffIndex + 4 
local ownerNameBuffIndex = ownerIDBuffIndex + 8 
local throughBuffIndex = ownerNameBuffIndex + 51 
local actionTypeBuffIndex = throughBuffIndex + 4
local warZoneBuffIndex = actionTypeBuffIndex + 1 
local gmDataBuffIndex = warZoneBuffIndex + 1 
local meBuffIndex = gmDataBuffIndex + 40
local nationIDBuffIndex = meBuffIndex + 4
local nationEnemyPKBuffIndex = nationIDBuffIndex + 1
------------------------------------------
local appearCountBuffIndex = nationEnemyPKBuffIndex + 1
local spAbiCountBuffIndex = appearCountBuffIndex + 1
local abiCountBuffIndex = spAbiCountBuffIndex + 2
local bExtInfoBuffIndex = abiCountBuffIndex + 2
-------------------------------------------
local buffKeys = {_appear = {},_spabil = {}, _curAbil = {}, _maxAbil = {}}
for i = 0, 19 do
    buffKeys._appear[i] = "_appear" .. i
end
for i = 0, 255 do
    buffKeys._spabil[i] = "_spabil" .. i
end
for i = 0, 399 do
    buffKeys._curAbil[i] = "_curAbil" .. i
    buffKeys._maxAbil[i] = "_maxAbil" .. i
end
local netBuffKey = "netType_%s_%s"
local appearArrBuffIndex = bExtInfoBuffIndex + 1
local GetAppearOffset = function (buffer)
    if not buffer._appearCount then 
        buffer:SetLuaIndex(appearCountBuffIndex) 
        buffer._appearCount = buffer:ReadUByte()
        buffer:SetLuaIndex(appearArrBuffIndex)
        local id,value
        for i = 1, buffer._appearCount do
            id = buffer:ReadUByte()
            value = buffer:ReadInt()
            buffer[buffKeys._appear[id]] = value
        end
    end 
    if not buffer._appearOffset then 
        buffer._appearOffset = appearArrBuffIndex + buffer._appearCount * 5
    end
    return buffer._appearOffset
end
-------------------------------------------------------------------
local GetSpAbilOffset = function (buffer)
    local appearOffset = GetAppearOffset(buffer)
    local spAbilArrBuffIndex = appearOffset
    if not buffer._spAbiCount then 
        buffer:SetLuaIndex(spAbiCountBuffIndex) 
        buffer._spAbiCount = buffer:ReadUShort()
        buffer:SetLuaIndex(spAbilArrBuffIndex)
        local id
        for i = 1, buffer._spAbiCount do
            id = buffer:ReadUByte()
            buffer[buffKeys._spabil[id]] = true
        end
    end 
    if not buffer._spAbilOffset then 
        buffer._spAbilOffset = spAbilArrBuffIndex + buffer._spAbiCount
    end
    return buffer._spAbilOffset

end 

local GetAbilOffset = function (buffer)
    local spAbilOffsetBuffIndex = GetSpAbilOffset(buffer)
    local abiBuffIndex = spAbilOffsetBuffIndex
    if not buffer._abiCount then 
        buffer:SetLuaIndex(abiCountBuffIndex) 
        buffer._abiCount = buffer:ReadUShort()
        buffer:SetLuaIndex(abiBuffIndex)
        local id,curValue,maxValue
        for i = 1, buffer._abiCount do
            id = buffer:ReadUShort()
            curValue = buffer:ReadInt64()
            maxValue = buffer:ReadInt64()
            buffer[buffKeys._curAbil[id]] = curValue
            buffer[buffKeys._maxAbil[id]] = maxValue
        end
    end 
    if not buffer._abilOffset then 
        buffer._abilOffset = abiBuffIndex + buffer._abiCount * 18
    end
    return buffer._abilOffset
end

local GetHaveExtInfo = function (buffer)
    if buffer._haveExtInfo == nil then 
        buffer:SetLuaIndex(bExtInfoBuffIndex) 
        buffer._haveExtInfo = buffer:ReadBool()
    end
    return buffer._haveExtInfo
end
-----------------------------------------
local teamIDBuffIndex = 0
local guildIDBuffIndex = teamIDBuffIndex + 4 
local offlineBuffIndex = guildIDBuffIndex + 41 
local shenMiRenBuffIndex = offlineBuffIndex + 1 
local guildNameBuffIndex = shenMiRenBuffIndex + 1 
local rankBuffIndex = guildNameBuffIndex + 31 
local rankNameBuffIndex = rankBuffIndex + 4 
local castleNameBuffIndex = rankNameBuffIndex + 31
local pklvBuffIndex = castleNameBuffIndex + 11 
local stallNameBuffIndex = pklvBuffIndex + 4 
local candleBuffIndex = stallNameBuffIndex + 51
local doubleTagBuffIndex = candleBuffIndex + 1
local doubleUserIDBuffIndex = doubleTagBuffIndex + 1
local nserverIDBuffIndex = doubleUserIDBuffIndex + 8 
local joinNetCountBuffIndex = nserverIDBuffIndex + 4
local joinNetDataBuffIndex = joinNetCountBuffIndex + 1
local GetNetOffset = function (buffer)
    if not buffer._netCount then
        buffer._netCount = actorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_JOINNETCOUNT) or 0
        if buffer._netCount > 0 then
            local abilOffset = GetAbilOffset(buffer)
            buffer:SetLuaIndex(abilOffset + joinNetDataBuffIndex)
            for i = 1, buffer._netCount do
                local type = buffer:ReadUByte()             -- 关系网类型id
                local netID1 = buffer:ReadShortString(38)
                local netID2 = buffer:ReadShortString(38)
                buffer[string.format(netBuffKey, type, 1)] = string.len(netID1) > 0 and netID1 or nil
                buffer[string.format(netBuffKey, type, 2)] = string.len(netID2) > 0 and netID2 or nil
            end
        end
    end
    if not buffer._netOffset then 
        buffer._netOffset = joinNetDataBuffIndex + buffer._netCount * (1 + 39 + 39)
    end
    return buffer._netOffset
end

local BufferProperty = 
{
    [global.MMO.ACTOR_BUFFER_NAME] = function(buffer)
        buffer:SetLuaIndex(nameBuffIndex)
        return SL:GBKToUTF8(buffer:ReadShortString(200))
    end,
    [global.MMO.ACTOR_BUFFER_SEX] = function(buffer)
        buffer:SetLuaIndex(sexBuffIndex)
        return buffer:ReadByte()
    end,
    [global.MMO.ACTOR_BUFFER_JOB] = function(buffer)
        buffer:SetLuaIndex(jobBuffIndex)
        return buffer:ReadByte()
    end,
    [global.MMO.ACTOR_BUFFER_MASTERID] = function(buffer)
        buffer:SetLuaIndex(masterIDBuffIndex)
        return buffer:ReadInt64Str()
    end,
    [global.MMO.ACTOR_BUFFER_PKCAMPID] = function(buffer)
        buffer:SetLuaIndex(pkcampIDBuffIndex)
        return buffer:ReadInt64()
    end,
    [global.MMO.ACTOR_BUFFER_FLAGSTATE] = function(buffer)
        buffer:SetLuaIndex(flagStateBuffIndex)
        return buffer:ReadInt64()
    end,
    [global.MMO.ACTOR_BUFFER_RACESERVER] = function(buffer)
        buffer:SetLuaIndex(raceServerBuffIndex)
        return buffer:ReadShort()
    end,
    [global.MMO.ACTOR_BUFFER_RANGECANFINDME] = function(buffer)
        buffer:SetLuaIndex(rangeCanFindMeBuffIndex)
        return buffer:ReadByte()
    end,
    [global.MMO.ACTOR_BUFFER_COLOR] = function(buffer)
        buffer:SetLuaIndex(colorBuffIndex)
        return buffer:ReadUByte()
    end,
    [global.MMO.ACTOR_BUFFER_TITLE] = function(buffer)
        buffer:SetLuaIndex(titleBuffIndex)
        return buffer:ReadInt()
    end,
    [global.MMO.ACTOR_BUFFER_OWNERID] = function(buffer)
        buffer:SetLuaIndex(ownerIDBuffIndex)
        return buffer:ReadInt64Str()
    end,
    [global.MMO.ACTOR_BUFFER_OWNERNAME] = function(buffer)
        buffer:SetLuaIndex(ownerNameBuffIndex)
        return SL:GBKToUTF8(buffer:ReadShortString(50))
    end,
    [global.MMO.ACTOR_BUFFER_THROUGH] = function(buffer)
        buffer:SetLuaIndex(throughBuffIndex)
        return buffer:ReadInt()
    end,
    [global.MMO.ACTOR_BUFFER_ACTIONTYPE] = function(buffer)
        buffer:SetLuaIndex(actionTypeBuffIndex)
        return buffer:ReadByte()
    end,
    [global.MMO.ACTOR_BUFFER_WARZONE] = function(buffer)
        buffer:SetLuaIndex(warZoneBuffIndex)
        return buffer:ReadByte()
    end,
    [global.MMO.ACTOR_BUFFER_GMDATA] = function(buffer, idx)
        buffer:SetLuaIndex(gmDataBuffIndex + (idx - 1) * 8)
        return buffer:ReadInt64()
    end,
    [global.MMO.ACTOR_BUFFER_ME] = function(buffer)
        buffer:SetLuaIndex(meBuffIndex)
        return buffer:ReadInt()
    end,
    [global.MMO.ACTOR_BUFFER_NATIONID] = function(buffer)
        buffer:SetLuaIndex(nationIDBuffIndex)
        return buffer:ReadByte()
    end,
    [global.MMO.ACTOR_BUFFER_NATIONENEMYPK] = function(buffer)
        buffer:SetLuaIndex(nationEnemyPKBuffIndex)
        return buffer:ReadBool()
    end,
---------------------
    [global.MMO.ACTOR_BUFFER_ARRAPPEAR] = function(buffer, idx)
        GetAppearOffset(buffer)
        return buffer[buffKeys._appear[idx]] or 0
    end,
    [global.MMO.ACTOR_BUFFER_ARRSPABIL] = function(buffer, idx)
        GetSpAbilOffset(buffer)
        if buffer[buffKeys._spabil[idx]] then 
            return true
        else
            return false
        end
    end,
    [global.MMO.ACTOR_BUFFER_ARRCURABIL] = function(buffer, idx)
        GetAbilOffset(buffer)
        return buffer[buffKeys._curAbil[idx]] or 0
    end,
    [global.MMO.ACTOR_BUFFER_ARRMAXABIL] = function(buffer, idx)
        GetAbilOffset(buffer)
        return buffer[buffKeys._maxAbil[idx]] or 0
    end,

-------------------exinfo
    [global.MMO.ACTOR_BUFFER_TEAMID] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + teamIDBuffIndex)
            return buffer:ReadInt()
        end
        return 0
    end,
    [global.MMO.ACTOR_BUFFER_GUILDID] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + guildIDBuffIndex)
            return SL:GBKToUTF8(buffer:ReadShortString(40))
        end
        return ""
    end,

    [global.MMO.ACTOR_BUFFER_OFFLINE] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + offlineBuffIndex)
            return buffer:ReadBool()
        end
        return false
    end,
    [global.MMO.ACTOR_BUFFER_SHENMIREN] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + shenMiRenBuffIndex)
            return buffer:ReadBool()
        end
        return false
    end,
    [global.MMO.ACTOR_BUFFER_GUILDNAME] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + guildNameBuffIndex)
            return SL:GBKToUTF8(buffer:ReadShortString(30))
        end
        return ""
    end,
    [global.MMO.ACTOR_BUFFER_RANK] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + rankBuffIndex)
            return buffer:ReadInt()
        end
        return 0
    end,
    [global.MMO.ACTOR_BUFFER_RANKNAME] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + rankNameBuffIndex)
            return SL:GBKToUTF8(buffer:ReadShortString(30))
        end
        return ""
    end,
    [global.MMO.ACTOR_BUFFER_CASTLENAME] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + castleNameBuffIndex)
            return SL:GBKToUTF8(buffer:ReadShortString(10))
        end
        return ""
    end,
    [global.MMO.ACTOR_BUFFER_PKLV] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + pklvBuffIndex)
            return buffer:ReadInt()
        end
        return 0
    end,
    [global.MMO.ACTOR_BUFFER_STALLNAME] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + stallNameBuffIndex)
            return SL:GBKToUTF8(buffer:ReadShortString(50))
        end
        return ""
    end,
    [global.MMO.ACTOR_BUFFER_CANDLE] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + candleBuffIndex)
            return buffer:ReadByte()
        end
        return 0
    end, 
    [global.MMO.ACTOR_BUFFER_DOUBLETAG] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + doubleTagBuffIndex)
            return buffer:ReadByte()
        end
        return 0
    end,
    [global.MMO.ACTOR_BUFFER_DOUBLEUSERID] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + doubleUserIDBuffIndex)
            return buffer:ReadInt64Str()
        end
        return ""
    end,
    [global.MMO.ACTOR_BUFFER_NSERVERID] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + nserverIDBuffIndex)
            return buffer:ReadInt()
        end
        return 0
    end,
    [global.MMO.ACTOR_BUFFER_JOINNETCOUNT] = function(buffer)
        local abilOffset = GetAbilOffset(buffer)
        local haveExinfo = GetHaveExtInfo(buffer)
        if haveExinfo then 
            buffer:SetLuaIndex(abilOffset + joinNetCountBuffIndex)
            return buffer:ReadByte()
        end
        return 0
    end,

-------------------clientNet 
    [global.MMO.ACTOR_BUFFER_NETID] = function(buffer, type, idx)
        GetNetOffset(buffer)
        local netKey = type and idx and string.format(netBuffKey, type, idx) or ""
        return buffer[netKey]
    end,
    
}

function actorUtils.GetBufferPropertyByID(buffer, propertyID, idx, exParam)
    if not BufferProperty[propertyID] then
        print("ActorUtils.GetBufferPropertyByID ERROR", propertyID, idx, exParam)
        return nil
    end
    return BufferProperty[propertyID](buffer, idx, exParam)
end

function actorUtils.SetActorProperty(actor, jsonData)
    if jsonData.race and actor.SetRace then
        actor:SetRace(jsonData.race)
    end

    if jsonData.raceImg and actor.SetRaceImg then
        actor:SetRaceImg(jsonData.raceImg)
    end

    if jsonData.nActorId and actor.SetTypeIndex then
        actor:SetTypeIndex(jsonData.nActorId)
    end

    local mapX, mapY = jsonData.X, jsonData.Y
    if mapX and mapY and actor.SetInSafeZone then
        local MapProxy = global.Facade:retrieveProxy( global.ProxyTable.MapProxy )
        actor:SetInSafeZone( MapProxy:GetInSafeArea(mapX, mapY) )
    end

    if actor.SetHuShen and jsonData.MagicShield then
        --设置护身状态
        actor:SetHuShen(jsonData.MagicShield)
    end

    if actor.SetShenMiRen and type(jsonData.ShenMiRen) == "boolean" then
        -- 神秘人
        actor:SetShenMiRen(jsonData.ShenMiRen)
    end
    
    if actor.SetFaction then
        local faction = jsonData.faction
        local lastFaction = actor:GetFaction()
        actor:SetFaction(faction)
        
        CheckActorCampValue(actor, faction, lastFaction)
    end

    if actor.SetNationID then --国家id
        actor:SetNationID( jsonData.nationid )
    end

    if actor.SetNationEnemyPK and jsonData.nPlayerPk ~= nil then --国家模式是否可被攻击
        actor:SetNationEnemyPK( jsonData.nPlayerPk )
    end
    
    if jsonData.caved ~= nil and actor.SetSleepInCave then
        local hide = jsonData.caved == true
        actor:SetSleepInCave( hide )
        actor:SetKeyValue(global.MMO.Is_Cave, hide)
    end

    -- 跨服 区服ID
    if jsonData.nServerId and actor.SetServerID then
        actor:SetServerID(jsonData.nServerId)
    end

    -- pkLv
    if jsonData.pklv and actor.SetPKLv then
        actor:SetPKLv(jsonData.pklv)
    end

    -- 主人ID
    if jsonData.MasterId and actor.SetMasterID then
        actor:SetMasterID(jsonData.MasterId)
    end

end
------------------actor attr----
actorUtils._actorAttr = {}
function actorUtils.SetActorAttrByID( actorID, key, value )
    if not actorID or not key then
        return nil
    end

    if not actorUtils._actorAttr[actorID] then
        actorUtils._actorAttr[actorID] = {}
    end

    actorUtils._actorAttr[actorID][key] = value
end

function actorUtils.GetActorAttrByID( actorID, key )
    if not actorID or not key then
        return nil
    end
    
    if not actorUtils._actorAttr[actorID] then
        return nil
    end
    
    return actorUtils._actorAttr[actorID][key]
end

function actorUtils.SetActorAttr( actor, key, value )
    if not actor or not key then
        return nil
    end

    local actorID = actor:GetID()
    actorUtils.SetActorAttrByID( actorID, key, value )
end

function actorUtils.GetActorAttr( actor, key )
    if not actor or not key then
        return nil
    end

    local actorID = actor:GetID()
    return actorUtils.GetActorAttrByID( actorID, key )
end

function actorUtils.ClenupActorAttrByID( actorID )
    if not actorID then
        return nil
    end

    if actorUtils._actorAttr[actorID] then
        actorUtils._actorAttr[actorID] = nil
    end
end

function actorUtils.ClenupActorAttr( actor )
    if not actor then
        return nil
    end

    local actorID = actor:GetID()
    actorUtils.ClenupActorAttrByID( actorID )
end
---------------------------------------------------------------
function actorUtils.CalcActorDirByPos(sX, sY, dX, dY, defaultDir)
    local dx = dX - sX
    local dy = dY - sY
    local ret = defaultDir

    if dx == 0 and dy < 0 then        -- top
        ret = 0 
    elseif dx > 0  and dy < 0  then -- right top
        ret = 1
    elseif dx > 0  and dy == 0 then  -- right
        ret = 2
    elseif dx > 0  and dy > 0  then -- right bottom
        ret = 3
    elseif dx == 0 and  dy > 0 then  -- bottom
        ret = 4
    elseif dx < 0  and dy > 0  then -- left bottom
        ret = 5
    elseif dx < 0  and dy == 0 then  -- left
        ret = 6
    elseif dx < 0  and dy < 0  then -- left top
        ret = 7
    end

    return ret
end

function actorUtils.SetActorName(actor, hudParam)
    if not actor or not hudParam then
        return nil
    end

    if actor:IsPlayer() then
        local MapProxy = global.Facade:retrieveProxy( global.ProxyTable.MapProxy )
        local isUnitveName = true
        local MasterID = actor:GetMasterID() or ""
        if actor:IsHumanoid() and MasterID == "" then
            isUnitveName = false
        end
        if isUnitveName and MapProxy:IsUnitiveName() then
            hudParam.Name = MapProxy:GetUnitiveName( true )
        end
        if isUnitveName and actor:IsShenMiRen() then
            hudParam.Name = GET_STRING(800720)
        end
    end

    actor:SetONameStr(hudParam.Name)

    -- 拆分
    local spName = hudParam.Name or ""
    local nameStr = G_GetSplitArray(spName, "\\")
    local showName = nameStr[1] or ""
    local i, j, namePrefix, name = string.find(showName, "%{(.+)%}(.+)")

    if actor:IsNPC() then
        local bubbleName = string.match(showName, "^$(.+)$$")
        if bubbleName then
            showName = ""
            actor:SetOnlyShowBubbleName(bubbleName)
        end
    end

    actor:SetName(name or showName)

    -- set actor guild name
    local guildID   = hudParam.GuildID or ""
    local guildName = hudParam.GuildName or ""
    if actor:IsPlayer() then
        local lastGuildName = actor:GetGuildName()
        actor:SetGuildName(guildName)
        actor:SetGuildID(guildID)
        if not actor:IsMainPlayer() then
            if guildName and string.len(guildName) > 0 then 
                local mainPlayer = global.gamePlayerController:GetMainPlayer()
                if mainPlayer and mainPlayer:GetGuildName() == guildName then
                    actor:SetCampValue("InGuild", true)
                end
            else
                actor:SetCampValue("InGuild", false)
            end
        elseif lastGuildName ~= guildName then
            global.Facade:sendNotification(global.NoticeTable.MainActorChange_OwnSidePlayer, global.MMO.TYPE_GUILD)
        end
    end

    -- set actor label color
    if actor:IsNPC() then
        local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        local color, isAuto = NPCProxy:GetNameColorByNPCID(actor:GetTypeIndex())
        if isAuto then
            hudParam.Color = color[1] or hudParam.Color
            actor:SetAutoNameColor(color)
        else
            hudParam.Color = color or hudParam.Color
        end
    end
    if hudParam.Color and actor.SetNameColor then
        actor:SetNameColor(hudParam.Color)
    end

    -- record main player name/guild
    if actor:IsMainPlayer() then
        local PlayerProperty = global.Facade:retrieveProxy( global.ProxyTable.PlayerPropertyProxy )
        PlayerProperty:SetName( actor:GetName() )
        PlayerProperty:SetMainPlayerNameColor(hudParam.Color or global.MMO.HUD_COLOR_DEFAULT)
    end
end

function CheckActorCampValue(actor, faction, lastFaction)
    if not actor then
        return
    end

    local isSet = false
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if mainPlayer and mainPlayer:GetID() ~= actor:GetID() then
        if faction and faction > 0 and faction == mainPlayer:GetFaction() then
            if actor.SetCampValue then
                actor:SetCampValue("InCamp", true)
                isSet = true
            end
        end
    end
    if not isSet and actor.SetCampValue then
        actor:SetCampValue("InCamp", false)
    end

    if actor:IsPlayer() and actor:IsMainPlayer() and lastFaction ~= faction then
        global.Facade:sendNotification(global.NoticeTable.MainActorChange_OwnSidePlayer, global.MMO.TYPE_CAMP)
    end
end

------------------------------------- player render order -------------------------------
local renderOrderIdle = 
{
    { 2, 3, 5, 0, 4, 1 },      -- weapon, cloth, wings, shield, hair, left-weapon
    { 4, 2, 5, 0, 3, 1 },
    { 5, 3, 2, 0, 4, 1 },
    { 5, 3, 2, 0, 4, 1 },
    { 2, 3, 0, 4, 5, 1 },
    { 1, 2, 0, 5, 3, 4 },
    { 0, 1, 3, 5, 2, 4 },
    { 0, 1, 3, 5, 2, 4 },
}

local renderOrderRun = 
{
    { 2, 3, 5, 0, 4, 1 },      -- weapon, cloth, wings, shield, hair
    { 4, 2, 5, 0, 3, 1 },
    { 4, 2, 5, 0, 3, 1 },
    { 5, 3, 2, 0, 4, 1 },
    { 5, 1, 0, 4, 2, 3 },
    { 1, 2, 0, 5, 3, 4 },
    { 0, 1, 3, 5, 2, 4 },
    { 0, 1, 3, 5, 2, 4 },
}
local renderOrderAttack = 
{
    { 2, 3, 5, 0, 4, 1 },      -- weapon, cloth, wings, shield, hair
    { 4, 2, 5, 0, 3, 1 },
    { 4, 2, 5, 0, 3, 1 },
    { 5, 3, 2, 0, 4, 1 },
    { 5, 1, 0, 4, 2, 3 },
    { 1, 2, 0, 5, 3, 4 },
    { 0, 1, 3, 5, 2, 4 },
    { 0, 1, 3, 5, 2, 4 },
}

local renderOrderDie = 
{
    { 3, 1, 0, 4, 2, 5 },      -- weapon, cloth, wings, shield, hair
    { 5, 3, 2, 0, 4, 1 },
    { 5, 3, 2, 0, 4, 1 },
    { 5, 3, 2, 0, 4, 1 },
    { 5, 1, 0, 3, 2, 4 },
    { 1, 2, 0, 4, 3, 5 },
    { 0, 1, 3, 4, 2, 5 },
    { 0, 1, 3, 4, 2, 5 },
}

local renderOrderStuck = 
{
    { 2, 0, 3, 4, 1, 5 },      -- weapon, cloth, wings, shield, hair, left-weapon
    { 4, 2, 5, 0, 3, 1 },
    { 2, 3, 5, 0, 4, 1 },
    { 2, 3, 5, 0, 4, 1 },
    { 5, 1, 0, 4, 2, 3 },
    { 1, 2, 0, 5, 3, 4 },
    { 0, 1, 3, 5, 2, 4 },
    { 0, 1, 3, 5, 2, 4 },
}


local PlayerRenderOrder = {
    [global.MMO.ANIM_IDLE]      = renderOrderIdle,
    [global.MMO.ANIM_WALK]      = renderOrderIdle,
    [global.MMO.ANIM_ATTACK]    = renderOrderAttack,
    [global.MMO.ANIM_SKILL]     = renderOrderAttack,
    [global.MMO.ANIM_DIE]       = renderOrderDie,
    [global.MMO.ANIM_RUN]       = renderOrderRun,
    [global.MMO.ANIM_STUCK]     = renderOrderStuck,
    [global.MMO.ANIM_SITDOWN]   = renderOrderAttack,
    [global.MMO.ANIM_BORN]      = renderOrderIdle,
    [global.MMO.ANIM_MINING]    = renderOrderAttack,
}
actorUtils.PlayerRenderOrder = PlayerRenderOrder

local function ReorderPlayerRender(array)
    local sortKey = {}
    if array[1] < array[2] then -- weapon:1 cloth:2 
        local t = clone(array)
        table.sort(t)
        for i, v in ipairs(t) do
            table.insert(sortKey, table.indexof(array, v))
        end

        table.remove(sortKey, table.indexof(sortKey, 1))
        local clothIdx = table.indexof(sortKey, 2)
        table.insert(sortKey, clothIdx + 1, 1)
    
        local order = {}
        for idx, key in ipairs(sortKey) do
            order[key] = idx - 1
        end
        return order
    end
    return array    
end

function actorUtils.ResetPlayerRenderOrderByGameData()
    if SL:GetValue("GAME_DATA", "WeaponLooksOrderUp") and next(SL:GetValue("GAME_DATA", "WeaponLooksOrderUp")) then
        for _, param in ipairs(SL:GetValue("GAME_DATA", "WeaponLooksOrderUp")) do
            if PlayerRenderOrder[param.act] and PlayerRenderOrder[param.act][param.dir + 1] then
                PlayerRenderOrder[param.act][param.dir + 1] = ReorderPlayerRender(PlayerRenderOrder[param.act][param.dir + 1])
            end
        end
    end
end

local renderWeaponOrder=
{
    [32*100+global.MMO.ANIM_IDLE] = {              -- 武器动画id*100 + 状态
        [5] = { 1, 2, 0, 5, 4, 3 }, -- weapon, cloth, wings, shield, hair
    },
    [32*100+global.MMO.ANIM_WALK] = {
        [5] = { 1, 2, 0, 5, 4, 3 }, -- weapon, cloth, wings, shield, hair
    },
    [32*100+global.MMO.ANIM_RUN] = {
        [5] = { 1, 2, 0, 5, 4, 3 }, -- weapon, cloth, wings, shield, hair
    },
    [32*100+global.MMO.ANIM_DIE] = {
        [5] = { 1, 2, 0, 5, 4, 3 }, -- weapon, cloth, wings, shield, hair
    }
}

actorUtils.PlayerWeaponRenderOrder = renderWeaponOrder
------------------------------------- player render order -------------------------------

function actorUtils.IsSmoothMove(actor)
    return not global.isWinPlayMode or 1 == CHECK_SETTING(global.MMO.SETTING_IDX_WINDOW_SMOOTH_VIEW)
end

function actorUtils.CheckIsRiding()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if mainPlayer then
        local masterID = mainPlayer:GetHorseMasterID()
        local copilotID = mainPlayer:GetHorseCopilotID()
        if masterID or copilotID then
            return true
        end
    end
    return false
end

function actorUtils.CheckRunStep()
    local isRide = actorUtils.CheckIsRiding()
    if not isRide and CHECK_SERVER_OPTION(global.MMO.SERVER_RUN_ONE) then
        return 1
    end
    return isRide and 3 or 2
end

function actorUtils.CheckRunAble()
    if global.ConstantConfig.gameOption_WalkOnly == 1 then
        return false
    end

    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)

    -- 721号消息禁跑/只能走
    if PlayerProperty:IsForbidRun() then
        return false
    end

    -- 血量低于10不可以跑
    if PlayerProperty:GetRoleCurHP() < 10 then
        return false
    end
    
    local buffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    return buffProxy:CheckRunEnable() == true
end

local skillActions = {
    [global.MMO.ACTION_YTPD]                = true, -- 倚天辟地
    [global.MMO.ACTION_ZXC]                 = true, -- 追心刺
    [global.MMO.ACTION_SJS]                 = true, -- 三绝杀
    [global.MMO.ACTION_DYZ]                 = true, -- 断岳斩
    [global.MMO.ACTION_HSQJ]                = true, -- 横扫千军
    [global.MMO.ACTION_FWJ]                 = true, -- 凤舞祭
    [global.MMO.ACTION_JLB]                 = true, -- 惊雷爆
    [global.MMO.ACTION_BTXD]                = true, -- 冰天雪地
    [global.MMO.ACTION_SLP]                 = true, -- 双龙破
    [global.MMO.ACTION_HXJ]                 = true, -- 虎啸诀
    [global.MMO.ACTION_BGZ]                 = true, -- 八卦掌
    [global.MMO.ACTION_SYZ]                 = true, -- 三焰咒
    [global.MMO.ACTION_WJGZ]                = true, -- 万剑归宗

    [global.MMO.ACTION_ASSASSIN_RUN]        = true, -- 刺客跑步
    [global.MMO.ACTION_ASSASSIN_SNEAK]      = true, -- 刺客潜行
    [global.MMO.ACTION_ASSASSIN_SMITE]      = true, -- 刺客重击
    [global.MMO.ACTION_ASSASSIN_SKILL]      = true, -- 刺客施法
    [global.MMO.ACTION_ASSASSIN_SY]         = true, -- 刺客霜月
    [global.MMO.ACTION_ASSASSIN_UNKNOWN]    = true, -- 刺客未知动作 
    [global.MMO.ACTION_ASSASSIN_XFT]        = true, -- 旋风腿
    [global.MMO.ACTION_JY]                  = true, -- 箭雨1
    [global.MMO.ACTION_JY2]                 = true, -- 箭雨2
    [global.MMO.ACTION_TSZ]                 = true, -- 推山掌
    [global.MMO.ACTION_XLFH]                = true, -- 降龙伏虎
}
function actorUtils.CheckInSkillAction(action)
    if not action then
        return false
    end

    return skillActions[action] == true
end

function actorUtils.ActorZhuiXinCi(actor, mapX, mapY, dir, zxcTime)
    actor:SetAction(global.MMO.ACTION_IDLE, true)

    -- 加速中
    if actor:GetIsFullSpeedup() then
        zxcTime = zxcTime / global.MMO.DEFAULT_MUCH_FAST_TIME
    elseif actor:GetIsSpeedup() then
        zxcTime = zxcTime / global.MMO.DEFAULT_FAST_TIME_RATE
    end
    
    -- pos & dir
    local lastPosX = actor:getPositionX()
    local lastPosY = actor:getPositionY()
    actor:SetDirection(dir)
    actor:setPosition(lastPosX, lastPosY)
    global.actorManager:SetActorMapXY( actor, mapX, mapY )
    
    -- action & anim
    actor:SetCurrActTime(zxcTime)
    actor:SetAction(global.MMO.ACTION_ZXC, true)
end

function actorUtils.ActorDash(actor, mapX, mapY, dir, dashTime)
    -- for move interrupt， force position
    actor:SetAction(global.MMO.ACTION_IDLE, true)

    -- 加速中
    if actor:GetIsFullSpeedup() then
        dashTime = dashTime / global.MMO.DEFAULT_MUCH_FAST_TIME
    elseif actor:GetIsSpeedup() then
        dashTime = dashTime / global.MMO.DEFAULT_FAST_TIME_RATE
    end
    
    -- pos & dir
    local lastPosX = actor:getPositionX()
    local lastPosY = actor:getPositionY()
    actor:SetDirection(dir)
    actor:setPosition(lastPosX, lastPosY)
    global.actorManager:SetActorMapXY( actor, mapX, mapY )
    
    -- action & anim
    actor:SetCurrActTime(dashTime)
    actor:SetDashWaiting(false)
    actor:SetAction(global.MMO.ACTION_DASH, true)
end

function actorUtils.ActorOnDash(actor, mapX, mapY, dir, dashTime, idleTime)
    -- for move interrupt， force position
    actor:SetAction(global.MMO.ACTION_IDLE, true)

    -- 加速中
    if actor:GetIsFullSpeedup() then
        dashTime = dashTime / global.MMO.DEFAULT_MUCH_FAST_TIME
    elseif actor:GetIsSpeedup() then
        dashTime = dashTime / global.MMO.DEFAULT_FAST_TIME_RATE
    end
    if actor:GetIsFullSpeedup() then
        idleTime = idleTime / global.MMO.DEFAULT_MUCH_FAST_TIME
    elseif actor:GetIsSpeedup() then
        idleTime = idleTime / global.MMO.DEFAULT_FAST_TIME_RATE
    end

    -- pos & dir
    local lastPosX = actor:getPositionX()
    local lastPosY = actor:getPositionY()
    actor:SetDirection(dir)
    actor:setPosition(lastPosX, lastPosY)
    global.actorManager:SetActorMapXY( actor, mapX, mapY )

    -- action & anim
    actor:SetCurrActTime(dashTime)
    if actor:IsPlayer() then
        actor:SetOnPushIdleTime(idleTime)
    end
    actor:SetAction(global.MMO.ACTION_ONPUSH, true)

    -- 
    local buffData = 
    {
        actorID = actor:GetID(),
        buffID = global.MMO.BUFF_ID_ONDASH_IDLE,
        param = dashTime + idleTime,
        autoRemove = true,
    }
    global.Facade:sendNotification(global.NoticeTable.AddBuffEntity, buffData)
end

function actorUtils.ActorSBYS(actor, mapX, mapY, dir)
    global.actorManager:SetActorMapXY( actor, mapX, mapY )
    
    actor:SetDirection(dir)
    actor:SetDashWaiting(false)
    actor:SetAction(global.MMO.ACTION_SBYS, true)
end

function actorUtils.ActorQLS(actor, mapX, mapY, dir)
    global.actorManager:SetActorMapXY( actor, mapX, mapY )
    
    local pX, pY = global.sceneManager:MapPos2WorldPos( mapX, mapY, true )
    actor:setPosition(pX, pY) 
    actor:SetDirection(dir)
    actor:SetAction(global.MMO.ACTION_TELEPORT, true)
    actor:SetCurrActTime(0.01)
end

function actorUtils.KEY_MAP_XY(x, y)
    return Merge16Bit(x, y)
end

function actorUtils.XY_KEY_MAP(key)
    return L16Bit(key), H16Bit(key)
end

function actorUtils.ConverAngleToDirection(angle)
    local ret = 0xff
    if (angle > -22.5 and angle <= 22.5) then -- right
        ret = global.MMO.ORIENT_R
    
    elseif (angle > 22.5 and angle <= 67.5) then -- right up
        ret = global.MMO.ORIENT_RU
    
    elseif (angle > 67.5 and angle <= 112.5) then -- up
        ret = global.MMO.ORIENT_U
    
    elseif (angle > 112.5 and angle <= 157.5) then -- left up
        ret = global.MMO.ORIENT_LU
    
    elseif ((angle > 157.5 and angle <= 180) or (angle <= -157.5 and angle > -180)) then -- left
        ret = global.MMO.ORIENT_L
    
    elseif (angle <= -112.5 and angle > -157.5) then -- left down
        ret = global.MMO.ORIENT_LB
    
    elseif (angle <= -67.5 and angle > -112.5) then -- down
        ret = global.MMO.ORIENT_B
    
    elseif (angle <= -22.5 and angle > -67.5) then --right down
        ret = global.MMO.ORIENT_RB
    end
    return ret
end

local DirMaps =
{
    {x =  0, y = -1},
    {x =  1, y = -1},
    {x =  1, y =  0},
    {x =  1, y =  1},
    {x =  0, y =  1},
    {x = -1, y =  1},
    {x = -1, y =  0},
    {x = -1, y = -1}
}
function actorUtils.DirToNormalizeVec2(dir)
    if dir <= 7 and dir >= 0 then
        return DirMaps[dir + 1]
    end
    return global.MMO.ORIENT_INVAILD
end
local calcWdP = cc.p(0, 0)
function actorUtils.CalcWorldDirection(dstX, dstY, srcX, srcY)
    calcWdP.x = dstX - srcX
    calcWdP.y = dstY - srcY
    local angle = math.deg(cc.pToAngleSelf(calcWdP))
    local ret = global.MMO.ORIENT_INVAILD
    if (angle > -22.5 and angle <= 22.5) then -- right
        ret = global.MMO.ORIENT_R
    
    elseif (angle > 22.5 and angle <= 67.5) then -- right up
        ret = global.MMO.ORIENT_RU
    
    elseif (angle > 67.5 and angle <= 112.5) then -- up
        ret = global.MMO.ORIENT_U
    
    elseif (angle > 112.5 and angle <= 157.5) then -- left up
        ret = global.MMO.ORIENT_LU
    
    elseif ((angle > 157.5 and angle <= 180) or (angle <= -157.5 and angle > -180)) then -- left
        ret = global.MMO.ORIENT_L
    
    elseif (angle <= -112.5 and angle > -157.5) then -- left down
        ret = global.MMO.ORIENT_LB
    
    elseif (angle <= -67.5 and angle > -112.5) then -- down
        ret = global.MMO.ORIENT_B
    
    elseif (angle <= -22.5 and angle > -67.5) then --right down
        ret = global.MMO.ORIENT_RB
    end
    return ret
end

local CalcMapDirectionT = {}
function actorUtils.CalcMapDirection(dX, dY, sX, sY)
    return GUIFunction:CalcMapDirection(dX, dY, sX, sY)
end

function actorUtils.CalcMapDistance(sX, sY, dX, dY)
    return math.max(math.abs(sX - dX), math.abs(sY - dY))
end

function actorUtils.Vec2ToDir(x, y)
    -- convert y
    if y ~= 0 then
        y = -y
    end
    
    local constant = global.MMO
    if x == 0 then
        if y == 0 then
            return constant.ORIENT_INVAILD
        elseif y > 0 then
            return constant.ORIENT_U
        else
            return constant.ORIENT_B
        end
    
    elseif x > 0 then
        if y == 0 then
            return constant.ORIENT_R
        elseif y > 0 then
            return constant.ORIENT_RU
        else
            return constant.ORIENT_RB
        end
    
    else
        if y == 0 then
            return constant.ORIENT_L
        elseif y > 0 then
            return constant.ORIENT_LU
        else
            return constant.ORIENT_LB
        end
    
    end
    
    return global.MMO.ORIENT_INVAILD
end

----------------------------------------------------------------
function actorUtils.CalcDestPosByDir(moveDir, moveStep)
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return nil
    end
    local sX = mainPlayer:GetMapX()
    local sY = mainPlayer:GetMapY()
    local dX, dY = global.PathFindController:FindDestPosJoystick(sX, sY, moveDir, moveStep)
    return dX, dY
end

function actorUtils.CheckOpenDoorByMapPos(x, y)
    if global.sceneManager:canOpenDoor(x, y) then
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        mapProxy:RequestOpenDoor(x, y)
        return true
    end
    return false
end

function actorUtils.CheckOpenDoorByDir(dir, step)
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return false
    end

    local normal = actorUtils.DirToNormalizeVec2(dir)
    local dstX = 0
    local dstY = 0
    for i = 1, step, 1 do
        dstX = mainPlayer:GetMapX() + normal.x * i
        dstY = mainPlayer:GetMapY() + normal.y * i
        if actorUtils.CheckOpenDoorByMapPos(dstX, dstY) then
            return true
        end
    end
    return false
end

----------------------------------------------------------------
local function attackEnable(sX, sY, dX, dY)
    if sX == dX and sY == dY then
        return false
    end
    
    if sX == dX or sY == dY then
        return true
    end
    
    local slope = (dX - sX) / (dY - sY)
    return 1 == math.abs(slope)
end

local function skillEnable()
    return true
end

local function moveEnable()
    return true
end

local function squLen(x, y)
    return x * x + y * y
end

local function findBestPos(sX, sY, dX, dY, range, enableFunc, minRange)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return dX, dY
    end

    minRange = minRange or 0
    if not range or 0 >= range then
        return dX, dY
    end
    
    local result = {}
    local index = 1
    local x = nil
    local y = nil
    local bestIndex = nil
    local cost  = global.MMO.MAX_CONST
    local seqR  = range*range
    local seqMR = minRange*minRange

    -- 1.check origin
    local len = squLen(sX - dX, sY - dY)
    if (len <= seqR) and (len >= seqMR) and enableFunc(sX, sY, dX, dY) then
        return sX, sY
    end
    
    -- 2.check other
    for offY = -range, range do
        for offX = -range, range do
            x = dX + offX
            y = dY + offY

            if enableFunc(x, y, dX, dY) and mapData:isObstacle(x, y) == 0 then
                result[index] = cc.p(x, y)
                local len = squLen(sX - x, sY - y)
                if len < cost and squLen(x - dX, y - dY) >= seqMR then
                    bestIndex = index
                    cost = len
                end
                index = index + 1
            end
        end
    end
    
    if bestIndex and result[bestIndex] then
        return result[bestIndex].x, result[bestIndex].y
    end
    return dX, dY
end

local function isLine(dX, dY, sX, sY)
    if dX == sX or dY == sY then
        return true
    end
    return false
end

local function calcDistance(dX, dY, sX, sY)
    local dis = actorUtils.CalcMapDistance(dX, dY, sX, sY)
    dis = dis + (isLine(dX, dY, sX, sY) and 0 or 0.1)
    return dis
end

function actorUtils.FindBestMovePos(sX, sY, dX, dY, range)
    return findBestPos(sX, sY, dX, dY, range, moveEnable)
end

function actorUtils.FindBestSkillPos(sX, sY, dX, dY, range, minRange)
    return findBestPos(sX, sY, dX, dY, range, skillEnable, minRange)
end

function actorUtils.FindBestAttackPos(sX, sY, dX, dY, range, minRange)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return dX, dY
    end

    minRange = minRange or 0
    if not range or 0 >= range then
        return dX, dY
    end
    
    local seqR  = range*range
    local seqMR = minRange*minRange
    
    local len   = squLen(sX - dX, sY - dY)
    if (len <= seqR) and (len >= seqMR) and attackEnable(sX, sY, dX, dY) then
        return sX, sY
    end

    local items = {}
    local index = 1
    local bestI = nil
    local cost  = global.MMO.MAX_CONST

    local x     = nil
    local y     = nil
    local lenA  = nil

    -- 2.check other
    local lenS  = nil
    local lenD  = nil
    for offY = -range, range do
        for offX = -range, range do
            x = dX + offX
            y = dY + offY

            if attackEnable(x, y, dX, dY) and (mapData:isObstacle(x, y) == 0 or (x == sX and y == sY)) then
                lenS = calcDistance(sX, sY, x, y)
                lenD = calcDistance(dX, dY, x, y)
                lenA = (lenS*1.1) + lenD
                if lenA < cost and squLen(x - dX, y - dY) >= seqMR then
                    bestI = index
                    cost  = lenA
                end

                items[index] = cc.p(x, y)
                index = index + 1
            end
        end
    end
    
    if bestI and items[bestI] then
        return items[bestI].x, items[bestI].y
    end
    return dX, dY
end

-- 获取角色外观
function actorUtils.GetFeatureByActorID(actorID)
    local features = {
        clothID       = 0,
        hairID        = 0,
        weaponID      = 0,
        shieldID      = 0,
        mountID       = 0,
        wingsID       = 0,
        weaponEff     = 0,
        shieldEffect  = 0,
        leftWeaponID  = 0,
        leftWeaponEff = 0
    }

    local actor = global.actorManager:GetActor(actorID)
    if not actor then 
        return features
    end

    features.clothID       = actor:GetAppearByID(global.MMO.P_F_CLOTH)
    features.weaponID      = actor:GetAppearByID(global.MMO.P_F_WEAPON)
    
    -- 左武器
    features.leftWeaponID  = actor:GetAppearByID(global.MMO.P_F_LEFT_WEAPON)  
    features.leftWeaponEff = actor:GetAppearByID(global.MMO.P_F_LEFT_WEAPON_EFF)  
    -- 发型
    local hairID           = actor:GetAppearByID(global.MMO.P_F_HAIR)

    -- 骑马
    features.mountID       = actor:GetAppearByID(global.MMO.P_F_MONSTER)

    -- 幻武 时装 翅膀 足迹 武器特效
    local wingsID       = actor:GetAppearByID(global.MMO.P_F_WINGS)
    local weaponEff     = actor:GetAppearByID(global.MMO.P_F_WEAPON_EFF)
    -- 足迹特效
    local mountEff      = actor:GetAppearByID(global.MMO.P_F_MONSTER_EFF)
    -- 骑马人物外观
    local mountCloth    = actor:GetAppearByID(global.MMO.P_F_MONSTER_CLOTH)
    -- 盾牌
    local shieldID      = actor:GetAppearByID(global.MMO.P_F_SHIELD)
    -- 盾牌特效
    local shieldEffect  = actor:GetAppearByID(global.MMO.P_F_SHIELD_EFF)

    if hairID and hairID > 0 then
        features.hairID = hairID
    end

    if wingsID and wingsID > 0 then
        features.wingsID = wingsID
    end

    if weaponEff and weaponEff > 0 then
        features.weaponEff = weaponEff
    end

    if mountEff and mountEff > 0 then
        features.mountEff = mountEff
    end

    if mountCloth and mountCloth > 0 then
        features.mountCloth = mountCloth
    end

    -- 盾牌
    if shieldID and shieldID > 0 then
        features.shieldID = shieldID
    end

    -- 盾牌特效
    if shieldEffect and shieldEffect > 0 then
        features.shieldEffect = shieldEffect
    end

    return features
end

-- 是否移动动画/动作
local MMO = global.MMO
local MAP_MOVE_ANIM = 
{
    [MMO.ANIM_WALK] = 1,
    [MMO.ANIM_RUN] = 1,
    [MMO.ANIM_RIDE_RUN] = 1,
    [MMO.ANIM_ASSASSIN_SNEAK] = 1,
    [MMO.ANIM_ASSASSIN_RUN] = 1,
}
local MAP_MOVE_ACTION = 
{
    [MMO.ACTION_WALK] = 1,
    [MMO.ACTION_RUN] = 1,
    [MMO.ACTION_RIDE_RUN] = 1,
    [MMO.ACTION_ASSASSIN_SNEAK] = 1,
    [MMO.ACTION_ASSASSIN_RUN] = 1,
}
function actorUtils.IsMoveAnim(anim)
    return MAP_MOVE_ANIM[anim]
end

function actorUtils.IsMoveAction(action)
    return MAP_MOVE_ACTION[action]
end
return actorUtils