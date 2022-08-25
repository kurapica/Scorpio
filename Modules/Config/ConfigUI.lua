--========================================================--
--                Scorpio SavedVariable Config UI System  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/06/25                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config.UI"               "1.0.0"
--========================================================--

-- Shared
local _PanelMap                 = {}

------------------------------------------------------
-- Scorpio Extension
------------------------------------------------------
class (Scorpio)                (function(_ENV)
    local _PanelCount           = 0

    --- Sets the saved variable to the _Config node
    function SetSavedVariable(self, name)
        self._Config:SetSavedVariable(name, 2)
        return self
    end

    --- Sets the saved variable to the _CharConfig Node
    function SetCharSavedVariable(Self, name)
        self._CharConfig:SetSavedVariable(name, 2)
        return self
    end

    --- Start using the config panel for the addon
    __Arguments__{ Boolean/nil }
    function UseConfigPanel(self, showAllSubNodes)
        local addon             = self._Addon
        local config            = addon._Config
        if _PanelMap[config] then return self end

        _PanelCount             = _PanelCount + 1
        _PanelMap[config]       = ConfigCategoryPanel("Scorpio_Config_Node_Panel_" .. _PanelCount, InterfaceOptionsFrame, config, addon._Name, nil, showAllSubNodes)
        return self
    end

    --- Bind the config node to a sub category panel
    __Arguments__{ NEString, ConfigNode, Boolean/nil }:Throwable()
    function UseSubConfigPanel(self, name, node, showAllSubNodes)
        if _PanelMap[node] then return self end
        local addon             = self._Addon
        if not _PanelMap[addon._Config] then
            throw("Usage: _Addon:UseSubConfigPanel(name, configNode[, showAllSubNodes]) - The _Addon:UseConfigPanel([showAllSubNodes]) must be called first to enable the config panel for _Config.")
        end

        _PanelCount             = _PanelCount + 1
        _PanelMap[node]         = ConfigCategoryPanel("Scorpio_Config_Node_Panel_" .. _PanelCount, InterfaceOptionsFrame, node, name, addon._Name, showAllSubNodes)
        return self
    end

    --- Show the config UI panel for the addon
    __Async__()
    function ShowConfigUI(self)
        self                    = self._Addon
        if InCombatLockdown() or not _PanelMap[self._Config] then return end

        InterfaceOptionsFrame_OpenToCategory(self._Name)
        Next() -- Make sure open to the category
        InterfaceOptionsFrame_OpenToCategory(self._Name)
    end
end)

------------------------------------------------------
-- Data Type UI Map
------------------------------------------------------
--- Represents the interface of the config node field handler
__Sealed__()
interface "IConfigSubjectHandler" (function(_ENV)
    require "Frame"

    -----------------------------------------------------------
    --                       property                        --
    -----------------------------------------------------------
    --- The config subject
    __Final__() __Observable__():AsInheritable()
    property "ConfigNodeField"  { type = ConfigSubject, handler = "SetConfigNodeField" }

    --- The value waiting for commit
    __Abstract__()
    property "ConfigNodeFieldUnCommitValue" { type = Any }

    -----------------------------------------------------------
    --                    abstract method                    --
    -----------------------------------------------------------
    --- Binding the ui element with a config node field's info,
    -- also can be used to clear the binding if configSubject is nil
    __Abstract__()
    function SetConfigNodeField(self, configSubject) end
end)

--- The bidirectional binding between the config node field and widget
__Sealed__()
class "__ConfigDataType__"      (function(_ENV)
    extend "IApplyAttribute"

    local _DataTypeWidgetMap    = {}

    -----------------------------------------------------------
    --                     static method                     --
    -----------------------------------------------------------
    --- Gets the widget type for the data type
    __Static__()
    function GetWidgetType(dataType)
        -- Gets the direct map
        local widget            = _DataTypeWidgetMap[dataType]
        if widget then return widget end

        -- Gets the common map
        if Enum.Validate(dataType) then
            return _DataTypeWidgetMap[EnumType]

        elseif Struct.Validate(dataType) then
            local stype         = Struct.GetStructCategory(dataType)

            if stype == StructCategory.CUSTOM then
                -- Check template first
                local btype     = Struct.GetTemplate(dataType)
                if btype and btype ~= dataType then
                    if _DataTypeWidgetMap[btype] then
                        return _DataTypeWidgetMap[btype]
                    end
                    dataType    = btype
                end

                -- Check base type
                btype           = Struct.GetBaseStruct(dataType)
                while btype do
                    widget      = _DataTypeWidgetMap[btype]
                    if widget then return widget end
                    btype       = Struct.GetBaseStruct(btype)
                end

                -- Use String as default
                return _DataTypeWidgetMap[String]

            elseif stype == StructCategory.ARRAY then
                -- Would use special widget for complex struct types
                return _DataTypeWidgetMap[ArrayStructType]

            elseif stype == StructCategory.MEMBER then
                return _DataTypeWidgetMap[MemberStructType]

            elseif stype == StructCategory.DICTIONARY then
                return _DataTypeWidgetMap[DictStructType]
            end
        end
    end

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    --- modify the target's definition
    function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
        if not Class.IsSubType(target, Frame) then
            error("The target class must be a sub type of Scorpio.UI.Frame", stack + 1)
        end
        Class.AddExtend(target, IConfigSubjectHandler)
        for i = 1, #self do
            _DataTypeWidgetMap[self[i]] = target
        end
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    property "AttributeTarget"  { default = AttributeTargets.Class }

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ (EnumType + StructType) * 1 }
    function __new(self, ...)
        return { ... }, true
    end
