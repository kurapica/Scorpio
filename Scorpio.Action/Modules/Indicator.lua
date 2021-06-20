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
__Sealed__() __ChildProperty__(SecureActionButton, "SpellActivationAlert")
class "SpellActivationAlert" (function(_ENV)
    inherit "Frame"

    __Sealed__() enum "AinmationState" { "STOP", "IN", "OUT" }

    __Bubbling__{ ["OuterGlowOver.Out"] = "OnFinished" }
    event "OnFinished"

    local function OnHide(self)
        self.AinmationState     = "STOP"
    end

    local function ChangeAntsSize(self)
        local w, h              = self:GetSize()
        self:GetChild("Ants"):SetSize(w * 0.85, h * 0.85)
    end

    ------------------------------------------------------
    --               Observable Property                --
    ------------------------------------------------------
    --- The animation state
    __Observable__()
    property "AinmationState"   { type = AinmationState, default = "STOP", handler = function(self, val) return val == "IN" and Next(ChangeAntsSize, self) end }

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
        self.OnHide             = self.OnHide + OnHide
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
UI.Property                     = {
    name                        = "AutoCastableTexture",
    require                     = SecureActionButton,
    childtype                   = Texture,
}

------------------------------------------------------------
--                     Default Style                      --
------------------------------------------------------------
local antAnimate                = AnimateTexCoords(256, 256, 48, 48, 22, 0.01)
local usableColor               = Color.WHITE
local unUsableColor             = Color(0.4, 0.4, 0.4)
local RANGE_INDICATOR           = "●"
local isInState                 = function(s) return s == "IN" end
local isOutState                = function(s) return s == "OUT" end
local isPlaying                 = function(s) return s ~= "STOP" and antAnimate or nil end
local flyoutArrowLocation       = {
    TOP                         = { Anchor("BOTTOM", 0, 0, "TOP") },
    BOTTOM                      = { Anchor("TOP", 0, 0, "BOTTOM") },
    LEFT                        = { Anchor("RIGHT", 0, 0, "LEFT") },
    RIGHT                       = { Anchor("LEFT", 0, 0, "RIGHT") },
}

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
                playing         = Wow.FromUIProperty("AinmationState"):Map(isInState),

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
                playing         = Wow.FromUIProperty("AinmationState"):Map(isInState),

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
                playing         = Wow.FromUIProperty("AinmationState"):Map(isInState),

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
                playing         = Wow.FromUIProperty("AinmationState"):Map(isInState),

                Scale           = {
                    order       = 1,
                    duration    = 0.3,
                    fromScale   = Dimension(2, 2),
                    toScale     = Dimension(1, 1),
                },
            },

            Out                 = {
                playing         = Wow.FromUIProperty("AinmationState"):Map(isOutState),

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
                playing         = Wow.FromUIProperty("AinmationState"):Map(isInState),

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
                playing         = Wow.FromUIProperty("AinmationState"):Map(isOutState),

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
            animateTexCoords    = Wow.FromUIProperty("AinmationState"):Map(isPlaying),
            alpha               = 1,

            In                  = {
                playing         = Wow.FromUIProperty("AinmationState"):Map(isInState),

                Alpha           = {
                    order       = 1,
                    duration    = 0.2,
                    startDelay  = 0.2,
                    fromAlpha   = 0,
                    toAlpha     = 1,
                }
            },

            Out                 = {
                playing         = Wow.FromUIProperty("AinmationState"):Map(isOutState),

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
        EquippedItemTexture     = {
            file                = [[Interface\Buttons\UI-ActionButton-Border]],
            drawLayer           = "OVERLAY",
            alphaMode           = "ADD",
            location            = { Anchor("TOPLEFT", -8, 8), Anchor("BOTTOMRIGHT", 8, -8) },
            visible             = Wow.FromUIProperty("IsEquippedItem"),
            vertexColor         = Color(0, 1.0, 0, 0.7),
        },
        HotKeyLabel             = {
            drawLayer           = "ARTWORK",
            subLevel            = 2,
            fontObject          = NumberFontNormal,
            justifyH            = "RIGHT",
            height              = 10,
            location            = { Anchor("TOPLEFT", 1, -3), Anchor("TOPRIGHT", -1, -3) },
            text                = Wow.FromUIProperty("HotKey"):Map(function(val) return val or RANGE_INDICATOR end),
        },

        -- For non-frequently used
        FlashTexture            = Wow.FromUIProperty("CanFlashing"):Map(function(val) return val and FlashTextureSkin or nil end),
        FlyoutArrow             = Wow.FromUIProperty("IsFlyout"):Map(function(val) return val and FlyoutArrowSkin or nil end),
        FlyoutBorder            = Wow.FromUIProperty("IsFlyout"):Map(function(val) return val and FlyoutBorderSkin or nil end),
        FlyoutBorderShadow      = Wow.FromUIProperty("IsFlyout"):Map(function(val) return val and FlyoutBorderShadowSkin or nil end),
        AutoCastableTexture     = Wow.FromUIProperty("IsAutoCastable"):Map(function(val) return val and AutoCastableTextureSkin or nil end),
        AutoCastShine           = Wow.FromUIProperty("IsAutoCasting"):Map(function(val) return val and AutoCastShineSkin or nil end),
    },
})

FlashTextureSkin                = {
    drawLayer                   = "ARTWORK",
    subLevel                    = 1,
    file                        = [[Interface\Buttons\UI-QuickslotRed]],
    setAllPoints                = true,
    visible                     = Wow.FromUIProperty("Flashing"), -- @todo
}

FlyoutArrowSkin                 = {
    drawLayer                   = "ARTWORK",
    subLevel                    = 2,
    file                        = [[Interface\Buttons\ActionBarFlyoutButton]],
    texCoords                   = RectType(0.62500000, 0.98437500, 0.74218750, 0.82812500),
    size                        = Size(23, 11),
    visible                     = Wow.FromUIProperty("IsFlyout"),
    location                    = Wow.FromUIProperty("FlyoutDirection"):Map(function(dir) return flyoutArrowLocation[dir or "TOP"] end),
    rotateDegree                = Wow.FromUIProperty("FlyoutDirection"):Map(function(dir) return dir == "RIGHT" and 90 or dir == "BOTTOM" and 180 or dir == "LEFT" and 270 or 0  end),
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
    visible                     = Wow.FromUIProperty("IsAutoCastable"),
}

AutoCastShineSkin               = {
    location                    = { Anchor("TOPLEFT", 1, -1), Anchor("BOTTOMRIGHT", -1, 1) },
}