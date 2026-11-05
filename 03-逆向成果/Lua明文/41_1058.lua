local RichTextHelp = class('RichTextHelp')

function RichTextHelp:CreateRichTextWithXML(str, width, defaultSize, defaultColor, callback)
    -- defaultColor = "#FFFFFF" 颜色采用这种格式
    -- callback 将 a href = "" href中的参数传回
    if str == nil then
        return self:CreateRichTextWithXML("空富文本")
    end

    width = width or 100
    defaultSize = defaultSize or 100
    defaultColor = defaultColor or "#FFFFFF"

    local richText = ccui.RichText:createWithXML(str, { KEY_FONT_SIZE = defaultSize, KEY_FONT_FACE = "fonts/font.ttf", KEY_FONT_COLOR_STRING = defaultColor, KEY_ANCHOR_FONT_COLOR_STRING = "#FFFFFF", KEY_ANCHOR_TEXT_LINE = "VALUE_TEXT_LINE_UNDER", KEY_ANCHOR_TEXT_OUTLINE_SIZE = 1 })
    if not richText then
        print("富文本错误：", str)
        return self:CreateRichTextWithXML("富文本错误")
    end
    richText:ignoreContentAdaptWithSize(false)
    richText:setContentSize(width, 0)
    richText:setTouchEnabled(false)

    return richText
end

return RichTextHelp
