local RemoteProxy = requireProxy("RemoteProxy")
local AttrConfigProxy = class("AttrConfigProxy", RemoteProxy)
AttrConfigProxy.NAME  = global.ProxyTable.AttrConfigProxy

function AttrConfigProxy:ctor()
   AttrConfigProxy.super.ctor(self)
   self._attribute = {}

   self._attTypes = {} --属性类型  表中的属性id
   self._nAttType = 0
end

function AttrConfigProxy:LoadConfig()
   SL:Print("[Require game_config] ", "cfg_att_score")
   self._attribute = SL:RequireFile("game_config/cfg_att_score")

   local n = 0
   -- 兼容scolor
   for _, v in pairs(self._attribute) do
      v.color = v.color or v.scolor

      n = n + 1
      self._attTypes[n] = v.Idx
   end
   self._nAttType = n

   -- 服务开关 修改属性为万分比
   local bFixMagicMiss = CHECK_SERVER_OPTION(SW_KEY_MAGIC_MISS_TYPE)
   if bFixMagicMiss then 
      self._attribute[15].type = 2
   end 

   local bFixAntiPoison = CHECK_SERVER_OPTION(SW_KEY_ANTI_POISON_TYPE)
   if bFixAntiPoison then 
      self._attribute[16].type = 2
      self._attribute[17].type = 2
   end 

   local bFixOther = CHECK_SERVER_OPTION("UseYSNewCalType")
   if bFixOther then 
      for i = 21, 31 do 
         self._attribute[i].type = 2
      end 
      self._attribute[43].type = 2
      self._attribute[72].type = 2
   end 
end

function AttrConfigProxy:GetAttTypes()
   return self._attTypes, self._nAttType
end

function AttrConfigProxy:GetAttConfigByAttId(attId)
   return self._attribute[attId]
end

function AttrConfigProxy:GetAttConfig()
   return self._attribute
end

function AttrConfigProxy:GetItemsConfigQuickUsable()
   return {
      [0] = true,
      [2] = true,
      [3] = true,
   }
end

function AttrConfigProxy:onRegister()
   AttrConfigProxy.super.onRegister(self)
end

return AttrConfigProxy