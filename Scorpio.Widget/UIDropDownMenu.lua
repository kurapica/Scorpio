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

local function adjustLocation(self, owner, anchor)
    anchor                      = anchor or "ANCHOR_TOPRIGHT"

    local scale                 = self:GetEffectiveScale()

    local width                 = self:GetWidth() * scale
    local height                = self:GetHeight() * scale

    local x, y
    if owner then
        local ownerScale        = owner:GetEffectiveScale()

        if anchor == "ANCHOR_TOPRIGHT" then
            x, y                = owner:GetRight() * ownerScale, owner:GetTop() * ownerScale
        elseif anchor == "ANCHOR_RIGHT" then
            x, y                = owner:GetRight() * ownerScale, select(2, owner:GetCenter()) * ownerScale
        elseif anchor == "ANCHOR_BOTTOMRIGHT" then
            x, y                = owner:GetRight() * ownerScale - width, owner:GetBottom() * ownerScale
        elseif anchor == "ANCHOR_TOPLEFT" then
            x, y                = owner:GetLeft()  * ownerScale - width, owner:GetTop() * ownerScale
        elseif anchor == "ANCHOR_LEFT" then
            x, y                = owner:GetLeft()  * ownerScale - width, select(2, owner:GetCenter()) * ownerScale
        elseif anchor == "ANCHOR_BOTTOMLEFT" then
            x, y                = owner:GetLeft()  * ownerScale, owner:GetBottom() * ownerScale
        end
    end

    if not (x and y) then x, y  = GetCursorPosition() end

    if self.OwnerOffset then
        x                       = x + self.OwnerOffset.x * scale
        y                       = y + self.OwnerOffset.y * scale
    end

    x                           = math.min(math.max(x, 0), GetScreenWidth() * scale - width)
    y                           = math.max(y, height)

    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
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
        if Class.IsObjectType(child, UIDropDownMenuButton) then
            child.MenuLevel     = 2
            child:SetFrameLevel(self:GetFrameLevel() + 2)
        end
    end

    adjustLocation(self, self.Owner, self.Anchor)
    self:Show()
end

local function showSubList(self)
    local level                 = self.MenuLevel
    local submenu               = self.SubMenu

    if not (level and submenu and self:IsShown()) then return end
    if _UIDropDownListLevel[level] == submenu then return end

    submenu:SetFrameLevel(self:GetFrameLevel() + 2)

    for i = #_UIDropDownListLevel, level, -1 do
        _UIDropDownListLevel[i]:Hide()
        _UIDropDownListLevel[i] = nil
        _UIDropDownCountDown[i] = nil
        _UIDropDownMenuButton[i]= nil
    end

    _UIDropDownListLevel[level] = submenu
    _UIDropDownMenuButton[level]= self

    for _, child in UIObject.GetChilds(submenu) do
        if Class.IsObjectType(child, UIDropDownMenuButton) then
            child.MenuLevel     = level + 1
            child:SetFrameLevel(submenu:GetFrameLevel() + 2)
        end
    end

    adjustLocation(submenu, self)
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
    -- must use the mouse up here
    if event == "GLOBAL_MOUSE_UP" and (button == "LeftButton" or button == "RightButton") then
        return Next(closeMenuList)
    end
end

