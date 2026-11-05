local mmoConstants = 
{
	-- 游戏状态
	GAME_STATE_ACTIVE = "active",             -- 启动
	GAME_STATE_INIT   = "init",               -- 初始化
	GAME_STATE_LOGIN  = "login",              -- 登陆
	GAME_STATE_ROLE   = "role",               -- 选角
	GAME_STATE_WORLD  = "world",              -- 游戏世界

	--operating mode
	OPERATING_MODE_WINDOWS = 1,			 	  -- windows操作模式
	OPERATING_MODE_MOBILE  = 2,				  -- 手机操作模式

	-- map grid size
	MapGridWidth      = 48,                   -- 地图格子宽度
	MapGridHeight     = 32,                   -- 地图格子高度
	DieAddZorder      = -70,

	MAX_CONST                 = 0xFFFFFFFF,

	ACTOR_ID_INVALID          = "0",

	-- 背包层级
	BAG_ITEM_ZORDER					= 1,
	BAG_TEXT_ZORDER					= 2,
	BAG_EFFECT_ZORDER				= 3,


	-- 默认 24位颜色
	DefaultColor          = 0xFFFFFF, 

	--******* HUD 颜色(色织表ID) *******
	HUD_COLOR_DEFAULT     = 255,     -- 默认


	-- 常用资源路径
	PATH_FONT                 = ( "fonts/font.ttf" ),
	PATH_FONT2                = ( "fonts/font2.ttf" ),
	PATH_FONT4                = ( "fonts/font4.ttf"),
	PATH_ST_FONT			  = ( "fonts/stfont.fnt" ),

	PATH_RES_ITEM             = ( "res/item/" ),
	PATH_RES_PUBLIC           = ( "res/public/" ),
	PATH_RES_PUBLIC_WIN32     = ( "res/public_win32/" ),
	PATH_RES_PRIVATE          = ( "res/private/" ),
	PATH_RES_SKILL_ICON       = ( "res/skill_icon/" ),
	PATH_RES_BUFF_ICON        = ( "res/buff_icon/" ),
	PATH_RES_SKILL_ICON_C     = ( "res/skill_icon_c/" ),
	PATH_RES_PLAYER_SHOW      = ( "res/player_show/" ),
	PATH_RES_ALPHA            = ( "res/public/alpha_1px.png" ),
	PATH_RES_HEAD_ICON        = ( "res/Topwear/" ),
	PATH_RES_CUSTOM           = ( "res/" ),
	LOCAL_USERDATA			  = "localUserData/",
	GOODSITEM_SCALE           = 1.3,  -- GOODS ITEM 默认缩放
	GOODSITEM_SCALE_WIN       = 1,

	-- 角色类型 type
	ACTOR_NONE                = -1,
	ACTOR_PLAYER              = 0,
	ACTOR_MONSTER             = 50,
	ACTOR_NPC                 = 100,
	ACTOR_DROPITEM            = 150,
	ACTOR_SEFFECT             = 200,
	--
	ACTOR_COLLECTION          = 250,
	ACTOR_HERO                = 400,

	ACTOR_SUBTYPE_NONE        = -1,    -- 未知
	ACTOR_SUBTYPE_NORMAL      = 1,    -- 普通
	ACTOR_SUBTYPE_ELITE       = 2,    -- 精英
	ACTOR_SUBTYPE_BOSS        = 3,    -- BOSS

	-- 角色细分种族
	ACTOR_RACE_NONE           = -1,   -- 未知
	ACTOR_RACE_NET_PLAYER     = 0,    -- 网络玩家
	ACTOR_RACE_HERO           = 1,    -- 英雄
	ACTOR_RACE_PET            = 5,    -- 宝宝
	ACTOR_RACE_DEFENDER       = 11,   -- 守卫
	ACTOR_RACE_NPC            = 50,   -- NPC
	ACTOR_RACE_HUMANOID       = 150,  -- 人形怪
	ACTOR_RACE_ESCORT         = 87,   -- 镖车
	ACTOR_RACE_PICKUPSPRITE   = 88,   -- 拾取小精灵
	ACTOR_RACE_COLLECTION     = 300,  -- 采集物

	-- 服务器 race
	ACTOR_SERVER_RACE_KNIEF   = 11,   	-- 服务器下发 race  大刀
	ACTOR_SERVER_RACE_FOLLOW_DOG = 113,	-- 趴狗
	ACTOR_SERVER_RACE_FOLLOW_DOG1= 140,
	ACTOR_SERVER_RACE_FOLLOW_DOG2= 142,
	ACTOR_SERVER_RACE_FOLLOW_DOG3= 144,
	ACTOR_SERVER_RACE_FIGHT_DOG  = 114,	-- 站狗
	ACTOR_SERVER_RACE_FIGHT_DOG1 = 141,
	ACTOR_SERVER_RACE_FIGHT_DOG2 = 143,
	ACTOR_SERVER_RACE_FIGHT_DOG3 = 145,

	-- actor 外观改变带的类型
	ACTOR_FTCHANGE_CLOTH      = 0,    -- 衣服
	ACTOR_FTCHANGE_WEAPON     = 1,    -- 武器
	ACTOR_FTCHANGE_CAP        = 13,   -- 斗笠
	ACTOR_FTCHANGE_SHIELD     = 16,   -- 盾牌
	ACTOR_FTCHANGE_CLOTH_EFF  = 50,   -- 衣服特效
	ACTOR_FTCHANGE_WEAPON_EFF = 51,   -- 武器特效
	ACTOR_FTCHANGE_TEAMSTATE  = 100,  -- 组队状态
	ACTOR_FTCHANGE_HAIR       = 101,  -- 发型
	ACTOR_FTCHANGE_SEX        = 102,  -- 性别

	--******* actor属性 类型 *******
	ACTOR_ATTR_HUDTITLE             = 2,              -- HUD title
	ACTOR_ATTR_HUDICONS             = 3,              -- HUD icons
	ACTOR_ATTR_HUDPARAM             = 4,              -- HUD param
	ACTOR_ATTR_PICK                 = 6,              -- 是否是可拾取道具
	ACTOR_ATTR_DIR                  = 13,             -- 方向
	ACTOR_ATTR_FEATURE              = 14,             -- 外观

	-- effect actor type
	EFFECT_TYPE_NORMAL        = 1,
	EFFECT_TYPE_FIRE          = 2,    -- 火墙
	EFFECT_TYPE_MINING_HIT    = 3,    -- 土(静态特效)(ps: 以前是挖矿)
	EFFECT_TYPE_PORTAL        = 4,    -- 传送门
	EFFECT_TYPE_SAFE          = 5,    -- 安全区
	EFFECT_TYPE_EMPTY         = 6,    -- 未使用 (禁锢(增加动态阻挡))
	EFFECT_TYPE_SFX           = 7,    -- 指定特效ID
	EFFECT_TYPE_MAX           = 7,

	-- 角色朝向
	ORIENT_U                  = 0,
	ORIENT_RU                 = 1,
	ORIENT_R                  = 2,
	ORIENT_RB                 = 3,
	ORIENT_B                  = 4,
	ORIENT_LB                 = 5,
	ORIENT_L                  = 6,
	ORIENT_LU                 = 7,
	ORIENT_COUNT			  = 8,
	ORIENT_INVAILD            = 0xff,

	-- 角色动作
	ACTION_INVALID            = 0xFF,
	ACTION_IDLE               = 0,
	ACTION_WALK               = 1,
	ACTION_ATTACK             = 2,       
	ACTION_SKILL              = 3,    
	ACTION_DIE                = 4,    
	ACTION_STUCK              = 5,
	ACTION_RUN                = 6,
	ACTION_BORN               = 7,
	ACTION_READY              = 8,
	ACTION_MINING             = 9,
	ACTION_SITDOWN            = 10,
	ACTION_DEATH              = 11,
	ACTION_CHANGESHAPE        = 14, -- 变身
	ACTION_TURN               = 15, -- 转身
	ACTION_CAVE               = 16, -- 钻回洞穴
	ACTION_RIDE_RUN           = 17,
	ACTION_UNKNOWN1           = 18, -- 服务器触发怪物动作1
	ACTION_UNKNOWN2           = 19, -- 服务器触发怪物动作2
	ACTION_UNKNOWN3           = 20, -- 服务器触发怪物动作3
	ACTION_DASH               = 21, -- 野蛮冲撞
	ACTION_ONPUSH             = 22, -- 被野蛮
	ACTION_DASH_WAITING       = 23, -- 野蛮等待
	ACTION_TELEPORT           = 24, -- 瞬移
	ACTION_IDLE_LOCK          = 25, -- 站着等待
	ACTION_YTPD               = 26, -- 倚天辟地
	ACTION_ZXC                = 27, -- 追心刺
	ACTION_SJS                = 28, -- 三绝杀
	ACTION_DYZ                = 29, -- 断岳斩
	ACTION_HSQJ               = 30, -- 横扫千军
	ACTION_FWJ                = 31, -- 凤舞祭
	ACTION_JLB                = 32, -- 惊雷爆
	ACTION_BTXD               = 33, -- 冰天雪地
	ACTION_SLP                = 34, -- 双龙破
	ACTION_HXJ                = 35, -- 虎啸诀
	ACTION_BGZ                = 36, -- 八卦掌
	ACTION_SYZ                = 37, -- 三焰咒
	ACTION_WJGZ               = 38, -- 万剑归宗
	ACTION_DASH_FAIL 		  = 39, -- 野蛮失败的撞墙动作
	ACTION_SBYS               = 40, -- 十步一杀

	ACTION_ASSASSIN_RUN       = 41, -- 刺客跑步
	ACTION_ASSASSIN_SNEAK     = 42, -- 刺客潜行
	ACTION_ASSASSIN_SMITE     = 43, -- 刺客重击
	ACTION_ASSASSIN_SKILL     = 44, -- 刺客施法
	ACTION_ASSASSIN_SY        = 45, -- 刺客霜月
	ACTION_ASSASSIN_UNKNOWN   = 46, -- 刺客未知动作 
	ACTION_ASSASSIN_XFT       = 47, -- 旋风腿
	ACTION_JY                 = 48, -- 箭雨1
	ACTION_JY2                = 49, -- 箭雨2
	ACTION_TSZ                = 50, -- 推山掌
	ACTION_XLFH               = 51, -- 降龙伏虎

	ACTION_MAX                = 51,

	-- 角色动画
	ANIM_INVALID        = 0xFF,
	ANIM_DEFAULT        = 0,          -- npc、skill、sfx default act:idle
	ANIM_IDLE           = 0,
	ANIM_WALK           = 1,
	ANIM_ATTACK         = 2,
	ANIM_SKILL          = 3,
	ANIM_DIE            = 4,  -- 死亡
	ANIM_RUN            = 5,
	ANIM_SHOWSTAND      = 6,  -- 内观（废弃）
	ANIM_STUCK          = 7,  -- 受击
	ANIM_SITDOWN        = 8,  -- 采集
	ANIM_BORN           = 9,  -- 出生
	ANIM_MINING         = 10, -- 挖矿
	ANIM_READY          = 11, -- 预备
	ANIM_CHANGESHAPE    = 12, -- 变身
	ANIM_DEATH          = 13, -- 挖完的尸体
	ANIM_UNKNOWN1       = 14, -- 服务器触发怪物动作1
	ANIM_UNKNOWN2       = 15, -- 服务器触发怪物动作2
	ANIM_UNKNOWN3       = 16, -- 服务器触发怪物动作3
	ANIM_RIDE_IDLE      = 17, -- 骑马等待
	ANIM_RIDE_WALK      = 18, -- 骑马走
	ANIM_RIDE_RUN       = 19, -- 骑马跑
	ANIM_RIDE_STUCK     = 20, -- 骑马受击
	ANIM_RIDE_DIE       = 21, -- 骑马死亡
	ANIM_YTPD           = 22, -- 倚天辟地
	ANIM_ZXC            = 23, -- 追心刺
	ANIM_SJS            = 24, -- 三绝杀
	ANIM_DYZ            = 25, -- 断岳斩
	ANIM_HSQJ           = 26, -- 横扫千军
	ANIM_FWJ            = 27, -- 凤舞祭
	ANIM_JLB            = 28, -- 惊雷爆
	ANIM_BTXD           = 29, -- 冰天雪地
	ANIM_SLP            = 30, -- 双龙破
	ANIM_HXJ            = 31, -- 虎啸诀
	ANIM_BGZ            = 32, -- 八卦掌
	ANIM_SYZ            = 33, -- 三焰咒
	ANIM_WJGZ           = 34, -- 万剑归宗
	ANIM_ASSASSIN_RUN       = 35, -- 刺客跑步
	ANIM_ASSASSIN_SNEAK     = 36, -- 刺客潜行
	ANIM_ASSASSIN_SMITE     = 37, -- 刺客重击
	ANIM_ASSASSIN_SKILL     = 38, -- 刺客施法
	ANIM_ASSASSIN_SY        = 39, -- 刺客霜月
	ANIM_ASSASSIN_UNKNOWN   = 40, -- 刺客未知动作 
	ANIM_ASSASSIN_XFT       = 41, -- 旋风腿
	ANIM_JY                 = 42, -- 箭雨1
	ANIM_JY2                = 43, -- 箭雨2
	ANIM_TSZ                = 44, -- 推山掌
	ANIM_XLFH           	= 45, -- 降龙伏虎

	ANIM_COUNT              = 46, -- max(ANIM, ORIENT)


	-- 角色外观类型
	P_F_CLOTH                   = 0,
	P_F_WEAPON                  = 1,
	P_F_WINGS                   = 2,
	P_F_SHIELD                  = 3,
	P_F_HAIR                    = 4,
	P_F_MONSTER                 = 5,
	P_F_WEAPON_EFF              = 6,
	P_F_MONSTER_EFF             = 7,
	P_F_MONSTER_CLOTH           = 8,
	P_F_SHIELD_EFF              = 9,
	P_F_LEFT_WEAPON             = 10,
	P_F_LEFT_WEAPON_EFF         = 11,
	P_F_MAX                     = 12,

	-- 角色Node tag
	PLAYER_AVATAR_TAG           = 999,
	PLAYER_BODY_TAG             = 900,
	PLAYER_WEAPON_TAG           = 901,
	PLAYER_WEAPON_EFF_TAG       = 902,
	PLAYER_WINGS_TAG            = 903,
	PLAYER_SHIELD_TAG           = 907,
	PLAYER_HAIR_TAG             = 908,
	PLAYER_MONSTER_TAG          = 897,
	PLAYER_MONSTER_EFF_TAG      = 898,
	PLAYER_MONSTER_CLOTH_TAG    = 899,
	PLAYER_LEFT_WEAPON_TAG      = 909,
	PLAYER_LEFT_WEAPON_EFF_TAG  = 910,
	PLAYER_MOUNT_TAG			= 888,

	-- 角色身上的动画偏移
	PLAYER_AVATAR_OFFSET        = cc.p( -24, 16 ),
	EFFECT_AVATAR_OFFSET        = cc.p( -24, 16 ),

	MONSTER_AVATAR_TAG          = 1000,
	MONSTER_BODY_TAG            = 999,
	MONSTER_MOUNT_TAG			= 888,

	NPC_MOUNT_TAG				= 888,

	DROP_MOUNT_TAG				= 888,

	NETWORK_DELAY               = 0.04,     -- second
	DEFAULT_WALK_TIME           = 0.54,         -- 走
	DEFAULT_RUN_TIME            = 0.60,         -- 跑
	DEFAULT_ATTACK_TIME         = 0.51,         -- 攻击
	DEFAULT_MAGIC_TIME          = 0.60,         -- 施法
	DEFAULT_YTPD_TIME			= 1.30, 		-- 倚天辟地
	DEFAULT_ZXC_TIME			= 0.80, 		-- 追心刺
	DEFAULT_SJS_TIME 			= 1.50, 		-- 三绝杀
	DEFAULT_DYZ_TIME			= 0.60,			-- 断岳斩
	DEFAULT_HSQJ_TIME 			= 1.00, 		-- 横扫千军
	DEFAULT_FWJ_TIME			= 0.60,			-- 凤舞祭
	DEFAULT_JLB_TIME			= 0.90, 		-- 惊雷爆
	DEFAULT_BTXD_TIME			= 0.80,			-- 冰天雪地
	DEFAULT_SLP_TIME			= 1.30,			-- 双龙破
	DEFAULT_HXJ_TIME			= 0.60,			-- 虎啸诀
	DEFAULT_BGZ_TIME			= 1.20, 		-- 八卦掌
	DEFAULT_SYZ_TIME			= 1.20, 		-- 三焰咒
	DEFAULT_WJGZ_TIME           = 1.40,         -- 万剑归宗
	DEFAULT_ASSASSIN_RUN_TIME       = 0.6, -- 刺客跑步
	DEFAULT_ASSASSIN_SNEAK_TIME		= 0.54, -- 刺客潜行
	DEFAULT_ASSASSIN_ATTACK_TIME    = 0.51, -- 刺客攻击
	DEFAULT_ASSASSIN_SKILL_TIME     = 0.6, -- 刺客施法
	DEFAULT_ASSASSIN_SY_TIME        = 1.0, -- 刺客霜月
	DEFAULT_ASSASSIN_UNKNOWN_TIME   = 0.6, -- 刺客未知动作 
	DEFAULT_ASSASSIN_XFT_TIME       = 0.8, -- 旋风腿
	DEFAULT_JY_TIME                 = 0.6, -- 箭雨1
	DEFAULT_JY2_TIME                = 0.8, -- 箭雨2
	DEFAULT_TSZ_TIME                = 0.6, -- 推山掌
	DEFAULT_XLFH_TIME               = 0.8, -- 降龙伏虎
	
	DEFAULT_MUCH_FAST_TIME      = 1.5,            -- 加速后，状态时间变为xxms
	DEFAULT_FAST_TIME_RATE      = 1.1,            -- 加速后，状态时间变为加速倍数

	DEFAULT_MORE_MUCH_FAST_TIME = 0.05, 			-- 加速后，更快的状态时间
	DEFAULT_MORE_MUCH_FAST_RATE = 3, 				-- 加速后，更快的加速倍率

	--******* 动画资源加载返回码 *******
	ANIM_LOAD_SUCCESS   = 0,          -- 动画加载成功
	ANIM_LOAD_CONFIG    = -1,         -- 动画配置错误
	ANIM_LOAD_TEX       = -2,         -- 动画贴图错误
	ANIM_LOAD_FRAME     = -3,         -- 动画帧错误
	ANIM_LOAD_TIMEOUT   = -4,         -- 下载失败
	ANIM_LOAD_OOM       = -5,         -- 内存溢出

	--******* 动画资源加载状态 *******
	LOAD_STATE_UNLOADING = -1,
	LOAD_STATE_LOADING   = 1,
	LOAD_STATE_UNUSED    = 3,
	LOAD_STATE_INUSED    = 4,
	LOAD_STATE_FAILED    = 5,
	LOAD_STATE_FOREVER   = 6,

	--******* 动画序列帧 类型 *******
	SFANIM_TYPE_PLAYER              = 1,              -- 玩家
	SFANIM_TYPE_MONSTER             = 2,              -- 怪物
	SFANIM_TYPE_NPC                 = 3,              -- NPC
	SFANIM_TYPE_SKILL               = 4,              -- 技能
	SFANIM_TYPE_SFX                 = 5,              -- 特效
	SFANIM_TYPE_WEAPON              = 6,              -- 武器
	SFANIM_TYPE_SHIELD              = 7,              -- 盾牌
	SFANIM_TYPE_WINGS               = 8,              -- 翅膀
	SFANIM_TYPE_HAIR                = 9,              -- 发型
	SFANIM_TYPE_NUM                 = 9,              -- max

	ANIM_DEFAULT_INTERVAL			= 0.1,		      -- 动画序列帧默认间隔(无配置时使用)

	-- 画质
	MEMORY_TYPE_L                   = 1,              -- 低端 1G
	MEMORY_TYPE_M                   = 2,              -- 中端 2G
	MEMORY_TYPE_H                   = 3,              -- 高端 4G
	MEMORY_TYPE_X                   = 4,              -- 超高端(无限制)
	----------------------------------------
	STATE_TYPE_STONE 				= 0, 			  -- 石化
	STATE_TYPE_CAVED 				= 1, 			  -- 地下 食人花
	STATE_TYPE_SKELETON 			= 2, 			  -- 死亡 骷髅
	STATE_TYPE_DIE 					= 3, 			  -- 死亡
	----------------------------------------
	--******* 混合模式 *******
	normal_pre_blend_func = { src = gl.ONE, dst = gl.ONE_MINUS_SRC_ALPHA },
	normal_blend_func     = { src = gl.SRC_ALPHA, dst = gl.ONE_MINUS_SRC_ALPHA },
	screen_blend_func     = { src = gl.ONE, dst = gl.ONE_MINUS_SRC_COLOR },
	add_blend_func        = { src = gl.ONE, dst = gl.ONE },
	overlying_blend_func  = { src = gl.SRC_ALPHA, dst = gl.ONE_MINUS_CONSTANT_COLOR },
	ALPHA_PREMULTIPLIED   = { src = gl.ONE, dst = 0x0303},

	--******* shader type *******
	SHADER_TYPE_HIGHTLIGHT    		= 1,
	SHADER_TYPE_GOLDEN        		= 2,
	SHADER_TYPE_SHADOW        		= 3,
	SHADER_TYPE_SLOW          		= 4,
	SHADER_TYPE_OUTLINE       		= 5,
	SHADER_TYPE_ICE           		= 6,
	SHADER_TYPE_HIGHTLIGHT_COVER 	= 7,
	SHADER_TYPE_BLUR          		= 8,
	SHADER_TYPE_ICE_ALPHA_MULTIP 	= 9,
	SHADER_TYPE_ICE_ALPHA_ENHANCE 	= 12,

	-- picker type
	PICK_NONE                   = 0xFFFFFFFF,
	PICK_ACTOR_PLAYER           = 0,            -- 玩家
	PICK_ACTOR_NPC              = 1,            -- NPC
	PICK_ACTOR_MONSTER          = 2,            -- 怪物
	PICK_MAP_GRID               = 3,            -- 场景grid
	PICK_ACTOR_COLLECTION       = 4,            -- 采集物
	PICK_ACTOR_CORPSE           = 5,            -- 尸体


	-- input state
	INPUT_STATE_IDLE            = 1,            -- idle
	INPUT_STATE_LAUNCH          = 2,            -- launch
	INPUT_STATE_MOVE            = 3,            -- move
	INPUT_STATE_CORPSE          = 4,            -- dig corpse
	INPUT_STATE_MAX             = 5,

	-- input priority
	INPUT_PRIORITY_SYSTEM      = 1,            -- system input
	INPUT_PRIORITY_ROBOT       = 2,            -- robot input
	INPUT_PRIORITY_USER        = 3,            -- user input

	-- launch priority
	LAUNCH_PRIORITY_SYSTEM      = 1,            -- system input
	LAUNCH_PRIORITY_ROBOT       = 2,            -- robot input
	LAUNCH_PRIORITY_USER        = 3,            -- user input

	-- launch type
	LAUNCH_TYPE_USER            = 1,            -- 主动释放
	LAUNCH_TYPE_AUTO            = 2,            -- 挂机释放
	LAUNCH_TYPE_LOCK            = 3,            -- 锁定目标释放
	LAUNCH_TYPE_ATTACK          = 4,            -- 强攻释放


	-- auto move type
	AUTO_MOVE_TYPE_TARGET       = 1,            -- 寻找目标   
	AUTO_MOVE_TYPE_MINIMAP      = 2,            -- 小地图       
	AUTO_MOVE_TYPE_CHAT         = 3,            -- 聊天框   
	AUTO_MOVE_TYPE_SERVER       = 4,            -- 服务器通知   

	AUTO_MOVE_START             = 1,            -- 自动寻路开始
	AUTO_MOVE_ABORT             = 2,            -- 自动寻路中断
	AUTO_MOVE_FINISH            = 3,            -- 自动寻路结束


	--******* auto index *******
	AUTO_FIND_TARGET_NONE        = -1,              -- 自动寻路目标 - 无


	--******* auto target state *******
	AUTO_TARGET_STATE_BEGIN      = 1,
	AUTO_TARGET_STATE_RUNNING    = 2,
	AUTO_TARGET_STATE_END        = 3,


	-- camera param
	CAMERA_FAR   = 1000,
	CAMERA_NEAR  = 10,

	CAMERA_Z_MIN     = 250,
	CAMERA_Z_DEFAULT = 554,
	CAMERA_Z_MAX     = 700,

	VIEW_SCALE_MIN   = 0.7,

	-- scene zOrder
	NODE_NUM                          = 21,
	NODE_ROOT                         = 0,         -- 10000
	NODE_GAME_WORLD                 = 1,         -- 10023
		NODE_MAP                      = 2,         -- 10003
		NODE_MAP_SLICE              = 3,         -- 10006
		NODE_SKILL_BEHIND             = 4,         -- 10034
		NODE_ACTOR                    = 5,         -- 10004
		NODE_ACTOR_SHADOW           = 6,         -- 10007
		NODE_ACTOR_CLONE_SHADOW     = 7,         -- 10030
			NODE_ACTOR_NPC_SHADOW     = 8,         -- 10031
			NODE_ACTOR_MONSTER_SHADOW = 9,         -- 10032
			NODE_ACTOR_PLAYER_SHADOW  = 10,        -- 10033
		NODE_ACTOR_SFX_BEHIND       = 11,        -- 10016
		NODE_ACTOR_SPRITE           = 12,        -- 10008
		NODE_ACTOR_SFX_FRONT        = 13,        -- 10010
		NODE_MAP_OBJ                  = 14,        -- 10035
		NODE_SKILL                    = 15,        -- 10015
		NODE_ACTOR_HUD                = 16,        -- 10009
		NODE_DAMAGE                   = 17,        -- 10017
	NODE_UI                         = 18,        -- 10005
		NODE_UI_NORMAL                = 19,        -- 10011
		NODE_UI_TOPMOST               = 20,        -- 10012

	-- 主界面层次关系
	MAIN_NODE_SUI_BOTTOM_LT   = "MAIN_NODE_SUI_BOTTOM_LT",
	MAIN_NODE_SUI_BOTTOM_RT   = "MAIN_NODE_SUI_BOTTOM_RT",
	MAIN_NODE_SUI_BOTTOM_LB   = "MAIN_NODE_SUI_BOTTOM_LB",
	MAIN_NODE_SUI_BOTTOM_RB   = "MAIN_NODE_SUI_BOTTOM_RB",

	MAIN_NODE_BOTTOM      = "MAIN_NODE_BOTTOM",
	MAIN_NODE_CENTER      = "MAIN_NODE_CENTER",
	MAIN_NODE_TOP         = "MAIN_NODE_TOP",

	MAIN_NODE_SUI_LT      = "MAIN_NODE_SUI_LT",
	MAIN_NODE_SUI_RT      = "MAIN_NODE_SUI_RT",
	MAIN_NODE_SUI_LB      = "MAIN_NODE_SUI_LB",
	MAIN_NODE_SUI_RB      = "MAIN_NODE_SUI_RB",
	MAIN_NODE_SUI_LM      = "MAIN_NODE_SUI_LM",
	MAIN_NODE_SUI_TM      = "MAIN_NODE_SUI_TM",
	MAIN_NODE_SUI_RM      = "MAIN_NODE_SUI_RM",
	MAIN_NODE_SUI_BM      = "MAIN_NODE_SUI_BM",

	MAIN_NODE_SUI_TOP_LT  = "MAIN_NODE_SUI_TOP_LT",
	MAIN_NODE_SUI_TOP_RT  = "MAIN_NODE_SUI_TOP_RT",
	MAIN_NODE_SUI_TOP_LB  = "MAIN_NODE_SUI_TOP_LB",
	MAIN_NODE_SUI_TOP_RB  = "MAIN_NODE_SUI_TOP_RB",
	MAIN_NODE_CHAT_MAIN   = "MAIN_NODE_CHAT_MAIN",
	MAIN_NODE_CHAT_MINI   = "MAIN_NODE_CHAT_MINI",
	MAIN_NODE_GUIDE       = "MAIN_NODE_GUIDE",


	--******* 音频类型 ( 技能音效在动画配置文件中 ) *******
	SND_TYPE_SKILL_LUAUNCH              = 1,     -- 释放技能

	SND_TYPE_SKILL_ATTACK               = 4,     --普攻
	SND_TYPE_MONEY                      = 5,     --货币变化
	SND_TYPE_LOGIN_DOOR                 = 6,     --登陆界面 开门
	SND_TYPE_LOGIN_SELECTONE            = 7,     --登陆界面 选择角色  
	SND_TYPE_FLY_OUT                    = 8,     --飞出视野
	SND_TYPE_FLY_IN                     = 9,     --飞入视野
	SND_TYPE_STUCK_WEAPON               = 10,    --受击 攻击方武器的声音
	SND_TYPE_STUCK                      = 11,    --受击 碰撞的声音
	SND_TYPE_SCREAM                     = 12,    --受击 受害者发出的声音
	SND_TYPE_PLAYER_DIE                 = 13,    --玩家死亡
	SND_TYPE_CLICK_ITEM                 = 15,    --点击道具
	SND_TYPE_USE_ITEM                   = 16,    --使用道具
	SND_TYPE_ACT_MOVE                   = 17,    --主角移动
	SND_TYPE_MON_BORN                   = 18,    --怪物出生
	SND_TYPE_MON_MOVE                   = 19,    --怪物移动
	SND_TYPE_MON_ATTACK                 = 20,    --怪物攻击
	SND_TYPE_MON_DIE                    = 21,    --怪物死亡
	SND_TYPE_UPGRADE                    = 24,    -- 升级
	SND_TYPE_MINING                     = 25,    -- 挖矿
	SND_TYPE_MINING_DROP                = 26,    -- 挖矿 起灰
	SND_TYPE_LAYER_CLICK                = 27,    -- 界面 点击 
	SND_TYPE_LAYER_CLOSE                = 28,    -- 界面 点×关闭
	SND_TYPE_BTN_CLICK                  = 29,    -- 指定按钮 点击 
	SND_TYPE_FLY_IN_HERO                = 30,    --英雄出生音效
	SND_TYPE_FLY_OUT_HERO               = 31,    --英雄收回音效
	SND_TYPE_OPEN_BOX                   = 32,    -- 钥匙开宝箱音效
	SND_TYPE_FLASH_BOX                  = 33,    -- 宝箱转圈到个点位音效

	SND_TYPE_BGM_LOGIN                  = 101,     --BGM 登陆界面
	SND_TYPE_BGM_SELECT                 = 102,     --BGM 选角界面
	SND_TYPE_BGM_DIE                    = 103,     --BGM 死亡
	SND_TYPE_BGM_MAP                    = 104,     --BGM 地图

	SUD_TYPE_NORMAL                     = 999,    -- 普通音效

	--******* sfx *******
	SFX_PORTAL                    = 7002,            -- 传送中
	SFX_MINE                      = 4058,            -- 矿标志
	SFX_SELECT_PLAYER             = 4008,            -- 选中玩家
	SFX_SELECT_MONSTER            = 4008,            -- 选中怪物
	SFX_UPGRADE                   = 4012,            -- 升级
	SFX_UPGRADE_BEHIND            = 4013,            -- 升级 在后面
	SFX_FLY_IN                    = 7,               -- 传回
	SFX_FLY_IN_2                  = 58,              -- 传回 2
	SFX_FLY_OUT                   = 6,               -- 传走
	SFX_FLY_OUT_2                 = 59,              -- 传走 2
	SFX_MONSTER_BORN1             = 2207,            -- 僵尸出生洞
	SFX_TOUCH_VIEW                = 5011,            -- 点击屏幕
	SFX_CURSOR					  = 5012,			 -- 点地板
	SFX_INTERNAL_LV_UP			  = 5006,			 -- 内功等级提升
	SFX_DROP_ITEM_JP			  = 5017,		     -- 掉落物极品特效
	SFX_DROP_ITEM_NORAML		  = 4508,		     -- 掉落物默认特效
	SFX_FIND_PATH_ARROW			  = 5013,			 -- 寻路箭头特效





	--******* HUD *******
	HUD_TYPE_SPRITE               = 0,              -- HUD 类型:sprite
	HUD_TYPE_BATCH_LABEL          = 1,              -- HUD 类型:batch label
	HUD_TYPE_ANIM                 = 2,
	HUD_TYPE_TIPS                 = 3,              -- HUD 类型:一些触发挂接节点 [人物头顶喊话、摊位名]
	HUD_TYPE_MAX                  = 3,


	--******* HUD batch label index *******
	HUD_LABEL_NAME                = 1,              -- 名字
	HUD_LABEL_GUILD               = 2,              -- 工会名字
	HUD_LABEL_HP                  = 3,              -- 血量
	HUD_LABEL_PRE_NAME0			  = 6,				-- 预留名字前缀0 名字同行
	HUD_LABEL_PRE_NAME1           = 7,              -- 预留名字前缀1
	HUD_LABEL_PRE_NAME2           = 8,              -- 预留名字前缀2
	HUD_LABEL_PRE_NAME3           = 9,              -- 预留名字前缀3
	HUD_LABEL_PRE_NAME4           = 10,             -- 预留名字前缀4
	HUD_LABEL_PRE_NAME5           = 11,             -- 预留名字前缀5
	HUD_LABEL_PRE_NAME6           = 12,             -- 预留名字前缀6
	HUD_LABEL_PRE_NAME7           = 13,             -- 预留名字前缀7
	HUD_LABEL_PRE_NAME8           = 14,             -- 预留名字前缀8
	HUD_LABEL_PRE_NAME9           = 15,             -- 预留名字前缀9
	HUD_LABEL_PRE_NAME10          = 16,             -- 预留名字前缀10
	HUD_LABEL_PRE_NAME11          = 17,             -- 预留名字前缀11
	HUD_LABEL_PRE_NAME12          = 18,             -- 预留名字前缀12
	HUD_LABEL_TITLE_1             = 19,             -- 称号1
	HUD_LABEL_TITLE_2             = 20,             -- 称号2
	HUD_LABEL_TITLE_3             = 21,             -- 称号3

	--******* HUD sprite index *******
	HUD_SPRITE_HP                 = 1,              -- 血条
	HUD_SPRITE_HP_BG              = 2,              -- 血条背景
	HUD_SPRITE_MP                 = 3,              -- 蓝条
	HUD_SPRITE_MP_BG              = 4,              -- 蓝条背景
	HUD_SPRITE_NG                 = 5,              -- 内功
	HUD_SPRITE_NG_BG              = 6,              -- 内功背景
	HUD_SPRITE_TITLE_1            = 7,              -- 称号1
	HUD_SPRITE_TITLE_2            = 8,              -- 称号2
	HUD_SPRITE_TITLE_3            = 9,              -- 称号3
	HUD_SPRITE_TEXT_BG            = 10,              -- 说话内容背景图
	HUD_SPRITE_TEXT_BG_CORNER     = 11,              -- 说话内容背景图角标
	HUD_SPRITE_BOOTH_NAME_BG      = 12,             -- 摆摊名 背景图
	HUD_SPRITE_ICON_1             = 13,             -- 顶戴
	HUD_SPRITE_ICON_2             = 14,             -- 顶戴
	HUD_SPRITE_ICON_3             = 15,             -- 顶戴
	HUD_SPRITE_ICON_4             = 16,             -- 顶戴
	HUD_SPRITE_ICON_5             = 17,             -- 顶戴
	HUD_SPRITE_ICON_6             = 18,             -- 顶戴
	HUD_SPRITE_ICON_7             = 19,             -- 顶戴
	HUD_SPRITE_ICON_8             = 20,             -- 顶戴
	HUD_SPRITE_ICON_9             = 21,             -- 顶戴
	HUD_SPRITE_ICON_10            = 22,             -- 顶戴
	HUD_SPRITE_ICON_11            = 23,             -- 顶戴 盒子专用
	HUD_COUNT_MAX                 = 24,             -- one type hud max count


	--******* HUD BAR index *******
	HUDHPUI_BAR                   = 1,
	HUDHPUI_BORDER                = 2,
	HUDMPUI_BAR                   = 3,
	HUDMPUI_BORDER                = 4,
	HUDNGUI_BAR                   = 5,
	HUDNGUI_BORDER                = 6,


	--******* HUD TEXT index *******
	HUD_TEXT_SPEECH               = 1,              -- 说话内容
	HUD_LABEL_BOOTH_NAME          = 4,              -- 封号名称 - 摊位名字

	--******* HUD tips index 特效*******
	HUD_NODE_TITLE_1               = 1,              -- 顶戴花翎1图片挂接节点
	HUD_NODE_TITLE_2               = 2,              -- 顶戴花翎2图片挂接节点
	HUD_NODE_TITLE_3               = 3,              -- 顶戴花翎3图片挂接节点
	HUD_NODE_TITLE_4               = 4,              -- 顶戴花翎4图片挂接节点
	HUD_NODE_TITLE_5               = 5,              -- 顶戴花翎5图片挂接节点
	HUD_NODE_TITLE_6               = 6,              -- 顶戴花翎6图片挂接节点
	HUD_NODE_TITLE_7               = 7,              -- 顶戴花翎7图片挂接节点
	HUD_NODE_TITLE_8               = 8,              -- 顶戴花翎8图片挂接节点
	HUD_NODE_TITLE_9               = 9,              -- 顶戴花翎9图片挂接节点
	HUD_NODE_TITLE_10              = 10,             -- 顶戴花翎10图片挂接节点
	HUD_NODE_TITLE_11              = 11,             -- 顶戴花翎11图片挂接节点  盒子顶戴

	--******* HUD sprite ID *******
	HP_BG_SPRITE_ID               = 9990,           -- 血条背景资源ID
	HP_SPRITE_ID                  = 9991,           -- 血条资源ID
	HP_MAIN_SPRITE_ID  			  = 9994, 			-- 血条资源ID  主玩家
	MP_SPRITE_ID                  = 9992,           -- 蓝条资源ID
	NG_SPRITE_ID				  = 9993,			-- 内功资源ID
	HUD_SPRITE_BG                 = 9980,           -- 九宫格拉伸背景图
	HUD_SPRITE_BG_CORNER          = 9981,           -- 背景图角标
	HUD_SPRITE_DEFAULT_ID         = 9999,           -- hud sprite 默认图片ID

	--******* HUD offset *******
	HUD_OFFSET_1                  = cc.p( -16, 50 ),
	HUD_OFFSET_BG_1               = cc.p( -16, 50 ),
	HUD_OFFSET_2                  = cc.p( -16, 50 ),
	HUD_OFFSET_BG_2               = cc.p( -16, 50 ),
	HUD_OFFSET_3                  = cc.p( -16, 47 ),
	HUD_OFFSET_BG_3               = cc.p( -16, 47 ),
	HUD_OFFSET_HORSE              = cc.p( 0, 15 ), -- 骑马的HUD偏移
	HUD_OFFSET_HORSE_LABEL        = cc.p( 0, 15 ), -- 骑马的HUD Label偏移

	--******* HUD Y offset *******
	HUD_DROPITEM_OFFSET_Y					= 10,		-- 掉落物Y偏移

	--******* modules index *******                 -- 控制 C++ 一些模块的开关
	Modules_Index_Enable_Splash             = 0,       -- 闪屏开关
	Modules_Index_Enable_Disconnect_Msg     = 1,       -- 断线重连 dispatch
	Modules_Index_Enable_Check_Heart_Beat   = 2,       -- 检测服务器心跳
	Modules_Index_Enable_ETC2               = 4,       -- ETC2 support
	Modules_Index_Value_Game_Type           = 5,       -- game type
	Modules_Index_Scene_Tex_Type            = 6,       -- scene tex sample type
	Modules_Index_Launch_Game_Flag          = 7,       -- launch game file
	Modules_Index_SPLASH_Flag               = 8,       -- splash flag
	Modules_Index_BoxLogin_Flag             = 9,       -- box login flag
	Modules_Index_Scene_Tiles_Flag          = 10,      -- scene tiles flag
	Modules_Index_Scene_SMTiles_Flag        = 11,      -- scene smtiles flag
	Modules_Index_Scene_Objects_Flag        = 12,      -- scene objects flag
	Modules_Index_LuaDownloader_Flag        = 13,      -- lua downloader flag
	Modules_Index_Scene_Artifact_Flag       = 14,      -- scene Artifact flag
	Modules_Index_Scene_Blend_Flag          = 15,      -- scene Blend flag
	Modules_Index_Net_BatchMsg              = 16,      -- -1 网络消息批量处理
	Modules_Index_Protobuf_Pbc              = 17,      -- 1 是否接入protobuf
	Modules_Index_NetClient_Free            = 18,      -- 消息析构是否可用
	Modules_Index_Cpp_Version            	= 19,      -- c++版本

	----c++版本---------
	CPP_VERSION_LABEL_TTF 					= 1,	  -- 修复ttf宋体崩溃  ttf显示优化
	--------------------

	--******* HAM type( 玩家攻击模式 ) *******
	HAM_ALL                           = 0,          -- 全体攻击模式
	HAM_PEACE                         = 1,          -- 和平
	HAM_DEAR                          = 2,          -- 夫妻
	HAM_MASTER                        = 3,          -- 师徒
	HAM_GROUP                         = 4,          -- 组队
	HAM_GUILD                         = 5,          -- 公会
	HAM_SHANE                         = 6,          -- 善恶
	HAM_NATION                        = 7,          -- 国家
	HAM_CAMP                          = 8,          -- 阵营
	HAM_SERVER                        = 9,          -- 区服

	--******* buff ID *******
	BUFF_ID_POISONING_GREEN           = 0,            -- 绿毒
	BUFF_ID_POISONING_RED             = 1,            -- 红毒
	BUFF_ID_POISONING_PURPLE  		  = 3,            -- 紫毒
	BUFF_ID_FREEZED_GRAY              = 5,            -- 麻痹
	BUFF_ID_CLOAKING                  = 8,            -- 隐身
	BUFF_ID_ANGEL_SHIELD              = 9,            -- 神圣战甲术
	BUFF_ID_GHOST_SHIELD              = 10,           -- 幽灵盾
	BUFF_ID_MAGIC_SHIELD              = 11,           -- 魔法盾
	BUFF_ID_STONE_MODE                = 12,           -- 石化状态(怪物)
	BUFF_ID_WUJI_SHIELD               = 1050,         -- 无极真气
	BUFF_ID_ICE                       = 1113,         -- 冰冻
	BUFF_ID_COBWEB                    = 13,           -- 蛛网
	BUFF_ID_COLORS                    = 1123,         -- 变色
	BUFF_ID_ONDASH_IDLE               = 69,           -- 锁定 被野蛮
	BUFF_ID_UN_IMPRISON               = 70,           -- 防禁锢
	BUFF_ID_UN_ATTACK                 = 71,           -- 禁止攻击
	BUFF_ID_COLOR                     = 2021,         -- 人物变色
	BUFF_ID_POISON_TRANSPARENT        = 2022,         -- 放大透明虚影
	BUFF_ID_THUNDER_SWORD             = 21,           -- 雷霆剑法
	BUFF_ID_SNEAK 					  = 80, 		  -- 潜行
	BUFF_ID_HORSE 					  = 9999, 	  	  -- 骑马

	ServerTime_Sub                    = 0,            -- 服务器和本地的时间差

	--******* 帧率类型 *******
	FRAME_RATE_TYPE_HIGH            = 1,              -- 高帧率
	FRAME_RATE_TYPE_LOW             = 2,              -- 低帧率


	--******* 玩家关系分类 *******
	RS_ENEMY                        = 1,              -- 敌人
	RS_NO                           = 2,              -- 非敌人,没有关系
	RS_GROUP                        = 3,              -- 同队伍
	RS_GUILD                        = 4,              -- 同行会
	RS_CAMP                         = 5,              -- 同阵营
	RS_ALLIANCE                     = 6,              -- 同盟
	RS_NATION                       = 7,              -- 国家
	RS_SERVER                       = 8,              -- 区服
	RS_DEAR 						= 9, 			  -- 夫妻
	RS_MASTER 						= 10, 			  -- 师徒

	--******* special skill id ******
	SKILL_INDEX_BASIC               = 0,              -- 基础攻击
	SKILL_INDEX_SDS                 = 6,              -- 施毒术
	SKILL_INDEX_GSJS                = 7,              -- 攻杀剑术
	SKILL_INDEX_CSJS                = 12,             -- 刺杀剑术
	SKILL_INDEX_ZHKL                = 17,             -- 召唤骷髅
	SKILL_INDEX_LHJF                = 26,             -- 烈火剑法
	SKILL_INDEX_YMCZ                = 27,             -- 野蛮冲撞
	SKILL_INDEX_ZHSS                = 30,             -- 召唤神兽
	SKILL_INDEX_LYJF                = 42,             -- 龙影剑法
	SKILL_INDEX_LTJF                = 43,             -- 雷霆剑法
	SKILL_INDEX_ZRJF                = 56,             -- 逐日剑法
	SKILL_INDEX_KTZ                 = 66,             -- 开天斩
	SKILL_INDEX_ZHJS                = 81,             -- 纵横剑术
	SKILL_INDEX_SBYS                = 82,             -- 十步一杀
	SKILL_INDEX_ZXC					= 100,			  -- 追心刺
    SKILL_INDEX_DIG                 = 999,            -- 挖矿技能

	--******* bag and item setting ******
	BAG_ITEM_PANEL_WIDTH            = 500,
	BAG_ITEM_PANEL_HEIGHT           = 320,
	BAG_ROW_MAX_ITEM_NUMBER         = 8,
	MAX_ITEM_NUMBER                 = 40,                        -- 0 - 39

	--  win 32
	BEST_RING_ITEM_WIDTH            = 73,
	BEST_RING_ITEM_HEIGHT           = 73,

	TRADE_ITEM_PANEL_HEIGHT         = 136,
	TRADE_ITEM_PANEL_WIDTH          = 340,
	TRADE_ROW_MAX_ITEM_NUMBER       = 5,
	TRADE_MAX_ITEM_NUMBER           = 10,
	TRADE_ITEM_SIZE_WIDTH           = 67,
	TRADE_ITEM_SIZE_HEIGHT          = 68,

	TRADE_ITEM_PANEL_HEIGHT_WIN         = 84,
	TRADE_ITEM_PANEL_WIDTH_WIN          = 210,
	TRADE_ITEM_SIZE_WIDTH_WIN           = 42,
	TRADE_ITEM_SIZE_HEIGHT_WIN          = 42,

	NPC_STORE_LIST_LENGTH           = 10,             --NPC商店每页长度

	NPC_STORAGE_MAX_PAGE            = 48,

	STALL_MAX_PAGE             		= 20,	--摆摊相关
	STALL_ITEM_WIDTH           		= 62,
	STALL_ITEM_HEIGHT          		= 64,
	STALL_ITEM_PANEL_WIDTH     		= 316,
	STALL_ITEM_PANEL_HEIGHT    		= 256,
	STALL_ROW_MAX_ITEM_NUMBER  		= 5,

	STALL_ITEM_WIDTH_WIN       		= 40.5,
	STALL_ITEM_HEIGHT_WIN      		= 42,
	STALL_ITEM_PANEL_WIDTH_WIN 		= 209,
	STALL_ITEM_PANEL_HEIGHT_WIN		= 168,


	MAIN_PLAYER_LAYER_BAG   = 100,--交易行查看背包
	MAIN_PLAYER_LAYER_STORAGE   = 101,--交易行查看仓库

	ITEM_FROM_BELONG_EQUIP = 1,
	ITEM_FROM_BELONG_BAG = 2,
	ITEM_FROM_BELONG_QUICKUSE = 3,
	ITEM_FROM_BELONG_STALL = 4,

	ITEM_FROM_BELONG_HEROBAG = 66,
	ITEM_FROM_BELONG_HEROEQUIP = 67,

	ITEM_FROM_BELONG_PETEQUIP = 77,

	MOVE_EVENT_TOUCH_AND_MOUSE_L    =1,
	MOVE_EVENT_MOUSE_R              =-1,

	SELETE_TARGET_TYPE_PICK           = 1,
	SELETE_TARGET_TYPE_FIND           = 2,
	SELETE_TARGET_TYPE_OTHER          = 3,

	SKILL_PRESENT_BASE                = 0,
	SKILL_PRESENT_LAUNCH              = 1,
	SKILL_PRESENT_FLY                 = 2,
	SKILL_PRESENT_HIT                 = 3,

	--内观缩放比例
	PLAYER_LOOKS_SCALE                = 1.44,
	PLAYER_OFFSET_X_WOMEN             = 2,

	QUICK_USE_SIZE                    = 6, -- 分操作系统

	--内观层级
	MODEL_LAYER_Z_BASE                = 1,  -- 裸模
	MODEL_LAYER_Z_CLOTH_EFFECT_UNDER  = 2,  -- 衣服特效底层
	MODEL_LAYER_Z_CLOTH               = 3,  -- 衣服
	MODEL_LAYER_Z_CLOTH_EFFECT_ON     = 4,  -- 衣服特效上层
	MODEL_LAYER_Z_WEAPON_EFFECT_UNDER = 5,  -- 武器特效底层
	MODEL_LAYER_Z_WEAPON              = 6,  -- 武器
	MODEL_LAYER_Z_WEAPON_EFFECT_ON    = 7,  -- 武器特效上层
	MODEL_LAYER_Z_HAIR                = 8,  -- 头发
	MODEL_LAYER_Z_VEIL_EFFECT_UNDER   = 9,  -- 面纱下层
	MODEL_LAYER_Z_VEIL                = 10, -- 面纱
	MODEL_LAYER_Z_VEIL_EFFECT_ON      = 11, -- 面纱上层
	MODEL_LAYER_Z_HEAD_EFFECT_UNDER   = 12, -- 头盔下层
	MODEL_LAYER_Z_HEAD                = 13, -- 头盔
	MODEL_LAYER_Z_HEAD_EFFECT_ON      = 14, -- 头盔上
	MODEL_LAYER_Z_SHIELD_EFFECT_UNDER = 15, -- 盾牌特效下层
	MODEL_LAYER_Z_SHIELD              = 16, -- 盾牌
	MODEL_LAYER_Z_SHIELD_EFFECT_ON    = 17, -- 盾牌特效上层

	CLICK_DOUBLE_TIME                 = 0.3,  -- 双击时间
	PC_TIPS_DELAY_TIME				  = 0.05, -- pc tips 延迟时间 

	-- NPC使用怪物外观ID段
	NPC_MONSTER_ID_PART               = 10000,

	CURSOR_TYPE_NORMAL                = 0,
	CURSOR_TYPE_PK                    = 1,
	CURSOR_TYPE_NPC                   = 2,

	--******* setting idx ******
	SETTING_IDX_PLAYER_NAME           = 1,    -- 人物显名设置
	SETTING_IDX_HP_NUM                = 2,    -- 数字显血设置
	SETTING_IDX_DAMAGE_NUM            = 3,    -- 飘血显示设置
	SETTING_IDX_HP_HUD                = 4,    -- 显示血条设置
	SETTING_IDX_MONSTER_NAME          = 5,    -- 怪物显名设置
	SETTING_IDX_ONE_DOUBLE_ROCKER     = 6,    -- 单双摇杆
	SETTING_IDX_HP_LOW_USE_HCS        = 7,    -- 生命值低于多少使用回城石
	SETTING_IDX_HP_LOW_USE_SJS        = 8,    -- 生命值低于多少使用随机石
	SETTING_IDX_HP_LOW_USE_HY         = 9,    -- 生命值低于多少使用HY
	SETTING_IDX_HP_LOW_USE_SHY        = 10,   -- 生命值低于多少使用SHY
	SETTING_IDX_MP_LOW_USE_LY         = 11,   -- 魔法值低于多少使用LY
	SETTING_IDX_MP_LOW_USE_SHY        = 12,   -- 魔法值低于多少使用SHY
	SETTING_IDX_AUTO_MOVE             = 13,   -- 自动走位
	SETTING_IDX_ALWAYS_ATTACK         = 14,   -- 持续攻击  
	SETTING_IDX_DAODAOCISHA           = 15,   -- 刀刀刺杀  
	SETTING_IDX_AUTO_LIEHUO           = 16,   -- 自动烈火
	SETTING_IDX_GEWEICISHA            = 17,   -- 隔位刺杀
	SETTING_IDX_SMART_BANYUE          = 18,   -- 智能半月
	SETTING_IDX_AUTO_MOFADUN          = 19,   -- 自动魔法盾
	SETTING_IDX_AUTO_FIRE_WALL        = 20,   -- 自动火墙
	SETTING_IDX_AUTO_GROUPSKILL       = 21,   -- 群怪技能
	SETTING_IDX_AUTO_DU               = 22,   -- 自动施毒
	SETTING_IDX_AUTO_YOULINGDUN       = 23,   -- 自动幽灵盾
	SETTING_IDX_AUTO_SSZJS            = 24,   -- 自动神圣战甲术
	SETTING_IDX_HP_LOW_USE_SKILL      = 25,   -- 生命值低于多少使用 技能
	SETTING_IDX_AUTO_SUMMON           = 26,   -- 自动召唤
	SETTING_IDX_BGMUSIC               = 27,   -- BG音乐
	SETTING_IDX_UNSAFE_TIPS           = 28,   -- 残血提示
	SETTING_IDX_CAMERA_ZOOM           = 29,   -- 摄像机zoom设置
	SETTING_IDX_SKILL_NEXT_ATTACK     = 30,   -- 技能接平砍
	SETTING_IDX_NOT_NEED_SHIFT        = 31,   -- pc 免shift
	SETTING_IDX_WINDOW_SMOOTH_VIEW    = 32,   -- PC端平滑模式
	SETTING_IDX_ONLY_NAME             = 33,   -- 只显人名
	SETTING_IDX_PLAYER_JOB_LEVEL      = 34,   -- 主场景显示玩家职业等级模式设置
	SETTING_IDX_EXP_IGNORE            = 35,   -- 经验过滤
	SETTING_IDX_EQUIP_COMPARE         = 36,   -- 装备对比
	SETTING_IDX_MAGIC_LOCK            = 37,   -- 魔法锁定
	SETTING_IDX_AUTO_LAUNCH           = 38,   -- 自动练功
	SETTING_IDX_HIDE_MONSTER_BODY     = 39,   -- 清理尸体
	SETTING_IDX_DU_FU_AUTOCHANGE      = 40,   -- 毒符互换
	SETTING_IDX_BB_ATTACK_WITH        = 41,   -- 宝宝跟随攻击
	SETTING_IDX_NEAR_LIEHUO           = 42,   -- 近身烈火
	SETTING_IDX_BOSS_TIPS             = 46,   -- boss提示
	SETTING_IDX_AUTO_SIMPSKILL        = 47,   -- 单体技能
	SETTING_IDX_DURABILITY_TIPS       = 50,   -- 耐久提示
	SETTING_IDX_AUTO_REPAIR           = 51,   -- 自动修理
	SETTING_IDX_EFFECTMUSIC           = 52,   -- 游戏音乐
	SETTING_IDX_AUTO_KAITIAN          = 53,   -- 自动开天
	SETTING_IDX_AUTO_ZHURI            = 54,   -- 自动逐日
	SETTING_IDX_AUTO_CLOAKING         = 55,   -- 自动隐身
	SETTING_IDX_MOVE_GEWEI_CISHA      = 56,   -- 移动隔位刺杀
	SETTING_IDX_PLAYER_SIMPLE_DRESS   = 57,   -- 人物简装
	SETTING_IDX_MONSTER_SIMPLE_DRESS  = 58,   -- 怪物简装
	SETTING_IDX_AUTO_WJZQ             = 59,   -- 自动无极真气
	SETTING_IDX_ROCKER_CANCEL_ATTACK  = 60,   -- 摇杆取消攻击
	SETTING_IDX_TITLE_VISIBLE         = 61,   -- 显示称号设置
	SETTING_IDX_AUTO_PUT_IN_EQUIP     = 62,   -- 装备自动穿戴读表
	SETTING_IDX_LEVEL_SHOW_NAME_HUD   = 63,   -- 不选中状态,满足等级显示玩家名字HUD
	SETTING_IDX_AUTO_FIGHT_BACK       = 64,   -- 自动反击
	SETTING_IDX_HP_UNIT               = 65,   -- hp血量单位转换
	SETTING_IDX_LAYER_OPACITY         = 66,   -- Layer Opacity
	SETTING_IDX_ROCKER_SHOW_DISTANCE  = 70,   -- 轮盘侧边距离
	SETTING_IDX_SKILL_SHOW_DISTANCE   = 71,   -- 技能侧边距离
	SETTING_IDX_MP_LOW_USE_HCS        = 77,   -- 魔法值低于多少使用回城石
	SETTING_IDX_MP_LOW_USE_SJS        = 78,   -- 魔法值低于多少使用随机石
	SETTING_IDX_AUTO_SHIELD_OF_FORCE  = 99,   -- 武力盾
	SETTING_IDX_AUTO_SHIELD_OF_TAOIST = 100,  -- 道力盾
	SETTING_IDX_FIRE_OPACITY          = 101,  -- 火墙淡化
	SETTING_IDX_FIRE_OWN_HIGHTLIGHT   = 102,  -- 自己火墙高亮（绿色）

	SETTING_IDX_AUTO_ICE_PALM		  = 110,  -- 自动寒冰掌
	SETTING_IDX_AUTO_BLOODTHIRSTY_S   = 111,  -- 自动嗜血术
	SETTING_IDX_AUTO_BREACH_NERVE_FU  = 112,  -- 自动裂神符
	SETTING_IDX_AUTO_DEATH_EYE  	  = 113,  -- 自动死亡之眼
	SETTING_IDX_AUTO_ICE_SICKLE_S     = 114,  -- 自动冰镰术
	SETTING_IDX_AUTO_FLAME_ICE        = 115,  -- 自动火焰冰
	SETTING_IDX_AUTO_ICE_GROUP_RAIN   = 116,  -- 自动冰霜群雨
	SETTING_IDX_AUTO_DOUBLE_DRAGON_Z  = 117,  -- 自动双龙斩
	SETTING_IDX_AUTO_DRAGON_SHADOW_JF = 118,  -- 自动龙影剑法
	SETTING_IDX_AUTO_THUNDERBOLT_JF   = 119,  -- 自动雷霆剑法
	SETTING_IDX_AUTO_FREELY_JS        = 120,  -- 自动纵横剑术
	SETTING_IDX_PICK_SETTING          = 121,  -- 拾取设置
	SETTING_IDX_AUTO_SHI_ZI_HOU 	  = 122,  -- 自动狮子吼
	SETTING_IDX_DISCARD_GOODS         = 123,  -- 丢弃物品
	SETTING_IDX_SPELL_HELP            = 124,  -- 施法辅助
	SETTING_IDX_PLAYER_NAME_COLOR	  = 125,  -- 玩家名字变色
	SETTING_IDX_TELEPORT_KEEP_TARGET  = 126,  -- 飞地图后锁定原目标(默认清除目标)

	SETTING_IDX_BOSS_NO_SIMPLE_DRESS  = 158,  -- Boss不简装

	SETTING_IDX_AUTO_COMBO			  = 200,  -- 自动连击
	SETTING_IDX_IGNORE_STALL		  = 201,  -- 屏蔽摆摊

	SETTING_IDX_MORE_FAST 			  = 300,  -- 更快的加速
	--
	SETTING_IDX_FRAME_RATE_TYPE_HIGH  = 1002, -- 高帧率模式设置
	SETTING_IDX_MONSTER_PET_VISIBLE   = 2001, -- 屏蔽物显示设置
	SETTING_IDX_EFFECT_SHOW           = 2002, -- 屏蔽特效设置
	SETTING_IDX_PLAYER_SHOW_FRIEND    = 2003, -- 屏蔽己方玩家设置
	SETTING_IDX_PLAYER_SHOW           = 2004, -- 屏蔽玩家设置
	SETTING_IDX_MONSTER_VISIBLE       = 2005, -- 屏蔽怪物设置
	SETTING_IDX_HERO_HIDE             = 3008, -- 屏蔽英雄
	SETTING_IDX_HERO_JOINT_SHAKE      = 3009, -- 合击震屏
	SETTING_IDX_HERO_AUTO_JOINT       = 3010, -- 自动合击
	SETTING_IDX_HERO_FOLLOW_ATTACK    = 3011, -- 跟随主角攻击
	SETTING_IDX_HERO_ATTACK_DODGE     = 3012, -- 英雄打怪躲避
	SETTING_IDX_HERO_AUTO_LOGIN       = 3013, -- 自动召唤英雄
	SETTING_IDX_HERO_AUTO_LOGINOUT    = 3014, -- 英雄残血自动收回
	SETTING_IDX_REVIVE_PROTECT        = 3015, -- 复活戒指回城保护
	SETTING_IDX_SKILL_EFFECT_SHOW     = 3017, -- 屏蔽技能特效
	--人物
	SETTING_IDX_HP_PROTECT1           = 3020, -- hp保护1
	SETTING_IDX_HP_PROTECT2           = 3021, -- hp保护2
	SETTING_IDX_HP_PROTECT3           = 3022, -- hp保护3
	SETTING_IDX_HP_PROTECT4           = 3023, -- hp保护4
	SETTING_IDX_MP_PROTECT1           = 3024, -- mp保护1
	SETTING_IDX_MP_PROTECT2           = 3025, -- mp保护2
	SETTING_IDX_MP_PROTECT3           = 3026, -- mp保护3
	SETTING_IDX_MP_PROTECT4           = 3027, -- mp保护4
	--hero
	SETTING_IDX_HERO_HP_PROTECT1      = 3030, -- hp保护1
	SETTING_IDX_HERO_HP_PROTECT2      = 3031, -- hp保护2
	SETTING_IDX_HERO_HP_PROTECT3      = 3032, -- hp保护3
	SETTING_IDX_HERO_HP_PROTECT4      = 3033, -- hp保护4
	SETTING_IDX_HERO_MP_PROTECT1      = 3034, -- mp保护1
	SETTING_IDX_HERO_MP_PROTECT2      = 3035, -- mp保护2
	SETTING_IDX_HERO_MP_PROTECT3      = 3036, -- mp保护3
	SETTING_IDX_HERO_MP_PROTECT4      = 3037, -- mp保护4

	SETTING_IDX_PK_PROTECT            = 3038, -- 红名保护

	SETTING_IDX_BEDAMAGED_PLAYER      = 3039, -- 被玩家攻击时
	SETTING_IDX_N_RANGE_NO_PICK       = 3040, -- N范围内有多少怪 不走去拾取
	SETTING_IDX_FIRST_ATTACK_MASTER   = 3041, -- 受到BB攻击时先打主人
	SETTING_IDX_NO_ATTACK_HAVE_BELONG = 3042, -- 不抢别人归属怪物
	SETTING_IDX_NO_MONSTER_USE        = 3043, -- 多少秒没怪物使用
	SETTING_IDX_BESIEGE_FLEE          = 3044, -- 周围有多少敌人时使用
	SETTING_IDX_RED_BESIEGE_FLEE      = 3045, -- 周围有多少红名时使用
	SETTING_IDX_ENEMY_ATTACK          = 3046, -- 周围有敌人时主动攻击
	SETTING_IDX_IGNORE_MONSTER        = 3047, -- 自动挂机忽略的怪物
	SETTING_IDX_REVIVE_PROTECT_HERO   = 3050, -- 复活戒指回城保护英雄

	TradingBankDesignSize			  = {width = 1136 , height = 640},

	SERVER_OPTION_ALLOW_ADD_FRIEND	  = 1,
	SERVER_OPTION_ALLOW_TRADE	  	  = 2,
	SERVER_OPTION_ALLOW_SHOW_FASHTION = 3,
	SERVER_OPTION_ALLOW_TEAM	  	  = 4,
	SERVER_OPTION_ALLOW_NEAR_SHOW	  = 5,		
	SERVER_OPTION_ALLOW_SHOW_HERO_FASHTION = 6,


	-- 进视野结构体属性
	ACTOR_BUFFER_NAME 			  	= 1,  --buffer:ReadShortString(200)
    ACTOR_BUFFER_SEX                = 2, --buffer:ReadByte()
    ACTOR_BUFFER_JOB                = 3, --buffer:ReadByte()
	ACTOR_BUFFER_MASTERID           = 4,--buffer:ReadInt64() --主人id
	ACTOR_BUFFER_PKCAMPID           = 5,--buffer:ReadInt64() --阵营
	ACTOR_BUFFER_FLAGSTATE          = 6,--buffer:ReadInt64()--人物状态值(与运算)：1 死亡状态
	ACTOR_BUFFER_RACESERVER         = 7,--buffer:ReadShort()
    ACTOR_BUFFER_RANGECANFINDME     = 8,--buffer:ReadByte()
	ACTOR_BUFFER_COLOR              = 9,--buffer:ReadByte()
    ACTOR_BUFFER_TITLE              = 10,--{t1 = buffer:ReadInt()}
	ACTOR_BUFFER_OWNERID            = 11,--buffer:ReadInt64()
    ACTOR_BUFFER_OWNERNAME          = 12,--buffer:ReadShortString(50)
    ACTOR_BUFFER_THROUGH            = 13,--buffer:ReadInt()
	ACTOR_BUFFER_ACTIONTYPE         = 14,--buffer:ReadByte()
    ACTOR_BUFFER_WARZONE            = 15,--buffer:ReadByte()
	ACTOR_BUFFER_GMDATA             = 16,--buffer:ReadArrInt64(5,0)
	ACTOR_BUFFER_ME                 = 17,--buffer:ReadInt() -- MoveEff
	ACTOR_BUFFER_NATIONID 			= 18,--buffer:ReadByte() -- 国家ID
	ACTOR_BUFFER_NATIONENEMYPK		= 19,--buffer:ReadBool() -- 怪物-国家模式是否可被攻击
	ACTOR_BUFFER_ARRAPPEAR          = 20,--用于延迟读取
	ACTOR_BUFFER_ARRAPPEAR_COUNT    = 21,--buffer:ReadByte() -- 外观数量0-19
	ACTOR_BUFFER_ARRSPABIL          = 22,--用于延迟读取
	ACTOR_BUFFER_ARRSPABIL_COUNT    = 23,--buffer:ReadUByte() -- 状态数量0-255
	ACTOR_BUFFER_ARRCURABIL         = 24,--用于延迟读取
    ACTOR_BUFFER_ARRMAXABIL         = 25,--用于延迟读取
	ACTOR_BUFFER_ARRABIL_COUNT      = 26,--buffer:ReadShort() -- 属性数量0-399
	ACTOR_BUFFER_BEXTINFO			= 27,--buffer:ReadBool() -- 是否有额外信息
	----------------------------------------------------------------------------------
		--外观结构 根据 ACTOR_BUFFER_ARRAPPEAR_COUNT 数量读
		ACTOR_BUFFER_ARRAPPEAR_ID		= 1, --buffer:ReadByte()
		ACTOR_BUFFER_ARRAPPEAR_VALUE	= 2, --buffer:ReadInt() 
	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------
		--状态结构 根据 ACTOR_BUFFER_ARRSPABIL_COUNT 数量读
		ACTOR_BUFFER_ARRSPABIL_ID		= 1,--buffer:ReadUShort()
	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------
		--属性结构 根据 ACTOR_BUFFER_ARRABIL_COUNT 数量读
		ACTOR_BUFFER_ARRABIL_ID			= 1,--buffer:ReadShort()
		ACTOR_BUFFER_ARRABIL_CURVALUE	= 2,--buffer:ReadInt64()
		ACTOR_BUFFER_ARRABIL_MAXVALUE	= 3,--buffer:ReadInt64()
	----------------------------------------------------------------------------------
	---------------------------------
	--额外信息 根据 ACTOR_BUFFER_BEXTINFO 读
    ACTOR_BUFFER_TEAMID             = 101,--buffer:ReadInt()
    ACTOR_BUFFER_GUILDID            = 102,--buffer:ReadShortString(40)
    ACTOR_BUFFER_OFFLINE            = 103,--buffer:ReadBool()
    ACTOR_BUFFER_SHENMIREN          = 104,--buffer:ReadBool()
    ACTOR_BUFFER_GUILDNAME          = 105,--buffer:ReadShortString(30)
    ACTOR_BUFFER_RANK               = 106,--buffer:ReadInt()
    ACTOR_BUFFER_RANKNAME           = 107,--buffer:ReadShortString(30)
    ACTOR_BUFFER_CASTLENAME         = 108,--buffer:ReadShortString(10)
    ACTOR_BUFFER_PKLV               = 109,--buffer:ReadInt()
    ACTOR_BUFFER_STALLNAME          = 110,--buffer:ReadShortString(50)
	ACTOR_BUFFER_DEARID             = 111,--buffer:ReadInt64()
    ACTOR_BUFFER_STID               = 112,--buffer:ReadInt64()
    ACTOR_BUFFER_CANDLE             = 113,--buffer:ReadByte()
	ACTOR_BUFFER_DOUBLETAG          = 114,--buffer:ReadByte() 
    ACTOR_BUFFER_DOUBLEUSERID       = 115,--buffer:ReadInt64() 
    ACTOR_BUFFER_NSERVERID          = 116,--buffer:ReadInt()
	ACTOR_BUFFER_JOINNETCOUNT		= 117,--buffer:ReadByte()
	--------------------------------
	-- 关系网结构 根据 ACTOR_BUFFER_JOINNETCOUNT 数量读
	ACTOR_BUFFER_NETID				= 201,
	--------------------------------
	



	
	HUD_Hp_Null   					  = "HUD_Hp_Null", 				-- 空血
	HUD_Hp_Full   					  =	"HUD_Hp_Full", 				-- 满血
	HUD_PC_MOUSE_SHOW             	  = "HUD_PC_MOUSE_SHOW",		-- PC 鼠标经过显血显名
	HUD_BAR_SHOW_FULL_HP			  = "HUD_BAR_SHOW_FULL_HP",		-- game_data 中 showFewHp 配置是 1 时， 进视野血量条强制显示满血
	HUD_SNEAK 						  = "HUD_SNEAK", 				-- 潜行

	Is_Gate							  = "Is_Gate",				    -- 城门
	Is_Wall							  = "Is_Wall",					-- 城墙
	Is_Cave							  = "Is_Cave",					-- 钻地怪

	ACT_SNEAK 						  = "ACT_SNEAK", 				-- 潜行动作

	IS_RUN_ONE 						  = "IS_RUN_ONE", 				-- 跑一格

	BUFF_PLAYER_AVATAR_SEX  		  = "BUFF_PLAYER_AVATAR_SEX",   -- buff变装性别

	HORSE_MAIN 						  = "HORSE_MAIN", 				-- 骑马  主驾
	HORSE_COPILOT					  = "HORSE_COPILOT",			-- 骑马  副驾
	HORSE_SEX 						  = "HORSE_SEX",				-- 骑马  性别

	HUD_HPBAR_VISIBLE     		  	  = 1,  						-- 血条-显示状态
	HUD_MPBAR_VISIBLE				  = 2,							-- 蓝条-显示状态
	HUD_NGBAR_VISIBLE				  = 3,							-- 内功-显示状态
	HUD_HMPLabel_VISIBLE			  = 4,							-- Hp、Mp、Job 显示状态
	HUD_NAMELabel_VISIBLE	      	  = 5,							-- 名字-显示状态
	HUD_GUILDLabel_VISIBLE	      	  = 6,							-- 行会-显示状态
	HUD_TITLELabel_VISIBLE	      	  = 7,							-- 封号-显示状态
	HUD_TITLE_VISIBLE	     	  	  = 8,							-- 称号-顶戴显示状态

	PLAYER_VISIBLE					  = 21,							-- 玩家-显示状态
	MONSTER_VISIBLE					  = 22,							-- 怪物-显示状态
	HERO_VISIBLE					  = 23,							-- 英雄-显示状态
	PLAYER_B_VISIBLE			      = 24,							-- 己方玩家-显示状态 [实际是是否己方玩家状态]
	
	MONSTER_NORMAL					  = 31,							-- 正常怪
	MONSTER_CLEAR					  = 32,							-- 清理怪

	DAMAGE_SHOW_NUM 			      = 1,						    -- 飘血 显示数字和伤害
    DAMAGE_SHOW_SPRITE                = 2,							-- 飘血 显示图片
    DAMAGE_SHOW_TEXT                  = 3,							-- 飘血 显示数字文本(无伤害)
    DAMAGE_SHOW_POINT 				  = 4, 							-- 飘血 显示小数单位
	
	MetaInvalidKey					  = "invalid key",				-- 元变量无效Key
	MetaInvalidValue				  = "undefined",				-- 元变量无效Value

	SERVER_OPTION_AUCTION             = "paimaitype",           -- 服务器开关 拍卖
	SO_SHOW_ALL_FIGHTPAGES            = "SHOW_ALL_FIGHTPAGES",  -- 服务器开关 显示所有战斗页
	SERVER_OPTION_MISSTION            = "ShowMissDlg",          -- 服务器开关 任务
	SERVER_OPTION_SNDAITEMBOX         = "ShowSndaItemBox",      -- 服务器开关 是否显示首饰盒
	SERVER_OPTION_TRADE_DEAL          = "Deal",                 -- 服务器开关 面对面交易 true/需要面对面
	SERVER_OPTION_AUTO_DRESS          = "autoDress",            -- 服务器开关 快捷使用tips
	SERVER_OPTION_OPEN_F_EQUIP        = "OpenFEquip",           -- 服务器开关 时装是否开启首饰
	SERVER_OPTION_BIND_GOLD           = "BindGold",             -- 服务器开关 开启元宝替换绑元
	SERVER_OPTION_NPC_BUTTON          = "NpcButton",            -- 服务器开关 显示npc按钮
	SERVER_OPTION_NPC_NAME            = "npc",                  -- 服务器开关 显示npc名字 1:不显示
	SERVER_DROP_TIPS                  = "DropTips",             -- 服务器开关 显示绑定丢弃提示 0:显示
	SERVER_EXP_IN_CHAT                = "ExpInChat",            -- 服务器开关 经验信息是否显示在聊天框 0：显示在聊天框
	SERVER_SHOW_STALL_NAME            = "ShowStallName",        -- 服务器开关 是否显示默认摊位名字  0：显示
	PLAYER_BLUE_BLOOD                 = "BlueBlood",            -- 服务器开关  是否显示蓝条HUD_SPRITE_MP   0: 显示
	ITEMTIPS_TOUBAO_SHOW              = "DropInsuredHumItems",  -- 服务器开关  是否显示itemtips的投保描述   1= 开启 0 = 关闭
	SERVER_OPTION_BAN_DOUBLE_FIREHIT  = "DisableDoubleFirehit", -- 服务器开关  是否禁止双烈火    1：禁止
	SERVER_OPTION_ALL_TEAM_EXP        = "HighLevelKillMonFixExpAllMap", --服务器开关 是否开启全队经验 true/false
	EQUIP_EXTRA_POS     			  = "EquipPanelType",	 	-- 服务器开关，是否有额外的装备位置  1= 开启 0 = 关闭
	SERVER_NO_SELL_MONEY 			  = "NoSellMoney",			-- 服务器开关，是否禁止交易货币   true = 禁止
	SERVER_CHECK_AUTO_FIGHT 		  = "CheckAutoFight",	 	-- 服务器开关，检测是否飞终止自动战斗
	SERVER_STALL_COLOR			  	  = "StallColor", 			-- 服务器开关  摆摊名字颜色
	SERVER_RUN_ONE 					  = "RunOne", 				-- 服务器开关  跑一格
	SERVER_SHABAKE_FREE_NAME_COLOR    = "InFreePKAreaNameColor",-- 服务器开关，沙巴克/行会战下无行会颜色       绿
	SERVER_ALLY_GUILD_NAME_COLOR 	  = "AllyAndGuildNameColor",-- 服务器开关，行会结盟颜色			    	  蓝
	SERVER_WAR_GUILD_NAME_COLOR 	  = "WarGuildNameColor", 	-- 服务器开关，行会宣战颜色				      橙
	SERVER_SHABAKE_HOME_X 			  = "CastleHomeX", 			-- 服务器开关，沙巴克中心坐标X
	SERVER_SHABAKE_HOME_Y 			  = "CastleHomeY", 			-- 服务器开关，沙巴克中心坐标Y
	SERVER_SHABAKE_RANGE_X 			  = "CastleWarRangeX", 		-- 服务器开关，沙巴克范围X
	SERVER_SHABAKE_RANGE_Y 			  = "CastleWarRangeY", 		-- 服务器开关，沙巴克范围Y
	SERVER_SHABAKE_MAP_NAME 		  = "CastleMapName", 		-- 服务器开关，攻沙区域 需判断坐标  	地图ID
	SERVER_SHABAKE_MAP_PALACE 		  = "CastleMapPalace", 		-- 服务器开关，攻沙区域 不需判断坐标 	地图ID
	SERVER_SHABAKE_MAP_SECRET 		  = "CastleMapSecret", 		-- 服务器开关，攻沙区域 不需判断坐标 	地图ID
	SERVER_DISPOSE_ITEM_FRM_CHIJIU    = "DisposeItemFrmChiJiu", -- 服务器开关，持久消失开关
	SERVER_NO_STD_ITEM_TO_CLIENT 	  = "NoStdItemToClient", 	-- 服务器开关，是否下发道具/装备表  ture=不下发读取本地  false=下发读取服务端
	SERVER_NO_TO_CLIENT_CFG 		  = "sNoToClientCfg", 		-- 服务器开关，不下发哪些配置文件   string  #分割


	-- 分辨率宽高
	RESOLUTION_WIDTH				  = 1920,
	RESOLUTION_HEIGHT				  = 1080,
	CAMERA_Z_MAX_WIN 				  = 980,

	-- 己方判断类型
	TYPE_GUILD						  = 1,
	TYPE_TEAM						  = 2,
	TYPE_CAMP						  = 3,
}

return mmoConstants
