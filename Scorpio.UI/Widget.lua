--========================================================--
--             Scorpio UI Basic Widgets                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/01/09                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Widget"                "1.0.0"
--========================================================--

--- The basic type for all ui ojbect provide the name and parent-children support
__Sealed__() __Abstract__()
class "UIObject" (function(_ENV)
    ----------------------------------------------
    --                 Helpers                  --
    ----------------------------------------------
    local _NameMap              = setmetatable({}, META_WEAKKEY)
    local _ChildMap             = setmetatable({}, META_WEAKKEY)

    local _SetParent            = getRealMethodCache("SetParent")
    local _GetParent            = getRealMethodCache("GetParent")

    local validate              = Struct.ValidateValue

    ----------------------------------------------
    --              Static Methods              --
    ----------------------------------------------
    --- Gets the ui object with the full name
    __Static__() __Arguments__{ NEString }
    function FromName(name)
        local obj

        for str in name:gmatch("[^%.]+") do
            if not obj then
                obj             = validate(UI, _G[str], true)
            else
                local children  = _ChildMap[obj[0]]
                obj             = children and children[str]
            end
            if not obj then return end
        end

        return obj
    end

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    --- Gets the ui object's name or full name
    __Final__() function GetName(self, full)
        local name              = _NameMap[self[0]]
        if full then
            local globalUI      = _G[name]
            if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
                return name
            else
                local parent    = self:GetParent()
                local pname     = parent and parent:GetName(true)
                if pname then return pname .. "." .. name end
            end
        else
            return name
        end
    end

    --- Gets the parent of ui object
    __Final__() function GetParent(self)
        return GetProxyUI(_GetParent[getmetatable(self)](self))
    end

    --- Sets the ui object's name
    __Final__() __Arguments__{ NEString }
    function SetName(self, name)
        local oname             = _NameMap[self[0]]
        if oname == name then return end

        local globalUI          = _G[oname]
        if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
            error("Usage: UI:SetName(name) - UI with global name can't change its name", 2)
        end

        local parent            = self:GetParent()
        if parent then
            local pui           = parent[0]
            local children      = _ChildMap[pui]

            if children and children[name] then
                error("Usage: UI:SetName(name) - the name is used by another child", 2)
            end

            if not children then
                children        = {}
                _ChildMap[pui]  = children
            end

            children[oname]     = nil
            children[name]      = self
        end

        _NameMap[self[0]]       = name
    end

    --- Sets the ui object's parent
    __Final__() __Arguments__{ UI/nil }
    function SetParent(self, parent)
        local oparent           = self:GetParent()
        if oparent == parent or IsSameUI(oparent, parent) then return end

        local name              = _NameMap[self[0]]
        local setParent         = _SetParent[getmetatable(self)]

        if oparent then
            local pui           = oparent[0]
            if _ChildMap[pui] and _ChildMap[pui][name] == self then
                _ChildMap[pui][name] = nil
            end
        end

        if parent == nil then return setParent(self, nil) end

        local pui               = parent[0]
        local children          = _ChildMap[pui]

        if children and children[name] and children[name] ~= self then
            error("Usage : UI:SetParent([parent]) : parent has another child with the same name.", 2)
        end

        setParent(self, GetRawUI(parent))

        if not children then
            children            = {}
            _ChildMap[pui]      = children
        end

        children[name]          = self
    end

    --- Gets the children of the frame
    __Iterator__() function GetChildren(self)
        local children          = _ChildMap[self[0]]
        if children then
            for name, child in pairs(children) do
                yield(name, child)
            end
        end
    end

    --- Gets the child with the given name
    function GetChild(self, name)
        local children          = _ChildMap[self[0]]
        return children and children[child]
    end

    ----------------------------------------------
    --                 Dispose                  --
    ----------------------------------------------
    function Dispose(self)
        local ui                = self[0]
        local name              = _NameMap[ui]

        self:SetParent(nil)

        -- Dispose the children
        local children          = _ChildMap[ui]
        if children then
            for _, obj in pairs(children) do obj:Dispose() end
        end

        -- Clear it from the _G
        local globalUI          = _G[name]
        if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
            _G[name]            = nil
        end

        -- Clear register datas
        _NameMap[ui]            = nil
        _ChildMap[ui]           = nil
    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Arguments__{ NEString, UI/UIParent, Any * 0 }
    function __ctor(self, name, parent, ...)
        parent                  = parent[0]

        local children          = _ChildMap[parent]

        if not children then
            children            = {}
            _ChildMap[parent]   = children
        end

        children[name]          = self
        _NameMap[self[0]]       = name
    end

    __Arguments__{ NEString, UI/UIParent, Any * 0 }
    function __exist(cls, name, parent, ...)
        local children          = _ChildMap[parent[0]]
        local object            = children and children[name]

        if object then
            if getmetatable(object) == cls then
                return object
            else
                throw(("Usage : %s(name, parent, ...) - the parent already has a child named '%s'."):format(GetNamespaceName(cls), name))
            end
        end
    end

    ----------------------------------------------
    --               Meta-Method                --
    ----------------------------------------------
    __index                     = GetChild
end)

