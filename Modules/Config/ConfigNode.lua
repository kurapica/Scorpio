--========================================================--
--                Scorpio SavedVariable Config System     --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/03/27                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config.ConfigNode"       "1.0.0"
--========================================================--

------------------------------------------------------
-- Helpers
------------------------------------------------------
local _PlayerLogined, _PlayerSpec, _PlayerWarMode
local _CharNodes, _SpecNodes, _WMNodes
local _Locale                   = _Locale

local isEnumType                = Enum.Validate
local isEnumValue               = Enum.ValidateValue
local isStructType              = Struct.Validate
local isStrutValue              = Struct.ValidateValue

local function validateValue(type, value)
    if isEnumType(type) then
        return isEnumValue(type, value)
    elseif isStructType(type) then
        return isStrutValue(type, value)
    else
        return nil, "The %s's type not supported"
    end
end

local function queueCharConfigNode(node, container, name, prevContainer)
    if _PlayerLogined then return false end

    _CharNodes                  = _CharNodes or {}
    _CharNodes[node]            = { container, name, prevContainer }

    return true
end

local function queueSpecConfigNode(node, container, name, prevContainer)
    if _PlayerSpec then return false end

    _SpecNodes                  = _SpecNodes or {}
    _SpecNodes[node]            = { container, name, prevContainer }

    return true
end

local function queueWarModeConfigNode(node, container, name, prevContainer)
    if _PlayerWarMode then return false end

    _WMNodes                    = _WMNodes or {}
    _WMNodes[node]              = { container, name, prevContainer }

    return true
end

local function processNodes(nodes)
    for node, config in pairs(nodes) do
        local ok, err           = pcall(node.InitConfigNode, node, unpack(config))
        if not ok then errorhandler(err) end
    end
end

------------------------------------------------------
-- Addon Event Handler
------------------------------------------------------
function OnEnable()
    _PlayerLogined              = true
    OnEnable                    = nil

    if _CharNodes then
        processNodes(_CharNodes)
        _CharNodes              = nil
    end
end

function OnSpecChanged(self, spec)
    _PlayerSpec                 = spec
    return _SpecNodes and processNodes(_SpecNodes)
end

function OnWarModeChanged(self, mode)
    _PlayerWarMode              = mode
    return _WMNodes and processNodes(_WMNodes)
end

