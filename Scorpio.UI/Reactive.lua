--========================================================--
--             Scorpio UI Reactive                        --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/12/22                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Reactive"              "1.0.0"
--========================================================--

import "System.Reactive"

local isUIObject                = UI.IsUIObject
local getCurrentTarget          = Scorpio.UI.Style.GetCurrentTarget

__Static__() __Arguments__{ NEString }
function Wow.FromUIProperty(name)
    return Observable(function(observer)
        local indicator         = getCurrentTarget()

        if indicator and isUIObject(indicator) then
            local frame         = indicator
            local subject

            while frame do
                subject         = Observable.From(frame, name)
                if subject then return subject:Subscribe(observer) end

                frame           = frame:GetParent()
            end
        end
    end)
end