--- Region is the basic type for anything that can occupy an area of the screen
__Sealed__() __Abstract__()
class "Region" (function(_ENV)
    inherit "UIObject"

    local _GetPoint             = getRealMethodCache("GetPoint")

    ----------------------------------------------
    --                 Helpers                  --
    ----------------------------------------------
    local function GetPos(self, point, e)
        local x, y              = self:GetCenter()

        if strfind(point, "TOP") then
            y                   = self:GetTop()
        elseif strfind(point, "BOTTOM") then
            y                   = self:GetBottom()
        end

        if strfind(point, "LEFT") then
            x                   = self:GetLeft()
        elseif strfind(point, "RIGHT") then
            x                   = self:GetRight()
        end

        return x * e, y * e
    end

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    --- Gets the anchor point of the given index
    __Final__() function GetPoint(self, index)
        local p, f, r, x, y     = _GetPoint[getmetatable(self)](self, index)
        return p, GetProxyUI(f), r, x, y
    end

    --- Get the region object's location(Type: Anchors), the data is serializable, can be saved directly.
    -- You can also apply a data of Anchors to get a location based on the data's point, relativeTo and relativePoint settings.
    __Arguments__{}:Throwable()
    function GetLocation(self)
        local loc               = {}
        local parent            = self:GetParent()

        for i = 1, self:GetNumPoints() do
            local p, f, r, x, y = self:GetPoint(i)

            f                   = f or parent
            if IsSameUI(f, parent) then
                -- Don't save parent
                f               = nil
            elseif parent and IsSameUI(f:GetParent(), parent) then
                -- Save the brother's name
                f               = f:GetName()
            else
                local uname     = f:GetName(true)
                if not uname then throw("Usage: Region:GetLocation() - The System can't identify the relativeTo frame.") end
                f               = uname
            end

            if r == p then r    = nil end
            if x == 0 then x    = nil end
            if y == 0 then y    = nil end

            loc[i]              = Anchor(p, x, y, f, r)
        end

        return loc
    end

    __Arguments__{ Anchors }:Throwable()
    function GetLocation(self, oLoc)
        local loc               = {}
        local parent            = self:GetParent()

        for i, anchor in ipairs(oLoc) do
            local relativeTo    = anchor.relativeTo
            local relativeFrame

            if relativeTo then
                relativeFrame   = parent and parent:GetChild(relativeTo) or UIObject.FromName(relativeTo)

                if not relativeFrame then
                    throw("Usage: Region:GetLocation(accordingLoc) - The System can't identify the relativeTo frame.")
                end
            else
                relativeFrame   = parent
            end

            if relativeFrame then
                local e         = self:GetEffectiveScale()/UIParent:GetScale()
                local x, y      = GetPos(self, anchor.point, e)
                local rx, ry    = GetPos(relativeFrame, anchor.relativePoint or anchor.point, e)

                tinsert(loc, Anchor(anchor.point, (x-rx)/e, (y-ry)/e, relativeTo, anchor.relativePoint or anchor.point))
            end
        end

        return loc
    end

    --- Set the region object's location
    function SetLocation(self, loc)
        if #loc > 0 then
            local parent = self:GetParent()

            self:ClearAllPoints()
            for _, anchor in ipairs(loc) do
                local relativeTo = anchor.relativeTo

                if relativeTo then
                    relativeTo = parent and parent:GetChild(relativeTo) or UIObject.FromName(relativeTo)

                    if not relativeTo then
                        error("Usage: Region:SetLocation(loc) - The System can't identify the relativeTo frame.", 2)
                    end
                else
                    relativeTo = parent
                end

                if relativeTo then
                    self:SetPoint(anchor.point, relativeTo, anchor.relativePoint or anchor.point, anchor.x or 0, anchor.y or 0)
                end
            end
        end
    end

    ----------------------------------------------
    --                 Dispose                  --
    ----------------------------------------------
    function Dispose(self)
        self:ClearAllPoints()
        self:Hide()
    end
end)

