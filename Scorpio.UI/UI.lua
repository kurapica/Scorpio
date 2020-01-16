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
        { name = "file",        type = String,  require = true },
        { name = "color",       type = ColorType },
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

----------------------------------------------
--                 UIObject                 --
----------------------------------------------
__Abstract__() class "UIObject"(function(_ENV)

    ----------------------------------------------
    --                 Helpers                  --
    ----------------------------------------------
    local _NameMap              = setmetatable({}, META_WEAKKEY)
    local _ChildMap             = setmetatable({}, META_WEAKKEY)

    local _SetParent            = getRealMethodCache("SetParent")
    local _GetParent            = getRealMethodCache("GetParent")
    local _GetNew               = getRealMetaMethodCache("__new")

    local validate              = Struct.ValidateValue

    ----------------------------------------------
    --              Static Methods              --
    ----------------------------------------------
    --- Gets the ui object with the full name
    __Static__() __Arguments__{ NEString }
    function FromName(name)
        local obj

        for str in name:gmatch("[^%.]+") do
            if not obj then
                obj             = validate(UI, _G[str], true)
            else
                local children  = _ChildMap[obj[0]]
                obj             = children and children[str]
            end
            if not obj then return end
        end

        return obj
    end

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    --- Gets the ui object's name or full name
    __Final__() function GetName(self, full)
        local name              = _NameMap[self[0]]
        if full then
            local globalUI      = _G[name]
            if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
                return name
            else
                local parent    = self:GetParent()
                local pname     = parent and parent:GetName(true)
                if pname then return pname .. "." .. name end
            end
        else
            return name
        end
    end

    --- Gets the parent of ui object
    __Final__() function GetParent(self)
        return GetProxyUI(_GetParent[getmetatable(self)](self))
    end

    --- Sets the ui object's name
    __Final__() __Arguments__{ NEString }
    function SetName(self, name)
        local oname             = _NameMap[self[0]]
        if oname == name then return end

        local globalUI          = _G[oname]
        if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
            error("Usage: UI:SetName(name) - UI with global name can't change its name", 2)
        end

        local parent            = self:GetParent()
        if parent then
            local pui           = parent[0]
            local children      = _ChildMap[pui]

            if children and children[name] then
                error("Usage: UI:SetName(name) - the name is used by another child", 2)
            end

            if not children then
                children        = {}
                _ChildMap[pui]  = children
            end

            children[oname]     = nil
            children[name]      = self
        end

        _NameMap[self[0]]       = name
    end

    --- Sets the ui object's parent
    __Final__() __Arguments__{ UI/nil }
    function SetParent(self, parent)
        local oparent           = self:GetParent()
        if oparent == parent or IsSameUI(oparent, parent) then return end

        local name              = _NameMap[self[0]]
        local setParent         = _SetParent[getmetatable(self)]

        if oparent then
            local pui           = oparent[0]
            if _ChildMap[pui] and _ChildMap[pui][name] == self then
                _ChildMap[pui][name] = nil
            end
        end

        if parent == nil then return setParent(self, nil) end

        local pui               = parent[0]
        local children          = _ChildMap[pui]

        if children and children[name] and children[name] ~= self then
            error("Usage : UI:SetParent([parent]) : parent has another child with the same name.", 2)
        end

        setParent(self, GetRawUI(parent))

        if not children then
            children            = {}
            _ChildMap[pui]      = children
        end

        children[name]          = self
    end

    --- Gets the children of the frame
    __Iterator__() function GetChilds(self)
        local children          = _ChildMap[self[0]]
        if children then
            for name, child in pairs(children) do
                yield(name, child)
            end
        end
    end

    --- Gets the child with the given name
    function GetChild(self, name)
        local children          = _ChildMap[self[0]]
        return children and children[name]
    end

    ----------------------------------------------
    --                 Dispose                  --
    ----------------------------------------------
    function Dispose(self)
        local ui                = self[0]
        local name              = _NameMap[ui]

        self:SetParent(nil)

        -- Dispose the children
        local children          = _ChildMap[ui]
        if children then
            for _, obj in pairs(children) do obj:Dispose() end
        end

        -- Clear it from the _G
        local globalUI          = _G[name]
        if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
            _G[name]            = nil
        end

        -- Clear register datas
        _NameMap[ui]            = nil
        _ChildMap[ui]           = nil
    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Final__() __Arguments__{ NEString, UI/UIParent, Any * 0 }
    function __exist(cls, name, parent, ...)
        local children          = _ChildMap[parent[0]]
        local object            = children and children[name]

        if object then
            if getmetatable(object) == cls then
                return object
            else
                throw(("Usage : %s(name, parent, ...) - the parent already has a child named '%s'."):format(GetNamespaceName(cls), name))
            end
        end
    end

    __Final__() __Arguments__{ NEString, UI/UIParent, Any * 0 }
    function __new(cls, name, parent, ...)
        local self              = _GetNew[cls](cls, name, parent, ...)
        parent                  = parent[0]

        local children          = _ChildMap[parent]

        if not children then
            children            = {}
            _ChildMap[parent]   = children
        end

        children[name]          = self
        _NameMap[self[0]]       = name

        return self
    end

    ----------------------------------------------
    --               Meta-Method                --
    ----------------------------------------------
    __index                     = GetChild
end)

