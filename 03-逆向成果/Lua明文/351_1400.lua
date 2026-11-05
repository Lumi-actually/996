local RenderTextureInfo = class("RenderTextureInfo")

function RenderTextureInfo:ctor(data)
    self._time = data.time or 0
    self._func = data.func
    self._isInvalid = false
    self._curTime = 0
    self._count = data.count or -1
    self._id = data.id or -1
end

function RenderTextureInfo:Tick(dt)
    if not self:IsInvalid() then
        self._curTime = self._curTime + dt
        if self._curTime >= self._time and (self._count == -1 or self._count > 0) then 

            if self._count > 0 then 
                self._count = self._count - 1
            end

            if self._count == 0 then 
                global.RenderTextureManager:RmvDrawFunc(self._id)
            end
            self._curTime = 0

            if self._func then 
                self._func()
            end
        end
    end 
end

function RenderTextureInfo:Reset(data)
    self._time = data.time or 0
    self._func = data.func
    self._isInvalid = false
    self._curTime = 0
    self._count = data.count or -1
    self._id = data.id or -1
end

function RenderTextureInfo:IsInvalid()
    return self._isInvalid
end

function RenderTextureInfo:SetInvalid(invalid)
    self._isInvalid = invalid
end

function RenderTextureInfo:GetID()
    return self._id
end

function RenderTextureInfo:GetCount()
    return self._count
end
return RenderTextureInfo