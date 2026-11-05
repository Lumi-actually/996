local SWidget = class("SWidget")

local Element   = require("sui/Element")
local SUIHelper = require("sui/SUIHelper")


function SWidget:ctor()
    self.element  = nil
    self.render   = nil
    self.trunk    = nil
    self.branches = {}
    self.index    = 1               -- Z轴
    self.depth    = 1               -- 深度
end

function SWidget:cleanup()
    self.element  = nil
    self.render   = nil
    self.trunk    = nil
    self.branches = {}
    self.index    = 1               -- Z轴
    self.depth    = 1               -- 深度
end

function SWidget:addBranch(branch)
    table.insert(self.branches, branch)

    branch.index  = #self.branches
    branch.trunk  = self
    branch.depth  = self.depth + 1
end

function SWidget:insertBranch(branch, index)
    table.insert(self.branches, index, branch)

    branch.index  = index
    branch.trunk  = self
    branch.depth  = self.depth + 1

    -- update index
    for index, branch in ipairs(self.branches) do
        branch.index = index
        if branch.render then
            branch.render:setLocalZOrder(branch.index)
        end
    end
end

function SWidget:removeBranch(branch)
    table.remove(self.branches, branch.index)

    if branch.render then
        if not global.SWidgetCache:cachingRender(branch) then
            branch.render:retain()
            if self.element.type == "ListView" then
                self.render:removeItem(self.render:getIndex(branch.render))
            elseif self.element.type == "PageView" then
                self.render:removePage(branch.render)
            else
                branch.render:removeFromParent()
            end
            branch.render:autorelease()
        end
    end

    -- update index
    for index, branch in ipairs(self.branches) do
        branch.index = index
        if branch.render then
            branch.render:setLocalZOrder(branch.index)
        end
    end
end

function SWidget:addBranchRender(branch)
    if not self.render then
        print("ERROR function SWidget:addBranchRender(branch), curr render error")
        return false
    end
    if not branch then
        print("ERROR function SWidget:addBranchRender(branch), branch arge error")
        return false
    end

    if self.element.type == "ListView" then
        -- self.render:pushBackCustomItem(branch.render)
        self.render:insertCustomItem(branch.render, branch.index-1)
    elseif self.element.type == "PageView" then
        self.render:insertPage(branch.render, branch.index-1)
    else
        self.render:addChild(branch.render)
        branch.render:setLocalZOrder(branch.index)
    end
end

function SWidget:replaceRender(newrender)
    local children = self.render:getChildren()
    for _, branch in ipairs(self.branches) do
        branch.render:retain()
        branch.render:autorelease()
        branch.render:removeFromParent()
        newrender:addChild(branch.render)
        branch.render:setLocalZOrder(branch.index)
    end

    self.render:removeFromParent()
    self.render = newrender
    self.trunk.render:addChild(self.render)
    self.render:setLocalZOrder(self.index)
end

return SWidget