--- LayeredRegion is an abstract UI type that groups together the functionality of layered graphical regions, specifically Textures and FontStrings.
__Sealed__() __Abstract__()
class "LayeredRegion" { Region }

--- Declare the class as basic widget class based on the Blz UI system
__Sealed__() class "__Widget__" (function(_ENV)
    extend "IApplyAttribute"

    local UI_PROTOTYPE          = {}

    local function onEventHandlerChanged(handler, self, name)
        if not handler.Hooked and self:HasScript(name) then
            handler.Hooked      = true

            self:HookScript(name, function(_, ...) return handler(self, ...) end)
        end
    end

    ----------------------------------------------
    --             Static Methods               --
    ----------------------------------------------
    __Static__() function Release()
        for name, ele in pairs(UI_PROTOTYPE) do
            pcall(ele.SetParent, ele, nil)ascx
        end

        wipe(UI_PROTOTYPE)
        UI_PROTOTYPE = nil

        collectgarbage()
    end

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    --- apply changes on the target
    -- @param   target                      the target
    -- @param   targettype                  the target type
    -- @param   manager                     the definition manager of the target
    -- @param   owner                       the target's owner
    -- @param   name                        the target's name in the owner
    -- @param   stack                       the stack level
    function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
        if not Class.IsSubType(target, UIObject) then return end

        local super             = Class.GetSuperClass(target)
        local frmtype           = Namespace.GetNamespaceName(target, true)

        self.Constructor        = self.Constructor or function(name, parent, ...)
            return CreateFrame(frmtype, nil, parent, ...)
        end

        local prototype         = self.Constructor(nil, frmtype ~= "Frame" and UI_PROTOTYPE[self.Parent or UI.Frame] or nil)
        UI_PROTOTYPE[target]    = prototype
        if Class.IsSubType(target, Region) then prototype:Hide() end

        -- Install Events
        if type(prototype.HasScript) == "function" then
            for _, evt in Enum.GetEnumValues(ScriptsType) do
                if prototype:HasScript(evt) and not Class.GetFeature(super, evt, true) then
                    __EventChangeHandler__(onEventHandlerChanged)
                    manager.event(evt)
                end
            end
        end

        -- Install Methods
        for name, func in pairs(getmetatable(prototype).__index) do
            manager.name        = func
        end

        -- Install Constructor
        manager.__new           = self.Constructor
    end

    ----------------------------------------------
    --                Property                  --
    ----------------------------------------------
    --- the attribute target
    property "AttributeTarget"  { set = false, default = AttributeTargets.Class }

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Arguments__{ Function/nil, (-UIObject)/nil }
    function __ctor(self, ctor, parent)
        self.Constructor        = ctor
        self.Parent             = parent
    end
end)

--- Frame is in many ways the most fundamental widget object. Other types of widget derivatives such as FontStrings, Textures and Animations can only be created attached to a Frame or other derivative of a Frame.
__Sealed__() __Widget__()
class "Frame" { Region }

--- Textures are visible areas descended from LayeredRegion, that display either a color block, a gradient, or a graphic raster taken from a .tga or .blp file
__Sealed__() __Widget__(
    function (name, parent, layer, inherits, sublevel)
        return parent:CreateTexture(nil, layer or "ARTWORK", inherits, sublevel or 0)
    end
)
class "Texture" { LayeredRegion }

--- MaskTextures are used to mask other textures
__Sealed__() __Widget__(
    function (name, parent, layer, inherits, sublevel)
        return parent:CreateMaskTexture(nil, layer or "ARTWORK", inherits, sublevel or 0)
    end
)
class "MaskTexture" { Texture }

--- FontStrings are one of the two types of Region that is visible on the screen. It draws a block of text on the screen using the characteristics in an associated FontObject.
__Sealed__() __Widget__(
    function (name, parent, layer, inherits, ...)
        return parent:CreateFontString(nil, layer or "OVERLAY", inherits or "GameFontNormal", ...)
    end
)
class "FontString" { LayeredRegion }

