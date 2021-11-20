--========================================================--
--             Scorpio Secure Spell Handler               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.SpellHandler"         "1.0.0"
--========================================================--

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "spell",
    InitSnippet                 = [[
        _StanceMap              = newtable()
        _MacroMap               = newtable()
    ]],

    UpdateSnippet               = [[
        local target            = ...

        if _StanceMap[target] then
            self:SetAttribute("*type*", "macro")
            self:SetAttribute("*macrotext*", "/click StanceButton".. _StanceMap[target])
        elseif _MacroMap[target] then
            self:SetAttribute("*type*", "macro")
            self:SetAttribute("*macrotext*", "/cast ".. _MacroMap[target])
        end
    ]],

    ReceiveSnippet              = [[
        local value, detail, extra = ...

        -- Spell id is stored in extra
        return extra
    ]],

    ClearSnippet                = [[
        self:SetAttribute("*type*", nil)
        self:SetAttribute("*macrotext*", nil)
    ]],
}

------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
_StanceMapTemplate              = "_StanceMap[%d] = %d\n"
_MacroMapTemplate               = "_MacroMap[%d]  = %q\n"

_StanceMap                      = {}
_Profession                     = {}
_MacroMap                       = {}

function OnEnable()
    OnEnable                    = nil

    UpdateStanceMap()
    UpdateMacroMap()

    Wow.FromEvent("UNIT_AURA"):MatchUnit("player"):Next():Subscribe(function()
        if not next(_StanceMap) then return end

        for _, btn in handler:GetIterator() do
            if _StanceMap[btn.ActionTarget] then
                handler:RefreshActionButtons(btn)
            end
        end
    end)

    return handler:RefreshActionButtons()
end

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
if Scorpio.IsRetail then
    __SystemEvent__"LEARNED_SPELL_IN_TAB"
    function LEARNED_SPELL_IN_TAB()
        return UpdateProfession()
    end

    __SystemEvent__"SKILL_LINES_CHANGED" "PLAYER_GUILD_UPDATE" "PLAYER_SPECIALIZATION_CHANGED"
    function SKILL_LINES_CHANGED(unit)
        return (not unit or unit == "player") and UpdateProfession()
    end
end

__SystemEvent__()
function SPELLS_CHANGED()
    UpdateMacroMap()
    UpdateStanceMap()
    return Scorpio.IsRetail and UpdateProfession()
end

__SystemEvent__"UPDATE_SHAPESHIFT_FORM" "PLAYER_ENTERING_WORLD" "SPELL_FLYOUT_UPDATE"
function UPDATE_SHAPESHIFT_FORM()
    return handler:RefreshActionButtons()
end

__SystemEvent__()
function UPDATE_SHAPESHIFT_FORMS()
    UpdateStanceMap()

    return handler:RefreshActionButtons()
end

__SystemEvent__()
function SPELL_UPDATE_COOLDOWN()
    return handler:RefreshCooldown()
end

__SystemEvent__"SPELL_UPDATE_USABLE" "PLAYER_ALIVE" "PLAYER_DEAD"
function SPELL_UPDATE_USABLE()
    return handler:RefreshUsable()
end

__SystemEvent__()
function CURRENT_SPELL_CAST_CHANGED()
    return handler:RefreshButtonState()
end

__NoCombat__()
function UpdateStanceMap()
    local str                   = ""

    for i = 1, GetNumShapeshiftForms() do
        local id                = select(4, GetShapeshiftFormInfo(i))
        if id then
            str                 = str.._StanceMapTemplate:format(id, i)
            _StanceMap[id]      = i
        end
    end

    if str ~= "" then
        handler:RunSnippet(str)

        for _, btn in handler:GetIterator() do
            if _StanceMap[btn.ActionTarget] then
                btn:SetAttribute("*type*", "macro")
                btn:SetAttribute("*macrotext*", "/click StanceButton".._StanceMap[btn.ActionTarget])
            end
        end
    end
end

__NoCombat__()
function UpdateMacroMap()
    local str                   = {}
    local cnt                   = 0
    local index                 = 1
    local _, id                 = GetSpellBookItemInfo(index, "spell")

    while id do
        local name              = GetSpellInfo(id)
        if name and _MacroMap[id] ~= name then
            _MacroMap[id]       = name
            cnt                 = cnt + 1
            str[cnt]            = _MacroMapTemplate:format(id, name)
        end

        index                   = index + 1
        _, id                   = GetSpellBookItemInfo(index, "spell")
    end

    if cnt > 0 then
        handler:RunSnippet(tblconcat(str, "\n"))

        for _, btn in handler:GetIterator() do
            if _MacroMap[btn.ActionTarget] then
                btn:SetAttribute("*type*", "macro")
                btn:SetAttribute("*macrotext*", "/cast ".._MacroMap[btn.ActionTarget])
            end
        end
    end
