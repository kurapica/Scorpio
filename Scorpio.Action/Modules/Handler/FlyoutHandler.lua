--========================================================--
--             Scorpio Secure Flyout Handler              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.FlyoutHandler"        "1.0.0"
--========================================================--

_Enabled                        = false

MAX_SKILLLINE_TABS              = _G.MAX_SKILLLINE_TABS

_FlyoutSlot                     = {}
_FlyoutTexture                  = {}

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "flyout",
    Target                      = "spell",
    PickupSnippet               = "Custom",
}

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
__SystemEvent__"LEARNED_SPELL_IN_TAB"
function LEARNED_SPELL_IN_TAB()
    return UpdateFlyoutSlotMap()
end

__SystemEvent__"SPELLS_CHANGED" "SKILL_LINES_CHANGED" "PLAYER_GUILD_UPDATE" "PLAYER_SPECIALIZATION_CHANGED"
function SPELLS_CHANGED(unit)
    return (not unit or unit == "player") and UpdateFlyoutSlotMap()
end

function UpdateFlyoutSlotMap()
    local type, id
    local name, texture, offset, numEntries, isGuild, offspecID

    wipe(_FlyoutSlot)
    wipe(_FlyoutTexture)

    for i = 1, MAX_SKILLLINE_TABS do
        name, texture, offset, numEntries, isGuild, offspecID = GetSpellTabInfo(i)

        if not name then
            break
        end

        if not isGuild and offspecID == 0 then
            for index = offset + 1, offset + numEntries do
                type, id = GetSpellBookItemInfo(index, "spell")

                if type == "FLYOUT" then
                    if not _FlyoutSlot[id] then
                        _FlyoutSlot[id] = index
                        _FlyoutTexture[id] = GetSpellBookItemTexture(index, "spell")
                    end
                end
            end
        end
    end

    return handler:Refresh()
end

-- Flyout action type handler

-- Overwrite methods
function handler:PickupAction(target)
    return PickupSpellBookItem(_FlyoutSlot[target], "spell")
end

function handler:GetActionTexture()
    return _FlyoutTexture[self.ActionTarget]
end

function handler:SetTooltip(GameTooltip)
    GameTooltip:SetSpellBookItem(_FlyoutSlot[self.ActionTarget], "spell")
end

function handler:IsFlyout()
    return true
end

-- Expand IFActionHandler
interface "IFActionHandler"
    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    __Doc__[[The action button's content if its type is 'flyout']]
    property "FlytoutID" {
        Get = function(self)
            return self:GetAttribute("actiontype") == "flyout" and tonumber(self:GetAttribute("spell")) or nil
        end,
        Set = function(self, value)
            self:SetAction("flyout", value)
        end,
        Type = NumberNil,
    }
endinterface "IFActionHandler"