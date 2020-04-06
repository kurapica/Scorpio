--========================================================--
--             Scorpio ComboBox Widget                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/03/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.ComboBox"          "1.0.0"
--========================================================--

-----------------------------------------------------------
--                    ComboBox Widget                    --
-----------------------------------------------------------
__Sealed__()
class "ComboBox" (function(_ENV)
    inherit "Frame"

    local DropDownListOwner
    local DropDownListConfig

    DropDownListConfig          = {
        dropdown                = true,
        anchor                  = "ANCHOR_BOTTOMRIGHT",
        check                   = {
            get                 = function()
                return DropDownListOwner and DropDownListOwner.SelectedValue
            end,
            set                 = function(value)
                if DropDownListOwner then
                    DropDownListOwner.SelectedValue = value
                    OnSelectedChange(DropDownListOwner, value)
                end
            end,
        },
        close                   = function()
            DropDownListOwner   = nil

            for i = #DropDownListConfig, 1, -1 do
                DropDownListConfig[i] = nil
            end
        end,
    }

    local function Toggle_OnClick(self)
        local owner             = self:GetParent()

        if DropDownListOwner == owner then
            return Scorpio.CloseDropDownMenu()
        end

        if DropDownListOwner then
            Scorpio.CloseDropDownMenu()

            -- Wait the preivous drop down closed
            Next(function()
                while DropDownListOwner do Next() end

                DropDownListOwner       = owner
                DropDownListConfig.owner= self

                local items             = owner.__ComboBox_Items
                if items then
                    for i = 1, #items do
                        DropDownListConfig[i] = items[i]
                    end
                end

                Scorpio.ShowDropDownMenu(DropDownListConfig)
            end)
        else
            DropDownListOwner           = owner
            DropDownListConfig.owner    = self

            local items                 = owner.__ComboBox_Items
            if items then
                for i = 1, #items do
                    DropDownListConfig[i] = items[i]
                end
            end

            Scorpio.ShowDropDownMenu(DropDownListConfig)
        end
    end

    --- Fired when the selected value changed
    event "OnSelectedChange"

    --- The icon texture file or id
    property "Icon"             {
        type                    = String + Number,
        set                     = function(self, val)
            self:GetChild("DisplayIcon"):SetTexture(val)
            self:GetChild("DisplayIcon"):SetShown(val and true or false)
        end,
        get                     = function(self)
            return self:GetChild("DisplayIcon"):GetTexture()
        end,
    }

    --- The text to be displayed
    property "Text"             {
        type                    = String,
        set                     = function(self, val) self:GetChild("DisplayText"):SetText(val) end,
        get                     = function(self) return self:GetChild("DisplayText"):GetText() end,
    }

    --- The selected value of the combobox
    property "SelectedValue"    { type = Any }

    --- The items to be selected
    __Indexer__()
    property "Items"            {
        type                    = String,
        set                     = function(self, value, text)
            local items         = self.__ComboBox_Items or {}

            tinsert(items, {
                text            = text,
                checkvalue      = value,
            })

            self.__ComboBox_Items = items
        end,
    }

    --- The methods used to clear all items
    function ClearItems(self)
        if self.__ComboBox_Items then wipe(self.__ComboBox_Items) end
    end

    __Template__{
        LeftBG                  = Texture,
        MiddleBG                = Texture,
        RightBG                 = Texture,
        DisplayText             = FontString,
        DisplayIcon             = Texture,
        Toggle                  = Button,
    }
    function __ctor(self)
        self:GetChild("DisplayIcon"):Hide()

        local button            = self:GetChild("Toggle")
        DropDownToggleButtonMixin.OnLoad_Intrinsic(button)
        button.HandlesGlobalMouseEvent = DropDownToggleButtonMixin.HandlesGlobalMouseEvent

        button.OnClick          = button.OnClick + Toggle_OnClick
    end
end)

-----------------------------------------------------------
--                     ComboBox Style                      --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [ComboBox]                  = {
        size                    = Size(165, 32),

        LeftBG                  = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]],
            width               = 25,
            location            = { Anchor("TOPLEFT", 0, 16), Anchor("BOTTOMLEFT", 0, -16) },
            texCoords           = RectType(0, 0.1953125, 0, 1),
        },

        RightBG                 = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]],
            width               = 25,
            location            = { Anchor("TOPRIGHT", 0, 16), Anchor("BOTTOMRIGHT", 0, -16) },
            texCoords           = RectType(0.8046875, 1, 0, 1),
        },

        MiddleBG                = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]],
            location            = { Anchor("TOPLEFT", 0, 0, "LeftBG", "TOPRIGHT"), Anchor("BOTTOMRIGHT", 0, 0, "RightBG", "BOTTOMLEFT") },
            texCoords           = RectType(0.1953125, 0.8046875, 0, 1),
        },

        DisplayText             = {
            drawLayer           = "ARTWORK",
            fontObject          = GameFontHighlightSmall,
            wordwrap            = false,
            justifyH            = "RIGHT",
            location            = { Anchor("RIGHT", -43, 2) },
        },

        DisplayIcon             = {
            drawLayer           = "OVERLAY",
            size                = Size(16, 16),
            location            = { Anchor("LEFT", 30, 2) },
        },

        Toggle                  = {
            location            = { Anchor("RIGHT", -16, 0) },
            size                = Size(24, 24),

            NormalTexture       = {
                file            = [[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Up]],
            },
            PushedTexture       = {
                file            = [[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Down]],
            },
            DisabledTexture     = {
                file            = [[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Disabled]],
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-Common-MouseHilight]],
                alphamode       = "ADD",
            },
        },
    },
})