local M = 
{
    NETMSG_HEADER_ENCODE_SIZE               =          32,  	-- in bytes,  32 bytes after encrypted.
    NETMSG_HEADER_DECODE_SIZE               =          24,  	-- in bytes,  24 bytes without encryption

    -- ---------------------------------------- Net Mess      age Type ---------------------------------------- 
    -- CS = Client -> Server,  SC = Server -> Client

    MSG_SC_NETWORK_DISCONNECTED			 	=		    0x1FFFFFFE,	--断线消息
    MSG_SC_NETWORK_ILLEGAL_MSG			    =		    0x2FFFFFFE,	--非法消息
    MSG_SC_NETWORK_BATCH_MSG			    =		    -1,	        --批量消息

    MSG_CS_HEART_BEAT_KEEP                  =           60000,  -- 客户端10s发个心跳，由于C++不好修改，Lua层处理

    MSG_CS_RELOGIN_SERVER				    = 			60002, 	-- 断线重连登录
    MSG_SC_SERVER_FORBIDDEN                 =          	60004,  -- 服务器踢人 - 维护
    MSG_SC_SERVER_FORBIDDEN_NET_ERROR       =           60005,  -- 服务器踢人 - 网络异常 重新连接
    MSG_SC_SERVER_GAME_ERROR                =           60006,  -- 需要把玩家踢下线
    MSG_SC_SERVER_KICKOUT                   =           528,    -- 服务器踢人 - 脚本触发
    MSG_SC_LIMIT_CHAT                       =           60008,  -- 同步聊天功能开关
    MSG_SC_CUSTOM_EVENT_REPORT              =           60009,  -- 自定义事件上报
    MSG_SC_NETWORK_OTHERPLACE_LOGIN		 	=			57,		-- 异地登录推送消息号
    MSG_SC_GAME_CONFIG                      =          	3,      -- 游戏配置
    MSG_SC_GAME_WORLD_INFO_INIT             = 			2,		-- 游戏世界初始化
    MSG_SC_GAME_UPDATE_ITEM                 =          	333,    -- 游戏更新物品配置数据

    -- *********** Login *********** --
    MSG_CS_LOGIN_SERVER				     	= 			20,	   	-- 登录
    MSG_CS_REQUEST_SERVER_LIST              =          	2001,  
    MSG_CS_SYNC_VERSION                     =          	2020,  	-- 同步版本号
    MSG_SC_RESPONSE_SERVER_LIST             =          	529,  

    MSG_CS_REQUEST_SERVER_INFO              =          	104,   	-- 获取第二个服务器（角色服？）的ip，port
    MSG_SC_RESPONSE_SERVER_INFO             =          	530,   	-- 返回指定服务器id的ip和port： ip/port/特殊数字（用于赋值给每个消息的param4）
    MSG_SC_RESPOINSE_CHECK_TOKEN_FAIL       =          	503,   	-- token二次验证 //密码错误 recog  -99 = 信息不全  -6 = 认证失败！

    MSG_CS_REQUEST_ROLE_INFO                =          	100,   	-- 连接新的服务器，并且连接成功之后马上发送一个消息给服务器，消息id为100， param3:1， 附加字符串：账号/ param4
    MSG_SC_SYSTEM_INFO   					= 			100,	--系统信息 和上面的消息ID相同 不过这个是接收上面是发送 并不冲突
    MSG_SC_RESPOINSE_ROLE_INFO_FAIL         =          	527,   	-- 查询角色信息失败
    MSG_SC_RESPOINSE_ROLE_INFO              =          	520,   	-- 消息内容：附加消息格式：用/来间隔开属性，显示角色选择或者创建面板

    MSG_CS_CREATE_ROLE                      =          	101,   	-- 请求创建角色, uid + "/" + name + "/1/" + job + "/" + sex;
    MSG_SC_CREATE_ROLE_SUCCESS              =          	521,   	-- 创建角色成功
    MSG_SC_CREATE_ROLE_FAIL                 =          	522,   	-- 创建角色失败

    MSG_CS_DELETE_ROLE                      =          	102,   	-- 请求删除角色
    MSG_SC_DELETE_ROLE_SUCCESS              =          	523,   	-- 删除角色成功
    MSG_SC_DELETE_ROLE_FAIL                 =          	524,  	-- 删除角色失败

    MSG_CS_RESTORE_ROLE_LIST                =          	108,   	-- 请求 恢复角色列表
    MSG_SC_RESTORE_ROLE_LIST                =          	558,   	-- 返回 恢复角色列表
    MSG_CS_RESTORE_ROLE                     =          	109,   	-- 请求 恢复角色
    MSG_SC_RESTORE_ROLE                     =          	559,  	-- 返回 恢复角色

    MSG_CS_SELECT_ROLE                      =          	103,   	-- 选择角色后，发送消息103，附加消息格式：账号/选择的角色名字
    MSG_SC_SERVER_NOTICE_REMOVE             =          	105,   	-- 后台公告删除
    MSG_SC_NOTICE                           =          	103,   	-- 返回 公告栏消息 
                                                                --[[消息头中，参数1为公告显示位置：
                                                                    1：顶端  2：中间，3：底部，4：喇叭，5：自定义
                                                                    参数2为是否同步到系统框
                                                                    0：不同步，1：同步
                                                                    字符串参数为具体的富文本内容]]

    MSG_SC_GAMESERVER_INFO                  =          	525,   	-- 发送消息103后，收到这个消息。
                                                                -- 这个消息是返回第三个服务器ip和port，收到后，断开之前的连接，连接发过来的ip和port，
                                                                -- 并且连接成功后，发送的第一个消息规定为：直接发送字符串（*#账号/角色名字/parma4/920080512/0）
    MSG_SC_GAMESERVER_INFO_ERROR            =           526,    -- 获取服务器下发的游戏 port失败       

    MSG_CS_ROLE_NAME                        =           107,    -- 请求角色名字
    MSG_SC_ROLE_NAME                        =           539,    -- 返回角色名字

    MSG_CS_ENTER_GAME_DUMMY                 =          	1018,   -- loading 完成发送这个消息 消息号：1018 附加字符串：*/*/*/0

    -- *********** scene *********** --
    MSG_SC_MAP_CHANGE                       =          	634,   	-- 场景切换
    MSG_SC_MAP_INIT                         =          	51,    	-- 场景创建
    MSG_SC_MAP_ACTOR_CLEANUP                =          	633,   	-- 清除场景内所有actor
    MSG_SC_ENTER_SAFE_AREA					=	        6096,	-- 安全区相关
    MSG_SM_THROUGHHUM                       =           6207,   -- 穿人穿怪消息
    MSG_SM_MAP_CONFIG                       =           60007,  -- 场景切换时的配置修改

    MSG_SC_MAP_ADD_SPECIAL_EFFECT           =          	804,   	-- 在场景上添加特效（安全区域周围特效  火墙特效）*/
    MSG_SC_MAP_RMV_SPECIAL_EFFECT           =          	805,   	-- 在场景上删除特效（安全区域周围特效  火墙特效）*/
    MSG_SC_MAP_PLAY_EFFECT                  =           554,    -- 在场景播放特效

    MSG_SC_MAP_ITEM_DROP_BATCH 			 	= 			610,    -- 掉落物品显示 - 批量
    MSG_SC_MAP_ITEM_REMOVE_BATCH 			= 			611,    -- 掉落物品消失 - 批量
    MSG_SC_MAP_ITEM_REMOVE_BY_XY 			= 			220,    -- 掉落物品清理 - 按坐标

    MSG_CS_MAP_ITEM_PICK    		        =          	1001,   -- 掉落物品拾取，通知服务器
    MSG_SC_MAP_ITEM_PICK_FAIL               =          	871,    -- 掉落物品拾取失败 
    MSG_CS_MAP_ITEM_DISCARD  		        =          	1000,   -- 物品丢弃，通知服务器
    MSG_CS_MAP_GOOD_DISCARD  		        =          	1016,   -- 金币丢弃

    -- *********** actor action *********** --
    MSG_SC_ACTION_CONFIREM_SUCCESS          =          	1,		-- 主玩家行为确认
    MSG_CS_MAIN_PLAYER_TURN                 =          	3010,  	-- 主玩家 请求转身
    MSG_CS_MAIN_PLAYER_WALK                 =          	3011,  	-- 主玩家 行走
    MSG_CS_MAIN_PLAYER_RUN                  =          	3013,  	-- 主玩家 跑
    MSG_CS_MAIN_PLAYER_RIDE_RUN             =          	3182,  	-- 主玩家 骑马跑

    MSG_SC_NET_PLAYER_RIDE_RUN              =          	3219,   -- 网络玩家 骑马跑
    MSG_SC_NET_ACTOR_RUN                    =          	13,    	-- 网络玩家 跑
    MSG_SC_NET_ACTOR_MOVE                   =          	11,    	-- 走
    MSG_SC_NET_ACTOR_IN_OF_VIEW             =          	10,    	-- 进视野（创建）
    MSG_SC_NET_ACTOR_OUT_OF_VIEW            =          	30,    	-- 出视野（删除）
    MSG_SC_NET_ACTOR_TURN                   =          	35,    	-- actor转身
    MSG_SC_NET_PLAYER_MOVE_FAIL             =          	28,    	-- 移动失败，强制拉回

    MSG_SC_NET_PLAYER_FLY_IN                =          	801,   	-- 飞进视野（传送特效）
    MSG_SC_NET_PLAYER_FLY_IN_2              =          	807,   	-- 飞进视野（传送特效，另外一种特效）
    MSG_SC_NET_PLAYER_FLY_OUT               =          	800,   	-- 飞出视野（传送特效）
    MSG_SC_NET_PLAYER_FLY_OUT_2             =          	806,   	-- 飞出视野（传送特效，另外一个特效）
    MSG_SC_NET_MONSTER_BORN              	=          	20,    	-- 怪物出生 或 沙巴克大门打开 沙巴克城墙改变
    MSG_SC_NET_MONSTER_CAVE                 =          	21,    	-- 钻回洞穴 沙巴克关门  食人花钻回  触龙神钻回 

    MSG_SC_NET_ACTOR_REVIVE                 =          	27,    	-- 网络玩家 复活
    MSG_SC_PLAYER_ITEM_REMOVE				= 			709,   	-- 玩家死亡 道具删除消息变动

    MSG_SC_MONSTER_OWNER                    =          	6124,
    MSG_SC_NET_ACTOR_DEATH_FALL_DOWN        =          	32,    	-- 死亡，倒下过程动画
    MSG_SC_NET_ACTOR_DEATH_SKELETON         =          	33,    	-- 死亡，显示被挖掘后的骨头

    MSG_SC_NET_ACTOR_DAMAGE_NUMBER_SHOW     =          	881,   	-- 伤害数字显示（目前尚不确定该消息的适用范围，先考虑为ACTOR）

    MSG_SC_ACTOR_CAMP_CHANGE                =           853,    -- Actor阵营ID改变 (服务端广播)

    MSG_SC_ACTOR_TEAM_CHANGE                =           60,     -- Actor组队ID改变 (服务端广播)
    -- *********** Player control *********** --
    MSG_SC_GAME_HELLO_TIPS                  =          	658,   	-- 进入游戏的第一个消息 提示信息/主玩家ID
    MSG_SC_CREATE_MAIN_PLAYER               =          	50,    	-- 创建主控玩家
    MSG_SC_PLAYER_FEATURE_CHANGED           =          	41,    	-- 玩家外观发生变化
    MSG_SC_PET_FEATURE_CHANGED              =           4590,   -- 宠物外观改变
    
    MSG_SC_ACTOR_ICONS_UPDATE               =           311,    -- actor 顶戴
    MSG_SC_ACTOR_TITLE_UPDATE               =           312,    -- actor 称号
    MSG_SC_ACTOR_BUFF_INIT                  =           5020,   -- actor buff 初始化
    MSG_SC_ACTOR_BUFF_ADD                   =           1207,   -- actor buff 增加
    MSG_SC_ACTOR_BUFF_RMV                   =           1208,   -- actor buff 删除

    MSG_SC_ACTOR_GMDATA_UPDATE              =           6531,   -- actor gmdata 更新

    -- MSG_SC_ACTOR_INTERNAL_FORCE_UPDATE      =           3115,   -- actor 内力值 刷新


    -- *********** Player property *********** --
    MSG_SC_ACTOR_NAME                       =         	42,    	-- 玩家名字信息：名字颜色，以及行会名 --玩家、怪物都走这里
    
    MSG_SC_ACTOR_UPDATE_ATTR                =         	53,     -- 刷新属性
    MSG_SC_ACTOR_DAMAGE_HP                  =          	31,     -- HP(受到伤害改变血量)

    MSG_CS_REQUEST_PK_STATE                 =         	1005,   -- 请求改变攻击模式
    MSG_SC_PLAYER_PK_STATE                  =         	609,    -- 当前PK模式

    MSG_SC_UPDATE_PLAYER_PKPOINT            =           1213,   -- 玩家PK值
    MSG_SC_UPDATE_DIYATTR_TITLE             =           1214,   -- 更新自定义属性标题配置  (玩家独立)
    
    -- *********** Player equip on/off *********** --
    MSG_CS_PLAYER_EQUIP_ON_REQUEST         	=        	1003,  	-- 装备穿上请求
    MSG_SC_PLAYER_EQUIP_ON_SUCCESS          =        	615,   	-- 装备穿上确认-成功
    MSG_SC_PLAYER_EQUIP_ON_FAIL             =        	616,   	-- 装备穿上确认-失败

    MSG_CS_PLAYER_EQUIP_OFF_REQUEST         =           1004,   -- 装备脱下请求
    MSG_SC_PLAYER_EQUIP_OFF_SUCCESS         =           619,    -- 装备脱下确认-成功
    MSG_SC_PLAYER_EQUIP_OFF_FAIL            =           620,    -- 装备脱下确认-失败

    MSG_CS_PLAYER_EQUIP_BEST_RINGS_STATE    =           1118,   -- 首饰盒状态
    MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE 	=           1182,   -- 首饰盒状态改变

    MSG_SC_PLAYER_EQUIP_INFO				=           621,	-- 上线服务器通知装备信息

    MSG_CS_ROLE_EQUIP_INFO_REQUEST          =           82,     -- 请求查看角色和元神的基本信息和装备信息
    MSG_SC_ROLE_INFO_RESPONSE               =           751,    -- 返回角色基础信息

    -- Bag
    MSG_CS_REQUEST_BAGDATA                  =           81,     -- 请求背包数据 request
    MSG_SC_RETURN_BAGDATA                   =           201,    -- 请求背包数据返回 Return
    MSG_SC_RETURN_BAGDATA_REMAINING         =           301,    -- 请求背包数据返回 Return 数据比较多  分两批返回
    MSG_SC_BAG_ADD_ITEM                     =           200,    -- 返回 - 增加道具
    MSG_SC_BAG_DEL_ITEM                     =           202,    -- 返回 - 删除道具
    MSG_SC_BAG_UPDATE_ITEM                  =           203,    -- 返回 - 刷新道具
    MSG_CS_USE_BAG_ITEM				        =           1006,	-- 主动使用物品
    MSG_CS_EAT_BAG_DRUG                     =           1017,   -- 背包药品使用 [StdMode 0-3]
    MSG_SC_BAG_ITEM_USE_SUCCESS		        =           635, 	-- 道具使用成功
    MSG_SC_BAG_ITEM_USE_FAILED			    =           636, 	-- 道具使用失败
    MSG_SC_DROP_ITEM_GET_FAILED             =           214,	-- 道具拾取失败
    MSG_SC_DROP_ITEM_SUCCESS          	    =           600,	-- 丢弃道具成功
    MSG_SC_DROP_ITEM_FAILED          	    =           601,	-- 丢弃道具失败
    MSG_SC_RESET_BAG_POS				    =           1212,	-- 整理背包
    MSG_CS_ITEM_NUMBER_CHANGE			    =           5279,	-- 拆分道具
    MSG_CS_ITEM_TWO_TO_ONE			  	    =           5280,	-- 叠加道具
    MSG_CS_ITEM_FIX_ITEMS				    =           5281,	-- 物品添加持久

    -- storage
    MSG_CS_STORAGE_STORE_REQUEST            =           1031,   -- 存放物品到仓库
    MSG_CS_STORAGEDATA_REQUEST              =           704,    -- 请求仓库数据
    MSG_SC_STOR_DATA						= 			704,	-- 仓库数据
    MSG_SC_STORAGE_STORE_FORBIDDEN			=           703,	-- 当前禁止使用仓库，或其它错误存储失败
    MSG_SC_STORAGE_STORE_STORED_ADD			=           701,    -- 存入成功
    MSG_SC_STORAGE_STORE_FULL				=           702,	-- 仓库满
    MSG_CS_STORAGE_PICK_OUT_REQUEST			=           1032,   -- 取出仓库物品
    MSG_SC_STORAGE_PICK_OUT_FORBIDDEN		=           706,    -- 当前禁止使用仓库，或其它错误存储失败
    MSG_SC_STORAGE_PICK_OUT_SUCC			=           705,    -- 取出到背包成功
    MSG_SC_STORAGE_PICK_OUT_FULL			=           707,    -- 背包满
    MSG_SC_STORAGE_COUNT_CHANGE             =           798,    -- 仓库格子数改变（只会增加

    -- *********** Player skill data ********* --
    MSG_SC_PLAYER_SKILL_DATA                =           211,    -- 技能列表数据
    MSG_SC_PLAYER_ADD_SKILL                 =           210,    -- 服务器返回新学的技能(主角)
    MSG_SC_PLAYER_DEL_SKILL                 =           212,    -- 服务器返回删除的技能(主角)
    MSG_SC_PLAYER_UP_SKILL                  =           640,    -- 更新技能
    MSG_SC_SKILL_ONOFF                      =           36,     -- 技能开关
    MSG_CS_PLAYER_SKILL_ATTACK              =           3014,   -- 请求 - 砍
    MSG_CS_PLAYER_SKILL_LAUNCH              =           3017,   -- 请求 - 施法
    MSG_SC_MAINPLAYER_MAGIC                 =           716,    -- 返回 - 施法
    MSG_SC_NET_PLAYER_ATTACK                =           14,     -- 广播 - 攻击动作+攻击表现
    MSG_SC_PLAYER_SKILL_LAUNCH_SUCCESS      =           17,     -- 广播 - 施法动作
    MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS       =           638,    -- 广播 - 施法表现
    MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS_JSON  =           639,    -- 广播 - 施法表现 [服务端json数据 处理多目标]
    MSG_SC_PLAYER_SKILL_27_SUCCESS          =           6,      -- 野蛮冲撞 - 成功
    MSG_SC_PLAYER_SKILL_27_BACKSTEP         =           9,      -- 野蛮冲撞 - 被撞开 main player/net player
    MSG_SC_SKILL_HIT_MISS					=           60003,  -- 飞行技能命中失败
    MSG_SC_SERVER_SKILL_RESP				=           1139,   -- 服务器主动触发的技能
    MSG_CS_SERVER_SKILL_LAUNCH				=           1139,   -- 服务器主动触发的技能


    MSG_SC_SUMMON_ALIVE_UPDATE			    = 		    1000,	-- 返回 召唤物状态
    MSG_SC_PET_STATE                        =           745,    -- 召唤物死亡

    -- *********** Npc ************** --
    MSG_CS_NPC_CLICK                        =           1010,   -- 点击npc发送给服务器消息
    MSG_CS_NPC_TASK_CLICK                   =           1011,   -- 点击npc（任务）按钮（链接）
    MSG_CS_NPC_STORE_SELL_PRE		        =		    1012,   -- NPC商店预出售道具
    MSG_CS_NPC_STORE_SELL_ITEM				=		    1013,   -- NPC商店最终出售道具
    MSG_CS_NPC_STORE_BUY                    =           1014,   -- 点击购买NPC商店某物品
    MSG_CS_NPC_STORE_ITEM_LIST              =           1015,   -- 点击请求NPC商店某物品列表
    MSG_CS_NPC_STORE_REPAIRE_PRE	        =		    1024,   -- NPC商店预修理道具
    MSG_CS_NPC_STORE_REPAIRE_ITEM			=		    1023,   -- NPC商店最终修理道具
    MSG_CS_NPC_MAKE_DRUG					=           1034,   -- NPC商店合成药品
    MSG_CS_NPC_DOSOMETHING                  =		    1206,   -- NPC自定义放入框 有道具后请求

    MSG_SC_NPC_TALK                         =           643,  	-- NPC对话
    MSG_SC_NPC_TALK_BACKGROUND              =           718,    -- NPC对话背景
    MSG_SC_NPC_TALK_CLOSE                   =           644,  	-- NPC对话关闭
    MSG_CS_NPC_TALK_OPEN_NOTIFY				=           1301,   -- NPC打开通知后端
    MSG_CS_NPC_TALK_CLOSE_NOTIFY			=           1302,   -- NPC关闭通知后端
    MSG_SC_NPC_STORE_OPEN                   =           645,  	-- NPC商店物品返回
    MSG_SC_NPC_SELL                         =		    646,	-- NPC出售物品打开
    MSG_SC_NPC_STORE_SELL_PRICE             =           647,  	-- NPC商店出售/修理物品预显示价格返回
    MSG_SC_NPC_STORE_SELL_RESULT_SUCCESS	= 		    648,	-- NPC商店出售结果	成功
    MSG_SC_NPC_STORE_SELL_RESULT_FAIL		= 		    649,	-- NPC商店出售结果	失败
    MSG_SC_NPC_STORE_BUY_RESULT_SUCCESS		= 		    650,	-- NPC商店购买结果	成功
    MSG_SC_NPC_STORE_BUY_RESULT_FAIL		= 		    651,	-- NPC商店购买结果	失败
    MSG_SC_NPC_STORE_ITEM_LIST              =           652,  	-- NPC商店某一物品列表返回
    MSG_SC_UPDATA_MONEY_NUMBER              = 		    653,   	-- 刷新玩家货币
    MSG_SC_NPC_REPAIRE_ITEM					=		    668,	-- NPC打开修理界面
    MSG_SC_NPC_REPAIRE_ITEM_RESULT_SUCCESS	=		    669,	-- NPC商店修理结果	成功
    MSG_SC_NPC_REPAIRE_ITEM_RESULT_FAIL		=		    670,	-- NPC商店修理结果	失败
    MSG_SC_NPC_REPAIRE_ITEM_PRICE			=		    671,	-- NPC商店修理价格
    MSG_SC_NPC_MAKE_DRUG_LIST			    =  		    712,	-- NPC炼药列表
    MSG_SC_NPC_MAKE_DRUG_SUCCESS			=           713,    -- NPC商店合成成功
    MSG_SC_NPC_MAKE_DRUG_FAILED				=           714,    -- NPC商店合成失败
    MSG_SC_NPC_DOSOMETHING                  =		    689,	-- NPC自定义放入框 类似出售修理

    MSG_SC_INIT_MONEY_INFO					= 		    213,	-- 初始化货币数据
    MSG_SC_AFK                              =           20101, 	-- 开启/关闭 自动挂机
    MSG_SC_INTTERUPT_AFK                    =           5283, 	-- 自动挂机打断
    MSG_SC_AUTO_FIND                        =           20102, 	-- 任务
    MSG_SC_STOP_AUTO_FIND                   =           5018, 	-- auto find 停止

    -- *********** Chat ************** --
    MSG_CS_PLAYER_SAY                       =           3030,   -- 说话
    MSG_SC_CHAT_MESSAGE                     =           40,     -- 收到聊天消息                
    MSG_SC_SERVICE_TIPS					    = 		    767,    -- 服务端发起提示弹窗
    MSG_SC_CHAT_AUTO_DELAY                  =           795,    -- 自动喊话时间间隔

    MSG_SC_STOP_FAKE_DROP                           = 5029,     -- 停止/开始假掉落提示 
    MSG_SC_ITEM_DROP_MSG_NEW                        = 5037,     -- 新物品掉落消息参数
    MSG_SC_FAKE_DROP_SPEED_UP                       = 5038,     -- 假掉落消息速度改变

    -- *********** system store ************** --
    MSG_CS_REQUEST_DATA_BY_PAGE				=           1046,	-- 根据页签获取对应的数据
    MSG_SC_GOTDATA_BY_PAGE					=           938,	-- 服务端根据页签返回数据	recog 页签 json 数据
    MSG_CS_PAGE_STORE_REQUEST_BUY_ITEM		=           1047,	-- 请求购买道具 参数 页签 道具ID
    MSG_CS_REQUEST_DATA_BY_INDEX			=           1116,	-- 根据商品ID获取对应的数据

    -- *********** Guild ************** --
    MSG_CS_GUILD_OPERATE                                = 1100,     -- 请求 客户端行会统一操作消息
    MSG_SC_GUILD_OPERATE                                = 763,      -- 返回 操作行会错误或提示统一下发数据
    MSG_SC_GUILD_MSG                                    = 762,      -- 返回 行会统一下发数据
    MSG_SC_SHABAKEGUILD_INFO                            = 6231,     -- 沙巴克行会消息

    --*********** Team **************-
    MSG_CS_GROUPOPERATE                             = 1020,     -- 请求 组队
    MSG_SC_GROUPMSG                                 = 660,      -- 返回 组队
    MSG_SC_GROUPMSG_FAIL                            = 661,      -- 返回 组队错误信息
    --*************Friend****************-
    MSG_CS_FRIENDOPERATE                            = 1101,     -- 请求 好友
    MSG_SC_FRIENDMSG                                = 972,      -- 返回 好友
    MSG_SC_FRIENDERRO                               = 973,      -- 返回 好友错误信息
    --*************Mail****************-
    MSG_CS_EMAIL_LIST                               = 3078,     -- 请求邮件列表
    MSG_SC_EMAIL_LIST                               = 874 ,     -- 返回邮件列表
    MSG_SC_EMAIL_NEW_NOTICE                         = 873,      -- 新邮件到来
    MSG_CS_EMAIL_READ                               = 3079,     -- 读邮件  --1 为keyid 内容为时间
    MSG_CS_EMAIL_DELETE                             = 3080,     -- 删除邮件 
    MSG_SC_EMAIL_TAKE_STATE_RESPONSE                = 3227,     -- 邮件收货状态
    MSG_CS_EMAIL_DELETE_ALL_READ                    = 3181,     -- 删除全部邮件(删除已读)
    MSG_SC_EMAIL_DELETE_ALL_READ                    = 936,      -- 服务器返回 删除全部邮件
    MSG_CS_EMAIL_GET                                = 3081,     -- 领取物品 （一键领取 param1 = 0，param2 = 1） （ param1 = keyid  param2 = 0  时间）
    MSG_SC_EMAIL_GET                                = 937,      -- 物品领取成功     
    --************trade************--
    MSG_CS_TRADING_INFO_REQUEST                    	= 1025,     -- (请求): 请求或同意和某人进行交易
    MSG_SC_TRADE_TRADER_RESULT						= 674,      -- (回复): 请求交易的结果 以及一些其他的错误码
    MSG_CS_TRADE_SEND_REQUEST                    	= 1112,     -- (回复)：xx请求和你交易
    MSG_SC_TRADE_INFO_RESPONSE						= 982,		-- 收到交易请求 	recog = 0 主动发起方收到的  recog 被交易方收到的
    MSG_SC_TRADING_ACCEPT_ALL                       = 673,      -- (回复)：打开交易对话框，参数1：对方是否是好友  参数2：对方是否是同行会
    MSG_CS_TRADING_CANCEL						    = 1028,     -- (请求): 取消交易
    MSG_CS_TRADING_TRADE						    = 1030,     -- (请求): 确定交易
    MSG_SC_TRADING_CANCEL                           = 681,      -- (回复): 取消交易  参数1为类型（0：系统，大于0时表示由玩家发起的取消交易，该参数是玩家的ID)
    MSG_SC_TRADING_TRADER_CHANGE_MONEY              = 686,      -- (回复): 对方交易货币修改，参数1:数量
    MSG_CS_TRADING_MYSELF_CHANGE_MONEY              = 1029,     -- (请求): 修改交易货币，参数1：数量
    MSG_SC_TRADING_MYSELF_CHANGE_MONEY_FAIL			= 685,		-- (回复)：放入金币失败
    MSG_SC_TRADING_MYSELF_CHANGE_MONEY              = 684,      -- (回复): 自己收到交易货币修改，参数1是结果，参数2是货币类型，参数3是数量  结果：0：成功 -2：金币不足，-3：元宝不足
    MSG_SC_TRADING_TRADER_PUTIN_ITEM                = 682,      -- (回复): 收到交易对方的物品放入消息 json 中
    MSG_SC_TRADING_TRADER_PUTOUT_ITEM               = 683,      -- (回复): 收到交易对方的物品取出消息 json 中
    MSG_CS_TRADING_MYSELF_PUTIN_ITEM                = 1026,     -- (请求): 参数1 放入 唯一ID 字符串 道具名
    MSG_CS_TRADING_MYSELF_PUTOUT_ITEM               = 1027,     -- (请求): 参数1 取出 唯一ID 字符串 道具名
    MSG_SC_TRADING_MYSELF_PUTIN_ITEM_SUCCESS        = 675,      -- (回复): 放入物品结果 成功
    MSG_SC_TRADING_MYSELF_PUTIN_ITEM_FAIL       	= 676,      -- (回复): 放入物品结果 失败
    MSG_SC_TRADING_MYSELF_PUTOUT_ITEM_SUCCESS       = 677,      -- (回复): 取回物品结果 成功
    MSG_SC_TRADING_MYSELF_PUTOUT_ITEM_FAIL       	= 678,      -- (回复): 取回物品结果 失败
    MSG_SC_TRADING_LOCK_CHANGE_STATUS             	= 688,      -- (回复): 收到双方状态改变: 参数1是类型（0取消锁定，1锁定）
    MSG_CS_CHANGE_MY_TRADE_STATE             		= 1152,     -- (请求): 请求改变状态：参数1类型（0取消锁定，1申请锁定）
    MSG_SC_TRADING_SUCCESSFUL                       = 687,      -- (回复): 交易成功

    --**************************************** 采集 **********************************************************
    MSG_CS_COLLECT_REQUEST                       	= 3005,     -- 采集 - 请求
    MSG_CS_COLLECT_COMPLETED                       	= 3006,     -- 采集完成 - 请求
    MSG_SC_COLLECT_COMPLETED                        = 3007,     -- 采集完成 - 返回状态

    -- ---------------------------------------- Net Message Type ---------------------------------------- 
    MSG_CS_SERVER_TIME_REQUEST						= 60001,    --请求服务器的时间
    MSG_SC_SERVER_TIME_RESPONSE						= 60001,    --返回服务器时间
    MSG_SC_ACROSS_DAY_RESPONSE						= 60002,    --跨天

    MSG_CS_OPEN_DOOR_REQUEST						= 1002,     --请求开门
    MSG_SC_OPEN_DOOR_NOTICE							= 612,      --通知开门
    MSG_SC_CLOSE_DOOR_NOTICE						= 614,      --通知关门

    MSG_CS_PICK_CORPSE 								= 1007,     --挖尸体
    MSG_SC_ACTION_PICK_CORPSE						= 637,	    --广播 挖尸体动作

    MSG_SC_MISSION_CHANGE                           = 55,       -- 任务数据 返回
    MSG_SC_MISSION_SUBMIT                           = 3031,     -- 任务数据 请求
    MSG_SC_MISSION_TOP                              = 3218,   -- 任务置顶

    MSG_SC_LOOK_STATUS_REQUEST                      = 1076,     --查询玩家组队和行会信息
    MSG_SC_LOOK_STATUS_RESPONSE                     = 968,      --返回
    MSG_CS_PERMIT_REQUEST                    	    = 5278,     --允许组队 交易 等
    MSG_SC_PERMIT_REPONSE						    = 1001, 	--返回

    MSG_CS_GAME_SETTING_CHANGE                      = 5277, -- 请求 设置数据发送

    MSG_CS_REBACK_TO_ROLE                           = 1009, -- 小退

    MSG_CS_SUMMONS_MODE_CHANGE						= 1130, -- 请求 召唤物攻击模式改变

    MSG_SC_SUICOMPONENT_UPDATE                      = 3213, -- 返回 自定义UI组件更新
    MSG_CS_SUICOMPONENT_SUBMIT                      = 3199, -- 请求 自定义UI组件点击响应
    MSG_CS_SCRIPT_TRIGGER                           = 6202, -- 返回 脚本响应
    MSG_SC_SCRIPT_TRIGGER                           = 6202, -- 请求 脚本响应

    MSG_CS_REQUEST_AUTO_STALL                       = 1059, -- 请求自动摆摊
    MSG_CS_REQUEST_STALL_INFO                       = 1201, -- 请求摆摊数据
    MSG_SC_RESPONE_STALL_INFO                 		= 218, 	-- 摆摊数据
    MSG_CS_REQUEST_STALL_BUY_ITEM                   = 1202, -- 请求购买摆摊物品
    MSG_SC_SELL_NOTICE								= 219,  --摆摊

    MSG_SC_ITEMBOX_UPDATE                           = 993,  -- ITEMBOX 返回更新
    MSG_SC_ITEMBOX_REMOVE                           = 994,  -- ITEMBOX 返回删除
    MSG_CS_ITEMBOX_PUTIN                            = 1203, -- ITEMBOX 请求放入
    MSG_CS_ITEMBOX_PUTOUT                           = 1204, -- ITEMBOX 请求取出

    MSG_SC_OPEN_URL									= 3214, --打开网页

    MSG_SC_FIRE_WORK_TX_REPONSE						= 1211,	-- 服务器消息 烟花特效

    MSG_CS_TITLE_REQUEST  				            = 5400,	--称号
    MSG_SC_TITLE_REPONSE 				            = 1200,

    MSG_SC_PLAY_AUDIO								= 6097,	-- 播放声音
    MSG_SC_REMOVE_TIMER_NOTICE						= 6098,	-- 清理定时公告

    MSG_SC_SIEGEWAR_STATUS_CHANGE					= 6099, -- 攻城战状态改变

    MSG_CS_CLOUD_STORAGE_CHANGE  			        = 1148, -- 请求 云端存储改变

    MSG_SC_OPENUI									= 3215,	-- 返回 打开界面

    MSG_SC_ACTOR_EFFECT_UPDATE						= 6200,	-- 返回 actor 特效刷新
    MSG_SC_ADD_NPC_EFFECT						    = 2980,	-- 返回 增加NPC特效
    MSG_SC_RMV_NPC_EFFECT						    = 2981,	-- 返回 删除NPC特效

    MSG_SC_PLAY_DICE								= 8001,	-- 返回 播放骰子动画

    MSG_CS_FIND_MAP_MONSTER							= 5284,	-- 请求 附近怪物
    MSG_SC_FIND_MAP_MONSTER							= 1510,	-- 返回 附近怪物

    MSG_CS_AUCTION_ITEM_LIST                        = 1120, -- 请求 拍卖物品列表
    MSG_SC_AUCTION_ITEM_LIST                        = 1111, -- 返回 拍卖物品列表
    MSG_CS_AUCTION_BID                              = 1122, -- 请求 竞拍
    MSG_SC_AUCTION_BID                              = 1112, -- 返回 竞拍
    MSG_CS_AUCTION_PUT_IN                           = 1119, -- 请求 上架
    MSG_SC_AUCTION_PUT_IN                           = 1110, -- 返回 上架
    MSG_CS_AUCTION_PUT_OUT                          = 1124, -- 请求 下架
    MSG_SC_AUCTION_PUT_OUT                          = 1114, -- 返回 下架
    MSG_CS_AUCTION_REPUT_IN                         = 1125, -- 请求 重新上架
    MSG_CS_AUCTION_LEAVE                            = 1121, -- 请求 告诉服务器关闭界面
    MSG_CS_AUCTION_ACQUIRE                          = 1123, -- 请求 领取物品
    MSG_SC_AUCTION_ACQUIRE                          = 1113, -- 返回 领取物品
    MSG_SC_AUCTION_ITEM_UPDATE                      = 1115, -- 返回 物品更新
    MSG_CS_AUCTION_PUT_LIST                         = 1154, -- 返回 上架列表
    MSG_SC_AUCTION_PUT_LIST                         = 1130, -- 返回 上架列表
    MSG_SC_AUCTION_PUT_COUNT                        = 1137, -- 返回 上架数量
    MSG_SC_AUCTION_PUT_LIST2                        = 1230, -- 返回 上架列表(数据太多有些一次性发不完,分两次)

    MSG_SC_PRODUCT_INFO								= 735,	-- 返回 充值商品
    MSG_SC_RECHARGE_RECEIVED						= 1523,	-- 返回 充值到账
    MSG_SC_RECHARGE_COMPLETE						= 6203,	-- 返回 完成
    MSG_CS_RECHARGE_ORDER_NO                        = 1390, -- 返回 订单号
    MSG_SC_RECHARGE_ORDER_NO                        = 1390, -- 返回 订单号

    MSG_SC_HYPERLINK_JUMP						    = 1109,	-- 返回 超链跳转
    
    MSG_SC_PROGRESS_BAR						        = 969,	-- 返回 进度条

    MSG_SC_OPEN_TREASUREBOX                         = 1134,
    MSG_CS_TREASUREBOX_INFO                         = 1133,
    MSG_SC_OPEN_TREASUREBOX_AGAIN                   = 1135,
    MSG_SC_TREASUREBOX_REWARD                       = 1136,

    	-- *********** rank ************** --
    MSG_CS_RANK_LIST_DATA_REQUEST                   = 5261,    -- 排行榜列表消息#请求消息号：5261，参数1：榜的类型
    MSG_SC_RANK_LIST_DATA_RESPONSE                  = 792,     -- 排行榜列表消息#参数1：返回消息号：792，榜的类型，字符串参数为json榜单数据 
    MSG_CS_RANK_PLAYER_DATA_REQUEST                 = 5262,    -- 排行榜个人外观数据查询
    MSG_SC_RANK_PLAYER_DATA_RESPONSE                = 717,     -- 排行榜个人外观数据 返回
    MSG_CS_RANK_SET_CONFIG_REQUEST                  = 5259,     -- 请求排行榜配置列表
    MSG_SC_RANK_SET_CONFIG_RESPONSE                 = 793,      -- 返回排行榜配置列表
    MSG_CS_CLICK_RANK_TYPE                          = 5266,     -- 点击排行榜英雄/人物分类触发
    MSG_CS_CLICK_RANK_VALUE                         = 5267,     -- 点击排行榜名单排名触发


    MSG_SC_EQUIP_RETRIEVE_RESPONSE                  = 780,  --装备回收

    MSG_CS_MINIMAP_MONSTERS_POINT                   = 5012, -- 请求 小地图 怪物坐标
    MSG_SC_MINIMAP_MONSTERS_POINT                   = 5012, -- 返回 小地图 怪物坐标

    MSG_SC_STORAGE_UPDATE                           = 736,  --仓库，存物品时候，存的叠加物品，需要更新
    MSG_CS_KEYCODE_EVENT                            = 2021, -- 服务器响应键盘

    MSG_CS_SCRIPT_ZHENBAO                           = 6900, --通知脚本打开珍宝界面
    MSG_SC_CLIPBOARD_TEXT                           = 1201, -- 复制文本

    -- *********** scene *********** --
    MSG_SC_RESPONE_SCENE_SHAKE                      = 6901, -- 屏幕震动


    ---zfs begin----
    MSG_CS_OPENHYPERCHECK                           = 1107,  --检测打开面板触发
    MSG_SC_OPENHYPERCHECK                           = 1108, --打开面板触发返回
    MSG_SC_EQUIP_Embattle_RESPONSE_HERO             = 1384, --刷新装备栏特效 参考 781
    MSG_SC_EQUIP_Embattle_RESPONSE                  = 781,  --装备特效id(类似法阵)
    -- MSG_SC_OPENHEALTH                               = 1100, --打开HP显示
    MSG_SC_CLOSEHEALTH                              = 1101, --关闭HP显示
    MSG_SC_BESTRONG_TIPS                            = 6902, --提升提示
    MSG_SC_GUIDE_TIPS                               = 6903, --新手引导
    MSG_SC_REDDOT_TIPS                              = 6904, --红点提示
    MSG_SC_BUBBLE_TIPS_CUSTOM                       = 6905, --气泡提示自定义按钮
