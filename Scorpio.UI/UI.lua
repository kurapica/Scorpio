--========================================================--
--                Scorpio UI FrameWork                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/27                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI"                       "1.0.0"
--========================================================--

namespace "Scorpio.UI"

----------------------------------------------
------------ Addon Event Handler -------------
----------------------------------------------
function OnLoad(self)
    _SVData:SetDefault     ("LayoutCache", {})
    _SVData.Char:SetDefault("LayoutCache", {})
end

function OnQuit(self)
    -- Save the layout datas
    wipe(_SVData.LayoutCache)
    wipe(_SVData.Char.LayoutCache)

    for frm, characterOnly in pairs(UI_USERPLACED) do
        if not frm.Disposed then
            local uname = frm:GetUniqueName()

            if uname then
                if characterOnly then
                    _SVData.Char.LayoutCache[uname] = {
                        Size = frm.Size,
                        Location = frm.Location,
                    }
                else
                    _SVData.LayoutCache[uname] = {
                        Size = frm.Size,
                        Location = frm.Location,
                    }
                end
            end
        end
    end
end

------------------------------------------------------------
--                     Enums(UI.xsd)                      --
------------------------------------------------------------
do
    __Sealed__()
    enum "FramePoint" {
        "TOPLEFT",
        "TOPRIGHT",
        "BOTTOMLEFT",
        "BOTTOMRIGHT",
        "TOP",
        "BOTTOM",
        "LEFT",
        "RIGHT",
        "CENTER",
    }

    __Sealed__()
    enum "FrameStrata" {
        "PARENT",
        "BACKGROUND",
        "LOW",
        "MEDIUM",
        "HIGH",
        "DIALOG",
        "FULLSCREEN",
        "FULLSCREEN_DIALOG",
        "TOOLTIP",
    }

    __Sealed__()
    enum "DrawLayer" {
        "BACKGROUND",
        "BORDER",
        "ARTWORK",
        "OVERLAY",
        "HIGHLIGHT",
    }

    __Sealed__() __Default__"ADD"
    enum "AlphaMode" {
        "DISABLE",
        "BLEND",
        "ALPHAKEY",
        "ADD",
        "MOD",
    }

    __Sealed__() __Default__"NONE"
    enum "OutlineType" {
        "NONE",
        "NORMAL",
        "THICK",
    }

    __Sealed__() __Default__ "MIDDLE"
    enum "JustifyVType" {
        "TOP",
        "MIDDLE",
        "BOTTOM",
    }

    __Sealed__() __Default__ "CENTER"
    enum "JustifyHType" {
        "LEFT",
        "CENTER",
        "RIGHT",
    }

    __Sealed__()
    enum "InsertMode" {
        "TOP",
        "BOTTOM",
    }

    __Sealed__() __Default__ "HORIZONTAL"
    enum "Orientation" {
        "HORIZONTAL",
        "VERTICAL",
    }

    __Sealed__()
    enum "AttributeType" {
        "nil",
        "boolean",
        "number",
        "string",
    }

    __Sealed__()
    enum "KeyValueType" {
        "nil",
        "boolean",
        "number",
        "string",
        "global",
    }

    __Sealed__()
    enum "ScriptInheritType" {
        "prepend",
        "append",
        "none",
    }

    __Sealed__()
    enum "ScriptIntrinsicOrderType" {
        "precall",
        "postcall",
        "none",
    }

    __Sealed__()
    enum "FontAlphabet" {
        "roman",
        "korean",
        "simplifiedchinese",
        "traditionalchinese",
        "russian",
    }

    __Sealed__() __Default__"NONE"
    enum "AnimLoopType" {
        "NONE",
        "REPEAT",
        "BOUNCE",
    }

    __Sealed__() __Default__"NONE"
    enum "AnimLoopStateType" {
        "NONE",
        "FORWARD",
        "REVERSE",
    }
    __Sealed__() __Default__"NONE"
    enum "AnimSmoothType" {
        "NONE",
        "IN",
        "OUT",
        "IN_OUT",
        "OUT_IN",
    }

    __Sealed__() __Default__"NONE"
    enum "AnimCurveType" {
        "NONE",
        "SMOOTH",
    }

    __Sealed__()
    enum "AnchorType" {
        "ANCHOR_TOPRIGHT",
        "ANCHOR_RIGHT",
        "ANCHOR_BOTTOMRIGHT",
        "ANCHOR_TOPLEFT",
        "ANCHOR_LEFT",
        "ANCHOR_BOTTOMLEFT",
        "ANCHOR_CURSOR",
        "ANCHOR_PRESERVE",
        "ANCHOR_NONE",
    }

    __Sealed__()
    enum "ButtonStateType" {
        "PUSHED",
        "NORMAL",
    }

    __Sealed__()
    enum "ButtonClickType" {
        "LeftButtonUp",
        "RightButtonUp",
        "MiddleButtonUp",
        "Button4Up",
        "Button5Up",
        "LeftButtonDown",
        "RightButtonDown",
        "MiddleButtonDown",
        "Button4Down",
        "Button5Down",
        "AnyUp",
        "AnyDown",
    }

    __Sealed__()
    enum "ScriptsType" {
        "OnLoad",
        "OnAttributeChanged",
        "OnSizeChanged",
        "OnEvent",
        "OnUpdate",
        "OnShow",
        "OnHide",
        "OnEnter",
        "OnLeave",
        "OnMouseDown",
        "OnMouseUp",
        "OnMouseWheel",
        "OnJoystickStickMotion",
        "OnJoystickAxisMotion",
        "OnJoystickButtonDown",
        "OnJoystickButtonUp",
        "OnJoystickHatMotion",
        "OnDragStart",
        "OnDragStop",
        "OnReceiveDrag",
        "PreClick",
        "OnClick",
        "PostClick",
        "OnDoubleClick",
        "OnValueChanged",
        "OnMinMaxChanged",
        "OnUpdateModel",
        "OnModelLoaded",
        "OnAnimFinished",
        "OnEnterPressed",
        "OnEscapePressed",
        "OnSpacePressed",
        "OnTabPressed",
        "OnTextChanged",
        "OnTextSet",
        "OnCursorChanged",
        "OnInputLanguageChanged",
        "OnEditFocusGained",
        "OnEditFocusLost",
        "OnHorizontalScroll",
        "OnVerticalScroll",
        "OnScrollRangeChanged",
        "OnCharComposition",
        "OnChar",
        "OnKeyDown",
        "OnKeyUp",
        "OnColorSelect",
        "OnHyperlinkEnter",
        "OnHyperlinkLeave",
        "OnHyperlinkClick",
        "OnMessageScrollChanged",
        "OnMovieFinished",
        "OnMovieShowSubtitle",
        "OnMovieHideSubtitle",
        "OnTooltipSetDefaultAnchor",
        "OnTooltipCleared",
        "OnTooltipAddMoney",
        "OnTooltipSetUnit",
        "OnTooltipSetItem",
        "OnTooltipSetSpell",
        "OnTooltipSetQuest",
        "OnTooltipSetAchievement",
        "OnTooltipSetFramestack",
        "OnTooltipSetEquipmentSet",
        "OnEnable",
        "OnDisable",
        "OnArrowPressed",
        "OnExternalLink",
        "OnButtonUpdate",
        "OnError",
        "OnDressModel",
        "OnCooldownDone",
        "OnPanFinished",
        -- Animation
        "OnPlay",
        "OnPause",
        "OnStop",
        "OnFinished",
        "OnLoop",
    }

    __Sealed__()
    enum "Classes" {
        "WARRIOR",
        "MAGE",
        "ROGUE",
        "DRUID",
        "HUNTER",
        "SHAMAN",
        "PRIEST",
        "WARLOCK",
        "PALADIN",
        "DEATHKNIGHT",
        "MONK",
        "DEMONHUNTER",
    }

    __Sealed__()
    enum "ClassPower" {
        MANA            = 0,
        RAGE            = 1,
        FOCUS           = 2,
        ENERGY          = 3,
        COMBO_POINTS    = 4,
        RUNES           = 5,
        RUNIC_POWER     = 6,
        SOUL_SHARDS     = 7,
        LUNAR_POWER     = 8,
        HOLY_POWER      = 9,
        ALTERNATE_POWER = 10,
        MAELSTROM       = 11,
        CHI             = 12,
        INSANITY        = 13,
        -- OBSOLETE     = 14,
        -- OBSOLETE2    = 15,
        ARCANE_CHARGES  = 16,
        FURY            = 17,
        PAIN            = 18,
    }
end

------------------------------------------------------------
--                   Data Types(UI.xsd)                   --
------------------------------------------------------------
do
    __Sealed__() __Base__(String)
    struct "LocaleString" { }

    __Sealed__() __Base__(PositiveInteger)
    struct "AnimOrderType" {
        function(val) assert(val <= 100, "%s must between 1 and 100.") end
    }

    __Sealed__() __Base__(Number)
    struct "ColorFloat" {
        function (val) assert(val >= 0 and val <= 1, "%s must between 0.0 and 1.0.") end
    }

    __Doc__[[
        The color data, 'Color(r, g, b[, a])' - used to create a color data,
        use obj.r, obj.g, obj.b, obj.a to access the color's part,
        also 'obj .. "text"' can be used to concat values.

        Some special color can be accessed like 'Color.Red', 'Color.Player', 'Color.Mage'
    ]]
    class "Color" (function(_ENV)

        ----------------------------------------------
        ----------------- Sub-Types ------------------
        ----------------------------------------------
        __Sealed__()
        struct "ColorType" {
            { Name = "r",   Type = ColorFloat, Require = true },
            { Name = "g",   Type = ColorFloat, Require = true },
            { Name = "b",   Type = ColorFloat, Require = true },
            { Name = "a",   Type = ColorFloat, Default = 1 },
        }

        ----------------------------------------------
        ---------------- Constructor -----------------
        ----------------------------------------------
        __Arguments__{ ColorType }
        function Color(self, color)
            self.r = color.r
            self.g = color.g
            self.b = color.b
            self.a = color.a
        end

        __Arguments__{
            { Type = ColorFloat, Name = "r"},
            { Type = ColorFloat, Name = "g"},
            { Type = ColorFloat, Name = "b"},
            { Type = ColorFloat, Name = "a", Nilable = true, Default = 1}
        }
        function Color(self, r, g, b, a)
            self.r = r
            self.g = g
            self.b = b
            self.a = a
        end

        ----------------------------------------------
        ----------------- Meta-Method ----------------
        ----------------------------------------------
        function __tostring(self)
            return ("\124c%.2x%.2x%.2x%.2x"):format(self.a * 255, self.r * 255, self.g * 255, self.b * 255)
        end

        function __concat(self, val)
            return tostring(self) .. tostring(val)
        end
    end)

    __Sealed__()
    struct "HSV" {
        { Name = "hue",         Type = Number,      Require = true },
        { Name = "saturation",  Type = ColorFloat,  Require = true },
        { Name = "value",       Type = ColorFloat,  Require = true },

        function (val)
            assert(val.hue >= 0 and val.hue <= 360, "%s.hue must between [0-360].")
        end,
    }

    __Sealed__()
    struct "Dimension" {
        { Name = "x", Type = Number },
        { Name = "y", Type = Number },
    }

    __Sealed__()
    struct "Position" {
        { Name = "x", Type = Number },
        { Name = "y", Type = Number },
        { Name = "z", Type = Number },
    }

    __Sealed__()
    struct "Size" {
        { Name = "width",   Type = Number },
        { Name = "height",  Type = Number },
    }

    __Sealed__()
    struct "MinMax" {
        { Name = "min", Type = Number, Require = true },
        { Name = "max", Type = Number, Require = true },

        function(val)
            assert(value.min <= value.max, "%s.min can't be greater than %s.max.")
        end,
    }

    __Sealed__()
    struct "Inset" {
        { Name = "left",    Type = Number },
        { Name = "right",   Type = Number },
        { Name = "top",     Type = Number },
        { Name = "bottom",  Type = Number },
    }

    __Sealed__()
    struct "ShadowType" {
        { Name = "Color",   Type = Color },
        { Name = "Offset",  Type = Dimension },
    }

    __Sealed__()
    struct "GradientType" {
        { Name = "orientation", Type = Orientation },
        { Name = "MinColor",    Type = Color },
        { Name = "MaxColor",    Type = Color },
    }

    __Sealed__()
    struct "FontType" {
        { Name = "font",        Type = String },
        { Name = "height",      Type = Number },
        { Name = "outline",     Type = OutlineType },
        { Name = "monochrome",  Type = Boolean },
    }

    __Sealed__()
    struct "BackdropType" {
        { Name = "bgFile",          Type = String },
        { Name = "edgeFile",        Type = String },
        { Name = "tile",            Type = Boolean },
        { Name = "tileSize",        Type = Number },
        { Name = "edgeSize",        Type = Number },
        { Name = "insets",          Type = Inset },
    }

    __Sealed__()
    struct "Anchor" {
        { Name = "point",           Type = FramePoint, Require = true },
        { Name = "x",               Type = NumberNil },
        { Name = "y",               Type = NumberNil },
        { Name = "relativeTo",      Type = String },
        { Name = "relativePoint",   Type = FramePoint },
    }

    __Sealed__()
    struct "Anchors" { Anchor }

    __Sealed__()
    struct "TexCoord" {
        { Name = "ULx",     Type = NumberNil },
        { Name = "ULy",     Type = NumberNil },
        { Name = "LLx",     Type = NumberNil },
        { Name = "LLy",     Type = NumberNil },
        { Name = "URx",     Type = NumberNil },
        { Name = "URy",     Type = NumberNil },
        { Name = "LRx",     Type = NumberNil },
        { Name = "LRy",     Type = NumberNil },
    }

    __Sealed__()
    struct "TexCoords" { TexCoord }

    __Sealed__()
    struct "AnimOriginType" {
        { Name = "point",   Type = FramePoint, Default = "CENTER" },
        { Name = "x",       Type = NumberNil },
        { Name = "y",       Type = NumberNil },
    }

    __Sealed__()
    struct "LightType" {
        { Name = "enabled",     Type = Boolean },
        { Name = "omni",        Type = Boolean },
        { Name = "dir",         Type = Position },
        { Name = "ambIntensity",Type = ColorFloat },
        { Name = "ambColor",    Type = Color },
        { Name = "dirIntensity",Type = ColorFloat },
        { Name = "dirColor",    Type = Color },
    }
end

