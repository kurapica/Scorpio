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

    local CHAR_NODE             = "char"
    local CHILD_NODE            = "__nodes"

    local _AddonConfigNode      = {}
    local _ConfigNodeAddon      = {}

    local _SubNodes             = {}
    local _Fields               = {}
    local _Defaults             = {}

    local _RawData              = {}
    local _PrevData             = nil  -- The data from the previous game session

    local strlower              = string.lower
    local clone                 = Toolset.clone

    local function validateValue(type, value)
        if Enum.Validate(type) then
            return Enum.ValidateValue(type, value)
        elseif Struct.Validate(type) then
            return Struct.ValidateValue(type, value)
        else
            return nil, "The %s's type not supported"
        end
    end

    local function initConfigNode(self, parent, name)
        if _RawData[self] then return end

        local prevdata

        if type(parent) == "string" then
            prevdata            = type(_G[parent]) == "table" and _G[parent]
        else
            -- Check if already loaded
            if not _RawData[parent] then return end

            if _PrevData[parent] then
                prevdata        = _PrevData[parent][CHAR_NODE]
                prevdata        = type(prevdata) == "table" and prevdata[name] or nil
                prevdata        = type(prevdata) == "table" and prevdata or nil
            end
        end

        local rawdata           = {}


        _PrevData[self]         = prevdata
        _RawData[self]          = rawdata

        -- Init the raw data with default settings
        if _Fields[self] then
            local default       = _Defaults[self]

            for name, fldtype in pairs(_Fields[self]) do
                local value     = prevdata and prevdata[name]

                if value ~= nil then
                    -- Validating the previous values
                    local r, m  = validateValue(name, fldtype, value)
                    value       = not m and r or nil
                end

                if value == nil and default and default[name] ~= nil then
                    value       = clone(default[name])
                end

                -- Assign value instead rawdata directly
                self[name]      = value
            end
        end

        -- Init the child nodes
        if _SubNodes[self] then
            rawdata[CHAR_NODE]  = {}

            for sname, snode in pairs(_SubNodes[self]) do
                rawdata[CHAR_NODE][sname] = initConfigNode(snode, self, sname)
            end
        end

        return rawdata
    end

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    __Arguments__{ NEString, EnumType + StructType, Any/nil }
    function SetField(self, name, ftype, value)
        name                    = strlower(name)

        local fields            = _Fields[self]
        if not fields then
            fields              = {}
            _Fields[self]       = fields
        end

        if fields[name] then
            return false, "The field " .. name .. " already has type specified"
        end

        fields[name]            = ftype

        if value ~= nil then
            local ret, msg      = validateValue(name, ftype, value)

            if msg then
                return false, Struct.GetErrorMessage(msg, name)
            end

            local default       = _Defaults[self]
            if not default then
                default         = {}
                _Defaults[self] = default
            end
            default[name]       = clone(ret)

            if _RawData[self] and _RawData[self][name] == nil then
                -- any subject should be created after the field is set
                -- this shouldn't be reach since raw data will be created after OnLoad
                -- Just make sure this works in all condition
                _RawData[self]  = clone(ret)
            end
        end
    end

    --- The set saved variables method, must be called in Addon's OnLoad handler
    __AsyncSingle__() __Arguments__{ NEString, NEString/nil }:Throwable()
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

        -- SavedVariablesPerCharacter
        if svchar then
            _G[svchar]          = initConfigNode(SVConfigNode(self, "Char"), svchar)
        end

        -- SavedVariables
        _G[sv]                  = initConfigNode(self, sv)
    end

    ----------------------------------------------
    --               Meta-method                --
    ----------------------------------------------
    function __index(self, name)
        name                    = strlower(name)

        -- Check the raw datas
        local value             = _RawData[self]
        value                   = value and value[name]

        if value ~= nil then return clone(value) end

        -- Return or create the sub nodes
        return SVConfigNode(self, name)
    end

    function __newindex(self, name, value)
        local rawdata           = _RawData[self]
        if not rawdata then
            error("The config node isn't inited, please wait until the addon is loaded", 2)
        end

        name                    = strlower(name)

        -- Check the sub nodes
        if _SubNodes[self] and _SubNodes[self][name] then
            error("The config child node can't be replaced", 2)
        end

        local field             = _Fields[self] and _Fields[self][name]

        if not field then
            error("The " .. name " .. is not a valid field", 2)
        end

        -- Validate
        if value ~= nil then
            local ret, msg      = validateValue(field, value)
            if msg then
                error(Struct.GetErrorMessage(msg, name), 2)
            end
            value               = ret
        end

        -- Replace nil with default
        if value == nil and _Defaults[self] and _Defaults[self][name] ~= nil then
            value               = clone(_Defaults[self][name])
        end

        -- Assign the value
        rawdata[name]           = value
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
        name                    = strlower(name)
        local subNodes          = _SubNodes[node]
        if not subNodes then
            subNodes            = {}
            _SubNodes[node]     = subNodes
        end
        subNodes[name]          = self

        -- Try Init the saved variable
        initConfigNode(self, node, name)
    end

    __Arguments__{ SVConfigNode, NEString }
    function __exist(_, node, name)
        name                    = strlower(name)
        local subNodes          = _SubNodes[node]
        return subNodes and subNodes[name]
    end
