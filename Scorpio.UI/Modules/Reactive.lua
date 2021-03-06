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
local isObjectType              = Class.IsObjectType
local isProperty                = System.Property.Validate
local isIndexerProperty         = System.Property.IsIndexer
local getCurrentTarget          = Scorpio.UI.Style.GetCurrentTarget
local getFeature                = Class.GetFeature

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

__Static__() __Arguments__{ NEString }
function Wow.FromPanelProperty(name)
    return Observable(function(observer)
        local indicator         = getCurrentTarget()

        if indicator and isUIObject(indicator) then
            local frame         = indicator
            local parent        = indicator:GetParent()
            local subject, index

            while parent do
                if isObjectType(parent, ElementPanel) then
                    index       = frame.ID
                    local prop  = getFeature(getmetatable(parent), name, true)
                    if prop and isIndexerProperty(prop) then
                        subject = Observable.From(parent, name)
                    end
                    break
                end

                frame           = parent
                parent          = parent:GetParent()
            end

            if index and subject then
                local matchIdx  = subject.__MatchIndex
                if not matchIdx then
                    matchIdx    = {}
                    subject.__MatchIndex = matchIdx

                    subject:Subscribe(function(idx, ...)
                        local s = matchIdx[idx]
                        return s and s:OnNext(...)
                    end)
                end

                local idxSub    = matchIdx[index]
                if not idxSub then
                    idxSub      = Subject()
                    matchIdx[index] = idxSub
                end

                return idxSub:Subscribe(observer)
            end
        end
    end)
end