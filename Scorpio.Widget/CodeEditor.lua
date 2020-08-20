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

    export {
        tblconcat               = table.concat,
        strbyte                 = string.byte,
        strchar                 = string.char,

        BYTE_WORD_KIND          = 0,
        BYTE_PUNC_KIND          = 1,
        BYTE_SPACE_KIND         = 2,

        DOUBLE_CLICK_INTERVAL   = 0.6,
    }

    _Byte                       = setmetatable({
        -- LineBreak
        LINEBREAK_N             = strbyte("\n"),
        LINEBREAK_R             = strbyte("\r"),

        -- Space
        SPACE                   = strbyte(" "),
        TAB                     = strbyte("\t"),

        -- UnderLine
        UNDERLINE               = strbyte("_"),

        -- Number
        ZERO                    = strbyte("0"),
        NINE                    = strbyte("9"),

        -- String
        SINGLE_QUOTE            = strbyte("'"),
        DOUBLE_QUOTE            = strbyte('"'),

        -- Operator
        PLUS                    = strbyte("+"),
        MINUS                   = strbyte("-"),
        ASTERISK                = strbyte("*"),
        SLASH                   = strbyte("/"),
        PERCENT                 = strbyte("%"),

        -- Compare
        LESSTHAN                = strbyte("<"),
        GREATERTHAN             = strbyte(">"),
        EQUALS                  = strbyte("="),

        -- Parentheses
        LEFTBRACKET             = strbyte("["),
        RIGHTBRACKET            = strbyte("]"),
        LEFTPAREN               = strbyte("("),
        RIGHTPAREN              = strbyte(")"),
        LEFTWING                = strbyte("{"),
        RIGHTWING               = strbyte("}"),

        -- Punctuation
        PERIOD                  = strbyte("."),
        BACKSLASH               = strbyte("\\"),
        COMMA                   = strbyte(","),
        SEMICOLON               = strbyte(";"),
        COLON                   = strbyte(":"),
        TILDE                   = strbyte("~"),
        HASH                    = strbyte("#"),

        -- WOW
        VERTICAL                = strbyte("|"),
        r                       = strbyte("r"),
        c                       = strbyte("c"),
    }, {
        __index = function(self, key)
            if type(key) == "string" and key:len() == 1 then
                local val       = strbyte(key)
                rawset(self, key, val)
                return val
            end
        end,
    })

    _Puncs                      = Dictionary(XList(128):Map(string.char):Filter("x=>x:match('[%p]+')"):Filter("x=>x~='_'"):Map(string.byte), true)
    _Spaces                     = Dictionary(XList(128):Map(string.char):Filter("x=>x:match('[%s]+')"):Map(string.byte), true)
    _Temp                       = {}

    -- Auto Pairs
    _AutoPairs                  = {
        [_Byte.LEFTBRACKET]     = _Byte.RIGHTBRACKET, -- []
        [_Byte.LEFTPAREN]       = _Byte.RIGHTPAREN, -- ()
        [_Byte.LEFTWING]        = _Byte.RIGHTWING, --{}
        [_Byte.SINGLE_QUOTE]    = true, -- ''
        [_Byte.DOUBLE_QUOTE]    = true, -- ""
        [_Byte.RIGHTBRACKET]    = false,
        [_Byte.RIGHTPAREN]      = false,
        [_Byte.RIGHTWING]       = false,
    }

    ------------------------------------------------------
    -- Test FontString
    ------------------------------------------------------
    _TestFontString             = UIParent:CreateFontString()
    _TestFontString:Hide()
    _TestFontString:SetWordWrap(true)

    ------------------------------------------------------
    -- Helpers
    ------------------------------------------------------
    local function skipColor(str, pos)
        while true do
            local byte          = strbyte(str, pos)

            if byte == _Byte.VERTICAL then
                local nbyte     = strbyte(str, pos + 1)
                if nbyte == _Byte.c then
                    -- Color start
                    pos         =  pos + 10
                elseif nbyte == _Byte.r then
                    -- Color end
                    pos         = pos + 2
                else
                    -- must be ||
                    return pos
                end
            else
                return pos
            end
        end
    end

    local function skipPrevColor(str, pos)
        while pos > 0 do
            local byte              = strbyte(str, pos)
            if byte == _Byte.r then
                local pbyte         = strbyte(str, pos - 1)
                if pbyte == _Byte.VERTICAL then
                    if strbyte(pos - 2) ~= _Byte.VERTICAL then
                        pos         = pos - 2
                    else
                        return pos
                    end
                else
                    return pos
                end
            else
                -- Check the previous
                if strbyte(pos - 8) == _Byte.c and strbyte(pos - 9) == _Byte.VERTICAL and strbyte(pos - 10) ~= _Byte.VERTICAL then
                    pos             = pos - 10
                else
                    return pos
                end
            end
        end
    end

    local function removeColor(str)
        local start             = 1
        local pos               = 1
        local npos
        local count             = 0

        wipe(_Temp)

        while pos <= #str do
            npos                = skipColor(str, pos)

            if npos ~= pos then
                count           = count + 1
                _Temp[count]    = str:sub(start, pos - 1)
                start           = npos
            end

            pos                 = npos + 1
        end

        count                   = count + 1
        _Temp[count]            = str:sub(start, -1)

        local result            = tblconcat(_Temp)
        wipe(_Temp)

        return result
    end

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

        _TestFontString:SetFont(font, height, flag)
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

    local function replaceBlock(str, startp, endp, replace)
        return str:sub(1, startp - 1) .. replace .. str:sub(endp + 1, -1)
    end

    local function getLines(str, startp, endp)
        endp                    = (endp and (endp + 1)) or startp + 1

        -- get prev LineBreak
        while startp > 0 do
            local byte          = strbyte(str, startp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            startp              = startp - 1
        end

        startp                  = startp + 1

        -- get next LineBreak
        while true do
            local byte          = strbyte(str, endp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            endp                = endp + 1
        end

        endp                    = endp - 1

        -- get block
        return startp, endp, str:sub(startp, endp)
    end

    local function getByteType(byte)
        return _Puncs[byte] and BYTE_PUNC_KIND or _Spaces[byte] and BYTE_SPACE_KIND or byte and BYTE_WORD_KIND
    end

    local function getWord(str, pos, notail)
        local startp, endp      = getLines(str, pos)
        if startp > endp then return end

        local pretype, tailtype

        -- Check the match type
        if not notail then
            tailtype            = getByteType(strbyte(str, skipColor(str, pos + 1))) or -1
        end

        if tailtype == 0 then
            pretype             = 0
        else
            pretype             = getByteType(strbyte(str, skipPrevColor(str, pos))) or -1
        end

        -- Match the word
        local prev, tail        = pos + 1, pos

        repeat
            prev                = skipPrevColor(str, prev - 1)
        until not prev or prev < startp or getByteType(strbyte(str, prev)) ~= pretype
        prev                    = prev and (prev + 1) or 0

        if not notail then
            repeat
                tail            = skipColor(str, tail + 1)
            until not tail or tail > endp or getByteType(strbyte(str, tail)) ~= tailtype
            tail                = tail - 1
        end

        return prev, tail
    end

    local function inString(str, pos)
        local startp, endp      = getLines(str, pos)
        if startp > endp then return false end

        local byte              = strbyte(str, startp)
        local isString          = 0
        local preEscape         = false

        while byte and startp <= pos do
            if not preEscape then
                if byte == _Byte.SINGLE_QUOTE then
                    if isString == 0 then
                        isString = 1
                    elseif isString == 1 then
                        isString = 0
                    end
                elseif byte == _Byte.DOUBLE_QUOTE then
                    if isString == 0 then
                        isString = 2
                    elseif isString == 2 then
                        isString = 0
                    end
                end
            end

            if byte == _Byte.BACKSLASH then
                preEscape       = not preEscape
            else
                preEscape       = false
            end

            startp              = startp + 1
            byte                = strbyte(str, startp)
        end

        return isString == 1 and _Byte.SINGLE_QUOTE or isString == 2 and _Byte.DOUBLE_QUOTE
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- Refresh the editor layout
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

    --- Highlight the text
    function HighlightText(self, startp, endp)
        local editor            = self.__Editor

        local text
        startp                  = startp or 0
        if not endp then
            text                = editor:GetText()
            endp                = #text
        end

        if endp < startp then startp, endp = endp, startp end

        self._HighlightStart    = startp
        self._HighlightEnd      = endp

        if startp ~= endp then
            text                = text or editor:GetText()
            editor._HighlightText = removeColor(text:sub(startp + 1, endp))
        else
            editor._HighlightText = ""
        end

        return editor:HighlightText(startp, endp)
    end

    --- Set the cursor position
    function SetCursorPosition(self, pos)
        local editor            = self.__Editor
        editor:SetCursorPosition(pos)
        return self:HighlightText(pos, pos)
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

    local function onChar(self, char)
        if self._InPasting or not self:HasFocus() then return true end

        -- Auto Pairs
        local auto              =  char and _AutoPairs[strbyte(char)]

        if auto == true then
        elseif auto then
            local cursor        = self:GetCursorPosition()
            local inner         = self._HighlightText or ""

            if inner ~= "" then
                self:Insert(inner .. strchar(auto))

                local stop      = cursor + #inner
                SetCursorPosition(self.__Owner, stop)
                HighlightText(self.__Owner, cursor, stop)
            else
                local text      = self:GetText()

                if not inString(text, cursor) then
                    local next  = skipColor(text, cursor + 1)
                    if strbyte(text, next) ~= strbyte(char) then
                        self:SetText(replaceBlock(text, cursor + 1, cursor, strchar(auto)))
                        SetCursorPosition(self.__Owner, cursor)
                    end
                end
            end
        elseif auto == false then
            local cursor        = self:GetCursorPosition()
            local text          = self:GetText()
            local next          = skipColor(text, cursor + 1)

            if strbyte(text, next) == strbyte(char) then
                self:SetText(replaceBlock(text, cursor + 1, next, ""))
            end

            SetCursorPosition(self.__Owner, cursor)
        end

        self._InCharComposition = false
    end

    local function onCharComposition(self)
        -- Avoid handle cursor change when input with IME
        self._InCharComposition = true
    end

    local function onMouseUpAsync(self, btn)
        local prev, curr        = self._MouseDownCur, self:GetCursorPosition()
        self._MouseDownCur      = false

        if self._CheckDblClk then
            -- Select the Words
            local prev          = self._MouseDownTime
            self._CheckDblClk   = false
            self._MouseDownTime = false

            if prev and (GetTime() - prev) < DOUBLE_CLICK_INTERVAL then
                local startp, endp  = getWord(self:GetText(), self:GetCursorPosition())
                if startp and endp then
                    return Next(HighlightText, self.__Owner, startp - 1, endp)
                end
            end
        end

        return HighlightText(self.__Owner, prev, curr)
    end

    local function onMouseUp(self, btn)
        return Next(onMouseUpAsync, self, btn)
    end

    local function onMouseDownAsync(self, btn)
        self._MouseDownCur      = self:GetCursorPosition()
    end

    local function onMouseDown(self, btn)
        Next(onMouseDownAsync, self, btn)

        -- Check Double Click to select word
        if IsShiftKeyDown() then
            self._MouseDownShf  = true
            self._MouseDownTime = false
            self._CheckDblClk   = false
        else
            self._MouseDownShf  = false

            local now           = GetTime()
            if self._MouseDownTime and (now - self._MouseDownTime) < DOUBLE_CLICK_INTERVAL then
                self._CheckDblClk   = true
            else
                self._CheckDblClk   = false
                self._MouseDownTime = now
            end
        end
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

        editor.OnSizeChanged    = editor.OnSizeChanged      + onSizeChanged
        editor.OnShow           = editor.OnShow             + onShow
        editor.OnChar           = editor.OnChar             + onChar
        editor.OnCharComposition= editor.OnCharComposition  + onCharComposition
        editor.OnMouseDown      = editor.OnMouseDown        + onMouseDown
        editor.OnMouseUp        = editor.OnMouseUp          + onMouseUp

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