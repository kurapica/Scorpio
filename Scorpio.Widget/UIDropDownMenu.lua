--========================================================--
--             Scorpio UIDropDownMenu Widget              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/03/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.UIDropDownMenu"    "1.0.0"
--========================================================--

local DELAY_TO_HIDE             = 2

local _UIDropDownListLevel      = {}
local _UIDropDownMenuButton     = {}
local _UIDropDownCountDown      = {}

local function autoHideMenuList()
    while #_UIDropDownListLevel > 0 do
        local mouseover         = #_UIDropDownListLevel

        while mouseover > 0 and not (_UIDropDownListLevel[mouseover]:IsMouseOver() or mouseover > 1 and _UIDropDownMenuButton[mouseover]:IsMouseOver())  do
            mouseover           = mouseover - 1
        end

        local now               = GetTime()

        -- Refreshing the hide delay
        for i = 1, mouseover do
            _UIDropDownCountDown[i] = now + DELAY_TO_HIDE
        end

        for i = mouseover + 1, #_UIDropDownListLevel do
            if _UIDropDownCountDown[i] then
                if _UIDropDownCountDown[i] <= now then
                    for j = #_UIDropDownListLevel, i, -1 do
                        _UIDropDownListLevel[j]:Hide()
                        _UIDropDownListLevel[j] = nil
                        _UIDropDownMenuButton[j]= nil
                        _UIDropDownCountDown[j] = nil
                    end
                    break
                end
            else
                _UIDropDownCountDown[i] = _UIDropDownCountDown[i - 1] or (now + DELAY_TO_HIDE)
            end
        end

        Next()
    end
end

local function adjustLocation(self, owner)
    local x, y
    if owner then
        x, y                    = owner:GetTop() * owner:GetEffectiveScale(), owner:GetRight() * owner:GetEffectiveScale()
    else
        x, y                    = GetCursorPosition()
    end

    local scale                 = UIParent:GetScale()

    local width                 = self:GetWidth() * owner:GetEffectiveScale()
    local height                = self:GetHeight() * owner:GetEffectiveScale()

    self:ClearAllPoints()

    if x + width >= GetScreenWidth() then
        if owner then
            self:SetPoint("RIGHT", owner, "LEFT")
        else
            self:SetPoint("LEFT", UIParent, (x - width) / scale, 0)
        end
    else
        if owner then
            self:SetPoint("LEFT", owner, "RIGHT")
        else
            self:SetPoint("LEFT", UIParent, x / scale, 0)
        end
    end

    if y > height then
        if owner then
            self:SetPoint("TOP", owner, "TOP")
        else
            self:SetPoint("TOP", UIParent, 0, y / scale)
        end
    else
        self:SetPoint("BOTTOM", UIParent)
    end
end

local function showMenuList(self)
    if #_UIDropDownListLevel == 0 then
        -- Start the scan, don't use OnEnter/OnLeave since it's too hard to keeping tracking
        Next(autoHideMenuList)
    end

    -- Reset the count down
    wipe(_UIDropDownCountDown)
    if _UIDropDownListLevel[1] == self then return end

    for i = #_UIDropDownListLevel, 1, -1 do
        _UIDropDownListLevel[i]:Hide()
        _UIDropDownListLevel[i] = nil
        _UIDropDownMenuButton[i]= nil
    end

    _UIDropDownListLevel[1]     = self

    for _, child in UIObject.GetChilds(self) do
        child.MenuLevel         = 1
    end

    adjustLocation(self, self.Owner)
    self:Show()
end

local function showSubList(self)
    local level                 = self.MenuLevel
    local submenu               = self.SubMenu
    if not (level and submenu and self:IsShown()) then return end
    if _UIDropDownListLevel[level] == submenu then return end

    for i = #_UIDropDownListLevel, level, -1 do
        _UIDropDownListLevel[i]:Hide()
        _UIDropDownListLevel[i] = nil
        _UIDropDownCountDown[i] = nil
        _UIDropDownMenuButton[i]= nil
    end

    _UIDropDownListLevel[level] = submenu
    _UIDropDownMenuButton[level]= self

    for _, child in UIObject.GetChilds(submenu) do
        child.MenuLevel         = level + 1
    end

    adjustLocation(submenu, self)
    submenu:SetFrameLevel(self:GetFrameLevel() + 2)
    submenu:Show()
end

local function closeMenuList(self)
    if not self or _UIDropDownListLevel[1] == self then
        for i = #_UIDropDownListLevel, 1, -1 do
            _UIDropDownListLevel[i]:Hide()
            _UIDropDownListLevel[i] = nil
            _UIDropDownCountDown[i] = nil
            _UIDropDownMenuButton[i]= nil
        end
    end
end

