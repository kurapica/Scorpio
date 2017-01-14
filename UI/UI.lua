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

------------------------------------------------------------
--                     Enums(UI.xsd)                      --
------------------------------------------------------------
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
enum "AnimLoopType" {
    "NONE",
    "REPEAT",
    "BOUNCE",
}

__Sealed__()
enum "AnimSmoothType" {
    "NONE",
    "IN",
    "OUT",
    "IN_OUT",
    "OUT_IN",
}

__Sealed__()
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

------------------------------------------------------------
--                     Struct(UI.xsd)                     --
------------------------------------------------------------
__Sealed__() __Base__(PositiveInteger)
struct "AnimOrderType" {
    function(val) assert(val <= 100, "%s must between 1 and 100.") end
}

__Sealed__() __Base__(Number)
struct "ColorFloat" {
    function (val) assert(val >= 0 and val <= 1, "%s must between 0.0 and 1.0.") end
}

__Sealed__()
struct "ColorType" {
    { Name = "r",   Type = ColorFloat, Require = true },
    { Name = "g",   Type = ColorFloat, Require = true },
    { Name = "b",   Type = ColorFloat, Require = true },
    { Name = "a",   Type = ColorFloat, Default = 1 },

    GetColorCode = function(val)
        return ("\124cff%.2x%.2x%.2x"):format(val.r * 255, val.g * 255, val.b * 255)
    end,
}

__Sealed__()
struct "Dimension" {
    { Name = "x", Type = Number, Require = true },
    { Name = "y", Type = Number, Require = true },
}

__Sealed__()
struct "Inset" {
    { Name = "left",    Type = Number, Require = true },
    { Name = "right",   Type = Number, Require = true },
    { Name = "top",     Type = Number, Require = true },
    { Name = "bottom",  Type = Number, Require = true },
}

__Sealed__()
struct "ShadowType" {
    { Name = "Color",  Type = ColorType },
    { Name = "Offset", Type = Dimension },
}

__Sealed__()
struct "GradientType" {
    { Name = "orientation", Type = Orientation },
    { Name = "MinColor",    Type = ColorType },
    { Name = "MaxColor",    Type = ColorType },
}

__Sealed__()
struct "FontType" {
    { Name = "font",        Type = String },
    { Name = "height",      Type = Number },
    { Name = "outline",     Type = OutlineType },
    { Name = "monochrome",  Type = Boolean },
    { Name = "justifyV",    Type = JustifyVType },
    { Name = "justifyH",    Type = JustifyHType },
    { Name = "spacing",     Type = NumberNil },
    { Name = "fixedSize",   Type = BooleanNil },
    { Name = "filter",      Type = BooleanNil },
    { Name = "Color",       Type = ColorType },
    { Name = "Shadow",      Type = ShadowType },
}

__Sealed__()
struct "BackdropType" {
    { Name = "bgFile",          Type = String },
    { Name = "edgeFile",        Type = String },
    { Name = "tile",            Type = Boolean },
    { Name = "tileSize",        Type = Number },
    { Name = "edgeSize",        Type = Number },
    { Name = "BackgroundInsets",Type = Inset },
    { Name = "alphaMode",       Type = AlphaMode, Default = "BLEND" },
    { Name = "Color",           Type = ColorType },
    { Name = "BorderColor",     Type = ColorType },
}

__Sealed__()
struct "Anchor" {
    { Name = "point",           Type = FramePoint, Require = true }
    { Name = "x",               Type = NumberNil }
    { Name = "y",               Type = NumberNil }
    { Name = "relativeTo",      Type = String }
    { Name = "relativePoint",   Type = FramePoint }
}

__Sealed__()
struct "Anchors" { Anchor }

