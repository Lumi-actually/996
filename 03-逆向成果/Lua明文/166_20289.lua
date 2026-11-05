local DebugProxy = requireProxy("DebugProxy")
local AudioProxy = class("AudioProxy", DebugProxy)
AudioProxy.NAME  = global.ProxyTable.AudioProxy

local MMO   = global.MMO
local bBand = bit.band

local AudioKeys = {
	s_walk_ground_l      	 = 1,
	s_walk_ground_r      	 = 2,
	s_run_ground_l       	 = 3,
	s_run_ground_r       	 = 4,
	s_walk_stone_l       	 = 5,
	s_walk_stone_r       	 = 6,
	s_run_stone_l        	 = 7,
	s_run_stone_r        	 = 8,
	s_walk_lawn_l        	 = 9,
	s_walk_lawn_r        	 = 10,
	s_run_lawn_l         	 = 11,
	s_run_lawn_r         	 = 12,
	s_walk_rough_l       	 = 13,
	s_walk_rough_r       	 = 14,
	s_run_rough_l        	 = 15,
	s_run_rough_r        	 = 16,
	s_walk_wood_l        	 = 17,
	s_walk_wood_r        	 = 18,
	s_run_wood_l         	 = 19,
	s_run_wood_r         	 = 20,
	s_walk_cave_l        	 = 21,
	s_walk_cave_r        	 = 22,
	s_run_cave_l         	 = 23,
	s_run_cave_r         	 = 24,
	s_walk_room_l        	 = 25,
	s_walk_room_r        	 = 26,
	s_run_room_l         	 = 27,
	s_run_room_r         	 = 28,
	s_walk_water_l       	 = 29,
	s_walk_water_r       	 = 30,
	s_run_water_l        	 = 31,
	s_run_water_r        	 = 32,

	s_hit_short          	 = 50,
	s_hit_wooden         	 = 51,
	s_hit_sword          	 = 52,
	s_hit_do             	 = 53,
	s_hit_axe            	 = 54,
	s_hit_club           	 = 55,
	s_hit_long           	 = 56,
	s_hit_fist           	 = 57,

	s_struck_short       	 = 60,
	s_struck_wooden      	 = 61,
	s_struck_sword       	 = 62,
	s_struck_do          	 = 63,
	s_struck_axe         	 = 64,
	s_struck_club        	 = 65,

	s_struck_body_sword  	 = 70,
	s_struck_body_axe    	 = 71,
	s_struck_body_longstick  = 72,
	s_struck_body_fist   	 = 73,

	s_struck_armor_sword 	 = 80,
	s_struck_armor_axe   	 = 81,
	s_struck_armor_longstick = 82,
	s_struck_armor_fist      = 83,

	s_strike_stone           = 91,
	s_drop_stonepiece        = 92,

	s_rock_door_open     	 = 100,
	s_intro_theme        	 = 102,
	s_meltstone          	 = 101,
	s_main_theme         	 = 102,
	s_norm_button_click  	 = 103,
	s_rock_button_click  	 = 104,
	s_glass_button_click 	 = 105,
	s_money              	 = 106,
	s_eat_drug           	 = 107,
	s_click_drug         	 = 108,
	s_spacemove_out      	 = 109,
	s_spacemove_in       	 = 110,

	s_click_weapon       	 = 111,
	s_click_armor        	 = 112,
	s_click_ring         	 = 113,
	s_click_armring      	 = 114,
	s_click_necklace     	 = 115,
	s_click_helmet       	 = 116,
	s_click_grobes       	 = 117,
	s_itmclick           	 = 118,

	s_rush_l             	 = 134,
	s_rush_r             	 = 135,
	s_firehit_ready      	 = 136,

	s_man_struck     	 	 = 138,
	s_wom_struck     		 = 139,
	s_man_die        		 = 144,
	s_wom_die        		 = 145,

	s_upgrade        		 = 146,
	s_open_box				 = 147,
	s_flash_box				 = 148,
	s_hero_active	 		 = 50016,
	s_hero_unactive	 		 = 50017,

	s_ride_walk 			 = 50131,
	s_ride_run 				 = 50132,
}

