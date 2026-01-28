--========================================================--
--             Scorpio Secure Action Handler              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.ActionHandler"        "1.0.0"
--========================================================--

_Enabled                        = false
NUM_ACTIONBAR_BUTTONS           = 12

if Scorpio.IsRetail then
    GetActionCount              = GetActionUseCount or GetActionCount

    local oldGetActionCharges   = C_ActionBar.GetActionCharges

    local maxChargs             = {}

    function GetActionCharges(id)
        local r                 = oldGetActionCharges(id)
        if r then
            local maxCharges    = r.maxCharges
            if issecretvalue(maxChargs) then
                maxCharges      = maxChargs[id] or 0
            else
                maxChargs[id]   = maxCharges or 0
            end
            return r.currentCharges, maxCharges, r.cooldownStartTime, r.cooldownDuration, r.chargeModRate
        end
        return 0, 0, 0, 0, 1
    end
end

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "action",
    DragStyle                   = "Keep",
    ReceiveStyle                = "Keep",
    InitSnippet                 = [[
        NUM_ACTIONBAR_BUTTONS   = 12

        _MainPage               = newtable()
        MainPage                = newtable() -- need table save local values

        UpdateMainActionBar     = [=[
            local page          = ...
            if not page then page = GetActionBarPage() end
            if type(page) ~= "number" then
                if HasVehicleActionBar() then
                    page        = GetVehicleBarIndex()
                elseif HasOverrideActionBar() then
                    page        = GetOverrideBarIndex()
                elseif HasTempShapeshiftActionBar() then
                    page        = GetTempShapeshiftBarIndex()
                elseif HasBonusActionBar() then
                    page        = GetBonusBarIndex()
                else
                    page        = GetActionBarPage()
                end
            end

            MainPage[0]         = page

            for btn in pairs(_MainPage) do
                btn:SetAttribute("actionpage", MainPage[0])
                Manager:RunFor(btn, UpdateAction)
            end
        ]=]
    ]],

    PickupSnippet               = [[
        local target            = ...

        if self:GetAttribute("actionpage") and self:GetID() > 0 then
            target              = self:GetID() + (tonumber(self:GetAttribute("actionpage"))-1) * NUM_ACTIONBAR_BUTTONS
        end

        return "action", target
    ]],

    PreClickSnippet             = [[
        local type, action      = GetActionInfo(self:GetAttribute("action"))
        return nil, format("%s|%s", tostring(type), tostring(action))
    ]],

    PostClickSnippet            = [[
        local message           = ...
        local type, action = GetActionInfo(self:GetAttribute("action"))
        if message ~= format("%s|%s", tostring(type), tostring(action)) then
            return Manager:RunFor(self, UpdateAction)
        end
    ]],

    OnEnableChanged             = function(self, value) _Enabled = value end,
}

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
function OnEnable()
    OnEnable                    = nil

    Wow.FromEvent("ACTIONBAR_UPDATE_COOLDOWN"):Next():Subscribe(function()
        return handler:RefreshCooldown()
    end)

    Wow.FromEvent("ACTIONBAR_UPDATE_STATE"):Next():Subscribe(function()
        return handler:RefreshButtonState()
    end)

    Wow.FromEvent("ACTIONBAR_UPDATE_USABLE"):Next():Subscribe(function()
        return handler:RefreshUsable()
    end)
end

__SystemEvent__()
function ACTIONBAR_SLOT_CHANGED(slot)
    if not slot or slot == 0 then
        return handler:RefreshActionButtons()
    else
        for _, button in handler:GetIterator() do
            if slot == button.ActionTarget then
                handler:RefreshActionButtons(button)
            end
        end
    end
end

__SystemEvent__()
function UPDATE_SUMMONPETS_ACTION(self)
    for _, btn in handler:GetIterator() do
        if GetActionInfo(btn.ActionTarget) == "summonpet" then
            handler:RefreshIcon()
        end
    end
end

__SystemEvent__"UPDATE_SHAPESHIFT_FORM" "UPDATE_SHAPESHIFT_FORMS"
function UPDATE_SHAPESHIFT_FORM(self)
    return handler:RefreshActionButtons()
end

------------------------------------------------------
-- Secure Enviornment Init
------------------------------------------------------
do
    -- ActionBar swap register
    local state                 = {}

    -- special using
    tinsert(state, "[possessbar]possess")
    tinsert(state, "[shapeshift]tempshapeshift")
    tinsert(state, "[overridebar]override")
    tinsert(state, "[vehicleui]vehicle")

    -- action bar swap
    for i = 2, 6 do
        tinsert(state, ("[bar:%d]%d"):format(i, i))
    end

    -- stance
    local _, playerclass        = UnitClass("player")

    if playerclass == "DRUID" then
        -- prowl first
        tinsert(state, "[bonusbar:1,stealth]8")
    elseif playerclass == "WARRIOR" then
        --tinsert(state, "[stance:1]1")
        --tinsert(state, "[stance:2]7")
        --tinsert(state, "[stance:3]8")
    end

    -- bonusbar map
    for i = 1, 5 do
        tinsert(state, ("[bonusbar:%d]%d"):format(i, i+6))
    end

    tinsert(state, "1")

    state                       = table.concat(state, ";")

    handler:RunSnippet(("MainPage[0] = %s"):format(SecureCmdOptionParse(state))) --Init
    handler.Manager:RegisterStateDriver("page", state)
    handler.Manager:SetAttribute("_onstate-page", [[Manager:Run(UpdateMainActionBar, newstate)]])