__Sealed__()
struct "TexCoord" {
    { Name = "left",    Type = Number, Require = true },
    { Name = "right",   Type = Number, Require = true },
    { Name = "top",     Type = Number, Require = true },
    { Name = "bottom",  Type = Number, Require = true },
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

------------------------------------------------------------
--                           UI                           --
------------------------------------------------------------
__Sealed__() __Abstract__() __ObjMethodAttr__{ Inheritable = true }
class (UI) (function(_ENV)

    _UIWrapperMap = setmetatable({}, META_WEAKKEY)

    ----------------------------------------------
    ---------------- Static-Method ---------------
    ----------------------------------------------
    __Doc__[[Get the wrapped object of ui element]]
    __Arguments__{ NEString }
    __Static__() function GetUIWrapper(element)
        element = _G[element]
        if type(element) ~= "table" then return end
        return GetUIWrapper(element)
    end

    __Arguments__{ Table }
    __Static__() function GetUIWrapper(element)
        if Reflector.ObjectIsClass(element, UI) then return element end
        if _UIWrapperMap[element] then return _UIWrapperMap[element] end

        if type(element[0]) ~= "userdata" or type(element.GetObjectType) ~= "function" then return end

        local frameType = element:GetObjectType()
        if frameType then return UI[frameType](element) end
    end

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[The method used to create the wow ui element, need to be overridden by widget-classes.]]
    function CreateUIElement(self, ...) end

    __Doc__[[Set the ui object's parent]]
    function SetParent(self, parent)
        if not parent then
            if self.Parent and self.Parent.Children[self.Name] == self then
                self.Parent.Children[self.Name] = nil
            end

            return
        end
    end

    __Doc__[[Get the ui object's parent]]
    function GetParent(self)

    end

    __Doc__[[Set the ui object's name]]
    function SetName(self, name)
    end

    __Doc__[[Get the ui object's name]]
    function GetName(self)
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The ui element controlled by the ui object]]
    property "UIElement" { Type = Table }

    __Doc__[[The Children of the ui object]]
    property "Children" { Field = "__UI_Children", Set = false, Default = function() return {} end }

    __Doc__[[The name of the ui object]]
    property "Name" { Type = NEString }

    __Doc__[[The parent of the ui object]]
    property "Parent" { Type = UI }

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
    end

    ----------------------------------------------
    ---------------- Constructor -----------------
    ----------------------------------------------
    __Arguments__{ Table }
    function UI(self, element)
        self.UIElement = element
        self[0] = element[0]
        _UIWrapperMap[element] = self
    end

    __Arguments__{ NEString, Table, { IsList = true, Nilable = true }}
    function UI(self, name, parent, ...)
        local element = self:CreateUIElement(name, parent, ...)


        self.UIElement = element
        self[0] = element[0]
        _UIWrapperMap[element] = self

        parent = GetUIWrapper(parent)

    end

    ----------------------------------------------
    ----------------- Meta-Method ----------------
    ----------------------------------------------
    __Arguments__{ NEString, Table, { IsList = true, Nilable = true }}
    function __exist(name, parent, ...)
        parent = GetUIWrapper(parent)

    end

    function __index(self, child)
    end
end)

------------------------------------------------------------
--                       UI Helper                        --
------------------------------------------------------------
function OnEventHandlerChanged(handler)
    local name = handler.Event
    local self = handler.Owner

    local _UI = rawget(self, "__UI")

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

function InstallPrototype(baseCls, prototype)
    local clsEnv = getfenv(2)

    -- Install Events
    for _, evt in Reflector.GetEnums(ScriptsType) do
        if prototype:HasScript(evt) and (not baseCls or not Reflector.HasEvent(baseCls, evt)) then
            __EventChangeHandler__(OnEventHandlerChanged)
            clsEnv.event(evt)
        end
    end

    -- Install Methods
    for name, func in pairs(getmetatable(prototype).__index) do
        if not baseCls or not baseCls[name] then
            clsEnv[name] = func
        end
    end

    -- Install CreateUIElement
    local frameType = prototype:GetObjectType()

    clsEnv.CreateUIElement = function(self, name, parent, ...)
        return CreateFrame(frameType, nil, parent, ...)
    end
end