local WeaponKeys = {
	[1]			= AudioKeys.s_hit_wooden,
	[2]			= AudioKeys.s_hit_sword,
	[3]			= AudioKeys.s_hit_axe,
	[4]			= AudioKeys.s_hit_do,
	[5]			= AudioKeys.s_hit_sword,
	[6]			= AudioKeys.s_hit_short,
	[7]			= AudioKeys.s_hit_axe,
	[8]			= AudioKeys.s_hit_long,
	[9]			= AudioKeys.s_hit_sword,
	[10]		= AudioKeys.s_hit_do,
	[11]		= AudioKeys.s_hit_axe,
	[12]		= AudioKeys.s_hit_long,
	[13]		= AudioKeys.s_hit_sword,
	[14]		= AudioKeys.s_hit_sword,
	[15]		= AudioKeys.s_hit_do,
	[16]		= AudioKeys.s_hit_do,
	[17]		= AudioKeys.s_hit_do,
	[18]		= AudioKeys.s_hit_long,
	[20]		= AudioKeys.s_hit_short,
	[21]		= AudioKeys.s_hit_long,
	[22]		= AudioKeys.s_hit_sword,
	[23]		= AudioKeys.s_hit_do,
	[24]		= AudioKeys.s_hit_club,

	[-1]		= AudioKeys.s_hit_fist
}

-- 0非人类玩家; 1人类玩家Shape==3; 2人类玩家除1外其他
local StuckKeys = {
	[0]  = {
		[1] 	= AudioKeys.s_struck_body_sword,
		[2] 	= AudioKeys.s_struck_body_sword,
		[3] 	= AudioKeys.s_struck_body_axe,
		[4] 	= AudioKeys.s_struck_body_sword,
		[5] 	= AudioKeys.s_struck_body_sword,
		[6] 	= AudioKeys.s_struck_body_sword,
		[8] 	= AudioKeys.s_struck_body_longstick,
		[9] 	= AudioKeys.s_struck_body_sword,
		[10] 	= AudioKeys.s_struck_body_sword,
		[11] 	= AudioKeys.s_struck_body_axe,
		[12] 	= AudioKeys.s_struck_body_longstick,
		[13] 	= AudioKeys.s_struck_body_sword,
		[14] 	= AudioKeys.s_struck_body_sword,
		[15] 	= AudioKeys.s_struck_body_sword,
		[16] 	= AudioKeys.s_struck_body_sword,
		[17] 	= AudioKeys.s_struck_body_sword,
		[18] 	= AudioKeys.s_struck_body_longstick,

		[-1] 	= AudioKeys.s_struck_body_fist
	},
	[1] = {
		[1] 	= AudioKeys.s_struck_armor_sword,
		[2] 	= AudioKeys.s_struck_armor_sword,
		[3] 	= AudioKeys.s_struck_armor_axe,
		[4] 	= AudioKeys.s_struck_armor_sword,
		[5] 	= AudioKeys.s_struck_armor_sword,
		[6] 	= AudioKeys.s_struck_armor_sword,
		[8] 	= AudioKeys.s_struck_armor_longstick,
		[9] 	= AudioKeys.s_struck_armor_sword,
		[10] 	= AudioKeys.s_struck_armor_sword,
		[11] 	= AudioKeys.s_struck_armor_axe,
		[12] 	= AudioKeys.s_struck_armor_longstick,
		[13] 	= AudioKeys.s_struck_armor_sword,
		[14] 	= AudioKeys.s_struck_armor_sword,
		[15] 	= AudioKeys.s_struck_armor_sword,
		[16] 	= AudioKeys.s_struck_armor_sword,
		[17] 	= AudioKeys.s_struck_armor_sword,
		[18] 	= AudioKeys.s_struck_armor_longstick,

		[-1] 	= AudioKeys.s_struck_armor_fist
	},
	[2]  = {
		[1] 	= AudioKeys.s_struck_body_sword,
		[2] 	= AudioKeys.s_struck_body_sword,
		[3] 	= AudioKeys.s_struck_body_axe,
		[4] 	= AudioKeys.s_struck_body_sword,
		[5] 	= AudioKeys.s_struck_body_sword,
		[6] 	= AudioKeys.s_struck_body_sword,
		[8] 	= AudioKeys.s_struck_body_longstick,
		[9] 	= AudioKeys.s_struck_body_sword,
		[10] 	= AudioKeys.s_struck_body_sword,
		[11] 	= AudioKeys.s_struck_body_axe,
		[12] 	= AudioKeys.s_struck_body_longstick,
		[13] 	= AudioKeys.s_struck_body_sword,
		[14] 	= AudioKeys.s_struck_body_sword,
		[15] 	= AudioKeys.s_struck_body_sword,
		[16] 	= AudioKeys.s_struck_body_sword,
		[17] 	= AudioKeys.s_struck_body_sword,
		[18] 	= AudioKeys.s_struck_body_longstick,

		[-1] 	= AudioKeys.s_struck_body_fist
	},
	[-1] 		= AudioKeys.s_struck_body_longstick
}

