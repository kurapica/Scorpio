--========================================================--
--                Scorpio UnitFrame FrameWork             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/06/09                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame"         "1.0.0"
--========================================================--

do
    ------------------------------------------------------
    --                Hover Spell Helper                --
    ------------------------------------------------------
    local _UnitFrameHoverSpellGroup

    _UpdateGroupQueue           = Queue()

    _ActionType                 = {
        Spell                   = {
            type                = "spell",
            parse               = function (spell)
                if (type(spell) == "string" or type(spell) == "number") and GetSpellInfo(spell) then
                    -- Only keep spell id
                    return tonumber(GetSpellLink(spell):match('spell:(%d+)')), IsHarmfulSpell(spell)
                end

                error("Invalid spell name|id - "..tostring(spell), 3)
            end,
            content             = "spell",
            tranMacro           = function (spell, with)
                if GetSpellInfo(spell) then
                    return ("/%s %%unit\n/cast %s"):format(with, GetSpellInfo(spell))
                end
            end
        },
        Macro                   = {
            type                = "macro",
            parse               = function (macro)
                if type(macro) == "string" then
                    macro       = GetMacroIndexByName(macro)
                end

                if type(macro) == "number" and macro > 0 and GetMacroInfo(macro) then
                    return macro
                end

                error("Invalid macro name|index", 3)
            end,
            content             = "macro"
        },
        MacroText               = {
            type                = "macro",
            parse               = function (macroText)
                if type(macroText) == "string" and strtrim(macroText) ~= "" then
                    return strtrim(macroText)
                end

                error("Invalid macro text", 3)
            end,
            content             = "macrotext"
        },
        Item                    = {
            type                = "item",
            parse               = function (item)
                if (type(item) == "string" or type(item) == "number") and GetItemInfo(item) then
                    return tonumber(select(GetItemInfo(item), 2):match('item:(%d+)'))
                end

                error("Invalid item|id|link", 3)
            end,
            content             = "item",
            tranMacro           = function (item, with)
                if GetItemInfo(item) then
                    return ("/%s %%unit\n/use %s"):format(with, GetItemInfo(item))
                end
            end
        },
        Menu                    = { type = "menu" },
        Target                  = { type = "target" },
        Focus                   = { type = "focus" },
        Assist                  = { type = "assist" },
    }

    _SetupTemplate              = [[self:SetAttribute("%s", %q)]]
    _ClearTemplate              = [[self:SetAttribute("%s", nil)]]

    _EnterTemplate              = [[self:SetBindingClick(true, "%s", self, "%s")]]
    _LeaveTemplate              = [[self:ClearBinding("%s")]]

    _Key2Name                   = setmetatable(
        {
            ["1"]               = "one",
            ["2"]               = "two",
            ["3"]               = "three",
            ["4"]               = "four",
            ["5"]               = "five",
            ["6"]               = "six",
            ["7"]               = "seven",
            ["8"]               = "eight",
            ["9"]               = "nine",
            ["0"]               = "zero",
            [","]               = "comma",
            ["."]               = "period",
            ["/"]               = "slash",
            ["`"]               = "backtick ",
            ["["]               = "leftbracket",
            ["]"]               = "rightbracket",
            ["\\"]              = "backslash",
            ["-"]               = "minus",
            ["="]               = "equals",
            [";"]               = "semicolon",
            ["'"]               = "singlequote",
            ["ESCAPE"]          = false,
            ["PRINTSCREEN"]     = false,
            ["LSHIFT"]          = false,
            ["RSHIFT"]          = false,
            ["LCTRL"]           = false,
            ["RCTRL"]           = false,
            ["LALT"]            = false,
            ["RALT"]            = false,
            ["UNKNOWN"]         = false,
        },{
            __index = function (self, key)
                if type(key) == "string" then
                    return key:lower()
                end
            end
        }
    )

    function parseBindKey(key)
        local ret

        if type(key) == "string" and strtrim(key) ~= "" then
            key                 = strtrim(key):upper()

            -- Check the tail key is "-"
            if key:sub(-1) == "-" then
                ret             = "-"
            else
                ret             = key:match("[^-]+$")
            end

            if not ret or ret == "" or not _Key2Name[ret] then return end

            -- Remap mouse key
            if ret == "LEFTBUTTON" then
                ret             = "BUTTON1"
            elseif ret == "RIGHTBUTTON" then
                ret             = "BUTTON2"
            elseif ret == "MIDDLEBUTTON" then
                ret             = "BUTTON3"
            end

            -- Remap option key
            if key:find("SHIFT-") then
                ret             = "SHIFT-" .. ret
            end

            if key:find("CTRL-") then
                ret             = "CTRL-" .. ret
            end

            if key:find("ALT-") then
                ret             = "ALT-" .. ret
            end
        end

        if not ret then error("Invalid binding key - " .. key, 3) end
        return ret
    end

    function getBindingDB(group, type, content)
        if not (_UnitFrameHoverSpellGroup and _UnitFrameHoverSpellGroup[group]) then return end

        for key, set in pairs(_UnitFrameHoverSpellGroup[group]) do
            if set["HarmAction"] == type and set["HarmContent"] == content then
                return key, set["HarmWith"], true
            elseif set["HelpAction"] == type and set["HelpContent"] == content then
                return key, set["HelpWith"], false
            end
        end
    end

    function getBindingDB4Key(group, key, harmful)
        local db                = _UnitFrameHoverSpellGroup and _UnitFrameHoverSpellGroup[group] and _UnitFrameHoverSpellGroup[group][key]

        if db then
            local prev          = harmful and "Harm" or "Help"
            return db[prev.."Action"], db[prev.."Content"], db[prev.."With"]
        end
    end

    function clearBindingDB(group, type, content)
        local key, with, harmful= getBindingDB(group, type, content)

        if key then
            local db            = _UnitFrameHoverSpellGroup[group][key]

            local prev          = harmful and "Harm" or "Help"

            db[prev.."Action"]  = nil
            db[prev.."Content"] = nil
            db[prev.."With"]    = nil

            if not next(db) then
                _UnitFrameHoverSpellGroup[group][key] = nil
            end

            return queueGroupUpdate(group)
        end
    end

    function clearBindingDB4Key(group, key)
        if not _UnitFrameHoverSpellGroup then return end

        if not _UnitFrameHoverSpellGroup[group] then
            return false
        end

        if not key then
            wipe(_UnitFrameHoverSpellGroup[group])
            return true
        end

        if not _UnitFrameHoverSpellGroup[group][key] then
            return false
        end

        _UnitFrameHoverSpellGroup[group][key] = nil

        return queueGroupUpdate(group)
    end

    function saveBindngDB(group, key, type, content, with, harmful)
        if not _UnitFrameHoverSpellGroup then return end

        if not key then throw("No binding key is set.")  end
        if not type or not _ActionType[type] then throw("No action type is set.") end
        if _ActionType[type].content and not content then throw("No action content is set.") end

        -- one spell in one group only match one key
        clearBindingDB(group, type, content)

        _UnitFrameHoverSpellGroup[group]        = _UnitFrameHoverSpellGroup[group]      or {}
        _UnitFrameHoverSpellGroup[group][key]   = _UnitFrameHoverSpellGroup[group][key] or {}

        local db                = _UnitFrameHoverSpellGroup[group][key]

        local prev              = harmful and "Harm" or "Help"

        db[prev.."Action"]      = type
        db[prev.."Content"]     = content
        db[prev.."With"]        = with

        return queueGroupUpdate(group)
    end

    function mapKey(key)
        key                     = key:lower()

        local isClk             = false
        local prev

        -- Check tail key
        if key:sub(-1) == "-" then
            prev, key           = key:sub(1, -2), key:sub(-1)
        else
            prev, key           = key:match("(.-)([^-]+)$")
        end

        if key:match("button%d+") then
            isClk               = true
            key                 = key:match("button(%d+)")
        else
            key                 = prev:gsub("-", "") .. _Key2Name[key]
            prev                = ""
        end

        return isClk, prev, key
    end

    function mapAction(action, content, with)
        local actionSet         = _ActionType[action]
        if not actionSet then return end

        if with and actionSet.tranMacro then
            return "MacroText", actionSet.tranMacro(content, with)
        else
            return action, content
        end
    end

    function getSnippet(group)
        if not (_UnitFrameHoverSpellGroup and _UnitFrameHoverSpellGroup[group]) then return end

        local setup             = List()
        local clear             = List()
        local enter             = List()
        local leave             = List()

        local isMouseClk, prev, kname, virtualKey, useVirtual, connect
        local actionSet, tranType, tranContent

        for key, set in pairs(_UnitFrameHoverSpellGroup[group]) do
            useVirtual          = false

            isMouseClk, prev, kname = mapKey(key)

            if not isMouseClk then
                enter:Insert(_EnterTemplate:format(key, kname))
                leave:Insert(_LeaveTemplate:format(key))
            end

            connect             = isMouseClk and "" or "-"

            if set.HarmAction and set.HelpAction then
                useVirtual      = true
            end

            if set.HarmAction then
                if useVirtual then
                    virtualKey  = "enemy" .. kname
                    setup:Insert(_SetupTemplate:format("harmbutton" .. connect .. kname, virtualKey))
                    clear:Insert(_ClearTemplate:format("harmbutton" .. connect .. kname))

                    virtualKey  = "-" .. virtualKey
                else
                    virtualKey  = connect .. kname
                end

                tranType, tranContent = mapAction(set.HarmAction, set.HarmContent, set.HarmWith)

                actionSet       = _ActionType[tranType]

                if actionSet then
                    setup:Insert(_SetupTemplate:format(prev .. "type" .. virtualKey, actionSet.type))
                    clear:Insert(_ClearTemplate:format(prev .. "type" .. virtualKey))

                    if actionSet.content and tranContent then
                        setup:Insert(_SetupTemplate:format(prev .. actionSet.content .. virtualKey, tranContent))
                        clear:Insert(_ClearTemplate:format(prev .. actionSet.content .. virtualKey))
                    end
                end
            end

            if set.HelpAction then
                if useVirtual then
                    virtualKey  = "friend" .. kname
                    setup:Insert(_SetupTemplate:format("helpbutton" .. connect .. kname, virtualKey))
                    clear:Insert(_ClearTemplate:format("helpbutton" .. connect .. kname))

                    virtualKey  = "-" .. virtualKey
                else
                    virtualKey  = connect .. kname
                end

                tranType, tranContent = mapAction(set.HelpAction, set.HelpContent, set.HelpWith)

                actionSet       = _ActionType[tranType]

                if actionSet then
                    setup:Insert(_SetupTemplate:format(prev .. "type" .. virtualKey, actionSet.type))
                    clear:Insert(_ClearTemplate:format(prev .. "type" .. virtualKey))

                    if actionSet.content and tranContent then
                        setup:Insert(_SetupTemplate:format(prev .. actionSet.content .. virtualKey, tranContent))
                        clear:Insert(_ClearTemplate:format(prev .. actionSet.content .. virtualKey))
                    end
                end
            end
        end
        return setup:Join("\n"), clear:Join("\n"), enter:Join("\n"), leave:Join("\n")
    end

    ------------------------------------------------------
    --               Hover Spell Manager                --
    ------------------------------------------------------
    -- Manager Frame
    _ManagerFrame               = SecureFrame("Scorpio_UnitFrame_HoverSpellManager")
    _ManagerFrame:Hide()

    -- Init manger frame's enviroment
    NoCombat(function ()
        _ManagerFrame:Execute[[
            Manager             = self

            _HoverOnUnitFrame   = nil
            _HoverOnUnitFrameLeaveSnippet = nil

            _GroupMap           = newtable()
            _UnitMap            = newtable()

            _SetupSnippet       = newtable()
            _ClearSnippet       = newtable()
            _EnterSnippet       = newtable()
            _LeaveSnippet       = newtable()
        ]]
    end)

    -- Global script sinppet, keep all run at global enviroment
    -- Init Snippet
    InitSnippet                 = [[
        local group             = "%s"
        local initFrame         = Manager:GetFrameRef("InitUnitFrame")

        if _HoverOnUnitFrame == initFrame and _HoverOnUnitFrameLeaveSnippet then
            _HoverOnUnitFrame:UnregisterAutoHide()
            Manager:RunFor(_HoverOnUnitFrame, _HoverOnUnitFrameLeaveSnippet)

            _HoverOnUnitFrame   = nil
            _HoverOnUnitFrameLeaveSnippet = nil
        end

        _GroupMap[initFrame]    = group
    ]]

    -- Dispose Snippet
    DisposeSnippet              = [[
        local group             = "%s"
        local disposeFrame      = Manager:GetFrameRef("DisposeUnitFrame")

        _GroupMap[disposeFrame] = nil

        if _HoverOnUnitFrame == disposeFrame then
            if _HoverOnUnitFrameLeaveSnippet then
                _HoverOnUnitFrame:UnregisterAutoHide()
            end
            _HoverOnUnitFrame   = nil
            _HoverOnUnitFrameLeaveSnippet = nil
        end

        if _LeaveSnippet[group] then
            Manager:RunFor(disposeFrame, _LeaveSnippet[group])
        end

        if _ClearSnippet[group] then
            Manager:RunFor(disposeFrame, _ClearSnippet[group])
        end
    ]]

    -- OnEnter Snippet
    -- Also keep clear & leave snippet for update using
    OnEnterSnippet              = [[
        local group             = _GroupMap[self]
        if not group then return end

        local unit              = self:GetAttribute("unit")

        if _HoverOnUnitFrame and _HoverOnUnitFrameLeaveSnippet and _HoverOnUnitFrame ~= self then
            _HoverOnUnitFrame:UnregisterAutoHide()
            Manager:RunFor(_HoverOnUnitFrame, _HoverOnUnitFrameLeaveSnippet)
            if _HoverOnUnitFrame:GetAttribute("unit") then
                _HoverOnUnitFrame:Show()
            end
        end

        if _SetupSnippet[group] and _UnitMap[self] ~= unit then
            _UnitMap[self]      = unit
            Manager:RunFor(self, _SetupSnippet[group]:gsub("%%unit", unit or ""))
        end

        _HoverOnUnitFrame       = self
        _HoverOnUnitFrameLeaveSnippet = _LeaveSnippet[group]

        if _EnterSnippet[group] then
            Manager:RunFor(self, _EnterSnippet[group])
        end

        if _HoverOnUnitFrameLeaveSnippet then
            _HoverOnUnitFrame:RegisterAutoHide(0.25)
        end
    ]]

    -- OnLeave Snippet
    OnLeaveSnippet              = [[
        local group             = _GroupMap[self]
        if not group then return end

        if _HoverOnUnitFrame == self then
            if _HoverOnUnitFrameLeaveSnippet then
                _HoverOnUnitFrame:UnregisterAutoHide()
                if _HoverOnUnitFrame:GetAttribute("unit") then
                    _HoverOnUnitFrame:Show()
                end
            end
            _HoverOnUnitFrame   = nil
            _HoverOnUnitFrameLeaveSnippet = nil
        end

        if _LeaveSnippet[group] then
            Manager:RunFor(self, _LeaveSnippet[group])
        end
    ]]

    -- OnHide Snippet
    OnHideSnippet               = [[
        local group             = _GroupMap[self]
        if not group then return end

        if _HoverOnUnitFrame ~= self then
            return
        end

        if _HoverOnUnitFrameLeaveSnippet then
            self:UnregisterAutoHide()
            if self:GetAttribute("unit") then
                self:Show()
            end
        end

        _HoverOnUnitFrame       = nil
        _HoverOnUnitFrameLeaveSnippet = nil

        if _LeaveSnippet[group] then
            Manager:RunFor(self, _LeaveSnippet[group])
        end
    ]]

    -- Build Snippet for group
    SetupGroupSnippet           = [[
        local group             = "%s"

        if _HoverOnUnitFrame and _GroupMap[_HoverOnUnitFrame] == group then
            if _HoverOnUnitFrameLeaveSnippet then
                _HoverOnUnitFrame:UnregisterAutoHide()
                Manager:RunFor(_HoverOnUnitFrame, _HoverOnUnitFrameLeaveSnippet)
            end
            _HoverOnUnitFrame   = nil
            _HoverOnUnitFrameLeaveSnippet = nil
        end

        for frm, grp in pairs(_GroupMap) do
            if grp == group then
                _UnitMap[frm]   = nil

                if _ClearSnippet[group] then
                    Manager:RunFor(frm, _ClearSnippet[group])
                end
            end
        end

        _SetupSnippet[group]    = %q
        _ClearSnippet[group]    = %q
        _EnterSnippet[group]    = %q
        _LeaveSnippet[group]    = %q

        if _SetupSnippet[group] == "" then
            _SetupSnippet[group]= nil
        end

        if _ClearSnippet[group] == "" then
            _ClearSnippet[group]= nil
        end

        if _EnterSnippet[group] == "" then
            _EnterSnippet[group]= nil
        end

        if _LeaveSnippet[group] == "" then
            _LeaveSnippet[group]= nil
        end
    ]]

    -- Initialize unit frame
    __NoCombat__()
    function initUnitFrame(self, group, old)
        if old then
            _ManagerFrame:SetFrameRef("DisposeUnitFrame", self)
            _ManagerFrame:Execute(DisposeSnippet:format(old:upper()))
        end

        if group then
            _ManagerFrame:SetFrameRef("InitUnitFrame", self)
            _ManagerFrame:Execute(InitSnippet:format(group:upper()))
        end
    end

    -- Dispose unit frame, but since we can't really dispose the frame
    -- Just keep the code, no use
    __NoCombat__()
    function removeUnitFrame(self, group)
        _ManagerFrame:UnwrapScript(self, "OnEnter")
        _ManagerFrame:UnwrapScript(self, "OnLeave")
        _ManagerFrame:UnwrapScript(self, "OnHide")

        _ManagerFrame:SetFrameRef("DisposeUnitFrame", self)
        _ManagerFrame:Execute(DisposeSnippet:format(group))
    end

    function queueGroupUpdate(group)
        if _UpdateGroupQueue[group] then return end
        if _UpdateGroupQueue.Count == 0 then FireSystemEvent("SCORPIO_UNITFRAME_HOVER_GROUP_UPDATE") end

        _UpdateGroupQueue[group]= true
        _UpdateGroupQueue:Enqueue(group)
    end

    __Service__(true)
    function ProcessGroupUpdate()
        while true do
            local group         = _UpdateGroupQueue:Dequeue()

            while group do
                Continue()
                NoCombat()

                if _UpdateGroupQueue[group] then
                    _UpdateGroupQueue[group] = nil

                    Debug("[UnitFrame]Setup the secure snippets for group: %s", group)
                    _ManagerFrame:Execute(SetupGroupSnippet:format(group, getSnippet(group)))
                end

                group           = _UpdateGroupQueue:Dequeue()
            end

            NextEvent("SCORPIO_UNITFRAME_HOVER_GROUP_UPDATE")
        end
    end

    ------------------------------------------------------
    --                   Module Event                   --
    ------------------------------------------------------
    if _G.GetSpecialization then
        -- Save in Spec
        function OnLoad(self)
            _SVData.Char.Spec:SetDefault {
                UnitFrameHoverSpellGroup= {}
            }
        end

        function OnSpecChanged(self)
            _UnitFrameHoverSpellGroup   = _SVData.Char.Spec.UnitFrameHoverSpellGroup

            for grp in pairs(_UnitFrameHoverSpellGroup) do
                queueGroupUpdate(grp)
            end
        end

        function OnQuit(self)
            for grp, db in pairs(_UnitFrameHoverSpellGroup) do
                if not next(db) then
                    _UnitFrameHoverSpellGroup[grp] = nil
                end
            end
        end
    else
        -- Save in Char
        function OnLoad(self)
            _SVData.Char:SetDefault {
                UnitFrameHoverSpellGroup= {}
            }

            _UnitFrameHoverSpellGroup   = _SVData.Char.UnitFrameHoverSpellGroup

            for grp in pairs(_UnitFrameHoverSpellGroup) do
                queueGroupUpdate(grp)
            end
        end

        function OnQuit(self)
            if _UnitFrameHoverSpellGroup then
                for grp, db in pairs(_UnitFrameHoverSpellGroup) do
                    if not next(db) then
                        _UnitFrameHoverSpellGroup[grp] = nil
                    end
                end
            end
        end
    end
