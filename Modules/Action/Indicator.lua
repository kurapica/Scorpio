--========================================================--
--                Scorpio Action Button Indicator         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/06/19                              --
--========================================================--

--========================================================--
Scorpio"Scorpio.Secure.SecureActionButton.Indicator" "1.0.0"
--========================================================--

namespace "Scorpio.Secure.SecureActionButton"

import "System.Reactive"

------------------------------------------------------------
--                      Help Service                      --
------------------------------------------------------------
AUTOCAST_SPEEDS                 = { 2, 4, 6, 8 }
AUTOCAST_TIMERS                 = { 0, 0, 0, 0 }

AUTO_CAST_SHINES                = {}

__Service__(true)
function AutoCastShineService()
    local prev                  = GetTime()

    while true do
        local hasShine          = false
        local now               = GetTime()
        local elapsed           = now - prev
        prev                    = now

        for i in pairs(AUTOCAST_TIMERS) do
            AUTOCAST_TIMERS[i]  = AUTOCAST_TIMERS[i] + elapsed
            if AUTOCAST_TIMERS[i] > AUTOCAST_SPEEDS[i] * 4 then
                AUTOCAST_TIMERS[i] = 0
            end
        end

        for shine in pairs(AUTO_CAST_SHINES) do
            hasShine            = true
            local distance      = shine:GetWidth()

            for i = 1, 4 do
                local timer     = AUTOCAST_TIMERS[i]
                local speed     = AUTOCAST_SPEEDS[i]

                if ( timer <= speed ) then
                    local basePosition = timer/speed*distance
                    shine[0+i]:SetPoint("CENTER", shine, "TOPLEFT", basePosition, 0)
                    shine[4+i]:SetPoint("CENTER", shine, "BOTTOMRIGHT", -basePosition, 0)
                    shine[8+i]:SetPoint("CENTER", shine, "TOPRIGHT", 0, -basePosition)
                    shine[12+i]:SetPoint("CENTER", shine, "BOTTOMLEFT", 0, basePosition)
                elseif ( timer <= speed*2 ) then
                    local basePosition = (timer-speed)/speed*distance
                    shine[0+i]:SetPoint("CENTER", shine, "TOPRIGHT", 0, -basePosition)
                    shine[4+i]:SetPoint("CENTER", shine, "BOTTOMLEFT", 0, basePosition)
                    shine[8+i]:SetPoint("CENTER", shine, "BOTTOMRIGHT", -basePosition, 0)
                    shine[12+i]:SetPoint("CENTER", shine, "TOPLEFT", basePosition, 0)
                elseif ( timer <= speed*3 ) then
                    local basePosition = (timer-speed*2)/speed*distance
                    shine[0+i]:SetPoint("CENTER", shine, "BOTTOMRIGHT", -basePosition, 0)
                    shine[4+i]:SetPoint("CENTER", shine, "TOPLEFT", basePosition, 0)
                    shine[8+i]:SetPoint("CENTER", shine, "BOTTOMLEFT", 0, basePosition)
                    shine[12+i]:SetPoint("CENTER", shine, "TOPRIGHT", 0, -basePosition)
                else
                    local basePosition = (timer-speed*3)/speed*distance
                    shine[0+i]:SetPoint("CENTER", shine, "BOTTOMLEFT", 0, basePosition)
                    shine[4+i]:SetPoint("CENTER", shine, "TOPRIGHT", 0, -basePosition)
                    shine[8+i]:SetPoint("CENTER", shine, "TOPLEFT", basePosition, 0)
                    shine[12+i]:SetPoint("CENTER", shine, "BOTTOMRIGHT", -basePosition, 0)
                end
            end
        end

        if not hasShine then
            NextEvent("SCORPIO_SAB_AUTO_CAST_SHINE")
            prev                = GetTime()
        end

        Next()
    end
end

function RegisterAutoCastShine(self)
    if self.IsAutoCast then
        if not next(AUTO_CAST_SHINES) then FireSystemEvent("SCORPIO_SAB_AUTO_CAST_SHINE") end
        AUTO_CAST_SHINES[self]  = true
    else
        AUTO_CAST_SHINES[self]  = nil
    end
end

