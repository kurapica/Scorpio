--========================================================--
--             Scorpio CodeEditor                         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/05/16                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.CodeEditor"        "1.0.0"
--========================================================--

-----------------------------------------------------------
--                  Text Editor Widget                   --
-----------------------------------------------------------
__Sealed__() class "CodeEditor" (function(_ENV)
    inherit "InputScrollFrame"

    local tblconcat             = table.concat

    ------------------------------------------------------
    -- Test FontString
    ------------------------------------------------------
    _TestFontString             = UIParent:CreateFontString()
    _TestFontString:Hide()
    _TestFontString:SetWordWrap(true)

    local function updateLineNum(self)
        local editor            = self.__Editor
        local linenum           = self.__LineNum

        if not linenum:IsShown() then return end

        local font, height, flag= editor:GetFont()
        local spacing           = editor:GetSpacing()
        local left, right       = editor:GetTextInsets()
        local lineWidth         = editor:GetWidth() - left - right
        local lineHeight        = height + spacing

        local endPos

        local text              = editor:GetText()
        local index             = 0
        local count             = 0
        local extra             = 0

        local lines             = linenum.Lines or {}
        linenum.Lines           = lines

        linenum:SetHeight(editor:GetHeight())

        _TestFontString:SetFontObject(editor:GetFontObject())
        _TestFontString:SetSpacing(spacing)
        _TestFontString:SetIndentedWordWrap(editor:GetIndentedWordWrap())
        _TestFontString:SetWidth(lineWidth)

        for line, endp in text:gmatch( "([^\r\n]*)()" ) do
            if endp ~= endPos then
                -- skip empty match
                endPos          = endp

                index           = index + 1
                count           = count + 1

                lines[count]    = index

                _TestFontString:SetText(line)

                extra           = _TestFontString:GetStringHeight() / lineHeight

                extra           = floor(extra) - 1

                for i = 1, extra do
                    count       = count + 1
                    lines[count]= ""
                end
            end
        end

        for i = #lines, count + 1, -1 do
            lines[i]            = nil
        end

        linenum:SetText(tblconcat(lines, "\n"))
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    __AsyncSingle__()
    function RefreshLayout(self)
        Next()

        local editor            = self.__Editor
        local linenum           = self.__LineNum

        local font, height, flag= editor:GetFont()
        local spacing           = editor:GetSpacing()

        linenum:SetFont(font, height, flag)
        linenum:SetSpacing(spacing)

        _TestFontString:SetFont(font, height, flag)
        _TestFontString:SetText("XXXX")

        linenum:SetWidth(_TestFontString:GetStringWidth() + 8)
        linenum:SetText("")

        local l, r, t, b        = editor:GetTextInsets()
        l                       = (linenum:IsShown() and linenum:GetWidth() or 0) + 5
        Style[editor].textInsets= Inset(l, r, t, b)

        linenum:ClearAllPoints()
        linenum:SetPoint("LEFT")
        linenum:SetPoint("TOP", editor, "TOP", 0, - t - spacing)

        Style[self].ScrollBar.valueStep = height + spacing

        return updateLineNum(self)
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The tab width, default 4
    property "TabWidth"     { type = NaturalNumber, default = 4 }

    --- Whether show the line num
    property "ShowLineNum"  { type = Bool, default = true, handler = function(self, flag) Style[self].ScrollChild.LineNum.visible = flag; self:RefreshLayout() end }

    ------------------------------------------------------
    -- UI Property
    ------------------------------------------------------
    --- the font settings
    UI.Property         {
        name            = "Font",
        type            = FontType,
        require         = InputScrollFrame,
        get             = function(self) return Style[self].ScrollChild.EditBox.font end,
        set             = function(self, font) Style[self].ScrollChild.EditBox.font = font; self:RefreshLayout() end,
        override        = { "FontObject" },
    }

    --- the Font object
    UI.Property         {
        name            = "FontObject",
        type            = FontObject,
        require         = InputScrollFrame,
        get             = function(self) return Style[self].ScrollChild.EditBox.fontObject end,
        set             = function(self, font) Style[self].ScrollChild.EditBox.fontObject = font; self:RefreshLayout() end,
        override        = { "Font" },
    }

    --- whether the text wrap will be indented
    UI.Property         {
        name            = "Indented",
        type            = Boolean,
        require         = InputScrollFrame,
        default         = false,
        get             = function(self) return Style[self].ScrollChild.EditBox.indented end,
        set             = function(self, val) Style[self].ScrollChild.EditBox.indented = val; self:RefreshLayout() end,
    }

    --- the fontstring's amount of spacing between lines
    UI.Property         {
        name            = "Spacing",
        type            = Number,
        require         = InputScrollFrame,
        default         = 0,
        get             = function(self) return Style[self].ScrollChild.EditBox.spacing end,
        set             = function(self, val) Style[self].ScrollChild.EditBox.spacing = val; self:RefreshLayout() end,
    }

    --- the insets from the edit box's edges which determine its interactive text area
    UI.Property         {
        name            = "TextInsets",
        type            = Inset,
        require         = InputScrollFrame,
        get             = function(self) return Style[self].ScrollChild.EditBox.textInsets end,
        set             = function(self, val) Style[self].ScrollChild.EditBox.textInsets = val; self:RefreshLayout() end,
    }

    ------------------------------------------------------
    -- Event Handler
    ------------------------------------------------------
    local function onSizeChanged(self)
        return updateLineNum(self.__Owner)
    end

    local function onShow(self)
        return self:RefreshLayout()
    end

    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    __Template__{
        LineHolder              = Frame,

        {
            ScrollChild         = {
                LineNum         = FontString,
            }
        }
    }
    function __ctor(self)
        local editor            = self:GetScrollChild():GetChild("EditBox")
        local linenum           = self:GetScrollChild():GetChild("LineNum")

        linenum:SetJustifyV("TOP")
        linenum:SetJustifyH("CENTER")

        editor.OnSizeChanged    = editor.OnSizeChanged  + onSizeChanged
        editor.OnShow           = editor.OnShow         + onShow

        editor.__Owner          = self

        self.__Editor           = editor
        self.__LineNum          = linenum
    end
end)


-----------------------------------------------------------
--              CodeEditor Style - Default               --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [CodeEditor]                = {
        maxLetters              = 0,
        countInvisibleLetters   = false,
        textInsets              = Inset(5, 5, 3, 3),

        LineHolder              = {
            location            = {
                Anchor("TOPLEFT", 5, -5),
                Anchor("BOTTOMLEFT", 5, 5),
                Anchor("RIGHT", 0, 0, "ScrollChild.LineNum"),
            },
            width               = 5,
            enableMouse         = true,
            frameStrata         = "FULLSCREEN",

            MiddleBGTexture     = {
                color           = Color(0.12, 0.12, 0.12, 0.8),
                setAllPoints    = true,
                alphaMode       = "ADD",
            }
        },
    }
})