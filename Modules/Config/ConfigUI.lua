--========================================================--
--                Scorpio SavedVariable Config UI System  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/06/25                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config.UI"               "1.0.0"
--========================================================--

local _PanelMap                 = {}
local _ConfigNode               = {}

------------------------------------------------------
-- Scorpio Extension
------------------------------------------------------
class "Scorpio" (function(_ENV)
    local _PanelCount           = 0

    --- Start using the config panel for the addon
    function UseConfigPanel(self)
        local config            = self._Config

        if _PanelMap[config] then return self end

        _PanelCount             = _PanelCount + 1
        ConfigPanel("Scorpio_Config_Node_Panel_" .. _PanelCount, InterfaceOptionsFrame, config, self._Name)
        return self
    end

    --- Bind the config node to a sub category panel
    __Arguments__{ NEString, ConfigNode }:Throwable()
    function UseSubConfigPanel(self, name, node)
        if _PanelMap[node] then return self end

        local config            = addon._Config

        if not _PanelMap[config] then
            throw("Usage: _Addon:UseSubConfigPanel(name, configNode) - The _Addon:UseConfigPanel() must be called first")
        end

        _PanelCount             = _PanelCount + 1
        ConfigPanel("Scorpio_Config_Node_Panel_" .. _PanelCount, InterfaceOptionsFrame, node, name, addon._Name)
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
interface "IConfigNodeFieldHandler" (function(_ENV)
    -----------------------------------------------------------
    --                    abstract method                    --
    -----------------------------------------------------------
    --- Binding the ui element with a config node field's info
    __Abstract__()
    function SetConfigNodeField(self, configSubject, name, dataType, desc, locale)
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
            error("The target class must be a sub type of Frame", stack + 1)
        end

        Class.AddExtend(target, IConfigNodeFieldHandler)
        _DataTypeWidgetMap[self[1]] = target
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    property "AttributeTarget"  { default = AttributeTargets.Class }

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ EnumType + StructType }
    function __new(self, dataType)
        return { dataType }, true
    end
end)


------------------------------------------------------
-- Auto-Gen Config UI Panel
------------------------------------------------------
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
    --                  Method                  --
    ----------------------------------------------
    --- This method will run when the player clicks "okay" in the Interface Options.
    function okay(self)
        print("okay")
    end

    --- This method will run when the player clicks "cancel" in the Interface Options.
    function cancel(self)
        print("cancel")
    end

    --- This method will run when the player clicks "defaults".
    function default(self)
        print("default")
    end

    --- This method will run when the Interface Options frame calls its OnShow function and after defaults
    function refresh(self)
        local node              = _ConfigNode[self]
        local locale            = node._Addon._Locale
        local panel             = self:GetChild("ScrollFrame"):GetChild("ScrollChild")
        local index             = 1

        --- Add the data type elements
        for name, ftype, default, desc in node:GetFields() do
            local widget        = getWidgetType(ftype)
            if not self[index] or getmetatable(self[index] ~= widget then
                if self[index] then
                    -- recycle
                end

                local ui    = widget("ConfigFieldWidget" .. index, panel)
                ui:SetID(index)
                ui:SetConfigNodeField(node[name], name, ftype, desc, locale)
            end
            index               = index + 1
        end

        --- Add sub config nodes as group box
        for name, nodes in self:GetSubNodes() do

        end
    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Template__{
        ScrollFrame             = FauxScrollFrame
    }
    function __ctor(self)
        return InterfaceOptions_AddCategory(self)
    end

    __Arguments__{ NEString, UI, ConfigNode, NEString, NEString/nil }
    function __new(_, name, parent, node, cateName, cateParent)
        if _PanelMap[node] then throw("The node already has a config panel binded") end

        local frame             = CreateFrame("Frame", nil, parent)
        frame.name              = cateName
        frame.parent            = cateParent
        _ConfigNode[frame]      = node
        _PanelMap[node]         = frame
        return frame
    end
end)

------------------------------------------------------
-- Default Style
------------------------------------------------------
Style.UpdateSkin("Default",     {
    [ConfigPanel]               = {
        ScrollFrame             = {
            location            = {
                Anchor("TOPLEFT", 0, -8),
                Anchor("BOTTOMRIGHT", - 32, 8)
            },
            scrollBarHideable   = true,

            ScrollChild         = {
                layoutManager   = Scorpio.UI.Layout.VerticalLayoutManager()
            },
        }
    }
})
