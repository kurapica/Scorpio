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
class "Scorpio"                 (function(_ENV)
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
    -----------------------------------------------------------
    --                       property                        --
    -----------------------------------------------------------
    --- The config subject
    __Final__() __Observable__():AsInheritable()
    property "ConfigNodeField"  { type = ConfigNode, handler = "SetConfigNodeField" }

    -----------------------------------------------------------
    --                    abstract method                    --
    -----------------------------------------------------------
    --- Binding the ui element with a config node field's info,
    -- also can be used to clear the binding if configSubject is nil
    __Abstract__()
    function SetConfigNodeField(self, configSubject)
    end
end)

--- The bidirectional binding between the config node field and widget
__Sealed__()
class "__ConfigDataType__"      (function(_ENV)
    extend "IInitAttribute"

    local _DataTypeWidgetMap    = {}

    -----------------------------------------------------------
    --                     static method                     --
    -----------------------------------------------------------
    --- Gets the widget type for the data type
    __Static__()
    function GetWidgetType(dataType)
        return _DataTypeWidgetMap[dataType]
    end

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    --- modify the target's definition
    function InitDefinition(self, target, targettype, definition, owner, name, stack)
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

    local function getWidgetType(dataType)
        if Enum.Validate(ftype) then
            return __ConfigDataType__.GetWidgetType(EnumType)

        elseif Struct.Validate(ftype) then
            local widgetType    = __ConfigDataType__.GetWidgetType(dataType)

            local stype         = Struct.GetStructCategory(ftype)
            if stype == StructCategory.CUSTOM then
                local btype     = Struct.GetBaseStruct(type)
                if btype then return GetConfigTypeUIMap(btype) end

                -- Use String as default
                return GetConfigTypeUIMap(String)

            elseif stype == StructCategory.ARRAY then
                return GetConfigTypeUIMap(ArrayStructType)

            elseif stype == StructCategory.MEMBER then
                return GetConfigTypeUIMap(MemberStructType)

            elseif stype == StructCategory.DICTIONARY then
                return GetConfigTypeUIMap(DictStructType)
            end
        end
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- Whether show the child config nodes
    property "ShowAllSubNodes"  { type = Boolean }

    --- The config node
    property "ConfigNode"       { type = ConfigNode }

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    --- Refresh the config panel and record the current value
    function Begin(self)
        self.__OriginValues     = self.ConfigNode:GetValues()
        self.__CurrValues       = self.ConfigNode:GetValues()

        local index             = 1

        --- Add the data type elements
        for name, ftype, desc, enableui, enablequickapply in node:GetFields() do
            if enableui ~= false then
                local widget                = getWidgetType(ftype)
                if widget then
                    local ui                = panel[index]
                    if not ui then
                        -- The field order can't be changed, so we don't need recycle them
                        ui                  = widget("ConfigFieldWidget" .. index, panel)
                        ui:SetID(index)
                        ui.ConfigNodeField  = node[name]

                        panel[index]        = ui
                    end
                    index                   = index + 1
                elseif enableui then
                    Warn("Lack the config ui widget for data type " .. tostring(ftype))
                end
            end
        end

        --- Add sub config nodes as group box
        for name, subnode in node:GetSubNodes() do
            -- The node that don't have a config panel and is enabled or not disabled when show all sub nodes
            if not _PanelMap[subnode] and (subnode.IsUIEnabled or self.ShowAllSubNodes and subnode.IsUIEnabled ~= false) then
                local ui                    = panel[index]
                if not ui then
                    ui                      = GroupBox("ConfigFieldWidget" .. index, panel)
                    ui:SetID(index)
                    panel[index]            = ui
                end
                Style[ui].header.text       = locale[name]
                showNodeFields(self, ui, subnode, locale)
                index                       = index + 1
            end
        end
    end

    --- Roll back to the old values
    function Rollback(self)
        self.ConfigNode:SetValues(self.__OriginValues)
        self.__OriginValues     = nil
        self.__CurrValues       = nil
    end

    --- Commit the selected value to config node fields
    function Commit(self)
        self.ConfigNode:SetValues(self.__CurrValues)
        self.__OriginValues     = nil
        self.__CurrValues       = nil
    end

    --- Resets the config node field values
    function Reset(self)
        self.ConfigNode:SetValues{}
        self.__OriginValues     = nil
        self.__CurrValues       = nil
    end
end)

------------------------------------------------------
-- Default Style
------------------------------------------------------
Style.UpdateSkin("Default",     {
    [ConfigPanel]               = {
        layoutManager           = Scorpio.UI.Layout.VerticalLayoutManager{ MarginLeft = 100, MarginTop = 20, MarginBottom = 20, VSpacing = 6 }
    }
})