end

------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:GetActionDetail()
    if self:GetID() > 0 then
        local target, desc      = self:GetID() + (tonumber(self:GetAttribute("actionpage") or 1)-1) * NUM_ACTIONBAR_BUTTONS

        if target then
            local type, id      = GetActionInfo(target)
            if type and id then
                desc             = ""..type.."_"..id
            end
        end

        return target, desc
    end
end

function handler:PickupAction(target)
    return PickupAction(target)
end

function handler:HasAction()
    return HasAction(self.ActionTarget)
end

function handler:GetActionText()
    return GetActionText(self.ActionTarget)
end

function handler:GetActionTexture()
    return GetActionTexture(self.ActionTarget)
end

function handler:GetActionCharges()
    return GetActionCharges(self.ActionTarget)
end

function handler:GetActionCount()
    return HasAction(self.ActionTarget) and GetActionCount(self.ActionTarget) or nil
end

function handler:GetActionCooldown()
    return GetActionCooldown(self.ActionTarget)
end

function handler:IsAttackAction()
    return IsAttackAction(self.ActionTarget)
end

function handler:IsEquippedItem()
    return IsEquippedAction(self.ActionTarget)
end

function handler:IsActivedAction()
    return IsCurrentAction(self.ActionTarget)
end

function handler:IsAutoRepeatAction()
    return IsAutoRepeatAction(self.ActionTarget)
end

function handler:IsUsableAction()
    return IsUsableAction(self.ActionTarget)
end

function handler:IsConsumableAction()
    local target                = self.ActionTarget
    return IsConsumableAction(target) or IsStackableAction(target) -- or (not IsItemAction(target) and GetActionCount(target) > 0)
end

function handler:IsInRange()
    return IsActionInRange(self.ActionTarget, self:GetAttribute("unit"))
end

function handler:SetTooltip(tip)
    return tip:SetAction(self.ActionTarget)
end

function handler:GetSpellId()
    local type, id              = GetActionInfo(self.ActionTarget)
    if type == "spell" then
        return id
    elseif type == "macro" then
        return GetMacroSpell(id)
    end
end

function handler:IsRangeSpell()
    return true
end

------------------------------------------------------
-- Extend Definitions
------------------------------------------------------
class "SecureActionButton" (function(_ENV)

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    --- Set the action page of the button
    __NoCombat__()
    function SetActionPage(self, page)
        page                    = tonumber(page) or 0
        page                    = page and floor(page)
        if page and page <= 0 then page = nil end
        if self:GetID() == nil then page = nil end

        if self:GetActionPage() ~= page then
            self:SetAttribute("actionpage", page)
            if page then
                self:SetAction("action", tonumber(self:GetAttribute("action")) or self:GetID() or 1)
            else
                self:SetAction(nil)
            end
        end
    end

    --- Get Action Page of action button
    function GetActionPage(self)
        local page              = self:GetAttribute("actionpage")
        return page and tonumber(page)
    end

    --- Set if this action button belongs to main page
    __NoCombat__()
    function SetMainPage(self, isMain)
        isMain                  = isMain and true or nil
        if self.__IFActionHandler_IsMainPage ~= isMain then
            self.__IFActionHandler_IsMainPage = isMain

            if isMain then
                handler.Manager:SetFrameRef("MainPageButton", self)
                handler.Manager:Execute([[
                    local btn   = Manager:GetFrameRef("MainPageButton")
                    if btn then
                        _MainPage[btn] = true
                        btn:SetAttribute("actionpage", MainPage[0] or 1)
                    end
                ]])
                self:SetAction("action", tonumber(self:GetAttribute("action")) or self:GetID() or 1)
            else
                handler.Manager:SetFrameRef("MainPageButton", self)
                handler.Manager:Execute([[
                    local btn   = Manager:GetFrameRef("MainPageButton")
                    if btn then
                        _MainPage[btn] = nil
                        btn:SetAttribute("actionpage", nil)
                    end
                ]])
                self:SetAction(nil)
            end
        end
    end

    --- Whether if the action button is belong to main page
    function IsMainPage(self)
        return self.__IFActionHandler_IsMainPage or false
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The action page of the action button if type is 'action'
    property "ActionPage"       { type = Number, set = SetActionPage, get = GetActionPage  }

    --- Whether the action button is used in the main page
    property "MainPage"         { type = Boolean, set = SetMainPage, get = IsMainPage }
end)