local function closeSubList(self)
    local level                 = self.MenuLevel
    local submenu               = self.SubMenu
    if not (level and submenu and _UIDropDownListLevel[level] == submenu) then return end

    for i = #_UIDropDownListLevel, level, -1 do
        _UIDropDownListLevel[i]:Hide()
        _UIDropDownListLevel[i] = nil
        _UIDropDownCountDown[i] = nil
        _UIDropDownMenuButton[i]= nil
    end
end

--- Secure hook the gobal mouse event to auto close the drop down list
__SecureHook__()
function UIDropDownMenu_HandleGlobalMouseEvent(button, event)
    if event == "GLOBAL_MOUSE_DOWN" and (button == "LeftButton" or button == "RightButton") then
        return closeMenuList()
    end
end

-----------------------------------------------------------
--                 UIDropDownMenu Widget                 --
-----------------------------------------------------------
--- The UI drop menu list template
class "UIDropDownList" { }

--- The UI drop down menu button template
__Sealed__()
class "UIDropDownMenuButton" (function(_ENV)
    inherit "Button"

    export { IsObjectType = Class.IsObjectType, GetChilds = UIObject.GetChilds }

    local function refreshCheckState(self)
        if self.IsCheckButton and self.Checked then
            self:GetChild("Check"):Show()
        else
            self:GetChild("Check"):Hide()
        end

        if self.IsCheckButton and not self.Checked then
            self:GetChild("UnCheck"):Show()
        else
            self:GetChild("UnCheck"):Hide()
        end
    end

    local function refreshIcon(self)
        local icon              = self:GetChild("Icon")

        if self.MouseOverIcon and self:IsMouseOver() then
            icon:SetTexture(self.MouseOverIcon)
            icon:Show()
        elseif self.Icon then
            icon:SetTexture(self.Icon)
            icon:Show()
        else
            icon:Hide()
        end
    end

    -- The event handlers
    local function OnEnter(self)
        local color             = Color.NORMAL
        self:GetChild("ColorSwatch"):SetVertexColor(color.r, color.g, color.b)
        self:GetChild("Highlight"):Show()
        refreshIcon(self)

        if self.TooltipTitle then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip_SetTitle(GameTooltip, self.TooltipTitle)
            if self.TooltipText then
                GameTooltip_AddNormalLine(GameTooltip, self.TooltipText, true)
            end
            GameTooltip:Show()
        end

        if not self.Disabled and self.SubMenu then
            showSubList(self)
        end
    end

    local function OnLeave(self)
        local color             = Color.HIGHLIGHT
        self:GetChild("ColorSwatch"):SetVertexColor(color.r, color.g, color.b)
        self:GetChild("Highlight"):Hide()
        refreshIcon(self)

        GameTooltip:Hide()
    end

    local function OnClick(self)
        if self.Disabled then return true end

        if self.IsColorButton then
            local color         = self.Color

            Scorpio.Continue(function()
                OnColorChoosed(self, Scorpio.PickColor(color))
            end)

            -- Block the custom onclick
            return true
        elseif self.IsCheckButton then
            self.Checked        = not self.Check

            OnCheckStateChanged(self, self.Checked)

            return true
        elseif self.SubMenu then
            if self.SubMenu:IsShown() then
                closeSubList(self)
            else
                showSubList(self)
            end

            return true
        end
    end

    local function InvisibleButton_OnEnter(self)
        return OnEnter(self:GetParent())
    end

    local function InvisibleButton_OnLeave(self)
        return OnLeave(self:GetParent())
    end

    -------------------------------------------------------
    --                       Event                       --
    -------------------------------------------------------
    --- Fired when the color is choosed
    event "OnColorChoosed"

    --- Fired when the check state changes
    event "OnCheckStateChanged"

    -------------------------------------------------------
    --                     Property                      --
    -------------------------------------------------------
    --- Whether the button is a check button
    property "IsCheckButton"    { type = Boolean, handler = refreshCheckState }

    --- Whether the button is used for choosing color
    property "IsColorButton"    {
        type                    = Boolean,
        handler                 = function(self, val)
            if val then
                self:GetChild("ColorSwatch"):Show()
                self:GetChild("ColorSwatchBG"):Show()
            else
                self:GetChild("ColorSwatch"):Hide()
                self:GetChild("ColorSwatchBG"):Hide()
            end
        end
    }

    --- Whether the button is checked
    property "Checked"          { type = Boolean, handler = refreshCheckState }

    --- The color property used to hold the color value
    property "Color"            {
        type                    = ColorType,
        handler                 = function(self, color)
            if color then
                self:GetChild("ColorSwatch"):SetColorTexture(color.r, color.g, color.b)
            else
                self:GetChild("ColorSwatch"):SetColorTexture(1, 1, 1)
            end
        end,
    }

    --- The sub menu list
    property "SubMenu"          {
        type                    = UIObject,
        handler                 = function(self, val)
            if val then
                self:GetChild("ExpandArrow"):Show()
            else
                self:GetChild("ExpandArrow"):Hide()
            end
        end
    }

    --- The icon
    property "Icon"             { type = String + Number, handler = refreshIcon }

    --- The mouse over icon
    property "MouseOverIcon"    { type = String + Number, handler = refreshIcon }

    --- The tooltip title
    property "TooltipTitle"     { type = String }

    --- The tooltip text
    property "TooltipText"      { type = String }

    --- Whether disable the menu button
    property "Disabled"         {
        type                    = Boolean,
        handler                 = function(self, value)
            if value then
                self:Disable()
                self:GetChild("InvisibleButton"):Show()
            else
                self:Enable()
                self:GetChild("InvisibleButton"):Hide()
            end
        end,
    }

    --- The menu level
    property "MenuLevel"        { type = Number }

    -------------------------------------------------------
    --                      Method                       --
    -------------------------------------------------------
    --- To prevent the auto drop down hidden for sub menu button
    function HandlesGlobalMouseEvent(self, buttonID, event)
        return self.SubMenu and event == "GLOBAL_MOUSE_DOWN" and buttonID == "LeftButton"
    end

    -------------------------------------------------------
    --                    Constructor                    --
    -------------------------------------------------------
    __Template__{
        Highlight                   = Texture,
        Check                       = Texture,
        UnCheck                     = Texture,
        Icon                        = Texture,
        ExpandArrow                 = Texture,
        ColorSwatchBG               = Texture,
        ColorSwatch                 = Texture,
        InvisibleButton             = Button,
    }
    function __ctor(self)
        self:SetFrameLevel(self:GetParent():GetFrameLevel() + 1)

        self:GetChild("Highlight"):Hide()
        self:GetChild("Check"):Hide()
        self:GetChild("UnCheck"):Hide()
        self:GetChild("Icon"):Hide()
        self:GetChild("ColorSwatch"):Hide()
        self:GetChild("ColorSwatchBG"):Hide()
        self:GetChild("ExpandArrow"):Hide()
        self:GetChild("InvisibleButton"):Hide()

        self.OnClick                = self.OnClick + OnClick

        self:GetChild("InvisibleButton"):SetScript("OnEnter", InvisibleButton_OnEnter)
        self:GetChild("InvisibleButton"):SetScript("OnLeave", InvisibleButton_OnLeave)
    end
end)