--------------hero
    MSG_SC_HERO_AbilEx                              = 1002, -- 英雄额外属性下发

    MSG_CS_HERO                                     = 3500, -- 请求召唤英雄、退出英雄
    MSG_SC_HERO_DIE                                 = 3517, -- 英雄死亡
    MSG_SC_PLAYER_EQUIP_INFO_HERO                   = 3078, -- 英雄装备信息
    
    MSG_SC_PLAYER_SKILL_DATA_HERO                   = 3085, -- 英雄技能
    MSG_SC_PLAYER_NAMEANDID_HERO                    = 3087, --英雄名字颜色 uid
    MSG_CS_HERO_ATTACK_MODE                         = 3508, -- 英雄攻击模式 0-2攻击 跟随 休息
    MSG_SC_HEROLOGIN                                = 3705, -- 英雄出生
    MSG_SC_HEROLOGOUT                               = 3706, -- 英雄退出
    MSG_SC_PLAYER_STATE_HERO                        = 3709,   -- 英雄状态
    MSG_CS_USE_BAG_ITEM_HERO                        = 3509,   -- 主动使用物品--1006
    
    MSG_SC_BAG_ITEM_USE_FAILED_HERO                 = 3097, -- 道具使用失败--636
    MSG_CS_LOCKTARGET_HERO                          = 3510,--锁定目标 和守护位置
    MSG_CS_LOCKTARGET_CANCEL_HERO                   = 3515,--取消
    
    MSG_CS_MAP_ITEM_DISCARD_HERO                    = 3516,   -- 物品丢弃，通知服务器
    MSG_SC_DROP_ITEM_SUCCESS_HERO                   = 1382,    -- 丢弃道具成功
    MSG_SC_DROP_ITEM_FAILED_HERO                    = 1383,    -- 丢弃道具失败

    -- Bag
    MSG_SC_RETURN_BAGDATA_HERO                      = 3082, --英雄包裹物品
    MSG_SC_BAG_ADD_ITEM_HERO                        = 3083, --返回 - 增加道具
    MSG_SC_BAG_DEL_ITEM_HERO                        = 3084,--返回 - 删除道具
    MSG_CS_HUMBAG_TO_HEROBAG                        = 3504, --人物背包到英雄背包
    MSG_CS_HEROBAG_TO_HUMBAG                        = 3505, --英雄背包到人物背包
    MSG_SC_HUMBAG_TO_HEROBAG_FAIL                   = 3090, --人物背包到英雄背包失败
    MSG_SC_HEROBAG_TO_HUMBAG_FAIL                   = 3091,  --英雄背包到人物背包失败
    MSG_SC_BAG_UPDATE_ITEM_HERO                     = 3088, --英雄更新物品
    -----
    ---skill 
    MSG_SC_PLAYER_ADD_SKILL_HERO                    = 3089,    -- 服务器返回新学的技能(英雄)   
    MSG_SC_PLAYER_DEL_SKILL_HERO                    = 3094,    -- 服务器返回删除的技能(英雄)  
    MSG_SC_PLAYER_UP_SKILL_HERO                     = 3095,    -- 更新技能
    MSG_CS_PLAYER_ONOFF_SKILL_HERO                  = 3512,     --开关技能
    
    ----
    --怒气
    MSG_SC_ANGER_HERO                               = 3098, --怒气值
    --开启合击
    MSG_CS_JOINTATTACK_HERO                         = 3511,--开启合击
    MSG_SC_JOINTATTACK_HERO                         = 3099,--开启合击 播放特效+攻击
    MSG_SC_EXTRA_EFFECT                             = 3100,--新增附加特效
    MSG_SC_HERO_EFFECT                              = 3101,--英雄身上特效
    -----
 
    --equip
    MSG_CS_PLAYER_EQUIP_ON_REQUEST_HERO             = 3502, --装备穿上请求
    MSG_CS_PLAYER_EQUIP_OFF_REQUEST_HERO            = 3503, -- 装备脱下请求
    MSG_SC_PLAYER_EQUIP_ON_SUCCESS_HERO             = 3700,--穿上戴上成功
    MSG_SC_PLAYER_EQUIP_ON_FAIL_HERO                = 3701,--穿失败
    MSG_SC_PLAYER_EQUIP_OFF_SUCCESS_HERO            = 3702, -- 脱下成功
    MSG_SC_PLAYER_EQUIP_OFF_FAIL_HERO               = 3703,--脱下失败


    MSG_CS_HERO_TAKEON_FROMHUMBAG                   = 3518,--人物背包穿戴英雄身上    
    MSG_CS_HERO_TAKEOFF_HUMBAG                      = 3519,--英雄身上脱到人物背包
    MSG_CS_HUM_TAKEON_FROM_HEROBAG                  = 3520,--英雄背包穿戴人物身上
    MSG_CS_HUM_TAKEOFF_TO_HEROBAG                   = 3521,--脱到英雄背包
    MSG_CS_PLAYER_EQUIP_BEST_RINGS_STATE_HERO           =  3517,    -- 首饰盒状态
    MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE_HERO 	        =  3113,    -- 首饰盒状态改变
    MSG_CS_TITLE_REQUEST_HERO                           =  3514,    --称号
    MSG_SC_TITLE_REPONSE_HERO                           =  3111,