local findhand = function (name)
	return string.find(name, "手镯") or string.find(name, "手套")
end

local ClickItemKeys = {
	[0]			= AudioKeys.s_click_drug,
	[5]			= AudioKeys.s_click_weapon,
	[6]			= AudioKeys.s_click_weapon,
	[10]		= AudioKeys.s_click_armor,
	[11]		= AudioKeys.s_click_armor,
	[15]		= AudioKeys.s_click_helmet,
	[19]		= AudioKeys.s_click_necklace,
	[20]		= AudioKeys.s_click_necklace,
	[21]		= AudioKeys.s_click_necklace,
	[22]		= AudioKeys.s_click_ring,
	[23]		= AudioKeys.s_click_ring,
	[24]		= function (name) return findhand(name) and AudioKeys.s_click_grobes or AudioKeys.s_click_armring end,
	[26]		= function (name) return findhand(name) and AudioKeys.s_click_grobes or AudioKeys.s_click_armring end,

	[-1] 		= AudioKeys.s_itmclick
}

local MoveKeys = {
	[1] = {
		--
		{min = 1385, max = 1385, key = AudioKeys.s_walk_wood_l},
		{min = 1386, max = 1386, key = AudioKeys.s_walk_wood_l},
		{min = 1391, max = 1391, key = AudioKeys.s_walk_wood_l},
		{min = 1392, max = 1392, key = AudioKeys.s_walk_wood_l},

		--
		{min = 1375, max = 1799, func = function (x) return math.round((x - 1375) / 25) % 2 == 0 and AudioKeys.s_walk_cave_l end},

		-- 
		{min = 825,  max = 1349, func = function (x) return math.round((x - 825) / 25) % 2 == 0 and AudioKeys.s_walk_stone_l end},

		-- 草地上行走
		{min = 330,  max = 349,  key = AudioKeys.s_walk_lawn_l},
		{min = 450,  max = 454,  key = AudioKeys.s_walk_lawn_l},
		{min = 550,  max = 554,  key = AudioKeys.s_walk_lawn_l},
		{min = 750,  max = 754,  key = AudioKeys.s_walk_lawn_l},
		{min = 950,  max = 954,  key = AudioKeys.s_walk_lawn_l},
		{min = 1250, max = 1254, key = AudioKeys.s_walk_lawn_l},
		{min = 1400, max = 1424, key = AudioKeys.s_walk_lawn_l},
		{min = 1455, max = 1474, key = AudioKeys.s_walk_lawn_l},
		{min = 1500, max = 1524, key = AudioKeys.s_walk_lawn_l},
		{min = 1550, max = 1574, key = AudioKeys.s_walk_lawn_l},

		-- 粗糙的地面
		{min = 250,  max = 254,  key = AudioKeys.s_walk_rough_l},
		{min = 1005, max = 1009, key = AudioKeys.s_walk_rough_l},
		{min = 1050, max = 1054, key = AudioKeys.s_walk_rough_l},
		{min = 1060, max = 1064, key = AudioKeys.s_walk_rough_l},
		{min = 1450, max = 1454, key = AudioKeys.s_walk_rough_l},
		{min = 1650, max = 1654, key = AudioKeys.s_walk_rough_l},

		-- 石头地面上行走
		{min = 605,  max = 609,  key = AudioKeys.s_walk_stone_l},
		{min = 650,  max = 654,  key = AudioKeys.s_walk_stone_l},
		{min = 660,  max = 664,  key = AudioKeys.s_walk_stone_l},
		{min = 2000, max = 2049, key = AudioKeys.s_walk_stone_l},
		{min = 3025, max = 3049, key = AudioKeys.s_walk_stone_l},
		{min = 2400, max = 2424, key = AudioKeys.s_walk_stone_l},
		{min = 4625, max = 4649, key = AudioKeys.s_walk_stone_l},
		{min = 4675, max = 4678, key = AudioKeys.s_walk_stone_l},

		-- 洞穴里行走
		{min = 1825, max = 1924, key = AudioKeys.s_walk_cave_l},
		{min = 2150, max = 2174, key = AudioKeys.s_walk_cave_l},
		{min = 3075, max = 3099, key = AudioKeys.s_walk_cave_l},
		{min = 3325, max = 3349, key = AudioKeys.s_walk_cave_l},
		{min = 3375, max = 3399, key = AudioKeys.s_walk_cave_l},

		-- 木头地面行走
		{min = 3230, max = 3230, key = AudioKeys.s_walk_wood_l},
		{min = 3231, max = 3231, key = AudioKeys.s_walk_wood_l},
		{min = 3246, max = 3246, key = AudioKeys.s_walk_wood_l},
		{min = 3277, max = 3277, key = AudioKeys.s_walk_wood_l},

		-- 带傈
		{min = 3780, max = 3799, key = AudioKeys.s_walk_wood_l},

		{min = 3825, max = 4434, func = function (x) return (x - 3825) % 25 == 0 and AudioKeys.s_walk_wood_l or AudioKeys.s_walk_ground_l end},

		-- 房间里
		{min = 2075, max = 2099, key = AudioKeys.s_walk_room_l},
		{min = 2125, max = 2149, key = AudioKeys.s_walk_room_l},

		-- 水中
		{min = 1800, max = 1824, key = AudioKeys.s_walk_water_l}
	},
	[2] = {
		{min = 0, 	 max = 115,  key = AudioKeys.s_walk_ground_l},
		{min = 120,  max = 124,  key = AudioKeys.s_walk_lawn_l}
	},
	[3] = {
		{min = 221,  max = 289,  key = AudioKeys.s_walk_stone_l},
		{min = 583,  max = 658,  key = AudioKeys.s_walk_stone_l},
		{min = 1183, max = 1206, key = AudioKeys.s_walk_stone_l},
		{min = 7163, max = 7295, key = AudioKeys.s_walk_stone_l},
		{min = 7404, max = 7414, key = AudioKeys.s_walk_stone_l},
		
		{min = 3125,  max = 3267,  key = AudioKeys.s_walk_wood_l},
		{min = 3757,  max = 3948,  key = AudioKeys.s_walk_wood_l},
		{min = 6030,  max = 6999,  key = AudioKeys.s_walk_wood_l},

		{min = 3316,  max = 3589,  key = AudioKeys.s_walk_room_l}
	}
}