-----------------------------------------------------------
--                 UIDropDownMenu Widget                 --
-----------------------------------------------------------
--- The UI drop down menu button template
__Sealed__()
class "UIDropDownMenuButton" (function(_ENV)
    inherit "Button"

    export { IsObjectType = Class.IsObjectType, GetChilds = UIObject.GetChilds }

    local function refreshCheckState(self)
        self:GetChild("Check"):Hide()
        self:GetChild("UnCheck"):Hide()
        self:GetChild("RadioCheck"):Hide()
        self:GetChild("RadioUnCheck"):Hide()

        if self.IsCheckButton then
            if self:GetParent() and self:GetParent().IsMultiCheck then
                if self.Checked then
                    self:GetChild("Check"):Show()
                else
                    self:GetChild("UnCheck"):Show()
                end
            else
                if self.Checked then
                    self:GetChild("RadioCheck"):Show()
                else
                    self:GetChild("RadioUnCheck"):Show()
                end
            end
        end
    end

    local function refreshIcon(self)
        local icon              = self:GetChild("DisplayIcon")

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
            if self:GetParent().IsMultiCheck then
                self.Checked    = not self.Checked
                OnCheckStateChanged(self, self.Checked)
            elseif not self.Checked then
                self.Checked    = true
                self:GetParent():OnCheckStateChanged(self.CheckValue)
            end

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

    --- The check value of the menu button
    property "CheckValue"       { type = Any }

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
        return self.SubMenu and buttonID == "LeftButton"
    end

    -------------------------------------------------------
    --                    Constructor                    --
    -------------------------------------------------------
    __Template__{
        Highlight                   = Texture,
        Check                       = Texture,
        UnCheck                     = Texture,
        RadioCheck                  = Texture,
        RadioUnCheck                = Texture,
        DisplayIcon                 = Texture,
        ExpandArrow                 = Texture,
        ColorSwatchBG               = Texture,
        ColorSwatch                 = Texture,
        InvisibleButton             = Button,
    }
    function __ctor(self)
        self:GetChild("Highlight"):Hide()
        self:GetChild("Check"):Hide()
        self:GetChild("UnCheck"):Hide()
        self:GetChild("RadioCheck"):Hide()
        self:GetChild("RadioUnCheck"):Hide()
        self:GetChild("DisplayIcon"):Hide()
        self:GetChild("ColorSwatch"):Hide()
        self:GetChild("ColorSwatchBG"):Hide()
        self:GetChild("ExpandArrow"):Hide()
        self:GetChild("InvisibleButton"):Hide()

        self.OnEnter                = self.OnEnter + OnEnter
        self.OnLeave                = self.OnLeave + OnLeave
        self.OnClick                = self.OnClick + OnClick

        self:GetChild("InvisibleButton"):SetScript("OnEnter", InvisibleButton_OnEnter)
        self:GetChild("InvisibleButton"):SetScript("OnLeave", InvisibleButton_OnLeave)
    end
end)

--- The drop down list template
__Sealed__() class "UIDropDownMenuList" (function(_ENV)
    inherit "Button"

    --- The check state change event, only triggered when IsMultiCheck is false
    event "OnCheckStateChanged"

    --- The owner of the drop down list
    property "Owner"            { type = UI }

    --- The Anchor to the owner
    property "Anchor"           { type = AnchorType, default = "ANCHOR_TOPRIGHT" }

    --- Whether the check menu buttons on the list is multi choosable
    property "IsMultiCheck"     { type = Boolean, default = true }

    --- The offsets from the frame's edges used to limit the menu buttons
    property "ContainerInsets"  { type = Inset }

    --- The x & y offsets to the owner
    property "OwnerOffset"      { type = Dimension }
end)

--- The drop down list menu template
__Sealed__() class "UIDropDownList" { UIDropDownMenuList }

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
            location            = { Anchor("LEFT", 18, 0), Anchor("RIGHT", -24, 0) },
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
            file                = [[Interface\Buttons\UI-CheckBox-Check]],
            size                = Size(16, 16),
            location            = { Anchor("LEFT") },
        },
        UnCheck                 = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Buttons\UI-CheckBox-Up]],
            size                = Size(16, 16),
            location            = { Anchor("LEFT") },
        },
        RadioCheck              = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Common\UI-DropDownRadioChecks]],
            size                = Size(16, 16),
            location            = { Anchor("LEFT") },
            texCoords           = RectType(0, 0.5, 0.5, 1.0),
        },
        RadioUnCheck            = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Common\UI-DropDownRadioChecks]],
            size                = Size(16, 16),
            location            = { Anchor("LEFT") },
            texCoords           = RectType(0.5, 1.0, 0.5, 1.0),
        },
        DisplayIcon             = {
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
    [UIDropDownMenuList]        = {
        frameStrata             = "FULLSCREEN_DIALOG",
        enableMouse             = true,
        Toplevel                = true,
        backdrop                = {
            bgFile              = [[Interface\Tooltips\UI-Tooltip-Background]],
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            tile                = true, tileSize = 16, edgeSize = 16,
            insets              = { left = 5, right = 4, top = 4, bottom = 4 }
        },
        backdropBorderColor     = ColorType(1, 1, 1),
        backdropColor           = ColorType(0.09, 0.09, 0.19),
        containerInsets         = Inset(8, 8, 8, 8),
    },
    [UIDropDownList]            = {
        backdrop                = {
            bgFile              = [[Interface\DialogFrame\UI-DialogBox-Background]],
            edgeFile            = [[Interface\DialogFrame\UI-DialogBox-Border]],
            tile                = true, tileSize = 32, edgeSize = 32,
            insets              = { left = 11, right = 12, top = 12, bottom = 11 }
        },
        backdropColor           = NIL,
        containerInsets         = Inset(16, 16, 16, 16),
        ownerOffset             = Dimension(0, 0),
    },
})

