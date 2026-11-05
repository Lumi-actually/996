
--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local EditBox = ccui.EditBox

function EditBox:onEditHandler(callback)
    self:registerScriptEditBoxHandler(function(name, sender)
        if global and global._editBoxEditing and tolua.isnull(global._editBoxEditing) then
            global._editBoxEditing = nil
        end
        if not global._editBoxEditing or global._editBoxEditing == sender or global.isWindows then
            global._editBoxEditing = sender
            if name == "return" or name == "send" then
                global._editBoxEditing = nil
            end
            local event = {}
            event.name = name
            event.target = sender
            callback(event)
        end
    end)
    return self
end

function EditBox:removeEditHandler()
    self:unregisterScriptEditBoxHandler()
    return self
end
