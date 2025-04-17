--========================================================--
--                Scorpio UnitFrame Reactive              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2025/04/01                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.Reactive""1.0.0"
--========================================================--

--- Style[HealthBar].text       = Wow.Unit.Health 
Scorpio.Wow.Unit                = reactive {
    --- No deep subscription for Unit, can override the default subscription
    Subscribe                   = function (self, ...)
        -- Gets the current unit frame
        local indicator         = getCurrentTarget()
        if not isUIObject(indicator) then return end
        while indicator and not isObjectType(indicator, IUnitFrame) do
            indicator           = indicator:GetParent()
        end
        if not indicator then return end
    
        -- handle the unit subject
        return indicator.Subject:Subscribe(...)
    end,
}

Scorpio.Wow.Unit.Health         = Observable(function(observer, subscription)
    
end)