--- The drop down list template
__Sealed__() class "UIDropDownList" (function(_ENV)
    inherit "Button"

    export { IsObjectType = Class.IsObjectType, GetChilds = UIObject.GetChilds, OrgSetFrameLevel = Button.SetFrameLevel }

    function SetFrameLevel(self, level)
        for _, child in GetChild(self) do
            if IsObjectType(child, UIDropDownMenuButton) then
                child:SetFrameLevel(level + 1)
            end
        end
    end


end)

-----------------------------------------------------------
--                 UIDropDownMenu Style                  --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [UIDropDownMenuButton]      = {
        size                    = Size(100, 16),
        normalFont              = GameFontHighlightSmallLeft,
        highlightFont           = GameFontHighlightSmallLeft,
        disabledFont            = GameFontDisableSmallLeft,

        ButtonText              = {
            location            = { Anchor("LEFT", -5, 0) },
        },

        -- Layer
        Highlight               = {
            drawLayer           = "BACKGROUND",
            file                = [[Interface\QuestFrame\UI-QuestTitleHighlight]],
            alphaMode           = "ADD",
            location            = { Anchor("TOPLEFT"), Anchor("BOTTOMRIGHT") },
        },
        Check                   = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Common\UI-DropDownRadioChecks]],
            size                = Size(16, 16),
            location            = { Anchor("LEFT") },
            texCoords           = RectType(0, 0.5, 0.5, 1.0),
        },
        UnCheck                 = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Common\UI-DropDownRadioChecks]],
            size                = Size(16, 16),
            location            = { Anchor("LEFT") },
            texCoords           = RectType(0.5, 1.0, 0.5, 1.0),
        },
        Icon                    = {
            drawLayer           = "ARTWORK",
            size                = Size(16, 16),
            location            = { Anchor("RIGHT") },
        },
        ColorSwatchBG           = {
            drawLayer           = "ARTWORK",
            size                = Size(16, 16),
            location            = { Anchor("RIGHT", -6, 0) },
            file                = [[Interface\ChatFrame\ChatFrameColorSwatch]],
        },
        ColorSwatch             = {
            drawLayer           = "OVERLAY",
            size                = Size(14, 14),
            location            = { Anchor("CENTER", 0, 0, "ColorSwatchBG") },
        },
        ExpandArrow             = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\ChatFrame\ChatFrameExpandArrow]],
            size                = Size(16, 16),
            location            = { Anchor("RIGHT", 0, 0) },
        },
        InvisibleButton         = {
            location            = { Anchor("TOPLEFT"), Anchor("BOTTOMLEFT"), Anchor("RIGHT", 0, 0, "ColorSwatch", "LEFT") },
        },
    },
    [UIDropDownList]            = {
        frameStrata             = "DIALOG",
    },
})