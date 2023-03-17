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

    __Sealed__()
    class "OperationStack" (function(_ENV)
        export { yield = coroutine.yield }

        local FIELD_BASE        = -1
        local FIELD_CURSOR      = -2
        local FIELD_COUNT       = -3
        local FIELD_MAX         = -4

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The max count of the stack
        property "MaxCount"     { field = FIELD_MAX, type = Number, default = -1 }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function Push(self, oper, text, start, stop)
            local max           = self.MaxCount
            if max == 0 then return end

            local base          = self[FIELD_BASE]

            self[FIELD_CURSOR]  = self[FIELD_CURSOR] + 1
            self[FIELD_COUNT]   = self[FIELD_CURSOR]

            base                = base + (self[FIELD_COUNT] - 1) * 4 + 1

            self[base + 0]      = oper
            self[base + 1]      = text
            self[base + 2]      = start
            self[base + 3]      = stop

            -- Reduce the stack
            if max > 0 and self[FIELD_COUNT] > max then
                local last      = base + (self[FIELD_COUNT] - max) * 4
                for i = base + 1, last do
                    self[i]     = nil
                end
                self[FIELD_BASE]= last
                self[FIELD_COUNT] = max
                self[FIELD_CURSOR]= max
            end
        end

        function Undo(self)
            if self[FIELD_CURSOR] > 1 then
                self[FIELD_CURSOR] = self[FIELD_CURSOR] - 1

                local base      = self[FIELD_BASE] + (self[FIELD_CURSOR] - 1) * 4 + 1
                return self[base], self[base + 1], self[base + 2], self[base + 3]
            end
        end

        function Redo(self)
            if self[FIELD_CURSOR] < self[FIELD_COUNT] then
                self[FIELD_CURSOR] = self[FIELD_CURSOR] + 1

                local base      = self[FIELD_BASE] + (self[FIELD_CURSOR] - 1) * 4 + 1
                return self[base], self[base + 1], self[base + 2], self[base + 3]
            end
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __new(_, maxcount)
            return {
                [FIELD_BASE]    = 0,
                [FIELD_COUNT]   = 0,
                [FIELD_CURSOR]  = 0,
                [FIELD_MAX]     = maxcount or -1,
            }, true
        end
    end)

    export {
        tinsert                 = table.insert,
        tremove                 = table.remove,
        tblconcat               = table.concat,
        strbyte                 = string.byte,
        strchar                 = string.char,
        strrep                  = string.rep,
        strtrim                 = Toolset.trim,
        decode                  = Text.UTF8Encoding.Decode,

        BYTE_WORD_KIND          = 0,
        BYTE_PUNC_KIND          = 1,
        BYTE_SPACE_KIND         = 2,

        DOUBLE_CLICK_INTERVAL   = 0.6,
        _FIRST_WAITTIME         = 0.3,
        _CONTINUE_WAITTIME      = 0.05,
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

    -- Operation
    _Operation                  = {
        INIT                    = 0,
        CHANGE_CURSOR           = 1,
        INPUTCHAR               = 2,
        INPUTTAB                = 3,
        DELETE                  = 4,
        BACKSPACE               = 5,
        ENTER                   = 6,
        PASTE                   = 7,
        CUT                     = 8,
        INDENTFORMAT            = 9,
        DELETE_LINE             = 10,
        DUPLICATE_LINE          = 11,
        UNDO_SAVE               = 12,
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
    -- Short Key Block
    ------------------------------------------------------
    _BtnBlockUp                 = CreateFrame("Button", "Scorpio_TextEditor_UpBlock", UIParent, "SecureActionButtonTemplate")
    _BtnBlockDown               = CreateFrame("Button", "Scorpio_TextEditor_DownBlock", UIParent, "SecureActionButtonTemplate")
    _BtnBlockUp:Hide()
    _BtnBlockDown:Hide()

    ------------------------------------------------------
    -- Key Scanner
    ------------------------------------------------------
    _KeyScan                    = CreateFrame("Frame", nil, UIParent)
    _KeyScan:Hide()
    _KeyScan:SetPropagateKeyboardInput(true)
    _KeyScan:EnableKeyboard(true)
    _KeyScan:SetFrameStrata("TOOLTIP")
    _KeyScan.ActiveKeys         = {}

    ------------------------------------------------------
    -- Inpput Helpers
    ------------------------------------------------------
    local function getPrevVerticalCount(str, pos)
        local sum               = 0

        while pos > 0 do
            local byte          = strbyte(str, pos)
            if byte ~= _Byte.VERTICAL then break end
            sum                 = sum + 1
            pos                 = pos - 1
        end

        return sum
    end

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
                    return pos, true
                end
            else
                return pos
            end
        end
    end

    local function checkUTF8(str, pos)
        local code, len         = decode(str, pos)
        return len and (pos + len - 1) or pos
    end

    local function skipPrevColor(str, pos)
        while pos > 0 do
            local byte          = strbyte(str, pos)
            if byte == _Byte.r then
                if getPrevVerticalCount(str, pos - 1) % 2 == 1 then
                    pos         = pos - 2
                else
                    return pos
                end
            elseif pos >= 10 and strbyte(str, pos - 8) == _Byte.c and getPrevVerticalCount(str, pos - 9) % 2 == 1 then
                pos             = pos - 10
            else
                return pos
            end
        end
    end

    local function checkPrevUTF8(str, pos)
        while pos and pos > 0 do
            local byte          = strbyte(str, pos)
            if byte < 0x80 then
                if byte == _Byte.VERTICAL then
                    return pos  - 1
                end
                return pos -- 1-byte
            elseif byte >= 0xC0 then
                return pos
            end

            pos                 = pos - 1
        end
        return 0
    end

    local function removeColor(str)
        local start             = 1
        local pos               = 1
        local npos, isv
        local count             = 0

        wipe(_Temp)

        while pos <= #str do
            npos, isv           = skipColor(str, pos)

            if npos ~= pos then
                count           = count + 1
                _Temp[count]    = str:sub(start, pos - 1)
                start           = npos
            end

            pos                 = npos + (isv and 2 or 1)
        end

        count                   = count + 1
        _Temp[count]            = str:sub(start, -1)

        local result            = tblconcat(_Temp)
        wipe(_Temp)

        return result
    end

    local function updateLineNum(self, try)
        local editor            = self.__Editor
        local linenum           = self.__LineNum

        if not linenum:IsShown() then return end

        local font, height, flag= editor:GetFont()
        local spacing           = editor:GetSpacing()
        local left, right       = editor:GetTextInsets()
        local lineWidth         = editor:GetWidth() - left - right
        local lineHeight        = height + spacing

        -- Wait for one phase
        if not font then return not try and Next(updateLineNum, self, true) end

        local text              = editor:GetText()
        local index             = 0
        local count             = 0
        local extra             = 0

        local lines             = linenum.Lines or {}
        linenum.Lines           = lines

        linenum:SetHeight(editor:GetHeight() + 10)

        _TestFontString:SetFont(font, height, flag)
        _TestFontString:SetSpacing(spacing)
        _TestFontString:SetIndentedWordWrap(editor:GetIndentedWordWrap())
        _TestFontString:SetWidth(lineWidth)

        for _, line in strsplit(text, "\n") do
            index               = index + 1
            count               = count + 1

            lines[count]        = index

            _TestFontString:SetText(line)

            extra               = _TestFontString:GetStringHeight() / lineHeight
            extra               = floor(extra) - 1

            for i = 1, extra do
                count           = count + 1
                lines[count]    = ""
            end
        end

        for i = #lines, count + 1, -1 do
            lines[i]            = nil
        end

        linenum:SetText(tblconcat(lines, "\n"))
    end

    local function replaceBlock(str, startp, endp, replace)
        return startp and (str:sub(1, startp - 1) .. replace .. str:sub(endp + 1, -1)) or str
    end

    local function getLines(str, startp, endp)
        endp                    = endp and (endp + 1) or endp == nil and (startp + 1) or endp

        -- get prev LineBreak
        while startp > 0 do
            local byte          = strbyte(str, startp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            startp              = startp - 1
        end

        startp                  = startp + 1

        if not endp then return startp end

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
        return startp, endp
    end

    local function getByteType(byte)
        return _Puncs[byte] and BYTE_PUNC_KIND or _Spaces[byte] and BYTE_SPACE_KIND or byte and BYTE_WORD_KIND
    end

    local function getWord(str, pos, notail, nopre)
        local startp, endp      = getLines(str, pos)
        if startp > endp then return end

        local pretype, tailtype

        -- Check the match type
        if not notail then
            tailtype            = getByteType(strbyte(str, (skipColor(str, pos + 1)))) or -1
        end

        if tailtype == 0 or nopre then
            pretype             = 0
        else
            pretype             = getByteType(strbyte(str, skipPrevColor(str, pos))) or -1
        end

        -- Match the word
        local prev, tail        = pos + 1, pos

        if not nopre then
            repeat
                prev            = skipPrevColor(str, prev - 1)
            until not prev or prev < startp or getByteType(strbyte(str, prev)) ~= pretype
            prev                = prev and (prev + 1) or 1
        end

        if not notail then
            local isv
            repeat
                tail, isv       = skipColor(str, tail + (isv and 2 or 1))
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

    local function endPrevKey(self)
        if self._SKIPCURCHGARROW then
            self._SKIPCURCHGARROW = nil
            self._SKIPCURCHG    = nil
        end
        self._InPasting         = false
        self._DownOffset        = false
    end

    local function isKeyPressed(self, key)
        return _KeyScan.FocusEditor == self and _KeyScan.ActiveKeys[key] or false
    end

    local function getLinesByReturn(str, startp, returnCnt)
        local byte
        local handledReturn     = 0
        local endp              = startp + 1

        returnCnt               = returnCnt or 0

        -- get prev LineBreak
        while startp > 0 do
            byte                = strbyte(str, startp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            startp              = startp - 1
        end

        startp                  = startp + 1

        -- get next LineBreak
        while true do
            byte                = strbyte(str, endp)

            if not byte then
                break
            elseif byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                returnCnt       = returnCnt - 1

                if returnCnt < 0 then
                    break
                end

                handledReturn   = handledReturn + 1
            end

            endp                = endp + 1
        end

        endp                    = endp - 1

        -- get block
        return startp, endp, handledReturn
    end

    local function getPrevLinesByReturn(str, startp, returnCnt)
        local byte
        local handledReturn     = 0
        local endp              = startp + 1

        returnCnt               = returnCnt or 0

        -- get prev LineBreak
        while true do
            byte                = strbyte(str, endp)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            endp                = endp + 1
        end

        endp                    = endp - 1

        local prevReturn

        -- get prev LineBreak
        while startp > 0 do
            byte                = strbyte(str, startp)

            if not byte then
                break
            elseif byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                returnCnt       = returnCnt - 1

                if returnCnt < 0 then
                    break
                end

                prevReturn      = startp

                handledReturn   = handledReturn + 1
            end

            startp              = startp - 1
        end

        if not prevReturn or prevReturn >  startp + 1 then
            startp              = startp + 1
        end

        -- get block
        return startp, endp, handledReturn
    end

    local function getOffsetByCursorPos(str, cursorPos)
        if not cursorPos or cursorPos <= 0 then return 0 end

        local startp            = getLines(str, cursorPos, false)
        local byteCnt, isv      = 0

        while startp <= cursorPos do
            startp, isv         = skipColor(str, startp)

            byteCnt             = byteCnt + 1
            startp              = startp + (isv and 2 or 1)
        end

        return byteCnt
    end

    local function getCursorPosByOffset(str, cursorPos, offset)
        local startp, endp      = getLines(str, cursorPos)
        startp                  = startp - 1

        local byteCnt, isv      = 0

        while byteCnt < offset and startp <= endp do
            startp, isv         = skipColor(str, startp)

            byteCnt             = byteCnt + 1
            startp              = startp + (isv and 2 or 1)
        end

        return startp
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

    ------------------------------------------------------
    -- Code Helpers
    ------------------------------------------------------
    _INPUTCHAR                  = _Operation.INPUTCHAR
    _BACKSPACE                  = _Operation.BACKSPACE

    _UTF8_Three_Char            = 224
    _UTF8_Two_Char              = 192

    _IndentNone                 = 0
    _IndentRight                = 1
    _IndentLeft                 = 2
    _IndentBoth                 = 3

    _EndColor                   = "|r"

    -- Token
    _Token                      = {
        UNKNOWN                 = 0,
        LINEBREAK               = 1,
        SPACE                   = 2,
        OPERATOR                = 3,
        LEFTBRACKET             = 4,
        RIGHTBRACKET            = 5,
        LEFTPAREN               = 6,
        RIGHTPAREN              = 7,
        LEFTWING                = 8,
        RIGHTWING               = 9,
        COMMA                   = 10,
        SEMICOLON               = 11,
        COLON                   = 12,
        HASH                    = 13,
        NUMBER                  = 14,
        COLORCODE_START         = 15,
        COLORCODE_END           = 16,
        COMMENT                 = 17,
        STRING                  = 18,
        ASSIGNMENT              = 19,
        EQUALITY                = 20,
        PERIOD                  = 21,
        DOUBLEPERIOD            = 22,
        TRIPLEPERIOD            = 23,
        LT                      = 24,
        LTE                     = 25,
        GT                      = 26,
        GTE                     = 27,
        NOTEQUAL                = 28,
        TILDE                   = 29,
        IDENTIFIER              = 30,
        VERTICAL                = 31,
    }

    _WordWrap                   = {
        [0] = _IndentNone,      -- UNKNOWN
        _IndentNone,            -- LINEBREAK
        _IndentNone,            -- SPACE
        _IndentBoth,            -- OPERATOR
        _IndentNone,            -- LEFTBRACKET
        _IndentNone,            -- RIGHTBRACKET
        _IndentNone,            -- LEFTPAREN
        _IndentNone,            -- RIGHTPAREN
        _IndentNone,            -- LEFTWING
        _IndentNone,            -- RIGHTWING
        _IndentRight,           -- COMMA
        _IndentNone,            -- SEMICOLON
        _IndentNone,            -- COLON
        _IndentLeft,            -- HASH
        _IndentNone,            -- NUMBER
        _IndentNone,            -- COLORCODE_START
        _IndentNone,            -- COLORCODE_END
        _IndentNone,            -- COMMENT
        _IndentNone,            -- STRING
        _IndentBoth,            -- ASSIGNMENT
        _IndentBoth,            -- EQUALITY
        _IndentNone,            -- PERIOD
        _IndentBoth,            -- DOUBLEPERIOD
        _IndentNone,            -- TRIPLEPERIOD
        _IndentBoth,            -- LT
        _IndentBoth,            -- LTE
        _IndentBoth,            -- GT
        _IndentBoth,            -- GTE
        _IndentBoth,            -- NOTEQUAL
        _IndentNone,            -- TILDE
        _IndentNone,            -- IDENTIFIER
        _IndentNone,            -- VERTICAL
    }

    -- Words
    _KeyWord                    = {
        ["and"]                 = _IndentNone,
        ["break"]               = _IndentNone,
        ["do"]                  = _IndentRight,
        ["else"]                = _IndentBoth,
        ["elseif"]              = _IndentLeft,
        ["end"]                 = _IndentLeft,
        ["false"]               = _IndentNone,
        ["for"]                 = _IndentNone,
        ["function"]            = _IndentRight,
        ["if"]                  = _IndentNone,
        ["in"]                  = _IndentNone,
        ["local"]               = _IndentNone,
        ["nil"]                 = _IndentNone,
        ["not"]                 = _IndentNone,
        ["or"]                  = _IndentNone,
        ["repeat"]              = _IndentRight,
        ["return"]              = _IndentNone,
        ["then"]                = _IndentRight,
        ["true"]                = _IndentNone,
        ["until"]               = _IndentLeft,
        ["while"]               = _IndentNone,
        -- Loop
        ["class"]               = _IndentNone,
        ["inherit"]             = _IndentNone,
        ["import"]              = _IndentNone,
        ["event"]               = _IndentNone,
        ["property"]            = _IndentNone,
        ["namespace"]           = _IndentNone,
        ["enum"]                = _IndentNone,
        ["struct"]              = _IndentNone,
        ["interface"]           = _IndentNone,
        ["extend"]              = _IndentNone,
    }

    -- Special
    _Special                    = {
        -- LineBreak
        [_Byte.LINEBREAK_N]     = _Token.LINEBREAK,
        [_Byte.LINEBREAK_R]     = _Token.LINEBREAK,

        -- Space
        [_Byte.SPACE]           = _Token.SPACE,
        [_Byte.TAB]             = _Token.SPACE,

        -- String
        [_Byte.SINGLE_QUOTE]    = -1,
        [_Byte.DOUBLE_QUOTE]    = -1,

        -- Operator
        [_Byte.MINUS]           = -1, -- need check
        [_Byte.PLUS]            = _Token.OPERATOR,
        [_Byte.SLASH]           = _Token.OPERATOR,
        [_Byte.ASTERISK]        = _Token.OPERATOR,
        [_Byte.PERCENT]         = _Token.OPERATOR,

        -- Compare
        [_Byte.LESSTHAN]        = -1,
        [_Byte.GREATERTHAN]     = -1,
        [_Byte.EQUALS]          = -1,

        -- Parentheses
        [_Byte.LEFTBRACKET]     = -1,
        [_Byte.RIGHTBRACKET]    = _Token.RIGHTBRACKET,
        [_Byte.LEFTPAREN]       = _Token.LEFTPAREN,
        [_Byte.RIGHTPAREN]      = _Token.RIGHTPAREN,
        [_Byte.LEFTWING]        = _Token.LEFTWING,
        [_Byte.RIGHTWING]       = _Token.RIGHTWING,

        -- Punctuation
        [_Byte.PERIOD]          = -1,
        [_Byte.COMMA]           = _Token.COMMA,
        [_Byte.SEMICOLON]       = _Token.SEMICOLON,
        [_Byte.COLON]           = _Token.COLON,
        [_Byte.TILDE]           = -1,
        [_Byte.HASH]            = _Token.HASH,

        -- WOW
        [_Byte.VERTICAL]        = -1,
    }

    -- Code Auto Completion
    _List                       = ListFrame("Scorpio_CodeEditor_AutoComplete", UIParent)
    _List:SetFrameStrata("TOOLTIP")
    _List:SetWidth(250)
    _List:Hide()

    _AutoCacheKeys              = List()
    _AutoCacheItems             = {}
    _AutoWordWeightCache        = {}
    _AutoWordMap                = {}
    _Recycle                    = {}
    _RecycleLast                = 0

    _AutoCheckKey               = ""
    _AutoCheckWord              = ""

    _BackAutoCache              = {}

    _CommonAutoCompleteList     = {}

    local function compare(t1, t2)
        t1                  = t1 or ""
        t2                  = t2 or ""

        local ut1           = strupper(t1)
        local ut2           = strupper(t2)

        if ut1 == ut2 then
            return t1 < t2
        else
            return ut1 < ut2
        end
    end

    local function compareWeight(t1, t2)
        return (_AutoWordWeightCache[t1] or 0) < (_AutoWordWeightCache[t2] or 0)
    end

    local function getIndex(list, name, sIdx, eIdx)
        if not sIdx then
            if not next(list) then return 0 end
            sIdx                = 1
            eIdx                = #list

            -- Border check
            if compare(name, list[sIdx]) then
                return 0
            elseif compare(list[eIdx], name) then
                return eIdx
            end
        end

        if sIdx == eIdx then return sIdx end

        local f                 = floor((sIdx + eIdx) / 2)

        if compare(name, list[f+1]) then
            return getIndex(list, name, sIdx, f)
        else
            return getIndex(list, name, f+1, eIdx)
        end
    end

    local function transMatchWord(w)
        return "(["..w:lower()..w:upper().."])([%w_%.]-)"
    end

    local function applyColor(...)
        local ret               = ""
        local word              = ""
        local pos               = 0

        local weight            = 0
        local n                 = select('#', ...)

        for i = 1, n do
            word                = select(i, ...)

            if i % 2 == 1 then
                pos             = floor((i+1)/2)
                ret             = ret .. Color.WHITE .. word .. Color.CLOSE

                if word ~= _AutoCheckKey:sub(pos, pos) then
                    weight      = weight + 1
                end
            else
                ret             = ret .. Color.GRAY .. word .. Color.CLOSE

                if i < n then
                    weight = weight + word:len()
                end
            end
        end

        _AutoWordWeightCache[_AutoCheckWord] = weight
        _AutoWordMap[_AutoCheckWord] = ret

        return ret
    end

    local function initCommonList()
        local index             = 0

        for i, v in ipairs{ "math", "string", "bit", "table", "coroutine" } do
            index               = i
            _CommonAutoCompleteList[i] = v
        end

        for k, v in pairs(_G) do
            if type(k) == "string" and (type(v) == "function" and not k:find("_") or type(v) == "table" and k:match("^C_")) then
                index           = index + 1
                _CommonAutoCompleteList[index] = k

                if index % 10 == 0 then
                    Continue()
                end
            end
        end

        local function addNamespaces(ns)
            index               = index + 1
            _CommonAutoCompleteList[index] = tostring(ns)

            if index % 10 == 0 then
                Continue()
            end

            for name, sns in Namespace.GetNamespaces(ns) do
                addNamespaces(sns)
            end
        end

        -- All namespaces from the PLoop
        addNamespaces(PLoop)

        Continue()
        List(_CommonAutoCompleteList):QuickSort(compare)
    end

    local function applyAutoComplete(self)
        local owner             = self.__Owner
        _List:Hide()

        if _CommonAutoCompleteList[1] or owner.AutoCompleteList[1] then
            -- Handle the auto complete
            local fullText      = self:GetText()
            local startp, endp  = getWord(fullText, self:GetCursorPosition(), true)
            local word          = startp and fullText:sub(startp, endp)

            if startp then
                local sp, ep    = getWord(fullText, startp - 1, true)

                if sp and sp == ep then
                    local byte  = strbyte(fullText, sp)

                    if byte == _Byte.PERIOD or byte == _Byte.COLON then
                        -- handle it later
                        if true then return end
                        local p = getWord(fullText, sp - 1, true)
                    end
                end
            end

            word                = word and removeColor(word)

            wipe(_AutoCacheKeys)
            wipe(_AutoWordMap)
            wipe(_AutoWordWeightCache)

            if word and word:match("^[%w_]+$") then
                word            = word:sub(1, 16)
                _AutoCheckKey   = word

                word            = word:lower()

                -- Match the auto complete list
                local uword     = "^" .. word:gsub("[%w_]", transMatchWord) .. "$"
                local header    = word:sub(1, 1)

                if not header or #header == 0 then return end

                local lst       = owner.AutoCompleteList
                local sIdx      = getIndex(lst, header)

                if sIdx == 0 then sIdx = 1 end

                for i = sIdx, #lst do
                    local value = lst[i]
                    if #value == 0 or compare(header, value:sub(1, 1)) then break end

                    _AutoCheckWord = value

                    if _AutoCheckWord:match(uword) then
                        _AutoCheckWord:gsub(uword, applyColor)

                        tinsert(_AutoCacheKeys, _AutoCheckWord)
                    end
                end

                lst             = _CommonAutoCompleteList
                sIdx            = getIndex(lst, header)

                if sIdx == 0 then sIdx = 1 end

                for i = sIdx, #lst do
                    local value = lst[i]
                    if not _AutoWordMap[value] then
                        if #value == 0 or compare(header, value:sub(1, 1)) then break end

                        _AutoCheckWord = value

                        if _AutoCheckWord:match(uword) then
                            _AutoCheckWord:gsub(uword, applyColor)

                            tinsert(_AutoCacheKeys, _AutoCheckWord)
                        end
                    end
                end

                _AutoCacheKeys:QuickSort(compareWeight)

                if #_AutoCacheKeys == 1 and _AutoCacheKeys[1] == _AutoCheckKey then
                    wipe(_AutoCacheKeys)
                end
            end

            for i, v in ipairs(_AutoCacheKeys) do
                local item  = _AutoCacheItems[i]
                if not item then
                    if _RecycleLast > 0 then
                        item= _Recycle[_RecycleLast]
                        _Recycle[_RecycleLast] = nil
                        _RecycleLast = _RecycleLast - 1
                    else
                        item= {}
                    end
                end

                item.checkvalue  = v
                item.text        = _AutoWordMap[v]
                --item.tiptitle  = text.tiptitle
                --item.tiptext   = text.tiptext

                _AutoCacheItems[i] = item
            end

            for i = #_AutoCacheItems, #_AutoCacheKeys + 1, -1 do
                _RecycleLast    = _RecycleLast + 1
                _Recycle[_RecycleLast] = _AutoCacheItems[i]
                _AutoCacheItems[i] = nil
            end

            -- Refresh the item
            _List.RawItems      = _AutoCacheItems
        end
    end

    local autoCompleteEditor
    local autoCompleteTime
    local taskStarted
    local autoComplete_x
    local autoComplete_y
    local autoComplete_w
    local autoComplete_h

    local function processAutoComplete()
        while autoCompleteEditor do
            if autoCompleteEditor and autoCompleteTime <= GetTime() then
                applyAutoComplete( autoCompleteEditor )

                if #_AutoCacheItems > 0 and autoCompleteEditor:HasFocus() then
                    _List.CurrentEditor = autoCompleteEditor

                    local owner     = autoCompleteEditor.__Owner
                    local linenum   = owner.__LineNum
                    local marginx   = linenum:IsShown() and linenum:GetWidth() or 0

                    -- Handle the auto complete
                    _List:ClearAllPoints()
                    _List:SetPoint("TOPLEFT", owner, autoComplete_x + marginx, autoComplete_y - autoComplete_h + Style[owner].ScrollBar.value)
                    _List:Show()
                    _List.SelectedIndex = 1
                else
                    _List.CurrentEditor = nil
                    _List:Hide()
                end

                autoCompleteEditor = nil
            end

            Next()
        end
        taskStarted     = false
    end

    local function registerAutoComplete(self, x, y, w, h)
        if not self.__Owner.AutoCompleteEnable then return end

        autoCompleteEditor      = self
        autoCompleteTime        = GetTime() + self.__Owner.AutoCompleteDelay
        autoComplete_x          = x
        autoComplete_y          = y
        autoComplete_w          = w
        autoComplete_h          = h

        if not taskStarted then
            taskStarted         = true
            -- Tiny cost for all editor
            Continue(processAutoComplete)
        end
    end

    local function initDefinition(self)
        self._IdentifierCache  = self._IdentifierCache or {}
        wipe(self._IdentifierCache)

        local owner             = self.__Owner

        owner:ClearAutoCompleteList()

        for k in pairs(_KeyWord) do
            self._IdentifierCache[k] = true
            owner:InsertAutoCompleteWord(k)
        end

        -- Operation Keep List
        self._OperationStack    = OperationStack(owner.MaxOperationCount)

        -- Clear now operation
        self._OperationOnLine   = nil
        self._OperationBackUpOnLine = nil
        self._OperationStartOnLine = nil
        self._OperationEndOnLine = nil
    end

    -- Token
    local function nextNumber(str, pos, noPeriod, cursorPos, trueWord, newPos)
        pos                     = pos or 1
        newPos                  = newPos or 0
        cursorPos               = cursorPos or 0

        -- just match, don't care error
        local e                 = 0
        local startPos          = pos

        local cnt               = 0
        local isHex             = true

        -- Number
        while true do
            local npos          = skipColor(str, pos)
            if npos ~= pos then
                trueWord        = trueWord and trueWord .. str:sub(startPos, pos - 1)
                pos             = npos
                startPos        = pos
            end

            local byte          = strbyte(str, pos)
            if not byte then break end

            cnt                 = cnt + 1

            if cnt == 1 and byte ~= _Byte.ZERO then isHex = false end
            if isHex and cnt == 2 and byte ~= _Byte.x and byte ~= _Byte.X then isHex = false end

            if isHex then
                if cnt > 2 then
                    if (byte >= _Byte.ZERO and byte <= _Byte.NINE) or (byte >= _Byte.a and byte <= _Byte.f) or (byte >= _Byte.A and byte <= _Byte.F) then
                        -- continue
                    else
                        break
                    end
                end
            else
                if byte >= _Byte.ZERO and byte <= _Byte.NINE then
                    if e == 1 then e = 2 end
                elseif byte == _Byte.E or byte == _Byte.e then
                    if e == 0 then e = 1 else break end
                elseif not noPeriod and e == 0 and byte == _Byte.PERIOD then
                    -- '.' only work before 'e'
                    noPeriod = true
                elseif e == 1 and (byte == _Byte.MINUS or byte == _Byte.PLUS) then
                    e           = 2
                else
                    break
                end
            end

            if pos <= cursorPos then
                newPos          = newPos + 1
            end

            pos                 = pos + 1
        end

        trueWord                = trueWord and trueWord .. str:sub(startPos, pos - 1)

        return pos, trueWord, newPos
    end

    local function nextComment(str, pos, cursorPos, trueWord, newPos)
        pos                     = pos or 1
        newPos                  = newPos or 0
        cursorPos               = cursorPos or 0

        local markLen           = 0
        local dblBrak           = false
        local startPos          = pos

        -- Skip the color part
        local npos, isv         = skipColor(str, pos)
        if npos ~= pos then
            trueWord            = trueWord and trueWord .. str:sub(startPos, pos - 1)
            pos                 = npos
            startPos            = pos
        end

        local byte              = strbyte(str, pos)

        if byte == _Byte.LEFTBRACKET then
            if pos <= cursorPos then
                newPos          = newPos + 1
            end

            pos                 = pos + 1

            while true do
                npos, isv       = skipColor(str, pos)
                if npos ~= pos then
                    trueWord    = trueWord and trueWord .. str:sub(startPos, pos - 1)
                    pos         = npos
                    startPos    = pos
                end

                byte            = strbyte(str, pos)

                if not byte then
                    break
                elseif byte == _Byte.EQUALS then
                    markLen     = markLen + 1
                elseif byte == _Byte.LEFTBRACKET then
                    dblBrak     = true
                else
                    break
                end

                if pos <= cursorPos then
                    newPos      = newPos + 1
                end

                pos             = pos + 1
                if dblBrak then break end
            end
        end

        if dblBrak then
            --[==[...]==]
            while true do
                npos, isv       = skipColor(str, pos)
                if npos ~= pos then
                    trueWord    = trueWord and trueWord .. str:sub(startPos, pos - 1)
                    pos         = npos
                    startPos    = pos
                end

                byte            = strbyte(str, pos)

                if not byte then
                    break
                elseif byte == _Byte.RIGHTBRACKET then
                    local len   = 0

                    if pos <= cursorPos then
                        newPos  = newPos + 1
                    end

                    pos         = pos + 1

                    while true do
                        npos, isv       = skipColor(str, pos)
                        if npos ~= pos then
                            trueWord    = trueWord and trueWord .. str:sub(startPos, pos - 1)
                            pos         = npos
                            startPos    = pos
                        end

                        byte    = strbyte(str, pos)

                        if byte == _Byte.EQUALS then
                            len = len + 1
                        else
                            break
                        end

                        if pos <= cursorPos then
                            newPos      = newPos + 1
                        end

                        pos     = pos + 1
                    end

                    if not byte then
                        break
                    elseif len == markLen and byte == _Byte.RIGHTBRACKET then
                        if pos <= cursorPos then
                            newPos      = newPos + 1
                        end

                        pos     = pos + 1
                        break
                    end
                end

                if pos <= cursorPos then
                    newPos      = newPos + (isv and 2 or 1)
                end

                pos             = pos + (isv and 2 or 1)
            end
        else
            --...
            while true do
                npos, isv       = skipColor(str, pos)
                if npos ~= pos then
                    trueWord    = trueWord and trueWord .. str:sub(startPos, pos - 1)
                    pos         = npos
                    startPos    = pos
                end

                byte            = strbyte(str, pos)

                if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                    break
                end

                if pos <= cursorPos then
                    newPos      = newPos + (isv and 2 or 1)
                end

                pos             = pos + (isv and 2 or 1)
            end
        end

        trueWord                = trueWord and trueWord .. str:sub(startPos, pos - 1)

        return pos, trueWord, newPos
    end

    local function nextString(str, pos, mark, cursorPos, trueWord, newPos)
        pos                     = pos or 1
        cursorPos               = cursorPos or 0
        newPos                  = newPos or 0

        local preEscape         = false
        local startPos          = pos

        if pos <= cursorPos then
            newPos              = newPos + 1
        end

        pos                     = pos + 1

        while true do
            local npos, isv     = skipColor(str, pos)
            if npos ~= pos then
                trueWord        = trueWord and trueWord .. str:sub(startPos, pos - 1)
                pos             = npos
                startPos        = pos
            end

            local byte          = strbyte(str, pos)

            if not byte or byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                break
            end

            if not preEscape and byte == mark then
                if pos <= cursorPos then
                    newPos      = newPos + 1
                end

                pos             = pos + 1
                break
            end

            if byte == _Byte.BACKSLASH then
                preEscape       = not preEscape
            else
                preEscape       = false
            end

            if pos <= cursorPos then
                newPos          = newPos + (isv and 2 or 1)
            end

            pos                 = pos + (isv and 2 or 1)
        end

        trueWord                = trueWord and trueWord .. str:sub(startPos, pos - 1)

        return pos, trueWord, newPos
    end

    local function nextIdentifier(str, pos, cursorPos, trueWord, newPos)
        pos                     = pos or 1
        cursorPos               = cursorPos or 0
        newPos                  = newPos or 0

        local startPos          = pos

        if pos <= cursorPos then
            newPos              = newPos + 1
        end

        pos                     = pos + 1

        while true do
            local npos, isv     = skipColor(str, pos)
            if npos ~= pos then
                trueWord        = trueWord and trueWord .. str:sub(startPos, pos - 1)
                pos             = npos
                startPos        = pos
            end

            local byte          = strbyte(str, pos)

            if not byte then
                break
            elseif byte == _Byte.SPACE or byte == _Byte.TAB then
                break
            elseif _Special[byte] then
                break
            end

            if pos <= cursorPos then
                newPos          = newPos + 1
            end

            pos                 = pos + (isv and 2 or 1)
        end

        trueWord                = trueWord and trueWord .. str:sub(startPos, pos - 1)

        return pos, trueWord, newPos
    end

    local function nextToken(str, pos, cursorPos, needTrueWord)
        pos                     = pos or 1
        cursorPos               = cursorPos or 0

        if not str then return nil, pos end

        local byte              = strbyte(str, pos)
        local start             = pos

        if not byte then return nil, pos end

        -- Space
        if byte == _Byte.SPACE or byte == _Byte.TAB then
            while true do
                pos             = pos + 1
                byte            = strbyte(str, pos)

                if not byte or (byte ~= _Byte.SPACE and byte ~= _Byte.TAB) then
                    return _Token.SPACE, pos, needTrueWord and str:sub(start, pos - 1)
                end
            end
        end

        -- Special character
        if _Special[byte] then
            if _Special[byte] >= 0 then
                return _Special[byte], pos + 1, needTrueWord and str:sub(start, pos)
            elseif _Special[byte] == -1 then
                if byte == _Byte.VERTICAL then
                    -- '|'
                    pos         = pos + 1
                    byte        = strbyte(str, pos)

                    if byte == _Byte.c then
                        --[[for i = pos + 1, pos + 8 do
                            byte = strbyte(str, i)

                            if i <= pos + 2 then
                                if byte ~= _Byte.f then
                                    return _Token.UNKNOWN, pos
                                end
                            else
                                if not ( ( byte >= _Byte.ZERO and byte <= _Byte.NINE ) or ( byte >= _Byte.a and byte <= _Byte.f ) ) then
                                    return  _Token.UNKNOWN, pos
                                end
                            end
                        end--]]

                        -- mark as '|cff20ff20'
                        return _Token.COLORCODE_START, pos + 9, ""
                    elseif byte == _Byte.r then
                        -- mark '|r'
                        return _Token.COLORCODE_END, pos + 1, ""
                    elseif byte == _Byte.VERTICAL then
                        return _Token.VERTICAL, pos + 1
                    else
                        -- don't know
                        return _Token.UNKNOWN, pos
                    end
                elseif byte == _Byte.MINUS then
                    -- '-'
                    pos         = skipColor(str, pos + 1)
                    byte        = strbyte(str, pos)

                    if byte == _Byte.MINUS then
                        -- '--'
                        return _Token.COMMENT, nextComment(str, pos + 1, cursorPos, needTrueWord and "--", 2)
                    else
                        -- '-'
                        return _Token.OPERATOR, pos, "-", 1
                    end
                elseif byte == _Byte.SINGLE_QUOTE or byte == _Byte.DOUBLE_QUOTE then
                    -- ' || "
                    return _Token.STRING, nextString(str, pos, byte, cursorPos, needTrueWord and "")
                elseif byte == _Byte.LEFTBRACKET then
                    local chkPos  = pos
                    local dblBrak = false

                    -- '['
                    pos         = pos + 1

                    while true do
                        pos     = skipColor(str, pos)
                        byte    = strbyte(str, pos)

                        if not byte then
                            break
                        elseif byte == _Byte.EQUALS then
                        elseif byte == _Byte.LEFTBRACKET then
                            dblBrak = true
                            break
                        else
                            break
                        end

                        pos     = pos + 1
                    end

                    if dblBrak then
                        return _Token.STRING, nextComment(str, chkPos, cursorPos, needTrueWord and "")
                    else
                        return _Token.LEFTBRACKET, chkPos + 1, "[", 1
                    end
                elseif byte == _Byte.EQUALS then
                    -- '='
                    pos         = skipColor(str, pos + 1)
                    byte        = strbyte(str, pos)

                    if byte == _Byte.EQUALS then
                        return _Token.EQUALITY, pos + 1, "==", 2
                    else
                        return _Token.ASSIGNMENT, pos, "=", 1
                    end
                elseif byte == _Byte.PERIOD then
                    -- '.'
                    pos         = skipColor(str, pos + 1)
                    byte        = strbyte(str, pos)

                    if not byte then
                        return _Token.PERIOD, pos, ".", 1
                    elseif byte == _Byte.PERIOD then
                        pos     = skipColor(str, pos + 1)
                        byte    = strbyte(str, pos)

                        if byte == _Byte.PERIOD then
                            return _Token.TRIPLEPERIOD, pos + 1, "...", 3
                        else
                            return _Token.DOUBLEPERIOD, pos, "..", 2
                        end
                    elseif byte >= _Byte.ZERO and byte <= _Byte.NINE then
                        return _Token.NUMBER, nextNumber(str, pos, true, cursorPos, needTrueWord and ".", 1)
                    else
                        return _Token.PERIOD, pos, ".", 1
                    end
                elseif byte == _Byte.LESSTHAN then
                    -- '<'
                    pos         = skipColor(str, pos + 1)
                    byte        = strbyte(str, pos)

                    if byte == _Byte.EQUALS then
                        return _Token.LTE, pos + 1, "<=", 2
                    else
                        return _Token.LT, pos, "<", 1
                    end
                elseif byte == _Byte.GREATERTHAN then
                    -- '>'
                    pos         = skipColor(str, pos + 1)
                    byte        = strbyte(str, pos)

                    if byte == _Byte.EQUALS then
                        return _Token.GTE, pos + 1, ">=", 2
                    else
                        return _Token.GT, pos, ">", 1
                    end
                elseif byte == _Byte.TILDE then
                    -- '~'
                    pos         = skipColor(str, pos + 1)
                    byte        = strbyte(str, pos)

                    if byte == _Byte.EQUALS then
                        return _Token.NOTEQUAL, pos + 1, "~=", 2
                    else
                        return _Token.TILDE, pos, "~", 1
                    end
                else
                    return _Token.UNKNOWN, pos
                end
            end
        end

        -- Number
        if byte >= _Byte.ZERO and byte <= _Byte.NINE then
            return _Token.NUMBER, nextNumber(str, pos, nil, cursorPos, needTrueWord and "")
        end

        -- Identifier
        return _Token.IDENTIFIER, nextIdentifier(str, pos, cursorPos, needTrueWord and "")
    end

    -- Color
    local function formatColor(self, str, cursorPos)
        local pos               = 1

        local token
        local content           = {}
        local cindex            = 0
        local nextPos
        local trueWord
        local word
        local newPos

        local owner             = self.__Owner
        local defaultColor      = tostring(owner.DefaultColor)
        local commentColor      = tostring(owner.CommentColor)
        local stringColor       = tostring(owner.StringColor)
        local numberColor       = tostring(owner.NumberColor)
        local instructionColor  = tostring(owner.InstructionColor)
        local functionColor     = tostring(owner.FunctionColor)
        local attrcolor         = tostring(owner.AttributeColor)

        cursorPos               = cursorPos or 0

        local chkLength         = 0
        local newCurPos         = 0
        local prevIdentifier

        local skipNextColorEnd  = false

        while true do
            token, nextPos, trueWord, newPos = nextToken(str, pos, cursorPos, true)
            if not token then break end

            word                = trueWord or str:sub(pos, nextPos - 1)
            newPos              = newPos   or word:len()
            cindex              = cindex + 1

            if token == _Token.COLORCODE_START or token == _Token.COLORCODE_END then
                -- clear prev colorcode
                content[cindex] = ""
            elseif token == _Token.IDENTIFIER then
                if _KeyWord[word] then
                    prevIdentifier  = nil
                    content[cindex] = instructionColor .. word .. _EndColor
                else
                    prevIdentifier  = cindex
                    content[cindex] = defaultColor .. word .. _EndColor
                end
            elseif token == _Token.NUMBER then
                prevIdentifier  = nil
                content[cindex] = numberColor .. word .. _EndColor
            elseif token == _Token.STRING then
                prevIdentifier  = nil
                content[cindex] = stringColor .. word .. _EndColor
            elseif token == _Token.COMMENT then
                prevIdentifier  = nil
                content[cindex] = commentColor .. word .. _EndColor
            else
                content[cindex] = word
                if token == _Token.SPACE or token == _Token.LEFTPAREN then
                    if prevIdentifier and token == _Token.LEFTPAREN then
                        -- Replace the function call's color
                        local c = content[prevIdentifier]:sub(#defaultColor + 1, -3)
                        if c:match("^__.*__$") then
                            content[prevIdentifier] = attrcolor .. c .. _EndColor
                        else
                            content[prevIdentifier] = functionColor .. c .. _EndColor
                        end
                        prevIdentifier = nil
                    end
                else
                    prevIdentifier = nil
                end
            end

            -- Check cursor position
            if chkLength < cursorPos then
                chkLength       = chkLength + nextPos - pos

                if chkLength >= cursorPos then
                    if content[cindex]:len() > 0 and strbyte(content[cindex], 1) == _Byte.VERTICAL and strbyte(content[cindex], 2) ~= _Byte.VERTICAL then
                        if chkLength == cursorPos then
                            newCurPos = newCurPos + newPos + 12
                        else
                            newCurPos = newCurPos + newPos + 10
                        end
                    elseif token == _Token.COLORCODE_END then
                        -- skip
                    else
                        newCurPos     = newCurPos + newPos
                    end
                else
                    newCurPos   = newCurPos + content[cindex]:len()
                end
            end

            pos                 = nextPos
        end

        return tblconcat(content), newCurPos
    end

    -- Indent
    local function formatIndent(self, str, cursorPos)
        local pos               = 1

        local token
        local content           = {}
        local cindex            = 0
        local indent            = 0
        local nextPos
        local word
        local rightSpace        = false
        local index
        local prevIndent        = 0
        local startIndent       = 0
        local prevToken
        local trueWord
        local oposQueue         = cursorPos and Queue()

        local tab               = self.__Owner.TabWidth

        while true do
            prevToken           = token
            token, nextPos, trueWord, newPos = nextToken(str, pos, cursorPos, true)
            if not token then break end

            word                = str:sub(pos, nextPos - 1)
            trueWord            = trueWord or word

            if cursorPos then oposQueue:Enqueue(pos, nextPos - 1) end

            -- Format Indent
            if token == _Token.LEFTWING then
                indent          = indent + 1
                startIndent     = startIndent + 1

                cindex          = cindex + 1
                content[cindex] = word
                if cursorPos then oposQueue:Enqueue(cindex) end

                rightSpace      = false
            elseif token == _Token.RIGHTWING then
                indent          = indent - 1
                if startIndent > 0 then
                    startIndent = startIndent - 1
                else
                    prevIndent  = prevIndent + 1
                end
                if content[cindex] == strrep(" ", tab * (indent+1)) then
                    content[cindex] = strrep(" ", tab * indent)
                end

                cindex          = cindex + 1
                content[cindex] = word
                if cursorPos then oposQueue:Enqueue(cindex) end

                rightSpace      = false
            elseif token == _Token.LINEBREAK then
                if rightSpace then
                    content[cindex] = content[cindex]:gsub("^(.-)%s*$", "%1")
                    if content[cindex] == "" then
                        content[cindex] = strrep(" ", tab * indent)
                    end
                end

                cindex          = cindex + 1
                content[cindex] = word
                if cursorPos then oposQueue:Enqueue(cindex) end

                cindex          = cindex + 1
                content[cindex] = strrep(" ", tab * indent)
                rightSpace      = true
            elseif token == _Token.SPACE then
                if not rightSpace then
                    cindex      = cindex + 1
                    content[cindex] = " "
                    if cursorPos then oposQueue:Enqueue(cindex) end
                else
                    if cursorPos then oposQueue:Enqueue(0) end
                end
                rightSpace      = true
            elseif token == _Token.IDENTIFIER then
                if _KeyWord[trueWord] then
                    if _KeyWord[trueWord] == _IndentNone then
                        indent = indent
                    elseif _KeyWord[trueWord] == _IndentRight then
                        indent = indent + 1
                        startIndent = startIndent + 1
                    elseif _KeyWord[trueWord] == _IndentLeft then
                        indent = indent - 1
                        if startIndent > 0 then
                            startIndent = startIndent - 1
                        else
                            prevIndent = prevIndent + 1
                        end

                        if prevToken == _Token.COLORCODE_START then
                            index = cindex - 1
                        else
                            index = cindex
                        end

                        if content[index] == strrep(" ", tab * (indent+1)) then
                            content[index] = strrep(" ", tab * indent)
                        end
                    elseif _KeyWord[trueWord] == _IndentBoth then
                        indent = indent
                        if startIndent == 0 then
                            prevIndent = prevIndent + 1
                            startIndent = startIndent + 1
                        end

                        if prevToken == _Token.COLORCODE_START then
                            index = cindex - 1
                        else
                            index = cindex
                        end

                        if content[index] == strrep(" ", tab * indent) then
                            content[index] = strrep(" ", tab * (indent-1))
                        end
                    end

                    cindex      = cindex + 1
                    content[cindex] = word
                    if cursorPos then oposQueue:Enqueue(cindex) end
                else
                    cindex      = cindex + 1
                    content[cindex] = word
                    if cursorPos then oposQueue:Enqueue(cindex) end

                    if not self._IdentifierCache[word] then
                        self._IdentifierCache[word] = true
                        self.__Owner:InsertAutoCompleteWord(word)
                    end
                end
                rightSpace      = false
            elseif _WordWrap[token] == _IndentNone then
                cindex          = cindex + 1
                content[cindex] = word
                if cursorPos then oposQueue:Enqueue(cindex) end

                rightSpace      = false
            elseif _WordWrap[token] == _IndentRight then
                cindex          = cindex + 1
                content[cindex] = word .. " "
                if cursorPos then oposQueue:Enqueue(cindex) end

                rightSpace      = true
            elseif _WordWrap[token] == _IndentLeft then
                if rightSpace then
                    cindex      = cindex + 1
                    content[cindex] = word
                else
                    cindex      = cindex + 1
                    content[cindex] = " " .. word
                end
                if cursorPos then oposQueue:Enqueue(cindex) end

                rightSpace      = false
            elseif _WordWrap[token] == _IndentBoth then
                if rightSpace then
                    cindex      = cindex + 1
                    content[cindex] = word .. " "
                else
                    cindex      = cindex + 1
                    content[cindex] = " " .. word .. " "
                end
                if cursorPos then oposQueue:Enqueue(cindex) end

                rightSpace      = true
            else
                cindex          = cindex + 1
                content[cindex] = word
                if cursorPos then oposQueue:Enqueue(cindex) end

                rightSpace      = false
            end

            pos                 = nextPos
        end

        -- Get the new cursor pos
        pos                     = 0
        local previdx           = 0
        while cursorPos do
            local s, e, idx     = oposQueue:Dequeue(3)

            if not s then
                -- Meet the last position
                cursorPos       = pos
                break
            end

            if e <= cursorPos then
                while previdx < idx do
                    previdx     = previdx + 1
                    pos         = pos + #content[previdx]
                end
            else
                if idx > 0 then
                    pos         = pos + cursorPos - s + 1
                end

                cursorPos       = pos
                break
            end
        end

        return tblconcat(content), indent, prevIndent, cursorPos
    end

    local function formatColor4Line(self, startp, endp)
        local cursorPos         = self:GetCursorPosition()
        local text              = self:GetText()
        local byte
        local line

        local owner             = self.__Owner
        local commentColor      = tostring(owner.CommentColor)
        local stringColor       = tostring(owner.StringColor)

        startp                  = startp or cursorPos
        endp                    = endp or cursorPos

        -- Color the line
        startp, endp            = getLines(text, startp, endp)

        -- check prev comment
        local preColorPos       = startp - 1
        local token, nextPos

        while preColorPos > 0 do
            byte                = strbyte(text, preColorPos)

            if byte == _Byte.VERTICAL and strbyte(text, preColorPos - 1) ~= _Byte.VERTICAL then
                -- '|'
                byte            = strbyte(text, preColorPos + 1)

                if byte == _Byte.c then
                    if commentColor == text:sub(preColorPos, preColorPos + 9) or stringColor == text:sub(preColorPos, preColorPos + 9) then
                        -- check multi-lines comment or string
                        token, nextPos = nextToken(text, preColorPos + 10)

                        if token == _Token.COMMENT or token == _Token.STRING then
                            if nextPos < startp and nextPos < endp then
                                break   -- no need to think about prev multi-lines comment and string
                            end

                            while token and (nextPos <= endp or nextPos <= startp) do
                                token, nextPos = nextToken(text, nextPos)
                            end

                            byte = strbyte(text, nextPos)

                            if not byte or (nextPos - 1 > endp and nextPos - 1 > startp) then
                                line, cursorPos = formatColor(self, text:sub(preColorPos, nextPos - 1), cursorPos - preColorPos + 1)

                                self:SetText(replaceBlock(text, preColorPos, nextPos - 1, line))

                                cursorPos = preColorPos + cursorPos - 1

                                return SetCursorPosition(self, cursorPos)
                            end

                            token, nextPos = nextToken(text, nextPos)

                            while token do
                                if token == _Token.COLORCODE_START or token == _Token.COLORCODE_END then
                                    line, cursorPos = formatColor(self, text:sub(preColorPos, endp), cursorPos - preColorPos + 1)

                                    self:SetText(replaceBlock(text, preColorPos, endp, line))

                                    cursorPos = preColorPos + cursorPos - 1

                                    return SetCursorPosition(self, cursorPos)
                                elseif token == _Token.IDENTIFIER or token == _Token.NUMBER or token == _Token.STRING or token == _Token.COMMENT then
                                    while token and token ~= _Token.COLORCODE_END do
                                        token, nextPos = nextToken(text, nextPos)
                                    end

                                    line, cursorPos = formatColor(self, text:sub(preColorPos, nextPos - 1), cursorPos - preColorPos + 1)

                                    self:SetText(replaceBlock(text, preColorPos, nextPos - 1, line))

                                    cursorPos = preColorPos + cursorPos - 1

                                    return SetCursorPosition(self, cursorPos)
                                end

                                token, nextPos = nextToken(text, nextPos)
                            end
                        else
                            break
                        end
                    else
                        break
                    end
                end
            end

            preColorPos         = preColorPos - 1
        end

        nextPos                 = startp
        token, nextPos          = nextToken(text, nextPos)

        while token and (nextPos <= endp or nextPos <= startp) do
            token, nextPos      = nextToken(text, nextPos)
        end

        if nextPos - 1 > endp and nextPos - 1 > startp then
            line, cursorPos     = formatColor(self, text:sub(startp, nextPos - 1), cursorPos - startp + 1)

            self:SetText(replaceBlock(text, startp, nextPos - 1, line))

            return SetCursorPosition(self, startp + cursorPos - 1)
        end

        while true do
            if not token then
                line, cursorPos = formatColor(self, text:sub(startp, endp), cursorPos - startp + 1)

                self:SetText(replaceBlock(text, startp, endp, line))

                return SetCursorPosition(self, startp + cursorPos - 1)
            elseif token == _Token.COLORCODE_START or token == _Token.COLORCODE_END then
                line, cursorPos = formatColor(self, text:sub(startp, endp), cursorPos - startp + 1)

                self:SetText(replaceBlock(text, startp, endp, line))

                return SetCursorPosition(self, startp + cursorPos - 1)
            elseif token == _Token.IDENTIFIER or token == _Token.NUMBER or token == _Token.STRING or token == _Token.COMMENT then
                while token and token ~= _Token.COLORCODE_END do
                    token, nextPos = nextToken(text, nextPos)
                end

                line, cursorPos = formatColor(self, text:sub(startp, nextPos - 1), cursorPos - startp + 1)

                self:SetText(replaceBlock(text, startp, nextPos - 1, line))

                return SetCursorPosition(self, startp + cursorPos - 1)
            end

            token, nextPos      = nextToken(text, nextPos)
        end
    end

    local function formatAll(self, str)
        local owner             = self.__Owner
        local pos               = 1
        local tab               = owner.TabWidth

        local token
        local content           = {}
        local cindex            = 0
        local nextPos
        local trueWord
        local word

        local defaultColor      = tostring(owner.DefaultColor)
        local commentColor      = tostring(owner.CommentColor)
        local stringColor       = tostring(owner.StringColor)
        local numberColor       = tostring(owner.NumberColor)
        local instructionColor  = tostring(owner.InstructionColor)
        local functionColor     = tostring(owner.FunctionColor)
        local attrcolor         = tostring(owner.AttributeColor)

        local indent            = 0
        local rightSpace        = false
        local index
        local prevIndent        = 0
        local startIndent       = 0
        local prevToken
        local prevIdentifier

        while true do
            prevToken           = token
            token, nextPos, trueWord = nextToken(str, pos, nil, true)
            if not token then break end

            word                = trueWord or str:sub(pos, nextPos - 1)

            if token == _Token.COLORCODE_START or token == _Token.COLORCODE_END then
                -- clear prev colorcode
                cindex          = cindex + 1
                content[cindex] = ""
            elseif token == _Token.LEFTWING then
                indent          = indent + 1
                startIndent     = startIndent + 1
                cindex          = cindex + 1
                content[cindex] = word
                rightSpace      = false
                prevIdentifier  = nil
            elseif token == _Token.RIGHTWING then
                indent          = indent - 1
                if startIndent > 0 then
                    startIndent = startIndent - 1
                else
                    prevIndent  = prevIndent + 1
                end
                if content[cindex] == strrep(" ", tab * (indent+1)) then
                    content[cindex] = strrep(" ", tab * indent)
                end
                cindex          = cindex + 1
                content[cindex] = word
                rightSpace      = false
                prevIdentifier  = nil
            elseif token == _Token.LINEBREAK then
                if rightSpace then
                    content[cindex] = content[cindex]:gsub("^(.-)%s*$", "%1")
                    if content[cindex] == "" then
                        content[cindex] = strrep(" ", tab * indent)
                    end
                end
                cindex          = cindex + 1
                content[cindex] = word
                cindex          = cindex + 1
                content[cindex] = strrep(" ", tab * indent)
                rightSpace      = true
                prevIdentifier  = nil
            elseif token == _Token.SPACE then
                if not rightSpace then
                    cindex      = cindex + 1
                    content[cindex] = " "
                end
                rightSpace      = true
            elseif token == _Token.IDENTIFIER then
                if _KeyWord[word] then
                    if _KeyWord[word] == _IndentNone then
                        indent  = indent
                    elseif _KeyWord[word] == _IndentRight then
                        indent  = indent + 1
                        startIndent = startIndent + 1
                    elseif _KeyWord[word] == _IndentLeft then
                        indent  = indent - 1
                        if startIndent > 0 then
                            startIndent = startIndent - 1
                        else
                            prevIndent = prevIndent + 1
                        end

                        if prevToken == _Token.COLORCODE_START then
                            index = cindex - 1
                        else
                            index = cindex
                        end

                        if content[index] == strrep(" ", tab * (indent+1)) then
                            content[index] = strrep(" ", tab * indent)
                        end
                    elseif _KeyWord[word] == _IndentBoth then
                        indent  = indent
                        if startIndent == 0 then
                            prevIndent = prevIndent + 1
                            startIndent = startIndent + 1
                        end

                        if prevToken == _Token.COLORCODE_START then
                            index = cindex - 1
                        else
                            index = cindex
                        end

                        if content[index] == strrep(" ", tab * indent) then
                            content[index] = strrep(" ", tab * (indent-1))
                        end
                    end
                    cindex      = cindex + 1
                    content[cindex] = instructionColor .. word .. _EndColor
                    prevIdentifier  = nil
                else
                    cindex      = cindex + 1
                    content[cindex] = defaultColor .. word .. _EndColor
                    prevIdentifier  = cindex

                    word        = removeColor(word)
                    if not self._IdentifierCache[word] then
                        self._IdentifierCache[word] = true
                        owner:InsertAutoCompleteWord(word)
                    end
                end
                rightSpace      = false
            else
                if prevIdentifier and token == _Token.LEFTPAREN then
                    -- Replace the function call's color
                    local c     = content[prevIdentifier]:sub(#defaultColor + 1, -3)
                    if c:match("^__.*__$") then
                        content[prevIdentifier] = attrcolor .. c .. _EndColor
                    else
                        content[prevIdentifier] = functionColor .. c .. _EndColor
                    end
                    prevIdentifier = nil
                else
                    prevIdentifier = nil
                end

                if token == _Token.NUMBER then
                    cindex      = cindex + 1
                    content[cindex] = numberColor .. word .. _EndColor
                elseif token == _Token.STRING then
                    cindex      = cindex + 1
                    content[cindex] = stringColor .. word .. _EndColor
                elseif token == _Token.COMMENT then
                    cindex      = cindex + 1
                    content[cindex] = commentColor .. word .. _EndColor
                else
                    cindex      = cindex + 1
                    content[cindex] = word
                end

                if _WordWrap[token] == _IndentNone then
                    rightSpace = false
                elseif _WordWrap[token] == _IndentRight then
                    content[#content] = content[#content] .. " "
                    rightSpace = true
                elseif _WordWrap[token] == _IndentLeft then
                    if not rightSpace then
                        content[#content] = " " .. content[#content]
                    end
                    rightSpace = false
                elseif _WordWrap[token] == _IndentBoth then
                    if rightSpace then
                        content[cindex] = content[cindex] .. " "
                    else
                        content[cindex] = " " .. content[cindex] .. " "
                    end
                    rightSpace  = true
                else
                    rightSpace  = false
                end
            end

            pos                 = nextPos
        end

        return tblconcat(content)
    end

    local function refreshText(self)
        self:SetText(self:GetText())
    end

    local function moveOnList(self, offset, key)
        local min, max          = 1, _List.ItemCount
        local index             = _List.SelectedIndex

        local first             = true
        self:SetAltArrowKeyMode(true)

        repeat
            index               = index + offset
            if index >= min and index <= max then
                _List.SelectedIndex = index
                _List:RefreshScrollView()
            else
                break
            end

            Delay(first and 0.3 or 0.1)
            first               = false
        until not isKeyPressed(self, key)

        self:SetAltArrowKeyMode(false)
    end

    function _List:OnItemClick(key)
        local editor            = _List.CurrentEditor
        if not editor then return _List:Hide() end

        local ct                = editor:GetText()
        local startp, endp      = getWord(ct, editor:GetCursorPosition(), true)

        wipe(_BackAutoCache)

        if key then
            for _, v in ipairs(_AutoCacheItems) do
                tinsert(_BackAutoCache, v.checkvalue)
            end

            _BackAutoCache[0]   = _List.SelectedIndex

            _List:Hide()

            editor:SetText(replaceBlock(ct, startp, endp, key))

            SetCursorPosition(editor.__Owner, startp + key:len() - 1)

            formatColor4Line(editor, startp, startp + key:len() - 1)
        else
            _List:Hide()
        end
    end

    ------------------------------------------------------
    -- Key Scan Helper
    ------------------------------------------------------
    local function saveOperation(self, isundo)
        if not self._OperationOnLine then return end

        -- check change
        if self:GetText() ~= self._OperationBackUpOnLine then
            self._OperationStack:Push(self._OperationOnLine, self._OperationBackUpOnLine, self._OperationStartOnLine, self._OperationEndOnLine)

            if isundo then
                self._OperationStack:Push(_Operation.UNDO_SAVE, self:GetText(), self._HighlightStart, self._HighlightEnd)
            end
        end

        self._OperationOnLine           = nil
        self._OperationBackUpOnLine     = nil
        self._OperationStartOnLine      = nil
        self._OperationEndOnLine        = nil
    end

    local function newOperation(self, oper)
        if self._OperationOnLine == oper then return end

        -- save last operation
        saveOperation(self)

        self._OperationOnLine       = oper

        self._OperationBackUpOnLine = self:GetText()
        self._OperationStartOnLine  = self._HighlightStart
        self._OperationEndOnLine    = self._HighlightEnd
    end

    local function undo(self)
        saveOperation(self, true)

        local oper, text, start, stop = self._OperationStack:Undo()
        if oper then
            self:SetText(text)
            SetCursorPosition(self.__Owner, stop)
            HighlightText(self.__Owner, start, stop)
        end
    end

    local function redo(self)
        local oper, text, start, stop = self._OperationStack:Redo()
        if oper then
            self:SetText(text)
            SetCursorPosition(self.__Owner, stop)
            HighlightText(self.__Owner, start, stop)
        end
    end

    local function asyncDelete(self)
        local first             = true
        local str               = self:GetText()
        local nextPos, isv
        local pos               = self:GetCursorPosition() + 1

        while self._DELETE do

            if first and self._HighlightStart ~= self._HighlightEnd then
                pos             = self._HighlightStart + 1
                nextPos         = self._HighlightEnd
            else
                nextPos         = pos

                -- yap, I should do this myself
                if IsControlKeyDown() then
                    -- delete words
                    local s, e  = getWord(str, nextPos, nil, true)
                    nextPos     = e or pos
                else
                    -- delete char
                    nextPos, isv= skipColor(str, nextPos)
                    if isv then
                        nextPos = nextPos + 1
                    else
                        nextPos = checkUTF8(str, nextPos)
                    end
                end
            end

            if pos > str:len() then break end

            str                 = replaceBlock(str, pos, nextPos, "")

            self:SetText(str)

            SetCursorPosition(self.__Owner, pos - 1)

            -- Do for long press
            if first then
                Delay(_FIRST_WAITTIME)
                first           = false
            else
                Delay(_CONTINUE_WAITTIME)
            end
        end

        return formatColor4Line(self)
    end

    local function asyncBackdpace(self)
        local first             = true
        local str               = self:GetText()
        local prevPos
        local pos               = self:GetCursorPosition()
        local isDelteLine       = false

        while self._BACKSPACE do
            if pos == 0 then break end

            if first and self._HighlightStart ~= self._HighlightEnd then
                pos             = self._HighlightEnd
                prevPos         = self._HighlightStart + 1
            else
                prevPos         = pos

                -- yap, I should do this myself
                if IsControlKeyDown() then
                    local s, e  = getWord(str, prevPos, true)
                    prevPos     = s or pos
                else
                    prevPos     = checkPrevUTF8(str, skipPrevColor(str, prevPos))

                    -- Auto pairs check
                    local byte  = strbyte(str, prevPos)

                    if _AutoPairs[byte] then
                        local n = skipColor(str, pos + 1)
                        if _AutoPairs[byte] == true then
                            if strbyte(str, n) == byte then
                                pos = n
                            end
                        elseif strbyte(str, n) == _AutoPairs[byte] then
                            pos = n
                        end
                    elseif byte == _Byte.LINEBREAK_N or byte == _Byte.LINEBREAK_R then
                        isDelteLine = true
                    end
                end
            end

            -- Delete
            str                 = replaceBlock(str, prevPos, pos, "")

            self:SetText(str)

            pos                 = prevPos - 1
            SetCursorPosition(self.__Owner, pos)

            if isDelteLine then
                isDelteLine     = false
                updateLineNum(self.__Owner)
            end

            -- Do for long press
            if first then
                Delay(_FIRST_WAITTIME)
                first           = false
            else
                Delay(_CONTINUE_WAITTIME)
            end
        end

        applyAutoComplete(self)
        return Next(formatColor4Line, self)
    end

    local function formatAllIndent(self)
        -- format all codes for indent and keep the cursor position
        newOperation(self, _Operation.INDENTFORMAT)

        local str, _, _, cursor = formatIndent(self, self:GetText(), self:GetCursorPosition())
        self:SetText(str)
        SetCursorPosition(self.__Owner, cursor)
    end

    _KeyScan:SetScript("OnKeyDown", function (self, key)
        if not key or _SkipKey[key] then return end

        if self.FocusEditor then
            local editor        = self.FocusEditor
            local owner         = editor.__Owner
            local cursorPos     = editor:GetCursorPosition()

            local oper          = _KEY_OPER[key]

            if oper then
                local text      = editor:GetText()

                if oper == _Operation.CHANGE_CURSOR then
                    local handled = false --editor:Fire("OnDirectionKey", _DirectionKeyEventArgs)

                    if _List:IsShown() then
                        local offset = 0

                        handled = true

                        if key == "PAGEUP" then
                            offset = - _List.DisplayCount
                        elseif key == "PAGEDOWN" then
                            offset = _List.DisplayCount
                        elseif key == "HOME" then
                            offset = 1 - _List.SelectedIndex
                        elseif key == "END" then
                            offset = _List.ItemCount - _List.SelectedIndex
                        elseif key == "UP" then
                            offset = -1
                        elseif key == "DOWN" then
                            offset = 1
                        else
                            handled = false
                        end

                        if offset ~= 0 then
                            Continue(moveOnList, editor, offset, key)
                        end
                    end

                    if handled then
                        self.ActiveKeys[key] = true
                        return self:SetPropagateKeyboardInput(false)
                    end

                    if key == "PAGEUP" then
                        local bar           = owner:GetChild("ScrollBar")
                        local skipLine      = floor(owner:GetHeight() / bar:GetValueStep())
                        local startp, endp, line = getPrevLinesByReturn(text, cursorPos, skipLine)

                        if line == 0 then return end

                        endPrevKey(editor)
                        saveOperation(editor)

                        if IsShiftKeyDown() then
                            editor._SKIPCURCHG = cursorPos
                        end

                        editor:SetCursorPosition(getCursorPosByOffset(text, startp, getOffsetByCursorPos(text, cursorPos)))
                        return
                    elseif key == "PAGEDOWN" then
                        local bar           = owner:GetChild("ScrollBar")
                        local skipLine      = floor(owner:GetHeight() / bar:GetValueStep())
                        local startp, endp, line = getLinesByReturn(text, cursorPos, skipLine)

                        if line == 0 then return end

                        endPrevKey(editor)
                        saveOperation(editor)

                        if IsShiftKeyDown() then
                            editor._SKIPCURCHG = cursorPos
                        end

                        editor:SetCursorPosition(getCursorPosByOffset(text, endp, getOffsetByCursorPos(text, cursorPos)))
                        return
                    elseif key == "HOME" then
                        local startp, endp = getLines(text, cursorPos)
                        local byte

                        if startp - 1 == cursorPos then return end

                        endPrevKey(editor)
                        saveOperation(editor)

                        if IsShiftKeyDown() then
                            editor._SKIPCURCHG = cursorPos
                        end

                        local byte          = strbyte(text, startp)
                        while _Spaces[byte] do
                            startp          = startp + 1
                            byte            = strbyte(text, startp)
                        end

                        if startp <= cursorPos then
                            self.ActiveKeys[key] = true
                            self:SetPropagateKeyboardInput(false)

                            editor:SetCursorPosition(startp - 1)
                        end
                        return
                    elseif key == "END" then
                        local startp, endp = getLines(editor:GetText(), cursorPos)

                        if endp == cursorPos then return end

                        endPrevKey(editor)
                        saveOperation(editor)

                        if IsShiftKeyDown() then
                            editor._SKIPCURCHG = cursorPos
                        end

                        return
                    elseif key == "UP" then
                        local _, _, line = getPrevLinesByReturn(editor:GetText(), cursorPos, 1)

                        if line > 0 then
                            endPrevKey(editor)
                            saveOperation(editor)

                            if IsShiftKeyDown() then
                                editor._SKIPCURCHG = cursorPos
                                editor._SKIPCURCHGARROW = true
                            end
                        end

                        return
                    elseif key == "DOWN" then
                        local text      = editor:GetText()
                        local _, _, line= getLinesByReturn(text, cursorPos, 2)

                        if line > 0 then
                            endPrevKey(editor)
                            saveOperation(editor)

                            if IsShiftKeyDown()  then
                                editor._SKIPCURCHG      = cursorPos
                                editor._SKIPCURCHGARROW = true
                            end

                            if line == 1 then
                                -- Check a special error
                                local startp, endp      = getLines(text, cursorPos)
                                local offset, isv       = 0

                                startp, isv             = skipColor(text, startp)

                                while startp <= cursorPos do
                                    offset              = offset + 1
                                    startp, isv         = skipColor(text, startp + (isv and 2 or 1))
                                end

                                editor._DownOffset      = offset
                            end
                        end

                        return
                    elseif key == "RIGHT" then
                        if cursorPos < text:len() then
                            endPrevKey(editor)
                            saveOperation(editor)

                            local skipCtrl = false

                            if IsShiftKeyDown() then
                                editor._SKIPCURCHG = cursorPos
                                editor._SKIPCURCHGARROW = true
                            elseif editor._HighlightStart ~= editor._HighlightEnd then
                                editor._SKIPCURCHG = nil
                                editor._SKIPCURCHGARROW = nil
                                skipCtrl    = true
                                self.ActiveKeys[key] = true
                                self:SetPropagateKeyboardInput(false)

                                SetCursorPosition(editor.__Owner, editor._HighlightEnd)
                            end

                            if not skipCtrl and IsControlKeyDown() then
                                local text  = editor:GetText()
                                local s, e  = getWord(text, cursorPos, nil, true)

                                if s and e then
                                    self.ActiveKeys[key] = true
                                    self:SetPropagateKeyboardInput(false)

                                    editor:SetCursorPosition(e)
                                end
                            end
                        end

                        return
                    elseif key == "LEFT" then
                        if cursorPos > 0 then
                            endPrevKey(editor)
                            saveOperation(editor)

                            local skipCtrl = false

                            if IsShiftKeyDown() then
                                editor._SKIPCURCHG = cursorPos
                                editor._SKIPCURCHGARROW = true
                            elseif editor._HighlightStart ~= editor._HighlightEnd then
                                editor._SKIPCURCHG = nil
                                editor._SKIPCURCHGARROW = nil
                                skipCtrl    = true
                                self.ActiveKeys[key] = true
                                self:SetPropagateKeyboardInput(false)

                                SetCursorPosition(editor.__Owner, editor._HighlightStart)
                            end

                            if not skipCtrl and IsControlKeyDown() then
                                local text  = editor:GetText()
                                local s, e  = getWord(text, cursorPos, true)

                                if s and e then
                                    self.ActiveKeys[key] = true
                                    self:SetPropagateKeyboardInput(false)

                                    editor:SetCursorPosition(s - 1)
                                end
                            end
                        end

                        return
                    end
                end

                if key == "TAB" then
                    endPrevKey(editor)
                    return newOperation(editor, _Operation.INPUTTAB)
                end

                if key == "DELETE" then
                    if not editor._DELETE and not IsShiftKeyDown() and (editor._HighlightStart ~= editor._HighlightEnd or cursorPos < text:len()) then
                        endPrevKey(editor)
                        editor._DELETE      = true
                        newOperation(editor, _Operation.DELETE)
                        self.ActiveKeys[key]= true
                        self:SetPropagateKeyboardInput(false)

                        return Continue(asyncDelete, editor)
                    end
                    return
                end

                if key == "BACKSPACE" then
                    if not editor._BACKSPACE and cursorPos > 0 then
                        endPrevKey(editor)
                        editor._BACKSPACE   = cursorPos
                        newOperation(editor, _Operation.BACKSPACE)
                        self.ActiveKeys[key]= true
                        self:SetPropagateKeyboardInput(false)

                        return Continue(asyncBackdpace, editor)
                    end
                    return
                end

                if key == "ENTER" then
                    endPrevKey(editor)
                    -- editor._SKIPCURCHG = true
                    return newOperation(editor, _Operation.ENTER)
                end
            end

            endPrevKey(editor)

            -- Don't consider multi-modified keys
            if IsShiftKeyDown() then
                -- shift+
                if IsControlKeyDown() then
                    self:SetPropagateKeyboardInput(false)

                    if key == "D" then
                        -- duplicate line
                        local text          = editor:GetText()
                        local startp, endp  = getLines(text, editor._HighlightStart, editor._HighlightEnd)
                        local line          = "\n" .. text:sub(startp, endp)

                        newOperation(editor, _Operation.DUPLICATE_LINE)
                        editor:SetText(replaceBlock(text, endp + 1, endp, line))
                        SetCursorPosition(editor.__Owner, endp + #line)

                        formatColor4Line(editor)
                        return saveOperation(editor)
                    elseif key == "K" then
                        -- Delete line
                        local text          = editor:GetText()
                        local startp, endp  = getLines(text, editor._HighlightStart, editor._HighlightEnd)

                        if startp and endp then
                            if startp == 1 and startp > endp then return end

                            newOperation(editor, _Operation.DELETE_LINE)
                            if endp >= startp then
                                -- Delete the current line
                                editor:SetText(replaceBlock(text, startp, endp + 1, ""))
                                SetCursorPosition(editor.__Owner, startp - 1)

                                formatColor4Line(editor)
                                return saveOperation(editor)
                            else
                                -- Delete the line break
                                editor:SetText(replaceBlock(text, startp - 1, startp - 1, ""))
                                SetCursorPosition(editor.__Owner, startp - 2)

                                formatColor4Line(editor)
                                return saveOperation(editor)
                            end
                        end
                    end

                    return
                end
            elseif IsAltKeyDown() then
                return OnAltKey(editor.__Owner, key)
            elseif IsControlKeyDown() then
                if key == "A" then
                    return owner:HighlightText()
                elseif key == "V" then
                    editor._InPasting = true
                    return newOperation(editor, _Operation.PASTE)
                elseif key == "C" then
                    -- do nothing
                    return
                elseif key == "Z" then
                    return undo(editor)
                elseif key == "Y" then
                    return redo(editor)
                elseif key == "X" then
                    if editor._HighlightStart ~= editor._HighlightEnd then
                        newOperation(editor, _Operation.CUT)
                    end
                    return
                elseif key == "K" then
                    -- Format the text
                    self.ActiveKeys[key]= true
                    self:SetPropagateKeyboardInput(false)
                    return formatAllIndent(editor)
                else
                    return OnControlKey(editor.__Owner, key)
                end
            elseif key:find("^F%d+") == 1 then
                return OnFunctionKey(editor.__Owner, key)
            end

            return newOperation(editor, _Operation.INPUTCHAR)
        end
    end)

    _KeyScan:SetScript("OnKeyUp", function (self, key)
        self:SetPropagateKeyboardInput(true)

        self.ActiveKeys[key] = nil

        if self.FocusEditor then
            if key == "DELETE" then
                self.FocusEditor._DELETE = nil
            end
            if key == "BACKSPACE" then
                self.FocusEditor._BACKSPACE = nil
            end
        end
    end)

    ------------------------------------------------------
    -- event
    ------------------------------------------------------
    --- Fired when alt + key is pressed
    event "OnAltKey"

    --- Fired when ctrl + key is pressed
    event "OnControlKey"

    --- Fired when function key is pressed
    event "OnFunctionKey"

    --- Fired when the enter is pressed(only works when the multiline is turn off)
    event "OnEnterPressed"

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    --- Refresh the editor layout
    __AsyncSingle__()
    function RefreshLayout(self)
        Next()

        local editor            = self.__Editor
        local linenum           = self.__LineNum

        local font, height, flag= editor:GetFont()
        local spacing           = editor:GetSpacing()

        while not font do
            Next()
            font, height, flag  = editor:GetFont()
            spacing             = editor:GetSpacing()
        end

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

        editor._HighlightStart  = startp
        editor._HighlightEnd    = endp

        if startp ~= endp then
            text                = text or editor:GetText()
            editor._HighlightText   = text:sub(startp + 1, endp)
        else
            editor._HighlightText   = ""
        end

        return editor:HighlightText(startp, endp)
    end

    --- Set the cursor position
    function SetCursorPosition(self, pos)
        local editor            = self.__Editor or self
        editor._OldCursorPosition = pos
        editor:SetCursorPosition(pos)
        return editor.__Owner:HighlightText(pos, pos)
    end

    --- Set The Text
    function SetText(self, text)
        text                    = text and tostring(text) or ""
        self                    = self.__Editor

        initDefinition(self)

        self:SetText(formatAll(self, text:gsub("\124", "\124\124")))
        SetCursorPosition(self, 0)

        newOperation(self, _Operation.INIT)
    end

    --- Get the text
    function GetText(self)
        return removeColor(self.__Editor:GetText() or ""):gsub("\124\124", "\124")
    end

    --- Clear the auto complete list
    function ClearAutoCompleteList(self)
        wipe(self.AutoCompleteList)
    end

    --- Insert word to the auto complete list
    function InsertAutoCompleteWord(self, word)
        if type(word) == "string" and strtrim(word) ~= "" then
            word                = strtrim(word)
            word                = removeColor(word)

            local lst           = self.AutoCompleteList
            local idx           = getIndex(lst, word)

            if lst[idx] == word then return end

            tinsert(lst, idx + 1, word)
        end
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The tab width, default 4
    property "TabWidth"         { type = NaturalNumber, default = 4, handler = refreshText }

    --- Whether show the line num
    property "ShowLineNum"      { type = Bool, default = true, handler = function(self, flag) Style[self].ScrollChild.LineNum.visible = flag; Style[self].LineHolder.visible = flag; self:RefreshLayout() end }

    --- The default text color
    property "DefaultColor"     { type = ColorType, handler = refreshText, default = Color(1, 1, 1) }

    --- The comment color
    property "CommentColor"     { type = ColorType, handler = refreshText, default = Color(0.5, 0.5, 0.5) }

    --- The string color
    property "StringColor"      { type = ColorType, handler = refreshText, default = Color(0, 1, 0) }

    --- The number color
    property "NumberColor"      { type = ColorType, handler = refreshText, default = Color(1, 1, 0) }

    --- The instruction color
    property "InstructionColor" { type = ColorType, handler = refreshText, default = Color(1, 0.39, 0.09) }

    --- The function
    property "FunctionColor"    { type = ColorType, handler = refreshText, default = Color(0.33, 1, 0.9) }

    --- The attribute color
    property "AttributeColor"   { type = ColorType, handler = refreshText, default = Color(0.52, 0.12, 0.47) }

    --- The custom auto complete list
    property "AutoCompleteList" { type = System.Collections.List, default = function() return System.Collections.List() end,    handler = function(self, value) return value and value:QuickSort(compare) end }

    --- The delay to show the auto complete
    property "AutoCompleteDelay"{ type = Number, default = 0.5 }

    --- Whether enable the auto complete
    property "AutoCompleteEnable"{type = Boolean, default = true }

    --- The max count of the undo list, -1 means no limit, 0 mean no undo/redo operation
    property "MaxOperationCount"{ type = Number, default = -1 }

    ------------------------------------------------------
    -- Event Handler
    ------------------------------------------------------
    local function blockShortKey()
        SetOverrideBindingClick(_BtnBlockDown, false, "DOWN", _BtnBlockDown:GetName(), "LeftButton")
        SetOverrideBindingClick(_BtnBlockUp, false, "UP", _BtnBlockUp:GetName(), "LeftButton")
    end

    local function unBlockShortKey()
        ClearOverrideBindings(_BtnBlockDown)
        ClearOverrideBindings(_BtnBlockUp)
    end

    local function updateCursorAsync(self)
        return SetCursorPosition(self.__Owner, self:GetCursorPosition())
    end

    local function onChar(self, char)
        if self._InPasting or not self:HasFocus() then return true end

        -- Auto Pairs
        local auto              =  char and _AutoPairs[strbyte(char)]
        local startp, endp

        if auto then
            -- { [ ( " '
            local cursor        = self:GetCursorPosition()
            local text          = self:GetText()
            local inner         = self._HighlightText
            local rchar         = auto == true and char or strchar(auto)

            if inner ~= "" then
                -- Has High Light Text, Just do the auto pairs
                self:SetText(replaceBlock(text, cursor + 1, cursor, inner .. rchar))

                local stop      = cursor + #inner
                SetCursorPosition(self.__Owner, stop)
                -- HighlightText(self.__Owner, cursor, stop)
                startp, endp    = cursor, stop
            else
                local next      = skipColor(text, cursor + 1)

                if not inString(text, auto == true and (cursor -1) or cursor) or strbyte(text, next) == auto then
                    if strbyte(text, next) ~= strbyte(char) then
                        self:SetText(replaceBlock(text, cursor + 1, cursor, rchar))
                        SetCursorPosition(self.__Owner, cursor)
                    end
                elseif auto == true then
                    if strbyte(text, next) == strbyte(char) then
                        self:SetText(replaceBlock(text, cursor + 1, next, ""))
                        SetCursorPosition(self.__Owner, cursor)
                    end
                end
            end
        elseif auto == false then
            -- ) ] }
            local cursor        = self:GetCursorPosition()
            local text          = self:GetText()
            local next          = skipColor(text, cursor + 1)

            if strbyte(text, next) == strbyte(char) then
                self:SetText(replaceBlock(text, cursor + 1, next, ""))
                SetCursorPosition(self.__Owner, cursor)
            end
        end

        self._InCharComposition = false

        return formatColor4Line(self, startp, endp)
    end

    local function onCharComposition(self)
        -- Avoid handle cursor change when input with IME
        self._InCharComposition = true
    end

    local function onCursorChanged(self, x, y, w, h)
        local oper              = self._OperationOnLine

        _List:Hide()

        if self._InCharComposition then return end

        if oper == _INPUTCHAR or oper == _BACKSPACE then
            -- Prepare the auto complete but with a delay
            registerAutoComplete(self, x, y, w, h)
        end

        local cursorPos         = self:GetCursorPosition()

        if cursorPos == self._OldCursorPosition and self._OperationOnLine ~= _Operation.CUT then
            return
        end

        local owner             = self.__Owner
        self._OldCursorPosition = cursorPos

        if self._InPasting then
            self._InPasting     = nil
            local startp, endp  = self._HighlightStart, cursorPos
            HighlightText(owner, cursorPos, cursorPos)

            return formatColor4Line(self, startp, endp)
        elseif self._MouseDownShf == false then
            -- First CursorChanged after mouse down if not press shift
            HighlightText(owner, cursorPos, cursorPos)

            self._MouseDownCur  = cursorPos
            self._MouseDownShf  = nil
        elseif self._MouseDownCur then
            if self._MouseDownCur ~= cursorPos then
                -- Hightlight all
                if self._HighlightStart and self._HighlightEnd and self._HighlightStart ~= self._HighlightEnd then
                    if self._HighlightStart == self._MouseDownCur then
                        HighlightText(owner, cursorPos, self._HighlightEnd)
                    elseif self._HighlightEnd == self._MouseDownCur then
                        HighlightText(owner, cursorPos, self._HighlightStart)
                    else
                        HighlightText(owner, self._MouseDownCur, cursorPos)
                    end
                else
                    HighlightText(owner, self._MouseDownCur, cursorPos)
                end

                self._MouseDownCur = cursorPos
            end
        elseif self._BACKSPACE or self._DELETE then
            -- Skip
        elseif self._SKIPCURCHG then
            if tonumber(self._SKIPCURCHG) then
                if self._HighlightStart and self._HighlightEnd and self._HighlightStart ~= self._HighlightEnd then
                    if self._HighlightStart == self._SKIPCURCHG then
                        HighlightText(owner, cursorPos, self._HighlightEnd)
                    elseif self._HighlightEnd == self._SKIPCURCHG then
                        HighlightText(owner, cursorPos, self._HighlightStart)
                    else
                        HighlightText(owner, self._SKIPCURCHG, cursorPos)
                    end
                else
                    HighlightText(owner, self._SKIPCURCHG, cursorPos)
                end
            end

            if not self._SKIPCURCHGARROW then
                self._SKIPCURCHG = nil
            else
                self._SKIPCURCHG = cursorPos
            end
        elseif self._DownOffset then
            local text          = self:GetText()
            local startp, endp  = getLines(text, cursorPos)

            local offset, isv   = 0

            startp, isv         = skipColor(text, startp)

            while startp < endp and offset < self._DownOffset do
                offset          = offset + 1
                if offset == self._DownOffset then break end
                startp          = skipColor(text, startp + (isv and 2 or 1))
            end

            self._DownOffset    = false

            if startp ~= cursorPos then
                return SetCursorPosition(owner, startp)
            end

            HighlightText(owner, cursorPos, cursorPos)
        else
            HighlightText(owner, cursorPos, cursorPos)
        end

        if self._OperationOnLine == _Operation.CUT then
            formatColor4Line(self)
            saveOperation(self)
        end
    end

    local function onEditFocusGained(self, ...)
        if _KeyScan.FocusEditor then
            endPrevKey(_KeyScan.FocusEditor)
        end

        _KeyScan.FocusEditor    = self
        _KeyScan:Show()

        NoCombat(blockShortKey)
    end

    local function onEditFocusLost(self, ...)
        if _KeyScan.FocusEditor ~= self then return end

        endPrevKey(self)
        _KeyScan.FocusEditor    = nil
        _KeyScan:Hide()

        NoCombat(unBlockShortKey)

        _List:Hide()
    end

    local function onEnterPressed(self)
        --- Handle the auto complete list
        if _List:IsShown() then
            local startp, endp, str
            local text          = self:GetText()

            wipe(_BackAutoCache)

            startp, endp        = getWord(text, self:GetCursorPosition(), true)
            str                 = _List.SelectedValue

            if not IsControlKeyDown() and startp and str then
                for _, item in ipairs(_List.RawItems) do
                    tinsert(_BackAutoCache, item.checkvalue)
                end

                _BackAutoCache[0] = _List.SelectedIndex

                self:SetText(replaceBlock(text, startp, endp, str))

                SetCursorPosition(self.__Owner, startp + str:len() - 1)

                formatColor4Line(self, startp, startp + str:len() - 1)

                return
            else
                _List:Hide()
            end
        end

        if not self:IsMultiLine() then return OnEnterPressed(self.__Owner) end

        -- The default behavior
        if not IsControlKeyDown() then
            self:Insert("\n")
        else
            local _, endp       = getLines(self:GetText(), self:GetCursorPosition())
            SetCursorPosition(self.__Owner, endp)
            self:Insert("\n")
        end

        Next(updateCursorAsync, self)

        -- On New Line
        local cursorPos         = self:GetCursorPosition()
        local text              = self:GetText()
        local tabWidth          = self.__Owner.TabWidth
        local lstartp, lendp    = getLines(text, cursorPos - 1)
        local lstr              = lstartp and text:sub(lstartp, lendp)
        local _, len, indent, startp, endp, str, lprevIndent, oprevIndent, prevIndent, lindent, llen

        lstr                    = lstr or ""
        _, llen                 = lstr:find("^%s+")
        llen                    = llen or 0

        lstr, lindent, lprevIndent = formatIndent(self, lstr:sub(llen+1, -1))

        oprevIndent             = lprevIndent

        if lprevIndent == 0 then
            if lindent == 0 then
                self:Insert(strrep(" ", llen))
            elseif lindent > 0 then
                self:Insert(strrep(" ", floor(llen/tabWidth)*tabWidth + tabWidth * lindent))
            end
        else
            startp, endp, str, len = lstartp, lendp, lstr, llen

            while startp > 1 do
                startp, endp      = getLines(text, startp - 2)
                str               = startp and text:sub(startp, endp)

                if startp < endp then
                    _, len      = str:find("^%s+")
                    len         = len or 0

                    if len < str:len() then
                        str, indent, prevIndent = formatIndent(self, str:sub(len+1, -1))

                        lprevIndent = lprevIndent - indent

                        if lprevIndent <= 0 then
                            break
                        end
                    end
                end
            end

            if lprevIndent <= 0 then
                lstr            = strrep(" ", floor(len / tabWidth) * tabWidth) .. lstr
                self:SetText(replaceBlock(text, lstartp, lendp, lstr))
                SetCursorPosition(self.__Owner, lstartp + lstr:len())
                self:Insert(strrep(" ", floor(len / tabWidth) * tabWidth + tabWidth * (lindent + oprevIndent)))
            else
                self:SetText(replaceBlock(text, lstartp, lendp, lstr))
                SetCursorPosition(self.__Owner, lstartp + lstr:len())
                self:Insert(strrep(" ", tabWidth * (lindent + oprevIndent)))
            end
        end

        formatColor4Line(self, lstartp)
        return updateLineNum(self.__Owner)
    end

    local function onMouseUpAsync(self, btn)
        local prev, curr        = self._MouseDownCur, self:GetCursorPosition()
        self._MouseDownCur      = nil
        self._MouseDownShf      = nil

        if self._CheckDblClk then
            -- Select the Words
            local prev          = self._MouseDownTime
            self._CheckDblClk   = false
            self._MouseDownTime = false

            if prev and (GetTime() - prev) < DOUBLE_CLICK_INTERVAL then
                local startp, endp  = getWord(self:GetText(), self:GetCursorPosition())
                if startp and endp then
                    SetCursorPosition(self.__Owner, endp)
                    return Next(HighlightText, self.__Owner, startp - 1, endp)
                end
            end
        end
    end

    local function onMouseUp(self, btn)
        return Next(onMouseUpAsync, self, btn)
    end

    local function onMouseDown(self, btn)
        self._MouseDownCur      = self:GetCursorPosition()

        --- Reset the state
        saveOperation(self)
        endPrevKey(self)

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

    local function onSizeChanged(self)
        return updateLineNum(self.__Owner)
    end

    local function onShow(self)
        return self.__Owner:RefreshLayout()
    end

    local function onTabPressed(self)
        local owner             = self.__Owner

        local text              = self:GetText()

        -- Handle the auto complete
        local startp, endp, str

        if _List:IsShown() then
            wipe(_BackAutoCache)

            startp, endp        = getWord(text, self:GetCursorPosition(), true)
            str                 = _List.SelectedValue

            if startp and str then
                for _, item in ipairs(_List.RawItems) do
                    tinsert(_BackAutoCache, item.checkvalue)
                end

                _BackAutoCache[0] = _List.SelectedIndex

                self:SetText(replaceBlock(text, startp, endp, str))

                SetCursorPosition(self.__Owner, startp + str:len() - 1)

                formatColor4Line(self, startp, startp + str:len() - 1)

                return true
            else
                _List:Hide()
            end
        elseif #_BackAutoCache > 0 then
            startp, endp        = getWord(text, self:GetCursorPosition(), true)
            str                 = startp and removeColor(text:sub(startp, endp))

            if str == _BackAutoCache[_BackAutoCache[0]] then
                _BackAutoCache[0] = _BackAutoCache[0] + 1

                if _BackAutoCache[0] > #_BackAutoCache then
                    _BackAutoCache[0] = 1
                end

                str             = _BackAutoCache[_BackAutoCache[0]]

                if str then
                    self:SetText(replaceBlock(text, startp, endp, str))

                    SetCursorPosition(self.__Owner, startp + str:len() - 1)

                    formatColor4Line(self, startp, startp + str:len() - 1)

                    return true
                else
                    wipe(_BackAutoCache)
                end
            end
        end

        -- Handle the default behavior
        local startp, endp, str, lineBreak
        local shiftDown         = IsShiftKeyDown()
        local cursorPos         = self:GetCursorPosition()
        local tabWidth          = owner.TabWidth

        if self._HighlightStart and self._HighlightEnd and self._HighlightEnd > self._HighlightStart then
            startp, endp        = getLines(text, self._HighlightStart, self._HighlightEnd)
            str                 = text:sub(startp, endp)

            if str:find("\n") then
                lineBreak       = "\n"
            elseif str:find("\r") then
                lineBreak       = "\r"
            else
                lineBreak       = false
            end

            if lineBreak then
                if shiftDown then
                    str         = str:gsub("[^".. lineBreak .."]+", _ShiftIndentFunc[tabWidth])
                else
                    str         = str:gsub("[^".. lineBreak .."]+", _IndentFunc[tabWidth])
                end

                self:SetText(replaceBlock(text, startp, endp, str))

                SetCursorPosition(owner, startp + str:len() - 1)

                HighlightText(owner, startp - 1, startp + str:len() - 1)
            else
                self:SetText(replaceBlock(text, self._HighlightStart + 1, self._HighlightEnd, strrep(" ", tabWidth)))
                SetCursorPosition(owner, self._HighlightStart + tabWidth)
            end
        else
            startp, endp        = getLines(text, cursorPos)
            str                 = text:sub(startp, endp)

            if shiftDown then
                local _, len    = str:find("^%s+")

                if len and len > 0 then
                    if startp + len - 1 >= cursorPos then
                        str     = strrep(" ", len - tabWidth) .. str:sub(len + 1, -1)

                        self:SetText(replaceBlock(text, startp, endp, str))

                        if cursorPos - tabWidth >= startp - 1 then
                            SetCursorPosition(owner, cursorPos - tabWidth)
                        else
                            SetCursorPosition(owner, startp - 1)
                        end
                    else
                        cursorPos = startp - 1 + floor((cursorPos - startp) / tabWidth) * tabWidth

                        SetCursorPosition(owner, cursorPos)
                    end
                end
            else
                local byte      = strbyte(text, cursorPos + 1)

                if byte == _Byte.RIGHTBRACKET or byte == _Byte.RIGHTPAREN then
                    saveOperation(self)

                    SetCursorPosition(owner, cursorPos + 1)
                else
                    local len   = tabWidth - (cursorPos - startp + 1) % tabWidth

                    str         = str:sub(1, cursorPos - startp + 1) .. strrep(" ", len) .. str:sub(cursorPos - startp + 2, -1)

                    self:SetText(replaceBlock(text, startp, endp, str))

                    SetCursorPosition(owner, cursorPos + len)
                end
            end
        end
    end

    local function onEscapePressed(self)
        if _List:IsShown() then
            _List:Hide()
            return true
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
        local lineHolder        = self:GetChild("LineHolder")

        lineHolder:SetPoint("TOPLEFT")
        lineHolder:SetPoint("BOTTOMLEFT")
        lineHolder:SetPoint("RIGHT", linenum, "RIGHT")

        -- Don't use the styles on the line num because there are too many changes on it
        linenum:SetJustifyV("TOP")
        linenum:SetJustifyH("CENTER")

        editor.OnEscapePressed:SetInitFunction(onEscapePressed)

        editor.OnChar           = editor.OnChar             + onChar
        editor.OnCharComposition= editor.OnCharComposition  + onCharComposition
        editor.OnCursorChanged  = editor.OnCursorChanged    + onCursorChanged
        editor.OnEditFocusGained= editor.OnEditFocusGained  + onEditFocusGained
        editor.OnEditFocusLost  = editor.OnEditFocusLost    + onEditFocusLost
        editor.OnEnterPressed   = editor.OnEnterPressed     + onEnterPressed
        editor.OnMouseDown      = editor.OnMouseDown        + onMouseDown
        editor.OnMouseUp        = editor.OnMouseUp          + onMouseUp
        editor.OnTabPressed     = editor.OnTabPressed       + onTabPressed
        editor.OnShow           = editor.OnShow             + onShow
        editor.OnSizeChanged    = editor.OnSizeChanged      + onSizeChanged

        editor.__Owner          = self

        self.__Editor           = editor
        self.__LineNum          = linenum

        initDefinition(editor)

        if not _CommonAutoCompleteList[1] then
            Next(initCommonList)
        end
    end
end)

-----------------------------------------------------------
--                      UI Property                      --
-----------------------------------------------------------
--- the font settings
UI.Property                     {
    name                        = "Font",
    type                        = FontType,
    require                     = CodeEditor,
    get                         = function(self) return Style[self].ScrollChild.EditBox.font end,
    set                         = function(self, font) Style[self].ScrollChild.EditBox.font = font; self:RefreshLayout() end,
    override                    = { "FontObject" },
}

--- the Font object
UI.Property                     {
    name                        = "FontObject",
    type                        = FontObject,
    require                     = CodeEditor,
    get                         = function(self) return Style[self].ScrollChild.EditBox.fontObject end,
    set                         = function(self, font) Style[self].ScrollChild.EditBox.fontObject = font; self:RefreshLayout() end,
    override                    = { "Font" },
}

--- whether the text wrap will be indented
UI.Property                     {
    name                        = "Indented",
    type                        = Boolean,
    require                     = CodeEditor,
    default                     = false,
    get                         = function(self) return Style[self].ScrollChild.EditBox.indented end,
    set                         = function(self, val) Style[self].ScrollChild.EditBox.indented = val; self:RefreshLayout() end,
}

--- the fontstring's amount of spacing between lines
UI.Property                     {
    name                        = "Spacing",
    type                        = Number,
    require                     = CodeEditor,
    default                     = 0,
    get                         = function(self) return Style[self].ScrollChild.EditBox.spacing end,
    set                         = function(self, val) Style[self].ScrollChild.EditBox.spacing = val; self:RefreshLayout() end,
}

--- the insets from the edit box's edges which determine its interactive text area
UI.Property                     {
    name                        = "TextInsets",
    type                        = Inset,
    require                     = CodeEditor,
    get                         = function(self) return Style[self].ScrollChild.EditBox.textInsets end,
    set                         = function(self, val) Style[self].ScrollChild.EditBox.textInsets = val; self:RefreshLayout() end,
}

-----------------------------------------------------------
--              CodeEditor Style - Default               --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [CodeEditor]                = {
        maxLetters              = 0,
        countInvisibleLetters   = false,
        textInsets              = Inset(5, 5, 3, 3),

        LineHolder              = {
            enableMouse         = false,
            frameStrata         = "FULLSCREEN",

            MiddleBGTexture     = {
                color           = Color(0.12, 0.12, 0.12, 0.8),
                setAllPoints    = true,
                alphaMode       = "ADD",
            }
        },
    }
})