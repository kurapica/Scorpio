--========================================================--
--             Scorpio UI Basic Widgets                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/01/09                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Widget"                "1.0.0"
--========================================================--

do
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
    function Release()
        for name, ele in pairs(UI_PROTOTYPE) do
            pcall(ele.SetParent, ele, nil)
        end

        wipe(UI_PROTOTYPE)
        UI_PROTOTYPE            = nil

        InstallPrototype        = nil
        Release                 = nil
        collectgarbage()
    end

    function InstallPrototype(_ENV, par, ui)
        local target            = Environment.GetNamespace(_ENV)
        local super             = Class.GetSuperClass(target)
        local frmtype           = Namespace.GetNamespaceName(target, true)
        local new               = Class.GetMetaMethod(target, "__new") or function(_, name, parent, ...)
            return CreateFrame(frmtype, nil, parent, ...)
        end

        if not (ui and type(ui) == "table" and ui.GetObjectType and ui:GetObjectType() == frmtype) then
            ui                  = nil
        end

        if not ui then
            ui                  = new(target, nil, frmtype ~= "Frame" and UI_PROTOTYPE[par or UI.Frame] or nil)
            UI_PROTOTYPE[target]= ui
        end

        if Class.IsSubType(target, LayoutFrame) then ui:Hide() end

        -- Install Events
        if type(ui.HasScript) == "function" then
            for _, evt in Enum.GetEnumValues(ScriptsType) do
                if ui:HasScript(evt) and not Class.GetFeature(super, evt, true) then
                    __EventChangeHandler__(onEventHandlerChanged)
                    _ENV.event(evt)
                end
            end
        end

        -- Install Methods
        for name, func in pairs(getmetatable(ui).__index) do
            _ENV[name]          = func
        end

        -- Install Constructor
        _ENV.__new              = new
    end
end

--- The basic type for all ui ojbect provide the name and parent-children support
__Sealed__() __Abstract__() class "UIObject"(function(_ENV)
    ----------------------------------------------
    --                 Helpers                  --
    ----------------------------------------------
    local _NameMap              = setmetatable({}, META_WEAKKEY)
    local _ChildMap             = setmetatable({}, META_WEAKKEY)

    local _SetParent            = getRealMethodCache("SetParent")
    local _GetParent            = getRealMethodCache("GetParent")
    local _GetNew               = getRealMetaMethodCache("__new")

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
    __Iterator__() function GetChilds(self)
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
        return children and children[name]
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
    __Final__() __Arguments__{ NEString, UI/UIParent, Any * 0 }
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

    __Final__() __Arguments__{ NEString, UI/UIParent, Any * 0 }
    function __new(cls, name, parent, ...)
        local self              = _GetNew[cls](cls, name, parent, ...)
        parent                  = parent[0]

        local children          = _ChildMap[parent]

        if not children then
            children            = {}
            _ChildMap[parent]   = children
        end

        children[name]          = self
        _NameMap[self[0]]       = name

        return self
    end

    ----------------------------------------------
    --               Meta-Method                --
    ----------------------------------------------
    __index                     = GetChild
end)

