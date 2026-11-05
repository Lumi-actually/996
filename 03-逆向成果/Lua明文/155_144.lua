local Element = class("Element")
function Element:ctor(etype)
    self.type = etype or "ERROR TYPE"
    self.attr = {}
end

return Element