-----------------------------------------------------------
--                  UIDropDownMenu API                   --
-----------------------------------------------------------
local _ButtonHolder             = CreateFrame("Frame")
_ButtonHolder:Hide()

local rycDropDownMenuButtons    = Recycle(UIDropDownMenuButton, "Scorpio_UIDropDownMenuButton%d", _ButtonHolder)
local rycDropDownMenuLists      = Recycle(UIDropDownMenuList, "Scorpio_UIDropDownMenuList%d")
local rycDropDownLists          = Recycle(UIDropDownList, "Scorpio_UIDropDownList%d")

function rycDropDownMenuButtons:OnInit(obj)
    return Style.InstantApplyStyle(obj)
end

function rycDropDownMenuLists:OnInit(obj)
    return Style.InstantApplyStyle(obj)
end

function rycDropDownLists:OnInit(obj)
    return Style.InstantApplyStyle(obj)
end

local function refreshMenuSize(self)
    local insets                = self.ContainerInsets
    local offset                = -(insets and insets.top or 0)
    local leftoff               = insets and insets.left or 0
    local rightoff              = -(insets and insets.right or 0)

    local maxw                  = 0
    local child

    for i = 1, #self do
        child                   = self[i]
        child:ClearAllPoints()
        child:SetPoint("LEFT", leftoff, 0)
        child:SetPoint("RIGHT", rightoff, 0)
        child:SetPoint("TOP", 0, offset)

        offset                  = offset - child:GetHeight()

        local ft                = child:GetFontString()
        if ft then
            local leftw         = 0
            local rightw        = 0
            for i = 1, ft:GetNumPoints() do
                local p, f, r, x, y = ft:GetPoint(i)

                if f and IsSameUI(f, child) and p and r then
                    if p:match("LEFT") and r:match("LEFT") then
                        leftw   = x
                    elseif p:match("RIGHT") and r:match("RIGHT") then
                        rightw  = - x
                    end
                end
            end
            maxw                = math.max(maxw, (ft:GetStringWidth() or 0) + leftw + rightw)
        end

        if child.SubMenu then
            refreshMenuSize(child.SubMenu)
        end
    end

    maxw                        = maxw + (insets and (insets.left + insets.right) or 0)
    offset                      = math.abs(offset) + (insets and insets.bottom or 0)

    local minwidth, minheight   = self:GetMinResize()
    local maxwidth, maxheight   = self:GetMaxResize()

    if maxwidth == 0  then maxwidth  = nil end
    if maxheight == 0 then maxheight = nil end

    maxw                        = math.min(math.max(maxw, minwidth or 0), maxwidth or math.huge)
    offset                      = math.min(math.max(offset, minheight or 0), maxheight or math.huge)

    self:SetWidth(maxw)
    self:SetHeight(offset)
end

local function recycleMenu(self)
    if self.CallbackOnClose then
        Continue(self.CallbackOnClose)
    end

    for i = #self, 1, -1 do
        local button            = self[i]

        if button.SubMenu then
            recycleMenu(button.SubMenu)
            button.SubMenu      = nil
        end

        button:SetParent(_ButtonHolder)
        button:ClearAllPoints()

        rycDropDownMenuButtons(button)

        self[i]                 = nil
    end

    self.OnHide                 = nil
    self.CallbackOnClose        = nil

    if Class.IsObjectType(self, UIDropDownList) then
        rycDropDownLists(self)
    else
        rycDropDownMenuLists(self)
    end
