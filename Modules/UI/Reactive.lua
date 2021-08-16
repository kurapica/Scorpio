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

__Static__() __Arguments__{ NEString * 1 }
function Wow.FromUIProperty(...)
    local name                  = select("#", ...) == 1 and name or { ... }
    return Observable(function(observer)
        local indicator         = getCurrentTarget()

        if indicator and isUIObject(indicator) then
            local frame         = indicator
            local subject

            if type(name) == "string" then
                while frame do
                    subject     = Observable.From(frame, name)
                    if subject then break end

                    frame       = frame:GetParent()
                end
            else
                local nsubject
                for _, n in ipairs(name) do
                    frame       = indicator
                    nsubject    = nil

                    while frame do
                        nsubject= Observable.From(frame, n)
                        if nsubject then break end

                        frame   = frame:GetParent()
                    end

                    if nsubject then
                        subject = subject and subject:CombineLatest(nsubject) or nsubject
                    else
                        return
                    end
                end
            end
            if subject then return subject:Subscribe(observer) end
        end
    end)
end

__Static__() __Arguments__{ NEString * 1 }
function Wow.FromPanelProperty(...)
    local name                  = select("#", ...) == 1 and name or { ... }
    return Observable(function(observer)
        local indicator         = getCurrentTarget()

        if indicator and isUIObject(indicator) then
            local frame         = indicator
            local parent        = indicator:GetParent()
            local index

            while parent do
                if isObjectType(parent, ElementPanel) then
                    -- Only check the nearest element panel
                    index       = frame:GetID()
                    break
                end

                frame           = parent
                parent          = parent:GetParent()
            end

            if index then
                if type(name) == "string" then
                    local prop          = getFeature(getmetatable(parent), name, true)
                    local psub          = prop and isIndexerProperty(prop) and Observable.From(parent, name)
                    if not psub then return end

                    local matchIdx      = psub.__MatchIndex
                    if not matchIdx then
                        matchIdx        = {}
                        psub.__MatchIndex = matchIdx

                        psub:Subscribe(function(idx, ...)
                            local s = matchIdx[idx]
                            return s and s:OnNext(...)
                        end)
                    end

                    local idxSub        = matchIdx[index]
                    if not idxSub then
                        idxSub          = Subject()
                        matchIdx[index] = idxSub
                    end

                    return idxSub:Subscribe(observer)
                else
                    local subject

                    for _, n in ipairs(name) do
                        local prop      = getFeature(getmetatable(parent), n, true)
                        local psub      = prop and isIndexerProperty(prop) and Observable.From(parent, n)
                        if not psub then return end

                        local matchIdx  = psub.__MatchIndex
                        if not matchIdx then
                            matchIdx    = {}
                            psub.__MatchIndex = matchIdx

                            psub:Subscribe(function(idx, ...)
                                local s = matchIdx[idx]
                                return s and s:OnNext(...)
                            end)
                        end

                        local idxSub    = matchIdx[index]
                        if not idxSub then
                            idxSub      = Subject()
                            matchIdx[index] = idxSub
                        end

                        subject         = subject and subject:CombineLatest(idxSub) or idxSub
                    end

                    if subject then subject:Subscribe(observer) end
                end
            end
        end
    end)
end

__Static__() __Arguments__{ -UIObject }
function Wow.FromFrameSize(type)
    return Observable(function(observer)
        local frame             = getCurrentTarget()
        local subject

        while frame do
            if not isObjectType(frame, type) then
                frame           = frame:GetParent()
            else
                subject         = BehaviorSubject()

                Observable.From(frame.OnSizeChanged):Subscribe(function()
                    print("OnSizeChanged")
                    subject:OnNext(frame:GetSize())
                end)

                subject:OnNext(frame:GetSize())

                break
            end
        end

        if subject then subject:Subscribe(observer) end
    end)
end