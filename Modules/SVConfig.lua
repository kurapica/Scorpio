--========================================================--
--                Scorpio SavedVariable Config System     --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/03/27                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.SVConfig"                "1.0.0"
--========================================================--


------------------------------------------------------------
-- The Addon SavedVariables configuration node
------------------------------------------------------------
__Sealed__() __SuperObject__(false):AsInheritable()
class "SVConfigNode" (function(_ENV)

    local _AddonConfigNode      = {}
    local _ConfigNodeAddon      = {}

    local _RawData              = {}
    local _SubNodes             = {}

    local _Fields               = {}
    local _Defaults             = {}


    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    __Arguments__{ NEString, EnumType + StructType, Any/nil }
    function SetField(self, name, type, value)
        local fields            = _Fields[self]
        if not fields then
            fields              = {}
            _Fields[self]       = fields
        end

        if fields[name] then
            return false, "The field " .. name .. " already has type specified"
        end

        fields[name]            = type

        if value ~= nil then
            local ret, msg
            if Enum.Validate(type) then
                ret, msg        = Enum.ValidateValue(type, value)
            elseif Struct.Validate(type) then
                ret, msg        = Struct.ValidateValue(type, value)
            end

            if msg then
                return false, Struct.GetErrorMessage(msg, name)
            end

            local default       = _Defaults[self]
            if not default then
                default         = {}
                _Defaults[self] = default
            end
            default[name]       = ret
        end
    end

    --- The set saved variables method, must be called in Addon's OnLoad handler
    __Async__(true) __Arguments__{ NEString, NEString/nil }:Throwable()
    function SetSavedVariables(self, sv, svchar)
        local addon             = _ConfigNodeAddon[self]

        if not addon then
            throw("Usage: SVConfigNode:SetSavedVariables(sv[, svchar]) - can only be used by config node of the addon")
        end

        if _RawData[self] then
            throw("Usage: SVConfigNode:SetSavedVariables(sv[, svchar]) - The config node already has saved variables binded")
        end

        if not IsAddOnLoaded(addon._Name) then
            while NextEvent("ADDON_LOADED") ~= addon._Name do end
            Next()
        end

        -- SavedVariables
        local svData            = _G[sv]
        if not svData then
            svData              = {}
            _G[sv]              = svData
        end
        _RawData[self]          = svData

        -- SavedVariablesPerCharacter
        if svchar then
            local svcharData        = _G[svchar]
            if not svcharData then
                svcharData          = {}
                _G[svchar]          = svcharData
            end
            local node              = SVConfigNode(self, "Char")
            _RawData[node]          = svcharData
        end
    end

    ----------------------------------------------
    --               Meta-method                --
    ----------------------------------------------
    __Arguments__{ NEString }
    function __index(self, key)

    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    -- Addon-Node
    __Arguments__{ Scorpio }
    function __ctor(self, addon)
        _AddonConfigNode[addon] = self
        _ConfigNodeAddon[self]  = addon
    end

    __Arguments__{ Scorpio }
    function __exist(_, addon)
        return _AddonConfigNode[addon]
    end

    -- Sub-Nodes
    __Arguments__{ SVConfigNode, NEString }
    function __ctor(self, node, name)
        local subNodes          = _SubNodes[node]
        if not subNodes then
            subNodes            = {}
            _SubNodes[node]     = subNodes
        end
        subNodes[name]          = self
    end

    __Arguments__{ SVConfigNode, NEString }
    function __exist(_, node, name)
        local subNodes          = _SubNodes[node]
        return subNodes and subNodes[name]
    end
end)



--- The binder for the config section and handler
-- @usage :
--      __ConfigSection__( System.Web.ConfigSection.Html.Render, { nolinebreak = Boolean, noindent = Boolean  } )
--      function HtmlRenderConfig(config, ...)
--          print(config.nolinebreak)
--      end
--
--      __ConfigSection__( System.Web.ConfigSection.Controller, "jsonprovider", -FormatProvider)
--      function JsonProviderConfig(field, value, ...)
--          print("The new json provider is " .. value)
--      end
__Sealed__() class "__Config__" (function(_ENV)
    extend "IAttachAttribute"

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    --- attach data on the target
    -- @param   target                      the target
    -- @param   targettype                  the target type
    -- @param   owner                       the target's owner
    -- @param   name                        the target's name in the owner
    -- @param   stack                       the stack level
    -- @return  data                        the attribute data to be attached
    function AttachAttribute(self, target, targettype, owner, name, stack)
        if self[3] then
            local section           = self[1]
            local fldname           = self[2]
            section.Field[fldname]  = self[3]

            section.OnFieldParse    = section.OnFieldParse + function(self, fld, val, ...)
                if fld == fldname then
                    return target(fld, val, ...)
                end
            end
        else
            local section           = self[1]
            if self[2] then
                for k, v in pairs(self[2]) do
                    if type(k) == "string" and (isenum(v) or isstruct(v)) then
                        section.Field[k] = v
                    else
                        error("The field's type can only be enum or struct", stack + 1)
                    end
                end
            end
            section.OnParse         = section.OnParse + function(self, ...) return target(...) end
        end
    end

    -----------------------------------------------------------
    --                       property                        --
    -----------------------------------------------------------
    --- the attribute target
    property "AttributeTarget" { set = false, default = AttributeTargets.Function }

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ ConfigSection, Table/nil }
    function __new(_, section, fields)
        return { section, fields, false }, true
    end

    __Arguments__{ ConfigSection, NEString, (EnumType + StructType)/Any }
    function __new(_, section, name, type)
        return { section, name, type }, true
    end
end)
