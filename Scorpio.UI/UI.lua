--========================================================--
--                Scorpio UI FrameWork                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/27                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI"                       "1.0.0"
--========================================================--

----------------------------------------------
--                 UI Core                  --
----------------------------------------------
__Sealed__() struct "Scorpio.UI" (function(_ENV)
    ----------------------------------------------
    --              Static Methods              --
    ----------------------------------------------
    local _ProxyMap             = setmetatable({}, META_WEAKALL)
    local _RawUIMap             = setmetatable({}, META_WEAKALL)

    --- Gets the raw ui of the given ui element, normally created by CreateFrame
    __Static__()  __Arguments__{ UI }
    function GetRawUI(self)
        return _RawUIMap[self[0]] or self
    end

    --- Gets the proxy ui of the given ui element, maybe the raw ui itself
    __Static__()  __Arguments__{ UI }
    function GetProxyUI(self)
        return _ProxyMap[self[0]] or self
    end

    --- Whether the two UI is the same
    function IsSameUI(self, target)
        return type(self) == "table" and type(target) == "table" and type(self[0]) == "userdata" and self[0] == target[0]
    end

    --- Registers the raw ui element
    __Static__() __Arguments__{ UI }
    function RegisterRawUI(self)
        _RawUIMap[self[0]]      = _RawUIMap[self[0]] or self
    end

    --- Registers the proxy ui element
    __Static__()   __Arguments__{ UI }
    function RegisterProxyUI(self)
        _ProxyMap[self[0]]      = self
    end

    ----------------------------------------------
    --                Validator                 --
    ----------------------------------------------
    function __valid(self, onlyvalid)
        if not (type(self) == "table" and type(self[0]) == "userdata") then
            return onlyvalid or "the %s must be a valid ui element"
        end
    end
end)

----------------------------------------------
--              System Prepare              --
----------------------------------------------
Environment.RegisterGlobalNamespace("Scorpio.UI")

----------------------------------------------
--              Basic Features              --
----------------------------------------------
namespace "Scorpio.UI"

----------------------------------------------
--              Enums(UI.xsd)               --
----------------------------------------------
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

    __Sealed__()
    enum "WrapMode" {
        "CLAMP",
        "REPEAT",
        "CLAMPTOBLACK",
        "CLAMPTOBLACKADDITIVE",
        "CLAMPTOWHITE",
        "MIRROR",
    }

    __Sealed__() __Default__"NONE"
    enum "AnimLoopType" {
        "NONE",
        "REPEAT",
        "BOUNCE",
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
        "OnUiMapChanged",
        "OnRequestNewSize",

        -- Animation
        "OnPlay",
        "OnPause",
        "OnStop",
        "OnFinished",
        "OnLoop",
    }
end

----------------------------------------------
--            Data Types(UI.xsd)            --
----------------------------------------------
do
    __Sealed__() __Base__(Integer)
    struct "AnimOrderType" {
        function(val, onlyvalid) if (val < 1 or val > 100) then return onlyvalid or "the %s must between 1 and 100" end end
    }

    __Sealed__()
    struct "Dimension" {
        { name = "x",           type = Number },
        { name = "y",           type = Number },
    }

    __Sealed__()
    struct "Position" {
        { name = "x",           type = Number },
        { name = "y",           type = Number },
        { name = "z",           type = Number },
    }

    __Sealed__()
    struct "Size" {
        { name = "width",       type = Number },
        { name = "height",      type = Number },
    }

    __Sealed__()
    struct "MinMax" {
        { name = "min",         type = Number, require = true },
        { name = "max",         type = Number, require = true },

        function(val, onlyvalid)
            return val.min > val.max and (onlyvalid or "%s.min can't be greater than %s.max") or nil
        end,
    }

    __Sealed__()
    struct "Inset" {
        { name = "left",        type = Number },
        { name = "right",       type = Number },
        { name = "top",         type = Number },
        { name = "bottom",      type = Number },
    }

    __Sealed__()
    struct "ShadowType" {
        { name = "Color",       type = Color },
        { name = "Offset",      type = Dimension },
    }

    __Sealed__()
    struct "GradientType" {
        { name = "orientation", type = Orientation },
        { name = "MinColor",    type = Color },
        { name = "MaxColor",    type = Color },
    }

    __Sealed__()
    struct "FontType" {
        { name = "font",        type = String },
        { name = "height",      type = Number },
        { name = "outline",     type = OutlineType },
        { name = "monochrome",  type = Boolean },
    }

    __Sealed__()
    struct "BackdropType" {
        { name = "bgFile",      type = String },
        { name = "edgeFile",    type = String },
        { name = "tile",        type = Boolean },
        { name = "tileSize",    type = Number },
        { name = "edgeSize",    type = Number },
        { name = "insets",      type = Inset },
    }

    __Sealed__()
    struct "Anchor" {
        { name = "point",       type = FramePoint, require = true },
        { name = "x",           type = Number },
        { name = "y",           type = Number },
        { name = "relativeTo",  type = String },
        { name ="relativePoint",type = FramePoint },
    }

    __Sealed__()
    struct "Anchors" { Anchor }

    __Sealed__()
    struct "RectType" {
        { name = "ULx",         type = Number },
        { name = "ULy",         type = Number },
        { name = "LLx",         type = Number },
        { name = "LLy",         type = Number },
        { name = "URx",         type = Number },
        { name = "URy",         type = Number },
        { name = "LRx",         type = Number },
        { name = "LRy",         type = Number },
    }

    __Sealed__()
    struct "TexCoords" { RectType }

    __Sealed__()
    struct "AnimOriginType" {
        { name = "point",       type = FramePoint, Default = "CENTER" },
        { name = "x",           type = Number },
        { name = "y",           type = Number },
    }

    __Sealed__()
    struct "LightType" {
        { name = "enabled",     type = Boolean },
        { name = "omni",        type = Boolean },
        { name = "dir",         type = Position },
        { name = "ambIntensity",type = ColorFloat },
        { name = "ambColor",    type = Color },
        { name = "dirIntensity",type = ColorFloat },
        { name = "dirColor",    type = Color },
    }
end