--- LayoutFrame is the basic type for anything that can occupy an area of the screen
__Sealed__()__Abstract__()class"LayoutFrame"(function(_ENV)
    inherit "UIObject"

    local _GetPoint             = getRealMethodCache("GetPoint")

    ----------------------------------------------
    --                 Helpers                  --
    ----------------------------------------------
    local function GetPos(self, point, e)
        local x, y              = self:GetCenter()
        return (strfind(point, "LEFT") and self:GetLeft() or strfind(point, "RIGHT")  and self:GetRight()  or x) * e,
               (strfind(point, "TOP")  and self:GetTop()  or strfind(point, "BOTTOM") and self:GetBottom() or y) * e
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
    __Final__() __Arguments__{}:Throwable()
    function GetLocation(self)
        local loc               = {}
        local parent            = self:GetParent()

        for i = 1, self:GetNumPoints() do
            local p, f, r, x, y = self:GetPoint(i)

            if IsSameUI(f, parent) then
                -- Don't save parent
                f               = nil
            else
                -- Save the brother's name or its full name
                f               = f:GetName(not IsSameUI(f:GetParent(), parent))
                if not f then throw("Usage: LayoutFrame:GetLocation() - The System can't identify the relativeTo frame's name") end
            end

            if r == p then r    = nil end
            if x == 0 then x    = nil end
            if y == 0 then y    = nil end

            loc[i]              = Anchor(p, x, y, f, r)
        end

        return loc
    end

    __Final__() __Arguments__{ Anchors }:Throwable()
    function GetLocation(self, oLoc)
        local loc               = {}
        local parent            = self:GetParent()

        for i, anchor in ipairs(oLoc) do
            local relativeTo    = anchor.relativeTo
            local relativeFrame

            if relativeTo then
                relativeFrame   = parent and UIObject.GetChild(parent, relativeTo) or UIObject.FromName(relativeTo)

                if not relativeFrame then
                    throw("Usage: LayoutFrame:GetLocation(accordingLoc) - The System can't identify the relativeTo frame.")
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
    __Final__() __Arguments__{ Anchors }:Throwable()
    function SetLocation(self, loc)
        if #loc > 0 then
            local parent = self:GetParent()

            self:ClearAllPoints()
            for _, anchor in ipairs(loc) do
                local relativeTo = anchor.relativeTo

                if relativeTo then
                    relativeTo = parent and UIObject.GetChild(parent, relativeTo) or UIObject.FromName(relativeTo)

                    if not relativeTo then
                        throw("Usage: LayoutFrame:SetLocation(loc) - The System can't identify the relativeTo frame")
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

--- Frame is in many ways the most fundamental widget object. Other types of widget derivatives such as FontStrings, Textures and Animations can only be created attached to a Frame or other derivative of a Frame.
__Sealed__() class "Frame"                  (function(_ENV) inherit(LayoutFrame) InstallPrototype(_ENV) end)

--- FontStrings are one of the two types of LayoutFrame that is visible on the screen. It draws a block of text on the screen using the characteristics in an associated FontObject.
__Sealed__() class "FontString"             (function(_ENV) inherit(LayoutFrame)__new = function (_, name, parent, layer, inherits, ...) return parent:CreateFontString(nil, layer or "OVERLAY", inherits or "GameFontNormal", ...) end InstallPrototype(_ENV, nil, _G.ZoneTextString) end)

--- Textures are visible areas descended from LayoutFrame, that display either a color block, a gradient, or a graphic raster taken from a .tga or .blp file
__Sealed__() class "Texture"                (function(_ENV) inherit(LayoutFrame)__new = function (_, name, parent, layer, inherits, sublevel) return parent:CreateTexture(nil, layer or "ARTWORK", inherits, sublevel or 0) end InstallPrototype(_ENV, nil, _G.WorldStateScoreFrameSeparator) end)

--- MaskTextures are used to mask other textures
__Sealed__() class "MaskTexture"            (function(_ENV) inherit(Texture)    __new = function (_, name, parent, layer, inherits, sublevel) return parent:CreateMaskTexture(nil, layer or "ARTWORK", inherits, sublevel or 0) end InstallPrototype(_ENV) end)

--- Lines are used to link two anchor points.
__Sealed__() class "Line"                   (function(_ENV) inherit(UIObject)   __new = function (_, name, parent, ...) return parent:CreateLine(nil, ...) end InstallPrototype(_ENV) end)

------------------------------------------------------------
--                      Animation                         --
------------------------------------------------------------
--- An AnimationGroup is how various animations are actually applied to a region; this is how different behaviors can be run in sequence or in parallel with each other, automatically. When you pause an AnimationGroup, it tracks which of its child animations were playing and how far advanced they were, and resumes them from that point.
-- An Animation in a group has an order from 1 to 100, which determines when it plays; once all animations with order 1 have completed, including any delays, the AnimationGroup starts all animations with order 2.
-- An AnimationGroup can also be set to loop, either repeating from the beginning or playing backward back to the beginning. An AnimationGroup has an OnLoop handler that allows you to call your own code back whenever a loop completes. The :Finish() method stops the animation after the current loop has completed, rather than immediately.
__Sealed__() class "AnimationGroup"         (function(_ENV) inherit(UIObject)   __new = function (_, name, parent, ...) return parent:CreateAnimationGroup(nil, ...) end InstallPrototype(_ENV) end)

--- Animations are used to change presentations or other characteristics of a frame or other region over time. The Animation object will take over the work of calling code over time, or when it is done, and tracks how close the animation is to completion.
-- The Animation type doesn't create any visual effects by itself, but it does provide an OnUpdate handler that you can use to support specialized time-sensitive behaviors that aren't provided by the transformations descended from Animations. In addition to tracking the passage of time through an elapsed argument, you can query the animation's progress as a 0-1 fraction to determine how you should set your behavior.
-- You can also change how the elapsed time corresponds to the progress by changing the smoothing, which creates acceleration or deceleration, or by adding a delay to the beginning or end of the animation.
-- You can also use an Animation as a timer, by setting the Animation's OnFinished script to trigger a callback and setting the duration to the desired time.
__Sealed__() class "Animation"              (function(_ENV) inherit(UIObject)   __new = function (_, name, parent, ...) return parent:CreateAnimation("Animation", nil, ...) end InstallPrototype(_ENV, AnimationGroup) end)

--- Alpha is a type of animation that automatically changes the transparency level of its attached region as it progresses. You can set the degree by which it will change the alpha as a fraction; for instance, a change of -1 will fade out a region completely
__Sealed__() class "Alpha"                  (function(_ENV) inherit(Animation)  __new = function (_, name, parent, ...) return parent:CreateAnimation("Alpha", nil, ...) end InstallPrototype(_ENV, AnimationGroup) end)

--- Path is an Animation type that combines multiple transitions into a single control path with multiple ControlPoints.
__Sealed__() class "Path"                   (function(_ENV) inherit(Animation)  __new = function (_, name, parent, ...) return parent:CreateAnimation("Path", nil, ...) end InstallPrototype(_ENV, AnimationGroup) end)

--- A special type that represent a point in a Path Animation.
__Sealed__() class "ControlPoint"           (function(_ENV) inherit(UIObject)   __new = function (_, name, parent, ...) return parent:CreateControlPoint(nil, ...) end InstallPrototype(_ENV, Path) end)

--- Rotation is an Animation that automatically applies an affine rotation to the region being animated. You can set the origin around which the rotation is being done, and the angle of rotation in either degrees or radians.
__Sealed__() class "Rotation"               (function(_ENV) inherit(Animation)  __new = function (_, name, parent, ...) return parent:CreateAnimation("Rotation", nil, ...) end InstallPrototype(_ENV, AnimationGroup) end)

--- Scale is an Animation type that automatically applies an affine scalar transformation to the region being animated as it progresses. You can set both the multiplier by which it scales, and the point from which it is scaled.
__Sealed__() class "Scale"                  (function(_ENV) inherit(Animation)  __new = function (_, name, parent, ...) return parent:CreateAnimation("Scale", nil, ...) end InstallPrototype(_ENV, AnimationGroup) end)

--- LineScale is an Animation type inherit Scale.
__Sealed__() class "LineScale"              (function(_ENV) inherit(Scale)      __new = function (_, name, parent, ...) return parent:CreateAnimation("LineScale", nil, ...) end InstallPrototype(_ENV, AnimationGroup) end)

--- Translation is an Animation type that applies an affine translation to its affected region automatically as it progresses.
__Sealed__() class "Translation"            (function(_ENV) inherit(Animation)  __new = function (_, name, parent, ...) return parent:CreateAnimation("Translation", nil, ...) end InstallPrototype(_ENV, AnimationGroup) end)

--- LineTranslation is an Animation type that applies an affine translation to its affected Line
__Sealed__() class "LineTranslation"        (function(_ENV) inherit(Translation)__new = function (_, name, parent, ...) return parent:CreateAnimation("LineTranslation", nil, ...) end InstallPrototype(_ENV, AnimationGroup) end)

------------------------------------------------------------
--                    Frame Widgets                       --
------------------------------------------------------------
-- ABANDON: ArchaeologyDigSiteFrame, Browser, Checkout, FogOfWarFrame, MovieFrame, QuestPOIFrame, ScenarioPOIFrame, UnitPositionFrame, GameTooltip

--- Button is the primary means for users to control the game and their characters.
__Sealed__() class "Button"                 (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.SpellBookFrameTabButton1) end)