function AudioProxy:ctor()
	AudioProxy.super.ctor(self)
	self._config = {}
	self:Init()
end

function AudioProxy:onRegister()
	AudioProxy.super.onRegister(self)
end

function AudioProxy:LoadConfig()
	SL:Print("[Require game_config] ", "cfg_sound")
    self._config = SL:RequireFile("game_config/cfg_sound")

	for k, v in pairs(self._config) do
		if v.file then
			v.file = string.gsub(tostring(v.file), "\\", "/")
			v.file = string.gsub(tostring(v.file), " ", "")
		end
	end
end

function AudioProxy:GetConfig(id)
	return self._config[id]
end

function AudioProxy:Init()
	self._AudioTypeFunc = {
		[MMO.SND_TYPE_SKILL_LUAUNCH] 	= function (type, index, sex, param, isRide, delayTime) return self:getSkillSoundId(index, delayTime)  end,
		[MMO.SND_TYPE_SKILL_ATTACK] 	= function () 						 					return self:getSkillAttack() 				   					end,
		[MMO.SND_TYPE_STUCK_WEAPON] 	= function (type, index, sex) 		 					return self:getWeaponSound(index) 			   		 end,
		[MMO.SND_TYPE_STUCK] 			= function (type, index, sex, param) 					return self:getStuckSoundId(index, param) end,
		[MMO.SND_TYPE_SCREAM] 			= function (type, index, sex, param) 					return self:getStuckScreamSoundId(param) 	   			 end,
		[MMO.SND_TYPE_PLAYER_DIE] 		= function (type, index, sex) 	     					return self:getPlayerDieSoundId(index) 	   				 end,
		[MMO.SND_TYPE_CLICK_ITEM] 		= function (type, index, sex, param) 					return self:getClickItemSoundId(param) 	   				 end,
		[MMO.SND_TYPE_USE_ITEM] 		= function (type, index, sex, param) 					return self:getUseItemSoundId(param) 		   				 end,
		[MMO.SND_TYPE_ACT_MOVE] 		= function (type, index, sex, param, isRide)			return self:getMoveSoundId(index, isRide)		 end,
		[MMO.SND_TYPE_MON_BORN] 		= function (type, index, sex) 		 					return self:getMonBornSoundId(index) 					 end,
		[MMO.SND_TYPE_MON_MOVE] 		= function (type, index, sex) 		 					return self:getMonMoveSoundId(index) 					 end,
		[MMO.SND_TYPE_MON_DIE] 			= function (type, index, sex) 		 					return self:getMonDieSoundId(index) 					 end,
		[MMO.SND_TYPE_MON_ATTACK] 		= function (type, index, sex) 		 					return self:getMonAttackSoundId(index) 				 end,
		[MMO.SUD_TYPE_NORMAL]			= function (type, index, sex) 							return index 													 end,

		[MMO.SND_TYPE_MONEY] 			= function () return AudioKeys.s_money 				end,
		[MMO.SND_TYPE_LOGIN_DOOR] 		= function () return AudioKeys.s_rock_door_open 	end,
		[MMO.SND_TYPE_LOGIN_SELECTONE]  = function () return AudioKeys.s_meltstone 			end,
		[MMO.SND_TYPE_FLY_OUT] 			= function () return AudioKeys.s_spacemove_out 		end,
		[MMO.SND_TYPE_FLY_IN] 			= function () return AudioKeys.s_spacemove_in 		end,
		[MMO.SND_TYPE_UPGRADE] 			= function () return AudioKeys.s_upgrade 			end,

		[MMO.SND_TYPE_MINING] 			= function () return AudioKeys.s_strike_stone 		end,
		[MMO.SND_TYPE_MINING_DROP] 		= function () return AudioKeys.s_drop_stonepiece 	end,
		[MMO.SND_TYPE_LAYER_CLICK] 		= function () return AudioKeys.s_glass_button_click end,
		[MMO.SND_TYPE_LAYER_CLOSE] 		= function () return AudioKeys.s_norm_button_click 	end,
		[MMO.SND_TYPE_BTN_CLICK]		= function () return AudioKeys.s_norm_button_click	end,
		[MMO.SND_TYPE_FLY_IN_HERO] 		= function () return AudioKeys.s_hero_active 		end,
		[MMO.SND_TYPE_FLY_OUT_HERO] 	= function () return AudioKeys.s_hero_unactive 		end,
		[MMO.SND_TYPE_UPGRADE] 			= function () return AudioKeys.s_upgrade 			end,
		[MMO.SND_TYPE_OPEN_BOX] 		= function () return AudioKeys.s_open_box 			end,
		[MMO.SND_TYPE_FLASH_BOX]		= function () return AudioKeys.s_flash_box 			end,

		-- BGM
		[MMO.SND_TYPE_BGM_LOGIN] 		= function () return "mp3/Log-in-long2.mp3" 		end,
		[MMO.SND_TYPE_BGM_DIE] 			= function () return "mp3/Game-over2.mp3" 			end,
		[MMO.SND_TYPE_BGM_SELECT] 		= function () return "mp3/sellect-loop2.mp3" 		end,
		[MMO.SND_TYPE_BGM_MAP] 			= function () return self:getMapBGM() 				end,
	}