------------------------------------------------------
--- The configuration node
------------------------------------------------------
__Sealed__()
class "ConfigNode"              (function(_ENV)

    local CHILD_NODE            = "__nodes"

    local _SubNodes             = Toolset.newtable(true)
    local _ParentNode           = Toolset.newtable(true, true)
    local _NodeName             = Toolset.newtable(true)
    local _SavedVariable        = Toolset.newtable(true)
    local _Fields               = {} -- { type, subject, default }
    local _EnableUI             = Toolset.newtable(true)

    local _RawData              = Toolset.newtable(true)

    local strlower              = string.lower
    local strtrim               = Toolset.trim
    local clone                 = Toolset.clone
    local tinsert               = table.insert
    local yield                 = coroutine.yield

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The addon owner
    __Abstract__()
    property "_Addon"           { default = function(self) local parent = self._Parent return parent and parent._Addon end }

    --- The parent node
    __Abstract__()
    property "_Parent"          { get = function(self) return _ParentNode[self] end }

    --- The saved variables
    __Abstract__()
    property "_SavedVariable"   { get = function(self) return _SavedVariable[self] end }

    __Abstract__()
    property "_Name"            { get = function(self) return _NodeName[self] and self._Addon._Locale[_NodeName[self]] end }

    --- Whether enable ui for the config node
    __Abstract__()
    property "_IsUIEnabled"      { get = function(self) return _EnableUI[self] end }

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    --- Sets the field with type and default value
    __Arguments__{ NEString, EnumType + StructType, Any/nil, NEString/nil, Boolean/nil, Boolean/nil }:Throwable()
    function SetField(self, name, ftype, value, desc, enableui, enableQuickApply)
        name                    = strlower(name)

        local fields            = _Fields[self]
        if not fields then
            fields              = {}
            _Fields[self]       = fields
        end

        if fields[name] then
            throw("The field " .. name .. " already has type specified")
        end

        fields[name]            = { type = ftype, desc = desc, enableui = enableui, enablequickapply = enableQuickApply }
        tinsert(fields, name)   -- Keeps the field order

        if value ~= nil then
            local ret, msg      = validateValue(ftype, value)
            if msg then throw( Struct.GetErrorMessage(msg, name) ) end
            fields[name].default= clone(ret, true)
        end

        if not _RawData[self] then return end -- not inited
        self:SetValue(name, nil, nil, true)
    end

    --- Gets the field type, default value and description
    function GetField(self, name)
        if type(name) ~= "string" then return end

        local fields            = _Fields[self]
        local field             = fields and fields[strlower(name)]
        if not field then return end
        return field.type, field.desc, field.enableui, field.enablequickapply
    end

    --- Gets the fields with order
    __Iterator__()
    function GetFields(self)
        local fields            = _Fields[self]
        if fields then
            local yield         = yield
            for _, name in ipairs(fields) do
                local field     = fields[name]
                yield(name, field.type, field.desc, field.enableui, field.enablequickapply)
            end
        end
    end

    --- Gets the sub nodes with order
    __Iterator__()
    function GetSubNodes(self)
        local subNodes          = _SubNodes[self]
        if subNodes then
            for _, name in ipairs(subNodes) do
                yield(name, subNodes[name])
            end
        end
    end

    --- Sets saved variables, must be called in Addon or Module's OnLoad handler
    function SetSavedVariable(self, sv, stack)
        if type(sv) ~= "string" then
            error("Usage: ConfigNode:SetSavedVariable(sv) - the sv must be a non-empty string", (stack or 1) + 1)
        end

        sv                      = strtrim(sv)
        if sv == "" then
            error("Usage: ConfigNode:SetSavedVariable(sv) - the sv must be a non-empty string", (stack or 1) + 1)
        end

        if _SavedVariable[self] then
            error("Usage: ConfigNode:SetSavedVariable(sv) - The config node already has saved variables binded", (stack or 1) + 1)
        end

        _SavedVariable[self]    = sv

        -- Remove self from parent
        if _ParentNode[self] then
            local parent        = _ParentNode[self]
            local subNodes      = _SubNodes[parent]

            -- Save the _Addon
            self._Addon         = parent._Addon

            for i, n in ipairs(subNodes) do
                local v         = subNodes[n]
                if v == self then
                    subNodes[n] = nil
                    tremove(subNodes, i)

                    if _RawData[self] then
                        _RawData[self] = nil
                    end

                    -- Clear the raw data
                    if _RawData[parent] and _RawData[parent][CHILD_NODE] then
                        _RawData[parent][CHILD_NODE][n] = nil

                        -- Clear the child node data if not needed
                        if next(_RawData[parent][CHILD_NODE]) == nil then
                            _RawData[parent][CHILD_NODE]= nil
                        end
                    end

                    break
                end
            end
            if #subNodes == 0 then
                _SubNodes[parent] = nil
            end
            _ParentNode[self]   =  nil
        end

        -- SavedVariables
        return self:InitConfigNode(_G, sv)
    end

    --- Sets the value to the field
    function SetValue(self, name, value, stack, init)
        local rawdata           = _RawData[self]

        if not rawdata then
            if init then return end
            error("The config node isn't inited, please wait until the saved variable is loaded", (stack or 1) + 1)
        end

        name                    = strlower(name)

        local fields            = _Fields[self]
        local field             = fields and fields[name]
        if not field then
            if init then return end
            error("The field " .. name .. " not existed", (stack or 1) + 1)
        end

        if value ~= nil then
            local ret, msg      = validateValue(field.type, value)
            if msg then
                if init then
                    value       = field.default
                else
                    error(Struct.GetErrorMessage(msg, name), (stack or 1) + 1)
                end
            else
                value           = ret
            end
        else
            value               = field.default
        end

        if rawdata[name] == value then return end
        rawdata[name]           = clone(value, true)

        return field.subject and field.subject:OnNext( clone(value, true) )
    end

    --- Sets values to the fields
    function SetValues(self, values, stack, init)
        stack                   = (stack or 1) + 1

        if type(values) ~= "table" then
            error("Usage: ConfigNode:SetValues(values[, stack]) - the values must be a table", stack)
        end

        local rawdata           = _RawData[self]

        if not rawdata then
            if init then return end
            error("The config node isn't inited, please wait until the saved variable is loaded", stack)
        end


        local fields            = _Fields[self]
        if not fields then return end
        for _, fldname in ipairs(fields) do
            self:SetValue(fldname, values[fldname], stack, init)
        end
    end

    --- Gets the value from field
    function GetValue(self, name)
        local rawdata           = _RawData[self]
        if not rawdata then return end

        name                    = strlower(name)
        if name ~= CHILD_NODE then
            return clone(rawdata[name], true)
        end
    end

    --- Gets all node field values
    function GetValues(self)
        local rawdata           = _RawData[self]
        if not rawdata then return end

        local ret               = {}
        for k, v in pairs(rawdata) do
            if k ~= CHILD_NODE then
                ret[k]          = clone(v, true)
            end
        end

        return ret
    end

    --- Init the config node, this must be called by the system, don't use it manually
    function InitConfigNode(self, container, name, prevContainer)
        -- Gets the previous session data if exists
        local prevdata          = (prevContainer or container)[name]
        if type(prevdata) ~= "table" or getmetatable(prevdata) ~= nil then
            prevdata            = nil
        end

        -- Build the new raw data
        local rawdata           = {}
        _RawData[self]          = rawdata
        container[name]         = rawdata -- rebuild the data container

        -- Init the raw data with field settings
        local fields            = _Fields[self]
        if fields then
            for _, fldname in ipairs(fields) do
                self:SetValue(fldname, prevdata and prevdata[fldname], 2, true)
            end
        end

        -- Init child nodes
        local subNodes          = _SubNodes[self]
        if subNodes then
            local childData     = {}
            rawdata[CHILD_NODE] = childData
            prevdata            = prevdata and prevdata[CHILD_NODE]

            for _, name in ipairs(subNodes) do
                subNodes[name]:InitConfigNode(childData, name, prevdata)
            end
        end
    end

    --- Enable the config ui for field
    function EnableUI(self)
        _EnableUI[self]         = true
        return self
    end

    --- Disable the config ui for field
    function DisableUI(self)
        _EnableUI[self]         = false
        return self
    end

    ----------------------------------------------
    --               Meta-method                --
    ----------------------------------------------
    --- Gets the node field or create new config nodes
    function __index(self, name)
        if type(name) ~= "string" then return end

        -- Keep use lower case for field name and sub node, so case insensitive
        name                    = strlower(name)

        -- Check the fields and get the obsrevable subject
        local fields            = _Fields[self]
        local field             = fields and fields[name]
        if field then
            local subject       = field.subject
            if not subject then
                local rawdata   = _RawData[self]
                subject         = ConfigSubject( self, name, clone(rawdata and rawdata[name], true) )
                field.subject   = subject
            end
            return subject
        end

        -- Return or create the sub nodes
        return ConfigNode(self, name)
    end

    --- Sets the field value
    __newindex                  = SetValue

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    -- Module-Node
    __Arguments__{}
    function __ctor(self) end

    __Arguments__{}
    function __exist(self) end

    -- Sub-Nodes
    __Arguments__{ ConfigNode, NEString }
    function __ctor(self, node, name)
        name                    = strlower(name)
        local subNodes          = _SubNodes[node]
        if not subNodes then
            subNodes            = {}
            _SubNodes[node]     = subNodes
        end
        subNodes[name]          = self
        tinsert(subNodes, name)
        _ParentNode[self]       = node
        _NodeName[self]         = name
    end

    __Arguments__{ ConfigNode, NEString }
    function __exist(_, node, name)
        local subNodes          = _SubNodes[node]
        return subNodes and subNodes[strlower(name)]
    end
end)