------------------------------------------------------------
--                       Indicator                        --
------------------------------------------------------------
__Sealed__()
class "SpellActivationAlert" (function(_ENV)
    inherit "Frame"

    __Sealed__() enum "AnimationState" { "STOP", "IN", "OUT" }

    __Bubbling__{ ["OuterGlowOver.Out"] = "OnFinished" }
    event "OnFinished"

    ------------------------------------------------------
    --                     Helpers                      --
    ------------------------------------------------------
    local hiddenFrame           = CreateFrame("Frame") hiddenFrame:Hide()
    local recycle

    local function ChangeAntsSize(self)
        local w, h              = self:GetSize()
        self:GetChild("Ants"):SetSize(w * 0.85, h * 0.85)
    end

    local function OnFinished(self)
        return recycle[getmetatable(self)](self)
    end

    recycle                     = setmetatable({}, { __index = function(self, cls)
            local pool          = Recycle(cls, tostring(cls):gsub("%.", "_") .. "%d", hiddenFrame)

            function pool:OnInit(alert)
                alert.OnFinished= OnFinished
            end

            function pool:OnPop(alert)
                alert:Show()
            end

            function pool:OnPush(alert)
                alert.AnimationState = "STOP"
                alert:SetParent(hiddenFrame)
                alert:ClearAllPoints()
                alert:Hide()
            end

            rawset(self, cls, pool)
            return pool
        end
    })

    ------------------------------------------------------
    --                 Static Property                  --
    ------------------------------------------------------
    __Static__() property "Pool" { set = false, default = recycle }

    ------------------------------------------------------
    --               Observable Property                --
    ------------------------------------------------------
    --- The animation state
    __Observable__()
    property "AnimationState"   { type = AnimationState, default = "STOP", handler = function(self, val) return val == "IN" and Next(ChangeAntsSize, self) end }

    ------------------------------------------------------
    --                   Constructor                    --
    ------------------------------------------------------
    __Template__{
        Spark                   = Texture,
        InnerGlow               = Texture,
        InnerGlowOver           = Texture,
        OuterGlow               = Texture,
        OuterGlowOver           = Texture,
        Ants                    = Texture,

        {
            Spark               = {
                In              = AnimationGroup,
                {
                    In          = {
                        Scale1  = Scale,
                        Scale2  = Scale,
                        Alpha1  = Alpha,
                        Alpha2  = Alpha,
                    }
                }
            },
            InnerGlow           = {
                In              = AnimationGroup,
                {
                    In          = {
                        Scale   = Scale,
                        Alpha   = Alpha,
                    }
                }
            },
            InnerGlowOver       = {
                In              = AnimationGroup,
                {
                    In          = {
                        Scale   = Scale,
                        Alpha   = Alpha,
                    }
                }
            },
            OuterGlow           = {
                In              = AnimationGroup,
                Out             = AnimationGroup,
                {
                    In          = {
                        Scale   = Scale
                    },
                    Out         = {
                        Alpha   = Alpha,
                    }
                }
            },
            OuterGlowOver       = {
                In              = AnimationGroup,
                Out             = AnimationGroup,
                {
                    In          = {
                        Scale   = Scale,
                        Alpha   = Alpha,
                    },
                    Out         = {
                        Alpha1  = Alpha,
                        Alpha2  = Alpha,
                    }
                }
            },
            Ants                = {
                In              = AnimationGroup,
                Out             = AnimationGroup,
                {
                    In          = {
                        Alpha   = Alpha,
                    },
                    Out         = {
                        Alpha   = Alpha,
                    }
                }
            }
        }
    }
    function __ctor(self)
    end
end)

__Sealed__() __ChildProperty__(SecureActionButton, "AutoCastShine")
class "AutoCastShine" (function(_ENV)
    inherit "Frame"

    ------------------------------------------------------
    --                     Property                     --
    ------------------------------------------------------
    property "IsAutoCast"       { type = Boolean, handler = RegisterAutoCastShine }

    ------------------------------------------------------
    --                   Constructor                    --
    ------------------------------------------------------
    function __ctor(self)
        for i = 1, 16 do
            local part          = Texture("part"..i, self, "BACKGROUND")
            part:SetTexture([[Interface\ItemSocketingFrame\UI-ItemSockets]])
            part:SetBlendMode("ADD")
            part:SetTexCoord(0.3984375, 0.4453125, 0.40234375, 0.44921875)
            part:SetPoint("CENTER")

            local size          =  i%4 == 1 and 13
                                or i%4 == 2 and 10
                                or i%4 == 3 and 7
                                or 4
            part:SetSize(size, size)

            self[i]             = part
        end
    end
end)