--- CheckButtons are a specialized form of Button; they maintain an on/off state, which toggles automatically when they are clicked, and additional textures for when they are checked, or checked while disabled.
__Sealed__() class "CheckButton"            (function(_ENV) inherit(Button) InstallPrototype(_ENV, nil, _G.SpellBookSkillLineTab1) end)

__Sealed__() class "ColorSelect"            (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.ColorPickerFrame) end)

--- Cooldown is a specialized variety of Frame that displays the little "clock" effect over abilities and buffs. It can be set with its running time, whether it should appear to "fill up" or "empty out", and whether or not there should be a bright edge where it's changing between dim and bright.
__Sealed__() class "Cooldown"               (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.ActionButton1Cooldown) end)

--- EditBoxes are used to allow the player to type text into a UI component.
__Sealed__() class "EditBox"                (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.BagItemSearchBox) end)

--- MessageFrames are used to present series of messages or other lines of text, usually stacked on top of each other.
__Sealed__() class "MessageFrame"           (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.UIErrorsFrame) end)

--- ScrollFrame is used to show a large body of content through a small window. The ScrollFrame is the size of the "window" through which you want to see the larger content, and it has another frame set as a "ScrollChild" containing the full content.
__Sealed__() class "ScrollFrame"            (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.ReputationListScrollFrame) end)

