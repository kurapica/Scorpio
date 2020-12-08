--========================================================--
--             Scorpio TabControl Widget                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/04/26                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.TabControl"        "1.0.0"
--========================================================--

-----------------------------------------------------------
--                    TabControl Widget                    --
-----------------------------------------------------------
__Sealed__() class "TabButton" (function(_ENV)
    inherit "Button"

    local Next                  = Scorpio.Next

    local function OnClick(self)
        if not self.Selected then
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            self.Selected       = true
        end
    end

    local function OnDisable(self)
        self:GetFontString():SetTextColor(0.5, 0.5, 0.5)

        if self.Selected then
            for _, child in self:GetParent():GetChilds() do
                if child ~= self and Class.IsObjectType(child, TabButton) and child:IsEnabled() then
                    child.Selected = true
                    break
                end
            end
        end
    end

    local function OnEnable(self)
        self:GetFontString():SetTextColor(1, 0.82, 0)
    end

    --- Whether the tab is selected
    property "Selected"         {
        type                    = Boolean,
        handler                 = function(self, flag)
            self:GetChild("LeftDisabled"):SetShown(flag)
            self:GetChild("MiddleDisabled"):SetShown(flag)
            self:GetChild("RightDisabled"):SetShown(flag)
            self:GetChild("Left"):SetShown(not flag)
            self:GetChild("Middle"):SetShown(not flag)
            self:GetChild("Right"):SetShown(not flag)
            self.Container:SetShown(flag)

            local text      = self:GetFontString()
            if flag then
                text:SetTextColor(1, 1, 1)
                text:ClearAllPoints()
                text:SetPoint("CENTER", 0, 0)
                self:GetHighlightTexture():Hide()
            else
                self:GetFontString():SetTextColor(1,0.82,0)
                text:ClearAllPoints()
                text:SetPoint("CENTER", 0, -3)
                self:GetHighlightTexture():Show()
            end

            if flag then
                for _, child in self:GetParent():GetChilds() do
                    if child ~= self and Class.IsObjectType(child, TabButton) then
                        child.Selected = false
                    end
                end
            end
        end,
    }

    --- The Container of the tab page
    property "Container"        { type = Frame }

    --- Override the SetText method
    function SetText(self, text)
        Button.SetText(self, text)

        Next(function()
            local text          = self:GetFontString()
            local width         = text and text:GetStringWidth() or 0

            self:SetWidth(width + 36)
        end)
    end

    __Template__{
        LeftDisabled            = Texture,
        MiddleDisabled          = Texture,
        RightDisabled           = Texture,
        Left                    = Texture,
        Middle                  = Texture,
        Right                   = Texture,
    }
    function __ctor(self)
        self:SetWidth(115)
        self:InstantApplyStyle()

        self:SetFrameLevel(self:GetFrameLevel() + 4)

        self.OnClick            = self.OnClick + OnClick
        self.OnEnable           = self.OnEnable + OnEnable
        self.OnDisable          = self.OnDisable + OnDisable
    end
end)

