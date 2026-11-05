local LexicalHelper = class("LexicalHelper")

local slen = string.len
local sgsub = string.gsub
local sfind = string.find
local strim = string.trim
local sformat = string.format

local Element = require("sui/Element")

function LexicalHelper:ctor()
end

function LexicalHelper:checkElement(etype, kvmap)
    if etype == "Img" then
        if not kvmap.img or kvmap.img == "" then
            return false
        end
        if (not sfind(kvmap.img, ".png")) and (not sfind(kvmap.img, ".jpg")) then
            return false
        end
    end

    return true
end

function LexicalHelper:Parse(source)
    local elements = {}
    if not source or source == "" then
        return elements
    end

    -- 
    source = string.gsub(source, "[\t\n\r]", "")
    source = string.gsub(source, "<>", "")

    local names = 
    {
        "Img",
        "Text",
        "RText",
        "Input",
        "Button",
        "Effect",
        "Frames",
        "Layout",
        "CheckBox",
        "ListView",
        "ItemShow",
        "COUNTDOWN",
        "ITEMBOX",
        "EquipShow",
        "BAGITEMS",
        "EQUIPITEMS",
        "DBItemShow",
        "TIMETIPS",
        "TextAtlas",
        "LoadingBar",
        "CircleBar",
        "PercentImg",
        "UIModel",
        "HEROEquipShow",
        "HEROEQUIPITEMS",
        "HERODBItemShow",
        "HEROBAGITEMS",
        "QuickTextView",
        "RTextX",
        "DLINKITEMS",
        "MKItemShow",
        "PETEQUIPSHOW",
        "PageView",
        "Slider",
        "MenuItem",
        "ScrapePic",
        "BmpText",
        "CostItem",
        "MiniMap"
    }
    for i, v in ipairs(names) do
        local origin  = sformat("<%s|", v)
        local replace = sformat("\n<%s|", v)
        source = string.gsub(source, origin, replace)
    end

    local source_lines = G_GetSplitArray(source, "\n")
    for line, content in ipairs(source_lines) do
        if slen(content) > 0 then
            self:parse_oneline(elements, content)
        end
    end

    return elements
end

function LexicalHelper:parse_kvmap(source)
    local function parse(str)
        local pattern = {sfind(str, "(.-)=(.+)")}
        if pattern[1] and pattern[2] then
            local key   = strim(pattern[3])
            local value = strim(pattern[4])
            return {key=key, value=value}
        end
        return nil
    end
    
    local kvmap = {}
    local kv_source = G_GetSplitArray(source, "|")
    for _, v in ipairs(kv_source) do
        local kv = parse(v)
        if kv then
            kvmap[kv.key] = kv.value
        end
    end
    return kvmap
end

function LexicalHelper:push_element(elements, etype, kvmap)
    local element = Element.new()
    element.type  = etype
    element.attr  = kvmap

    table.insert(elements, element)
end

function LexicalHelper:parse_oneline(elements, content)
    while content and slen(content) > 0 do
        local find_info = {sfind(content, "<(%a-)|(.+)>")}
        local begin_pos = find_info[1]
        local end_pos   = find_info[2]

        if begin_pos and end_pos then
            -- prefix
            if begin_pos ~= 1 then
                local substr = string.sub(content, 1, begin_pos - 1)
                local etype  = "RText"
                local kvmap  = {text = substr}
                self:push_element(elements, etype, kvmap)
            end

            -- element
            local etype = strim(find_info[3])
            local kvmap = self:parse_kvmap(find_info[4])
            if self:checkElement(etype, kvmap) then
                self:push_element(elements, etype, kvmap)
            else
                -- print("del", etype, find_info[4])
            end

            -- suffix
            content = string.sub(content, end_pos+1, slen(content))
        else
            -- push text
            local etype = "RText"
            local kvmap = {text = content}
            self:push_element(elements, etype, kvmap)

            content = ""
        end
    end
end

-- ++++++++++++++++++++++++++++++++++++++++++
-- 通用属性 
-- id               元素ID ！！禁止使用 default_x (x为数字 1 2 3) 
-- children         子节点
-- link             响应事件
-- ax               锚点X
-- ay               锚点Y
-- x                坐标X
-- y                坐标Y
-- percentx         坐标X 百分比
-- pencenty         坐标Y 百分比
-- width            宽
-- height           高
-- percentwidth     宽 百分比
-- percentheight    高 百分比
-- tips             鼠标悬停提醒文本 (非PC端可点击触发)
-- tipsx            鼠标悬停提醒文本X偏移
-- tipsy            鼠标悬停提醒文本Y偏移
-- tipWidth         鼠标悬停提醒文本宽度设置


-- **************************
-- 显示文本
-- <Text>
-- <Text|text=测试文本|color=xx|size=12|scrollWidth=50|link=@脚本命令>
-- text          文本
-- color         文本颜色 支持闪烁，格式为{255,254,253}，闪烁间隔1s
-- size          文本大小
-- scrollWidth   滚动区域宽度
-- scrollWay     滚动方式 -- 0 从右到左 1 从下到上
-- scrollTime    滚动时间
-- scrollHeight  滚动区域高度
-- clickInterval 点击间隔 单位:毫秒
-- auto          自动执行秒数  （配合platform参数使用
-- platform      平台 1 PC端 2 手机端
-- simplenum     简化数值
-- **************************


