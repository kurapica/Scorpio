--========================================================--
--                Scorpio SavedVariable Config Subject    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/05/02                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config.ConfigSubject"    "1.0.0"
--========================================================--

--- The config subject is a bidirectional binding
__Sealed__() __Final__()
class "ConfigSubject"           (function(_ENV)
    inherit "Subject"

    local NAME_FIELD            = 1
    local TYPE_FIELD            = 2
    local VALUE_FIELD           = 3
    local QUICKAPPLY_FIELD      = 4
    local DESC_FIELD            = 5
    local UNCOMMIT_FIELD        = 6

    local onNext                = Subject.OnNext

    -----------------------------------------------------------------------
    --                              event                                --
    -----------------------------------------------------------------------
    --- Fired when the value is set by UI
    event "OnValueSet"

    -----------------------------------------------------------------------
    --                             property                              --
    -----------------------------------------------------------------------
    --- The name of the config subject
    property "Name"             { field = NAME_FIELD, set = false }

    --- The type of the config subject
    property "Type"             { field = TYPE_FIELD, set = false }

    --- The value of the config subject
    property "Value"            { field = VALUE_FIELD, set = "SetValue" }

    --- Whether enable the quick apply
    property "EnableQuickApply" { field = QUICKAPPLY_FIELD, set = false }

    --- The description
    property "Description"      { field = DESC_FIELD, set = false }

    --- The un-commit value
    property "UnCommitValue"    { field = UNCOMMIT_FIELD, set = false }

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
        if self[VALUE_FIELD] ~= value then
            self[VALUE_FIELD]   = value
            if not self[QUICKAPPLY_FIELD] then
                self[UNCOMMIT_FIELD] = value
            end
            return onNext(self, value)
        end
    end

    --- Gets the current value
    function GetValue(self)
        return self[VALUE_FIELD]
    end

    --- Sets the value to the config node field
    function SetValue(self, value)
        if self[QUICKAPPLY_FIELD] then
            OnValueSet(self, value)
        else
            self[UNCOMMIT_FIELD] = value
        end
    end

    --- Commit the set value
    function Commit(self)
        if self[QUICKAPPLY_FIELD] then return end
        OnValueSet(self, self[UNCOMMIT_FIELD])
    end

    -----------------------------------------------------------------------
    --                            constructor                            --
    -----------------------------------------------------------------------
    __Arguments__{ String, AnyType, Any/nil, Boolean/nil, String/nil }
    function __ctor(self, name, type, value, enablequickapply, desc)
        self[NAME_FIELD]        = name
        self[TYPE_FIELD]        = type
        self[VALUE_FIELD]       = value
        self[QUICKAPPLY_FIELD]  = enablequickapply
        self[DESC_FIELD]        = desc

        if not enablequickapply then
            self[UNCOMMIT_FIELD]= value
        end
    end
end)