--- SpellActivationAlert
UI.Property                     {
    name                        = "SpellActivationAlert",
    require                     = Frame,
    type                        = Boolean,
    default                     = false,
    set                         = function(self, value)
        local alert             = self.__SpellActivationAlert
        if value then
            if not alert then
                alert           = SpellActivationAlert.Pool[SpellActivationAlert]()
                local w, h      = self:GetSize()

                alert:SetParent(self)
                alert:ClearAllPoints()
                alert:SetPoint("CENTER")
                alert:SetSize(w * 1.4, h * 1.4)
                self.__SpellActivationAlert = alert
            end

            alert.AnimationState= "IN"
        else
            if alert then
                alert.AnimationState = "OUT"
                self.__SpellActivationAlert = nil
            end
        end
    end,
}

-- The bottom background texture
UI.Property                     {
    name                        = "CountLabel",
    require                     = SecureActionButton,
    childtype                   = FontString,
}

-- The bottom background texture
UI.Property                     {
    name                        = "NameLabel",
    require                     = SecureActionButton,
    childtype                   = FontString,
}

-- The bottom background texture
UI.Property                     {
    name                        = "HotKeyLabel",
    require                     = SecureActionButton,
    childtype                   = FontString,
}

-- The flash texture
UI.Property                     {
    name                        = "FlashTexture",
    require                     = SecureActionButton,
    childtype                   = Texture,
}

-- The equipped item texture
UI.Property                     {
    name                        = "EquippedItemTexture",
    require                     = SecureActionButton,
    childtype                   = Texture,
}

-- The flyout border
UI.Property                     {
    name                        = "FlyoutBorder",
    require                     = SecureActionButton,
    childtype                   = Texture,
}

-- The flyout border shadow
UI.Property                     {
    name                        = "FlyoutBorderShadow",
    require                     = SecureActionButton,
    childtype                   = Texture,
}

-- The flyout arrow
UI.Property                     {
    name                        = "FlyoutArrow",
    require                     = SecureActionButton,
    childtype                   = Texture,
}

--- The Auto castable texture
UI.Property                     {
    name                        = "AutoCastableTexture",
    require                     = SecureActionButton,
    childtype                   = Texture,
}

--- The search overlay texture
UI.Property                     {
    name                        = "SearchOverlay",
    require                     = SecureActionButton,
    childtype                   = Texture,
}

--- The charge cooldown
UI.Property                     {
    name                        = "ChargeCooldown",
    require                     = SecureActionButton,
    childtype                   = Cooldown,
}

--- The quest icon texture
UI.Property                     {
    name                        = "IconQuestTexture",
    require                     = ContainerFrameItemButton,
    childtype                   = Texture,
}

--- The junk icon texture
UI.Property                     {
    name                        = "JunkIcon",
    require                     = ContainerFrameItemButton,
    childtype                   = Texture,
}

--- The new item texture
UI.Property                     {
    name                        = "NewItemTexture",
    require                     = ContainerFrameItemButton,
    childtype                   = Texture,
}

--- The battlepay item texture
UI.Property                     {
    name                        = "BattlepayItemTexture",
    require                     = ContainerFrameItemButton,
    childtype                   = Texture,
}

--- The glow flash
UI.Property                     {
    name                        = "GlowFlashTexture",
    require                     = ContainerFrameItemButton,
    childtype                   = Texture,
}

--- The upgrade icon
UI.Property                     {
    name                        = "UpgradeIcon",
    require                     = ContainerFrameItemButton,
    childtype                   = Texture,
}