--- Lines are used to link two anchor points.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateLine(nil, ...)
    end
)
class "Line" { Texture }

------------------------------------------------------------
--                      Animation                         --
------------------------------------------------------------
--- An AnimationGroup is how various animations are actually applied to a region; this is how different behaviors can be run in sequence or in parallel with each other, automatically. When you pause an AnimationGroup, it tracks which of its child animations were playing and how far advanced they were, and resumes them from that point.
-- An Animation in a group has an order from 1 to 100, which determines when it plays; once all animations with order 1 have completed, including any delays, the AnimationGroup starts all animations with order 2.
-- An AnimationGroup can also be set to loop, either repeating from the beginning or playing backward back to the beginning. An AnimationGroup has an OnLoop handler that allows you to call your own code back whenever a loop completes. The :Finish() method stops the animation after the current loop has completed, rather than immediately.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateAnimationGroup(nil, ...)
    end
)
class "AnimationGroup" { UIObject }

--- The animation interface used to provide final methods for animations
__Sealed__() interface "IAnimation" (function(_ENV)

    _GetRegionParent            = getRealMethodCache("GetRegionParent")
    _GetTarget                  = getRealMethodCache("GetTarget")

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    --- Returns the Region object on which the animation operates
    -- @return System.Widget.Region     Reference to the Region object on which the animation operates
    __Final__() function GetRegionParent(self)
        return GetProxyUI(_GetRegionParent[getmetatable(self)](self))
    end

    --- Returns the target object on which the animation operates
    -- @return System.Widget.Region     Reference to the target object on which the animation operates
    __Final__() function GetTarget(self)
       return GetProxyUI(_GetTarget[getmetatable(self)](self))
    end
end)

--- Animations are used to change presentations or other characteristics of a frame or other region over time. The Animation object will take over the work of calling code over time, or when it is done, and tracks how close the animation is to completion.
-- The Animation type doesn't create any visual effects by itself, but it does provide an OnUpdate handler that you can use to support specialized time-sensitive behaviors that aren't provided by the transformations descended from Animations. In addition to tracking the passage of time through an elapsed argument, you can query the animation's progress as a 0-1 fraction to determine how you should set your behavior.
-- You can also change how the elapsed time corresponds to the progress by changing the smoothing, which creates acceleration or deceleration, or by adding a delay to the beginning or end of the animation.
-- You can also use an Animation as a timer, by setting the Animation's OnFinished script to trigger a callback and setting the duration to the desired time.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateAnimation("Animation", nil, ...)
    end, AnimationGroup
)
class "Animation" { UIObject }

--- Alpha is a type of animation that automatically changes the transparency level of its attached region as it progresses. You can set the degree by which it will change the alpha as a fraction; for instance, a change of -1 will fade out a region completely
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateAnimation("Alpha", nil, ...)
    end, AnimationGroup
)
class "Alpha" { Animation }

--- Path is an Animation type that combines multiple transitions into a single control path with multiple ControlPoints.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateAnimation("Path", nil, ...)
    end, AnimationGroup
)
class "Path" { Animation }

--- A special type that represent a point in a Path Animation.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateControlPoint(nil, ...)
    end, AnimationGroup
)
class "ControlPoint" { UIObject}

--- Rotation is an Animation that automatically applies an affine rotation to the region being animated. You can set the origin around which the rotation is being done, and the angle of rotation in either degrees or radians.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateAnimation("Rotation", nil, ...)
    end, AnimationGroup
)
class "Rotation" { Animation }

--- Scale is an Animation type that automatically applies an affine scalar transformation to the region being animated as it progresses. You can set both the multiplier by which it scales, and the point from which it is scaled.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateAnimation("Scale", nil, ...)
    end, AnimationGroup
)
class "Scale" { Animation }

--- LineScale is an Animation type inherit Scale.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateAnimation("LineScale", nil, ...)
    end, AnimationGroup
)
class "LineScale" { Animation }

--- Translation is an Animation type that applies an affine translation to its affected region automatically as it progresses.
__Sealed__() __Widget__(
    function (name, parent, ...)
        return parent:CreateAnimation("Translation", nil, ...)
    end, AnimationGroup
)
class "Translation" { Animation }