end

__NoCombat__()
function UpdateProfession()
    local lst                   = { GetProfessions() }
    local offset, spell, name

    for i = 1, 6 do
        if lst[i] then
            offset              = 1 + select(6, GetProfessionInfo(lst[i]))
            spell               = select(2, GetSpellBookItemInfo(offset, "spell"))
            name                = GetSpellBookItemName(offset, "spell")

            if _Profession[name] ~= spell then
                _Profession[name] = spell

                for _, btn in handler:GetIterator() do
                    if GetSpellInfo(btn.ActionTarget) == name then
                        btn:SetAction("spell", spell)
                    end
                end
            end
        end
    end
end

------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:Refresh()
    local target                = self.ActionTarget
    if not target then return end

    if not _StanceMap[target] and not _MacroMap[target] then
        local name              = GetSpellInfo(target)
        if name and _MacroMap[target] ~= name then
            _MacroMap[target]   = name

            NoCombat(function ()
                handler:RunSnippet( _MacroMapTemplate:format(target, name) )

                self:SetAttribute("*type*", "macro")
                self:SetAttribute("*macrotext*", "/cast ".. name)
            end)
        end
    end
end

function handler:PickupAction(target)
    return PickupSpell(target)
end

function handler:GetActionTexture()
    local target                = self.ActionTarget

    if _StanceMap[target] then
        return (GetShapeshiftFormInfo(_StanceMap[target]))
    elseif _MacroMap[target] then
        return GetSpellTexture(_MacroMap[target])
    else
        return GetSpellTexture(target)
    end
end

function handler:GetActionCharges()
    local target                = self.ActionTarget
    if _MacroMap[target] then
        return GetSpellCharges(_MacroMap[target])
    else
        return GetSpellCharges(target)
    end
end

function handler:GetActionCount()
    local target                = self.ActionTarget
    if _MacroMap[target] then
        return GetSpellCount(_MacroMap[target])
    end
end

function handler:GetActionCooldown()
    local target                = self.ActionTarget

    if _StanceMap[target] then
        if select(2, GetSpellCooldown(target)) > 2 then
            return GetSpellCooldown(target)
        else
            return 0, 0
        end
    elseif _MacroMap[target] then
        return GetSpellCooldown(_MacroMap[target])
    else
        return GetSpellCooldown(target)
    end
end

function handler:IsAttackAction()
    return IsAttackSpell(GetSpellInfo(self.ActionTarget))
end

function handler:IsActivedAction()
    local target                = self.ActionTarget
    if _StanceMap[target] then
        return select(2, GetShapeshiftFormInfo(_StanceMap[target]))
    elseif _MacroMap[target] then
        return IsCurrentSpell(_MacroMap[target])
    end
end

function handler:IsAutoRepeatAction()
    local target                = _MacroMap[self.ActionTarget]
    return target and IsAutoRepeatSpell(target)
end

function handler:IsUsableAction()
    local target                = self.ActionTarget

    if _StanceMap[target] then
        return select(3, GetShapeshiftFormInfo(_StanceMap[target]))
    elseif _MacroMap[target] then
        return IsUsableSpell(_MacroMap[target])
    end
end

function handler:IsConsumableAction()
    local target                = _MacroMap[self.ActionTarget]
    return target and IsConsumableSpell(_MacroMap[target])
end

function handler:IsInRange()
    local target                = self.ActionTarget
    if not _StanceMap[target] and _MacroMap[target] then
        local val               = IsSpellInRange(_MacroMap[target], self:GetAttribute("unit"))
        if val == 1 then return true end
        if val == 0 then return false end
        return val
    end
end

function handler:SetTooltip(tip)
    return tip:SetSpellByID(self.ActionTarget)
end

function handler:GetSpellId()
    return self.ActionTarget
end

function handler:IsRangeSpell()
    return true
end

function handler:Map(target, detail)
    -- Convert to spell id
    if tonumber(target) then
        target                  = tonumber(target)
    else
        target                  = GetSpellLink(target)
        target                  = tonumber(target and target:match("spell:(%d+)"))
    end

    if target and _Profession[GetSpellInfo(target)] then
        target                  = _Profession[GetSpellInfo(target)]
    end

    return target, detail
end
