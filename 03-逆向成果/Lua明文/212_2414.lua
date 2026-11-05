-- add empty ccslog function to avoid function not defined error.
-- if you log something, add what you want in it.
if cc.exports then
    cc.exports.ccslog = function(...) end
else
    ccslog = function(...) end
end

-- used as metaTable
local luaExtend = {}

local function getChildInSubNodes(nodeTable, key)
    if #nodeTable == 0 then
        return nil
    end
    local child = nil
    local subNodeTable = {}
    for _, v in ipairs(nodeTable) do
        child = v:getChildByName(key)
        if (child) then
            return child
        end
    end
    for _, v in ipairs(nodeTable) do
        local subNodes = v:getChildren()
        if #subNodes ~= 0 then
            for _, v1 in ipairs(subNodes) do
                table.insert(subNodeTable, v1)
            end
        end
    end
    return getChildInSubNodes(subNodeTable, key)
end

luaExtend.__index = function(table, key)
local root = table.root
local child = root[key]
    if child then
        return child
    end

    child = root:getChildByName(key)
    if child then
        root[key] = child
        return child
    end

    child = getChildInSubNodes(root:getChildren(), key)
    if child then root[key] = child end
    return child
end
-- used as metaTable

luaExtend.__newindex = function(table, key, value)
    if key == "root" and nil == rawget(table, key) then
        local function checkChildren(children)
            if #children == 0 then
                return nil
            end

            for _, child in pairs(children) do
                if child.getDescription and (child:getDescription() == "ListView" or child:getDescription() == "ScrollView") then
                    if child:getDirection() == 1 and (nil == child.UserData or (tonumber(child.UserData[1]) and tonumber(child.UserData[1]) > 0)) then
                        local speed = nil
                        if child.UserData and tonumber(child.UserData[1]) and tonumber(child.UserData[1]) > 0 then
                            speed = tonumber(child.UserData[1])
                        end
                        child:addMouseScrollPercent(speed)
                    end
                end
                checkChildren(child:getChildren())
            end
        end
        checkChildren(value:getChildren())
    end

    rawset(table, key, value)
end

return luaExtend