----------------------------------------------
--                 Template                 --
----------------------------------------------
__Sealed__() class "__Template__" (function (_ENV)
    extend "IInitAttribute"

    local _Template             = {}

    local isUIObjectType        = UI.IsUIObjectType
    local getSuperCTOR          = Class.GetSuperMetaMethod
    local yield                 = coroutine.yield

    -----------------------------------------------------------
    --                     static method                     --
    -----------------------------------------------------------
    __Static__() __Iterator__()
    function GetElements(cls)
        local elements          = _Template[cls]
        if not elements then return end
        for k, v in pairs(elements) do yield(k, v) end
    end

    __Static__()
    function GetElementType(cls, name)
        local elements          = _Template[cls]
        return elements and elements[name]
    end

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    --- modify the target's definition
    -- @param   target                      the target
    -- @param   targettype                  the target type
    -- @param   definition                  the target's definition
    -- @param   owner                       the target's owner
    -- @param   name                        the target's name in the owner
    -- @param   stack                       the stack level
    -- @return  definition                  the new definition
    function InitDefinition(self, target, targettype, definition, owner, name, stack)
        if targettype == AttributeTargets.Method then
            if name ~= "__ctor" then
                error("The __Template__ can only be used on the constructor, not nomral method", stack + 1)
            end

            if type(self[1]) ~= "table" then
                error("The __Template__ lack the element settings", stack + 1)
            end

            local elements      = {}

            for k, v in pairs(self[1]) do
                if type(k) == "string" and isUIObjectType(v) then
                    elements[k] = v
                else
                    error("The __Template__'s element type must be an ui object type", stack + 1)
                end
            end

            _Template[owner]    = elements

            return function(self, ...)
                local sctor = getSuperCTOR(target, "__ctor")
                if sctor then sctor(self, ...) end

                for k, v in pairs(elements) do
                    v(k, self)
                end

                return definition(self, ...)
            end
        elseif targettype == AttributeTargets.Class then
            if type(definition) == "table" then
                local new       = { self[0] }
                local elements  = {}

                for k, v in pairs(definition) do
                    if type(k) == "string" and isUIObjectType(v) then
                        elements[k] = v
                    else
                        new[k]  = v
                    end
                end

                _Template[target] = elements

                new.__ctor      = function(self, ...)
                    local sctor = getSuperCTOR(target, "__ctor")
                    if sctor then sctor(self, ...) end

                    for k, v in pairs(elements) do
                        v(k, self)
                    end
                end

                return new
            else
                error("The __Template__ require the class use table of element type settings as definition", stack + 1)
            end
        end
    end

    -----------------------------------------------------------
    --                       property                       --
    -----------------------------------------------------------
    property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Class }

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ ClassType/nil }
    function __new(_, cls) return { [0] = cls }, true end

    __Arguments__{ RawTable }
    function __new(_, setting) return { setting }, true  end
end)