-- **************************
-- 图片
-- <Img>
-- <Img|img=xxx.png|bg=1|move=1|reset=1|show=0|layerid=0|width=xx|height=xx|scale9l=xx|scale9r=xx|scale9t=xx|scale9b=xx|link=@脚本命令>
-- img           图片路径
-- bg            是背景图
-- esc           ESC关闭
-- move          可移动
-- reset         重置界面坐标
-- show          显示位置 0左上 1右上 2左下 3右下 4中间
-- layerid       界面ID
-- scale9l       九宫拉伸 距左侧距离
-- scale9r       九宫拉伸 距右侧距离
-- scale9t       九宫拉伸 距上方距离
-- scale9b       九宫拉伸 距下方距离
-- loadDelay     延迟加载
-- loadCount     延迟加载时第一次需要加载的层数
-- loadStep      延迟加载每次加载的层数
-- grey          灰化显示
-- bagPos        背包位置 1左边 0右边
-- flip          翻转显示
-- **************************


-- **************************
-- 按钮
-- <Button>
-- <Button|nimg=xx|pimg=xx|mimg=xx|tips=xx|text=按钮文本|color=255|size=12|width=xx|height=xx|link=@脚本命令>
-- nimg          正常图片路径
-- pimg          按下图片路径
-- mimg          鼠标经过图片路径
-- text          文本
-- color         文本颜色
-- size          文本大小
-- grey          灰化显示
-- textwidth     文本最大宽度
-- clickInterval 点击间隔 单位:毫秒     
-- **************************


-- **************************
-- 复选框
-- <CheckBox>
-- <CheckBox|checkboxid=xx|nimg=xx|pimg=xx|default=xx|submit=xx|delay=xx|count=xx|link=@脚本命令>
-- checkboxid    复选框ID 用于提交数据
-- nimg          未选择时显示的图片
-- pimg          选择时显示的图片
-- default       默认选择状态 1显示 0不显示
-- submit        点击是否提交
-- delay         自动提交时间
-- count         自动提交次数
-- **************************


-- **************************
-- 特效
-- <Effect>
-- <Effect|effectid=xxxx|effecttype=xx|scale=xx>
-- effectid      特效id
-- effecttype    特效类型 0.普通特效 1.npc模型 2.怪物模型 3.技能特效
-- act           特效动作 0.待机 1.走 2.攻击...
-- dir           特效方向 0.上 1.右上 2.右 ...
-- speed         特效速度 1.正常速度
-- scale         缩放比例 1.正常缩放 
-- count         播放次数
-- **************************


-- **************************
-- 输入框
-- <Input>
-- <Input|inputid=xx|type=xx|width=xx|height=xx|color=xx|size=xx|mincount=xx|maxcount=xx|errortips=xx>
-- inputid       输入框ID 用于提交数据
-- type          输入类型 0任意文本 1数字  2密码
-- text          默认内容
-- place         空着时提醒文本
-- placecolor    空着时提醒文本颜色
-- width         输入框宽度
-- height        输入框高度
-- color         输入文本颜色
-- size          输入文本大小
-- mincount      最小输入字符数
-- maxcount      最大输入字符数
-- errortips     输入类型不符提醒
-- onlyCh        输入仅能中文 1仅中文
-- **************************


-- **************************
-- 倒计时
-- <COUNTDOWN>
-- <COUNTDOWN|time=xx|count=xx|size=xx|color=xx|link=@脚本命令>
-- time          倒计时时间
-- link          脚本命令
-- count         循环次数
-- size          文本大小
-- color         文本颜色
-- showWay       显示方式 1 [小于1天 xx:xx:xx 大于1天 xx天xx时xx分]  0 [xx秒]
-- outline       描边大小
-- outlinecolor  描边颜色
-- **************************


-- **************************
-- 道具图标
-- <ItemShow>
-- <ItemShow|itemid=xx|itemcount|showtips=xx|link=@脚本命令>
-- itemid        物品id
-- itemcount     物品数量
-- showtips      是否显示tips
-- link          脚本命令
-- grey          灰化显示
-- lock          1/0 显示锁图标
-- color         数量文本颜色
-- dblink        双击触发
-- **************************


-- **************************
-- 容器
-- <Layout>
-- <Layout|width=xx|height=xx|color=xx|link=@脚本命令>
-- width         容器宽度
-- height        容器高度
-- color         容器颜色
-- **************************


-- **************************
-- 富文本
-- <RText>
-- <RText|text='<我是富文本/FCOLOR=254>'|text=>
-- text          内容
-- scrollWidth   滚动区域宽度
-- scrollWay     滚动方式 -- 0 从右到左 1 从下到上
-- scrollTime    滚动时间
-- scrollHeight  滚动区域高度
-- **************************


