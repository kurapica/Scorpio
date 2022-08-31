--========================================================--
--             Scorpio Config Struct Type Viewer          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/08/29                              --
--========================================================--

--========================================================--
Scorpio      "Scorpio.Widget.ConfigStructTypeViewer" "1.0.0"
--========================================================--

--- The struct MemberStructType viewer
__Sealed__() __ConfigDataType__(MemberStructType)
class "MemberStructTypeViewer"  (function(_ENV)
    inherit "Frame"

    local function refreshValue(self, name, v)
        if not self.ConfigSubject then return end

        local value             = self.Value
        value[name]             = v

        for _, mem in Struct.GetMembers(self.ConfigSubject.Type) do
            if mem:IsRequire() and value[mem:GetName()] == nil then return end
        end

        return self:SetConfigSubjectValue(value)
    end

    --- The member widget
    property "MemberWidgets"    { default = function() return {} end }

    --- The current value
    property "Value"            { default = function() return {} end }

    --- Sets the config subject
    function SetConfigSubject(self, configSubject)
        local locale            = configSubject.Locale
        local stype             = configSubject.Type
        local index             = 1
        local hasRequire        = false

        for _, mem in Struct.GetMembers(stype) do
            local name          = mem:GetName()
            local type          = mem:GetType()
            local widget        = __ConfigDataType__.GetWidgetType(type)

            if mem:IsRequire() then
                hasRequire      = true
            end

            if widget then
                local ui        = self.MemberWidgets[name]

                if not ui then
                    local sub   = ConfigSubject(locale[name], type, nil, true, nil, locale)
                    sub.OnValueSet = function(s, v) s:OnNext(v) refreshValue(self, name, v) end

                    -- The field order can't be changed, so we don't need recycle them
                    ui          = widget("ConfigFieldWidget" .. name, self)
                    ui:SetConfigSubject(sub)
                    self.MemberWidgets[name] = ui
                end

                ui:SetID(index)
                index           = index + 1
            else
                Warn("Lack the config ui widget for data type " .. tostring(ftype))
            end
        end

        return configSubject:Subscribe(function(value)
            if type(value) ~= "table" then
                value           = not hasRequire and stype() or nil
            end
            self.Value          = value

            if value then
                for name, ui in pairs(self.MemberWidgets) do
                    ui.ConfigSubject:OnNext(value[name])
                end
            else
                for name, ui in pairs(self.MemberWidgets) do
                    ui.ConfigSubject:OnNext(nil)
                end
            end
        end)
    end
end)

