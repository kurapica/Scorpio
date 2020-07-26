--========================================================--
--             Scorpio Editor Templats                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/05/16                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.Editor"            "1.0.0"
--========================================================--

-----------------------------------------------------------
--                  Text Editor Widget                   --
-----------------------------------------------------------
__Sealed__() class "CodeEditor" (function(_ENV)
    inherit "InputScrollFrame"

    local getCursorLocation     = _G.GetCursorPosition
    local strbyte               = string.byte
    local strchar               = string.char
    local floor                 = math.floor
    local ceil                  = math.ceil
    local tblconcat             = table.concat
    local tinsert               = table.insert
    local tremove               = table.remove

    local _ConcatReturn         = nil
    local _TempRemoveColor      = {}

    _DBL_CLK_CHK                = 0.3
    _FIRST_WAITTIME             = 0.3
    _CONTINUE_WAITTIME          = 0.03
    _STR_CHAR_MAX               = 32

    _UTF8_Three_Char            = 224
    _UTF8_Two_Char              = 192

    _TabWidth                   = 4

    -- Bytes
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
        E                       = strbyte("E"),
        e                       = strbyte("e"),
        x                       = strbyte("x"),
        a                       = strbyte("a"),
        f                       = strbyte("f"),

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
        __index                 = function(self, key)
            if type(key) == "string" and key:len() == 1 then
                rawset(self, key, strbyte(key))
            end

            return rawget(self, key)
        end,
    })

    -- Special
    _Special                    = {
        -- LineBreak
        [_Byte.LINEBREAK_N]     = 1,
        [_Byte.LINEBREAK_R]     = 1,

        -- Space
        [_Byte.SPACE]           = 1,
        [_Byte.TAB]             = 1,

        -- String
        [_Byte.SINGLE_QUOTE]    = 1,
        [_Byte.DOUBLE_QUOTE]    = 1,

        -- Operator
        [_Byte.MINUS]           = 1,
        [_Byte.PLUS]            = 1,
        [_Byte.SLASH]           = 1,
        [_Byte.SLASH]           = 1,
        [_Byte.ASTERISK]        = 1,
        [_Byte.PERCENT]         = 1,

        -- Compare
        [_Byte.LESSTHAN]        = 1,
        [_Byte.GREATERTHAN]     = 1,
        [_Byte.EQUALS]          = 1,

        -- Parentheses
        [_Byte.LEFTBRACKET]     = 1,
        [_Byte.RIGHTBRACKET]    = 1,
        [_Byte.LEFTPAREN]       = 1,
        [_Byte.RIGHTPAREN]      = 1,
        [_Byte.LEFTWING]        = 1,
        [_Byte.RIGHTWING]       = 1,

        -- Punctuation
        [_Byte.PERIOD]          = 1,
        [_Byte.COMMA]           = 1,
        [_Byte.SEMICOLON]       = 1,
        [_Byte.COLON]           = 1,
        [_Byte.TILDE]           = 1,
        [_Byte.HASH]            = 1,

        -- WOW
        [_Byte.VERTICAL]        = 1,
    }

    -- Operation
    _Operation                  = {
        CHANGE_CURSOR           = 1,
        INPUTCHAR               = 2,
        INPUTTAB                = 3,
        DELETE                  = 4,
        BACKSPACE               = 5,
        ENTER                   = 6,
        PASTE                   = 7,
        CUT                     = 8,
    }

    _KEY_OPER                   = {
        PAGEUP                  = _Operation.CHANGE_CURSOR,
        PAGEDOWN                = _Operation.CHANGE_CURSOR,
        HOME                    = _Operation.CHANGE_CURSOR,
        END                     = _Operation.CHANGE_CURSOR,
        UP                      = _Operation.CHANGE_CURSOR,
        DOWN                    = _Operation.CHANGE_CURSOR,
        RIGHT                   = _Operation.CHANGE_CURSOR,
        LEFT                    = _Operation.CHANGE_CURSOR,
        TAB                     = _Operation.INPUTTAB,
        DELETE                  = _Operation.DELETE,
        BACKSPACE               = _Operation.BACKSPACE,
        ENTER                   = _Operation.ENTER,
    }

    -- SkipKey
    _SkipKey                    = {
        -- Control keys
        LALT                    = true,
        LCTRL                   = true,
        LSHIFT                  = true,
        RALT                    = true,
        RCTRL                   = true,
        RSHIFT                  = true,
        -- other nouse keys
        ESCAPE                  = true,
        CAPSLOCK                = true,
        PRINTSCREEN             = true,
        INSERT                  = true,
        UNKNOWN                 = true,
    }

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

    -- Temp list
    _BackSpaceList              = {}

    ------------------------------------------------------
    -- Test FontString
    ------------------------------------------------------
    _TestFontString             = UIParent:CreateFontString()
    _TestFontString:Hide()
    _TestFontString:SetWordWrap(true)

    ------------------------------------------------------
    -- Key Scanner
    ------------------------------------------------------
    _KeyScan                    = CreateFrame("Frame")
    _KeyScan:Hide()
    _KeyScan:EnableKeyboard(true)
    _KeyScan:SetFrameStrata("TOOLTIP")
    _KeyScan:SetPropagateKeyboardInput(true)
    _KeyScan.ActiveKeys         = {}

    ------------------------------------------------------
    -- Short Key Block
    ------------------------------------------------------
    _BtnBlockUp                 = CreateFrame("Button", "Scorpio_TextEditor_UpBlock", UIParent, "SecureActionButtonTemplate")
    _BtnBlockDown               = CreateFrame("Button", "Scorpio_TextEditor_DownBlock", UIParent, "SecureActionButtonTemplate")
    _BtnBlockUp:Hide()
    _BtnBlockDown:Hide()

    ------------------------------------------------------
    -- Helper
    ------------------------------------------------------
    local function removeColor(str)
        local byte
        local pos               = 1

        wipe(_TempRemoveColor)

        if not str or #str == 0 then return "" end

        byte                    = strbyte(str, pos)

        while true do
            if byte == _Byte.VERTICAL then
                -- handle the color code
                pos             = pos + 1
                byte            = strbyte(str, pos)

                if byte == _Byte.c then
                    pos         = pos + 9
                elseif byte == _Byte.r then
                    pos         = pos + 1
                else
                    tinsert(_TempRemoveColor, _Byte.VERTICAL)
                end

                byte            = strbyte(str, pos)
            else
                if not byte then break end

                tinsert(_TempRemoveColor, byte)

                pos             = pos + 1
                byte            = strbyte(str, pos)
            end
        end

        local bytlen            = #_TempRemoveColor

        if bytlen == #str then
            wipe(_TempRemoveColor)
            return str
        end

        for i = 1, ceil(bytlen / _STR_CHAR_MAX) do
            _TempRemoveColor[i] = strchar(unpack(_TempRemoveColor, (i-1) * _STR_CHAR_MAX + 1, min(bytlen, i * _STR_CHAR_MAX))
        end

        str                     = tblconcat(_TempRemoveColor, "", 1, ceil(bytlen / _STR_CHAR_MAX))
        wipe(_TempRemoveColor)

        return str
    end

    local function replaceBlock(str, startp, endp, replace)
        return str:sub(1, startp - 1) .. replace .. str:sub(endp + 1, -1)
    end

    local function updateLineNum(self)
        local editor            = self.__Editor
        local lineNum           = self.__LineNum
        local inset             = editor:GetTextInsets()
        local lineWidth         = editor:GetWidth() - inset.left - inset.right
        local lineHeight        = editor:GetFont().height + editor:GetSpacing()

        local endPos

        local text              = editor:GetText()
        local index             = 0
        local count             = 0
        local extra             = 0


        local lines             = lineNum.Lines or {}
        lineNum.Lines           = lines

        lineNum:SetHeight(editor:GetHeight())

        _TestFontString:SetFontObject(editor:GetFontObject())
        _TestFontString:SetSpacing(editor:GetSpacing())
        _TestFontString:SetIndentedWordWrap(editor:GetIndentedWordWrap())
        _TestFontString:SetWidth(lineWidth)

        if not _ConcatReturn then
            if text:find("\n") then
                _ConcatReturn = "\n"
            elseif text:find("\r") then
                _ConcatReturn = "\r"
            end
        end

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

        if _ConcatReturn then
            lineNum:SetText(tblconcat(lines, _ConcatReturn))
        else
            lineNum:SetText(tostring(lines[1] or ""))
        end
    end

    function Ajust4Font(self)
        local editor            = self.__Editor
        local lineNum           = self.__LineNum
        lineNum:SetFont(editor:GetFont())
        lineNum:SetSpacing(editor:GetSpacing())

        _TestFontString:SetFont(editor:GetFont())
        _TestFontString.Text = "XXXX"

        lineNum.Width = _TestFontString:GetStringWidth() + 8
        lineNum.Text = ""

        local inset = editor.TextInsets

        if lineNum.Visible then
            inset.left = lineNum.Width + 5

            editor.TextInsets = inset

            lineNum:SetPoint("TOP", editor, "TOP", 0, - (inset.top))
        else
            inset.left = 5

            editor.TextInsets = inset

            lineNum:SetPoint("TOP", editor, "TOP", 0, - (inset.top))
        end

        self.ValueStep = editor.Font.height + editor.Spacing

        UpdateLineNum(self)
    end

    function GetLines4Line(self, line)
        if not _ConcatReturn then
            return 0, self.__Editor.Text:len()
        end

        local startp, endp = 0, 0
        local str = self.__Editor.Text
        local count = 0

        while count < line and endp do
            startp = endp
            endp = endp + 1

            endp = str:find(_ConcatReturn, endp)
            count = count + 1
        end

        if not endp then
            endp = str:len()
        end

        return startp, endp
    end

    function GetLines(str, startp, endp)
        local byte

        endp = (endp and (endp + 1)) or startp + 1

        -- get prev LineBreak
        while startp > 0 do
            byte = strbyte(str, startp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            startp = startp - 1
        end

        startp = startp + 1

        -- get next LineBreak
        while true do
            byte = strbyte(str, endp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            endp = endp + 1
        end

        endp = endp - 1

        -- get block
        return startp, endp, str:sub(startp, endp)
    end

    function GetLinesByReturn(str, startp, returnCnt)
        local byte
        local handledReturn = 0
        local endp = startp + 1

        returnCnt = returnCnt or 0

        -- get prev LineBreak
        while startp > 0 do
            byte = strbyte(str, startp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            startp = startp - 1
        end

        startp = startp + 1

        -- get next LineBreak
        while true do
            byte = strbyte(str, endp)

            if not byte then
                break
            elseif byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                returnCnt = returnCnt - 1

                if returnCnt < 0 then
                    break
                end

                handledReturn = handledReturn + 1
            end

            endp = endp + 1
        end

        endp = endp - 1

        -- get block
        return startp, endp, str:sub(startp, endp), handledReturn
    end

    function GetPrevLinesByReturn(str, startp, returnCnt)
        local byte
        local handledReturn = 0
        local endp = startp + 1

        returnCnt = returnCnt or 0

        -- get prev LineBreak
        while true do
            byte = strbyte(str, endp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            endp = endp + 1
        end

        endp = endp - 1

        local prevReturn

        -- get prev LineBreak
        while startp > 0 do
            byte = strbyte(str, startp)

            if not byte then
                break
            elseif byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                returnCnt = returnCnt - 1

                if returnCnt < 0 then
                    break
                end

                prevReturn = startp

                handledReturn = handledReturn + 1
            end

            startp = startp - 1
        end

        if not prevReturn or prevReturn >  startp + 1 then
            startp = startp + 1
        end

        -- get block
        return startp, endp, str:sub(startp, endp), handledReturn
    end

    function GetOffsetByCursorPos(str, startp, cursorPos)
        if not cursorPos or cursorPos < 0 then
            return 0
        end

        startp = startp or cursorPos

        while startp > 0 do
            byte = strbyte(str, startp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            startp = startp - 1
        end

        startp = startp + 1

        local byte = strbyte(str, startp)
        local byteCnt = 0

        while startp <= cursorPos do
            if byte == _Byte.VERTICAL then
                -- handle the color code
                startp = startp + 1
                byte = strbyte(str, startp)

                if byte == _Byte.c then
                    startp = startp + 9
                elseif byte == _Byte.r then
                    startp = startp + 1
                end

                byte = strbyte(str, startp)
            else
                if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                    break
                end

                byteCnt = byteCnt + 1
                startp = startp + 1
                byte = strbyte(str, startp)
            end
        end

        return byteCnt
    end

    function GetCursorPosByOffset(str, startp, offset)
        startp = startp or 1
        offset = offset or 0

        while startp > 0 do
            byte = strbyte(str, startp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            startp = startp - 1
        end

        local byte
        local byteCnt = 0

        while byteCnt < offset do
            startp  = startp  + 1
            byte = strbyte(str, startp)

            if byte == _Byte.VERTICAL then
                -- handle the color code
                startp = startp + 1
                byte = strbyte(str, startp)

                if byte == _Byte.c then
                    startp = startp + 8
                end
            else
                if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                    startp = startp - 1
                    break
                end

                byteCnt = byteCnt + 1
            end
        end

        return startp
    end

    function GetWord(str, cursorPos, noTail)
        local startp, endp = GetLines(str, cursorPos)

        if startp > endp then return end

        _BackSpaceList.LastIndex = 0

        local prevPos = startp
        local byte
        local curIndex = -1
        local prevSpecial = nil

        while prevPos <= endp do
            byte = strbyte(str, prevPos)

            if byte == _Byte.VERTICAL then
                prevPos = prevPos + 1
                byte = strbyte(str, prevPos)

                if byte == _Byte.c then
                    -- color start
                    _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                    _BackSpaceList[_BackSpaceList.LastIndex] = prevPos - 1

                    if cursorPos == prevPos - 2 then
                        curIndex = _BackSpaceList.LastIndex
                    end

                    prevPos = prevPos + 9
                elseif byte == _Byte.r then
                    -- color end
                    _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                    _BackSpaceList[_BackSpaceList.LastIndex] = prevPos - 1

                    if cursorPos == prevPos - 2 then
                        curIndex = _BackSpaceList.LastIndex
                    end

                    prevPos = prevPos + 1
                else
                    -- only mean "||"
                    _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                    _BackSpaceList[_BackSpaceList.LastIndex] = prevPos - 1

                    if cursorPos == prevPos - 2 then
                        curIndex = _BackSpaceList.LastIndex
                    end

                    prevPos = prevPos + 1
                end
            elseif _Special[byte] then
                _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                _BackSpaceList[_BackSpaceList.LastIndex] = prevPos

                if cursorPos == prevPos - 1 then
                    curIndex = _BackSpaceList.LastIndex
                end

                prevPos = prevPos + 1
            else
                _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                _BackSpaceList[_BackSpaceList.LastIndex] = prevPos

                if cursorPos == prevPos - 1 then
                    curIndex = _BackSpaceList.LastIndex
                end

                if byte >= _UTF8_Three_Char then
                    prevPos = prevPos + 3
                elseif byte >= _UTF8_Two_Char then
                    prevPos = prevPos + 2
                else
                    prevPos = prevPos + 1
                end
            end
        end

        if cursorPos == endp then
            curIndex = _BackSpaceList.LastIndex + 1
        end

        if curIndex > 0 then
            local prevIndex = curIndex - 1
            local isSpecial = nil
            local isColor

            while prevIndex > 0 do
                prevPos = _BackSpaceList[prevIndex]
                byte = strbyte(str, prevPos)

                isColor = false

                if byte == _Byte.VERTICAL then
                    prevPos = prevPos + 1
                    byte = strbyte(str, prevPos)

                    if byte == _Byte.c or byte == _Byte.r then
                        isColor = true
                    end
                end

                if isColor then
                    -- skip
                elseif isSpecial == nil then
                    isSpecial = _Special[byte] and true or false
                elseif isSpecial then
                    if not _Special[byte] then
                        break
                    end
                else
                    if _Special[byte] then
                        break
                    end
                end

                prevIndex = prevIndex - 1
            end

            prevIndex = prevIndex + 1

            local nextIndex = curIndex

            prevSpecial = isSpecial
            isSpecial = nil

            while nextIndex <= _BackSpaceList.LastIndex do
                prevPos = _BackSpaceList[nextIndex]
                byte = strbyte(str, prevPos)

                isColor = false

                if byte == _Byte.VERTICAL then
                    prevPos = prevPos + 1
                    byte = strbyte(str, prevPos)

                    if byte == _Byte.c or byte == _Byte.r then
                        isColor = true
                    end
                end

                if isColor then
                    -- skip
                elseif isSpecial == nil then
                    isSpecial = _Special[byte] and true or false

                    if noTail and isSpecial ~= prevSpecial then
                        break
                    end
                elseif isSpecial then
                    if not _Special[byte] then
                        break
                    end
                else
                    if _Special[byte] then
                        break
                    end
                end

                nextIndex = nextIndex + 1
            end

            nextIndex = nextIndex - 1

            startp = _BackSpaceList[prevIndex]
            if _BackSpaceList.LastIndex > nextIndex and _BackSpaceList[nextIndex + 1] then
                endp = _BackSpaceList[nextIndex + 1] - 1
            end

            return startp, endp, str:sub(startp, endp)
        end
    end

    function SaveOperation(self)
        if not self.__OperationOnLine then
            return
        end

        local nowText = self.__Editor.Text

        -- check change
        if nowText == self.__OperationBackUpOnLine then
            self.__OperationOnLine = nil
            self.__OperationBackUpOnLine = nil
            self.__OperationStartOnLine = nil
            self.__OperationEndOnLine = nil

            return
        end

        self.__OperationIndex = self.__OperationIndex + 1
        self.__MaxOperationIndex = self.__OperationIndex

        local index = self.__OperationIndex

        -- Modify some oper var
        if self.__OperationOnLine == _Operation.DELETE then
            local _, oldLineCnt, newLineCnt

            _, oldLineCnt = self.__OperationBackUpOnLine:gsub("\n", "\n")
            _, newLineCnt = nowText:gsub("\n", "\n")

            _, self.__OperationEndOnLine = GetLinesByReturn(self.__OperationBackUpOnLine, self.__OperationStartOnLine, oldLineCnt - newLineCnt)
        end

        if self.__OperationOnLine == _Operation.BACKSPACE then
            local _, oldLineCnt, newLineCnt

            _, oldLineCnt = self.__OperationBackUpOnLine:gsub("\n", "\n")
            _, newLineCnt = nowText:gsub("\n", "\n")

            self.__OperationStartOnLine = GetPrevLinesByReturn(self.__OperationBackUpOnLine, self.__OperationEndOnLine, oldLineCnt - newLineCnt)
        end

        -- keep operation data
        self.__Operation[index] = self.__OperationOnLine

        self.__OperationBackUp[index] = select(3, GetLines(self.__OperationBackUpOnLine, self.__OperationStartOnLine, self.__OperationEndOnLine))
        self.__OperationStart[index] = self.__OperationStartOnLine
        self.__OperationEnd[index] = self.__OperationEndOnLine

        self.__OperationData[index] = select(3, GetLines(nowText, self.__HighlightTextStart, self.__HighlightTextEnd))
        self.__OperationFinalStart[index] = self.__HighlightTextStart
        self.__OperationFinalEnd[index] = self.__HighlightTextEnd

        -- special operation
        if self.__OperationOnLine == _Operation.ENTER then
            local realStart = GetLines(self.__OperationBackUpOnLine, self.__OperationStartOnLine, self.__OperationEndOnLine)
            if realStart > self.__OperationStartOnLine then
                realStart = self.__OperationStartOnLine
            end
            self.__OperationData[index] = select(3, GetLines(nowText, realStart, self.__HighlightTextEnd))
            self.__OperationFinalStart[index] = realStart
            self.__OperationFinalEnd[index] = self.__HighlightTextEnd
        end

        if self.__OperationOnLine == _Operation.PASTE then
            self.__OperationData[index] = select(3, GetLines(nowText, self.__OperationStartOnLine, self.__HighlightTextEnd))
            self.__OperationFinalStart[index] = self.__OperationStartOnLine
            self.__OperationFinalEnd[index] = self.__HighlightTextEnd
        end

        if self.__OperationOnLine == _Operation.CUT then
            self.__OperationData[index] = select(3, GetLines(nowText, self.__HighlightTextStart, self.__HighlightTextStart))
            self.__OperationFinalStart[index] = self.__HighlightTextStart
            self.__OperationFinalEnd[index] = self.__HighlightTextStart
        end

        self.__OperationOnLine = nil
        self.__OperationBackUpOnLine = nil
        self.__OperationStartOnLine = nil
        self.__OperationEndOnLine = nil

        return self:Fire("OnOperationListChanged")
    end

    function NewOperation(self, oper)
        if self.__OperationOnLine == oper then
            return
        end

        -- save last operation
        SaveOperation(self)

        self.__OperationOnLine = oper

        self.__OperationBackUpOnLine = self.__Editor.Text
        self.__OperationStartOnLine = self.__HighlightTextStart
        self.__OperationEndOnLine = self.__HighlightTextEnd
    end

    function EndPrevKey(self)
        if self.__SKIPCURCHGARROW then
            self.__SKIPCURCHG = nil
            self.__SKIPCURCHGARROW = nil
        end

        self.__InPasting = nil
    end

    function BlockShortKey()
        SetOverrideBindingClick(IGAS:GetUI(_BtnBlockDown), false, "DOWN", _BtnBlockDown.Name, "LeftButton")
        SetOverrideBindingClick(IGAS:GetUI(_BtnBlockUp), false, "UP", _BtnBlockUp.Name, "LeftButton")
    end

    function UnblockShortKey()
        ClearOverrideBindings(IGAS:GetUI(_BtnBlockDown))
        ClearOverrideBindings(IGAS:GetUI(_BtnBlockUp))
    end

    _IndentFunc = _IndentFunc or {}
    _ShiftIndentFunc = _ShiftIndentFunc or {}

    do
        setmetatable(_IndentFunc, {
            __index = function(self, key)
                if tonumber(key) then
                    local tab = floor(tonumber(key))

                    if tab > 0 then
                        if not rawget(self, key) then
                            rawset(self, key, function(str)
                                return strrep(" ", tab) .. str
                            end)
                        end

                        return rawget(self, key)
                    end
                end
            end,
        })

        setmetatable(_ShiftIndentFunc, {
            __index = function(self, key)
                if tonumber(key) then
                    local tab = floor(tonumber(key))

                    if tab > 0 then
                        if not rawget(self, key) then
                            rawset(self, key, function(str)
                                local _, len = str:find("^%s+")

                                if len and len > 0 then
                                    return strrep(" ", len - tab) .. str:sub(len + 1, -1)
                                end
                            end)
                        end

                        return rawget(self, key)
                    end
                end
            end,
        })

        wipe(_IndentFunc)
        wipe(_ShiftIndentFunc)
    end

    function Search2Next(self)
        if not self.__InSearch then
            return
        end

        local text = self.__Editor.Text

        local startp, endp = text:find(self.__InSearch, self.CursorPosition)

        if not startp then
            startp, endp = text:find(self.__InSearch, 0)
        end

        local s, e

        s = startp
        e = endp

        if s and e then
            SaveOperation(self)

            AdjustCursorPosition(self, e)

            self:HighlightText(s - 1, e)
        else
            IGAS:MsgBox(L"'%s' can't be found in the content.":format(self.__InSearch))

            self:SetFocus()
        end
    end

    function GoLineByNo(self, no)
        local text = self.__Editor.Text
        local lineBreak

        if text:find("\n") then
            lineBreak = "\n"
        elseif text:find("\r") then
            lineBreak = "\r"
        else
            lineBreak = false
        end

        no = no - 1

        local pos = 0
        local newPos

        if not lineBreak then
            return
        end

        SaveOperation(self)

        while no > 0 do
            newPos = text:find(lineBreak, pos + 1)

            if newPos then
                no = no - 1
                pos = newPos
            else
                break
            end
        end

        return AdjustCursorPosition(self, pos)
    end

    function Thread_FindText(self)
        local searchText = IGAS:MsgBox(L"Please input the search content", "ic")

        self:SetFocus()

        searchText = searchText and strtrim(searchText)

        if searchText and searchText ~= "" then
            -- Prepare the search
            self.__InSearch = searchText

            Search2Next(self)
        end
    end

    function Thread_GoLine(self)
        local goLine = IGAS:MsgBox(L"Please input the line number", "ic")

        self:SetFocus()

        goLine = goLine and tonumber(goLine)

        if goLine and goLine >= 1 then
            GoLineByNo(self, floor(goLine))
        end
    end

    function Thread_GoLastLine4Enter(self, value, h)
        local count = 10

        while count > 0 and self:GetVerticalScrollRange() + h < value do
            count = count - 1
            Threading.Sleep(0.1)
        end

        self.Value = value
    end

    function Thread_DELETE(self)
        local first = true
        local str = self.__Editor.Text
        local pos = self.CursorPosition + 1
        local byte
        local isSpecial = nil
        local nextPos

        while self.__DELETE do
            isSpecial = nil

            if first and self.__HighlightTextStart ~= self.__HighlightTextEnd then
                pos = self.__HighlightTextStart + 1
                nextPos = self.__HighlightTextEnd + 1
            else
                nextPos = pos
                byte = strbyte(str, nextPos)

                -- yap, I should do this myself
                if IsControlKeyDown() then
                    -- delete words
                    while true do
                        if not byte then
                            break
                        elseif byte == _Byte.VERTICAL then
                            nextPos = nextPos + 1
                            byte = strbyte(str, nextPos)

                            if byte == _Byte.c then
                                -- skip color start
                                nextPos = nextPos + 8
                            elseif byte == _Byte.r then
                                -- skip color end
                            else
                                -- only mean "||"
                                if isSpecial == nil then
                                    isSpecial = true
                                elseif not isSpecial then
                                    nextPos = nextPos - 1
                                    break
                                end
                            end
                        else
                            if isSpecial == nil then
                                isSpecial = _Special[byte] and true or false
                            elseif not isSpecial then
                                if _Special[byte] then
                                    break
                                end
                            else
                                if not _Special[byte] then
                                    break
                                end
                            end
                        end

                        nextPos = nextPos + 1
                        byte = strbyte(str, nextPos)
                    end
                else
                    -- delete char
                    while true do
                        if not byte then
                            break
                        elseif byte == _Byte.VERTICAL then
                            nextPos = nextPos + 1
                            byte = strbyte(str, nextPos)

                            if byte == _Byte.c then
                                -- skip color start
                                nextPos = nextPos + 8
                            elseif byte == _Byte.r then
                                -- skip color end
                            else
                                -- only mean "||"
                                nextPos = nextPos + 1
                                break
                            end
                        else
                            if byte >= _UTF8_Three_Char then
                                nextPos = nextPos + 3
                            elseif byte >= _UTF8_Two_Char then
                                nextPos = nextPos + 2
                            else
                                nextPos = nextPos + 1
                            end
                            break
                        end

                        nextPos = nextPos + 1
                        byte = strbyte(str, nextPos)
                    end
                end
            end

            if pos == nextPos then
                break
            end

            str = ReplaceBlock(str, pos, nextPos - 1, "")

            self.__Editor.Text = str

            AdjustCursorPosition(self, pos - 1)

            -- Do for long press
            if first then
                Threading.Sleep(_FIRST_WAITTIME)
                first = false
            else
                Threading.Sleep(_CONTINUE_WAITTIME)
            end
        end

        self:Fire("OnDeleteFinished")
    end

    function Thread_BACKSPACE(self)
        local first = true
        local str = self.__Editor.Text
        local pos = self.CursorPosition
        local byte
        local isSpecial = nil
        local prevPos
        local prevIndex
        local prevColorStart = nil
        local prevWhite = 0
        local whiteIndex = 0

        _BackSpaceList.LastIndex = 0

        while self.__BACKSPACE do
            isSpecial = nil

            if first and self.__HighlightTextStart ~= self.__HighlightTextEnd then
                pos = self.__HighlightTextEnd
                prevPos = self.__HighlightTextStart + 1
            else
                -- prepare char list
                if _BackSpaceList.LastIndex == 0 then
                    -- index the prev return char
                    prevPos = pos
                    byte = strbyte(str, prevPos)
                    prevWhite = 0
                    whiteIndex = 0

                    while true do
                        if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                            break
                        end

                        prevPos = prevPos - 1
                        byte = strbyte(str, prevPos)
                    end

                    if byte then
                        -- record the newline
                        _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                        _BackSpaceList[_BackSpaceList.LastIndex] = prevPos
                    end

                    prevPos = prevPos + 1

                    -- Check prev space
                    if prevPos <= pos then
                        byte = strbyte(str, prevPos)

                        if byte == _Byte.SPACE then
                            _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                            _BackSpaceList[_BackSpaceList.LastIndex] = prevPos
                            whiteIndex = _BackSpaceList.LastIndex

                            while prevPos <= pos do
                                prevWhite = prevWhite + 1
                                prevPos = prevPos + 1
                                byte = strbyte(str, prevPos)

                                if byte ~= _Byte.SPACE then
                                    break
                                end
                            end
                        end
                    end

                    while prevPos <= pos do
                        byte = strbyte(str, prevPos)

                        if byte == _Byte.VERTICAL then
                            prevPos = prevPos + 1
                            byte = strbyte(str, prevPos)

                            if byte == _Byte.c then
                                prevColorStart = prevColorStart or (prevPos - 1)
                                -- skip color start
                                prevPos = prevPos + 9
                            elseif byte == _Byte.r then
                                prevColorStart = prevColorStart or (prevPos - 1)
                                -- skip color end
                                prevPos = prevPos + 1
                            else
                                -- only mean "||"
                                _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                                _BackSpaceList[_BackSpaceList.LastIndex] = prevColorStart or prevPos - 1
                                prevColorStart = nil

                                prevPos = prevPos + 1
                            end
                        elseif _Special[byte] then
                            _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                            _BackSpaceList[_BackSpaceList.LastIndex] = prevColorStart or prevPos
                            prevColorStart = nil

                            prevPos = prevPos + 1
                        else
                            _BackSpaceList.LastIndex = _BackSpaceList.LastIndex + 1
                            _BackSpaceList[_BackSpaceList.LastIndex] = prevColorStart or prevPos
                            prevColorStart = nil

                            if byte >= _UTF8_Three_Char then
                                prevPos = prevPos + 3
                            elseif byte >= _UTF8_Two_Char then
                                prevPos = prevPos + 2
                            else
                                prevPos = prevPos + 1
                            end
                        end
                    end
                end

                if _BackSpaceList.LastIndex == 0 then
                    break
                end

                prevIndex = _BackSpaceList.LastIndex

                -- yap, I should do this myself
                if IsControlKeyDown() then
                    -- delete words
                    while prevIndex > 0 do
                        prevPos = _BackSpaceList[prevIndex]
                        byte = strbyte(str, prevPos)

                        while byte == _Byte.VERTICAL do
                            prevPos = prevPos + 1
                            byte = strbyte(str, prevPos)

                            if byte == _Byte.c then
                                -- skip color start
                                prevPos = prevPos + 9
                                byte = strbyte(str, prevPos)
                            elseif byte == _Byte.r then
                                -- skip color end
                                prevPos = prevPos + 1
                                byte = strbyte(str, prevPos)
                            else
                                prevPos = prevPos - 1
                                byte = strbyte(str, prevPos)
                                break
                            end
                        end

                        if isSpecial == nil then
                            isSpecial = _Special[byte] and true or false
                        elseif isSpecial then
                            if not _Special[byte] then
                                break
                            end
                        else
                            if _Special[byte] then
                                break
                            end
                        end

                        prevIndex = prevIndex - 1
                    end

                    prevIndex = prevIndex + 1
                    prevPos = _BackSpaceList[prevIndex]

                    _BackSpaceList.LastIndex = prevIndex - 1
                else
                    if prevIndex ~= whiteIndex or (prevIndex == whiteIndex and prevWhite == 0) then
                        -- delete char
                        prevPos = _BackSpaceList[prevIndex]

                        _BackSpaceList.LastIndex = prevIndex - 1
                    else
                        prevPos = _BackSpaceList[prevIndex]

                        prevWhite = (ceil(prevWhite / self.TabWidth) - 1) * self.TabWidth
                        if prevWhite < 0 then prevWhite = 0 end

                        prevPos = prevPos + prevWhite

                        if prevWhite <= 0 then
                            _BackSpaceList.LastIndex = prevIndex - 1
                        end
                    end
                end
            end

            -- Auto pairs check
            local char = str:sub(prevPos, pos)
            local offset = pos

            char = RemoveColor(char)

            if char and char:len() == 1 and _AutoPairs[strbyte(char)] then
                offset = offset + 1

                byte = strbyte(str, offset)

                while true do
                    if byte == _Byte.VERTICAL then
                        -- handle the color code
                        offset = offset + 1
                        byte = strbyte(str, offset)

                        if byte == _Byte.c then
                            offset = offset + 9
                        elseif byte == _Byte.r then
                            offset = offset + 1
                        else
                            offset = offset - 1
                            break
                        end

                        byte = strbyte(str, offset)
                    else
                        break
                    end
                end

                if (_AutoPairs[strbyte(char)] == true and byte == strbyte(char)) or _AutoPairs[strbyte(char)] == byte then
                    -- pass
                else
                    offset = pos
                end
            end

            -- Delete
            str = ReplaceBlock(str, prevPos, offset, "")

            self.__Editor.Text = str

            AdjustCursorPosition(self, prevPos - 1)

            pos = prevPos - 1

            -- Do for long press
            if first then
                Threading.Sleep(_FIRST_WAITTIME)
                first = false
            else
                Threading.Sleep(_CONTINUE_WAITTIME)
            end
        end

        -- shift tab
        pos = self.CursorPosition
        local startp, endp, line = GetLines(str, pos)

        local _, len = line:find("^%s+")

        if len and len > 1 and startp + len - 1 >= pos then
            if len % self.TabWidth ~= 0 then
                line = line:sub(len + 1, -1)
                len = floor(len/self.TabWidth) * self.TabWidth

                line = strrep(" ", len) .. line

                str = ReplaceBlock(str, startp, endp, line)

                self.__Editor.Text = str

                AdjustCursorPosition(self, startp - 1 + len)
            end
        end

        self:Fire("OnBackspaceFinished")
    end

    _DirectionKeyEventArgs = EventArgs()

    function _KeyScan:OnKeyDown(key)
        if _SkipKey[key] then return end

        if self.FocusEditor and key then
            local editor = self.FocusEditor
            local cursorPos = editor.CursorPosition

            local oper = _KEY_OPER[key]

            if oper then
                if oper == _Operation.CHANGE_CURSOR then

                    _DirectionKeyEventArgs.Handled = false
                    _DirectionKeyEventArgs.Cancel = false
                    _DirectionKeyEventArgs.Key = key

                    editor:Fire("OnDirectionKey", _DirectionKeyEventArgs)

                    if _DirectionKeyEventArgs.Handled or _DirectionKeyEventArgs.Cancel then
                        self.ActiveKeys[key] = true
                        return self:SetPropagateKeyboardInput(false)
                    end

                    if key == "PAGEUP" then
                        local text = editor.__Editor.Text
                        local skipLine = floor(editor.Height / editor.ValueStep)
                        local startp, endp, _, line = GetPrevLinesByReturn(text, cursorPos, skipLine)

                        if line == 0 then
                            return
                        end

                        EndPrevKey(editor)

                        SaveOperation(editor)

                        if editor.Value > editor.Height then
                            editor.Value = editor.Value - editor.Height
                        else
                            editor.Value = 0
                        end

                        if IsShiftKeyDown() then
                            editor.__SKIPCURCHG = cursorPos
                        end

                        editor.CursorPosition = GetCursorPosByOffset(text, startp, GetOffsetByCursorPos(text, nil, cursorPos))

                        return
                    end

                    if key == "PAGEDOWN" then
                        local text = editor.__Editor.Text
                        local skipLine = floor(editor.Height / editor.ValueStep)
                        local startp, endp, _, line = GetLinesByReturn(text, cursorPos, skipLine)

                        if line == 0 then
                            return
                        end

                        EndPrevKey(editor)

                        SaveOperation(editor)

                        local maxValue = editor.Container.Height - editor.Height

                        if editor.Value + editor.Height < maxValue then
                            editor.Value = editor.Value + editor.Height
                        else
                            editor.Value = maxValue
                        end

                        if IsShiftKeyDown() then
                            editor.__SKIPCURCHG = cursorPos
                        end

                        editor.CursorPosition = GetCursorPosByOffset(text, endp, GetOffsetByCursorPos(text, nil, cursorPos))

                        return
                    end

                    if key == "HOME" then
                        local text = editor.__Editor.Text
                        local startp, endp = GetLines(text, cursorPos)
                        local byte

                        if startp - 1 == cursorPos then
                            return
                        end

                        EndPrevKey(editor)

                        SaveOperation(editor)

                        if IsShiftKeyDown() then
                            editor.__SKIPCURCHG = cursorPos
                        end

                        return
                    end

                    if key == "END" then
                        local startp, endp = GetLines(editor.__Editor.Text, cursorPos)

                        if endp == cursorPos then
                            return
                        end

                        EndPrevKey(editor)

                        SaveOperation(editor)

                        if IsShiftKeyDown() then
                            editor.__SKIPCURCHG = cursorPos
                        end

                        return
                    end

                    if key == "UP" then
                        local _, _, _, line = GetPrevLinesByReturn(editor.__Editor.Text, cursorPos, 1)

                        if line > 0 then
                            EndPrevKey(editor)

                            SaveOperation(editor)

                            if IsShiftKeyDown() then
                                editor.__SKIPCURCHG = cursorPos
                                editor.__SKIPCURCHGARROW = true
                            end
                        end

                        return
                    end

                    if key == "DOWN" then
                        local _, _, _, line = GetLinesByReturn(editor.__Editor.Text, cursorPos, 1)

                        if line > 0 then
                            EndPrevKey(editor)

                            SaveOperation(editor)

                            if IsShiftKeyDown()  then
                                editor.__SKIPCURCHG = cursorPos
                                editor.__SKIPCURCHGARROW = true
                            end
                        end

                        return
                    end

                    if key == "RIGHT" then
                        if cursorPos < editor.__Editor.Text:len() then
                            EndPrevKey(editor)

                            SaveOperation(editor)

                            if IsShiftKeyDown() then
                                editor.__SKIPCURCHG = cursorPos
                                editor.__SKIPCURCHGARROW = true
                            end
                        end

                        return
                    end

                    if key == "LEFT" then
                        if cursorPos > 0 then
                            EndPrevKey(editor)

                            SaveOperation(editor)

                            if IsShiftKeyDown() then
                                editor.__SKIPCURCHG = cursorPos
                                editor.__SKIPCURCHGARROW = true
                            end
                        end

                        return
                    end
                end

                if key == "TAB" then
                    EndPrevKey(editor)
                    return NewOperation(editor, _Operation.INPUTTAB)
                end

                if key == "DELETE" then
                    if not editor.__DELETE and not IsShiftKeyDown() and (editor.__HighlightTextStart ~= editor.__HighlightTextEnd or cursorPos < editor.__Editor.Text:len()) then
                        EndPrevKey(editor)
                        editor.__DELETE = true
                        NewOperation(editor, _Operation.DELETE)
                        self.ActiveKeys[key] = true
                        self:SetPropagateKeyboardInput(false)

                        _Thread.Thread = Thread_DELETE
                        return _Thread(editor)
                    end
                    return
                end

                if key == "BACKSPACE" then
                    if not editor.__BACKSPACE and cursorPos > 0 then
                        EndPrevKey(editor)
                        editor.__BACKSPACE = cursorPos
                        NewOperation(editor, _Operation.BACKSPACE)
                        self.ActiveKeys[key] = true
                        self:SetPropagateKeyboardInput(false)

                        _Thread.Thread = Thread_BACKSPACE
                        return _Thread(editor)
                    end
                    return
                end

                if key == "ENTER" then
                    EndPrevKey(editor)
                    -- editor.__SKIPCURCHG = true
                    return NewOperation(editor, _Operation.ENTER)
                end
            end

            EndPrevKey(editor)

            -- Don't consider multi-modified keys
            if IsShiftKeyDown() then
                -- shift+
            elseif IsAltKeyDown() then
                return editor:Fire("OnAltKey", key)
            elseif IsControlKeyDown() then
                if key == "A" then
                    editor:HighlightText()
                    return
                elseif key == "V" then
                    editor.__InPasting = true
                    return NewOperation(editor, _Operation.PASTE)
                elseif key == "C" then
                    -- do nothing
                    return
                --[[elseif key == "Z" then
                    return editor:Undo()
                elseif key == "Y" then
                    return editor:Redo()--]]
                elseif key == "X" then
                    if editor.__HighlightTextStart ~= editor.__HighlightTextEnd then
                        NewOperation(editor, _Operation.CUT)
                    end
                    return
                elseif key == "F" then
                    _Thread.Thread = Thread_FindText
                    return _Thread(editor)
                elseif key == "G" then
                    _Thread.Thread = Thread_GoLine
                    return _Thread(editor)
                else
                    return editor:Fire("OnControlKey", key)
                end
            elseif key:find("^F%d+") == 1 then
                if key == "F3" and editor.__InSearch then
                    -- Continue Search
                    return Search2Next(editor)
                end

                return editor:Fire("OnFunctionKey", key)
            end

            return NewOperation(editor, _Operation.INPUTCHAR)
        end
    end

    function _KeyScan:OnKeyUp(key)
        self:SetPropagateKeyboardInput(true)

        self.ActiveKeys[key] = nil

        if self.FocusEditor then
            if key == "DELETE" then
                self.FocusEditor.__DELETE = nil
            end
            if key == "BACKSPACE" then
                self.FocusEditor.__BACKSPACE = nil
            end
        end

        if _Thread:IsSuspended() then
            _Thread:Resume()
        end
    end

    ------------------------------------------------------
    -- Widget Event
    ------------------------------------------------------
    -- Fired when press enter key
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnEnterPressed" }
    event "OnEnterPressed"

    -- Fired when cursor location changed
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnCursorChanged" }
    event "OnCursorChanged"

    -- Fired when a char is input
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnChar" }
    event "OnChar"

    -- Fired when the operation list changed
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnOperationListChanged" }
    event "OnOperationListChanged"

    -- Fired when text is pasted
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnPasting" }
    event "OnPasting"

    -- Fired when release the delete key
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnDeleteFinished" }
    event "OnDeleteFinished"

    -- Fired when release the backspace key
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnBackspaceFinished" }
    event "OnBackspaceFinished"

    -- Fired when the text is cut
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnCut" }
    event "OnCut"

    -- Fired when press the escape key
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnEscapePressed" }
    event "OnEscapePressed"

    -- Fired when the editor lost focus
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnEditFocusLost" }
    event "OnEditFocusLost"

    -- Fired when press the direction key
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnDirectionKey" }
    event "OnDirectionKey"

    -- Fired when press the tab key
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnTabPressed" }
    event "OnTabPressed"

    -- Fired when moving the cursor to a new line
    __Bubbling__{ ["ScrollChild.EditBox"] = "OnNewLine" }
    event "OnNewLine"

    ------------------------------------------------------
    -- Methods
    ------------------------------------------------------
    function AdjustCursorPosition(self, pos)
        self.__OldCursorPosition= pos
        self.__Editor:SetCursorPosition(pos)
        return self.__Editor:HighlightText(pos, pos)
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
        self.__Editor           = self:GetChild("ScrollChild"):GetChild("EditBox")
        self.__LineNum          = self:GetChild("ScrollChild"):GetChild("LineNum")
    end
end)


-----------------------------------------------------------
--                Editor Style - Default                 --
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
        ScrollChild             = {
            LineNum             = {
                location        = Anchor{ Anchor("TOPLEFT") },
                width           = 5,
                justifyV        = "TOP",
                justifyH        = "CENTER",
            },
        }
    }
})