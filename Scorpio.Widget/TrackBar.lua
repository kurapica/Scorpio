--========================================================--
--             Scorpio TrackBar Widget                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/04/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.TrackBar"          "1.0.0"
--========================================================--

-----------------------------------------------------------
--                 UIPanelButton Widget                  --
-----------------------------------------------------------
__Sealed__() class "TrackBar" (function(_ENV)
    inherit "Slider"

    local floor                 = math.floor
    local getValue              = Slider.GetValue
    local setValue              = Slider.SetValue
    local setValueStep          = Slider.SetValueStep
    local getValueStep          = Slider.GetValueStep

    local function OnValueChanged(self)
        self:GetChild("Text"):SetText(self:GetValue() or "")
    end

    function SetValue(self, value)
        setValue(self, value)
        OnValueChanged(self)
    end

    function GetValue(self)
        local value             = getValue(self)
        local step              = self:GetValueStep()

        if value and step then
            local count         = tostring(step):match("%.%d+")
            count               = count and 10 ^ (#count - 1) or 1
            return floor(count * value) / count
        end

        return value
    end

    function SetValueStep(self, step)
        self.__RealValueStep    = step
        setValueStep(self, step)
    end

    function GetValueStep(self)
        return self.__RealValueStep or getValueStep(self)
    end

    __Template__{
        Text                    = FontString,
        MinText                 = FontString,
        MaxText                 = FontString,
    }
    function __ctor(self)
        self.OnValueChanged     = self.OnValueChanged + OnValueChanged
    end
end)

-----------------------------------------------------------
--             UIPanelButton Style - Default             --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [TrackBar]                  = {
        orientation             = "HORIZONTAL",
        enableMouse             = true,
        hitRectInsets           = Inset(0, 0, -10, -10),
        backdrop                = {
            bgFile              = [[Interface\Buttons\UI-SliderBar-Background]],
            edgeFile            = [[Interface\Buttons\UI-SliderBar-Border]],
            tile                = true, tileSize = 8, edgeSize = 8,
            insets              = { left = 3, right = 3, top = 6, bottom = 6 }
        },

        ThumbTexture            = {
            file                = [[Interface\Buttons\UI-SliderBar-Button-Horizontal]],
            size                = Size(32, 32),
        },

        Text                    = {
            fontObject          = GameFontNormalSmall,
            location            = { Anchor("TOP", 0, 0, nil, "BOTTOM") },
        },

        MinText                 = {
            fontObject          = GameFontNormalHuge,
            location            = { Anchor("TOPLEFT", 0, 0, nil, "BOTTOMLEFT") },
            text                = "-",
        },

        MaxText                 = {
            fontObject          = GameFontNormalHuge,
            location            = { Anchor("TOPRIGHT", 0, 0, nil, "BOTTOMRIGHT") },
            text                = "+",
        }
    },
})