------------------------------------------------------------
--                     Default Style                      --
------------------------------------------------------------
local shareAtlas                = AtlasType("", true)
local antAnimate                = AnimateTexCoords(256, 256, 48, 48, 22, 0.01)
local usableColor               = Color.WHITE
local unUsableColor             = Color(0.4, 0.4, 0.4)
local RANGE_INDICATOR           = "●"
local isInState                 = function(s) return s == "IN" end
local isOutState                = function(s) return s == "OUT" end
local isPlaying                 = function(s) return s ~= "STOP" and antAnimate or nil end
local flyoutArrowLocation       = { UP = { Anchor("BOTTOM", 0, 0, nil, "TOP") }, DOWN = { Anchor("TOP", 0, 0, nil, "BOTTOM") }, LEFT = { Anchor("RIGHT", 0, 0, nil, "LEFT") }, RIGHT = { Anchor("LEFT", 0, 0, nil, "RIGHT") } }
local replaceKey                = {
    ['ALT']                     = 'A',
    ['CTRL']                    = 'C',
    ['SHIFT']                   = 'S',
    ['NUMPAD']                  = 'N',
    ['PLUS']                    = '+',
    ['MINUS']                   = '-',
    ['MULTIPLY']                = '*',
    ['DIVIDE']                  = '/',
    ['BACKSPACE']               = 'BAK',
    ['BUTTON']                  = 'B',
    ['CAPSLOCK']                = 'CAPS',
    ['CLEAR']                   = 'CLR',
    ['DELETE']                  = 'DEL',
    ['END']                     = 'END',
    ['HOME']                    = 'HME',
    ['INSERT']                  = 'INS',
    ['MOUSEWHEELDOWN']          = 'WD',
    ['MOUSEWHEELUP']            = 'WU',
    ['NUMLOCK']                 = 'NL',
    ['PAGEDOWN']                = 'PD',
    ['PAGEUP']                  = 'PU',
    ['SCROLLLOCK']              = 'SL',
    ['SPACEBAR']                = 'SP',
    ['SPACE']                   = 'SP',
    ['TAB']                     = '↦',
    ['DOWNARROW']               = '↓',
    ['LEFTARROW']               = '←',
    ['RIGHTARROW']              = '→',
    ['UPARROW']                 = '↑',
}

LE_ITEM_QUALITY_COMMON          = _G.LE_ITEM_QUALITY_COMMON or Scorpio.IsRetail and _G.Enum.ItemQuality.Common or 1
NEW_ITEM_ATLAS_BY_QUALITY       = Toolset.clone(NEW_ITEM_ATLAS_BY_QUALITY, true)
BAG_ITEM_QUALITY_COLORS         = XDictionary(BAG_ITEM_QUALITY_COLORS):Map(function(k, v) return Color(v.r, v.g, v.b) end):ToTable()
DEFAULT_ITEM_ATLAS              = "bags-glow-white"