------------------------------------------------------
--- The addon configuration node
------------------------------------------------------
__Sealed__()
class "AddonConfigNode"         (function(_ENV)
    inherit "ConfigNode"

    local _AddonConfigMap       = {}
    local _ConfigAddonMap       = {}

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The addon of the config node
    property "_Addon"           { get = function(self) return _ConfigAddonMap[self] end }

    --- The config node name
    property "_Name"            { get = function(self) return self._Addon._Locale[self._Addon._Name] end }

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Arguments__{ Scorpio }
    function __ctor(self, addon)
        _AddonConfigMap[addon]  = self
        _ConfigAddonMap[self]   = addon
    end

    __Arguments__{ Scorpio }
    function __exist(_, addon)
        return _AddonConfigMap[addon]
    end
end)

------------------------------------------------------
--- The character configuration node
------------------------------------------------------
__Sealed__()
class "CharConfigNode"          (function(_ENV)
    inherit "ConfigNode"

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The config node name
    property "_Name"            { get = function(self) return GetRealmName() .. "-" .. UnitName("player") end }

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    function InitConfigNode(self, container, name, prevContainer)
        -- Process Char Config Node only after PLAYER_LOGIN
        if queueCharConfigNode(self, container, name, prevContainer) then return end

        if self._SavedVariable then
            return container == _G and super.InitConfigNode(self, container, name, prevContainer)
        else
            local allUserData   = container[name] or prevContainer and prevContainer[name] or {}
            container[name]     = allUserData

            return super.InitConfigNode(self, allUserData, GetRealmName() .. "-" .. UnitName("player"))
        end
    end
end)