end

function AudioProxy:getAudioId(data)
	local type = data and data.type
	if not type then 
		return nil 
	end
	local func = self._AudioTypeFunc[type]
	if not func then
		return nil
	end
	local p1, p2, p3, p4 = func(type, data.index, data.sex, data.param, data.isRide, data.delayTime)
	return p1, p2, p3, p4
end

function AudioProxy:getBGMPath(data)
	local type = data and data.type
	if not type then 
		return nil 
	end

	local func = self._AudioTypeFunc[type]
	return func and func(type, data.index, data.sex, data.param) or nil
end

-- 获取地图背景音乐
function AudioProxy:getMapBGM()
	local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
	local mapBGMID = MapProxy:GetMapBGM() 
	mapBGMID = tonumber(mapBGMID) or 0
	if mapBGMID < 1 then
		return nil
	end

	local audio = self:GetConfig(mapBGMID)
	return audio and audio.file
end

-- 技能
function AudioProxy:getSkillSoundId(index, delayTime)
	return index, delayTime
end

function AudioProxy:getSkillAttack()
	local mainPlayer = global.gamePlayerController:GetMainPlayer()
	if not mainPlayer then 
		return nil
	end

	return self:getWeaponSound(mainPlayer:GetAppearByID(global.MMO.P_F_WEAPON))