Style.UpdateSkin("Default",     {
    [SpellActivationAlert]      = {
        frameStrata             = "DIALOG",

        Spark                   = {
            drawLayer           = "BACKGROUND",
            file                = [[Interface\SpellActivationOverlay\IconAlert]],
            texCoords           = RectType(0.00781250, 0.61718750, 0.00390625, 0.26953125),
            setAllPoints        = true,
            alpha               = 0,

            In                  = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isInState),

                Scale1          = {
                    order       = 1,
                    duration    = 0.2,
                    scale       = Dimension(1.5, 1.5),
                },
                Alpha1          = {
                    order       = 1,
                    duration    = 0.2,
                    fromAlpha   = 0,
                    toAlpha     = 1,
                },
                Scale2          = {
                    order       = 1,
                    duration    = 0.2,
                    startDelay  = 0.2,
                    scale       = Dimension(0.666666, 0.666666),
                },
                Alpha2          = {
                    order       = 1,
                    duration    = 0.2,
                    startDelay  = 0.2,
                    fromAlpha   = 1,
                    toAlpha     = 0,
                },
            },
        },

        InnerGlow               = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\SpellActivationOverlay\IconAlert]],
            texCoords           = RectType(0.00781250, 0.50781250, 0.27734375, 0.52734375),
            setAllPoints        = true,
            alpha               = 0,

            In                  = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isInState),

                Scale           = {
                    order       = 1,
                    duration    = 0.3,
                    fromScale   = Dimension(0.5, 0.5),
                    toScale     = Dimension(1, 1)
                },
                Alpha           = {
                    order       = 1,
                    duration    = 0.2,
                    startDelay  = 0.3,
                    fromAlpha   = 1,
                    toAlpha     = 0,
                },
            },
        },

        InnerGlowOver           = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\SpellActivationOverlay\IconAlert]],
            texCoords           = RectType(0.00781250, 0.50781250, 0.53515625, 0.78515625),
            location            = { Anchor("TOPLEFT", 0, 0, "InnerGlow"), Anchor("BOTTOMRIGHT", 0, 0, "InnerGlow") },
            alpha               = 0,

            In                  = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isInState),

                Scale           = {
                    order       = 1,
                    duration    = 0.3,
                    fromScale   = Dimension(0.5, 0.5),
                    toScale     = Dimension(1, 1)
                },
                Alpha           = {
                    order       = 1,
                    duration    = 0.3,
                    fromAlpha   = 1,
                    toAlpha     = 0,
                },
            },
        },

        OuterGlow               = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\SpellActivationOverlay\IconAlert]],
            texCoords           = RectType(0.00781250, 0.50781250, 0.27734375, 0.52734375),
            setAllPoints        = true,
            alpha               = 1,

            In                  = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isInState),

                Scale           = {
                    order       = 1,
                    duration    = 0.3,
                    fromScale   = Dimension(2, 2),
                    toScale     = Dimension(1, 1),
                },
            },

            Out                 = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isOutState),

                Alpha           = {
                    order       = 1,
                    duration    = 0.2,
                    startDelay  = 0.2,
                    fromAlpha   = 1,
                    toAlpha     = 0,
                },
            },
        },

        OuterGlowOver           = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\SpellActivationOverlay\IconAlert]],
            texCoords           = RectType(0.00781250, 0.50781250, 0.53515625, 0.78515625),
            location            = { Anchor("TOPLEFT", 0, 0, "OuterGlow"), Anchor("BOTTOMRIGHT", 0, 0, "OuterGlow") },
            alpha               = 1,

            In                  = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isInState),

                Scale           = {
                    order       = 1,
                    duration    = 0.3,
                    fromScale   = Dimension(2, 2),
                    toScale     = Dimension(1, 1),
                },
                Alpha           = {
                    order       = 1,
                    duration    = 0.3,
                    fromAlpha   = 1,
                    toAlpha     = 0,
                },
            },

            Out                 = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isOutState),

                Alpha1          = {
                    order       = 1,
                    duration    = 0.2,
                    fromAlpha   = 0,
                    toAlpha     = 1,
                },
                Alpha2          = {
                    order       = 2,
                    duration    = 0.2,
                    fromAlpha   = 1,
                    toAlpha     = 0,
                },
            },
        },

        Ants                    = {
            drawLayer           = "OVERLAY",
            file                = [[Interface\SpellActivationOverlay\IconAlertAnts]],
            setAllPoints        = true,
            animateTexCoords    = Wow.FromUIProperty("AnimationState"):Map(isPlaying),
            alpha               = 1,

            In                  = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isInState),

                Alpha           = {
                    order       = 1,
                    duration    = 0.2,
                    startDelay  = 0.2,
                    fromAlpha   = 0,
                    toAlpha     = 1,
                }
            },

            Out                 = {
                playing         = Wow.FromUIProperty("AnimationState"):Map(isOutState),

                Alpha           = {
                    order       = 1,
                    duration    = 0.2,
                    fromAlpha   = 1,
                    toAlpha     = 0,
                },
            },
        },
    },

    [SecureActionButton]        = {
        size                    = Size(36, 36),
        alpha                   = Wow.FromUIProperty("GridVisible", "GridAlwaysShow"):Map(function(v, a) return (v or a) and 1 or 0 end),

        NormalTexture           = {
            file                = Wow.FromUIProperty("HasAction"):Map(function(v) return v and [[Interface\Buttons\UI-Quickslot2]] or [[Interface\Buttons\UI-Quickslot]] end),
            location            = { Anchor("TOPLEFT", -15, 15), Anchor("BOTTOMRIGHT", 15, -15) },
        },
        PushedTexture           = {
            file                = [[Interface\Buttons\UI-Quickslot-Depress]],
            setAllPoints        = true,
        },
        HighlightTexture        = {
            file                = [[Interface\Buttons\ButtonHilight-Square]],
            setAllPoints        = true,
            alphaMode           = "ADD",
        },
        CheckedTexture          = {
            file                = [[Interface\Buttons\CheckButtonHilight]],
            setAllPoints        = true,
            alphaMode           = "ADD",
        },
        IconTexture             = {
            drawLayer           = "BACKGROUND",
            file                = Wow.FromUIProperty("Icon"),
            setAllPoints        = true,
            vertexColor         = Wow.FromUIProperty("IsUsable"):Map(function(v) return v and usableColor or unUsableColor end),
            desaturated         = Wow.FromUIProperty("IconLocked"),
        },
        CountLabel              = {
            drawLayer           = "ARTWORK",
            fontObject          = NumberFontNormal,
            subLevel            = 2,
            justifyH            = "RIGHT",
            location            = { Anchor("BOTTOMRIGHT", -2, 2) },
            text                = Wow.FromUIProperty("Count"),
        },
        NameLabel               = {
            drawLayer           = "OVERLAY",
            fontObject          = GameFontHighlightSmallOutline,
            justifyH            = "CENTER",
            height              = 10,
            location            = { Anchor("BOTTOMLEFT", 0, 2), Anchor("BOTTOMRIGHT", 0, 2) },
            text                = Wow.FromUIProperty("Text"),
        },
        HotKeyLabel             = {
            drawLayer           = "ARTWORK",
            subLevel            = 2,
            fontObject          = NumberFontNormal,
            justifyH            = "RIGHT",
            height              = 10,
            location            = { Anchor("TOPLEFT", 1, -3), Anchor("TOPRIGHT", -1, -3) },
            text                = Wow.FromUIProperty("HotKey"):Map(function(val) return val and val:upper():gsub(' ', ''):gsub("%a+", replaceKey) or RANGE_INDICATOR end),
            vertexColor         = Wow.FromUIProperty("InRange"):Map(function(ir) return ir == false and Color.RED or Color.WHITE end),
            visible             = Wow.FromUIProperty("HotKey", "InRange"):Map(function(key, ir) return key or ir ~= nil end),
        },
        Cooldown                = {
            setAllPoints        = true,
            cooldown            = Wow.FromUIProperty("Cooldown"),
            hideCountdownNumbers= false,
        },

        -- For non-frequently used
        SpellActivationAlert    = Wow.FromUIProperty("OverlayGlow"),
        EquippedItemTexture     = Wow.FromUIProperty("IsEquippedItem"):Map(function(val) return val and EquippedItemTextureSkin or nil end),
        FlashTexture            = Wow.FromUIProperty("IsAutoAttack"):Map(function(val) return val and FlashTextureSkin or nil end),
        FlyoutArrow             = Wow.FromUIProperty("IsFlyout"):Map(function(val) return val and FlyoutArrowSkin or nil end),
        FlyoutBorder            = Wow.FromUIProperty("IsFlyout"):Map(function(val) return val and FlyoutBorderSkin or nil end),
        FlyoutBorderShadow      = Wow.FromUIProperty("IsFlyout"):Map(function(val) return val and FlyoutBorderShadowSkin or nil end),
        AutoCastableTexture     = Wow.FromUIProperty("IsAutoCastable"):Map(function(val) return val and AutoCastableTextureSkin or nil end),
        AutoCastShine           = Wow.FromUIProperty("IsAutoCastable"):Map(function(val) return val and AutoCastShineSkin or nil end),
        SearchOverlay           = Wow.FromUIProperty("ShowSearchOverlay"):Map(function(val) return val and SearchOverlaySkin or nil end),
        ChargeCooldown          = Wow.FromUIProperty("IsChargable"):Map(function(val) return val and ChargeCooldownSkin or nil end),
    },

    [ContainerFrameItemButton]  = {
        alpha                   = 1,

        SearchOverlay           = {
            drawLayer           = "OVERLAY",
            subLevel            = 2,
            setAllPoints        = true,
            color               = Color(0, 0, 0, 0.8),
            visible             = Wow.FromUIProperty("ShowSearchOverlay"),
        },

        NormalTexture           = {
            file                = [[Interface\Buttons\UI-Quickslot2]],
            location            = { Anchor("TOPLEFT", -15, 15), Anchor("BOTTOMRIGHT", 15, -15) },
        },

        UpgradeIcon             = {
            drawLayer           = "OVERLAY",
            subLevel            = 1,
            atlas               = AtlasType("bags-greenarrow", true),
            location            = { Anchor("TOPLEFT" ) },
            visible             = Wow.FromUIProperty("IsUpgradeItem"):Map(function(val) return val and true or false end),
        },

        IconQuestTexture        = {
            drawLayer           = "OVERLAY",
            subLevel            = 2,
            setAllPoints        = true,
            file                = Wow.FromUIProperty("ItemQuestStatus"):Map(function(val) return val and TEXTURE_ITEM_QUEST_BORDER or TEXTURE_ITEM_QUEST_BANG end),
            visible             = Wow.FromUIProperty("ItemQuestStatus"):Map(function(val) return val ~= nil end),
        },

        JunkIcon                = {
            drawLayer           = "OVERLAY",
            subLevel            = 5,
            atlas               = AtlasType("bags-junkcoin", true),
            location            = { Anchor("TOPLEFT", 1, 0) },
            visible             = Wow.FromUIProperty("IsJunk"),
        },

        EquippedItemTexture     = {
            drawLayer           = "OVERLAY",
            location            = { Anchor("TOPLEFT", -2, 2), Anchor("BOTTOMRIGHT", 2, -2) },
            file                = Wow.FromUIProperty("IsArtifactRelicItem"):Map(function(val) return val and [[Interface\Artifacts\RelicIconFrame]] or [[Interface\Common\WhiteIconFrame]] end),
            vertexColor         = Wow.FromUIProperty("ItemQuality"):Map(function(val) return val and val >= LE_ITEM_QUALITY_COMMON and BAG_ITEM_QUALITY_COLORS[val] or Color.WHITE end),
            visible             = Wow.FromUIProperty("ItemQuality"):Map(function(val) return val and val >= LE_ITEM_QUALITY_COMMON and BAG_ITEM_QUALITY_COLORS[val] and true or false end),
        },

        BattlepayItemTexture    = {
            drawLayer           = "OVERLAY",
            subLevel            = 2,
            file                = [[Interface\Store\store-item-highlight]],
            location            = { Anchor("CENTER") },
            visible             = Wow.FromUIProperty("IsNewItem", "IsBattlePayItem"):Map(function(new, pay) return new and pay end),
        },

        NewItemTexture          = {
            drawLayer           = "OVERLAY",
            subLevel            = 2,
            atlas               = Wow.FromUIProperty("IsNewItem", "IsBattlePayItem", "ItemQuality"):Map(function(new, pay, quality) shareAtlas.atlas = quality and NEW_ITEM_ATLAS_BY_QUALITY[quality] or DEFAULT_ITEM_ATLAS return shareAtlas end),
            alpha               = 0,
            alphaMode           = "ADD",
            location            = { Anchor("CENTER") },
            visible             = Wow.FromUIProperty("IsNewItem", "IsBattlePayItem"):Map(function(new, pay) return new and not pay end),

            AnimationGroup      = {
                playing         = Wow.FromUIProperty("IsNewItem"),
                toFinalAlpha    = true,
                looping         = "REPEAT",

                Alpha1          = {
                    smoothing   = "NONE",
                    order       = 1,
                    duration    = 0.8,
                    fromAlpha   = 1,
                    toAlpha     = 0.4,
                },

                Alpha2          = {
                    smoothing   = "NONE",
                    order       = 2,
                    duration    = 0.8,
                    fromAlpha   = 0.4,
                    toAlpha     = 1,
                }
            },
        },

        GlowFlashTexture        = {
            drawLayer           = "OVERLAY",
            subLevel            = 2,
            atlas               = AtlasType("bags-glow-flash", true),
            alpha               = 0,
            alphaMode           = "ADD",
            location            = { Anchor("CENTER") },

            AnimationGroup      = {
                toFinalAlpha    = true,
                playing         = Wow.FromUIProperty("IsNewItem"),

                Alpha           = {
                    smoothing   = "OUT",
                    duration    = 0.6,
                    order       = 1,
                    fromAlpha   = 1,
                    toAlpha     = 0,
                },
            }
        },
    },
})

