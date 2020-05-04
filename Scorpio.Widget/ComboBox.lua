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

    USE_LIST_LIMIT_COUNT        = 5

    local DropDownListOwner
    local DropDownListConfig

    local ShareListFrameOwner
    local ShareListFrame        = ListFrame("Scorpio_ComboBox_ShareListFrame")
    ShareListFrame:SetFrameStrata("TOOLTIP")
    ShareListFrame:Hide()

    __Async__()
    function ShareListFrame:OnShow()
        local count             = 120

        while self:IsShown() do
            if self:IsMouseOver() then
                count           = 120
            else
                count           = count - 1

                if count < 1 then
                    return self:Hide()
                end
            end

            Next()
        end
    end

    function ShareListFrame:OnHide()
        ShareListFrameOwner     = nil
    end

    function ShareListFrame:OnItemClick(value)
        if ShareListFrameOwner then
            ShareListFrameOwner.SelectedValue = value
            OnSelectedChange(ShareListFrameOwner, value)
        end

        self:Hide()
    end

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

    local function openDropDownList(self)
        local owner             = self:GetParent()
        while DropDownListOwner or ShareListFrameOwner do Next() end

        local items             = owner.__ComboBox_Items

        if #items > USE_LIST_LIMIT_COUNT then
            ShareListFrameOwner = owner
            ShareListFrame:ClearAllPoints()
            ShareListFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
            ShareListFrame:SetPoint("LEFT", owner, "LEFT")

            ShareListFrame.RawItems = items
            ShareListFrame:Show()
        else
            DropDownListOwner   = owner
            DropDownListConfig.owner = self

            if items then
                for i = 1, #items do
                    DropDownListConfig[i] = items[i]
                end
            end

            Scorpio.ShowDropDownMenu(DropDownListConfig)
        end
    end

    local function Toggle_OnClick(self)
        local owner             = self:GetParent()

        if DropDownListOwner then
            if DropDownListOwner == owner then
                return Scorpio.CloseDropDownMenu()
            end

            Scorpio.CloseDropDownMenu()
        elseif ShareListFrameOwner then
            if ShareListFrameOwner == owner then
                return ShareListFrame:Hide()
            end

            ShareListFrame:Hide()
        end

        Next(openDropDownList, self)
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
    property "SelectedValue"    { type = Any,
        handler                 = function(self, value)
            local items         = self.__ComboBox_Items or {}
            local itemidx

            for i, item in ipairs(items) do
                if item.checkvalue == value then
                    self.Text   = item.text
                    break
                end
            end
        end
    }

    --- The items to be selected
    __Indexer__()
    property "Items"            {
        type                    = String + ListFrame.ListItem,
        set                     = function(self, value, text)
            local items         = self.__ComboBox_Items or {}
            local itemidx

            for i, item in ipairs(items) do
                if item.checkvalue == value then
                    itemidx     = i
                    break
                end
            end

            if text == nil then
                if itemidx then tremove(items, itemidx) end
            elseif type(text) == "string" then
                if itemidx then
                    local item      = items[itemidx]

                    item.checkvalue = value
                    item.text       = text
                    item.icon       = nil
                    item.tiptitle   = nil
                    item.tiptext    = nil
                else
                    tinsert(items, {
                        -- So we share the same struct for dropdown menu item and combobox
                        -- Just for simple
                        checkvalue  = value,
                        text        = text,
                    })
                end
            else
                if itemidx then
                    local item      = items[itemidx]

                    item.checkvalue = value
                    item.text       = text.text
                    item.icon       = text.icon
                    item.tiptitle   = text.tiptitle
                    item.tiptext    = text.tiptext
                else
                    tinsert(items, {
                        checkvalue  = value,
                        text        = text.text,
                        icon        = text.icon,
                        tiptitle    = text.tiptitle,
                        tiptext     = text.tiptext,
                    })
                end
            end

            self.__ComboBox_Items   = items
        end,
    }

    --- The methods used to clear all items
    function ClearItems(self)
        if self.__ComboBox_Items then wipe(self.__ComboBox_Items) end
    end

    __Template__{
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
        height                  = 32,

        LeftBGTexture           = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]],
            width               = 25,
            location            = { Anchor("TOPLEFT", 0, 16), Anchor("BOTTOMLEFT", 0, -16) },
            texCoords           = RectType(0, 0.1953125, 0, 1),
        },

        RightBGTexture          = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]],
            width               = 25,
            location            = { Anchor("TOPRIGHT", 0, 16), Anchor("BOTTOMRIGHT", 0, -16) },
            texCoords           = RectType(0.8046875, 1, 0, 1),
        },

        MiddleBGTexture         = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]],
            location            = { Anchor("TOPLEFT", 0, 0, "LeftBGTexture", "TOPRIGHT"), Anchor("BOTTOMRIGHT", 0, 0, "RightBGTexture", "BOTTOMLEFT") },
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
                setAllPoints    = true,
            },
            PushedTexture       = {
                file            = [[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Down]],
                setAllPoints    = true,
            },
            DisabledTexture     = {
                file            = [[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Disabled]],
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-Common-MouseHilight]],
                setAllPoints    = true,
                alphamode       = "ADD",
            },
        },
    },
})