end

-- 普攻(第二帧时播放)
function AudioProxy:getWeaponSound(weaponID)
	if not weaponID then 
		return nil 
	end

	return WeaponKeys[weaponID] or WeaponKeys[-1], 0.085
end

-- 受击装备的声音
function AudioProxy:getStuckSoundId(attackweapon, actorID)
	if not actorID then 
		return nil
	end

	local gameActor = global.actorManager:GetActor(actorID)
	if not gameActor or not gameActor:IsPlayer() then
		return StuckKeys[0][attackweapon] or StuckKeys[0][-1]
	end

	local equip = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Dress)

	if equip and equip.Shape == 3 then
		return StuckKeys[1][attackweapon] or StuckKeys[1][-1]
	else
		return StuckKeys[2][attackweapon] or StuckKeys[2][-1]
	end
end

-- 受击
function AudioProxy:getStuckScreamSoundId(actorID)
	if not actorID then return 
		nil 
	end

	local gameActor = global.actorManager:GetActor(actorID)
	if not gameActor or not gameActor:IsPlayer() then
		return nil
	end

	return gameActor:GetSexID() == 0 and AudioKeys.s_man_struck or AudioKeys.s_wom_struck
end

-- 死亡
function AudioProxy:getPlayerDieSoundId(sex)
	if not sex then 
		return nil 
	end

	return sex == 0 and AudioKeys.s_man_die or AudioKeys.s_wom_die