--- The struct ArrayStructType viewer
__Sealed__() __ConfigDataType__(ArrayStructType)
class "ArrayStructTypeViewer"   (function(_ENV)
    inherit "Frame"

    -- Helpers
    local clone                 = Toolset.clone
    local tostring              = Toolset.tostring

    local function refreshList(self)
        local list              = self:GetChild("IndexList")
        local selectedIndex     = list.SelectedValue
        list:ClearItems()

        if self.UseMember then
            local mem           = self.UseMember
            for i, value in ipairs(self.Value) do
                list.Items[i]   = tostring(value[mem])
            end
        elseif self.UseValue then
            for i, value in ipairs(self.Value) do
                list.Items[i]   = tostring(value)
            end
        else
            for i, value in ipairs(self.Value) do
                list.Items[i]   = tostring(i)
            end
        end

        if selectedIndex and selectedIndex <= #self.Value then
            list.SelectedValue  = selectedIndex
        end
    end

    local function refreshValue(self)
        return self:SetConfigSubjectValue(clone(self.Value, true))
    end

    local function onAdd(self)
        self                    = self:GetParent()
        if self.SelectedValue == nil then return end
        tinsert(self.Value, self.SelectedValue)
        refreshValue(self)
        self:GetChild("IndexList").SelectedValue = #self.Value
    end

    local function onSave(self)
        self                    = self:GetParent()
        local index             = self:GetChild("IndexList").SelectedValue
        if index and index <= #self.Value and self.SelectedValue ~= nil then
            self.Value[index]   = self.SelectedValue
            return refreshValue(self)
        end
    end

    local function onDel(self)
        self                    = self:GetParent()
        local index             = self:GetChild("IndexList").SelectedValue
        if index and index <= #self.Value then
            tremove(self.Value, index)
            return refreshValue(self)
        end
    end

    local function onItemSelected(self)
        local index             = self.SelectedValue
        self                    = self:GetParent()

        if index and index <= #self.Value then
            self.SelectedValue  = clone(self.Value[index], true)
        end
    end

    --- The value widget
    property "ValueWidget"      { }

    --- The selected value to be insert/upate
    property "SelectedValue"    { handler = function(self, val) return self.ValueWidget and self.ValueWidget.ConfigSubject:OnNext(val) end }

    --- The current value
    __Set__(PropertySet.DeepClone)
    property "Value"            {
        type                    = Table,
        default                 = function() return {} end,
        handler                 = refreshList
    }

    --- The member name to be displayed
    property "UseMember"        { type = String }

    --- Whther use value as label
    property "UseValue"         { type = Boolean }

    --- Sets the config subject
    function SetConfigSubject(self, configSubject)
        local locale            = configSubject.Locale
        local eleType           = Struct.GetArrayElement(configSubject.Type)
        local widget            = __ConfigDataType__.GetWidgetType(eleType)
        local name              = "Element"

        if not widget then return end

        if self.ValueWidget then
            if getmetatable(self.ValueWidget) ~= widget then
                return Warn("The ArrayStructTypeViewer can't be re-used for different data types")
            end
        else
            local sub           = ConfigSubject(name, eleType, nil, true, nil, locale)
            sub.OnValueSet      = function(s, v) self.SelectedValue = v end

            -- The field order can't be changed, so we don't need recycle them
            ui                  = widget("ConfigFieldWidget" .. name, self)
            ui:SetConfigSubject(sub)
            ui:SetID(1)
            self.ValueWidget    = ui

            -- Check how to display the list's text
            if Enum.Validate(eleType) or Struct.GetStructCategory(eleType) == StructCategory.CUSTOM then
                self.UseValue   = true
            elseif Struct.GetStructCategory(eleType) == StructCategory.ARRAY or Struct.GetStructCategory(eleType) == StructCategory.DICTIONARY then
                self.UseValue   = false
            else
                local cmem, req
                for _, mem in Struct.GetMembers(eleType) do
                    local mtype = mem:GetType()
                    if Enum.Validate(mtype) or Struct.GetStructCategory(mtype) == StructCategory.CUSTOM then
                        if mem:IsRequire() and not req then
                            req = true
                            cmem= mem:GetName()
                        else
                            cmem= cmem or mem:GetName()
                        end
                    end
                end
                self.UseMember  = cmem
            end
        end

        return configSubject:Subscribe(function(value) self.Value = value end)
    end

    --- The constructor
    __Template__ {
        IndexList               = ListFrame,
        Add                     = UIPanelButton,
        Save                    = UIPanelButton,
        Remove                  = UIPanelButton,
    }
    function __ctor(self)
        self:GetChild("Add").OnClick    = self:GetChild("Add").OnClick    + onAdd
        self:GetChild("Save").OnClick   = self:GetChild("Save").OnClick   + onSave
        self:GetChild("Remove").OnClick = self:GetChild("Remove").OnClick + onDel
        self:GetChild("IndexList").OnItemClick = self:GetChild("IndexList").OnItemClick + onItemSelected
    end
end)

