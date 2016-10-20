--========================================================--
--                Scorpio.ISystemEvent                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/09/09                              --
--========================================================--

--========================================================--
Module            "Scorpio.ISystemEvent"             "1.0.0"
--========================================================--

__Doc__[[The system event or custom event provider]]
__Sealed__() interface "ISystemEvent" (function(_ENV)

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    _EventManager = CreateFrame("Frame")
    _EventManager:Hide()

    function _EventManager:OnEvent(evt, ...)
        local objs = rawget(_EventDistribution, evt)
        if objs then
            for obj in pairs(objs) do
                OnEvent(obj, evt, ...)
            end
        end
    end

    _EventManager:SetScript("OnEvent", _EventManager.OnEvent)

    _EventDistribution = setmetatable({},
        {
            __index = function (self, key)
                if type(key) == "string" then
                    local val = setmetatable({}, META_WEAKKEY)
                    rawset(self, key, val)
                    return val
                end
            end,
        }
    )

    ----------------------------------------------
    ------------------- Event  -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Fired when the system event or custom event is triggered</desc>
        <param name="event" type="string">the event's name</param>
        <param name="...">the other arguments</param>
    ]]
    event "OnEvent"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Register system event or custom event</desc>
        <param name="event" type="string">the system|custom event name</param>
    ]]
    __Arguments__{ String }
    function RegisterEvent(self, evt)
        local objs = _EventDistribution[evt]
        if objs then
            if not next(objs) then
                pcall(_EventManager.RegisterEvent, _EventManager, evt)
            end
            objs[self] = true
        end
    end

    __Doc__[[
        <desc>Whether the system event or custom event is registered</desc>
        <param name="event" type="string">the system|custom event name</param>
        <return>true if the event is registered</return>
    ]]
    __Arguments__{ String }
    function IsEventRegistered(self, evt)
        local objs = rawget(_EventDistribution, evt)
        return objs and objs[self] and true or false
    end

    __Doc__[[
        <desc>Unregister system event or custom event</desc>
        <param name="event" type="string">the system|custom event name</param>
    ]]
    __Arguments__{ String }
    function UnregisterEvent(self, evt)
        local objs = rawget(_EventDistribution, evt)
        if objs and objs[self] then
            objs[self] = nil
            if not next(objs) then
                pcall(_EventManager.UnregisterEvent, _EventManager, evt)
            end
        end
    end

    __Doc__[[Unregister all the events]]
    function UnregisterAllEvents(self)
        for evt, objs in pairs(_EventDistribution) do
            if objs[self] then
                objs[self] = nil
                if not next(objs) then
                    pcall(_EventManager.UnregisterEvent, _EventManager, evt)
                end
            end
        end
    end

    __Doc__[[
        <desc>Trigger the event</desc>
        <param name="event" type="string">the event's name</param>
        <param name="...">the other arguments</param>
    ]]
    function FireEvent(self, evt, ...)
        return _EventManager:OnEvent(evt, ...)
    end

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        self:UnregisterAllEvents()
    end
end)