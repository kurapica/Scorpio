--========================================================--
--             Scorpio UI Style FrameWork                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/11/28                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Style"                 "1.0.0"
--========================================================--

export {
    clone                       = Toolset.clone,
    validateStrutValue          = Struct.ValidateValue,
    isSubType                   = Class.IsSubType,
    getSubNS                    = Namespace.GetNamespace,
    tinsert                     = table.insert,

    isUIObject                  = UI.IsUIObject,
    isUIObjectType              = UI.IsUIObjectType,
    getElements                 = __Template__.GetElements,
    getElementType              = __Template__.GetElementType,
    getChild                    = UIObject.GetChild,
}

local isTypeValidDisabled       = System.Platform.TYPE_VALIDATION_DISABLED

local NIL
local _Property                 = {}
local _Methods                  = {}

local _Default                  = {}
local _Custom                   = setmetatable({}, META_WEAKKEY)

local function applyCustomProperty(target, name, value)
    if value == nil or value == NIL then
    else
    end
end

local function applyDefaultStyles(target, default)
    default                     = default or _Default[getmetatable(target)]
    if not default then return end

    for k, v in pairs(default) do
        if k ~= 0 then
            Continue(applyCustomProperty, target, k, v)
        end
    end

    if default[0] then
        for k, v in pairs(default[0]) do
            local child         = getChild(target, k)
            if child then
                Continue(applyDefaultStyles, child, v)
            end
        end
    end
end

----------------------------------------------
--             Scorpio UI Style             --
----------------------------------------------
local _StyleOwner               = {}
local _StyleAccessor

local function setTargetStyle(key, value)
    if type(value) ~= "table" then error("The style settings must be a table", 3) end

    local target                = _StyleOwner[1]
    local tarcls
    local isCustom
    local default

    if isUIObject(target) then
        -- Custom style
        for i = 2, #_StyleOwner do
            target              = getChild(target, _StyleOwner[i])
            if not target then error("The target of the style settings isn't existed", 3) end
        end

        tarcls                  = getmetatable(target)
        isCustom                = true
    elseif isUIObjectType(target) then
        -- Default style
        tarcls                  = target

        default                 = _Default[tarcls]
        if not default then
            default             = {}
            _Default[tarcls]    = default
        end

        for i = 2, #_StyleOwner do
            local name          = _StyleOwner[i]
            tarcls              = getElementType(tarcls, name)
            if not tarcls then error("The target of the style settings isn't existed", 3) end

            local childs        = default[0]
            if not childs then
                childs          = {}
                default[0]      = childs
            end

            default             = childs[name]
            if not default then
                default         = {}
                childs[name]    = default
            end
        end

        isCustom                = false
    else
        error("The target of the style settings isn't valid", 3) end
    end

    local props                 = _Property[tarcls]
    if not props then error("The target's class has no property definitions", 3) end

    for n, v in pairs(value) do
        if type(n) == "string" then
            local ln            = strlower(n)
            local prop          = props[ln]
            if not prop then error(strformat("The %q isn't a valid property for the target", n), 2) end

            if v ~= NIL and prop.validate then
                local ret, msg  = prop.validate(prop.type, v)
                if msg then error(Struct.GetErrorMessage(msg, n), 2) end
                v               = ret
            end

            if isCustom then
                local cprops    = _Custom[target]
                if not cprops then
                    cprops      = {}
                    _Custom[target] = cprops
                end
                cprops[ln]      = v

                Continue(applyCustomProperty, target, prop, v)
            else
                default[ln]     = v

                -- Continue(applyDefaultProperty, ln, v, unpack(_StyleOwner))
            end
        end
    end
end