--- The struct DictStructType viewer
__Sealed__() __ConfigDataType__(DictStructType)
class "DictStructTypeViewer"    (function(_ENV)
    inherit "Frame"

    -- Helpers
    local clone                 = Toolset.clone

    local function refreshList(self)
        local list              = self:GetChild("IndexList")
        local selectedValue     = list.SelectedValue
        list:ClearItems()

        for name, value in pairs(self.Value) do
            list.Items[name]    = tostring(name)
        end

        list.SelectedValue      = selectedValue
    end

    local function refreshValue(self, value)
        return self:SetConfigSubjectValue(clone(self.Value))
    end

    local function onSave(self)
        self                    = self:GetParent()
        if self.SelectedKey and self.SelectedValue ~= nil then
            self.Value[self.SelectedKey] = self.SelectedValue
            return refreshValue(self)
        end
    end

    local function onDel(self)
        self                    = self:GetParent()
        if self.SelectedKey then
            self.Value[self.SelectedKey] = nil
            self.SelectedKey    = nil
            self.SelectedValue  = nil
            self:GetChild("IndexList").SelectedValue = nil
            return refreshValue(self)
        end
    end

    local function onItemSelected(self)
        local index             = self.SelectedValue
        self                    = self:GetParent()

        if index and self.Value[index] ~= nil then
            self.SelectedKey    = index
            self.SelectedValue  = clone(self.Value[index], true)
        end
    end

    --- The key widget
    property "KeyWidget"        { }

    --- The value widget
    property "ValueWidget"      { }

    --- The selected key to be update/delete
    property "SelectedKey"      { handler = function(self, val) return self.KeyWidget and self.KeyWidget.ConfigSubject:OnNext(val) end }

    --- The selected value to be insert/upate
    property "SelectedValue"    { handler = function(self, val) return self.ValueWidget and self.ValueWidget.ConfigSubject:OnNext(val) end }

    --- The current value
    __Set__(PropertySet.DeepClone)
    property "Value"            {
        type                    = Table,
        default                 = function() return {} end,
        handler                 = refreshList
    }

    --- Sets the config subject
    function SetConfigSubject(self, configSubject)
        local locale            = configSubject.Locale
        local keyType           = Struct.GetDictionaryKey(configSubject.Type)
        local eleType           = Struct.GetDictionaryValue(configSubject.Type)
        local keyWidget         = __ConfigDataType__.GetWidgetType(keyType)
        local widget            = __ConfigDataType__.GetWidgetType(eleType)
        if not widget then return end

        if self.KeyWidget then
            if getmetatable(self.KeyWidget) ~= keyWidget then
                return Warn("The DictStructTypeViewer can't be re-used for different data types")
            end
        else
            local sub           = ConfigSubject(locale["Key"], keyType, nil, true, nil, locale)
            sub.OnValueSet      = function(s, v) self.SelectedKey = v end

            -- The field order can't be changed, so we don't need recycle them
            ui                  = keyWidget("ConfigFieldWidgetKey", self)
            ui:SetConfigSubject(sub)
            ui:SetID(1)
            self.KeyWidget      = ui
        end

        if self.ValueWidget then
            if getmetatable(self.ValueWidget) ~= widget then
                return Warn("The DictStructTypeViewer can't be re-used for different data types")
            end
        else
            local sub           = ConfigSubject(locale["Value"], eleType, nil, true, nil, locale)
            sub.OnValueSet      = function(s, v) self.SelectedValue = v end

            -- The field order can't be changed, so we don't need recycle them
            ui                  = widget("ConfigFieldWidgetValue", self)
            ui:SetConfigSubject(sub)
            ui:SetID(2)
            self.ValueWidget    = ui
        end

        return configSubject:Subscribe(function(value) self.Value = value end)
    end

    --- The constructor
    __Template__ {
        IndexList               = ListFrame,
        Save                    = UIPanelButton,
        Remove                  = UIPanelButton,
    }
    function __ctor(self)
        self:GetChild("Save").OnClick   = self:GetChild("Save").OnClick   + onSave
        self:GetChild("Remove").OnClick = self:GetChild("Remove").OnClick + onDel
        self:GetChild("IndexList").OnItemClick = self:GetChild("IndexList").OnItemClick + onItemSelected
    end
end)