--- The most sophisticated control over text display is offered by SimpleHTML widgets. When its text is set to a string containing valid HTML markup, a SimpleHTML widget will parse the content into its various blocks and sections, and lay the text out. While it supports most common text commands, a SimpleHTML widget accepts an additional argument to most of these; if provided, the element argument will specify the HTML elements to which the new style information should apply, such as formattedText:SetTextColor("h2", 1, 0.3, 0.1) which will cause all level 2 headers to display in red. If no element name is specified, the settings apply to the SimpleHTML widget's default font.
__Sealed__() class "SimpleHTML"             (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.OpenMailBodyText) end)

--- Sliders are elements intended to display or allow the user to choose a value in a range.
__Sealed__() class "Slider"                 (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.OpacitySliderFrame) end)

--- StatusBars are similar to Sliders, but they are generally used for display as they don't offer any tools to receive user input.
__Sealed__() class "StatusBar"              (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.PlayerFrameHealthBar) end)

------------------------------------------------------------
--                        Model                           --
------------------------------------------------------------
--- Model provide a rendering environment which is drawn into the backdrop of their frame, allowing you to display the contents of an .m2 file and set facing, scale, light and fog information, or run motions associated
__Sealed__() class "Model"                  (function(_ENV) inherit(Frame) InstallPrototype(_ENV) end)

--- ModelScene
__Sealed__() class "ModelScene"             (function(_ENV) inherit(Frame) InstallPrototype(_ENV, nil, _G.AzeriteLevelUpToast and _G.AzeriteLevelUpToast.IconEffect) end)

--- PlayerModels are the most commonly used subtype of Model frame. They expand on the Model type by adding functions to quickly set the model to represent a particular player or creature, by unitID or creature ID.
__Sealed__() class "PlayerModel"            (function(_ENV) inherit(Model) InstallPrototype(_ENV, nil, _G.CharacterModelFrame) end)

__Sealed__() class "CinematicModel"         (function(_ENV) inherit(PlayerModel) InstallPrototype(_ENV) end)

__Sealed__() class "DressUpModel"           (function(_ENV) inherit(PlayerModel) InstallPrototype(_ENV, nil, _G.DressUpModel) end)

__Sealed__() class "TabardModel"            (function(_ENV) inherit(PlayerModel) InstallPrototype(_ENV, nil, _G.TabardModel) end)

------------------------------------------------------------
--                       Release                          --
------------------------------------------------------------
Release()