------------------------------------------------------------
--                    Special Colors                      --
------------------------------------------------------------
do
    __Sealed__()
    class "Color" (function(_ENV)
        ----------------------------------------------
        -------------- Static Property ---------------
        ----------------------------------------------
        __Doc__[[The close tag to close color text]]
        __Static__() property "CLOSE"           { Set = false, Default = "|r" }

        ------------------ Classes ------------------
        __Doc__[[The Hunter class's default color]]
        __Static__() property "HUNTER"          { Set = false, Default = Color(0.67, 0.83, 0.45) }

        __Doc__[[The Warlock class's default color]]
        __Static__() property "WARLOCK"         { Set = false, Default = Color(0.53, 0.53, 0.93) }

        __Doc__[[The Priest class's default color]]
        __Static__() property "PRIEST"          { Set = false, Default = Color(1.00, 1.00, 1.00) }

        __Doc__[[The Paladin class's default color]]
        __Static__() property "PALADIN"         { Set = false, Default = Color(0.96, 0.55, 0.73) }

        __Doc__[[The Mage class's default color]]
        __Static__() property "MAGE"            { Set = false, Default = Color(0.25, 0.78, 0.92) }

        __Doc__[[The Rogue class's default color]]
        __Static__() property "ROGUE"           { Set = false, Default = Color(1.00, 0.96, 0.41) }

        __Doc__[[The Druid class's default color]]
        __Static__() property "DRUID"           { Set = false, Default = Color(1.00, 0.49, 0.04) }

        __Doc__[[The Shaman class's default color]]
        __Static__() property "SHAMAN"          { Set = false, Default = Color(0.00, 0.44, 0.87) }

        __Doc__[[The Warrior class's default color]]
        __Static__() property "WARRIOR"         { Set = false, Default = Color(0.78, 0.61, 0.43) }

        __Doc__[[The Deathknight class's default color]]
        __Static__() property "DEATHKNIGHT"     { Set = false, Default = Color(0.77, 0.12, 0.23) }

        __Doc__[[The Monk class's default color]]
        __Static__() property "MONK"            { Set = false, Default = Color(0.00, 1.00, 0.59) }

        __Doc__[[The Demonhunter class's default color]]
        __Static__() property "DEMONHUNTER"     { Set = false, Default = Color(0.64, 0.19, 0.79) }

        ------------------ Powers -------------------
        __Doc__[[The mana's default color]]
        __Static__() property "MANA"            { Set = false, Default = Color(0.00, 0.00, 1.00) }

        __Doc__[[The rage's default color]]
        __Static__() property "RAGE"            { Set = false, Default = Color(1.00, 0.00, 0.00) }

        __Doc__[[The focus's default color]]
        __Static__() property "FOCUS"           { Set = false, Default = Color(1.00, 0.50, 0.25) }

        __Doc__[[The energy's default color]]
        __Static__() property "ENERGY"          { Set = false, Default = Color(1.00, 1.00, 0.00) }

        __Doc__[[The combo_points's default color]]
        __Static__() property "COMBO_POINTS"    { Set = false, Default = Color(1.00, 0.96, 0.41) }

        __Doc__[[The runes's default color]]
        __Static__() property "RUNES"           { Set = false, Default = Color(0.50, 0.50, 0.50) }

        __Doc__[[The runic_power's default color]]
        __Static__() property "RUNIC_POWER"     { Set = false, Default = Color(0.00, 0.82, 1.00) }

        __Doc__[[The soul_shards's default color]]
        __Static__() property "SOUL_SHARDS"     { Set = false, Default = Color(0.50, 0.32, 0.55) }

        __Doc__[[The lunar_power's default color]]
        __Static__() property "LUNAR_POWER"     { Set = false, Default = Color(0.30, 0.52, 0.90) }

        __Doc__[[The holy_power's default color]]
        __Static__() property "HOLY_POWER"      { Set = false, Default = Color(0.95, 0.90, 0.60) }

        __Doc__[[The maelstrom's default color]]
        __Static__() property "MAELSTROM"       { Set = false, Default = Color(0.00, 0.50, 1.00) }

        __Doc__[[The insanity's default color]]
        __Static__() property "INSANITY"        { Set = false, Default = Color(0.40, 0.00, 0.80) }

        __Doc__[[The chi's default color]]
        __Static__() property "CHI"             { Set = false, Default = Color(0.71, 1.00, 0.92) }

        __Doc__[[The arcane_charges's default color]]
        __Static__() property "ARCANE_CHARGES"  { Set = false, Default = Color(0.10, 0.10, 0.98) }

        __Doc__[[The fury's default color]]
        __Static__() property "FURY"            { Set = false, Default = Color(0.79, 0.26, 0.99) }

        __Doc__[[The pain's default color]]
        __Static__() property "PAIN"            { Set = false, Default = Color(1.00, 0.61, 0.00) }

        __Doc__[[The stagger's default color]]
        __Static__() property "STAGGER"         { Set = false, Default = Color(0.52, 1.00, 0.52) }

        __Doc__[[The stagger's warnning color]]
        __Static__() property "STAGGER_WARN"    { Set = false, Default = Color(1.00, 0.98, 0.72) }

        __Doc__[[The stagger's dangerous color]]
        __Static__() property "STAGGER_DYING"   { Set = false, Default = Color(1.00, 0.42, 0.42) }

        ------------------ Vehicle ------------------
        __Doc__[[The ammoslot's default color]]
        __Static__() property "AMMOSLOT"        { Set = false, Default = Color(0.80, 0.60, 0.00) }

        __Doc__[[The fuel's default color]]
        __Static__() property "FUEL"            { Set = false, Default = Color(0.00, 0.55, 0.50) }

        --------------- Item quality ----------------
        __Doc__[[The common quality's default color]]
        __Static__() property "COMMON"          { Set = false, Default = Color(0.66, 0.66, 0.66) }

        __Doc__[[The uncommon quality's default color]]
        __Static__() property "UNCOMMON"        { Set = false, Default = Color(0.08, 0.70, 0.00) }

        __Doc__[[The rare quality's default color]]
        __Static__() property "RARE"            { Set = false, Default = Color(0.00, 0.57, 0.95) }

        __Doc__[[The epic quality's default color]]
        __Static__() property "EPIC"            { Set = false, Default = Color(0.78, 0.27, 0.98) }

        __Doc__[[The legendary quality's default color]]
        __Static__() property "LEGENDARY"       { Set = false, Default = Color(1.00, 0.50, 0.00) }

        __Doc__[[The artifact quality's default color]]
        __Static__() property "ARTIFACT"        { Set = false, Default = Color(0.90, 0.80, 0.50) }

        __Doc__[[The heirloom quality's default color]]
        __Static__() property "HEIRLOOM"        { Set = false, Default = Color(0.00, 0.80, 1.00) }

        __Doc__[[The wow_token quality's default color]]
        __Static__() property "WOWTOKEN"        { Set = false, Default = Color(0.00, 0.80, 1.00) }

        --------------- Common Color ----------------
        __Doc__[[The magic debuff's default color]]
        __Static__() property "MAGIC"           { Set = false, Default = Color(0.20, 0.60, 1.00) }

        __Doc__[[The curse debuff's default color]]
        __Static__() property "CURSE"           { Set = false, Default = Color(0.60, 0.00, 1.00) }

        __Doc__[[The disease debuff's default color]]
        __Static__() property "DISEASE"         { Set = false, Default = Color(0.60, 0.40, 0.00) }

        __Doc__[[The poison debuff's default color]]
        __Static__() property "POISON"          { Set = false, Default = Color(0.00, 0.60, 0.00) }


        --------------- Common Color ----------------
        __Doc__[[The red color]]
        __Static__() property "RED"             { Set = false, Default = Color(1.00, 0.10, 0.10) }

        __Doc__[[The green color]]
        __Static__() property "GREEN"           { Set = false, Default = Color(0.10, 1.00, 0.10) }

        __Doc__[[The gray color]]
        __Static__() property "GRAY"            { Set = false, Default = Color(0.50, 0.50, 0.50) }

        __Doc__[[The yellow color]]
        __Static__() property "YELLOW"          { Set = false, Default = Color(1.00, 1.00, 0.00) }

        __Doc__[[The light yellow color]]
        __Static__() property "LIGHTYELLOW"     { Set = false, Default = Color(1.00, 1.00, 0.60) }

        __Doc__[[The orange color]]
        __Static__() property "ORANGE"          { Set = false, Default = Color(1.00, 0.50, 0.25) }
    end)

    -- Add PLAYER Class Color
    __Doc__[[The player's default color]]
    Color.PLAYER = { Set = false, Default = Color[(select(2, UnitClass("player")))], Static = true }
end

------------------------------------------------------------
--                       UI Helper                        --
------------------------------------------------------------
do
    UI_BLOCKED_METHODS = {
        GetScript               = true,
        SetScript               = true,
        HookScript              = true,
        HasScript               = true,

        CreateAnimation         = true,
        CreateAnimationGroup    = true,
        CreateControlPoint      = true,
        CreateFontString        = true,
        CreateTexture           = true,
        CreateLine              = true,

        GetAnimations           = true,
        GetAnimationGroups      = true,
        GetControlPoints        = true,
        GetChildren             = true,
        GetRegions              = true,

        RegisterEvent           = true,
        IsEventRegistered       = true,
        UnregisterAllEvents     = true,
        UnregisterEvent         = true,
        RegisterUnitEvent       = true,
        RegisterAllEvents       = true,
    }

    UI_BLOCKED_EVENTS = {
        OnEvent                 = true,
        OnUpdate                = true,
    }

    UI_PROTOTYPE = {}

    UI_USERPLACED = setmetatable({}, META_WEAKKEY)

    function OnEventHandlerChanged(handler)
        local name = handler.Event
        local self = handler.Owner

        local _UI = self.UIElement
        if type(_UI) ~= "table" or _UI == self or type(_UI.HasScript) ~= "function" or not _UI:HasScript(name) then
            return
        end

        self.__UI_WidgetEvent = self.__UI_WidgetEvent or {}

        if handler:IsEmpty() then
            -- UnRegister
            if _UI:GetScript(name) == self.__UI_WidgetEvent[name] then
                _UI:SetScript(name, nil)
            end
        else
            if not self.__UI_WidgetEvent[name] then
                self.__UI_WidgetEvent[name] = function(self, ...) return handler(...) end
            end

            -- Register
            if not _UI:GetScript(name) then
                _UI:SetScript(name, self.__UI_WidgetEvent[name])
            elseif _UI:GetScript(name) ~= self.__UI_WidgetEvent[name] then
                if not self.__UI_WidgetEvent["Hooked_" .. name] then
                    self.__UI_WidgetEvent["Hooked_" .. name] = true
                    _UI:HookScript(name, self.__UI_WidgetEvent[name])
                end
            end
        end
    end

    function InstallPrototype(ptype, ctor, isFont)
        local clsEnv    = getfenv(2)
        local baseCls   = Reflector.GetSuperClass(clsEnv.__PLOOP_OWNER) -- A little trick
        local baseType  = baseCls and Reflector.GetNameSpaceName(baseCls)
        local frameType = Reflector.GetNameSpaceName(clsEnv.__PLOOP_OWNER)
        local prototype

        if ptype then
            if ctor then
                prototype = ctor(nil, frameType, UI_PROTOTYPE[ptype])
            else
                prototype = CreateFrame(frameType, nil, UI_PROTOTYPE[ptype])
            end
        else
            prototype = CreateFrame(frameType)
        end

        if prototype.Hide then prototype:Hide() end
        UI_PROTOTYPE[frameType] = prototype

        -- Install Events
        if type(prototype.HasScript) == "function" then
            for _, evt in Reflector.GetEnums(ScriptsType) do
                if not UI_BLOCKED_EVENTS[evt] and prototype:HasScript(evt) and (not baseCls or not Reflector.HasEvent(baseCls, evt)) then
                    __EventChangeHandler__(OnEventHandlerChanged)
                    clsEnv.event(evt)
                end
            end
        end

        -- Install Methods
        for name, func in pairs(getmetatable(prototype).__index) do
            if UI_BLOCKED_METHODS[name] then
                -- Pass
            elseif isFont and IFont[name] then
                -- Pass
            elseif baseCls and baseCls[name] then
                if UI_PROTOTYPE[baseType] and UI_PROTOTYPE[baseType][name] == baseCls[name] then
                    if baseCls[name] ~= func then
                        clsEnv[name] = func
                    end
                end
            else
                clsEnv[name] = func
            end
        end

        -- Install CreateUIElement
        clsEnv.CreateUIElement = ctor or function(self, name, parent, ...)
            return CreateFrame(frameType, nil, parent, ...)
        end
    end

    function LoadFrameData(self)
        if _SVData and UI_USERPLACED[self] ~= nil then
            local uname = self:GetUniqueName()
            if uname then
                local data
                if UI_USERPLACED[self] then
                    data = _SVData.Char.LayoutCache[uname]
                else
                    data = _SVData.LayoutCache[uname]
                end

                if data then
                    if data.Size then self.Size = data.Size end
                    if data.Location then self.Location = data.Location end
                end
            end
        end
    end
end

------------------------------------------------------------
--                           UI                           --
------------------------------------------------------------
__Doc__[[The abstract root UI class]]
__Sealed__() __Abstract__() __ObjMethodAttr__{ Inheritable = true }
class (UI) (function(_ENV)

    _UIWrapperMap = setmetatable({}, META_WEAKKEY)

    ----------------------------------------------
    ---------------- Static-Method ---------------
    ----------------------------------------------
    __Doc__[[Get the wrapped object of ui element]]
    __Static__() function GetUIWrapper(element)
        if type(element) == "string" then element = _G[element] end
        if type(element) ~= "table" then return nil end

        -- Check if it's a wrapper
        if IsClass(element, UI) then return element end

        -- Check if its wrapper existed
        local wrapper = _UIWrapperMap[element]
        if wrapper then return wrapper end

        -- Make a new wrapper for it
        if type(element[0]) ~= "userdata" or type(element.GetObjectType) ~= "function" then return nil end

        local frameType = element:GetObjectType()
        if frameType then return UI[frameType](element) end

        return nil
    end

    __Doc__[[Get the ui object for the unique name]]
    __Static__() function GetUniqueObject(name)
        local obj

        if type(name) ~= "string" then return end

        for str in name:gmatch("[^%.]+") do
            if not obj then
                obj = GetUIWrapper(str)
            else
                obj = obj.Children[str]
            end
            if not obj then return nil end
        end

        return obj
    end

    ----------------------------------------------
    -------------- ----- Method -------------------
    ----------------------------------------------
    __Doc__[[The method used to create the wow ui element, need to be overridden by widget-classes.]]
    function CreateUIElement(self, ...) end

    __Doc__[[Whether the object is an instance of the class]]
    IsClass = Reflector.ObjectIsClass

    __Doc__[[Whether the object is an instance of the interface]]
    IsInterface = Reflector.ObjectIsInterface

    __Doc__[[Get the class of the object]]
    GetClass = Reflector.GetObjectClass

    __Doc__[[Set the ui object's parent]]
    function SetParent(self, parent)
        parent = GetUIWrapper(parent)

        local oparent = self:GetParent()

        if oparent == parent then return end

        local name = self:GetName()

        if parent == nil then
            if oparent and oparent.Children[name] == self then
                oparent.Children[name] = nil
            end

            return self.UIElement:SetParent(nil)
        end

        if parent.Children[name] and parent.Children[name] ~= self then
            error("Usage : UI:SetParent([parent]) : parent has another child with the same name.", 2)
        end

        if oparent and oparent.Children[name] == self then
            oparent.Children[name] = nil
        end

        self.UIElement:SetParent(parent.UIElement)

        parent.Children[name] = self
    end

    __Doc__[[Get the ui object's parent]]
    function GetParent(self)
        return GetUIWrapper(self.UIElement:GetParent())
    end

    __Doc__[[Set the ui object's name]]
    __Arguments__{ NEString }
    function SetName(self, name)
        local parent = self:GetParent()
        local oname = self.__UI_Name

        if oname == name then return end

        if parent then
            if parent.Children[name] then
                error("Usage: UI:SetName(name) - the name is used by another child.", 2)
            end

            parent.Children[oname] = nil
            parent.Children[name] = self
        end

        self.__UI_Name = name
    end

    __Doc__[[Get the ui object's name]]
    function GetName(self)
        return self.__UI_Name
    end

    __Doc__[[Get the ui object's unique access name]]
    function GetUniqueName(self)
        local uname

        while self do
            local globalName = self.UIElement:GetName()

            if globalName then
                -- The root is UIParent
                if uname then
                    return globalName .. "." .. uname
                else
                    return globalName
                end
            end

            if uname then
                uname = self:GetName() .. "." .. uname
            else
                uname = self:GetName()
            end

            self = self:GetParent()
        end

        -- No return since we can't identify it in next session
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The ui element controlled by the ui object]]
    property "UIElement" { Field = "__UI_Element", Set = false }

    __Doc__[[The Children of the ui object]]
    property "Children" { Field = "__UI_Children", Set = false, Default = function() return Dictionary() end }

    __Doc__[[The name of the ui object]]
    property "Name" { Type = NEString, Set = "SetName", Get = "GetName" }

    __Doc__[[The parent of the ui object]]
    property "Parent" { Type = UI, Set = "SetParent", Get = "GetParent" }

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        local name = self:GetName()

        self:SetParent(nil)

        -- Dispose the children
        if self.__UI_Children then
            for _, obj in pairs(self.__UI_Children) do obj:Dispose() end
        end

        -- Clear it from the _G
        if name and _G[name] and (_G[name] == self or _G[name] == self.UIElement) then
            _G[name] = nil
        end

        self.__UI_Children = nil
        self.__UI_Element = nil
    end

    ----------------------------------------------
    ---------------- Constructor -----------------
    ----------------------------------------------
    __Arguments__{ RawTable }
    function UI(self, init)
        local name = init.Name
        local parent = GetUIWrapper(init.Parent or UIParent)

        if not name or not parent then
            error("No name and parent found in the init table")
        end

        if Reflector.IsSuperClass(getmetatable(self), LayeredRegion) then
            This(self, name, parent, init.DrawLayer or "ARTWORK", init.Template, init.SubLevel or 0)
            init.DrawLayer = nil
            init.SubLevel = nil
        else
            This(self, name, parent, init.Template)
        end
        init.Name = nil
        init.Parent = nil
        init.Template = nil

        return self(init)
    end

    __Arguments__{ Table }
    function UI(self, element)
        self.__UI_Element = element
        self[0] = element[0]
        _UIWrapperMap[element] = self

        self.__UI_Name = element:GetName()
    end

    __Arguments__{ NEString, Table, { IsList = true, Nilable = true } }
    function UI(self, name, parent, ...)
        parent = GetUIWrapper(parent)

        if parent.Children[name] then
            error(("Usage : %s(name, parent, ...) : parent already has a child named '%s'."):format(Reflector.GetNameSpaceName(getmetatable(self)), name))
        end

        local element = self:CreateUIElement(name, parent.UIElement, ...)

        self.__UI_Element = element
        self[0] = element[0]
        _UIWrapperMap[element] = self

        parent.Children[name] = self
        self.__UI_Name = name
    end

    __Arguments__{ NEString, { IsList = true, Nilable = true } }
    function UI(self, name, ...) return This(self, name, UIParent, ...) end

    ----------------------------------------------
    ----------------- Meta-Method ----------------
    ----------------------------------------------
    __Arguments__{ RawTable }
    function __exist(self, init)
        local name = init.Name
        local parent = GetUIWrapper(init.Parent or UIParent)

        if name and parent then
            return parent.Children[name]
        end
    end

    __Arguments__{ Table }
    function __exist(element)
        if IsClass(element, UI) then return element end
        return _UIWrapperMap[element]
    end

    __Arguments__{ NEString, Table, { IsList = true, Nilable = true }}
    function __exist(name, parent, ...)
        parent = GetUIWrapper(parent)
        if rawget(parent, "__UI_Children") then return parent.__UI_Children[name] end
    end

    __Arguments__{ NEString, { IsList = true, Nilable = true } }
    function __exist(name, ...)
        local parent = GetUIWrapper(UIParent)
        if rawget(parent, "__UI_Children") then return parent.__UI_Children[name] end
    end

    function __index(self, child)
        if rawget(self, "__UI_Children") then return self.__UI_Children[child] end
    end

    __Arguments__{ RawTable }
    function __call(self, init)
        local children = init.Children

        if children then init.Children = nil end

        for k, v in pairs(init) do
            self[k] = v
        end

        if children then
            for _, cinit in ipairs(children) do
                if not Reflector.IsClass(cinit.Type) then
                    error("The children's Type is not class", 2)
                end

                if type(cinit.Name) ~= "string" then
                    error("The children's Name must be a string", 2)
                end

                local child = self.Children[cinit.Name]

                if child then
                    if getmetatable(child) ~= cinit.Type then
                        error(("The %q is used by another child of other type"):format(cinit.Name), 2)
                    end
                    cinit.Type = nil
                    cinit.Name = nil
                    cinit.Template = nil
                else
                    if Reflector.IsSuperClass(cinit.Type, LayeredRegion) then
                        child = cinit.Type(cinit.Name, self, cinit.DrawLayer or "ARTWORK", cinit.Template, cinit.SubLevel or 0)
                        cinit.DrawLayer = nil
                        cinit.SubLevel = nil
                    else
                        child = cinit.Type(cinit.Name, self, cinit.Template)
                    end
                    cinit.Type = nil
                    cinit.Name = nil
                    cinit.Template = nil
                end

                child(cinit)
            end
        end
    end
end)

------------------------------------------------------------
--                         Region                         --
------------------------------------------------------------
__Doc__[[Region is the basic type for anything that can occupy an area of the screen. As such, Frames, Textures and FontStrings are all various kinds of Region. Region provides most of the functions that support size, position and anchoring, including animation.]]
__Sealed__() __Abstract__()
class "Region" (function(_ENV)
    inherit "UI"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local function GetPos(frame, point)
        local e = frame:GetEffectiveScale()/UIParent:GetScale()
        local x, y = frame:GetCenter()

        if strfind(point, "TOP") then
            y = frame:GetTop()
        elseif strfind(point, "BOTTOM") then
            y = frame:GetBottom()
        end

        if strfind(point, "LEFT") then
            x = frame:GetLeft()
        elseif strfind(point, "RIGHT") then
            x = frame:GetRight()
        end

        return x * e, y * e
    end

    ----------------------------------------------
    -------------------- Event -------------------
    ----------------------------------------------
    __Doc__[[Run when the region object's location is changed]]
    event "OnLocationChanged"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function GetPoint(self, pointNum)
        local point, frame, relativePoint, x, y = self.UIElement:GetPoint(pointNum)
        return point, UI.GetUIWrapper(frame), relativePoint, x, y
    end

    __Doc__[[
        Get the region object's location(Type: Anchors), the data is serializable, can be saved directly.
        You can also apply a data of Anchors to get a location based on the data's point, relativeTo and relativePoint settings.
    ]]
    __Arguments__{ }
    function GetLocation(self)
        local loc = {}
        local parent = self:GetParent()

        for i = 1, self:GetNumPoints() do
            local point, relativeTo, relativePoint, x, y = self:GetPoint(i)

            relativeTo = relativeTo or parent
            if relativeTo == parent then
                -- Don't save parent
                relativeTo = nil
            elseif parent and relativeTo:GetParent() == parent then
                -- Save the brother's name
                relativeTo = relativeTo:GetName()
            else
                local uname = relativeTo:GetUniqueName()

                if not uname then
                    error("Usage: Region:GetLocation() - The System can't identify the relativeTo frame.", 2)
                end

                relativeTo = uname
            end

            if relativePoint == point then
                relativePoint = nil
            end

            if x == 0 then x = nil end
            if y == 0 then y = nil end

            loc[i] = Anchor(point, x, y, relativeTo, relativePoint)
        end

        return loc
    end

    __Arguments__{ Anchors }
    function GetLocation(self, oLoc)
        local loc = {}
        local parent = self:GetParent()

        for i, anchor in ipairs(oLoc) do
            local relativeTo = anchor.relativeTo
            local relativeFrame

            if relativeTo then
                relativeFrame = parent and parent.Children[relativeTo] or UI.GetUniqueObject(relativeTo)

                if not relativeFrame then
                    error("Usage: Region:GetLocation(accordingLoc) - The System can't identify the relativeTo frame.", 2)
                end
            else
                relativeFrame = parent
            end

            if relativeFrame then
                local e = self:GetEffectiveScale()
                local ep = UIParent:GetScale()
                local x, y = GetPos(self, anchor.point)
                local rx, ry = GetPos(relativeFrame, anchor.relativePoint or anchor.point)

                tinsert(loc, Anchor(anchor.point, (x-rx)*ep/e, (y-ry)*ep/e, relativeTo, anchor.relativePoint or anchor.point))
            end
        end

        return loc
    end

    __Doc__[[Set the region object's location]]
    function SetLocation(self, loc)
        if #loc > 0 then
            local parent = self:GetParent()

            self:ClearAllPoints()
            for _, anchor in ipairs(loc) do
                local relativeTo = anchor.relativeTo

                if relativeTo then
                    relativeTo = parent and parent.Children[relativeTo] or UI.GetUniqueObject(relativeTo)

                    if not relativeTo then
                        error("Usage: Region:SetLocation(loc) - The System can't identify the relativeTo frame.", 2)
                    end
                else
                    relativeTo = parent
                end

                if relativeTo then
                    self:SetPoint(anchor.point, relativeTo, anchor.relativePoint or anchor.point, anchor.x or 0, anchor.y or 0)
                end
            end

            return OnLocationChanged(self)
        end
    end

    __Doc__[[
        <desc>Sets whether the frame's location and size is saved and load automatically</desc>
        <param name="userplaced" type="Boolean">whether the frame's location and size is saved and load automatically</param>
        <param name="characterOnly" type="Boolean">whether the location and size is saved character only</param>
    ]]
    function SetUserPlaced(self, userplaced, characterOnly)
        if userplaced then
            UI_USERPLACED[self] = characterOnly and true or false

            -- Load the datas from the previous session
            return LoadFrameData[self]
        else
            UI_USERPLACED[self] = nil
        end
    end

    __Doc__[[Gets whether the frame's location and size is saved and load automatically]]
    function IsUserPlaced(self)
        return UI_USERPLACED[self] ~= nil
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the frame's transparency value(0-1)]]
    property "Alpha" {
        Type = ColorFloat,
        Get = function(self) return self:GetAlpha() end,
        Set = function(self, alpha) self:SetAlpha(alpha) end,
    }

    __Doc__[[The distance from the bottom of the screen to the bottom of the region]]
    property "Bottom" { Set = false, Get = function(self) return self:GetBottom() end }

    __Doc__[[The screen coordinates of the region's center]]
    property "Center" { Set = false, Get = function(self) return Dimension(self:GetCenter()) end }

    __Doc__[[the height of the region]]
    property "Height" {
        Type = PositiveNumber,
        Get = function(self) return self:GetHeight() end,
        Set = function(self, height) self:SetHeight(height) end,
    }

    __Doc__[[The distance from the left edge of the screen to the left edge of the region]]
    property "Left" { Set = false, Get = function(self) return self:GetLeft() end }

    __Doc__[[the location of the region]]
    property "Location" {
        Type = Anchors,
        Get = "GetLocation",
        Set = "SetLocation",
    }

    __Doc__[[The distance from the left edge of the screen to the right edge of the region]]
    property "Right" { Set = false, Get = function(self) return self:GetRight() end }

    __Doc__[[The size of the region]]
    property "Size" {
        Type = Size,
        Get = function(self) return Size(self:GetSize()) end,
        Set = function(self, size) self:SetSize(size.width, size.height) end,
    }

    __Doc__[[The distance from the bottom of the screen to the top of the region]]
    property "Top" { Set = false, Get = function(self) return self:GetTop() end }

    __Doc__[[Whether the frame's size and location is saved for account]]
    property "UserPlaced" {
        Type = Boolean,
        Get = function(self) return UI_USERPLACED[self] ~= nil end,
        Set = function(self, val)
            if val then
                return self:SetUserPlaced(true, false)
            else
                return self:SetUserPlaced(false)
            end
        end,
    }

    __Doc__[[Whether the frame's size and location is saved character only]]
    property "UserPlacedCharacterOnly" {
        Type = Boolean,
        Get = function(self) return UI_USERPLACED[self] end,
        Set = function(self, val)
            if val then
                return self:SetUserPlaced(true, true)
            else
                return self:SetUserPlaced(false)
            end
        end,
    }

    __Doc__[[wheter the region is shown or not.]]
    property "Visible" {
        Type = Boolean,
        Get = function(self) return self:IsShown() and true or false end,
        Set = function(self, visible) self[visible and "Show" or "Hide"](self) end,
    }

    __Doc__[[the width of the region]]
    property "Width" {
        Type = PositiveNumber,
        Get = function(self) return self:GetWidth() end,
        Set = function(self, width) self:SetWidth(width) end,
    }

    ----------------------------------------------
    ------------------ Dispose -------------------
    ----------------------------------------------
    function Dispose(self)
        self:SetUserPlaced(false)
        self:ClearAllPoints()
        self:Hide()
    end

    ----------------------------------------------
    ----------------- Meta-Method ----------------
    ----------------------------------------------
    __Arguments__{ RawTable }
    function __call(self, init)
        local isUserPlaced = init.UserPlaced
        local isUserPlacedCharacter = init.UserPlacedCharacterOnly

        init.UserPlaced = nil
        init.UserPlacedCharacterOnly = nil

        Super.__call(self, init)

        if isUserPlacedCharacter then
            self:SetUserPlaced(true, true)
        elseif isUserPlaced then
            self:SetUserPlaced(true)
        else
            self:SetUserPlaced(false)
        end
    end
end)

------------------------------------------------------------
--                      LayeredRegion                     --
------------------------------------------------------------
__Doc__[[LayeredRegion is an abstract UI type that groups together the functionality of layered graphical regions, specifically Textures and FontStrings.]]
__Sealed__() __Abstract__()
class "LayeredRegion" (function(_ENV)
    inherit "Region"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Sets a color shading for the region's graphics.</desc>
        <param name="red">number, red component of the color (0.0 - 1.0)</param>
        <param name="green">number, green component of the color (0.0 - 1.0)</param>
        <param name="blue">number, blue component of the color (0.0 - 1.0)</param>
        <param name="alpha">number, alpha (opacity) for the graphic (0.0 = fully transparent, 1.0 = fully opaque)</param>
    ]]
    function SetVertexColor(self, r, g, b, a)
        self.__LayeredRegion_VertexColorR = r
        self.__LayeredRegion_VertexColorG = g
        self.__LayeredRegion_VertexColorB = b
        self.__LayeredRegion_VertexColorA = a

        return self.UIElement:SetVertexColor(r, g, b, a)
    end

    __Doc__[[
        <desc>Gets a color shading for the region's graphics.</desc>
        <return type="red">number, red component of the color (0.0 - 1.0)</return>
        <return type="green">number, green component of the color (0.0 - 1.0)</return>
        <return type="blue">number, blue component of the color (0.0 - 1.0)</return>
        <return type="alpha">number, alpha (opacity) for the graphic (0.0 = fully transparent, 1.0 = fully opaque)</return>
    ]]
    function GetVertexColor(self)
        return self.__LayeredRegion_VertexColorR,
                self.__LayeredRegion_VertexColorG,
                self.__LayeredRegion_VertexColorB,
                self.__LayeredRegion_VertexColorA
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the layer at which the region's graphics are drawn relative to others in its frame]]
    property "DrawLayer" {
        Type = DrawLayer,
        Get = function(self) return self:GetDrawLayer() end,
        Set = function(self, layer) return self:SetDrawLayer(layer) end,
    }

    __Doc__[[the color shading for the region's graphics]]
    property "VertexColor" {
        Type = Color,
        Get = function(self) return Color(self:GetVertexColor()) end,
        Set = function(self, color) self:SetVertexColor(color.r, color.g, color.b, color.a) end,
    }
end)

------------------------------------------------------------
--                         IFont                          --
------------------------------------------------------------
__Doc__[[The interface for the font frames like FontString, SimpleHTML and etc.]]
__Sealed__()
interface "IFont" (function(_ENV)

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the font settings]]
    property "Font" {
        Type = FontType,
        Get = function(self)
            local filename, fontHeight, flags = self:GetFont()
            local outline, monochrome = "NONE", false
            if flags then
                if flags:find("THICKOUTLINE") then
                    outline = "THICK"
                elseif flags:find("OUTLINE") then
                    outline = "NORMAL"
                end
                if flags:find("MONOCHROME") then
                    monochrome = true
                end
            end
            return FontType(filename, fontHeight, outline, monochrome)
        end,
        Set = function(self, font)
            local flags

            if font.outline then
                if font.outline == "NORMAL" then
                    flags = "OUTLINE"
                elseif font.outline == "THICK" then
                    flags = "THICKOUTLINE"
                end
            end
            if font.monochrome then
                if flags then
                    flags = flags..",MONOCHROME"
                else
                    flags = "MONOCHROME"
                end
            end
            return self:SetFont(font.font, font.height, flags)
        end,
    }

    __Doc__[[the Font object]]
    property "FontObject" {
        Get = function(self) return self:GetFontObject() end,
        Set = function(self, fontObject) self:SetFontObject(fontObject) end,
    }

    __Doc__[[The font path]]
    property "FontPath" {
        Type = NEString,
        Get = function(self) return (self:GetFont()) end,
        Set = function(self, val)
            local _, fontHeight, flags = self:GetFont()
            return self:SetFont(val, fontHeight, flags)
        end,
    }

    __Doc__[[The font height]]
    property "FontHeight" {
        Type = PositiveNumber,
        Get = function(self)
            local _, fontHeight = self:GetFont()
            return fontHeight
        end,
        Set = function(self, height)
            local filename, fontHeight, flags = self:GetFont()
            return self:SetFont(filename, height, flags)
        end,
    }

    __Doc__[[The font's outline setting]]
    property "Outline" {
        Type = OutlineType,
        Get = function(self)
            local _, _, flags = self:GetFont()

            if flags then
                if flags:find("THICKOUTLINE") then
                    return "THICK"
                elseif flags:find("OUTLINE") then
                    return "NORMAL"
                end
            end

            return "NONE"
        end,
        Set = function(self, val)
            local filename, fontHeight, oflags = self:GetFont()
            local flags

            if val == "NORMAL" then
                flags = "OUTLINE"
            elseif val == "THICK" then
                flags = "THICKOUTLINE"
            end

            if oflags and oflags:find("MONOCHROME") then
                if flags then
                    flags = flags..",MONOCHROME"
                else
                    flags = "MONOCHROME"
                end
            end
            return self:SetFont(filename, fontHeight, flags)
        end,
    }

    __Doc__[[The Font's monochrome setting]]
    property "Monochrome" {
        Type = Boolean,
        Get = function(self)
            local _, _, flags = self:GetFont()

            if flags:find("MONOCHROME") then
                return true
            else
                return false
            end
        end,
        Set = function(self, val)
            local filename, fontHeight, flags = self:GetFont()

            if flags then
                if val and not flags:find("MONOCHROME") then
                    flags = flags .. ",MONOCHROME"
                elseif not val then
                    flags = flags:gsub("%s*,?%s*MONOCHROME%s*,?%s*", "")
                end
            else
                flags = val and "MONOCHROME" or ""
            end

            return self:SetFont(filename, fontHeight, flags)
        end,
    }

    __Doc__[[the fontstring's horizontal text alignment style]]
    property "JustifyH" {
        Type = JustifyHType,
        Get = function(self) return self:GetJustifyH() end,
        Set = function(self, justifyH) self:SetJustifyH(justifyH) end,
    }

    __Doc__[[the fontstring's vertical text alignment style]]
    property "JustifyV" {
        Type = JustifyVType,
        Get = function(self) return self:GetJustifyV() end,
        Set = function(self, justifyV) self:SetJustifyV(justifyV) end,
    }

    __Doc__[[the color of the font's text shadow]]
    property "ShadowColor" {
        Type = Color,
        Get = function(self) return Color(self:GetShadowColor()) end,
        Set = function(self, color) self:SetShadowColor(color.r, color.g, color.b, color.a) end,
    }

    __Doc__[[the offset of the fontstring's text shadow from its text]]
    property "ShadowOffset" {
        Type = Dimension,
        Get = function(self) return Dimension(self:GetShadowOffset()) end,
        Set = function(self, offset) self:SetShadowOffset(offset.x, offset.y) end,
    }

    __Doc__[[the fontstring's amount of spacing between lines]]
    property "Spacing" {
        Type = Number,
        Get = function(self) return self:GetSpacing() end,
        Set = function(self, spacing) self:SetSpacing(spacing) end,
    }

    __Doc__[[the fontstring's default text color]]
    property "TextColor" {
        Type = Color,
        Get = function(self) return Color(self:GetTextColor()) end,
        Set = function(self, color) self:SetTextColor(color.r, color.g, color.b, color.a) end,
    }
end)

------------------------------------------------------------
--                         Frame                          --
------------------------------------------------------------
__Doc__[[Frame is in many ways the most fundamental widget object. Other types of widget derivatives such as FontStrings, Textures and Animations can only be created attached to a Frame or other derivative of a Frame.]]
__Sealed__() __AutoProperty__()
class "Frame" (function(_ENV)
    inherit "Region"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    FRAME_ATTR_TARGET = false
    FRAME_ATTR_COLLECTOR = newproxy(true)

    getmetatable(FRAME_ATTR_COLLECTOR).__index = function(self, key)
        if FRAME_ATTR_TARGET then return FRAME_ATTR_TARGET:GetAttribute(key) end
    end

    getmetatable(FRAME_ATTR_COLLECTOR).__newindex = function(self, key, value)
        if FRAME_ATTR_TARGET then return FRAME_ATTR_TARGET:SetAttribute(key, value) end
    end

    getmetatable(FRAME_ATTR_COLLECTOR).__metatable = true

    InstallPrototype()

    ----------------------------------------------
    -------------------- Event -------------------
    ----------------------------------------------
    __Doc__[[Fired when a frame's min resize changed]]
    event "OnMinResizeChanged"

    __Doc__[[Fired when a frame's max resize changed]]
    event "OnMaxResizeChanged"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Sets the maximum size of the frame for user resizing. Applies when resizing the frame with the mouse via :StartSizing().</desc>
        <param name="maxWidth">number, maximum width of the frame (in pixels), or 0 for no limit</param>
        <param name="maxHeight">number, maximum height of the frame (in pixels), or 0 for no limit</param>
    ]]
    function SetMaxResize(self, ...)
        self.UIElement:SetMaxResize(...)
        return OnMaxResizeChanged(self)
    end

    __Doc__[[
        <desc>Sets the minimum size of the frame for user resizing. Applies when resizing the frame with the mouse via :StartSizing().</desc>
        <param name="minWidth">number, minimum width of the frame (in pixels), or 0 for no limit</param>
        <param name="minHeight">number, minimum height of the frame (in pixels), or 0 for no limit</param>
    ]]
    function SetMinResize(self, ...)
        self.UIElement:SetMinResize(...)
        return OnMinResizeChanged(self)
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The attribute collections of the frame]]
    property "Attribute" {
        Set = false,
        Get = function(self)
            FRAME_ATTR_TARGET = self
            return FRAME_ATTR_COLLECTOR
        end,
    }

    __Doc__[[the backdrop graphic for the frame]]
    property "Backdrop" { Type = BackdropType }

    __Doc__[[the shading color for the frame's border graphic]]
    property "BackdropBorderColor" {
        Type = Color,
        Get = function(self) return Color(self:GetBackdropBorderColor()) end,
        Set = function(self, color) self:SetBackdropBorderColor(color.r, color.g, color.b, color.a) end,
    }

    __Doc__[[the shading color for the frame's background graphic]]
    property "BackdropColor" {
        Type = Color,
        Get = function(self) return Color(self:GetBackdropColor()) end,
        Set = function(self, color) self:SetBackdropColor(color.r, color.g, color.b, color.a) end,
    }

    __Doc__[[whether the frame's boundaries are limited to those of the screen]]
    property "ClampedToScreen" { Type = Boolean }

    __Doc__[[offsets from the frame's edges used when limiting user movement or resizing of the frame]]
    property "ClampRectInsets" {
        Type = Inset,
        Get = function(self) return Inset(self:GetClampRectInsets()) end,
        Set = function(self, rInset) self:SetClampRectInsets(rInset.left, rInset.right, rInset.top, rInset.bottom) end,
    }

    __Doc__[[Whether the children is limited to draw inside the frame's boundaries]]
    property "ClipsChildren" { Type = Boolean, Get = "DoesClipChildren", Set = "SetClipsChildren" }

    __Doc__[[the 3D depth of the frame (for stereoscopic 3D setups)]]
    property "Depth" { Type = Number }

    __Doc__[[whether the frame's depth property is ignored (for stereoscopic 3D setups)]]
    property "DepthIgnored" { Type = Boolean }

    __Doc__[[Whether the frame don't save its location in layout-cache]]
    property "DontSavePosition" { Type = Boolean }

    __Doc__[[The effective alpha, readonly]]
    property "EffectiveAlpha" {}

    __Doc__[[The effective depth, readonly]]
    property "EffectiveDepth" {}

    __Doc__[[The effective scale, readonly]]
    property "EffectiveScale" {}

    __Doc__[[The effective flattens render layers]]
    property "EffectivelyFlattensRenderLayers" {}

    __Doc__[[Whether the frame's child is render in flattens layers]]
    property "FlattensRenderLayers" { Type = Boolean }

    __Doc__[[the level at which the frame is layered relative to others in its strata]]
    property "FrameLevel" { Type = Number }

    __Doc__[[the general layering strata of the frame]]
    property "FrameStrata" { Type = FrameStrata }

    __Doc__[[the insets from the frame's edges which determine its mouse-interactable area]]
    property "HitRectInsets" {
        Type = Inset,
        Get = function(self) return Inset(self:GetHitRectInsets()) end,
        Set = function(self, rInset) self:SetHitRectInsets(rInset.left, rInset.right, rInset.top, rInset.bottom) end,
    }

    __Doc__[[Whether the hyper links are enabled]]
    property "HyperlinksEnabled" { Type = Boolean }

    __Doc__[[a numeric identifier for the frame]]
    property "ID" { Type = Number }

    __Doc__[[Whether the frame ignore its parent's alpha settings]]
    property "IgnoreParentAlpha" { Type = Boolean }

    __Doc__[[Whether the frame ignore its parent's scale settings]]
    property "IgnoreParentScale" { Type = Boolean }

    __Doc__[[Whether the joystick is enabled for the frame]]
    property "JoystickEnabled" { Type = Boolean }

    __Doc__[[whether keyboard interactivity is enabled for the frame]]
    property "KeyboardEnabled" { Type = Boolean }

    __Doc__[[the maximum size of the frame for user resizing]]
    property "MaxResize" {
        Type = Size,
        Get = function(self) return Size(self:GetMaxResize()) end,
        Set = function(self, size) self:SetMaxResize(size.width, size.height) end,
    }

    __Doc__[[the minimum size of the frame for user resizing]]
    property "MinResize" {
        Type = Size,
        Get = function(self) return Size(self:GetMinResize()) end,
        Set = function(self, size) self:SetMinResize(size.width, size.height) end,
    }

    __Doc__[[Whether the mouse click is enabled]]
    property "MouseClickEnabled" { Type = Boolean }

    __Doc__[[whether mouse interactivity is enabled for the frame]]
    property "MouseEnabled" { Type = Boolean }

    __Doc__[[Whether the mouse motion in enabled]]
    property "MouseMotionEnabled" { Type = Boolean }

    __Doc__[[whether the frame can be moved by the user]]
    property "Movable" { Type = Boolean }

    __Doc__[[whether mouse wheel interactivity is enabled for the frame]]
    property "MouseWheelEnabled" { Type = Boolean }

    __Doc__[[Whether the frame get the propagate keyboard input]]
    property "PropagateKeyboardInput" { Type = Boolean }

    __Doc__[[whether the frame can be resized by the user]]
    property "Resizable" { Type = Boolean }

    __Doc__[[the frame's scale factor]]
    property "Scale" { Type = Number }

    __Doc__[[whether the frame should automatically come to the front when clicked]]
    property "Toplevel" { Type = Boolean }
end)

------------------------------------------------------------
--                        Texture                         --
------------------------------------------------------------
__Doc__[[Textures are visible areas descended from LayeredRegion, that display either a color block, a gradient, or a graphic raster taken from a .tga or .blp file]]
__Sealed__() __AutoProperty__()
class "Texture" (function(_ENV)
    inherit "LayeredRegion"

    local _SetPortraitTexture = SetPortraitTexture

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame",
        function (self, name, parent, layer, inherits, sublevel)
            return parent:CreateTexture(nil, layer or "ARTWORK", inherits, sublevel or 0)
        end
    )

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Sets the texture object's color</desc>
        <param name="red">number, Red component of the color (0.0 - 1.0)</param>
        <param name="green">number, Green component of the color (0.0 - 1.0)</param>
        <param name="blue">number, Blue component of the color (0.0 - 1.0)</param>
        <param name="alpha">number, Alpha (opacity) for the color (0.0 = fully transparent, 1.0 = fully opaque)</param>
    ]]
    function SetColorTexture(self, r, g, b, a)
        self.__TextureR = r
        self.__TextureG = g
        self.__TextureB = b
        self.__TextureA = a or 1

        return self.UIElement:SetColorTexture(r, g, b, a or 1)
    end

    __Doc__[[
        <desc>Paint a Texture object with the specified unit's portrait</desc>
        <param name="unit">string, the unit to be painted</param>
    ]]
    function SetPortraitUnit(self, unit)
        if type(unit) == "string" and UnitExists(unit) then
            self.__TextureUnit = unit
            return _SetPortraitTexture(self.UIElement, unit)
        else
            self.__TextureUnit = nil
            return self.UIElement:SetTexture(nil)
        end
    end

    __Doc__[[
        <desc>Sets the texture to be displayed from a file applying circular opacity mask making it look round like portraits</desc>
        <param name="texture">string, the texture file path</param>
    ]]
    function SetPortraitTexture(self, path)
        self.__TexturePortrait = nil
        return SetPortraitToTexture(self.UIElement, nil)
    end

    __Doc__"SetTexCoord" [[
        <desc>Sets corner coordinates for scaling or cropping the texture image</desc>
        <format>left, right, top, bottom</format>
        <format>ULx, ULy, LLx, LLy, URx, URy, LRx, LRy</format>
        <param name="left">number, Left edge of the scaled/cropped image, as a fraction of the image's width from the left</param>
        <param name="right">number, Right edge of the scaled/cropped image, as a fraction of the image's width from the left</param>
        <param name="top">number, Top edge of the scaled/cropped image, as a fraction of the image's height from the top</param>
        <param name="bottom">number, Bottom edge of the scaled/cropped image, as a fraction of the image's height from the top</param>
        <param name="ULx">number, Upper left corner X position, as a fraction of the image's width from the left</param>
        <param name="ULy">number, Upper left corner Y position, as a fraction of the image's height from the top</param>
        <param name="LLx">number, Lower left corner X position, as a fraction of the image's width from the left</param>
        <param name="LLy">number, Lower left corner Y position, as a fraction of the image's height from the top</param>
        <param name="URx">number, Upper right corner X position, as a fraction of the image's width from the left</param>
        <param name="URy">number, Upper right corner Y position, as a fraction of the image's height from the top</param>
        <param name="LRx">number, Lower right corner X position, as a fraction of the image's width from the left</param>
        <param name="LRy">number, Lower right corner Y position, as a fraction of the image's height from the top</param>
    ]]
    function SetTexCoord(self, ...)
        self.__TextureOriginTexCoord = nil
        return self.UIElement:SetTexCoord(...)
    end

    __Doc__"SetGradient" [[
        <desc>Sets a gradient color shading for the texture. Gradient color shading does not change the underlying color of the texture image, but acts as a filter</desc>
        <param name="orientation">System.Widget.Orientation, Token identifying the direction of the gradient</param>
        <param name="startR">number, Red component of the start color (0.0 - 1.0)</param>
        <param name="startG">number, Green component of the start color (0.0 - 1.0)</param>
        <param name="startB">number, Blue component of the start color (0.0 - 1.0)</param>
        <param name="endR">number, Red component of the end color (0.0 - 1.0)</param>
        <param name="endG">number, Green component of the end color (0.0 - 1.0)</param>
        <param name="endB">number, Blue component of the end color (0.0 - 1.0)</param>
    ]]
    function SetGradient(self, orientation, startR, startG, startB, endR, endG, endB)
        self.__TextureGraOrient = orientation
        self.__TextureGraStartR = startR
        self.__TextureGraStartG = startG
        self.__TextureGraStartB = startB
        self.__TextureGraStartA = nil
        self.__TextureGraEndR   = endR
        self.__TextureGraEndG   = endG
        self.__TextureGraEndB   = endB
        self.__TextureGraEndA   = nil
        return self.UIElement:SetGradient(orientation, startR, startG, startB, endR, endG, endB)
    end

    __Doc__"SetGradientAlpha" [[
        <desc>Sets a gradient color shading for the texture (including opacity in the gradient). Gradient color shading does not change the underlying color of the texture image, but acts as a filter</desc>
        <param name="orientation">System.Widget.Orientation, Token identifying the direction of the gradient (string)</param>
        <param name="startR">number, Red component of the start color (0.0 - 1.0)</param>
        <param name="startG">number, Green component of the start color (0.0 - 1.0)</param>
        <param name="startB">number, Blue component of the start color (0.0 - 1.0)</param>
        <param name="startAlpha">number, Alpha (opacity) for the start side of the gradient (0.0 = fully transparent, 1.0 = fully opaque)</param>
        <param name="endR">number, Red component of the end color (0.0 - 1.0)</param>
        <param name="endG">number, Green component of the end color (0.0 - 1.0)</param>
        <param name="endB">number, Blue component of the end color (0.0 - 1.0)</param>
        <param name="endAlpha">number, Alpha (opacity) for the end side of the gradient (0.0 = fully transparent, 1.0 = fully opaque)</param>
    ]]
    function SetGradientAlpha(self, orientation, startR, startG, startB, startAlpha, endR, endG, endB, endAlpha)
        self.__TextureGraOrient = orientation
        self.__TextureGraStartR = startR
        self.__TextureGraStartG = startG
        self.__TextureGraStartB = startB
        self.__TextureGraStartA = startAlpha
        self.__TextureGraEndR   = endR
        self.__TextureGraEndG   = endG
        self.__TextureGraEndB   = endB
        self.__TextureGraEndA   = endAlpha
        return self.UIElement:SetGradientAlpha(orientation, startR, startG, startB, startAlpha, endR, endG, endB, endAlpha)
    end

    __Doc__[[
        <desc>Rotate texture for radian with current texcoord settings</desc>
        <param name="radian">number, the rotation raidian</param>
    ]]
    function RotateRadian(self, radian)
        if type(radian) ~= "number" then
            error("Usage: Texture:RotateRadian(radian) - 'radian' must be number.", 2)
        end

        if not self.__TextureOriginTexCoord then
            self.__TextureOriginTexCoord = { self:GetTexCoord() }
            self.__TextureOriginWidth = self:GetWidth()
            self.__TextureOriginHeight = self:GetHeight()
        end

        while radian < 0 do radian = radian + 2 * math.pi end
        radian = radian % (2 * math.pi)

        local angle = radian % (math.pi /2)

        local left = self.__TextureOriginTexCoord[1]
        local top = self.__TextureOriginTexCoord[2]
        local right = self.__TextureOriginTexCoord[7]
        local bottom = self.__TextureOriginTexCoord[8]

        local dy = self.__TextureOriginWidth * math.cos(angle) * math.sin(angle) * (bottom-top) / self.__TextureOriginHeight
        local dx = self.__TextureOriginHeight * math.cos(angle) * math.sin(angle) * (right - left) / self.__TextureOriginWidth
        local ox = math.cos(angle) * math.cos(angle) * (right-left)
        local oy = math.cos(angle) * math.cos(angle) * (bottom-top)

        local newWidth = self.__TextureOriginWidth*math.cos(angle) + self.__TextureOriginHeight*math.sin(angle)
        local newHeight = self.__TextureOriginWidth*math.sin(angle) + self.__TextureOriginHeight*math.cos(angle)

        local ULx   -- Upper left corner X position, as a fraction of the image's width from the left (number)
        local ULy   -- Upper left corner Y position, as a fraction of the image's height from the top (number)
        local LLx   -- Lower left corner X position, as a fraction of the image's width from the left (number)
        local LLy   -- Lower left corner Y position, as a fraction of the image's height from the top (number)
        local URx   -- Upper right corner X position, as a fraction of the image's width from the left (number)
        local URy   -- Upper right corner Y position, as a fraction of the image's height from the top (number)
        local LRx   -- Lower right corner X position, as a fraction of the image's width from the left (number)
        local LRy   -- Lower right corner Y position, as a fraction of the image's height from the top (number)

        if radian < math.pi / 2 then
            -- 0 ~ 90
            ULx = left - dx
            ULy = bottom - oy

            LLx = right - ox
            LLy = bottom + dy

            URx = left + ox
            URy = top - dy

            LRx = right + dx
            LRy = top + oy
        elseif radian < math.pi then
            -- 90 ~ 180
            URx = left - dx
            URy = bottom - oy

            ULx = right - ox
            ULy = bottom + dy

            LRx = left + ox
            LRy = top - dy

            LLx = right + dx
            LLy = top + oy

            newHeight, newWidth = newWidth, newHeight
        elseif radian < 3 * math.pi / 2 then
            -- 180 ~ 270
            LRx = left - dx
            LRy = bottom - oy

            URx = right - ox
            URy = bottom + dy

            LLx = left + ox
            LLy = top - dy

            ULx = right + dx
            ULy = top + oy
        else
            -- 270 ~ 360
            LLx = left - dx
            LLy = bottom - oy

            LRx = right - ox
            LRy = bottom + dy

            ULx = left + ox
            ULy = top - dy

            URx = right + dx
            URy = top + oy

            newHeight, newWidth = newWidth, newHeight
        end

        self.UIElement:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
        self.Width = newWidth
        self.Height = newHeight
    end

    __Doc__[[
        <desc>Rotate texture for degree with current texcoord settings</desc>
        <param name="degree">number, the rotation degree</param>
    ]]
    function RotateDegree(self, degree)
        if type(degree) ~= "number" then
            error("Usage: Texture:RotateDegree(degree) - 'degree' must be number.", 2)
        end
        return RotateRadian(self, math.rad(degree))
    end

    __Doc__[[
        <desc>Shear texture for raidian</desc>
        <param name="radian">number, the shear radian</param>
    ]]
    function ShearRadian(self, radian)
        if type(radian) ~= "number" then
            error("Usage: Texture:ShearRadian(radian) - 'radian' must be number.", 2)
        end

        if not self.__TextureOriginTexCoord then
            self.__TextureOriginTexCoord = { self:GetTexCoord() }
            self.__TextureOriginWidth = self.Width
            self.__TextureOriginHeight = self.Height
        end

        while radian < - math.pi/2 do radian = radian + 2 * math.pi end
        radian = radian % (2 * math.pi)

        if radian > math.pi /2 then
            error("Usage: Texture:ShearRadian(radian) - 'radian' must be between -pi/2 and pi/2.", 2)
        end

        local left = self.__TextureOriginTexCoord[1]
        local top = self.__TextureOriginTexCoord[2]
        local right = self.__TextureOriginTexCoord[7]
        local bottom = self.__TextureOriginTexCoord[8]

        local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = unpack(self.__TextureOriginTexCoord)

        if radian > 0 then
            ULx = left - (bottom-top) * math.sin(radian)
            LRx = right + (bottom-top) * math.sin(radian)
        elseif radian < 0 then
            radian = math.abs(radian)
            LLx = left - (bottom-top) * math.sin(radian)
            URx = right + (bottom-top) * math.sin(radian)
        end

        return self.UIElement:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
    end

    __Doc__[[
        <desc>Shear texture with degree</desc>
        <param name="degree">number, the shear degree</param>
    ]]
    function ShearDegree(self, degree)
        if type(degree) ~= "number" then
            error("Usage: Texture:ShearDegree(degree) - 'degree' must be number.", 2)
        end

        return ShearRadian(self, math.rad(degree))
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the blend mode of the texture]]
    property "BlendMode" { Type = AlphaMode }

    __Doc__[[the texture's color]]
    property "Color" {
        Type = Color,
        Get = function(self)
            local path = self:GetTexture()

            if type(path) == "string" and strmatch(path, "^Color%-") then
                return Color(
                        self.__TextureR,
                        self.__TextureG,
                        self.__TextureB,
                        self.__TextureA
                    )
            end
        end,
        Set = function(self, color)
            self:SetColorTexture(color.r, color.g, color.b, color.a)
        end,
    }

    __Doc__[[whether the texture image should be displayed with zero saturation]]
    property "Desaturated" { Type = Boolean }

    __Doc__[[The texture's desaturation]]
    property "Desaturation" { Type = ColorFloat }

    __Doc__[[Whether the texture is horizontal tile]]
    property "HorizTile" { Type = Boolean }

    __Doc__[[whether the texture object loads its image file in the background]]
    property "NonBlocking" { Type = Boolean }

    __Doc__[[the texture object's image file path]]
    property "Path" {
        Type = String + Number,
        Get = function(self)
            local path = self:GetTexture()

            if type(path) == "string" then
                if not strmatch(path, "^Color%-") and not strmatch(path, "^RTPortrait%d*") then
                    return path
                end
            else
                return path
            end
        end,
        Set = "SetTexture",
    }

    __Doc__[[the texture to be displayed from a file applying circular opacity mask making it look round like portraits.]]
    property "PortraitMask" {
        Field = "__TexturePortrait",
        Set = "SetPortraitTexture",
        Type = String,
    }

    __Doc__[[the unit be displayed as a portrait, such as "player", "target"]]
    property "PortraitUnit" {
        Type = String,
        Get = function(self)
            local path = self:GetTexture()

            if type(path) == "string" and strmatch(path, "^RTPortrait%d*") then
                return self.__TextureUnit
            end
        end,
        Set = "SetPortraitUnit",
    }

    __Doc__[[The corner coordinates for scaling or cropping the texture image]]
    property "TexCoord" {
        Type = TexCoord,
        Get = function(self) return TexCoord( self:GetTexCoord() ) end,
        Set = function(self, td) self:SetTexCoord( td.ULx, td.ULy, td.LLx, td.LLy, td.URx, td.URy, td.LRx, td.LRy ) end,
    }

    __Doc__[[Whether the texture is vertical tile]]
    property "VertTile" { Type = Boolean }

    __Doc__[[The gradient color shading for the texture]]
    property "Gradient" {
        Type = GradientType,
        Set = function(self, val)
            return self:SetGradient(val.orientation, val.MinColor.r, val.MinColor.g, val.MinColor.b, val.MaxColor.r, val.MaxColor.g, val.MaxColor.b)
        end,
        Get = function(self)
            if not self.__TextureGraStartA then
                return GradientType(
                    self.__TextureGraOrient,
                    Color(
                        self.__TextureGraStartR,
                        self.__TextureGraStartG,
                        self.__TextureGraStartB
                    ),
                    Color(
                        self.__TextureGraEndR,
                        self.__TextureGraEndG,
                        self.__TextureGraEndB
                    )
                )
            end
        end,
    }

    __Doc__[[The gradient color shading (including opacity in the gradient) for the texture]]
    property "GradientAlpha" {
        Type = GradientType,
        Set = function(self, val)
            return self:SetGradientAlpha(val.orientation, val.MinColor.r, val.MinColor.g, val.MinColor.b, val.MinColor.a, val.MaxColor.r, val.MaxColor.g, val.MaxColor.b, val.MaxColor.a)
        end,
        Get = function(self)
            if self.__TextureGraStartA then
                return GradientType(
                    self.__TextureGraOrient,
                    Color(
                        self.__TextureGraStartR,
                        self.__TextureGraStartG,
                        self.__TextureGraStartB,
                        self.__TextureGraStartA
                    ),
                    Color(
                        self.__TextureGraEndR,
                        self.__TextureGraEndG,
                        self.__TextureGraEndB,
                        self.__TextureGraEndA
                    )
                )
            end
        end,
    }
end)

------------------------------------------------------------
--                      FontString                        --
------------------------------------------------------------
__Doc__[[FontStrings are one of the two types of Region that is visible on the screen. It draws a block of text on the screen using the characteristics in an associated FontObject.]]
__Sealed__() __AutoProperty__()
class "FontString" (function(_ENV)
    inherit "LayeredRegion"
    extend "IFont"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame",
        function (self, name, parent, layer, inherits, ...)
            return parent:CreateFontString(nil, layer or "OVERLAY", inherits or "GameFontNormal", ...)
        end, true
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[whether the text wrap will be indented]]
    property "IndentedWordWrap" { Type = Boolean }

    __Doc__[[the max lines of the text]]
    property "MaxLines" { Type = PositiveInteger }

    __Doc__[[whether long lines of text will wrap within or between words]]
    property "NonSpaceWrap" {
        Type = Boolean,
        Get = "CanNonSpaceWrap",
        Set = "SetNonSpaceWrap",
    }

    __Doc__[[whether long lines of text in the font string can wrap onto subsequent lines]]
    property "WordWrap" {
        Type = Boolean,
        Get = "CanWordWrap",
        Set = "SetWordWrap"
    }

    __Doc__[[the height of the text displayed in the font string]]
    property "StringHeight" { }

    __Doc__[[the width of the text displayed in the font string]]
    property "StringWidth" { }

    __Doc__[[the text to be displayed in the font string]]
    property "Text" { Type = LocaleString }
end)

------------------------------------------------------------
--                         Line                           --
------------------------------------------------------------
__Doc__[[Lines are used to link two anchor points.]]
__Sealed__() __AutoProperty__()
class "Line" (function(_ENV)
    inherit "Texture"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame",
        function (self, name, parent, ...)
            return parent:CreateLine(nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The start point of the line]]
    property "StartPoint" { Type = Dimension }

    __Doc__[[The end point of the line]]
    property "EndPoint" { Type = Dimension }

    __Doc__[[The thickness of the line]]
    property "Thickness" { Type = PositiveNumber }
end)

------------------------------------------------------------
--                      Animation                         --
------------------------------------------------------------
__Doc__[[
    An AnimationGroup is how various animations are actually applied to a region; this is how different behaviors can be run in sequence or in parallel with each other, automatically. When you pause an AnimationGroup, it tracks which of its child animations were playing and how far advanced they were, and resumes them from that point.
    An Animation in a group has an order from 1 to 100, which determines when it plays; once all animations with order 1 have completed, including any delays, the AnimationGroup starts all animations with order 2.
    An AnimationGroup can also be set to loop, either repeating from the beginning or playing backward back to the beginning. An AnimationGroup has an OnLoop handler that allows you to call your own code back whenever a loop completes. The :Finish() method stops the animation after the current loop has completed, rather than immediately.
]]
__Sealed__() __AutoProperty__()
class "AnimationGroup" (function(_ENV)
    inherit "UI"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame",
        function (self, name, parent, ...)
            return parent:CreateAnimationGroup(nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[looping type for the animation group: BOUNCE , NONE  , REPEAT]]
    property "Looping" { Type = AnimLoopType }

    __Doc__[[Whether to final alpha is set]]
    property "ToFinalAlpha" { Type = Boolean, Set = "SetToFinalAlpha", Get = "IsSetToFinalAlpha" }
end)

__Doc__[[
    Animations are used to change presentations or other characteristics of a frame or other region over time. The Animation object will take over the work of calling code over time, or when it is done, and tracks how close the animation is to completion.
    The Animation type doesn't create any visual effects by itself, but it does provide an OnUpdate handler that you can use to support specialized time-sensitive behaviors that aren't provided by the transformations descended from Animations. In addition to tracking the passage of time through an elapsed argument, you can query the animation's progress as a 0-1 fraction to determine how you should set your behavior.
    You can also change how the elapsed time corresponds to the progress by changing the smoothing, which creates acceleration or deceleration, or by adding a delay to the beginning or end of the animation.
    You can also use an Animation as a timer, by setting the Animation's OnFinished script to trigger a callback and setting the duration to the desired time.
]]
__Sealed__() __AutoProperty__()
class "Animation" (function(_ENV)
    inherit "UI"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("AnimationGroup",
        function (self, name, parent, ...)
            return parent:CreateAnimation("Animation", nil, ...)
        end
    )

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Returns the Region object on which the animation operates</desc>
        <return type="System.Widget.Region">Reference to the Region object on which the animation operates</return>
    ]]
    function GetRegionParent(self)
        return UI.GetUIWrapper(self.UIElement:GetRegionParent())
    end

    __Doc__[[
        <desc>Returns the target object on which the animation operates</desc>
        <return type="System.Widget.Region">Reference to the target object on which the animation operates</return>
    ]]
    function GetTarget(self)
        return UI.GetUIWrapper(self.UIElement:GetTarget())
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Amount of time the animation delays before its progress begins (in seconds)]]
    property "StartDelay" { Type = Number }

    __Doc__[[Time for the animation to delay after finishing (in seconds)]]
    property "EndDelay" { Type = Number }

    __Doc__[[Time for the animation to progress from start to finish (in seconds)]]
    property "Duration" { Type = Number }

    __Doc__[[Position at which the animation will play relative to others in its group (between 0 and 100)]]
    property "Order" { Type = Number }

    __Doc__[[Type of smoothing for the animation, IN, IN_OUT, NONE, OUT]]
    property "Smoothing" { Type = AnimSmoothType }

    __Doc__[[The smooth progress of the animation]]
    property "SmoothProgress" { Type = Number }
end)

__Doc__[[Alpha is a type of animation that automatically changes the transparency level of its attached region as it progresses. You can set the degree by which it will change the alpha as a fraction; for instance, a change of -1 will fade out a region completely]]
__Sealed__() __AutoProperty__()
class "Alpha" (function(_ENV)
    inherit "Animation"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("AnimationGroup",
        function (self, name, parent, ...)
            return parent:CreateAnimation("Alpha", nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the animation's amount of alpha (opacity) start from]]
    property "FromAlpha" { Type = Number }

    __Doc__[[the animation's amount of alpha (opacity) end to]]
    property "ToAlpha" { Type = Number }
end)

__Doc__[[Path is an Animation type that combines multiple transitions into a single control path with multiple ControlPoints.]]
__Sealed__() __AutoProperty__()
class "Path" (function(_ENV)
    inherit "Animation"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("AnimationGroup",
        function (self, name, parent, ...)
            return parent:CreateAnimation("Path", nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The curveType of the given path]]
    property "Curve" { Type = AnimCurveType }
end)

__Doc__[[A special type that represent a point in a Path Animation.]]
__Sealed__() __AutoProperty__()
class "ControlPoint" (function(_ENV)
    inherit "UI"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Path",
        function (self, name, parent, ...)
            return parent:CreateControlPoint(nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the control point offsets]]
    property "Offset" {
        Type = Dimension,
        Get = function(self)
            return Dimension(elf:GetOffset())
        end,
        Set = function(self, offset)
            return self:SetOffset(offset.x, offset.y)
        end,
    }

    __Doc__[[Position at which the animation will play relative to others in its group (between 0 and 100)]]
    property "Order" { Type = Number }
end)

__Doc__[[Rotation is an Animation that automatically applies an affine rotation to the region being animated. You can set the origin around which the rotation is being done, and the angle of rotation in either degrees or radians.]]
__Sealed__() __AutoProperty__()
class "Rotation" (function(_ENV)
    inherit "Animation"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("AnimationGroup",
        function (self, name, parent, ...)
            return parent:CreateAnimation("Rotation", nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the animation's rotation amount (in degrees)]]
    property "Degrees" { Type = Number }

    __Doc__[[the animation's rotation amount (in radians)]]
    property "Radians" { Type = Number }

    __Doc__[[the rotation animation's origin point]]
    property "Origin" {
        Get = function(self)
            return AnimOriginType(self:GetOrigin())
        end,
        Set = function(self, origin)
            self:SetOrigin(origin.point, origin.x, origin.y)
        end,
        Type = AnimOriginType,
    }
end)

__Doc__[[Scale is an Animation type that automatically applies an affine scalar transformation to the region being animated as it progresses. You can set both the multiplier by which it scales, and the point from which it is scaled.]]
__Sealed__() __AutoProperty__()
class "Scale" (function(_ENV)
    inherit "Animation"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("AnimationGroup",
        function (self, name, parent, ...)
            return parent:CreateAnimation("Scale", nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the animation's scaling factors]]
    property "Scale" {
        Get = function(self)
            return Dimension(self:GetScale())
        end,
        Set = function(self, offset)
            self:SetScale(offset.x, offset.y)
        end,
        Type = Dimension,
    }

    __Doc__[[the scale animation's origin point]]
    property "Origin" {
        Get = function(self)
            return AnimOriginType(self:GetOrigin())
        end,
        Set = function(self, origin)
            self:SetOrigin(origin.point, origin.x, origin.y)
        end,
        Type = AnimOriginType,
    }

    __Doc__[[the animation's scale amount that start from]]
    property "FromScale" {
        Get = function(self)
            return Dimension(self:GetFromScale())
        end,
        Set = function(self, offset)
            self:SetFromScale(offset.x, offset.y)
        end,
        Type = Dimension,
    }

    __Doc__[[the animation's scale amount that end to]]
    property "ToScale" {
        Get = function(self)
            return Dimension(self:GetToScale())
        end,
        Set = function(self, offset)
            self:SetToScale(offset.x, offset.y)
        end,
        Type = Dimension,
    }
end)

__Doc__[[LineScale is an Animation type inherit Scale.]]
__Sealed__() __AutoProperty__()
class "LineScale" (function(_ENV)
    inherit "Animation"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("AnimationGroup",
        function (self, name, parent, ...)
            return parent:CreateAnimation("LineScale", nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the animation's scaling factors]]
    property "Scale" {
        Get = function(self)
            return Dimension(self:GetScale())
        end,
        Set = function(self, offset)
            self:SetScale(offset.x, offset.y)
        end,
        Type = Dimension,
    }

    __Doc__[[the scale animation's origin point]]
    property "Origin" {
        Get = function(self)
            return AnimOriginType(self:GetOrigin())
        end,
        Set = function(self, origin)
            self:SetOrigin(origin.point, origin.x, origin.y)
        end,
        Type = AnimOriginType,
    }

    __Doc__[[the animation's scale amount that start from]]
    property "FromScale" {
        Get = function(self)
            return Dimension(self:GetFromScale())
        end,
        Set = function(self, offset)
            self:SetFromScale(offset.x, offset.y)
        end,
        Type = Dimension,
    }

    __Doc__[[the animation's scale amount that end to]]
    property "ToScale" {
        Get = function(self)
            return Dimension(self:GetToScale())
        end,
        Set = function(self, offset)
            self:SetToScale(offset.x, offset.y)
        end,
        Type = Dimension,
    }
end)

__Doc__[[Translation is an Animation type that applies an affine translation to its affected region automatically as it progresses.]]
__Sealed__() __AutoProperty__()
class "Translation" (function(_ENV)
    inherit "Animation"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("AnimationGroup",
        function (self, name, parent, ...)
            return parent:CreateAnimation("Translation", nil, ...)
        end
    )

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the animation's translation offsets]]
    property "Offset" {
        Type = Dimension,
        Get = function(self)
            return Dimension(self:GetOffset())
        end,
        Set = function(self, offset)
            return self:SetOffset(offset.x, offset.y)
        end,
    }
end)


------------------------------------------------------------
--                    Frame Widgets                       --
------------------------------------------------------------
__Doc__[[
    ArchaeologyDigSiteFrame is a frame that is used to display digsites. Any one frame can be used to display any number of digsites, called blobs. Each blob is a polygon with a border and a filling texture.
    To draw a blob onto the frame use the DrawBlob function. This will draw a polygon representing the specified digsite. It seems that it's only possible to draw digsites where you can dig and is on the current map.
    Changes to how the blobs should render will only affect newly drawn blobs. That means that if you want to change the opacity of a blob you must first clear all blobs using the DrawNone function and then redraw the blobs.
]]
__Sealed__() __AutoProperty__()
class "ArchaeologyDigSiteFrame" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")
end)

__Doc__[[Button is the primary means for users to control the game and their characters.]]
__Sealed__() __AutoProperty__()
class "Button" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function GetFontString(self)
        return UI.GetUIWrapper(self.UIElement:GetFontString())
    end

    function GetDisabledTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetDisabledTexture())
    end

    function GetHighlightTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetHighlightTexture())
    end

    function GetNormalTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetNormalTexture())
    end

    function GetPushedTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetPushedTexture())
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Whether the button is enabled]]
    property "Enabled" { Type = Boolean }

    __Doc__[[the font object used for the button's disabled state]]
    property "DisabledFontObject" { }

    __Doc__[[the font object used when the button is highlighted]]
    property "HighlightFontObject" { }

    __Doc__[[the font object used for the button's normal state]]
    property "NormalFontObject" { }

    __Doc__[[the texture object used when the button is disabled]]
    property "DisabledTexture" { }

    __Doc__[[the texture object used when the button is highlighted]]
    property "HighlightTexture" { }

    __Doc__[[the texture object used for the button's normal state]]
    property "NormalTexture" { }

    __Doc__[[the texture object used when the button is pushed]]
    property "PushedTexture" { }

    __Doc__[[the FontString object used for the button's label text]]
    property "FontString" { Type = FontString }

    __Doc__[[the offset for moving the button's label text when pushed]]
    property "PushedTextOffset" {
        Get = function(self)
            return Dimension(self:GetPushedTextOffset())
        end,
        Set = function(self, offset)
            self:SetPushedTextOffset(offset.x, offset.y)
        end,
        Type = Dimension,
    }

    __Doc__[[the text displayed as the button's label]]
    property "Text" { Type = LocaleString }

    __Doc__[[true if the button's highlight state is locked]]
    __Handler__( function (self, value)
        if value then
            self:LockHighlight()
        else
            self:UnlockHighlight()
        end
    end )
    property "HighlightLocked" { Field = true, Type = Boolean }

    __Doc__[[Whether enable the motion script while disabled]]
    property "MotionScriptsWhileDisabled" { Type = Boolean }
end)

__Doc__[[Browser is used to provide help helpful pages in the game]]
__Sealed__() __AutoProperty__()
class "Browser" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")
end)

__Doc__[[EditBoxes are used to allow the player to type text into a UI component.]]
__Sealed__() __AutoProperty__()
class "EditBox" (function(_ENV)
    inherit "Frame"
    extend "IFont"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame", nil, true)

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[whether the text wrap will be indented]]
    property "IndentedWordWrap" { Type = Boolean }

    __Doc__[[Whether count the invisible letters for max letters]]
    property "CountInvisibleLetters" { Type = Boolean }

    __Doc__[[true if the edit box shows more than one line of text]]
    property "MultiLine" { Type = Boolean }

    __Doc__[[true if the edit box only accepts numeric input]]
    property "Numeric" { Type = Boolean }

    __Doc__[[true if the text entered in the edit box is masked]]
    property "Password" { Type = Boolean }

    __Doc__[[true if the edit box automatically acquires keyboard input focus]]
    property "AutoFocus" { Type = Boolean }

    __Doc__[[the maximum number of history lines stored by the edit box]]
    property "HistoryLines" { Type = Number }

    __Doc__[[true if the edit box is currently focused]]
    property "Focused" {
        Get = "HasFocus",
        Set = function(self, focus)
            if focus then
                self:SetFocus()
            else
                self:ClearFocus()
            end
        end,
        Type = Boolean,
    }

    __Doc__[[true if the arrow keys are ignored by the edit box unless the Alt key is held]]
    property "AltArrowKeyMode" { Type = Boolean }

    __Doc__[[the rate at which the text insertion blinks when the edit box is focused]]
    property "BlinkSpeed" { Type = Number }

    __Doc__[[the current cursor position inside edit box]]
    property "CursorPosition" { Type = Number }

    __Doc__[[the maximum number of bytes of text allowed in the edit box, default is 0(Infinite)]]
    property "MaxBytes" { Type = Number }

    __Doc__[[the maximum number of text characters allowed in the edit box]]
    property "MaxLetters" { Type = Number }

    __Doc__[[the contents of the edit box as a number]]
    property "Number" { Type = Number }

    __Doc__[[the edit box's text contents]]
    property "Text" { Type = String }

    __Doc__[[the insets from the edit box's edges which determine its interactive text area]]
    property "TextInsets" {
        Get = function(self)
            return Inset(self:GetTextInsets())
        end,
        Set = function(self, value)
            self:SetTextInsets(value.left, value.right, value.top, value.bottom)
        end,
        Type = Inset,
    }

    __Doc__[[Whether the edit box is enabled]]
    property "Enabled" { Type = Boolean }
end)

__Doc__[[CheckButtons are a specialized form of Button; they maintain an on/off state, which toggles automatically when they are clicked, and additional textures for when they are checked, or checked while disabled.]]
__Sealed__() __AutoProperty__()
class "CheckButton" (function(_ENV)
    inherit "Button"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function GetCheckedTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetCheckedTexture())
    end

    function GetDisabledCheckedTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetDisabledCheckedTexture())
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[true if the checkbutton is checked]]
    property "Checked" { Type = Boolean }

    __Doc__[[the texture object used when the button is checked]]
    property "CheckedTexture" { }

    __Doc__[[the texture object used when the button is disabled and checked]]
    property "DisabledCheckedTexture" { }
end)

__Sealed__() __AutoProperty__()
class "ColorSelect" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function GetColorValueTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetColorValueTexture())
    end

    function GetColorValueThumbTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetColorValueThumbTexture())
    end

    function GetColorWheelTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetColorWheelTexture())
    end

    function GetColorWheelThumbTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetColorWheelThumbTexture())
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the texture for the color picker's value slider background]]
    property "ColorValueTexture" { }

    __Doc__[[the texture for the color picker's value slider thumb]]
    property "ColorValueThumbTexture" { }

    __Doc__[[the texture for the color picker's hue/saturation wheel]]
    property "ColorWheelTexture" { }

    __Doc__[[the texture for the selection indicator on the color picker's hue/saturation wheel]]
    property "ColorWheelThumbTexture" { }

    __Doc__[[the HSV color value]]
    property "ColorHSV" {
        Type = HSV,
        Get = function(self) return HSV(self:GetColorHSV()) end,
        Set = function(self, v) self:SetColorHSV(v.hue, v.saturation, v.value) end,
    }

    __Doc__[[the RGB color value]]
    property "Color" {
        Type = Color,
        Get = function(self) return Color(self:GetColorRGB()) end,
        Set = function(self, v) self:SetColorRGB(v.r, v.g, v.b) end,
    }
end)

__Doc__[[Cooldown is a specialized variety of Frame that displays the little "clock" effect over abilities and buffs. It can be set with its running time, whether it should appear to "fill up" or "empty out", and whether or not there should be a bright edge where it's changing between dim and bright.]]
__Sealed__() __AutoProperty__()
class "Cooldown" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Whether the cooldown animation "sweeps" an area of darkness over the underlying image; false if the animation darkens the underlying image and "sweeps" the darkened area away]]
    property "Reverse" { Type = Boolean }

    __Doc__[[the duration currently shown by the cooldown frame in milliseconds]]
    property "CooldownDuration" { Type = Number }

    __Doc__[[Whether the cooldown 'bling' when finsihed]]
    property "DrawBling" { Type = Boolean }

    __Doc__[[Whether a bright line should be drawn on the moving edge of the cooldown animation]]
    property "DrawEdge" { Type = Boolean }

    __Doc__[[Whether a shadow swipe should be drawn]]
    property "DrawSwipe" { Type = Boolean }

    __Doc__[[Sets the bling texture]]
    property "BlingTexture" { }

    __Doc__[[Sets the edge texture]]
    property "EdgeTexture" { }

    __Doc__[[Sets the swipe color]]
    property "SwipeColor" {
        Type = Color,
        Set = function(self, color)
            return self:SetSwipeColor(color.r, color.g, color.b, color.a)
        end,
    }

    __Doc__[[Sets the swipe texture]]
    property "SwipeTexture" { }

    __Doc__[[Whether hide count down numbers]]
    property "HideCountdownNumbers" { Type = Boolean }
end)

__Doc__[[GameTooltips are used to display explanatory information relevant to a particular element of the game world.]]
__Sealed__() __AutoProperty__()
class "GameTooltip" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    COPPER_PER_SILVER = _G.COPPER_PER_SILVER
    SILVER_PER_GOLD   = _G.SILVER_PER_GOLD

    InstallPrototype("Frame", function(self, name, parent, ...)
        if select("#", ...) > 0 then
            return CreateFrame("GameTooltip", name, parent, ...)
        else
            return CreateFrame("GameTooltip", name, parent, "GameTooltipTemplate")
        end
    end)

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function GetOwner(self)
        return UI.GetUIWrapper(self.UIElement:GetOwner())
    end

    __Doc__[[
        <desc>Get the left text of the given index line</desc>
        <param name="index">number, between 1 and self:NumLines()</param>
        <return type="string"></return>
    ]]
    function GetLeftText(self, index)
        local name = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name = name.."TextLeft"..index

        if type(_G[name]) == "table" and _G[name].GetText then
            return _G[name]:GetText()
        end
    end

    __Doc__[[
        <desc>Get the right text of the given index line</desc>
        <param name="index">number, between 1 and self:NumLines()</param>
        <return type="string"></return>
    ]]
    function GetRightText(self, index)
        local name = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name = name.."TextRight"..index

        if type(_G[name]) == "table" and _G[name].GetText then
            return _G[name]:GetText()
        end
    end

    __Doc__[[
        <desc>Set the left text of the given index line</desc>
        <param name="index">number, between 1 and self:NumLines()</param>
        <param name="text">string</param>
        <return type="string"></return>
    ]]
    function SetLeftText(self, index, text)
        local name = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name = name.."TextLeft"..index

        if type(_G[name]) == "table" and _G[name].GetText then
            return _G[name]:SetText(text)
        end
    end

    __Doc__[[
        <desc>Set the right text of the given index line</desc>
        <param name="index">number, between 1 and self:NumLines()</param>
        <param name="text">string</param>
        <return type="string"></return>
    ]]
    function SetRightText(self, index, text)
        local name = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name = name.."TextRight"..index

        if type(_G[name]) == "table" and _G[name].GetText then
            return _G[name]:SetText(text)
        end
    end

    __Doc__[[
        <desc>Get the texutre of the given index line</desc>
        <param name="index">number, between 1 and self:NumLines()</param>
        <return type="string"></return>
    ]]
    function GetTexture(self, index)
        local name = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name = name.."Texture"..index

        if type(_G[name]) == "table" and _G[name].GetTexture then
            return _G[name]:GetTexture()
        end
    end

    __Doc__[[
        <desc>Get the money of the given index, default 1</desc>
        <param name="index">number, between 1 and self:NumLines()</param>
        <return type="number"></return>
    ]]
    function GetMoney(self, index)
        local name = self:GetName()

        index = index or 1
        if not name or not index or type(index) ~= "number" then return end

        name = name.."MoneyFrame"..index

        if type(_G[name]) == "table" then
            local gold = strmatch((_G[name.."GoldButton"] and _G[name.."GoldButton"]:GetText()) or "0", "%d*") or 0
            local silver = strmatch((_G[name.."SilverButton"] and _G[name.."SilverButton"]:GetText()) or "0", "%d*") or 0
            local copper = strmatch((_G[name.."CopperButton"] and _G[name.."CopperButton"]:GetText()) or "0", "%d*") or 0

            return gold * COPPER_PER_SILVER * SILVER_PER_GOLD + silver * COPPER_PER_SILVER + copper
        end
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The owner of this gametooltip]]
    property "Owner" { Type = UI }

    __Doc__[[The padding of the GameTooltip]]
    property "Padding" {
        Type = Size,
        Get = function(self) return Size(self:GetPadding()) end,
        Set = function(self, s) self:SetPadding(s.width, s.height) end,
    }

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function Dispose(self)
        local name = self:GetName()
        local index, chkName

        self:ClearLines()

        if name and _G[name] == self.UIElement then
            -- remove lefttext
            index = 1

            while _G[name.."TextLeft"..index] do
                _G[name.."TextLeft"..index] = nil
                index = index + 1
            end

            -- remove righttext
            index = 1

            while _G[name.."TextRight"..index] do
                _G[name.."TextRight"..index] = nil
                index = index + 1
            end

            -- remove texture
            index = 1

            while _G[name.."Texture"..index] do
                _G[name.."Texture"..index] = nil
                index = index + 1
            end

            -- remove self
            _G[name] = nil
        end
    end
end)

__Doc__[[MessageFrames are used to present series of messages or other lines of text, usually stacked on top of each other.]]
__Sealed__() __AutoProperty__()
class "MessageFrame" (function(_ENV)
    inherit "Frame"
    extend "IFont"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame", nil, true)

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[whether messages added to the frame automatically fade out after a period of time]]
    property "Fading" { Type = Boolean }

    __Doc__[[whether long lines of text are indented when wrapping]]
    property "IndentedWordWrap" { Type = Boolean }

    __Doc__[[the amount of time for which a message remains visible before beginning to fade out]]
    property "TimeVisible" { Type = Number }

    __Doc__[[the duration of the fade-out animation for disappearing messages]]
    property "FadeDuration" { Type = Number }

    __Doc__[[the position at which new messages are added to the frame]]
    property "InsertMode" { Type = InsertMode }

    __Doc__[[The power of the fade-out animation for disappearing messages]]
    property "FadePower" { Type = Number }
end)

__Doc__[[MovieFrames are used to play video files of some formats.]]
__Sealed__() __AutoProperty__()
class "MovieFrame" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Whether the subtitles should be shown for the movie]]
    property "SubtitlesEnabled" { Type = Boolean, Set = "EnableSubtitles" }
end)

__Doc__[[QuestPOIFrames are used to draw blobs of interest points for quest on the world map]]
__Sealed__() __AutoProperty__()
class "QuestPOIFrame" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")
end)

__Sealed__() __AutoProperty__()
class "ScenarioPOIFrame" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")
end)

__Doc__[[ScrollFrame is used to show a large body of content through a small window. The ScrollFrame is the size of the "window" through which you want to see the larger content, and it has another frame set as a "ScrollChild" containing the full content.]]
__Sealed__() __AutoProperty__()
class "ScrollFrame" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[Gets the frame scrolled by the scroll frame]]
    function GetScrollChild(self)
        return UI.GetUIWrapper(self.UIElement:GetScrollChild())
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the scroll frame's current horizontal scroll position]]
    property "HorizontalScroll" { Type = Number }

    __Doc__[[the scroll frame's vertical scroll position]]
    property "VerticalScroll" { Type = Number }

    __Doc__[[The frame scrolled by the scroll frame]]
    property "ScrollChild" { Type = Region }
end)

__Doc__[[The most sophisticated control over text display is offered by SimpleHTML widgets. When its text is set to a string containing valid HTML markup, a SimpleHTML widget will parse the content into its various blocks and sections, and lay the text out. While it supports most common text commands, a SimpleHTML widget accepts an additional argument to most of these; if provided, the element argument will specify the HTML elements to which the new style information should apply, such as formattedText:SetTextColor("h2", 1, 0.3, 0.1) which will cause all level 2 headers to display in red. If no element name is specified, the settings apply to the SimpleHTML widget's default font.]]
__Sealed__() __AutoProperty__()
class "SimpleHTML" (function(_ENV)
    inherit "Frame"
    extend "IFont"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    class "Element" (function(_ENV)
        ----------------------------------------------
        ------------------ Property ------------------
        ----------------------------------------------
        __Doc__[[The owner of the element]]
        property "Owner" { Type = SimpleHTML }

        __Doc__[[The target element in the html like 'h2']]
        property "Element" { Type = String }

        __Doc__[[whether long lines of text are indented when wrapping]]
        property "IndentedWordWrap" {
            Get = function (self)
                return self.Owner:GetIndentedWordWrap(self.Element)
            end,
            Set = function (self, value)
                self.Owner:SetIndentedWordWrap(self.Element, value)
            end,
            Type = Boolean,
        }

        __Doc__[[the Font object]]
        property "FontObject" {
            Get = function (self)
                return self.Owner:GetFontObject(self.Element)
            end,
            Set = function (self, obj)
                self.Owner:SetFontObject(self.Element, obj)
            end,
        }

        __Doc__[[the font settings]]
        property "Font" {
            Type = FontType,
            Get = function(self)
                local filename, fontHeight, flags = self.Owner:GetFont(self.Element)
                local outline, monochrome = "NONE", false
                if flags then
                    if flags:find("THICKOUTLINE") then
                        outline = "THICK"
                    elseif flags:find("OUTLINE") then
                        outline = "NORMAL"
                    end
                    if flags:find("MONOCHROME") then
                        monochrome = true
                    end
                end
                return FontType(filename, fontHeight, outline, monochrome)
            end,
            Set = function(self, font)
                local flags

                if font.outline then
                    if font.outline == "NORMAL" then
                        flags = "OUTLINE"
                    elseif font.outline == "THICK" then
                        flags = "THICKOUTLINE"
                    end
                end
                if font.monochrome then
                    if flags then
                        flags = flags..",MONOCHROME"
                    else
                        flags = "MONOCHROME"
                    end
                end
                return self.Owner:SetFont(self.Element, font.font, font.height, flags)
            end,
        }

        __Doc__[[The font path]]
        property "FontPath" {
            Type = NEString,
            Get = function(self) return (self.Owner:GetFont(self.Element)) end,
            Set = function(self, val)
                local _, fontHeight, flags = self.Owner:GetFont(self.Element)
                return self.Owner:SetFont(self.Element, val, fontHeight, flags)
            end,
        }

        __Doc__[[The font height]]
        property "FontHeight" {
            Type = PositiveNumber,
            Get = function(self)
                local _, fontHeight = self.Owner:GetFont(self.Element)
                return fontHeight
            end,
            Set = function(self, height)
                local filename, fontHeight, flags = self.Owner:GetFont(self.Element)
                return self.Owner:SetFont(self.Element, filename, height, flags)
            end,
        }

        __Doc__[[The font's outline setting]]
        property "Outline" {
            Type = OutlineType,
            Get = function(self)
                local _, _, flags = self.Owner:GetFont(self.Element)

                if flags then
                    if flags:find("THICKOUTLINE") then
                        return "THICK"
                    elseif flags:find("OUTLINE") then
                        return "NORMAL"
                    end
                end

                return "NONE"
            end,
            Set = function(self, val)
                local filename, fontHeight, oflags = self.Owner:GetFont(self.Element)
                local flags

                if val == "NORMAL" then
                    flags = "OUTLINE"
                elseif val == "THICK" then
                    flags = "THICKOUTLINE"
                end

                if oflags and oflags:find("MONOCHROME") then
                    if flags then
                        flags = flags..",MONOCHROME"
                    else
                        flags = "MONOCHROME"
                    end
                end
                return self.Owner:SetFont(self.Element, filename, fontHeight, flags)
            end,
        }

        __Doc__[[The Font's monochrome setting]]
        property "Monochrome" {
            Type = Boolean,
            Get = function(self)
                local _, _, flags = self.Owner:GetFont(self.Element)

                if flags:find("MONOCHROME") then
                    return true
                else
                    return false
                end
            end,
            Set = function(self, val)
                local filename, fontHeight, flags = self.Owner:GetFont(self.Element)

                if flags then
                    if val and not flags:find("MONOCHROME") then
                        flags = flags .. ",MONOCHROME"
                    elseif not val then
                        flags = flags:gsub("%s*,?%s*MONOCHROME%s*,?%s*", "")
                    end
                else
                    flags = val and "MONOCHROME" or ""
                end

                return self.Owner:SetFont(self.Element, filename, fontHeight, flags)
            end,
        }
        __Doc__[[the fontstring's horizontal text alignment style]]
        property "JustifyH" {
            Get = function (self)
                return self.Owner:GetJustifyH(self.Element)
            end,
            Set = function (self, value)
                self.Owner:SetJustifyH(self.Element, value)
            end,
            Type = JustifyHType,
        }

        __Doc__[[the fontstring's vertical text alignment style]]
        property "JustifyV" {
            Get = function (self)
                return self.Owner:GetJustifyV(self.Element)
            end,
            Set = function (self, value)
                self.Owner:SetJustifyV(self.Element, value)
            end,
            Type = JustifyVType,
        }

        __Doc__[[the color of the font's text shadow]]
        property "ShadowColor" {
            Get = function(self)
                return Color(self.Owner:GetShadowColor(self.Element))
            end,
            Set = function(self, color)
                self.Owner:SetShadowColor(self.Element, color.r, color.g, color.b, color.a)
            end,
            Type = Color,
        }

        __Doc__[[the offset of the fontstring's text shadow from its text]]
        property "ShadowOffset" {
            Get = function(self)
                return Dimension(self.Owner:GetShadowOffset(self.Element))
            end,
            Set = function(self, offset)
                self.Owner:SetShadowOffset(self.Element, offset.x, offset.y)
            end,
            Type = Dimension,
        }

        __Doc__[[the fontstring's amount of spacing between lines]]
        property "Spacing" {
            Get = function (self)
                return self.Owner:GetSpacing(self.Element)
            end,
            Set = function (self, value)
                self.Owner:SetSpacing(self.Element, value)
            end,
            Type = Number,
        }

        __Doc__[[the fontstring's default text color]]
        property "TextColor" {
            Get = function(self)
                return Color(self.Owner:GetTextColor(self.Element))
            end,
            Set = function(self, color)
                self.Owner:SetTextColor(self.Element, color.r, color.g, color.b, color.a)
            end,
            Type = Color,
        }

        ----------------------------------------------
        ----------------- Constructor ----------------
        ----------------------------------------------
        function Element(self, owner)
            self.Owner = owner
        end

        ----------------------------------------------
        ----------------- Meta-Method ----------------
        ----------------------------------------------
        function __index(self, key)
            self.Element = key
            return self
        end

        __call = __index
    end)

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the format string used for displaying hyperlinks in the frame]]
    property "HyperlinkFormat" { Type = String }

    __Doc__[[Whether hyperlinks in the frame's text are interactive]]
    property "HyperlinksEnabled" { Type = Boolean }

    __Doc__[[whether long lines of text are indented when wrapping]]
    property "IndentedWordWrap" { Type = Boolean }

    __Doc__[[The content of the html viewer]]
    property "Text" { Type = String }

    __Doc__[[The element accessor]]
    property "Element" { Set = false, Default = function(self) return Element(self) end }
end)

__Doc__[[Sliders are elements intended to display or allow the user to choose a value in a range.]]
__Sealed__() __AutoProperty__()
class "Slider" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function GetThumbTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetThumbTexture())
    end

    function SetThumbTexture(self, texture, layer)
        self.__Slider_DrawLayer = layer or "ARTWORK"
        self.UIElement:SetThumbTexture(texture, layer)
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Graphics layer in which the texture should be drawn]]
    __Handler__(function(self, layer)
        self.UIElement:SetThumbTexture(self.UIElement:GetThumbTexture(), layer)
    end)
    property "DrawLayer" { Field = "__Slider_DrawLayer", Type = DrawLayer, Default = "ARTWORK" }

    __Doc__[[the orientation of the slider]]
    property "Orientation" { Type = Orientation }

    __Doc__[[the texture object for the slider thumb]]
    property "ThumbTexture" { }

    __Doc__[[the value representing the current position of the slider thumb]]
    property "Value" { Type = Number }

    __Doc__[[the minimum increment between allowed slider values]]
    property "ValueStep" { Type = Number }

    __Doc__[[whether user interaction with the slider is allowed]]
    property "Enabled" { Type = Boolean }

    __Doc__[[the minimum and maximum values of the slider bar]]
    property "MinMaxValue" {
        Get = function(self)
            return MinMax(self:GetMinMaxValues())
        end,
        Set = function(self, value)
            return self:SetMinMaxValues(value.min, value.max)
        end,
        Type = MinMax,
    }

    __Doc__[[the steps per page of the slider bar]]
    property "StepsPerPage" { Type = Number }

    __Doc__[[Whether obey the step setting when drag the slider bar]]
    property "ObeyStepOnDrag" { Type = Boolean }
end)

__Doc__[[StatusBars are similar to Sliders, but they are generally used for display as they don't offer any tools to receive user input.]]
__Sealed__() __AutoProperty__()
class "StatusBar" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function GetStatusBarTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetStatusBarTexture())
    end

    function SetStatusBarTexture(self, texture, layer)
        self.__StatusBar_DrawLayer = layer
        self.UIElement:SetStatusBarTexture(texture, layer)
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Graphics layer in which the texture should be drawn]]
    __Handler__(function(self, layer)
        self.UIElement:SetStatusBarTexture(self.UIElement:GetStatusBarTexture(), layer)
    end)
    property "DrawLayer" { Field = "__StatusBar_DrawLayer", Type = DrawLayer, Default = "ARTWORK" }

    __Doc__[[the minimum and maximum values of the status bar]]
    property "MinMaxValue" {
        Get = function(self)
            return MinMax(self:GetMinMaxValues())
        end,
        Set = function(self, set)
            self:SetMinMaxValues(set.min, set.max)
        end,
        Type = MinMax,
    }

    __Doc__[[the orientation of the status bar]]
    property "Orientation" { Type = Orientation }

    __Doc__[[the color shading for the status bar's texture]]
    property "StatusBarColor" {
        Get = function(self)
            return Color(self:GetStatusBarColor())
        end,
        Set = function(self, colorTable)
            self:SetStatusBarColor(colorTable.r, colorTable.g, colorTable.b, colorTable.a)
        end,
        Type = Color,
    }

    __Doc__[[the texture used for drawing the filled-in portion of the status bar]]
    property "StatusBarTexture" { }

    __Doc__[[The texture atlas]]
    property "StatusBarAtlas" { Type = String }

    __Doc__[[ the value of the status bar]]
    property "Value" { Type = Number }

    __Doc__[[whether the status bar's texture is rotated to match its orientation]]
    property "RotatesTexture" { Type = Boolean }

    __Doc__[[Whether the status bar's texture is reverse filled]]
    property "ReverseFill" { Type = Boolean }

    __Doc__[[The fill style of the status bar]]
    property "FillStyle" { }
end)

------------------------------------------------------------
--                        Model                           --
------------------------------------------------------------
__Doc__[[Model provide a rendering environment which is drawn into the backdrop of their frame, allowing you to display the contents of an .m2 file and set facing, scale, light and fog information, or run motions associated]]
__Sealed__() __AutoProperty__()
class "Model" (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[the model's current fog color]]
    property "FogColor" {
        Get = function(self)
            return Color(self:GetFogColor())
        end,
        Set = function(self, colorTable)
            self:SetFogColor(colorTable.r, colorTable.g, colorTable.b, colorTable.a)
        end,
        Type = Color,
    }

    __Doc__[[the far clipping distance for the model's fog]]
    property "FogFar" { Type = Number }

    __Doc__[[the near clipping distance for the model's fog]]
    property "FogNear" { Type = Number }

    __Doc__[[the scale factor determining the size at which the 3D model appears]]
    property "ModelScale" { Type = Number }

    __Doc__[[the model file to be displayed]]
    property "Model" {
        Set = function(self, file)
            if file then
                self:SetModel(file)
            else
                self:ClearModel()
            end
        end,
        Type = NEString,
    }

    __Doc__[[the position of the 3D model within the frame]]
    property "Position" {
        Type = Position,
        Get = function(self) return Position(self:GetPosition()) end,
        Set = function(self, value) self:SetPosition(value.x, value.y, value.z) end,
    }

    __Doc__[[the light sources used when rendering the model]]
    property "Light" {
        Get = function(self)
            local enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB = self:GetLight()
            return LightType(
                enabled,
                omni,
                Position(dirX, dirY, dirZ),
                ambIntensity,
                Color(ambR, ambG, ambB),
                dirIntensity,
                Color(dirR, dirG, dirB)
            )
        end,
        Set = function(self, set)
            local enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB

            enabled = set.enabled or false
            omni = set.omni or false

            if set.dir then
                dirX, dirY, dirZ = set.dir.x, set.dir.y, set.dir.z

                if set.ambIntensity and set.ambColor then
                    ambIntensity = set.ambIntensity
                    ambR, ambG, ambB = set.ambColor.r, set.ambColor.g, set.ambColor.b

                    if set.dirIntensity and set.dirColor then
                        dirIntensity = set.dirIntensity
                        dirR, dirG, dirB = set.dirColor.r, set.dirColor.g, set.dirColor.b
                    end
                end
            end

            return self:SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
        end,
        Type = LightType,
    }

    __Doc__[[The model's desaturation]]
    property "Desaturation" { Type = ColorFloat }

    __Doc__[[The model's camera distance]]
    property "CameraDistance" { Type = NUmber }

    __Doc__[[The model's camera facing]]
    property "CameraFacing" { Type = NUmber }

    __Doc__[[The model's camera position]]
    property "CameraPosition" {
        Type = Position,
        Get = function(self) return Position(self:GetCameraPosition()) end,
        Set = function(self, value) self:SetCameraPosition(value.x, value.y, value.z) end,
    }

    __Doc__[[The model's camera roll]]
    property "CameraRoll" { Type = Number }

    __Doc__[[The model's camera target position]]
    property "CameraTarget" {
        Type = Position,
        Get = function(self) return Position(self:GetCameraTarget()) end,
        Set = function(self, value) self:SetCameraTarget(value.x, value.y, value.z) end,
    }

    __Doc__[[The model's alpha]]
    property "ModelAlpha" { Type = ColorFloat }

    __Doc__[[The model's draw layer]]
    property "ModelDrawLayer" { Type = DrawLayer }

    __Doc__[[The model's scale]]
    property "ModelScale" { Type = Number }

    __Doc__[[The model's facing]]
    property "Facing" { Type = Number }

    __Doc__[[The model's pitch]]
    property "Pitch" { Type = Number }

    __Doc__[[The model's roll]]
    property "Roll" { Type = Number }
end)

__Doc__[[PlayerModels are the most commonly used subtype of Model frame. They expand on the Model type by adding functions to quickly set the model to represent a particular player or creature, by unitID or creature ID.]]
__Sealed__() __AutoProperty__()
class "PlayerModel" (function(_ENV)
    inherit "Model"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The displayed model id]]
    property "DisplayInfo" { Type = Number }

    __Doc__[[Whether blend]]
    property "DoBlend" { Type = Boolean }

    __Doc__[[Whether keep model when hidden]]
    property "KeepModelOnHide" { Type = Boolean }
end)

__Sealed__() __AutoProperty__()
class "CinematicModel" (function(_ENV)
    inherit "PlayerModel"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")
end)

__Sealed__() __AutoProperty__()
class "DressUpModel" (function(_ENV)
    inherit "PlayerModel"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Whether auto dress]]
    property "AutoDress" { Type = Boolean }

    __Doc__[[Whether sheathed the weapon]]
    property "Sheathed" { Type = Boolean }

    __Doc__[[Whether use transmog skin]]
    property "UseTransmogSkin" { Type = Boolean }
end)

__Sealed__() __AutoProperty__()
class "TabardModel" (function(_ENV)
    inherit "PlayerModel"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    InstallPrototype("Frame")

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function GetLowerEmblemTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetLowerEmblemTexture())
    end

    function GetUpperEmblemTexture(self)
        return UI.GetUIWrapper(self.UIElement:GetUpperEmblemTexture())
    end
end)

------------------------------------------------------------
--                        Clear                           --
------------------------------------------------------------
do
    for name, ele in pairs(UI_PROTOTYPE) do
        pcall(ele.SetParent, ele, nil)
    end

    wipe(UI_PROTOTYPE)
    UI_PROTOTYPE = nil

    collectgarbage()
end