------------------------------------------------------------
--                    Frame Widgets                       --
------------------------------------------------------------
--- ArchaeologyDigSiteFrame is a frame that is used to display digsites. Any one frame can be used to display any number of digsites, called blobs. Each blob is a polygon with a border and a filling texture.
-- To draw a blob onto the frame use the DrawBlob function. this will draw a polygon representing the specified digsite. It seems that it's only possible to draw digsites where you can dig and is on the current map.
-- Changes to how the blobs should render will only affect newly drawn blobs. That means that if you want to change the opacity of a blob you must first clear all blobs using the DrawNone function and then redraw the blobs.
__Sealed__() __Widget__()
class "ArchaeologyDigSiteFrame" { Frame }

--- Button is the primary means for users to control the game and their characters.
__Sealed__() __Widget__()
class "Button" { Frame }

--- Browser is used to provide help helpful pages in the game
__Sealed__() __Widget__()
class "Browser" { Frame }

--- EditBoxes are used to allow the player to type text into a UI component.
__Sealed__() __Widget__()
class "EditBox" { Frame }

--- CheckButtons are a specialized form of Button; they maintain an on/off state, which toggles automatically when they are clicked, and additional textures for when they are checked, or checked while disabled.
__Sealed__() __Widget__()
class "CheckButton" { Button }

__Sealed__() __Widget__()
class "ColorSelect" { Frame }

--- Cooldown is a specialized variety of Frame that displays the little "clock" effect over abilities and buffs. It can be set with its running time, whether it should appear to "fill up" or "empty out", and whether or not there should be a bright edge where it's changing between dim and bright.
__Sealed__() __Widget__()
class "Cooldown" { Frame }

--- GameTooltips are used to display explanatory information relevant to a particular element of the game world.
__Sealed__() __Widget__(function(name, parent, ...)
        if select("#", ...) > 0 then
            return CreateFrame("GameTooltip", name, parent, ...)
        else
            return CreateFrame("GameTooltip", name, parent, "GameTooltipTemplate")
        end
    end)
class "GameTooltip" (function(_ENV)
    inherit "Frame"

    local _GetOwner             = _G.GameTooltip.GetOwner

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    COPPER_PER_SILVER           = _G.COPPER_PER_SILVER
    SILVER_PER_GOLD             = _G.SILVER_PER_GOLD

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    function GetOwner(self)
        return GetProxyUI(_GetOwner(self))
    end

    --- Get the left text of the given index line
    -- @param  index            number, between 1 and self:NumLines()
    -- @return string
    function GetLeftText(self, index)
        local name              = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name                    = name.."TextLeft"..index

        if type(_G[name]) == "table" and _G[name].GetText then
            return _G[name]:GetText()
        end
    end

    --- Get the right text of the given index line
    -- @param  index            number, between 1 and self:NumLines()
    -- @return string
    function GetRightText(self, index)
        local name              = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name                    = name.."TextRight"..index

        if type(_G[name]) == "table" and _G[name].GetText then
            return _G[name]:GetText()
        end
    end

    --- Set the left text of the given index line
    -- @param  index            number, between 1 and self:NumLines()
    -- @param  text             string
    -- @return string
    function SetLeftText(self, index, text)
        local name              = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name                    = name.."TextLeft"..index

        if type(_G[name]) == "table" and _G[name].GetText then
            return _G[name]:SetText(text)
        end
    end

    --- Set the right text of the given index line
    -- @param  index            number, between 1 and self:NumLines()
    -- @param  text             string
    -- @return string
    function SetRightText(self, index, text)
        local name              = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name                    = name.."TextRight"..index

        if type(_G[name]) == "table" and _G[name].GetText then
            return _G[name]:SetText(text)
        end
    end

    --- Get the texutre of the given index line
    -- @param  index            number, between 1 and self:NumLines()
    -- @return string
    function GetTexture(self, index)
        local name          = self:GetName()
        if not name or not index or type(index) ~= "number" then return end

        name                = name.."Texture"..index

        if type(_G[name]) == "table" and _G[name].GetTexture then
            return _G[name]:GetTexture()
        end
    end

    --- Get the money of the given index, default 1
    -- @param  index            number, between 1 and self:NumLines()
    -- @return number
    function GetMoney(self, index)
        local name              = self:GetName()

        index                   = index or 1
        if not name or not index or type(index) ~= "number" then return end

        name                    = name.."MoneyFrame"..index

        if type(_G[name]) == "table" then
            local gold          = strmatch((_G[name.."GoldButton"] and _G[name.."GoldButton"]:GetText()) or "0", "%d*") or 0
            local silver        = strmatch((_G[name.."SilverButton"] and _G[name.."SilverButton"]:GetText()) or "0", "%d*") or 0
            local copper        = strmatch((_G[name.."CopperButton"] and _G[name.."CopperButton"]:GetText()) or "0", "%d*") or 0

            return gold * COPPER_PER_SILVER * SILVER_PER_GOLD + silver * COPPER_PER_SILVER + copper
        end
    end

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    function Dispose(self)
        local name              = self:GetName()
        local index, chkName

        self:ClearLines()

        if name and _G[name] == self.UIElement then
            -- remove lefttext
            index               = 1

            while _G[name.."TextLeft"..index] do
                _G[name.."TextLeft"..index] = nil
                index           = index + 1
            end

            -- remove righttext
            index               = 1

            while _G[name.."TextRight"..index] do
                _G[name.."TextRight"..index] = nil
                index           = index + 1
            end

            -- remove texture
            index               = 1

            while _G[name.."Texture"..index] do
                _G[name.."Texture"..index] = nil
                index           = index + 1
            end

            -- remove self
            _G[name] = nil
        end
    end
end)