------------------------------------------------------
-- Default Style
------------------------------------------------------
Style.UpdateSkin("Default",     {
    [MemberStructTypeViewer]    = {
        -- display
        backdrop                = {
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            tile                = true, tileSize = 16, edgeSize = 16,
            insets              = { left = 5, right = 5, top = 5, bottom = 5 }
        },
        backdropBorderColor     = Color(0.6, 0.6, 0.6),

        -- layout
        layoutManager           = Layout.VerticalLayoutManager(),
        padding                 = {
            top                 = 8,
            bottom              = 8,
        },
        marginRight             = 8,

        -- config subject handler
        [IConfigSubjectHandler] = {
            label               = {
                location        = { Anchor("TOPRIGHT", -10, -4, nil, "TOPLEFT") },
                justifyH        = "RIGHT",
                Text            = Wow.FromUIProperty("ConfigSubject"):Map("x=>x and x.Name"),
            },

            marginLeft          = 80,
            marginBottom        = 32,
        },
    },
    [ArrayStructTypeViewer]     = {
        -- display
        backdrop                = {
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            tile                = true, tileSize = 16, edgeSize = 16,
            insets              = { left = 5, right = 5, top = 5, bottom = 5 }
        },
        backdropBorderColor     = Color(0.6, 0.6, 0.6),

        -- layout
        layoutManager           = Layout.VerticalLayoutManager(),
        padding                 = {
            top                 = 8,
            bottom              = 32, -- For buttons
        },
        marginRight             = 8,
        MinResize               = Size(100, 200), -- The min height

        -- children
        IndexList               = {
            location            = {
                Anchor("TOPLEFT", 8, -8),
                Anchor("BOTTOMLEFT", 8, 8),
            },
            width               = 150,
        },
        Remove                  = {
            location            = { Anchor("BOTTOMRIGHT", -8, 8) },
            size                = Size(48, 24),
            text                = "-",
        },
        Save                    = {
            location            = { Anchor("RIGHT", -4, 0, "Remove", "LEFT") },
            size                = Size(48, 24),
            text                = "√",
        },
        Add                     = {
            location            = { Anchor("RIGHT", -4, 0, "Save", "LEFT") },
            size                = Size(48, 24),
            text                = "+",
        },

        -- config subject handler
        [IConfigSubjectHandler] = {
            marginLeft          = 160,
            marginBottom        = 36,
        },
    },
    [DictStructTypeViewer]      = {
        -- display
        backdrop                = {
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            tile                = true, tileSize = 16, edgeSize = 16,
            insets              = { left = 5, right = 5, top = 5, bottom = 5 }
        },
        backdropBorderColor     = Color(0.6, 0.6, 0.6),

        -- layout
        layoutManager           = Layout.VerticalLayoutManager(),
        padding                 = {
            top                 = 8,
            bottom              = 32, -- For buttons
        },
        marginRight             = 8,
        MinResize               = Size(100, 200), -- The min height

        -- children
        IndexList               = {
            location            = {
                Anchor("TOPLEFT", 8, -8),
                Anchor("BOTTOMLEFT", 8, 8),
            },
            width               = 150,
        },
        Remove                  = {
            location            = { Anchor("BOTTOMRIGHT", -8, 8) },
            size                = Size(48, 24),
            text                = "-",
        },
        Save                    = {
            location            = { Anchor("RIGHT", -4, 0, "Remove", "LEFT") },
            size                = Size(48, 24),
            text                = "√",
        },

        -- config subject handler
        [IConfigSubjectHandler] = {
            label               = {
                location        = { Anchor("TOPRIGHT", -10, -4, nil, "TOPLEFT") },
                justifyH        = "RIGHT",
                Text            = Wow.FromUIProperty("ConfigSubject"):Map("x=>x and x.Name"),
            },

            marginLeft          = 230,
            marginBottom        = 36,
        },
    },
})
