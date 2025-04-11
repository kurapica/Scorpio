--========================================================--
--                Scorpio UnitFrame Reactive              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2025/04/01                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.Reactive""1.0.0"
--========================================================--

export                          {
    getCurrentTarget            = UI.Style.GetCurrentTarget,
    isUIObject                  = UI.IsUIObject,
    isObjectType                = Class.IsObjectType,
}

--- Style[HealthBar].text       = Wow.Unit.Health 
Scorpio.Wow.Unit                = Observable(function(observer, subscription)
    -- Gets the current unit frame
    local indicator             = getCurrentTarget()
    if not isUIObject(indicator) then return end
    while indicator and not isObjectType(indicator, IUnitFrame) do
        indicator               = indicator:GetParent()
    end
    if not indicator then return end

    -- handle the unit subject
    local subject               = indicator.Subject
    
end)

Style[healthbar].text = Wow.Unit.Health