__Sealed__()
class "TabControl" (function(_ENV)
    inherit "Frame"

    local function refreshHeaderScroll(self)
        local header            = self:GetChild("Header")
        local container         = header:GetChild("Container")

        if container:GetWidth() < self:GetWidth() then
            if self:GetChild("LeftScroll"):IsShown() then
                self:GetChild("LeftScroll"):Hide()
                self:GetChild("RightScroll"):Hide()

                header:ClearAllPoints()
                header:SetPoint("TOPLEFT")
                header:SetPoint("RIGHT")

                container:ClearAllPoints()
                container:SetPoint("TOPLEFT")
                container:SetPoint("BOTTOM")
            end
        else
            if not self:GetChild("LeftScroll"):IsShown() then
                self:GetChild("LeftScroll"):Show()
                self:GetChild("RightScroll"):Show()

                header:ClearAllPoints()
                header:SetPoint("TOPLEFT")
                header:SetPoint("RIGHT", self:GetChild("LeftScroll"), "LEFT")

                container:ClearAllPoints()
                container:SetPoint("TOPLEFT")
                container:SetPoint("BOTTOM")
            end

            local offset        = container.HorizontalOffset or 0

            if offset > (container:GetWidth() - header:GetWidth()) then
                container.HorizontalOffset = container:GetWidth() - header:GetWidth()
                container:ClearAllPoints()
                container:SetPoint("TOPLEFT", -container.HorizontalOffset, 0)
                container:SetPoint("BOTTOM")
            end
        end
    end

    local function HeaderContainer_Resize(self)
        local width             = 0
        local index             = 0

        repeat
            index               = index + 1
            local child         = self:GetChild("TabButton" .. index)
            if child then width = width + child:GetWidth() end
        until not child

        self:SetWidth(width)

        return refreshHeaderScroll(self:GetParent():GetParent())
    end

    local function LeftScroll_OnClick(self)
        self                    = self:GetParent()
        local header            = self:GetChild("Header")
        local container         = header:GetChild("Container")
        local offset            = container.HorizontalOffset or 0

        offset                  = offset - header:GetWidth() / 2
        if offset < 0 then offset = 0 end

        container.HorizontalOffset = offset
        container:ClearAllPoints()
        container:SetPoint("TOPLEFT", -offset, 0)
        container:SetPoint("BOTTOM")
    end

    local function RightScroll_OnClick(self)
        self                    = self:GetParent()
        local header            = self:GetChild("Header")
        local container         = header:GetChild("Container")
        local offset            = container.HorizontalOffset or 0
        local maxoff            = container:GetWidth() - header:GetWidth()

        offset                  = offset + header:GetWidth() / 2
        if offset > maxoff then offset = maxoff end

        container.HorizontalOffset = offset
        container:ClearAllPoints()
        container:SetPoint("TOPLEFT", -offset, 0)
        container:SetPoint("BOTTOM")
    end

    local function TabButton_OnSizeChanged(self)
        return HeaderContainer_Resize(self:GetParent())
    end

    local function OnSizeChanged(self)
        return refreshHeaderScroll(self)
    end

    --- Add a tab page and return the tab button
    __Arguments__{ NEString, UI/nil }
    function AddTabPage(self, name, frame)
        local header            = self:GetChild("Header"):GetChild("Container")
        local index             = 0

        repeat
            index               = index + 1
            local child         = header:GetChild("TabButton" .. index)
            if child and child:GetText() == name then return child end
        until not child

        local tabButton         = TabButton("TabButton" .. index, header)
        tabButton.OnSizeChanged = tabButton.OnSizeChanged + TabButton_OnSizeChanged

        tabButton:ClearAllPoints()

        if index == 1 then
            tabButton:SetPoint("BOTTOMLEFT")
        else
            local prev          = header:GetChild("TabButton" .. (index - 1))
            tabButton:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT")
        end

        tabButton:SetText(name)
        local container         = Frame("TabPageContainer" .. index, self:GetChild("Body"))
        container:SetPoint("TOPLEFT")
        container:SetPoint("BOTTOMRIGHT")
        tabButton.Container     = container

        if index == 1 then
            tabButton.Selected  = true
        else
            tabButton.Selected  = false
        end

        return tabButton
    end

    --- Get the tab button by name
    function GetTabPage(self, name)
        local header            = self:GetChild("Header"):GetChild("Container")
        local index             = 0

        repeat
            index               = index + 1
            local child         = header:GetChild("TabButton" .. index)
            if child and child:GetText() == name then return child end
        until not child
    end

    __Template__{
        Header                  = ScrollFrame,
        Body                    = Frame,
        LeftScroll              = Button,
        RightScroll             = Button,

        -- Child Tree
        {
            Header              = {
                Container       = Frame,
            }
        }
    }
    function __ctor(self)
        local header            = self:GetChild("Header")
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT")
        header:SetPoint("RIGHT")
        header:SetHeight(32)

        local container         = header:GetChild("Container")
        header:SetScrollChild(container)
        container:ClearAllPoints()
        container:SetPoint("TOPLEFT")
        container:SetPoint("BOTTOM")
        container:SetWidth(1)

        local leftScroll        = self:GetChild("LeftScroll")
        local rightScroll       = self:GetChild("RightScroll")

        leftScroll:Hide()
        rightScroll:Hide()

        self.OnSizeChanged      = self.OnSizeChanged + OnSizeChanged
        leftScroll.OnClick      = leftScroll.OnClick + LeftScroll_OnClick
        rightScroll.OnClick     = rightScroll.OnClick + RightScroll_OnClick
    end
end)