end

local function buildDropDownMenuList(info, dropdown, root)
    local menu                  = dropdown and rycDropDownLists() or rycDropDownMenuLists()

    if root then
        menu.Owner              = info.owner
        menu.Anchor             = info.anchor
        menu.OnHide             = recycleMenu

        if info.close then
            menu.CallbackOnClose= info.close
        end
    else
        menu.OnHide             = nil
    end

    local checkvalue

    if info.check then
        menu.IsMultiCheck       = false

        menu.OnCheckStateChanged= function(self, val)
            return info.check.set(val)
        end

        if type(info.check.get) == "function" then
            checkvalue          = info.check.get()
        else
            checkvalue          = info.check.get
        end
    else
        menu.IsMultiCheck       = true

        menu.OnCheckStateChanged= nil
    end

    for i, binfo in ipairs(info) do
        local button            = rycDropDownMenuButtons()
        button:SetParent(menu)
        button:SetID(i)

        menu[i]                 = button

        button:SetText(binfo.text)

        if binfo.color then
            button.IsColorButton= true
            local value
            if type(binfo.color.get) == "function" then
                value           = binfo.color.get()
            else
                value           = binfo.color.get
            end
            value               = value and Struct.ValidateValue(ColorType, value)
            if value then
                button.Color    = value
            end

            button.OnColorChoosed = function(self, color)
                return binfo.color.set(color)
            end
        else
            button.IsColorButton= nil
            button.OnColorChoosed = nil
        end

        if not menu.IsMultiCheck and binfo.checkvalue ~= nil then
            button.IsCheckButton= true
            button.CheckValue   = binfo.checkvalue
            button.Checked      = checkvalue == binfo.checkvalue
            button.OnCheckStateChanged = nil
        elseif binfo.check then
            button.IsCheckButton= true
            local value
            if type(binfo.check.get) == "function" then
                value           = binfo.check.get()
            else
                value           = binfo.check.get
            end
            button.Checked      = value and true or false

            button.OnCheckStateChanged = function(self, checked)
                return binfo.check.set(checked)
            end
        else
            button.IsCheckButton= false
            button.OnCheckStateChanged = nil
        end

        if binfo.click then
            button.OnClick      = function(self)
                return Continue(binfo.click)
            end
        else
            button.OnClick      = nil
        end

        if binfo.disabled then
            button.Disabled     = true
        else
            button.Disabled     = false
        end

        if binfo.submenu then
            button.SubMenu      = buildDropDownMenuList(binfo.submenu, dropdown)
        end
    end

    return menu
end

struct "UIDropDownMenuInfo" {}

__Sealed__() struct "UIDropDownMenuButtonInfo" {
    { name = "text",    type = String, require = true },
    { name = "color",   type = PropertyAccessor },
    { name = "check",   type = PropertyAccessor },
    { name = "checkvalue", type = Any },
    { name = "click",   type = Function },
    { name = "disabled",type = Boolean },
    { name = "submenu", type = UIDropDownMenuInfo }
}

__Sealed__() struct "UIDropDownMenuInfo" {
    { name = "dropdown",type = Boolean },
    { name = "owner",   type = UIObject },
    { name = "anchor",  type = AnchorType },
    { name = "check",   type = PropertyAccessor },
    { name = "close",   type = Function },

    function (self)
        if #self == 0 then
            return "%s must contain menu button settings"
        end

        for i = 1, #self do
            local val, message = Struct.ValidateValue(UIDropDownMenuButtonInfo, self[i])
            if message then
                return message:gsub("%%s", "%%s[" .. i .. "]")
            end
        end
    end
}

--- The API to show the drop down menu
__Static__() __Async__()
__Arguments__{ UIDropDownMenuInfo }
function Scorpio.ShowDropDownMenu(info)
    local menu                  = buildDropDownMenuList(info, info.dropdown and info.owner and true or false, true)
    Next() Next()

    refreshMenuSize(menu)

    return showMenuList(menu)
end

__Static__()
Scorpio.CloseDropDownMenu       = closeMenuList