--- MessageFrames are used to present series of messages or other lines of text, usually stacked on top of each other.
__Sealed__() __Widget__()
class "MessageFrame" { Frame }

--- MovieFrames are used to play video files of some formats.
__Sealed__() __Widget__()
class "MovieFrame" { Frame }

--- QuestPOIFrames are used to draw blobs of interest points for quest on the world map
__Sealed__() __Widget__()
class "QuestPOIFrame" { Frame }

__Sealed__() __Widget__()
class "ScenarioPOIFrame" { Frame }

--- The interface used to provide the final methods for the Scroll Frame
__Sealed__() interface "IScrollFrame" (function(_ENV)
    _GetScrollChild             = getRealMethodCache("GetScrollChild")

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    --- Gets the frame scrolled by the scroll frame
    __Final__() function GetScrollChild(self)
        return GetProxyUI(_GetScrollChild[getmetatable(self)](self))
    end
end)

--- ScrollFrame is used to show a large body of content through a small window. The ScrollFrame is the size of the "window" through which you want to see the larger content, and it has another frame set as a "ScrollChild" containing the full content.
__Sealed__() __Widget__()
class "ScrollFrame" { Frame, IScrollFrame }

--- The most sophisticated control over text display is offered by SimpleHTML widgets. When its text is set to a string containing valid HTML markup, a SimpleHTML widget will parse the content into its various blocks and sections, and lay the text out. While it supports most common text commands, a SimpleHTML widget accepts an additional argument to most of these; if provided, the element argument will specify the HTML elements to which the new style information should apply, such as formattedText:SetTextColor("h2", 1, 0.3, 0.1) which will cause all level 2 headers to display in red. If no element name is specified, the settings apply to the SimpleHTML widget's default font.
__Sealed__() __Widget__()
class "SimpleHTML" { Frame }

--- Sliders are elements intended to display or allow the user to choose a value in a range.
__Sealed__() __Widget__()
class "Slider" { Frame }

--- StatusBars are similar to Sliders, but they are generally used for display as they don't offer any tools to receive user input.
__Sealed__() __Widget__()
class "StatusBar" { Frame }

------------------------------------------------------------
--                        Model                           --
------------------------------------------------------------
--- Model provide a rendering environment which is drawn into the backdrop of their frame, allowing you to display the contents of an .m2 file and set facing, scale, light and fog information, or run motions associated
__Sealed__() __Widget__()
class "Model" { Frame }

--- PlayerModels are the most commonly used subtype of Model frame. They expand on the Model type by adding functions to quickly set the model to represent a particular player or creature, by unitID or creature ID.
__Sealed__() __Widget__()
class "PlayerModel" { Model }

__Sealed__() __Widget__()
class "CinematicModel" { PlayerModel }

__Sealed__() __Widget__()
class "DressUpModel" { PlayerModel}

__Sealed__() __Widget__()
class "TabardModel" { PlayerModel}

------------------------------------------------------------
--                       Release                          --
------------------------------------------------------------
__Widget__.Release()