end

--- The root unit frame widget class with hover spell casting
-- We can bind short keys to the hover spell group, each unit frame can have a group
--
-- UnitFrame.HoverSpellGroups["Default"].Spell["Holy Light"].With["target"].Key = "ctrl-f"
-- UnitFrame.HoverSpellGroups["Default"].MacroText["/cast Holy Light"].Key = "ctrl-f"
--
__Sealed__() __SecureTemplate__"SecureUnitButtonTemplate, SecureHandlerAttributeTemplate"
class "UnitFrame" (function(_ENV)
    inherit "SecureButton"
    extend "IUnitFrame"

    import "System.Reactive"

    ------------------------------------------------------
    --                      Helper                      --
    ------------------------------------------------------
    -- The secure snippet for the unit attribute changes
    local _onattributechanged   = [[
        if name == "unit" then
            if self:GetAttribute("deactivated") then
                if value then self:SetAttribute("unit", nil) end
                return
            end

            if type(value) == "string" then
                value = strlower(value)
            else
                value = nil
            end

            local nounitwatch = self:GetAttribute("nounitwatch")

            if value == "player" then
                if not nounitwatch then
                    UnregisterUnitWatch(self)
                end
                self:Show()
            elseif value then
                if not nounitwatch then
                    RegisterUnitWatch(self)
                else
                    self:Show()
                end
            else
                if not nounitwatch then
                    UnregisterUnitWatch(self)
                end
                self:Hide()
            end

            self:CallMethod("ProcessUnitChange", value)
        elseif name == "nounitwatch" then
            local unit = self:GetAttribute("unit")

            if unit and unit ~= "player" then
                if value then
                    UnregisterUnitWatch(self)
                else
                    RegisterUnitWatch(self)
                end
            end
        end
    ]]

    local function OnEnter(self)
        return self:UpdateTooltip()
    end

    local function OnLeave(self)
        GameTooltip:FadeOut()
    end

    ------------------------------------------------------
    --            Hover Spell Group Accessor            --
    ------------------------------------------------------
    __Sealed__() class "HoverSpellGroupAccessor" (function(_ENV)
        local accessor

        ------------------------------------------------------
        --                      method                      --
        ------------------------------------------------------
        function Reset(self)
            return self.Group and clearBindingDB4Key(self.Group)
        end

        ------------------------------------------------------
        --                     Proeprty                     --
        ------------------------------------------------------
        --- The hover spell group
        property "Group"        { type = String }

        --- The action type accessor
        for name, set in pairs(_ActionType) do
            if set.content then
                __Indexer__(String + Number)
                property(name)  {
                    get         = function(self, content)
                        self.Data.Type      = name
                        self.Data.Content   = content
                        self.Data.With      = nil
                        return self
                    end,
                }
            else
                property(name)  {
                    get         = function(self)
                        self.Data.Type      = name
                        self.Data.Content   = nil
                        self.Data.With      = nil
                        return self
                    end
                }
            end
        end

        --- Get the with settings from the binding
        property "With"         {
            get                 = function(self)
                local type, ct  = self.Data.Type, self.Data.Content
                if type then
                    return (select(2, getBindingDB(self.Group, type, ct)))
                end
            end
        }

        --- Whether combine a 'target' action
        property "WithTarget"   {
            get                 = function(self)
                self.Data.With  = "target"
                return self
            end
        }

        --- Whether combine a 'focus' action
        property "WithFocus"    {
            get                 = function(self)
                self.Data.With  = "focus"
                return self
            end
        }

        --- Whether combine a 'assist' action
        property "WithAssist"   {
            get                 = function(self)
                self.Data.With  = "assist"
                return self
            end
        }

        --- Gets/Sets the binding key
        property "Key"          {
            throwable           = true,
            get                 = function(self)
                local type, ct  = self.Data.Type, self.Data.Content
                if type then
                    return getBindingDB(self.Group, type, ct)
                end
            end,
            set                 = function(self, value)
                local type, ct  = self.Data.Type, self.Data.Content
                local harmful

                if not type then
                    throw("Usage: UnitFrame.HoverSpellGroups[group].Action[content].Key = value - the action type not specified")
                end

                local action    = _ActionType[type]

                if action.content and not ct then
                    throw("Usage: UnitFrame.HoverSpellGroups[group].Action[content].Key = value - the action content not specified")
                end

                if action.parse then
                    ct, harmful = action.parse(ct)
                end

                if value == nil then
                    return clearBindingDB(self.Group, type, ct)
                else
                    value       = parseBindKey(value)
                    if not value then
                        throw("Usage: UnitFrame.HoverSpellGroups[group].Action[content].Key = value - the key value not valid")
                    end

                    local otype, oct, owith = getBindingDB4Key(value)
                    if type == otype and ct == oct and self.Data.With == owith then
                        return
                    end

                    return saveBindngDB(self.Group, value, type, ct, self.Data.With, harmful)
                end
            end,
        }

        ------------------------------------------------------
        --                   Constructor                    --
        ------------------------------------------------------
        __Arguments__{ NEString }
        function __ctor(self, group)
            self.Group          = group:upper()
            self.Data           = {}

            accessor            = self
        end

        __Arguments__{ NEString}
        function __exist(cls, group)
            if accessor then
                accessor.Group  = group:upper()
                wipe(accessor.Data)

                return accessor
            end
        end
    end)

    ------------------------------------------------------
    --                 Static Proeprty                  --
    ------------------------------------------------------
    --- The hover spell group accessor
    __Static__() __Indexer__(NEString)
    property "HoverSpellGroups" {
        get                     = function(self, name)
            return HoverSpellGroupAccessor(name)
        end,
    }

    ------------------------------------------------------
    --                     Proeprty                     --
    ------------------------------------------------------
    --- The unit attached to the unit frame
    property "Unit"             {
        type                    = String,
        set                     = function(self, unit)
            if unit ~= self:GetAttribute("unit") then
                self:SetAttribute("unit", unit)
            end
        end,
        get                     = function(self)
            return self:GetAttribute("unit")
        end,
    }

    --- Whether active the unit frame, deactive it will hide it
    property "Activated"        {
        type                    = Boolean,
        set                     = function(self, active)
            if self.Activated == active then return end

            NoCombat(function()
                if active then
                    local unit  = self:GetAttribute("deactivated")
                    if unit then
                        self:SetAttribute("deactivated", nil)

                        if type(unit) == "string" then
                            self:SetAttribute("unit", unit)
                        end
                    end
                else
                    self:SetAttribute("deactivated", self:GetAttribute("unit") or true)
                    self:SetAttribute("unit", nil)
                end
            end)
        end,
        get                     = function(self)
            return not self:GetAttribute("deactivated")
        end,
        default                 = true,
    }

    --- Whether enable the unit watch
    property "UnitWatchEnabled" {
        type                    = Boolean,
        set                     = function(self, enabled)
            if self.UnitWatchEnabled == enabled then return end
            NoCombat(function() self:SetAttribute("nounitwatch", not enabled) end)
        end,
        get                     = function(self)
            return not self:GetAttribute("nounitwatch")
        end,
    }

    --- The refresh interval for special unit like 'targettarget'
    property "Interval"         { type = PositiveNumber, default = 0.5 }

    --- The hover spell group
    property "HoverSpellGroup"  { type = String, handler = initUnitFrame }

    ------------------------------------------------------
    --                      Method                      --
    ------------------------------------------------------
    __SecureMethod__()
    function ProcessUnitChange(self, unit)
        return self:OnUnitRefresh(unit)
    end

    function UpdateTooltip(self)
        local unit              = self:GetAttribute("unit")
        if unit then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(unit)
            local r, g, b       = GameTooltip_UnitColor(unit)
            _G.GameTooltipTextLeft1:SetTextColor(r, g, b)
        end
    end

    ------------------------------------------------------
    --                   Constructor                    --
    ------------------------------------------------------
    function __ctor(self, ...)
        -- Use * so those are default actions that can be overridden
        self:SetAttribute("*type1", "target")
        self:SetAttribute("shift-type1", "focus")
        self:SetAttribute("*type2", "togglemenu")

        self:RegisterForClicks("AnyUp")

        self.OnEnter            = self.OnEnter + OnEnter
        self.OnLeave            = self.OnLeave + OnLeave

        _ManagerFrame:WrapScript(self, "OnEnter", OnEnterSnippet)
        _ManagerFrame:WrapScript(self, "OnLeave", OnLeaveSnippet)
        _ManagerFrame:WrapScript(self, "OnHide",  OnHideSnippet)

        -- Prepare for secure handler
        self:SetAttribute("_onattributechanged", _onattributechanged)

        -- The group maybe set by child class
        -- normally should be done by the style system
        if self.HoverSpellGroup then
            initUnitFrame(self)
        end
    end
end)