----------
    MSG_CM_GETPLAYERINFO                            = 5030, --查看用户信息 ---交易行用
    MSG_SC_GETPLAYERINFO                            = 5031, --查看用户信息返回


    MSG_SC_SELLROLESUCCESS_LOGOUT                   = 5032, --寄售角色成功 退出
    MSG_SM_BINDHUMMSG                               = 1381, -- 弹实名认证
    MSG_CM_BINDHUMMSG                               = 1380, -- 实名认证结果
    MSG_SC_DAYSTATE                                 = 1210, --昼夜状态
    MSG_SC_CHANGECANDLE                             = 1209,--切换蜡烛状态
    MSG_SC_SENDKILLMONEXPEFF                        = 5040,--飘经验特效
    MSG_SC_REDPOINTVARCHANGE                        = 5024,--前端红点 

    MSG_CS_MOBLOCKTARGET                            = 1141,--宝宝锁定怪物
    MSG_CS_MOBUNLOCKTARGET                          = 1142,--宝宝取消锁定怪物

    MSG_SC_LYTOKEN                                  = 3199,--联运token
    MSG_CS_QUERYBOXSELLITEM                         = 5035,--查询交易行装备tips
    MSG_SC_QUERYBOXSELLITEM                         = 5035,--查询交易行装备tips
    MSG_CS_CHECKBOXSELLITEM                         = 5036,--检测道具是否可以上架
    MSG_SC_CHECKBOXSELLITEM                         = 5036,--返回检测道具是否可以上架
    ---zfs end----

    MSG_SC_SCREEN_EFFECT_PLAY                       = 738,  -- 屏幕播放特效
    MSG_SC_SCREEN_EFFECT_REMOVE                     = 742,  -- 删除屏幕特效

    MSG_SC_JUMP_CHARGE                              = 1202, -- 主动拉起充值

    MSG_CS_QURYSOFTCLOSE                            = 1099, -- 小退 请求小退
    MSG_SC_REBACK_TO_ROLE                           = 5011, -- 小退 服务器返回数据(返回成功即小退)
 
    MSG_SC_PICKUP_MODE_UPDATE                       = 5014, -- 拾取模式

    MSG_SC_PICKUP_SPRITE                            = 5017, -- 拾取精灵
    MSG_CS_PICKSPRITE_PICKUP                        = 5016, -- 拾取精灵 拾取
    MSG_CS_PICKSPRITE_PICKUP_ANI                    = 5019, -- 拾取精灵 拾取动画
    MSG_SC_SET_PICKSPRITE_FLY_DST                   = 5041, --小精灵设置
    MSG_CS_FILTER_PICKUP_ITEM                       = 5017, -- 发送过滤挂机拾取物品


    MSG_SM_COLLIMATOR_RESPONSE                      = 739, --开启准星消息
    MSG_CM_COLLIMATOR_REQUEST                       = 740, --准星瞄准消息
    MSG_CM_CANCELCOLLIMATOR_REQUEST                 = 741, --取消准星瞄准

    MSG_CS_NPC_NEWTYPE_OK                           = 6203, --ok框新type请求
    MSG_SC_REIN_ATTR_RESPONSE                       = 811, --转生属性分配数据
    MSG_CS_REIN_ATTR_CONFIRM                        = 1043, --确认属性点分配

    MSG_CS_JSON_PROTO_HELPER_REQUEST				= 5555, -- 发送 通用服务器jsonProto
    MSG_SC_JSON_PROTO_HELPER_RESPONSE				= 5555, -- 返回

    MSG_CS_SSR_NETWORK_REQUEST			        	= 9001, -- 发送 通用服务器ssr net proto
    MSG_SC_SSR_NETWORK_RESPONSE   				    = 9001, -- 返回

    MSG_CS_SSR_LUA_NETWORK_REQUEST			        = 9002, -- 发送 通用服务器ssr net proto
    MSG_SC_SSR_LUA_NETWORK_RESPONSE   			    = 9002, -- 返回

    MSG_CS_AUTO_MOVE_NOTIFY                         = 5013, -- 通知服务器自动寻路
    MSG_SC_AUTO_MOVE                                = 5013, -- 服务器自动寻路

    MSG_SC_SETITEMLOOKS                             = 719,  -- 设置物品内观

    MSG_SC_REMOVE_TIMER_NOTICEXY                    = 114,  -- 删除新倒计时提示
    
    MSG_SC_START_APP                                = 6204, -- 服务器通知 拉起app

    MSG_CS_UPDATE_MODEL_CONFIG                      = 6205, -- 请求 刷新模型表

    MSG_CS_TEAMMEMEBER_DATA                         = 6206,  --请求组队成员信息
    MSG_SC_MINIMAP_TEAM_DATA                        = 6206,  --返回组队成员信息
    
    MSG_SC_PLAYER_SKILL_82_SUCCESS                  = 10060, -- 十步一杀瞬移成功

    MSG_SC_PLAY_MAGICBALL_EFFECT                    = 2982,  -- 魔血球特效

    MSG_SC_PLAYER_SKILL_71_SUCCESS                  = 10071, -- 擒龙手瞬移
    
    MSG_REQUEST_SUSPECTINFO                         = 59999, -- 网易盾数据上报

    MSG_SC_PLAYER_RELIVE_STATE                      = 2983,  -- 是否可复活状态

    MSG_SC_NORUNONLYMSG                             = 721,   -- 禁止跑
    MSG_SC_PLAYER_CANCHANGE_MODE                    = 722,   -- 可改变的攻击模式

    MSG_CS_GET_DAWANKA_INFO                         = 9100,  -- 请求大玩咖数据
    MSG_CS_SEND_XULEI_VIP                           = 9101,  -- 发送迅雷vip数据

    MSG_SC_NOT_AUTO_TIPS_EQUIPS                     = 1340,  -- 禁止弹出自动穿戴

    MSG_SC_USE_CDK                                  = 3217, --兑换码

    MSG_SC_SKILL_ACTION_CONFIRM_SUCCESS             = 9999,   -- 主玩家技能行为确认

    MSG_SC_PLAYER_UP_SKILL_CD                       = 5021,   -- 技能CD改变

    MSG_SC_REST_SKILL_CD                            = 5043,   -- 重置技能CD

    MSG_CS_CLICK_REMOTE_MAP                         = 5044,   -- 通知 跨地图点击地图坐标

    MSG_SC_UPDATE_SKILL_CD_NEW                      = 5045,   -- 技能最大/当前CD改变 - 新


