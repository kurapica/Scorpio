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
        strrep                  = string.rep,

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
                if pos > 1 and strbyte(str, pos - 1) == _Byte.VERTICAL and (pos == 2 or strbyte(str, pos - 2) ~= _Byte.VERTICAL) then
                    pos             = pos - 2
                else
                    return pos
                end
            elseif pos >= 10 and strbyte(str, pos - 8) == _Byte.c and strbyte(str, pos - 9) == _Byte.VERTICAL and (pos == 10 or strbyte(str, pos - 10) ~= _Byte.VERTICAL) then
                pos             = pos - 10
            else
                return pos
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
            tailtype            = getByteType(strbyte(str, skipColor(str, pos + 1))) or -1
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

    local function endPrevKey(self)
        if self._SKIPCURCHGARROW then
            self._SKIPCURCHGARROW = nil
            self._SKIPCURCHG    = nil
        end
        self._InPasting         = false
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
        local byteCnt           = 0

        while startp <= cursorPos do
            startp              = skipColor(str, startp)

            byteCnt             = byteCnt + 1
            startp              = startp + 1
        end

        return byteCnt
    end

    local function getCursorPosByOffset(str, cursorPos, offset)
        local startp, endp      = getLines(str, cursorPos)
        startp                  = startp - 1

        local byteCnt           = 0

        while byteCnt < offset and startp <= endp do
            startp              = skipColor(str, startp)

            byteCnt             = byteCnt + 1
            startp              = startp + 1
        end

        return startp
    end

    local function newOperation(editor, type)
        editor._OperationOnLine = type
    end

    local function saveOperation(editor)
    end

    local function asyncDelete(self)
        local first             = true
        local str               = self:GetText()
        local nextPos
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
                    nextPos     = skipColor(str, nextPos)
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

        -- self:Fire("OnDeleteFinished")
    end

    local function asyncBackdpace(self)
        local first             = true
        local str               = self:GetText()
        local prevPos
        local pos               = self:GetCursorPosition()

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
                    prevPos     = skipPrevColor(str, prevPos)

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
                    end
                end
            end

            -- Delete
            str                 = replaceBlock(str, prevPos, pos, "")

            self:SetText(str)

            pos                 = prevPos - 1
            SetCursorPosition(self.__Owner, pos)

            -- Do for long press
            if first then
                Delay(_FIRST_WAITTIME)
                first           = false
            else
                Delay(_CONTINUE_WAITTIME)
            end
        end

        --self:Fire("OnBackspaceFinished")
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
                    local handled = nil --editor:Fire("OnDirectionKey", _DirectionKeyEventArgs)

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
                        local _, _, line = getLinesByReturn(editor:GetText(), cursorPos, 1)

                        if line > 0 then
                            endPrevKey(editor)

                            saveOperation(editor)

                            if IsShiftKeyDown()  then
                                editor._SKIPCURCHG = cursorPos
                                editor._SKIPCURCHGARROW = true
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
            elseif IsAltKeyDown() then
                return editor:Fire("OnAltKey", key)
            elseif IsControlKeyDown() then
                if key == "A" then
                    owner:HighlightText()
                    return
                elseif key == "V" then
                    editor._InPasting = true
                    return newOperation(editor, _Operation.PASTE)
                elseif key == "C" then
                    -- do nothing
                    return
                elseif key == "Z" then
                    --return editor:Undo()
                elseif key == "Y" then
                    --return editor:Redo()
                elseif key == "X" then
                    if editor._HighlightStart ~= editor._HighlightEnd then
                        newOperation(editor, _Operation.CUT)
                    end
                    return
                end
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

        editor._HighlightStart  = startp
        editor._HighlightEnd    = endp

        if startp ~= endp then
            text                = text or editor:GetText()
            editor._HighlightText   = text:sub(startp + 1, endp)
        else
            editor._HighlightText   = ""
        end

        print("Hightlight", startp, endp)

        return editor:HighlightText(startp, endp)
    end

    --- Set the cursor position
    function SetCursorPosition(self, pos)
        local editor            = self.__Editor
        editor._OldCursorPosition = pos
        editor:SetCursorPosition(pos)
        return self:HighlightText(pos, pos)
    end

    --- Set The Text
    function SetText(self, text)
        self.__Editor:SetText(text)
    end

    --- Get the text
    function GetText(self)
        return self.__Editor:GetText()
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
                HighlightText(self.__Owner, cursor, stop)
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
    end

    local function onCharComposition(self)
        -- Avoid handle cursor change when input with IME
        self._InCharComposition = true
    end

    local function onCursorChanged(self, x, y, w, h)
        if self._InCharComposition then return end

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

            return -- self:Fire("OnPasting", startp, endp)
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
        else
            HighlightText(owner, cursorPos, cursorPos)
        end

        if self._OperationOnLine == _Operation.CUT then
            -- self:Fire("OnCut", self.__OperationStartOnLine, self.__OperationEndOnLine, self.__OperationBackUpOnLine:sub(self.__OperationStartOnLine, self.__OperationEndOnLine))
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
    end

    local function onEnterPressed(self)
        if not IsControlKeyDown() then
            self:Insert("\n")
        else
            local _, endp = getLines(self:GetText(), self:GetCursorPosition())
            SetCursorPosition(self.__Owner, endp)
            self:Insert("\n")
        end

        Next(updateCursorAsync, self)

        -- On New Line
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

    local function onMouseDownAsync(self, btn)
        self._MouseDownCur      = self:GetCursorPosition()

        --- Reset the state
        saveOperation(self)
        endPrevKey(self)
        updateCursorAsync(self)
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

    local function onSizeChanged(self)
        return updateLineNum(self.__Owner)
    end

    local function onShow(self)
        return self:RefreshLayout()
    end

    local function onTabPressed(self)
        local owner             = self.__Owner

        local text              = self:GetText()

        if self._HighlightStart == 0 and self._HighlightStart ~= self._HighlightEnd and self._HighlightEnd == text:len() then
            -- just reload text
            owner:SetText(owner:GetText())
            return SetCursorPosition(owner, 0)
        end

        local handled           = false -- self:Fire("OnTabPressed", args)
        if handled then return end

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
                    SaveOperation(self)

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

        -- Don't use the styles on the line num because there are too many changes on it
        linenum:SetJustifyV("TOP")
        linenum:SetJustifyH("CENTER")

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