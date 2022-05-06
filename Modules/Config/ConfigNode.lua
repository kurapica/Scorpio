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

local function validateValue(type, value)
    if Enum.Validate(type) then
        return Enum.ValidateValue(type, value)
    elseif Struct.Validate(type) then
        return Struct.ValidateValue(type, value)
    else
        return nil, "The %s's type not supported"
    end
end

local function queueCharConfigNode(node, container, name, prevContainer)
    if _PlayerLogined then return false end

    _CharNodes                  = _CharNodes or {}
    _CharNodes[#_CharNodes + 1] = node
    node[1]                     = container
    node[2]                     = name
    node[3]                     = prevContainer

    return true
end

local function queueSpecConfigNode(node, container, name, prevContainer)
    if _PlayerSpec then return false end

    _SpecNodes                  = _SpecNodes or {}
    _SpecNodes[#_SpecNodes + 1] = node
    node[1]                     = container
    node[2]                     = name
    node[3]                     = prevContainer

    return true
end


local function queueWarModeConfigNode(node, container, name, prevContainer)
    if _PlayerWarMode then return false end

    _WMNodes                    = _WMNodes or {}
    _WMNodes[#_WMNodes + 1]     = node
    node[1]                     = container
    node[2]                     = name
    node[3]                     = prevContainer

    return true
end



------------------------------------------------------
-- Addon Event Handler
------------------------------------------------------
function OnEnable()
    _PlayerLogined              = true
    OnEnable                    = nil

    if _CharNodes then
        for i = 1, #_CharNodes do
            local node          = _CharNodes[i]
            local ok, err       = pcall(node.InitConfigNode, node, unpack(node))
            if not ok then
                errorhandler(err)
            end
        end

        _CharNodes              = nil
    end
end

function OnSpecChanged(self, spec)
    _PlayerSpec                 = spec

    if _SpecNodes then
        for i = 1, #_SpecNodes do
            local node          = _SpecNodes[i]
            local ok, err       = pcall(node.InitConfigNode, node, unpack(node))
            if not ok then
                errorhandler(err)
            end
        end
    end
end

function OnWarModeChanged(self, mode)
    _PlayerWarMode              = mode

    if _WMNodes then
        for i = 1, #_WMNodes do
            local node          = _WMNodes[i]
            local ok, err       = pcall(node.InitConfigNode, node, unpack(node))
            if not ok then
                errorhandler(err)
            end
        end
    end
end

------------------------------------------------------
--- The Addon SavedVariables configuration node
------------------------------------------------------
__Sealed__()
class "ConfigNode" (function(_ENV)

    local CHILD_NODE            = "__nodes"

    local _SubNodes             = Toolset.newtable(true)
    local _ParentNode           = Toolset.newtable(true, true)
    local _SavedVariable        = Toolset.newtable(true)
    local _Fields               = {} -- { type, subject, default }

    local _RawData              = Toolset.newtable(true)
    local _PrevData             = Toolset.newtable(true)

    local strlower              = string.lower
    local strtrim               = Toolset.trim
    local clone                 = Toolset.clone

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The parent node
    property "_Parent"          { get = function(self) return _ParentNode[self] end }

    --- The saved variables
    property "_SavedVariable"   { get = function(self) return _SavedVariable[self] end }

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    __Arguments__{ NEString, EnumType + StructType, Any/nil }:Throwable()
    function SetField(self, name, ftype, value)
        name                    = strlower(name)

        local fields            = _Fields[self]
        if not fields then
            fields              = {}
            _Fields[self]       = fields
        end

        if fields[name] then
            throw("The field " .. name .. " already has type specified")
        end

        fields[name]            = { type = ftype }

        if value ~= nil then
            local ret, msg      = validateValue(ftype, value)

            if msg then
                throw( Struct.GetErrorMessage(msg, name) )
            end

            fields[name].default= clone(ret)
        end

        if not _RawData[self] then return end -- not inited
        self:SetValue(name, nil, nil, true)
    end

    --- The set saved variables method, must be called in Addon or Module's OnLoad handler
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

        if _ParentNode[self] then
            -- Remove self from parent
            local parent        = _ParentNode[self]
            local subNodes      = _SubNodes[parent]

            for k, v in pairs(subNodes) do
                if v == self then
                    subNodes[k] = nil

                    if _RawData[self] then
                        _RawData[self] = nil
                        _RawData[parent][CHILD_NODE][k] = nil

                        -- Clear the data if not needed
                        if next(_RawData[parent][CHILD_NODE]) == nil then
                            _RawData[parent][CHILD_NODE]= nil
                        end
                    end

                    break
                end
            end
            if next(subNodes) == nil then
                _SubNodes[parent] = nil
            end
            _ParentNode[self]   =  nil
        end

        -- SavedVariables
        return self:InitConfigNode(_G, sv)
    end

    --- Set the value to the field
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

        value                   = clone(value, true)
        rawdata[name]           = value

        return field.subject and field.subject:OnNext( clone(value, true) )
    end

    --- Init the config node, this must be called by the system, don't use it by your own
    function InitConfigNode(self, container, name, prevContainer)
        if _RawData[self] then return end -- Already inited

        -- Gets the previous session data
        local prevdata          = (prevContainer or container)[name]
        if type(prevdata) ~= "table" or getmetatable(prevdata) ~= nil then
            prevdata            = nil
        end

        -- Build the new raw data
        local rawdata           = {}

        _PrevData[self]         = prevdata
        _RawData[self]          = rawdata
        container[name]         = rawdata

        -- Init the raw data with field settings
        if _Fields[self] then
            for name, field in pairs(_Fields[self]) do
                self:SetValue(name, prevdata and prevdata[name], nil, true)
            end
        end

        -- Init child nodes
        if _SubNodes[self] then
            local childData     = {}
            rawdata[CHILD_NODE] = childData
            prevdata            = prevdata and prevdata[CHILD_NODE]

            for k, node in pairs(_SubNodes[self]) do
                InitConfigNode(node, childData, k, prevdata)
            end
        end
    end

    ----------------------------------------------
    --               Meta-method                --
    ----------------------------------------------
    function __index(self, name)
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
        _ParentNode[self]       = node
    end

    __Arguments__{ ConfigNode, NEString }
    function __exist(_, node, name)
        local subNodes          = _SubNodes[node]
        return subNodes and subNodes[strlower(name)]
    end
end)

------------------------------------------------------
--- THe character configuration node
------------------------------------------------------
__Sealed__()
class "CharConfigNode" (function(_ENV)
    inherit "ConfigNode"

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
class "SpecConfigNode" (function(_ENV)
    inherit "ConfigNode"

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    function SetSavedVariable(self)
        error("The specialization config node can't bind saved variables", 2)
    end

    function InitConfigNode(self, container, name, prevContainer)
        -- Process Char Config Node only after PLAYER_LOGIN
        if queueSpecConfigNode(self, container, name, prevContainer) then return end

        local allSpecData   = container[name] or prevContainer and prevContainer[name] or {}
        container[name]     = allSpecData

        return super.InitConfigNode(self, allSpecData, _PlayerSpec)
    end
end)

__Sealed__()
class "WarModeConfigNode" (function(_ENV)
    inherit "ConfigNode"

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
-- __Config__(_Config, true)
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

        node:SetField(name, ftype, default)
        node[name]:Subscribe(target)

        return function(value)
            node:SetValue(name, value, 2)
        end
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    property "AttributeTarget"  { default = AttributeTargets.Function }

    property "Node"             { type = ConfigNode }

    property "Name"             { type = String }

    property "Type"             { type = EnumType + StructType }

    property "Default"          { type = Any }

    ----------------------------------------------
    --                Constructor               --
    ----------------------------------------------
    __Arguments__{ ConfigNode, Boolean }
    function __ctor(self, node, value)
        self.Node               = node
        self.Type               = Boolean
        self.Default            = value
    end

    __Arguments__{ ConfigNode, Number }
    function __ctor(self, node, value)
        self.Node               = node
        self.Type               = Number
        self.Default            = value
    end

    __Arguments__{ ConfigNode, String }
    function __ctor(self, node, value)
        self.Node               = node
        self.Type               = String
        self.Default            = value
    end

    __Arguments__{ ConfigNode, NEString, Boolean }
    function __ctor(self, node, name, value)
        self.Node               = node
        self.Name               = name
        self.Type               = Boolean
        self.Default            = value
    end

    __Arguments__{ ConfigNode, NEString, Number }
    function __ctor(self, node, name, value)
        self.Node               = node
        self.Name               = name
        self.Type               = Number
        self.Default            = value
    end

    __Arguments__{ ConfigNode, EnumType + StructType, Any/nil }
    function __ctor(self, node, ftype, value)
        self.Node               = node
        self.Type               = ftype
        self.Default            = value
    end

    __Arguments__{ ConfigNode, NEString, EnumType + StructType, Any/nil }
    function __ctor(self, node, name, ftype, value)
        self.Node               = node
        self.Name               = name
        self.Type               = ftype
        self.Default            = value
    end

    __Arguments__{ ConfigNode, RawTable, Any/nil }
    function __ctor(self, node, definition, value)
        local ok, structType    = Attribute.IndependentCall(function(temp) local type = struct(temp) return type end, definition)
        if not ok then throw(structType) end

        self.Node               = node
        self.Type               = structType
        self.Default            = value
    end

    __Arguments__{ ConfigNode, NEString, RawTable, Any/nil }
    function __ctor(self, node, name, definition, value)
        local ok, structType    = Attribute.IndependentCall(function(temp) local type = struct(temp) return type end, definition)
        if not ok then throw(structType) end

        self.Node               = node
        self.Name               = name
        self.Type               = structType
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