--------------------宠物
    MSG_CS_PETS_TAKEON_ITEM_REQUEST                 = 4500,     -- 宠物穿戴装备请求
    MSG_CS_PETS_TAKEOFF_ITEM_REQUEST                = 4501,     -- 宠物脱下装备请求
    MSG_CS_RECALL_PETS_REQUEST                      = 4502,     -- 召唤指定宠物出战
    MSG_CS_PETS_WAER_EQUIP_REQUEST                  = 4503,     -- 查询宠物身上装备

    MSG_SC_USER_PETS_DATA_INFO                      = 6400,     -- 宠物信息下发
    MSG_SC_PETS_TAKEON_SUCCESS                      = 6500,     -- 宠物穿装备成功
    MSG_SC_PETS_TAKEON_FAIL                         = 6501,     -- 宠物穿装备失败
    MSG_SC_PETS_TAKEOFF_SUCCESS                     = 6502,     -- 宠物脱装备成功
    MSG_SC_PETS_TAKEOFF_FAIL                        = 6503,     -- 宠物脱装备失败
    MSG_SC_PETS_EQUIP_INFO                          = 6504,     -- 宠物当前装备信息
    MSG_SC_PETS_ADD_ITEM                            = 6505,     -- 宠物增加装备
    MSG_SC_PET_PROPERTIES                           = 6506,     -- 宠物属性数据
    MSG_SC_PETS_DEL_EQUIP                           = 6507,     -- 宠物删除装备
    MSG_SC_PETS_SELECTED_ORBACK                     = 6508,     -- 当前选中宠物/收回

    MSG_CS_AUTOPLAYGAME_REQUEST                     = 9102, -- 前端发送自动挂机消息(快捷键时发送)
    
    MSG_CS_SENDBOXGIFTLIST_REQUEST                  = 6208, --996传奇盒子  请求盒子礼包内容
    MSG_SC_SENDBOXGIFTLIST_RESPON                   = 6208, --996传奇盒子  服务端返回盒子礼包内容
    MSG_CS_SENDBOXGIFTSTATE_REQUEST                 = 6209, --996传奇盒子  请求盒子礼包领取状态
    MSG_SC_SENDBOXGIFTSTATE_RESPON                  = 6209, --996传奇盒子  服务端返回盒子礼包领取状态
    MSG_CS_GETBOXGIFTBYTYPE_REQUEST                 = 6210, --996传奇盒子  请求盒子礼包
    MSG_CS_SETBOXGIFTSTATE_REQUEST                  = 6211, --996传奇盒子  请求称号显示状态
    MSG_CS_SENDBOXGIFTBUTTONID_REQUEST              = 6212, --996传奇盒子  点击相关界面按钮时发送数据上报
    MSG_SC_GET_AWARD_STATET_RESPON                  = 6213, --996盒子      领取礼包返回的提示
    MSG_SC_GET_INFORMATION_RESPON                   = 3102, --收集个人数据
    MSG_SC_GET_EVERYDAY_CHARGE                      = 3105, --每日充值信息

    MSG_SC_PLAY_WEATHER_EFFECT                      = 6909, --地图增加天气效果
    MSG_SC_PLAY_MAP_ALL_WEATHER                     = 6910, --进地图下发所有天气效果
    MSG_SC_CLEAR_WEATHER_BY_MAP                     = 6911, --清理当前地图某个天气效果

    MSG_CS_TELL_CHAT_VISIBLE                        = 5023, --通知聊天框显示隐藏状态 (触发)
    MSG_CS_UNLOCK_BAG_SIZE                          = 5022, --解锁新的背包格子 (触发)

    MSG_SC_HORSE_UP                                 = 3220, --上马
    MSG_SC_HORSE_DOWN                               = 3221, --下马

    MSG_CS_HORSE_INVITE                             = 3183, --邀请上马
    MSG_CS_HORSE_AGREE                              = 3184, --同意上马
    MSG_SC_HORSE_INVITE                             = 3222, --后端  邀请上马

    MSG_CS_BIGTIP_CLICK                             = 5025, --大血条头像点击
    
    MSG_SC_SERVER_INFO_UPLOAD                       = 60000, -- 上报服务器信息到后台

    MSG_CS_YWPACKINFO_REQUEST                       = 6530, --进入游戏上报云手机信息

    MSG_SC_ACTOR_MOVE_EFF                           = 5042, --玩家移动特效

    MSG_SC_SENDMAGICSCRIPTEFFECT                    = 3224, --个人的技能表现修改列表

    MSG_CS_MagicOnOff                               = 1140, --开关型技能单控

    MSG_CS_CHANGESAFEAREA                           = 5285, --脚本进出安全区操作

    MSG_SC_NET_PLAYER_MOVE_FORCE                    = 59,   --强制移动

    MSG_SC_INITMAGICCD                              = 1183, --所有CD归0

    MSG_SM_ACTOR_AUTO_MINING                        = 9103, --挖矿

    MSG_CS_HROSEDOWN                                = 3185, -- 下马

    MSG_CS_MODIFY_RESOLUTION                        = 3225, -- 修改分辨率触发


    MSG_SC_PLAYER_NG_SKILL_DATA                     = 6215,     -- 内功技能列表数据
    MSG_SC_PLAYER_ADD_NG_SKILL                      = 6214,     -- 添加内功技能(主角)
    MSG_SC_PLAYER_DEL_NG_SKILL                      = 6216,     -- 删除内功技能(主角)
    MSG_CS_PLAYER_ONOFF_INTERNAL_SKILL              = 1008,     -- 请求内功技能开关(主角)

    MSG_SC_HERO_NG_SKILL_DATA                       = 6218,     -- 内功技能列表数据(英雄)
    MSG_SC_HERO_ADD_NG_SKILL                        = 6217,     -- 添加内功技能(英雄)
    MSG_SC_HERO_DEL_NG_SKILL                        = 6219,     -- 删除内功技能(英雄)

    MSG_CS_GET_NG_SKILL_DATA                        = 6220,     -- 请求内功技能数据(英雄/人物)

    MSG_CS_MERIDIAN_ACUPOINT_OPEN                   = 6221,     -- 请求经络穴位开启
    MSG_CS_MERIDIAN_LEVELUP                         = 6222,     -- 请求某经络升级
    MSG_CS_MERIDIAN_GET_INFO                        = 6223,     -- 请求经络信息
    MSG_SC_MERIDIAN_GET_INFO                        = 6223,     -- 返回经络信息
    MSG_SC_MERIDIAN_INFO_UPDATE                     = 6224,     -- 经络信息更新

    MSG_CS_SET_COMBO_SKILL                          = 6226,     -- 请求设置连击技能
    MSG_SC_SET_COMBO_SKILL                          = 6227,     -- 设置连击技能返回
    
    MSG_SC_SET_COMBO_SKILL_OPEN_NUM                 = 6229,     -- 连击技能格子数

    MSG_SC_GAME_DATA_SET                            = 6913,     -- GAME_DATA表部分字段下发(服务端共用)
    MSG_CS_SERVER_CONFIG                            = 6512,     -- GAME_DATA表请求下发
    MSG_SC_SERVER_CONFIG                            = 6512,     -- GAME_DATA表请求下发

    MSG_SC_ADD_ATTR_RESPONSE                        = 812,      -- 属性已加点数据 [新版]
    MSG_CS_ADD_ATTR_CONFIRM                         = 1048,     -- 确认属性点分配 [新版]

    MSG_CS_WALKEX                                   = 3012,     -- 跑步一格
    MSG_SC_WALKEX                                   = 12,       -- 跑步一格

    MSG_CS_PURCHASE_ITEM_LIST                       = 1510,     -- 请求 求购物品列表
    MSG_SC_PURCHASE_ITEM_LIST                       = 3300,     -- 返回 求购物品列表
    MSG_CS_PURCHASE_PUT_IN                          = 1511,     -- 请求 上架求购
    MSG_CS_PURCHASE_PUT_OUT                         = 1512,     -- 请求 下架求购
    MSG_CS_PURCHASE_TAKE_OUT                        = 1513,     -- 请求 取出已收
    MSG_CS_PURCHASE_SELL                            = 1514,     -- 请求 出售
    MSG_CS_PURCHASE_CLOSE                           = 1515,     -- 通知服务端关闭求购面板
    MSG_SC_PURCHASE_OPERA                           = 3301,     -- 操作返回
    MSG_SC_PURCHASE_UPDATE                          = 3302,     -- 数据刷新 

    MSG_CS_EXCHANGE_ITEM_LIST                       = 1520,     -- 请求 交易所物品列表
    MSG_SC_EXCHANGE_ITEM_LIST                       = 3310,     -- 返回 交易所物品列表
    MSG_CS_EXCHANGE_PUT_IN                          = 1521,     -- 请求 上架交易所
    MSG_CS_EXCHANGE_PUT_OUT                         = 1522,     -- 请求 下架交易所
    MSG_CS_EXCHANGE_SELL                            = 1524,     -- 请求 购买
    MSG_CS_EXCHANGE_CLOSE                           = 1525,     -- 通知服务端关闭交易所面板
    MSG_SC_EXCHANGE_OPERA                           = 3311,     -- 操作返回
    MSG_SC_EXCHANGE_UPDATE                          = 3312,     -- 数据刷新 
    MSG_CS_EXCHANGE_ITEM_PRICE                      = 1526,     -- 请求 查询交易所物品价格
    MSG_SC_EXCHANGE_ITEM_PRICE                      = 3313,     -- 返回 交易所物品列表

    MSG_SC_MOBILE_DEVICE_INFO                       = 5026, -- 移动设备信息

    MSG_CS_NOTICE_FPS                               = 5027,     -- 告诉服务端游戏帧率

    MSG_SM_CASTLEMAPINFO                            = 9108,     -- 服务器开关配置修改

    MSG_SC_MOBILE_SDK_INFO                          = 5028, --移动端sdk参数信息（appid appkey channel等）

    MSG_SC_FIGHT_BACK_ID                            = 6532,     -- 服务端强制通知反击 (针对护身状态的掉蓝)

    MSG_SC_LIMIT_DISTANCE_ESCORT                    = 3200,     -- 限制和镖车的走跑距离

    MSG_CS_RELATION_OPERATE                         = 1102,     -- 请求 关系网操作
    MSG_SC_RELATION_OPERATE                         = 920,      -- 返回 关系网操作



    MSG_CS_SERVER_CUSTOM_VAR                        = 622,       -- 发送 请求服务器自定义变量
    MSG_SC_SERVER_CUSTOM_VAR                        = 622,       -- 返回
    MSG_SC_SERVER_BATCH_CUSTOM_VAR                  = 623,       -- 批量 服务器自定义变量

    MSG_CS_GUI_PROTO_HELPER_REQUEST				    = 6666,      -- 发送 通用服务器 GUI
    MSG_SC_GUI_PROTO_HELPER_RESPONSE				= 6666,      -- 返回

    MSG_SC_CHANGE_KF                                = 5050,      -- 通知客户端切换服务器

    MSG_SM_UPDATEITEMTIME                           = 204,      --玩家物品包括装备、背包
    MSG_SM_HEROUPDATEITEMTIME                       = 3106,     --英雄物品

    MSG_CS_SERVER_SAVE_MONSTER                        = 5001,       -- 发送，请求服务器保存内挂配置不攻击怪物
    MSG_SC_SERVER_SAVE_MONSTER                        = 5001,       -- 返回

}


local proxy = {}
local mt    = {
    __index = M,
    __newindex =  function (t ,k ,v)
        error("forbid set MSG_TYPE value")
    end
} 
setmetatable(proxy, mt)

return proxy