EquippedItemTextureSkin         = {
    file                        = [[Interface\Buttons\UI-ActionButton-Border]],
    drawLayer                   = "OVERLAY",
    alphaMode                   = "ADD",
    location                    = { Anchor("TOPLEFT", -8, 8), Anchor("BOTTOMRIGHT", 8, -8) },
    vertexColor                 = Color(0, 1.0, 0, 0.7),
}

FlashTextureSkin                = {
    drawLayer                   = "ARTWORK",
    subLevel                    = 1,
    file                        = [[Interface\Buttons\UI-QuickslotRed]],
    setAllPoints                = true,
    alpha                       = 0,

    AnimationGroup              = {
        playing                 = Wow.FromUIProperty("IsAutoAttacking"),
        looping                 = "REPEAT",

        Alpha1                  = {
            order               = 1,
            duration            = 0.01,
            fromAlpha           = 0,
            toAlpha             = 1,
        },
        Alpha2                  = {
            order               = 1,
            duration            = 0.01,
            startDelay          = 0.4,
            fromAlpha           = 1,
            toAlpha             = 0,
        },
        Alpha3                  = {
            order               = 1,
            duration            = 0.01,
            startDelay          = 0.8,
            fromAlpha           = 0,
            toAlpha             = 0,
        },
    }
}

