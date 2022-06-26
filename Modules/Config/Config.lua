--========================================================--
--                Scorpio SavedVariable Config System     --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/05/02                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config"                  "1.0.0"
--========================================================--

namespace "Scorpio.Config"

Environment.RegisterGlobalNamespace(Scorpio.Config)

------------------------------------------------------
-- Config Node Field Data Bidirectional Binding
------------------------------------------------------
__Sealed__()
class "__ConfigTypeHandler__" (function(_ENV)
    extend "IAttachAttribute"

    local _ConfigTypeUIMap      = {}
    local clone                 = Toolset.clone

    -----------------------------------------------------------
    --                     static method                     --
    -----------------------------------------------------------
    __Static__()
    function GetConfigTypeUIMap(type)
        if _ConfigTypeUIMap[type] then
            return unpack(_ConfigTypeUIMap[type])

        elseif Enum.Validate(type) then
            -- The default ui type for all enum types
            return GetConfigTypeUIMap(EnumType)

        elseif Struct.Validate(type) then
            local stype         = Struct.GetStructCategory(type)

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

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    --- attach data on the target
    function AttachAttribute(self, target, targettype, owner, name, stack)
        -- Check the arguments
        if type(self[2]) ~= "function" and not Class.GetMethod(target, self[2], true) then
            error("The set method not existed in the target class", stack + 1)
        end

        if type(self[3]) ~= "function" and not Class.GetMethod(target, self[3], true) then
            error("The get method not existed in the target class", stack + 1)
        end

        if not Event.Validate(Class.GetFeature(target, self[4])) then
            error("The event not existed in the target class", stack + 1)
        end

        -- Register the config type UI map
        _ConfigTypeUIMap[self[1]] = {
            type                = target,
            set                 = self[2],
            get                 = self[3],
            event               = self[4]
        }
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    property "AttributeTarget"  { default = AttributeTargets.Class }

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ EnumType + StructType, NEString + Function, NEString + Function, NEString }
    function __new(self, configType, setMethod, getMethod, event)
        if setMethod == getMethod then
            throw("The setMethod and getMethod can't be the same")
        end

        return { configType, setMethod, getMethod, event }, true
    end
end)


-- Handle the config node field data UI display and update
class "ConfigTypeHandler" (function(_ENV)

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ ConfigNode, NEString }
    function __new(self, node, field)
        return { configType, setMethod, getMethod, event }, true
    end
end)

