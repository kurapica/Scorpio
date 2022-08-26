--========================================================--
--                Scorpio SavedVariable Config Subject    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/05/02                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config.ConfigSubject"    "1.0.0"
--========================================================--

--- The config node field subject, used to get/set value of the field, the style system will also
-- check this type to know whether need use bidirectional binding when assign this to an ui element
__Sealed__() __Final__()
class "ConfigSubject"           (function(_ENV)
    inherit "Subject"

    local NODE_FIELD            = 1
    local NAME_FIELD            = 2
    local VALUE_FIELD           = 3

    local onNext                = Subject.OnNext

    -----------------------------------------------------------------------
    --                             property                              --
    -----------------------------------------------------------------------
    --- The config node
    property "Node"             { set = false, field = NODE_FIELD }

    --- The config node field
    property "Field"            { set = false, field = NAME_FIELD }

    --- The current config node field value
    property "Value"            { set = "SetValue", field = VALUE_FIELD }

    --- The tyep of the config node field
    property "Type"             { get = function(self) return select(1, self[NODE_FIELD]:GetField(self[NAME_FIELD])) end }

    --- The desc of the config node
    property "Desc"             { get = function(self) return select(2, self[NODE_FIELD]:GetField(self[NAME_FIELD])) end }

    --- Whether enable quick apply
    property "EnableQuickApply" { get = function(self) return select(4, self[NODE_FIELD]:GetField(self[NAME_FIELD])) end }

    --- The localized field name
    property "LocalizedField"   { get = function(self) return self[NODE_FIELD]._Addon._Locale[self[NAME_FIELD]] end }

    -----------------------------------------------------------------------
    --                              method                               --
    -----------------------------------------------------------------------
    function Subscribe(self, ...)
        local observer          = super.Subscribe(self, ...)
        -- Check value to avoid OnNext when define config node field handlers
        return self[VALUE_FIELD] ~= nil and observer:OnNext(self[VALUE_FIELD])
    end

    --- Provides the observer with new data
    function OnNext(self, value)
        self[VALUE_FIELD]       = value
        return onNext(self, value)
    end

    --- Gets the current value
    function GetValue(self)
        return self[VALUE_FIELD]
    end

    --- Sets the value to the config node field
    function SetValue(self, value)
        self[NODE_FIELD]:SetValue(self[NAME_FIELD], value, 2)
    end

    -----------------------------------------------------------------------
    --                            constructor                            --
    -----------------------------------------------------------------------
    __Arguments__{ ConfigNode, NEString, Any/nil }
    function __ctor(self, node, field, value)
        self[NODE_FIELD]        = node
        self[NAME_FIELD]        = field
        self[VALUE_FIELD]       = value
    end
end)