FlyoutArrowSkin                 = {
    drawLayer                   = "ARTWORK",
    subLevel                    = 2,
    file                        = [[Interface\Buttons\ActionBarFlyoutButton]],
    texCoords                   = RectType(0.62500000, 0.98437500, 0.74218750, 0.82812500),
    size                        = Size(23, 11),
    location                    = Wow.FromUIProperty("FlyoutDirection"):Map(function(dir) return flyoutArrowLocation[dir or "TOP"] end),
    rotateDegree                = Wow.FromUIProperty("FlyoutDirection"):Next():Map(function(dir) return dir == "RIGHT" and 90 or dir == "DOWN" and 180 or dir == "LEFT" and 270 or 0  end),
}

FlyoutBorderSkin                = {
    drawLayer                   = "ARTWORK",
    subLevel                    = 1,
    file                        = [[Interface\Buttons\ActionBarFlyoutButton]],
    texCoords                   = RectType(0.01562500, 0.67187500, 0.39843750, 0.72656250),
    location                    = { Anchor("TOPLEFT", -3, 3), Anchor("BOTTOMRIGHT", 3, -3) },
    visible                     = Wow.FromUIProperty("Flyouting"),
}

FlyoutBorderShadowSkin          = {
    drawLayer                   = "ARTWORK",
    subLevel                    = 1,
    file                        = [[Interface\Buttons\ActionBarFlyoutButton]],
    texCoords                   = RectType(0.01562500, 0.76562500, 0.00781250, 0.38281250),
    location                    = { Anchor("TOPLEFT", -6, 6), Anchor("BOTTOMRIGHT", 6, -6) },
    visible                     = Wow.FromUIProperty("Flyouting"),
}

AutoCastableTextureSkin         = {
    drawLayer                   = "OVERLAY",
    file                        = [[Interface\Buttons\UI-AutoCastableOverlay]],
    location                    = { Anchor("TOPLEFT", -14, 14), Anchor("BOTTOMRIGHT", 14, -14) },
}

AutoCastShineSkin               = {
    location                    = { Anchor("TOPLEFT", 1, -1), Anchor("BOTTOMRIGHT", -1, 1) },
    isAutoCast                  = Wow.FromUIProperty("IsAutoCasting"),
}

SearchOverlaySkin               = {
    drawLayer                   = "OVERLAY",
    subLevel                    = 2,
    setAllPoints                = true,
    color                       = Color(0, 0, 0, 0.8),
}

ChargeCooldownSkin              = {
    setAllPoints                = true,
    cooldown                    = Wow.FromUIProperty("ChargeCooldown"),
}