-----------------------------------------------------------
--                   TabControl Style                    --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [TabButton]                 = {
        height                  = 24,

        LeftDisabled            = {
            drawLayer           = "BORDER",
            file                = [[Interface\OptionsFrame\UI-OptionsFrame-ActiveTab]],
            size                = Size(20, 24),
            location            = { Anchor("BOTTOMLEFT", 0, -3) },
            texCoords           = RectType(0, 0.15625, 0, 1.0),
        },
        MiddleDisabled          = {
            drawLayer           = "BORDER",
            file                = [[Interface\OptionsFrame\UI-OptionsFrame-ActiveTab]],
            location            = { Anchor("TOPLEFT", 0, 0, "LeftDisabled", "TOPRIGHT"), Anchor("BOTTOMRIGHT", 0, 0, "RightDisabled", "BOTTOMLEFT") },
            texCoords           = RectType(0.15625, 0.84375, 0, 1.0),
        },
        RightDisabled           = {
            drawLayer           = "BORDER",
            file                = [[Interface\OptionsFrame\UI-OptionsFrame-ActiveTab]],
            size                = Size(20, 24),
            location            = { Anchor("BOTTOMRIGHT", 0, -3) },
            texCoords           = RectType(0.84375, 1.0, 0, 1.0),
        },
        Left                    = {
            drawLayer           = "BORDER",
            file                = [[Interface\OptionsFrame\UI-OptionsFrame-InActiveTab]],
            size                = Size(20, 24),
            location            = { Anchor("TOPLEFT") },
            texCoords           = RectType(0, 0.15625, 0, 1.0),
        },
        Middle                  = {
            drawLayer           = "BORDER",
            file                = [[Interface\OptionsFrame\UI-OptionsFrame-InActiveTab]],
            location            = { Anchor("TOPLEFT", 0, 0, "Left", "TOPRIGHT"), Anchor("BOTTOMRIGHT", 0, 0, "Right", "BOTTOMLEFT") },
            texCoords           = RectType(0.15625, 0.84375, 0, 1.0),
        },
        Right                   = {
            drawLayer           = "BORDER",
            file                = [[Interface\OptionsFrame\UI-OptionsFrame-InActiveTab]],
            size                = Size(20, 24),
            location            = { Anchor("TOPRIGHT") },
            texCoords           = RectType(0.84375, 1.0, 0, 1.0),
        },
        ButtonText              = {
            fontObject          = GlueFontNormalSmall,
        },

        HighlightTexture        = {
            file                = [[Interface\PaperDollInfoFrame\UI-Character-Tab-Highlight]],
            location            = { Anchor("TOPLEFT", 10, -4), Anchor("BOTTOMRIGHT", -10, 4) },
            alphamode           = "ADD",
        },

        normalFont              = GlueFontNormalSmall,
        disabledFont            = GameFontDisableSmall,
        highlightFont           = GlueFontHighlightSmall,
    },
    [TabControl]                = {
        RightScroll             = {
            location            = { Anchor("TOPRIGHT") },
            size                = Size(32, 32),

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]],
                setAllPoints    = true,
            },
            PushedTexture       = {
                file            = [[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]],
                setAllPoints    = true,
            },
            DisabledTexture     = {
                file            = [[Interface\Buttons\UI-SpellbookIcon-NextPage-Disabled]],
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-Common-MouseHilight]],
                setAllPoints    = true,
                alphamode       = "ADD",
            },
        },
        LeftScroll              = {
            location            = { Anchor("RIGHT", 0, 0, "RightScroll", "LEFT") },
            size                = Size(32, 32),

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]],
                setAllPoints    = true,
            },
            PushedTexture       = {
                file            = [[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]],
                setAllPoints    = true,
            },
            DisabledTexture     = {
                file            = [[Interface\Buttons\UI-SpellbookIcon-PrevPage-Disabled]],
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-Common-MouseHilight]],
                setAllPoints    = true,
                alphamode       = "ADD",
            },
        },
        Header                  = {
            height              = 24,
        },
        Body                    = {
            location            = { Anchor("TOPLEFT", 0, 0, "Header", "BOTTOMLEFT"), Anchor("BOTTOMRIGHT") },
            backdrop            = {
                edgeFile        = [[Interface\Tooltips\UI-Tooltip-Border]],
                tile            = true, tileSize = 16, edgeSize = 16,
                insets          = { left = 5, right = 5, top = 5, bottom = 5 }
            },
            backdropBorderColor = Color(0.6, 0.6, 0.6),
        }
    },
})