end)

------------------------------------------------------
-- Auto-Gen Config UI Panel
-------------------------------------------------------
--- The panel used to display the config node
__Sealed__()
class "ConfigPanel"             (function(_ENV)
    inherit "Frame"

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The node field map
    property "NodeFieldWidgets" { default = function() return {} end }

    --- The sub node config panel
    property "SubNodePanels"    { default = function() return {} end }

    --- Whether show the child config nodes
    property "ShowAllSubNodes"  { type = Boolean }

    --- The config node
    property "ConfigNode"       { type = ConfigNode }

    __Observable__()
    property "ConfigNodeName"   { type = String }

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    --- Refresh the config panel and record the current value
    function Begin(self)
        local node              = self.ConfigNode
        self.ConfigNodeName     = self.ConfigNode._Name -- Refresh when open
        self.__OriginValues     = node:GetValues()

        -- Start rendering
        local index             = 1
        local locale            = node._Addon._Locale

        --- Render the node field
        for name, ftype, desc, enableui, enablequickapply in node:GetFields() do
            if enableui then
                local widget    = __ConfigDataType__.GetWidgetType(ftype)
                print(name, ftype, widget)
                if widget then
                    local ui    = self.NodeFieldWidgets[name]

                    if not ui then
                        print("Create", widget, "for", name)
                        -- The field order can't be changed, so we don't need recycle them
                        ui      = widget("ConfigFieldWidget" .. name, self)
                        ui.ConfigNodeField          = node[name]
                        self.NodeFieldWidgets[name] = ui
                    end

                    ui:SetID(index)
                    if not enablequickapply then
                        ui.ConfigNodeFieldUnCommitValue = node[name]:GetValue() -- reset the commit value
                    end
                    index       = index + 1
                else
                    Warn("Lack the config ui widget for data type " .. tostring(ftype))
                end
            end
        end

        --- Render the sub config node panel
        for name, subnode in node:GetSubNodes() do
            -- The node that don't have a config panel and is enabled or not disabled when show all sub nodes
            if not _PanelMap[subnode] and (subnode.IsUIEnabled or self.ShowAllSubNodes and subnode.IsUIEnabled ~= false) then
                local ui        = self.SubNodePanels[name]

                if not ui then
                    ui                      = ConfigPanel("ConfigFieldPanel" .. name, self)
                    ui.ConfigNode           = subnode
                    ui.ShowAllSubNodes      = self.ShowAllSubNodes
                    self.SubNodePanels[name]= ui
                end

                ui:SetID(index)
                index           = index + 1

                ui:Begin()
            end
        end
    end

    --- Roll back to the old values
    function Rollback(self)
        self.ConfigNode:SetValues(self.__OriginValues)
        self.__OriginValues     = nil

        for _, panel in pairs(self.SubNodePanels) do
            panel:Rollback()
        end
    end

    --- Commit the selected value to config node fields
    function Commit(self)
        self.__OriginValues     = nil

        for _, ui in pairs(self.NodeFieldWidgets) do
            if not ui.ConfigNodeField.EnableQuickApply then
                ui.ConfigNodeField:SetValue(ui.ConfigNodeFieldUnCommitValue)
            end
        end

        for _, panel in pairs(self.SubNodePanels) do
            panel:Commit()
        end
    end

    --- Resets the config node field values
    function Reset(self)
        self.ConfigNode:SetValues{}
        self.__OriginValues     = nil

        for _, panel in pairs(self.SubNodePanels) do
            panel:Reset()
        end
    end
end)

--- The header of the config panel
__Sealed__() __Template__(Frame)
__ChildProperty__(ConfigPanel, "Header")
class "ConfigPanelHeader"       {
    HeaderText                  = FontString,
    UnderLine                   = Texture,

    --- The text of the header
    Text                        = {
        type                    = String,
        get                     = function(self)
            return self:GetChild("HeaderText"):GetText()
        end,
        set                     = function(self, text)
            self:GetChild("HeaderText"):SetText(text or "")
        end,
    },
}

------------------------------------------------------
-- Default Style
------------------------------------------------------
Style.UpdateSkin("Default",     {
    [ConfigPanel]               = {
        layoutManager           = Layout.VerticalLayoutManager{ MarginLeft = 100, MarginTop = 48, MarginBottom = 20, VSpacing = 32 },

        Header                  = {
            Text                = Wow.FromUIProperty("ConfigNodeName")
        },

        [IConfigSubjectHandler] = {
            Label               = {
                location        = { Anchor("TOPRIGHT", -10, -4, nil, "TOPLEFT") },
                justifyH        = "RIGHT",
                Text            = Wow.FromUIProperty("ConfigNodeField"):Map("x=>x.LocalizedField"),
            }
        },
    },
    [ConfigPanelHeader]         = {
        location                = { Anchor("TOPLEFT"), Anchor("TOPRIGHT") },
        height                  = 36,

        HeaderText              = {
            fontObject          = OptionsFontHighlight,
            location            = { Anchor("TOPLEFT", 16, -16) },
        },

        UnderLine               = {
            height              = 1,
            color               = Color(1, 1, 1, 0.2),
            location            = { Anchor("TOPLEFT", 0, -3, "HeaderText", "BOTTOMLEFT"), Anchor("RIGHT", -16, 0) },
        },
    }
})
