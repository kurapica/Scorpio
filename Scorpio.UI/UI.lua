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
    --                Predefined                --
    ----------------------------------------------
    class "UIObject" {}

    ----------------------------------------------
    --              Static Methods              --
    ----------------------------------------------
    local _ProxyMap             = setmetatable({}, META_WEAKALL)
    local _RawUIMap             = setmetatable({}, META_WEAKALL)

    local isSubType             = Class.IsSubType

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
    __Static__() __Arguments__{ UI }
    function RegisterProxyUI(self)
        _ProxyMap[self[0]]      = self
    end

    __Static__()
    function IsUIObject(self)
        return type(self) == "table" and type(self[0]) == "userdata"
    end

    __Static__()
    function IsUIObjectType(cls)
        return isSubType(cls, UIObject)
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
    enum "VertexIndexType" {
        UpperLeft   = _G.UPPER_LEFT_VERTEX  or 1,
        LowerLeft   = _G.LOWER_LEFT_VERTEX  or 2,
        UpperRight  = _G.UPPER_RIGHT_VERTEX or 3,
        LowerRight  = _G.LOWER_RIGHT_VERTEX or 4,
    }

    __Sealed__() __Default__("STANDARD")
    enum "FillStyle" {
        "STANDARD",
        "STANDARD_NO_RANGE_FILL",
        "CENTER",
        "REVERSE",
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

        -- Actor
        "OnModelLoading",
        "OnModelLoaded",
        "OnAnimFinished",
    }
end

----------------------------------------------
--            Data Types(UI.xsd)            --
----------------------------------------------
do
    __Sealed__()
    struct "AtlasType" {
        { name = "atlas",       type = String },
        { name = "useAtlasSize",type = Boolean },
    }

    __Sealed__()
    struct "AnimOrderType" {
        __base = Integer,
        function(val, onlyvalid) if (val < 1 or val > 100) then return onlyvalid or "the %s must between [1, 100]" end end
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
        { name = "width",       type = Number, require = true },
        { name = "height",      type = Number, require = true },
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
    struct "GradientType" {
        { name = "orientation", type = Orientation },
        { name = "mincolor",    type = Color + ColorType },
        { name = "maxcolor",    type = Color + ColorType },
    }

    __Sealed__()
    struct "AlphaGradientType" {
        { name = "start",       type = Number },
        { name = "length",      type = Number }
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
        { name = "tileEdge",    type = Boolean },
        { name = "tileSize",    type = Number },
        { name = "edgeSize",    type = Number },
        { name = "alphaMode",   type = AlphaMode },
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
        { name = "left",        type = Number },
        { name = "right",       type = Number },
        { name = "top",         type = Number },
        { name = "bottom",      type = Number },
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
        { name = "ambColor",    type = Color + ColorType },
        { name = "dirIntensity",type = ColorFloat },
        { name = "dirColor",    type = Color + ColorType },
    }

    __Sealed__()
    struct "TextureType" {
        { name = "file",        type = String + Number,  require = true },
        { name = "color",       type = ColorType },
    }

    __Sealed__()
    struct "FadeoutOption" {
        { name = "duration",    type = Number, require = true },
        { name = "delay",       type = Number, default = 0 },
        { name = "start",       type = Number, default = 1 },
        { name = "stop",        type = Number, default = 0 },
        { name = "autohide",    type = Boolean },
    }
end

----------------------------------------------
--                   Font                   --
----------------------------------------------
__Sealed__()
struct "FontObject" {  function(val, onlyvalid) if not (type(val) == "table" and val.GetObjectType and val:GetObjectType() == "Font") then return onlyvalid or "the %s must a font object" end end }

--- The Font object is to be shared between other objects that share font characteristics
__Sealed__() __Final__()
class "Font" (function(_ENV)
    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    for name, method in pairs(getmetatable(_G.GameFontNormal).__index) do
        _ENV[name]              = method
    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Arguments__{ NEString }
    function __new(_, name)
        return CreateFont(name), true
    end
end)