-- **************************
-- 序列帧
-- <Frames>
-- <Frames|prefix=xx|suffix=xx|count=xx|speed=xx|loop=xx>
-- prefix        前缀
-- suffix        后缀
-- count         图片数量
-- speed         播放速度 毫秒
-- loop          是否循环 -1.循环 1.播放1次 2.播放2次
-- finishframe   结束帧 (图标下标)
-- finishhide    结束是否隐藏 0默认 1隐藏
-- **************************


-- **************************
-- 物品放入框
-- <ITEMBOX>
-- <ITEMBOX|boxindex=xx|img=xx|stdmode=xx>
-- 物品放入框
-- boxindex      编号
-- img           背景图片
-- stdmode       允许放入的物品类型。DB库的StdMode值，如果有多个使用“,”隔开，如果为“*”时，允许所有物品
-- **************************


-- **************************
-- 列表容器
-- <ListView>
-- <ListView|children={1,2}|direction=xx|bounce=xx|margin=xx|default=xx>
-- 物品放入框
-- direction     方向 1竖向 2横向
-- bounce        是否弹性 1是 0否
-- margin        子控件间隔
-- default       默认跳转的索引条目
-- reload        是否强制重新加载
-- cantouch      是否可交互 1默认 0不可
-- **************************


-- **************************
-- 装备图标
-- <EquipShow>
-- <EquipShow|index=xx|showtips=xx|link=@脚本命令>
-- index         位置
-- showtips      是否显示tips
-- link          脚本命令
-- grey          灰化显示
-- showstar      显示星级 1.显示 0.不显示
-- bgtype        是否显示背景图 
-- scale         缩放比例 
-- **************************

-- **************************
-- 背包道具
-- <BAGITEMS>
-- <BAGITEMS|condition=xx#xx,xx#xx,|select=1,2,3|count=xx|row=1|link=@脚本命令>
-- condition        StdMode#Shape&StdMode#Shape
-- exclude          被排除显示的, 唯一ID,唯一ID
-- select           已经选择的道具唯一ID
-- count            格子数量
-- row              行数
-- link             脚本命令
-- selecttype       选择类型 0.多选 1.单选
-- showstar         显示星级 1.显示 0.不显示
-- iwidth           元素宽
-- iheight          元素高
-- iimg             元素背景图
-- **************************


-- **************************
-- 穿戴装备
-- <EQUIPITEMS>
-- <EQUIPITEMS|positions=*|select=1,2,3|count=xx|row=1|link=@脚本命令>
-- positions        装备位
-- select           已经选择的道具唯一ID
-- count            格子数量
-- row              行数
-- link             脚本命令
-- selecttype       选择类型 0.多选 1.单选
-- showstar         显示星级 1.显示 0.不显示
-- iwidth           元素宽
-- iheight          元素高
-- iimg             元素背景图
-- **************************


-- **************************
-- 数据库装备图标
-- <DBItemShow>
-- <DBItemShow|makeindex>
-- makeindex     唯一ID
-- showtips      是否显示tips
-- link          脚本命令
-- grey          灰化显示
-- showstar      显示星级 1.显示 0.不显示
-- **************************


-- **************************
-- 倒计时
-- <TIMETIPS>
-- <TIMETIPS|time>
-- time         剩余时间
-- size         大小
-- color        颜色
-- **************************


-- **************************
-- 数据库装备图标
-- <TextAtlas>
-- <TextAtlas|img=xx|iwidth=xx|iheight=xx|schar=xx|text=xx>
-- img          资源路径
-- iwidth       宽
-- iheight      高
-- schar        startCharMap
-- **************************

-- **************************
-- 基本等同BAGITEM 
-- <DLINKITEMS>
-- link         双击触发
-- **************************

-- **************************
-- 基于DBItemShow和HERODBItemShow
-- <MKItemShow>
-- link         双击触发和拖动到背包触发
-- canmove      可拖动参数
-- **************************

-- **************************
-- 滑动条/拉杆
-- <Slider>
-- sliderid     滑动条ID 用于提交数据
-- link         拖动触发
-- ballimg      拖动球资源
-- barimg       拖动条资源
-- bgimg        拖动背景资源
-- defvalue     默认展示值
-- maxvalue     拖动最大值（非进度百分比）
-- **************************

-- **************************
-- 下拉菜单
-- <MenuItem>
-- menuid       下拉菜单ID 用于提交数据
-- link         拖动触发
-- img          展示底资源
-- arrowimg     箭头图资源
-- listimg      菜单列表底图资源
-- itemname     菜单列表文本 #分隔 
-- select       默认选择文本
-- selectimg    选中图片资源
-- direction    方向 默认0下拉 1上拉
-- itemhei      单条菜单列表项高
-- fontsize     字体大小
-- fontcolor    字体色值
-- selectcolor  选中的字体色值
-- **************************

-- **************************
-- 刮图
-- <ScrapePic>
-- showimg      展示图片资源
-- maskimg      遮罩图片资源 默认 "public/mask_1.png"
-- clearhei     刮除高度
-- movetime     移动时间
-- begintime    开始点击到结束触发间隔
-- link         结束触发
-- **************************


return LexicalHelper
