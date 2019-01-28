--========================================================--
--             Scorpio UI Style FrameWork                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/01/09                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Style"                 "1.0.0"
--========================================================--

----------------------------------------------
--          Scorpio UI Style Core           --
----------------------------------------------
local _PropertyOwner
local _PropertyAccessor

Namespace.SaveNamespace("Scorpio.UI.Style", prototype {
    __tostring                  = Namespace.GetNamespaceName,
    __index                     = function(self, key, stack)
        local tkey              = type(key)
        if tkey == "string" then
            return Namespace.GetNamespace(self, key)
        elseif tkey == "table" and key[0] then -- no more check, keep simple
            _PropertyOwner      = key
            return _PropertyAccessor
        end
    end,
})

----------------------------------------------
--         Scorpio UI Property Core         --
----------------------------------------------
local _Property                 = {}

if System.Platform.TYPE_VALIDATION_DISABLED then
    _PropertyAccessor               = prototype {
        __metatable                 = Scorpio.UI.Style,
        __index                     = function(self, key)
            return _Property[strlower(key)].get(_PropertyOwner)
        end,
        __newindex                  = function(self, key, value)
            local prop              = _Property[strlower(key)]
            if prop.validate then
                prop.set(_PropertyOwner, prop.validate(prop.type, value))
            else
                prop.set(_PropertyOwner, value)
            end
        end,
    }
else
    local META_TYPE_PROP_CACHE      = {
        __index                     = function(self, key)
            local prop              = _Property[key]
            if not prop or (prop.objtype and not Class.IsSubType(self[1], prop.objtype)) then return nil end
            rawset(self, key, prop)
            return prop
        end
    }

    local _Property4Type            = setmetatable({}, {
        __index = function(self, key)
            if Class.Validate(key) then
                local cache         = setmetatable({ [1] = key }, META_TYPE_PROP_CACHE)
                rawset(self, key, cache)
                return cache
            end
        end
    }

    _PropertyAccessor               = prototype {
        __metatable                 = Scorpio.UI.Style,
        __index                     = function(self, key)
            if type(key) ~= "string" then error("the widget property name must be string", 2) end

            local cls               = getmetatable(self)
            local ptype             = _Property4Type[cls]

            if not ptype then
                -- Means the raw bliz ui
                ptype               = _Property4Type[UI[self:GetObjectType()]]
                rawset(_Property4Type, cls, ptype)
            end

            local prop              = ptype[strlower(key)]
            if not prop then error(strformat("the object has no widget property named %q", key), 2) end

            return prop.get(_PropertyOwner, 2)
        end,
        __newindex                  = function(self, key, value)
            if type(key) ~= "string" then error("the widget property name must be string", 2) end

            local cls               = getmetatable(self)
            local ptype             = _Property4Type[cls]

            if not ptype then
                -- Means the raw bliz ui
                ptype               = _Property4Type[UI[self:GetObjectType()]]
                rawset(_Property4Type, cls, ptype)
            end

            local prop              = ptype[strlower(key)]
            if not prop then error(strformat("the object has no widget property named %q", key), 2) end

            if value == nil and prop.require then error(strformat("the %q widget property require non-nil value", key), 2) end

            if prop.validate then
                local ret, msg      = prop.validate(prop.type, value)
                if msg then error(Struct.GetErrorMessage(msg, prop.name), 2) end
                prop.set(_PropertyOwner, ret, 2)
            else
                prop.set(_PropertyOwner, value, 2)
            end
        end,
    }
end

struct "Scorpio.UI.Style.Property" {
    { name = "name",    type    = NEString, require = true },
    { name = "get" ,    type    = Function, require = true },
    { name = "set" ,    type    = Function, require = true },
    { name = "type",    type    = AnyType },
    { name = "require", type    = Boolean },
    { name = "objtype", type    = InterfaceType + ClassType },

    __valid                     = function(self)
        local name              = strlower(self.name)
        if _Property[name] then
            return strformat("the %q widget property is already existed", name)
        end
    end,

    __init                      = System.Platform.TYPE_VALIDATION_DISABLED and function(self)
        self                    = Toolset.clone(self)

        if self.type then
           if Struct.Validate(self.type) then
                if not Struct.IsImmutable(self.type) then
                    self.validate  = Struct.ValidateValue
                end
                if Struct.GetStructCategory(self.type) ~= StructCategory.CUSTOM then
                    self.depthcomp = true
                end
            end
        end

        _Property[strlower(self.name)] = self
    end or function(self)
        self                    = Toolset.clone(self)

        if self.type then
            if Enum.Validate(self.type) then
                self.validate   = Enum.ValidateValue
            elseif Struct.Validate(self.type) then
                self.validate   = Struct.ValidateValue
                if Struct.GetStructCategory(self.type) ~= StructCategory.CUSTOM then
                    self.depthcomp = true
                end
            elseif Class.Validate(self.type) then
                self.validate   = Class.ValidateValue
            elseif Interfacce.Validate(self.type) then
                self.validate   = Interfacce.ValidateValue
            end
        end

        _Property[strlower(self.name)] = self
    end
}