------------------------------------------------------
--- The specialization configuration node
------------------------------------------------------
__Sealed__()
class "SpecConfigNode"          (function(_ENV)
    inherit "ConfigNode"

    local GetSpecializationInfo = _G.GetSpecializationInfo or function() return nil, _Locale["Specialization"] end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The config node name
    property "_Name"            { get = function(self) return select(2, GetSpecializationInfo(_PlayerSpec)) end }

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    function SetSavedVariable(self)
        error("The specialization config node can't bind saved variables", 2)
    end

    function InitConfigNode(self, container, name, prevContainer)
        -- Process Spec Config Node only after PLAYER_SPECIALIZATION_CHANGED
        if queueSpecConfigNode(self, container, name, prevContainer) then return end

        local allSpecData   = container[name] or prevContainer and prevContainer[name] or {}
        container[name]     = allSpecData

        return super.InitConfigNode(self, allSpecData, _PlayerSpec)
    end
end)

------------------------------------------------------
--- The warmode configuration node
------------------------------------------------------
__Sealed__()
class "WarModeConfigNode"       (function(_ENV)
    inherit "ConfigNode"

    local IsWarModeDesired      = C_PvP and C_PvP.IsWarModeDesired or function() return false end,

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The config node name
    property "_Name"            { get = function(self) return IsWarModeDesired() and _Locale["PVP"] or _Locale["PVE"] end }

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    function SetSavedVariable(self)
        error("The war mode config node can't bind saved variables", 2)
    end

    function InitConfigNode(self, container, name, prevContainer)
        -- Process War Mode Config Node only after PLAYER_FLAGS_CHANGED
        if queueWarModeConfigNode(self, container, name, prevContainer) then return end

        local allWarModeData= container[name] or prevContainer and prevContainer[name] or {}
        container[name]     = allWarModeData

        return super.InitConfigNode(self, allWarModeData, _PlayerWarMode)
    end
end)

------------------------------------------------------
--- The binder for the config section and handler
-- @usage :
--
-- Scorpio "TestAddon" ""
--
-- function OnLoad()
--  _CharConfig:SetSavedVariable("TestAddonChar")
--  _Config:SetSavedVariable("TestAddon", "TestAddonChar")
-- end
--
-- __Config__(_Config, true, "Enable the log")
-- function EnableLog(value)
--
-- end
--
-- __Config__(_Config, Boolean)(true)
-- function EnableLog(value)
--
-- end