end)


--- The binder for the config section and handler
-- @usage :
--
-- Scorpio "TestAddon" ""
--
-- _Config:SetSavedVariables("TestAddon", "TestAddonChar")
--
-- __Config__(_Config, true)
-- function EnableLog(value)
--
-- end
--
-- __Config__(_Config, Boolean)(true)
-- function EnableLog(value)
--
-- end

-- __Config__(_Config, "EnableLog", Boolean)(true)
-- function EnableLog(value)
--
-- end
__Sealed__()
class "__Config__" (function(_ENV)
    extend "IAttachAttribute"

    function AttachAttribute(self, target, targettype, owner, name, stack)
        if Class.IsObjectType(owner, Scorpio) then
            local node          = self.Node
            local name          = self.Name or name
            local ftype         = self.Type
            local default       = self.Default

        else
            error("__Config__ can only be applyed to objects of Scorpio.", stack + 1)
        end
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    property "AttributeTarget"  { default = AttributeTargets.Function }

    property "Node"             { type = SVConfigNode }

    property "Name"             { type = String }

    property "Type"             { type = EnumType + StructType }

    property "Default"          { type = Any }

    ----------------------------------------------
    --                Constructor               --
    ----------------------------------------------
    __Arguments__{ SVConfigNode, Boolean }
    function __ctor(self, node, value)
        self.Node               = node
        self.Type               = Boolean
        self.Default            = value
    end

    __Arguments__{ SVConfigNode, Number }
    function __ctor(self, node, value)
        self.Node               = node
        self.Type               = Number
        self.Default            = value
    end

    __Arguments__{ SVConfigNode, NEString, Boolean }
    function __ctor(self, node, name, value)
        self.Node               = node
        self.Name               = name
        self.Type               = Boolean
        self.Default            = value
    end

    __Arguments__{ SVConfigNode, NEString, Number }
    function __ctor(self, node, name, value)
        self.Node               = node
        self.Name               = name
        self.Type               = Number
        self.Default            = value
    end

    __Arguments__{ SVConfigNode, EnumType + StructType, Any/nil }
    function __ctor(self, node, ftype, value)
        self.Node               = node
        self.Type               = ftype
        self.Default            = value
    end

    __Arguments__{ SVConfigNode, NEString, EnumType + StructType, Any/nil }
    function __ctor(self, node, name, ftype, value)
        self.Node               = node
        self.Name               = name
        self.Type               = ftype
        self.Default            = value
    end

    ----------------------------------------------
    --                Meta-Method               --
    ----------------------------------------------
    __Arguments__{ value }
    function __call(self, value)
        self.Default            = value
    end
end)