-- Style[UnitFrame].HealthBar.Back = { Texture = "/xxxxx" }
local Style                     = Namespace.SaveNamespace("Scorpio.UI.Style", prototype {
    __tostring                  = Namespace.GetNamespaceName,
    __index                     = function(self, key)
        if type(key) == "string" then
            return getSubNS(self, key) or _Methods[key]
        end

        if isUIObject(key) or isUIObjectType(key) then
            wipe(_StyleOwner)[1]= key
            return _StyleAccessor
        end
    end,
    __newindex                  = function(self, key, value)
        if isUIObject(key) or isUIObjectType(key) then
            wipe(_StyleOwner)[1]= key
            setTargetStyle(value)
        end
    end
})

_StyleAccessor                  = prototype{
    __metatable                 = Style,
    __index                     = function(self, key)
        local len               = #_StyleOwner
        if len > 0 and type(key) == "string" then
            _StyleOwner[len + 1]= key
            return _StyleAccessor
        else
            error("The sub key must be string", 2)
        end
    end,
    __newindex                  = function(self, key, value)
        local len               = #_StyleOwner
        if len > 0 and type(key) == "string" then
            _StyleOwner[len + 1]= key
            setTargetStyle(value)
        else
            error("The sub key must be string", 2)
        end
    end
})

NIL                            = Namespace.SaveNamespace("Scorpio.UI.Style.NIL", prototype { __tostring = function() return "nil" end })


----------------------------------------------
--           Scorpio UI Property            --
----------------------------------------------
local function dispatchPropertySetting(cls, prop, setting, oldsetting, root)
    local settings              = _Property[cls]
    if not settings then
        settings                = {}
        _Property[cls]          = settings
    end

    if root then
        oldsetting              = settings[prop]
    elseif settings[prop] and oldsetting ~= settings[prop] then
        return
    end

    settings[prop]              = setting

    for scls in Class.GetSubTypes(cls) do
        dispatchPropertySetting(scls, prop, setting, oldsetting)
    end
end

Runtime.OnTypeDefined           = Runtime.OnTypeDefined + function(ptype, cls)
    if ptype == Class and IsUIObjectType(cls) then
        if _Property[cls] then return end

        local super             = Class.GetSuperClass(cls)
        if super and _Property[super] then
            _Property[cls]      = clone(_Property[super])
        end
    end
end

__Sealed__()
struct "Scorpio.UI.Style.Property" {
    name                        = { type  = NEString, require = true },
    type                        = { type  = AnyType },
    require                     = { type  = ClassType + struct { ClassType }, require = true },
    set                         = { type  = Function, require = true },
    get                         = { type  = Function },
    clear                       = { type  = Function },
    default                     = { type  = Any },
    nilable                     = { type  = Boolean },

    __init                      = function(self)
        local setting           = {
            name                = self.name,
            type                = self.type,
            set                 = self.set,
            get                 = self.get,
            clear               = self.clear,
            default             = clone(self.default, true),
            nilable             = self.nilable,
        }

        if self.type then
            if isTypeValidDisabled then
               if Struct.Validate(self.type) and not Struct.IsImmutable(self.type) then
                    setting.validate = Struct.ValidateValue
                end
            else
                if Enum.Validate(self.type) then
                    setting.validate = Enum.ValidateValue
                elseif Struct.Validate(self.type) then
                    setting.validate = Struct.ValidateValue
                elseif Class.Validate(self.type) then
                    setting.validate = Class.ValidateValue
                elseif Interface.Validate(self.type) then
                    setting.validate = Interface.ValidateValue
                end
            end

            if setting.default ~= nil and setting.validate then
                setting.default = setting.validate(setting.type, setting.default)
            end
        end

        local name              = strlower(self.name)

        if isUIObjectType(self.require) then
            dispatchPropertySetting(self.require, name, setting, nil, true)
        else
            for _, cls in ipairs(self.require) do
                dispatchPropertySetting(cls, name, setting, nil, true)
            end
        end
    end,
}


----------------------------------------------
--             Style Interface              --
----------------------------------------------
__Sealed__() IStyle = interface ("Scorpio.UI.Style.IStyle", { function(self) Continue(applyDefaultStyles, self) end })
__Sealed__() class "UIObject" { IStyle }
