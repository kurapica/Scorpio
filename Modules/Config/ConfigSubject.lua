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
    --                              method                               --
    -----------------------------------------------------------------------
    function Subscribe(self, ...)
        local observer          = super.Subscribe(self, ...)
        return self[VALUE_FIELD] ~= nil and observer:OnNext(self[VALUE_FIELD])
    end

    --- Provides the observer with new data
    function OnNext(self, value)
        self[VALUE_FIELD]       = value
        onNext(self, value)
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