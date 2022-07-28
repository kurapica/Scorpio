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
    local TYPE_FIELD            = 3
    local VALUE_FIELD           = 4
    local DESC_FIELD            = 5

    local onNext                = Subject.OnNext

    -----------------------------------------------------------------------
    --                             property                              --
    -----------------------------------------------------------------------
    --- The config node
    property "Node"             { set = false, field = NODE_FIELD }

    --- The config node field
    property "Field"            { set = false, field = NAME_FIELD }

    --- The config field type
    property "Type"             { set = false, field = TYPE_FIELD }

    --- The current config node field value
    property "Value"            { set = "SetValue", field = VALUE_FIELD }

    --- The config field description
    property "Desc"             { set = false, field = DESC_FIELD }

    -----------------------------------------------------------------------
    --                              method                               --
    -----------------------------------------------------------------------
    function Subscribe(self, ...)
        local observer          = super.Subscribe(self, ...)
        return observer:OnNext(self[VALUE_FIELD])
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
    __Arguments__{ ConfigNode, NEString, AnyType, Any/nil, String/nil }
    function __ctor(self, node, field, type, value, desc)
        self[NODE_FIELD]        = node
        self[NAME_FIELD]        = field
        self[TYPE_FIELD]        = type
        self[VALUE_FIELD]       = value
        self[DESC_FIELD]        = desc
    end
end)