end

function AudioProxy:getClickItemSoundId(std)
	local stdMode = std and std.StdMode
	if not stdMode then 
		return nil 
	end

	local value = ClickItemKeys[stdMode] or ClickItemKeys[-1]
	if type(value) == "function" then
		return value(std.Name)
	end

	return value
end

function AudioProxy:getUseItemSoundId(std)
	local stdMode = std and std.StdMode
	if not stdMode then 
		return nil 
	end

	return stdMode == 0 and AudioKeys.s_click_drug or nil
end

-- 移动
function AudioProxy:getMoveSoundId(action, isRide)
	local mainPlayer = global.gamePlayerController:GetMainPlayer()
	if not mainPlayer then 
		return nil 
	end

	local mapData = global.sceneManager:GetMapData2DPtr()
	if not mapData then 
		return nil 
	end

	-- 基本动作
	local tileInfo = mapData:GetTileInfo(mainPlayer:GetMapX(), mainPlayer:GetMapY())
	if not tileInfo then 
		return nil 
	end

	-- 检查地图属性
	local bidx = bBand(tileInfo.BkImg, 0x7FFF)
	bidx = tileInfo.Area * 10000 + bidx - 1
	local m_nFootStepSound = self:IsInRang(bidx, MoveKeys[1], AudioKeys.s_walk_ground_l)


	bidx = bBand(tileInfo.MidImg, 0x7FFF)
	bidx = bidx - 1
	m_nFootStepSound = self:IsInRang(bidx, MoveKeys[2], m_nFootStepSound)

	
	bidx = bBand(tileInfo.FrImg, 0x7FFF)
	bidx = bidx - 1
	m_nFootStepSound = self:IsInRang(bidx, MoveKeys[3], m_nFootStepSound)
	
	if not m_nFootStepSound then
		return nil
	end

	local nextFootStepSound = m_nFootStepSound + 1
	if action == global.MMO.ACTION_RUN then
		m_nFootStepSound = m_nFootStepSound + 2
		nextFootStepSound = m_nFootStepSound + 1
	elseif action == global.MMO.ACTION_RIDE_RUN then
		m_nFootStepSound = AudioKeys.s_ride_run
		nextFootStepSound = nil
	elseif action == global.MMO.ACTION_WALK and isRide then
		m_nFootStepSound = AudioKeys.s_ride_walk
		nextFootStepSound = nil
	end

	local frameNum = 0.085
	local delayTime = frameNum
	local delayTime2 = frameNum * 4

	return m_nFootStepSound, delayTime, nextFootStepSound, delayTime2
end

function AudioProxy:getMonBornSoundId(clothID)
	if not clothID then 
		return nil 
	end

	return clothID * 10 + 200
end

function AudioProxy:getMonMoveSoundId(clothID)
	if not clothID then 
		return nil 
	end

	if Random(1, 8) ~= 1 then
		return nil
	end

	return clothID * 10 + 201
end

function AudioProxy:getMonDieSoundId(clothID)
	if not clothID then 
		return nil 
	end
	
	return clothID * 10 + 206, 0.085
end

function AudioProxy:getMonAttackSoundId(clothID)
	if not clothID then 
		return nil 
	end

	return clothID * 10 + 202, 0.085 * 2
end

function AudioProxy:IsInRang(num, tabs, defValue)
	local n = #tabs
	for i = 1, n do
		local d = tabs[i]
		if num >= d.min and num <= d.max then
			if d.key then
				return d.key
			end

			local value = d.func and d.func(num)
			if value then
				return value
			end
		end
	end
	return defValue
end

return AudioProxy