-- __Config__(_CharConfig, "EnableLog", Boolean)(true)
-- function EnableLog(value)
--
-- end
------------------------------------------------------
__Sealed__()
class "__Config__" (function(_ENV)
    extend "IInitAttribute"

    function InitDefinition(self, target, targettype, definition, owner, name, stack)
        local node          = self.Node
        local name          = self.Name or name
        local ftype         = self.Type
        local default       = self.Default

        if default ~= nil then
            local ret, msg  = validateValue(ftype, default)
            if msg then
                error(Struct.GetErrorMessage(msg, "default"), stack + 1)
            end
            default         = ret
        end

        node:SetField(name, ftype, default, self.Desc, self.EnableFieldUI, self.EnableQuickApply)
        node[name]:Subscribe(target)\
        return function(value) node:SetValue(name, value, 2) end
    end

    --- Disable the config ui for field
    function DisableUI(self)
        self.EnableFieldUI      = false
        return self
    end

    --- Disable the quick apply
    function DisableQuickApply(self)
        self.EnableQuickApply   = false
        return self
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    property "AttributeTarget"  { default = AttributeTargets.Function }

    --- the attribute's priority
    property "Priority"         { type = AttributePriority, default = AttributePriority.Lowest }

    --- the attribute's sub level of priority
    property "SubLevel"         { type = Number, default = -999999 }

    --- The config node
    property "Node"             { type = ConfigNode }

    --- The field name
    property "Name"             { type = String }

    --- The field type
    property "Type"             { type = EnumType + StructType }

    --- The field default value
    property "Default"          { type = Any }

    --- The field description
    property "Desc"             { type = NEString }

    --- Whether enable the UI for the field
    property "EnableFieldUI"    { type = Boolean, default = true }

    --- Disable quick apply, so the config UI won't apply the changed until click the OKay button
    property "EnableQuickApply" { type = Boolean, default = true }

    ----------------------------------------------
    --                Constructor               --
    ----------------------------------------------
    --- __Config__(_Config, true, "[Type]Boolean [Name]Handler name [Default]true")
    __Arguments__{ ConfigNode, Boolean, NEString/nil }
    function __ctor(self, node, value, desc)
        self.Node               = node
        self.Type               = Boolean
        self.Default            = value
        self.Desc               = desc
    end

    --- __Config__(_Config, 3, "[Type]Number [Name]Handler name [Default]3")
    __Arguments__{ ConfigNode, Number, NEString/nil }
    function __ctor(self, node, value, desc)
        self.Node               = node
        self.Type               = Number
        self.Default            = value
        self.Desc               = desc
    end

    --- __Config__(_Config, "enable", true, "[Type]Boolean [Name]enable [Default]true")
    __Arguments__{ ConfigNode, NEString, Boolean, NEString/nil }
    function __ctor(self, node, name, value, desc)
        self.Node               = node
        self.Name               = name
        self.Type               = Boolean
        self.Default            = value
        self.Desc               = desc
    end

    --- __Config__(_Config, "loglevel", 3, "[Type]Number [Name]loglevel [Default]3")
    __Arguments__{ ConfigNode, NEString, Number, NEString/nil }
    function __ctor(self, node, name, value, desc)
        self.Node               = node
        self.Name               = name
        self.Type               = Number
        self.Default            = value
        self.Desc               = desc
    end

    --- __Config__(_Config, "hello")  [Type]String [Name]Handler name [Default]hello
    __Arguments__{ ConfigNode, String }
    function __ctor(self, value)
        self.Node               = node
        self.Type               = String
        self.Default            = value
    end

    --- __Config__(_Config, "hello", "world")  [Type]String [Name]hello [Default]world
    __Arguments__{ ConfigNode, NEString, String }
    function __ctor(self, node, name, value)
        self.Node               = node
        self.Node               = name
        self.Type               = String
        self.Default            = value
    end

    --- __Config__(_Config, "hello", "world", "[Type]String [Name]hello [Default]world")
    __Arguments__{ ConfigNode, NEString, String, NEString }
    function __ctor(self, node, name, value, desc)
        self.Node               = node
        self.Name               = name
        self.Type               = String
        self.Default            = value
        self.Desc               = desc
    end

    --- __Config__(_Config, Size, { width = 0, helght = 0 }, "[Type]Size [Name]Handler name [Default]{ width = 0, helght = 0 }")
    __Arguments__{ ConfigNode, EnumType + StructType, Any/nil, NEString/nil }
    function __ctor(self, node, ftype, value, desc)
        self.Node               = node
        self.Type               = ftype
        self.Default            = value
        self.Desc               = desc
    end

    --- __Config__(_Config, "size", Size, { width = 0, helght = 0 }, "[Type]Size [Name]size [Default]{ width = 0, helght = 0 }")
    __Arguments__{ ConfigNode, NEString, EnumType + StructType, Any/nil, NEString/nil }
    function __ctor(self, node, name, ftype, value, desc)
        self.Node               = node
        self.Name               = name
        self.Type               = ftype
        self.Default            = value
        self.Desc               = desc
    end

    -- __Config__(_Config, { width = Number, height = Number }, { width = 0, height = 0}, "[Type]Anonymous [Name]Handler name [Default]{ width = 0, helght = 0 }")
    __Arguments__{ ConfigNode, RawTable, Any/nil, NEString/nil }
    function __ctor(self, node, definition, value, desc)
        local ok, structType    = Attribute.IndependentCall(function(temp) local type = struct(temp) return type end, definition)
        if not ok then throw(structType) end

        self.Node               = node
        self.Type               = structType
        self.Default            = value
        self.Desc               = desc
    end

    -- __Config__(_Config, "size", { width = Number, height = Number }, { width = 0, height = 0}, "[Type]Anonymous [Name]size [Default]{ width = 0, helght = 0 }")
    __Arguments__{ ConfigNode, NEString, RawTable, Any/nil, NEString/nil }
    function __ctor(self, node, name, definition, value, desc)
        local ok, structType    = Attribute.IndependentCall(function(temp) local type = struct(temp) return type end, definition)
        if not ok then throw(structType) end

        self.Node               = node
        self.Name               = name
        self.Type               = structType
        self.Default            = value
        self.Desc               = desc
    end

    ----------------------------------------------
    --                Meta-Method               --
    ----------------------------------------------
    --- Sets the default value
    -- __Config__(_Config, "size", { width = Number, height = Number }){ width = 0, height = 0}
    __Arguments__{ value }
    function __call(self, value)
        self.Default            = value
    end
end)
