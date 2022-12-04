--========================================================--
--              Scorpio UI Widget Properties              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/01/09                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Property"              "1.0.0"
--========================================================--

------------------------------------------------------------
--                         Helper                         --
------------------------------------------------------------
do
    local defaultFadeoutOption  = FadeoutOption{ duration = 1 }
    local orgSetTexCoord        = Texture.SetTexCoord

    function fadeIn(self)
        local fade              = self[fadeOut]
        self:SetAlpha(fade and fade.start or 1)
    end

    __Async__() function fadeOut(self)
        local fade              = self[fadeOut] or defaultFadeoutOption
        local target            = GetTime()
        local duration          = fade.duration or 1
        local stop              = fade.stop or 0
        local start             = fade.start or 1

        -- Check the delay
        if fade.delay and fade.delay > 0 then
            target              = target + fade.delay
            while GetTime() < target and not self:IsMouseOver() do
                Next()
            end
        end

        local current           = target

        target                  = target + duration

        while current < target and not self:IsMouseOver() do
            self:SetAlpha(stop + (start - stop) * (target - current) / duration)

            Next()
            current             = GetTime()
        end

        if self:IsMouseOver() then
            self:SetAlpha(start)
        elseif current >= target and fade.autohide then
            if pcall(self.Hide, self) then
                self:SetAlpha(start)
            end
        end
    end

    __Async__() function animateTexCoords(self, settings)
        self.__AnimateTexCoords = ((self.__AnimateTexCoords or 0) + 1) % 10000

        if settings then
            -- initialize everything
            local task          = self.__AnimateTexCoords
            local frame         = 1
            local throttle      = settings.throttle
            local total         = throttle
            local numColumns    = floor(settings.textureWidth/settings.frameWidth)
            local numRows       = floor(settings.textureHeight/settings.frameHeight)
            local columnWidth   = settings.frameWidth/settings.textureWidth
            local rowHeight     = settings.frameHeight/settings.textureHeight
            local numFrames     = settings.numFrames
            local prev          = GetTime()

            while self.__AnimateTexCoords == task do
                if total > throttle then
                    local adv   = floor(total / throttle)
                    while ( frame + adv > numFrames ) do
                        frame   = frame - numFrames
                    end
                    frame       = frame + adv
                    total       = 0
                    local left  = mod(frame-1, numColumns)*columnWidth
                    local right = left + columnWidth
                    local bottom= ceil(frame/numColumns)*rowHeight
                    local top   = bottom - rowHeight
                    self:SetTexCoord(left, right, top, bottom)
                end

                Next()

                local now       = GetTime()
                total           = total + now - prev
                prev            = now
            end
        end
    end

    function hookSetTexCoord(self, ...)
        local currDegree        = self.__RotateDegree or 0
        if currDegree > 0 then setRotateDegree(self, 0) end
        orgSetTexCoord(self, ...)
        return currDegree > 0 and setRotateDegree(self, currDegree)
    end

    function setRotateDegree(self, degree)
        degree                  = degree or 0
        self.__RotateDegree     = degree

        if degree == 0 then
            if self.__OriginTexCoord then
                orgSetTexCoord(self, unpack( self.__OriginTexCoord))
                if self:GetNumPoints() <= 1 then
                    self:SetSize(self.__OriginWidth, self.__OriginHeight)
                end

                self.__OriginTexCoord   = nil
                self.__OriginWidth      = nil
                self.__OriginHeight     = nil
            end

            return
        end

        self.SetTexCoord        = hookSetTexCoord -- A simple hook

        local radian            = math.rad(degree or 0)

        if not self.__OriginTexCoord then
            self.__OriginTexCoord = { self:GetTexCoord() }
            self.__OriginWidth  = math.max(self:GetWidth() or 0, 1)
            self.__OriginHeight = math.max(self:GetHeight() or 0, 1)
        end

        while radian < 0 do radian = radian + 2 * math.pi end
        radian                  = radian % (2 * math.pi)

        local angle             = radian % (math.pi / 2)

        local left              = self.__OriginTexCoord[1]
        local top               = self.__OriginTexCoord[2]
        local right             = self.__OriginTexCoord[7]
        local bottom            = self.__OriginTexCoord[8]

        local dy                = self.__OriginWidth * math.cos(angle) * math.sin(angle) * (bottom-top) / self.__OriginHeight
        local dx                = self.__OriginHeight * math.cos(angle) * math.sin(angle) * (right - left) / self.__OriginWidth
        local ox                = math.cos(angle) * math.cos(angle) * (right-left)
        local oy                = math.cos(angle) * math.cos(angle) * (bottom-top)

        local newWidth          = self.__OriginWidth*math.cos(angle) + self.__OriginHeight*math.sin(angle)
        local newHeight         = self.__OriginWidth*math.sin(angle) + self.__OriginHeight*math.cos(angle)

        local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy

        if radian < math.pi / 2 then
            -- 0 ~ 90
            ULx                 = left - dx
            ULy                 = bottom - oy

            LLx                 = right - ox
            LLy                 = bottom + dy

            URx                 = left + ox
            URy                 = top - dy

            LRx                 = right + dx
            LRy                 = top + oy
        elseif radian < math.pi then
            -- 90 ~ 180
            URx                 = left - dx
            URy                 = bottom - oy

            ULx                 = right - ox
            ULy                 = bottom + dy

            LRx                 = left + ox
            LRy                 = top - dy

            LLx                 = right + dx
            LLy                 = top + oy

            newHeight, newWidth = newWidth, newHeight
        elseif radian < 3 * math.pi / 2 then
            -- 180 ~ 270
            LRx                 = left - dx
            LRy                 = bottom - oy

            URx                 = right - ox
            URy                 = bottom + dy

            LLx                 = left + ox
            LLy                 = top - dy

            ULx                 = right + dx
            ULy                 = top + oy
        else
            -- 270 ~ 360
            LLx                 = left - dx
            LLy                 = bottom - oy

            LRx                 = right - ox
            LRy                 = bottom + dy

            ULx                 = left + ox
            ULy                 = top - dy

            URx                 = right + dx
            URy                 = top + oy

            newHeight, newWidth = newWidth, newHeight
        end

        orgSetTexCoord(self, ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
        if self:GetNumPoints() <= 1 then
            self:SetSize(newWidth, newHeight)
        end
    end

    function getRotateDegree(self)
        return self.__RotateDegree or 0
    end
end

------------------------------------------------------------
--                      LayoutFrame                       --
------------------------------------------------------------
do
    --- the frame's transparency value(0-1)
    UI.Property         {
        name            = "Alpha",
        type            = ColorFloat,
        require         = { LayoutFrame, Line },
        default         = 1,
        get             = function(self) return self:GetAlpha() end,
        set             = function(self, alpha) self:SetAlpha(alpha) end,
    }

    --- the frame's fadeout settings
    UI.Property         {
        name            = "Fadeout",
        type            = FadeoutOption + Boolean,
        require         = { LayoutFrame, Line },
        default         = false,
        set             = function(self, fade)
            self        = UI.GetWrapperUI(self)

            if fade then
                if fade ~= true then self[fadeOut] = fade else fade = nil end
                self:SetAlpha(fade and fade.start or 1)

                self.OnLeave    = self.OnLeave + fadeOut
                self.OnEnter    = self.OnEnter + fadeIn
            else
                fade            = self[fadeOut]
                self:SetAlpha(fade and fade.start or 1)

                self[fadeOut]   = nil
                self.OnLeave    = self.OnLeave - fadeOut
                self.OnEnter    = self.OnEnter - fadeIn
            end
        end,
    }

    --- the height of the LayoutFrame
    UI.Property         {
        name            = "Height",
        type            = Number,
        require         = { LayoutFrame, Line },
        secure          = true,
        get             = function(self) return self:GetHeight() end,
        set             = function(self, height) self:SetHeight(height) end,
        override        = { "Size" },
    }

    --- Whether ignore parent's alpha settings
    UI.Property         {
        name            = "IgnoreParentAlpha",
        type            = Boolean,
        require         = { LayoutFrame, Line },
        default         = false,
        get             = function(self) return self:IsIgnoringParentAlpha() end,
        set             = function(self, flag) self:SetIgnoreParentAlpha(flag) end,
    }

    --- Whether ignore parent's scal settings
    UI.Property         {
        name            = "IgnoreParentScale",
        type            = Boolean,
        require         = { LayoutFrame, Line },
        default         = false,
        secure          = true,
        get             = function(self) return self:IsIgnoringParentScale() end,
        set             = function(self, flag) self:SetIgnoreParentScale(flag) end,
    }

    --- Whether set all points to the parent
    UI.Property         {
        name            = "SetAllPoints",
        type            = Boolean,
        require         = LayoutFrame,
        secure          = true,
        set             = function(self, flag) self:ClearAllPoints() if flag then self:SetPoint("TOPLEFT") self:SetPoint("BOTTOMRIGHT") end end,
        clear           = function(self) self:ClearAllPoints() end,
        override        = { "Location" }, -- So it can override the Location settings
    }

    --- the location of the LayoutFrame
    UI.Property         {
        name            = "Location",
        type            = Anchors,
        require         = LayoutFrame,
        secure          = true,
        get             = function(self) return LayoutFrame.GetLocation(GetProxyUI(self)) end,
        set             = function(self, loc)   LayoutFrame.SetLocation(GetProxyUI(self), loc) end,
        clear           = function(self) self:ClearAllPoints() end,
        override        = { "SetAllPoints" }, -- So it can override the setAllPoints settings
    }

    --- the frame's scale factor or the scale animation's setting
    UI.Property         {
        name            = "Scale",
        type            = PositiveNumber,
        require         = LayoutFrame,
        default         = 1,
        secure          = true,
        get             = function(self) return self:GetScale() end,
        set             = function(self, scale) self:SetScale(scale) end,
    }

    --- The size of the LayoutFrame
    UI.Property         {
        name            = "Size",
        type            = Size,
        require         = { LayoutFrame, Line },
        secure          = true,
        get             = function(self) return Size(self:GetSize()) end,
        set             = function(self, size) self:SetSize(size.width, size.height) end,
        override        = { "Height", "Width" },
    }

    --- wheter the LayoutFrame is shown or not.
    UI.Property         {
        name            = "Visible",
        type            = Boolean,
        require         = { LayoutFrame, Line },
        default         = true,
        secure          = true,
        get             = function(self) return self:IsShown() and true or false end,
        set             = function(self, visible) self:SetShown(visible) end,
    }

    --- the width of the LayoutFrame
    UI.Property         {
        name            = "Width",
        type            = Number,
        require         = { LayoutFrame, Line },
        secure          = true,
        get             = function(self) return self:GetWidth() end,
        set             = function(self, width) self:SetWidth(width) end,
        override        = { "Size" },
    }

    --- The pass through buttons
    if Frame.SetPassThroughButtons then
    UI.Property         {
        name            = "SetPassThroughButtons",
        type            = struct { String },
        require         = Button,
        nilable         = true,
        secure          = true,
        set             = function(self, val) if val then self:SetPassThroughButtons(unpack(val)) else self:SetPassThroughButtons(nil) end end
    } end
end

------------------------------------------------------------
--                      LayeredFrame                      --
------------------------------------------------------------
do
    --- the layer at which the LayeredFrame's graphics are drawn relative to others in its frame
    UI.Property         {
        name            = "DrawLayer",
        type            = DrawLayer,
        require         = { Texture, FontString, ModelScene, Line },
        default         = "ARTWORK",
        get             = function(self) return self:GetDrawLayer() end,
        set             = function(self, layer) return self:SetDrawLayer(layer) end,
    }

    --- the color shading for the LayeredFrame's graphics
    UI.Property         {
        name            = "VertexColor",
        type            = ColorType,
        require         = { Texture, FontString, Line },
        default         = Color.WHITE,
        get             = Texture.GetVertexColor and function(self) return Color(self:GetVertexColor()) end,
        set             = function(self, color) self:SetVertexColor(color.r, color.g, color.b, color.a) end,
    }

    UI.Property         {
        name            = "SubLevel",
        type            = Integer,
        require         = { Texture, FontString, Line },
        default         = 0,
        depends         = { "DrawLayer" },
        get             = function(self) return select(2, self:GetDrawLayer()) end,
        set             = function(self, sublevel) self:SetDrawLayer(self:GetDrawLayer(), sublevel) end,
    }
end

------------------------------------------------------------
--                       FontFrame                        --
------------------------------------------------------------
do
    FONT_TYPES  = { EditBox, FontString, MessageFrame, SimpleHTML }

    --- the font settings
    UI.Property         {
        name            = "Font",
        type            = FontType,
        require         = FONT_TYPES,
        get             = function(self)
            local filename, fontHeight, flags   = self:GetFont()
            local outline, monochrome           = "NONE", false
            if flags then
                if flags:find("THICKOUTLINE") then
                    outline         = "THICK"
                elseif flags:find("OUTLINE") then
                    outline         = "NORMAL"
                end
                if flags:find("MONOCHROME") then
                    monochrome      = true
                end
            end
            return FontType(filename, fontHeight, outline, monochrome)
        end,
        set             = function(self, font)
            local flags

            if font.outline then
                if font.outline == "NORMAL" then
                    flags           = "OUTLINE"
                elseif font.outline == "THICK" then
                    flags           = "THICKOUTLINE"
                end
            end
            if font.monochrome then
                if flags then
                    flags           = flags..",MONOCHROME"
                else
                    flags           = "MONOCHROME"
                end
            end
            return self:SetFont(font.font, font.height, flags)
        end,
        override        = { "FontObject" },
    }

    --- the Font object
    UI.Property         {
        name            = "FontObject",
        type            = FontObject,
        require         =  { EditBox, FontString, MessageFrame },
        get             = function(self) return self:GetFontObject() end,
        set             = function(self, fontObject) self:SetFontObject(fontObject) end,
        override        = { "Font" },
    }

    --- the fontstring's horizontal text alignment style
    UI.Property         {
        name            = "JustifyH",
        type            = JustifyHType,
        require         = FONT_TYPES,
        default         = "CENTER",
        get             = function(self) return self:GetJustifyH() end,
        set             = function(self, justifyH) self:SetJustifyH(justifyH) end,
    }

    --- the fontstring's vertical text alignment style
    UI.Property         {
        name            = "JustifyV",
        type            = JustifyVType,
        require         = FONT_TYPES,
        default         = "MIDDLE",
        get             = function(self) return self:GetJustifyV() end,
        set             = function(self, justifyV) self:SetJustifyV(justifyV) end,
    }

    --- the color of the font's text shadow
    UI.Property         {
        name            = "ShadowColor",
        type            = ColorType,
        require         = FONT_TYPES,
        default         = Color(0, 0, 0, 0),
        get             = function(self) return Color(self:GetShadowColor()) end,
        set             = function(self, color) self:SetShadowColor(color.r, color.g, color.b, color.a) end,
    }

    --- the offset of the fontstring's text shadow from its text
    UI.Property         {
        name            = "ShadowOffset",
        type            = Dimension,
        require         = FONT_TYPES,
        default         = Dimension(0, 0),
        get             = function(self) return Dimension(self:GetShadowOffset()) end,
        set             = function(self, offset) self:SetShadowOffset(offset.x, offset.y) end,
    }

    --- the fontstring's amount of spacing between lines
    UI.Property         {
        name            = "Spacing",
        type            = Number,
        require         = FONT_TYPES,
        default         = 0,
        get             = function(self) return self:GetSpacing() end,
        set             = function(self, spacing) self:SetSpacing(spacing) end,
    }

    --- the fontstring's default text color
    UI.Property         {
        name            = "TextColor",
        type            = ColorType,
        require         =  { EditBox, FontString, MessageFrame },
        default         = Color(1, 1, 1),
        get             = function(self) return Color(self:GetTextColor()) end,
        set             = function(self, color) self:SetTextColor(color.r, color.g, color.b, color.a) end,
    }

    --- the fontstring's default text color
    UI.Property         {
        name            = "TextColor",
        type            = ColorType,
        require         = SimpleHTML,
        default         = Color(1, 1, 1),
        set             = function(self, color)
            self:SetTextColor("h1", color.r, color.g, color.b, color.a)
            self:SetTextColor("h2", color.r, color.g, color.b, color.a)
            self:SetTextColor("h3", color.r, color.g, color.b, color.a)
            self:SetTextColor("p", color.r, color.g, color.b, color.a)
        end,
    }

    --- the Font object
    UI.Property         {
        name            = "FontObject",
        type            = FontObject,
        require         = SimpleHTML,
        set             = function(self, fontObject)
            self:SetFontObject("h1", fontObject)
            self:SetFontObject("h2", fontObject)
            self:SetFontObject("h3", fontObject)
            self:SetFontObject("p", fontObject)
        end,
        override        = { "Font" },
    }

    --- whether the text wrap will be indented
    UI.Property         {
        name            = "Indented",
        type            = Boolean,
        require         = FONT_TYPES,
        default         = false,
        get             = function(self) return self:GetIndentedWordWrap() end,
        set             = function(self, flag) self:SetIndentedWordWrap(flag) end,
    }
end

------------------------------------------------------------
--                        Texture                         --
--                                                        --
------------------------------------------------------------
do
    local _Texture_Deps = { "Color", "Atlas", "FileID", "File" }
    local _HWrapMode    = setmetatable({}, META_WEAKKEY)
    local _VWrapMode    = setmetatable({}, META_WEAKKEY)
    local _FilterMode   = setmetatable({}, META_WEAKKEY)

    --- the atlas setting of the texture
    UI.Property         {
        name            = "Atlas",
        type            = AtlasType,
        require         = { Texture, Line },
        get             = function(self) return AtlasType(self:GetAtlas()) end,
        set             = function(self, val) self:SetAtlas(val.atlas, val.useAtlasSize) end,
        clear           = function(self) self:SetAtlas(nil) end,
        override        = { "Color", "FileID", "File" },
    }

    --- the alpha mode of the texture
    UI.Property         {
        name            = "AlphaMode",
        type            = AlphaMode,
        require         = { Texture, Line },
        default         = "BLEND",
        get             = function(self) return self:GetBlendMode() end,
        set             = function(self, val) self:SetBlendMode(val) end,
        depends         = _Texture_Deps,
    }

    --- the texture's color
    UI.Property         {
        name            = "Color",
        type            = ColorType,
        require         = { Texture, Line },
        set             = function(self, color) self:SetColorTexture(color.r, color.g, color.b, color.a) end,
        clear           = function(self) self:SetTexture(nil) end,
        override        = { "Atlas", "FileID", "File" },
    }

    --- whether the texture image should be displayed with zero saturation
    UI.Property         {
        name            = "Desaturated",
        type            = Boolean,
        require         = { Texture, Line },
        default         = false,
        get             = function(self) return self:IsDesaturated() end,
        set             = function(self, val) self:SetDesaturated(val) end,
        depends         = _Texture_Deps,
    }

    --- The texture's desaturation
    UI.Property         {
        name            = "Desaturation",
        type            = ColorFloat,
        require         = { Texture, Line, Model },
        default         = 0,
        get             = function(self) return self:GetDesaturation() end,
        set             = function(self, val) self:SetDesaturation(val) end,
        depends         = _Texture_Deps,
    }

    --- The wrap behavior specifying what should appear when sampling pixels with an x coordinate outside the (0, 1) region of the texture coordinate space.
    UI.Property         {
        name            = "HWrapMode",
        type            = WrapMode,
        require         = { Texture, Line },
        default         = "CLAMP",
        get             = function(self) return _HWrapMode[self] or "CLAMP" end,
        set             = function(self, val) if val == "CLAMP" then val = nil end _HWrapMode[self] = val end,
    }

    --- Wrap behavior specifying what should appear when sampling pixels with a y coordinate outside the (0, 1) region of the texture coordinate space
    UI.Property         {
        name            = "VWrapMode",
        require         = { Texture, Line },
        type            = WrapMode,
        default         = "CLAMP",
        get             = function(self) return _VWrapMode[self] or "CLAMP" end,
        set             = function(self, val) if val == "CLAMP" then val = nil end _VWrapMode[self] = val end,
    }

    --- Texture filtering mode to use
    UI.Property         {
        name            = "FilterMode",
        require         = { Texture, Line },
        type            = FilterMode,
        default         = "LINEAR",
        get             = function(self) return _FilterMode[self] or "LINEAR" end,
        set             = function(self, val) if val == "LINEAR" then val = nil end _FilterMode[self] = val end,
    }

    --- Whether the texture is horizontal tile
    UI.Property         {
        name            = "HorizTile",
        type            = Boolean,
        require         = { Texture, Line },
        default         = false,
        get             = function(self) return self:GetHorizTile() end,
        set             = function(self, val) self:SetHorizTile(val) end,
    }

    --- Whether the texture is vertical tile
    UI.Property         {
        name            = "VertTile",
        require         = { Texture, Line },
        type            = Boolean,
        default         = false,
        get             = function(self) return self:GetVertTile() end,
        set             = function(self, val) self:SetVertTile(val) end,
    }

    --- The gradient color shading for the texture
    UI.Property         {
        name            = "Gradient",
        type            = GradientType,
        require         = { Texture, Line },
        set             = Scorpio.IsRetail and function(self, val) self:SetGradient(val.orientation, val.mincolor, val.maxcolor) end
                        or function(self, val) self:SetGradient(val.orientation, val.mincolor.r, val.mincolor.g, val.mincolor.b, val.maxcolor.r, val.maxcolor.g, val.maxcolor.b) end,
        clear           = Scorpio.IsRetail and function(self) self:SetGradient("HORIZONTAL", Color.WHITE, Color.WHITE) end
                        or function(self) self:SetGradient("HORIZONTAL", 1, 1, 1, 1, 1, 1) end,
        depends         = _Texture_Deps,
    }

    --- The gradient color shading (including opacity in the gradient) for the texture
    if Texture.SetGradientAlpha then
    UI.Property         {
        name            = "GradientAlpha",
        type            = GradientType,
        require         = { Texture, Line },
        set             = function(self, val) self:SetGradientAlpha(val.orientation, val.mincolor.r, val.mincolor.g, val.mincolor.b, val.mincolor.a, val.maxcolor.r, val.maxcolor.g, val.maxcolor.b, val.maxcolor.a) end,
        clear           = function(self) self:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 1, 1, 1, 1, 1) end,
        depends         = _Texture_Deps,
    } end

    --- whether the texture object loads its image file in the background
    UI.Property         {
        name            = "NonBlocking",
        type            = Boolean,
        require         = { Texture, Line },
        default         = false,
        get             = Texture.GetNonBlocking
                        and function(self) return self:GetNonBlocking() end
                        or  function(self) return self:IsBlockingLoadRequested() end,
        set             = Texture.SetNonBlocking
                        and function(self, val) self:SetNonBlocking(val) end
                        or  function(self, val) self:SetBlockingLoadsRequested(val) end,
    }

    --- The rotation of the texture
    if Texture.SetRotation then
    UI.Property         {
        name            = "Rotation",
        type            = Number,
        require         = { Texture, Line, Cooldown },
        default         = 0,
        get             = Texture.GetRotation and function(self) return self:GetRotation() end,
        set             = function(self, val) self:SetRotation(val) end,
        depends         = _Texture_Deps,
    } end

    --- whether snap to pixel grid
    UI.Property         {
        name            = "SnapToPixelGrid",
        type            = Boolean,
        require         = { Texture, Line },
        default         = false,
        get             = function(self) return self:IsSnappingToPixelGrid() end,
        set             = function(self, val) self:SetSnapToPixelGrid(val) end,
        depends         = _Texture_Deps,
    }

    --- the texel snapping bias
    UI.Property         {
        name            = "TexelSnappingBias",
        type            = Number,
        require         = { Texture, Line },
        default         = 0,
        get             = function(self) return self:GetTexelSnappingBias() end,
        set             = function(self, val) self:SetTexelSnappingBias(val) end,
        depends         = _Texture_Deps,
    }

    --- The corner coordinates for scaling or cropping the texture image
    UI.Property         {
        name            = "TexCoords",
        type            = RectType,
        require         = { Texture, Line },
        get             = function(self) local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = self:GetTexCoord() if URx then return { ULx = ULx, ULy = ULy, LLx = LLx, LLy = LLy, URx = URx, URy = URy, LRx = LRx, LRy = LRy } elseif ULx then return { left = ULx, right = ULy, top = LLx, bottom = LLy } end end,
        set             = function(self, val) if not val.ULx then self:SetTexCoord(val.left, val.right, val.top, val.bottom) else self:SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy) end end,
        clear           = function(self) self:SetTexCoord(0, 1, 0, 1) end,
        depends         = { "Color", "Atlas", "FileID", "File" },
    }

    --- The texture file id
    UI.Property         {
        name            = "FileID",
        type            = Number,
        require         = { Texture, Line },
        get             = function(self) return self:GetTextureFileID() end,
        set             = function(self, val) self:SetTexture(val, _HWrapMode[self], _VWrapMode[self], _FilterMode[self]) end,
        clear           = function(self) self:SetTexture(nil) end,
        override        = { "Atlas", "Color", "File" },
        depends         = { "HWrapMode", "VWrapMode", "FilterMode" },
    }

    --- The texture file path
    UI.Property         {
        name            = "File",
        type            = String + Number,
        require         = { Texture, Line },
        get             = function(self) return self:GetTextureFilePath() end,
        set             = function(self, val) self:SetTexture(val, _HWrapMode[self], _VWrapMode[self], _FilterMode[self]) end,
        clear           = function(self) self:SetTexture(nil) end,
        override        = { "Atlas", "Color", "FileID" },
        depends         = { "HWrapMode", "VWrapMode", "FilterMode" },
    }

    --- The mask file path
    UI.Property         {
        name            = "Mask",
        type            = String,
        require         = { Texture, Line },
        set             = function(self, val) self:SetMask(val) end,
        nilable         = true,
        depends         = _Texture_Deps,
    }

    --- The vertex offset of upperleft corner
    UI.Property         {
        name            = "VertexOffsetUpperLeft",
        type            = Dimension,
        require         = { Texture, Line },
        get             = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.UpperLeft)) end,
        set             = function(self, val) self:SetVertexOffset(VertexIndexType.UpperLeft, val.x, val.y) end,
        clear           = function(self) self:SetVertexOffset(VertexIndexType.UpperLeft, 0, 0) end,
        depends         = _Texture_Deps,
    }

    --- The vertex offset of lowerleft corner
    UI.Property         {
        name            = "VertexOffsetLowerLeft",
        type            = Dimension,
        require         = { Texture, Line },
        get             = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.LowerLeft)) end,
        set             = function(self, val) self:SetVertexOffset(VertexIndexType.LowerLeft, val.x, val.y) end,
        clear           = function(self) self:SetVertexOffset(VertexIndexType.LowerLeft, 0, 0) end,
        depends         = _Texture_Deps,
    }

    --- The vertex offset of upperright corner
    UI.Property         {
        name            = "VertexOffsetUpperRight",
        type            = Dimension,
        require         = { Texture, Line },
        get             = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.UpperRight)) end,
        set             = function(self, val) self:SetVertexOffset(VertexIndexType.UpperRight, val.x, val.y) end,
        clear           = function(self) self:SetVertexOffset(VertexIndexType.UpperRight, 0, 0) end,
        depends         = _Texture_Deps,
    }

    --- The vertex offset of lowerright corner
    UI.Property         {
        name            = "VertexOffsetLowerRight",
        type            = Dimension,
        require         = { Texture, Line },
        get             = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.LowerRight)) end,
        set             = function(self, val) self:SetVertexOffset(VertexIndexType.LowerRight, val.x, val.y) end,
        clear           = function(self) self:SetVertexOffset(VertexIndexType.LowerRight, 0, 0) end,
        depends         = _Texture_Deps,
    }

    --- The animation texcoords
    UI.Property         {
        name            = "AnimateTexCoords",
        type            = AnimateTexCoords,
        require         = Texture,
        nilable         = true,
        set             = animateTexCoords,
    }

    --- The mask texture
    for i = 0, 3 do
        UI.Property     {
            name        = "MaskTexture" .. (i == 0 and "" or i),
            type        = MaskTexture,
            childtype   = MaskTexture,
            require     = { Frame, Texture },
            clear       = function(self, mask) return self.RemoveMaskTexture and self:RemoveMaskTexture(mask) end,
            set         = function(self, mask) return self.AddMaskTexture and self:AddMaskTexture(mask) end,
        }
    end

    --- Rotate degree
    UI.Property         {
        name            = "RotateDegree",
        type            = Number,
        require         = Texture,
        default         = 0,
        get             = getRotateDegree,
        set             = setRotateDegree,
    }
end

------------------------------------------------------------
--                          Line                          --
------------------------------------------------------------
do
    local function toAnchor(self, p, f, x, y)
        f               = UIObject.GetRelativeUIName(self, f)
        if f == false then return nil end
        return Anchor(p, x, y, f)
    end

    local function fromAnchor(self, anchor)
        return anchor.point, UIObject.GetRelativeUI(self, anchor.relativeTo) or self:GetParent(), anchor.x or 0, anchor.y or 0
    end

    --- the start point of the line
    UI.Property         {
        name            = "StartPoint",
        type            = Anchor,
        require         = Line,
        set             = function(self, anchor) self:SetStartPoint(fromAnchor(self, anchor)) end,
        get             = function(self) return toAnchor(self, self:GetStartPoint()) end,
    }

    --- the end point of the line
    UI.Property         {
        name            = "EndPoint",
        type            = Anchor,
        require         = Line,
        set             = function(self, anchor) self:SetEndPoint(fromAnchor(self, anchor)) end,
        get             = function(self) return toAnchor(self, self:GetEndPoint()) end,
    }

    --- the thickness of the line
    UI.Property         {
        name            = "Thickness",
        type            = Number,
        require         = Line,
        default         = 1,
        set             = function(self, val) self:SetThickness(val) end,
        get             = function(self) return self:GetThickness() end,
    }
end

------------------------------------------------------------
--                       FontString                       --
------------------------------------------------------------
do
    --- The alpha gradient
    UI.Property         {
        name            = "AlphaGradient",
        type            = AlphaGradientType,
        require         = FontString,
        set             = function(self, val) self:SetAlphaGradient(val.start, val.length) end,
        clear           = function(self) self:SetAlphaGradient(0, 10^6) end,
    }

    --- the max lines of the text
    UI.Property         {
        name            = "MaxLines",
        type            = Number,
        require         = FontString,
        default         = 0,
        set             = function(self, val) self:SetMaxLines(val) end,
        get             = function(self) return self:GetMaxLines() end,
    }

    --- whether long lines of text will wrap within or between words
    UI.Property         {
        name            = "NonSpaceWrap",
        type            = Boolean,
        require         = FontString,
        default         = false,
        set             = function(self, val) self:SetNonSpaceWrap(val) end,
        get             = function(self) return self:CanNonSpaceWrap() end,
    }

    --- the text to be displayed in the font string
    UI.Property         {
        name            = "Text",
        type            = String,
        require         = { FontString, Button, EditBox, SimpleHTML },
        default         = "",
        set             = function(self, val) self:SetText(val) end,
        get             = function(self) return self:GetText() end,
    }

    --- the height of the text displayed in the font string
    UI.Property         {
        name            = "TextHeight",
        type            = Number,
        require         = FontString,
        set             = function(self, val) self:SetTextHeight(val) end,
        get             = function(self) return self:GetLineHeight() end,
    }

    --- whether long lines of text in the font string can wrap onto subsequent lines
    UI.Property         {
        name            = "WordWrap",
        type            = Boolean,
        require         = FontString,
        default         = true,
        set             = function(self, val) self:SetWordWrap(val) end,
        get             = function(self) return self:CanWordWrap() end,
    }
end

------------------------------------------------------------
--                      Animation                         --
------------------------------------------------------------
do
    --- the playing state of the animation or animation group
    UI.Property         {
        name            = "Playing",
        type            = Boolean,
        require         = { Animation, AnimationGroup },
        default         = false,
        set             = function(self, val) if val then return self:IsPlaying() or self:Play() else return self:IsPlaying() and self:Stop() end end,
        get             = function(self) return self:IsPlaying() end,
    }

    --- looping type for the animation group: BOUNCE , NONE  , REPEAT
    UI.Property         {
        name            = "Looping",
        type            = AnimLoopType,
        require         = AnimationGroup,
        default         = "NONE",
        set             = function(self, val) self:SetLooping(val) end,
        get             = function(self) return self:GetLooping() end,
    }

    --- Whether to final alpha is set
    UI.Property         {
        name            = "ToFinalAlpha",
        type            = Boolean,
        require         = AnimationGroup,
        default         = false,
        set             = function(self, val) self:SetToFinalAlpha(val) end,
        get             = function(self) return self:IsSetToFinalAlpha() end,
    }

    --- The speed multiplier
    if AnimationGroup.SetAnimationSpeedMultiplier then
    UI.Property         {
        name            = "SpeedMultiplier",
        type            = Number,
        require         = AnimationGroup,
        default         = 1,
        set             = function(self, val) self:SetAnimationSpeedMultiplier(val) end,
        get             = function(self) return self:GetAnimationSpeedMultiplier() end,
    } end

    --- Time for the animation to progress from start to finish (in seconds)
    UI.Property         {
        name            = "Duration",
        type            = Number,
        require         = Animation,
        default         = 0,
        set             = function(self, val) self:SetDuration(val) end,
        get             = function(self) return self:GetDuration() end,
    }

    --- Time for the animation to delay after finishing (in seconds)
    UI.Property         {
        name            = "EndDelay",
        type            = Number,
        require         = Animation,
        set             = function(self, val) self:SetEndDelay(val) end,
        get             = function(self) return self:GetEndDelay() end,
    }

    --- Position at which the animation will play relative to others in its group (between 0 and 100)
    UI.Property         {
        name            = "Order",
        type            = Integer,
        require         = { Animation, ControlPoint },
        set             = function(self, val) self:SetOrder(val) end,
        get             = function(self) return self:GetOrder() end,
    }

    --- The smooth progress of the animation
    UI.Property         {
        name            = "SmoothProgress",
        type            = Number,
        require         = Animation,
        set             = function(self, val) self:SetSmoothProgress(val) end,
        get             = function(self) return self:GetSmoothProgress() end,
    }

    --- Type of smoothing for the animation, IN, IN_OUT, NONE, OUT
    UI.Property         {
        name            = "Smoothing",
        type            = AnimSmoothType,
        require         = Animation,
        default         = "NONE",
        set             = function(self, val) self:SetSmoothing(val) end,
        get             = function(self) return self:GetSmoothing() end,
    }

    --- Amount of time the animation delays before its progress begins (in seconds)
    UI.Property         {
        name            = "StartDelay",
        type            = Number,
        require         = Animation,
        default         = 0,
        set             = function(self, val) self:SetStartDelay(val) end,
        get             = function(self) return self:GetStartDelay() end,
    }

    --- the animation's amount of alpha (opacity) start from
    UI.Property         {
        name            = "FromAlpha",
        type            = ColorFloat,
        require         = Alpha,
        default         = 0,
        set             = function(self, val) self:SetFromAlpha(val) end,
        get             = function(self) return self:GetFromAlpha() end,
    }

    --- the animation's amount of alpha (opacity) end to
    UI.Property         {
        name            = "ToAlpha",
        type            = ColorFloat,
        require         = Alpha,
        default         = 0,
        set             = function(self, val) self:SetToAlpha(val) end,
        get             = function(self) return self:GetToAlpha() end,
    }

    --- The curve type of the path
    UI.Property         {
        name            = "Curve",
        type            = AnimCurveType,
        require         = Path,
        default         = "NONE",
        set             = Path.SetCurve
                        and function(self, val) self:SetCurve(val) end
                        or  function(self, val) self:SetCurveType(val) end,
        get             = Path.GetCurve
                        and function(self) return self:GetCurve() end
                        or  function(self) return self:GetCurveType() end,
    }

    --- the offsets settings
    UI.Property         {
        name            = "Offset",
        type            = Dimension,
        require         = { ControlPoint, Translation },
        set             = function(self, val) self:SetOffset(val.x, val.y) end,
        get             = function(self) return Dimension(self:GetOffset()) end,
    }

    --- the animation's rotation amount (in degrees)
    UI.Property         {
        name            = "Degrees",
        type            = Number,
        require         = Rotation,
        get             = function(self) return self:GetDegrees() end,
        set             = function(self, val) self:SetDegrees(val) end,
    }

    --- the rotation animation's origin point
    UI.Property         {
        name            = "Origin",
        type            = AnimOriginType,
        require         = { Rotation, Scale },
        get             = function(self) return AnimOriginType(self:GetOrigin()) end,
        set             = function(self, val) self:SetOrigin(val.point, val.x, val.y) end,
    }

    --- the animation's rotation amount (in radians)
    UI.Property         {
        name            = "Radians",
        type            = Number,
        require         = Rotation,
        get             = function(self) return self:GetRadians() end,
        set             = function(self, val) self:SetRadians(val) end,
    }

    --- the animation's scaling factors
    UI.Property         {
        name            = "KeepScale",
        type            = Dimension,
        require         = Scale,
        default         = Dimension(1, 1),
        set             = function(self, val) self:SetScale(val.x, val.y) end,
        get             = function(self) return Dimension(self:GetScale()) end,
    }

    --- the animation's scale amount that start from
    UI.Property         {
        name            = "FromScale",
        type            = Dimension,
        require         = Scale,
        default         = Dimension(1, 1),
        set             = Scale.SetFromScale
                        and function(self, val) self:SetFromScale(val.x, val.y) end
                        or  function(self, val) self:SetScaleFrom(val.x, val.y) end,
        get             = Scale.GetFromScale
                        and function(self) return Dimension(self:GetFromScale()) end
                        or  function(self) return Dimension(self:GetScaleFrom()) end
    }

    --- the animation's scale amount that end to
    UI.Property         {
        name            = "ToScale",
        type            = Dimension,
        require         = Scale,
        default         = Dimension(1, 1),
        set             = Scale.SetToScale
                        and function(self, val) self:SetToScale(val.x, val.y) end
                        or  function(self, val) self:SetScaleTo(val.x, val.y) end,
        get             = Scale.GetToScale
                        and function(self) return Dimension(self:GetToScale()) end
                        or  function(self) return Dimension(self:GetScaleTo()) end,
    }

    --- the animation's scaling factors
    UI.Property         {
        name            = "Scale",
        type            = Dimension,
        require         = Scale,
        default         = Dimension(1, 1),
        set             = function(self, val) self:SetScale(val.x, val.y) end,
        get             = function(self) return Dimension(self:GetScale()) end,
    }
end

------------------------------------------------------------
--                         Frame                          --
------------------------------------------------------------
do
    --- whether the frame's boundaries are limited to those of the screen
    UI.Property         {
        name            = "ClampedToScreen",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetClampedToScreen(val) end,
        get             = function(self) return self:IsClampedToScreen() end,
    }

    --- offsets from the frame's edges used when limiting user movement or resizing of the frame
    UI.Property         {
        name            = "ClampRectInsets",
        type            = Inset,
        require         = Frame,
        default         = Inset(0, 0, 0, 0),
        secure          = true,
        set             = function(self, val) self:SetClampRectInsets(val.left, val.right, val.top, val.bottom) end,
        get             = function(self) return Inset(self:GetClampRectInsets()) end,
    }

    --- Whether the children is limited to draw inside the frame's boundaries
    UI.Property         {
        name            = "ClipChildren",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetClipsChildren(val) end,
        get             = function(self) return self:DoesClipChildren() end,
    }

    --- the 3D depth of the frame (for stereoscopic 3D setups)
    if Frame.SetDepth then
    UI.Property         {
        name            = "Depth",
        type            = Number,
        require         = Frame,
        default         = 0,
        secure          = true,
        set             = function(self, val) self:SetDepth(val) end,
        get             = function(self) return self:GetDepth() end,
    } end

    --- Whether the frame don't save its location in layout-cache
    UI.Property         {
        name            = "DontSavePosition",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetDontSavePosition(val) end,
        get             = function(self) return self:GetDontSavePosition() end,
    }

    --- Whether the frame's child is render in flattens layers
    UI.Property         {
        name            = "FlattenRenderLayers",
        type            = Boolean,
        require         = Frame,
        default         = false,
        set             = function(self, val) self:SetFlattensRenderLayers(val) end,
        get             = function(self) return self:GetFlattensRenderLayers() end,
    }

    --- Whether a frame to be rendered in its own framebuffer
    UI.Property         {
        name            = "FrameBuff",
        type            = Boolean,
        require         = Frame,
        default         = false,
        set             = Frame.SetFrameBuffer
                        and function(self, val) self:SetFrameBuffer(val) end
                        or  function(self, val) self:SetIsFrameBuffer(val) end,
    }

    --- the level at which the frame is layered relative to others in its strata
    UI.Property         {
        name            = "FrameLevel",
        type            = Number,
        require         = Frame,
        default         = 1,
        secure          = true,
        set             = function(self, val) self:SetFrameLevel(val) end,
        get             = function(self) return self:GetFrameLevel() end,
    }

    --- the general layering strata of the frame
    UI.Property         {
        name            = "FrameStrata",
        type            = FrameStrata,
        require         = Frame,
        default         = "MEDIUM",
        secure          = true,
        set             = function(self, val) self:SetFrameStrata(val) end,
        get             = function(self) return self:GetFrameStrata() end,
    }

    --- the insets from the frame's edges which determine its mouse-interactable area
    UI.Property         {
        name            = "HitRectInsets",
        type            = Inset,
        require         = Frame,
        secure          = true,
        default         = Inset(0, 0, 0, 0),
        set             = function(self, val) self:SetHitRectInsets(val.left, val.right, val.top, val.bottom) end,
        get             = function(self) return Inset(self:GetHitRectInsets()) end,
    }

    --- Whether the hyper links are enabled
    UI.Property         {
        name            = "HyperlinksEnabled",
        type            = Boolean,
        require         = Frame,
        default         = false,
        set             = function(self, val) self:SetHyperlinksEnabled(val) end,
        get             = function(self) return self:GetHyperlinksEnabled() end,
    }

    --- a numeric identifier for the frame
    UI.Property         {
        name            = "ID",
        type            = Number,
        require         = Frame,
        default         = 0,
        secure          = true,
        set             = function(self, val) self:SetID(val) end,
        get             = function(self) return self:GetID() end,
    }

    --- whether the frame's depth property is ignored (for stereoscopic 3D setups)
    if Frame.IgnoreDepth then
    UI.Property         {
        name            = "IgnoringDepth",
        type            = Boolean,
        require         = Frame,
        default         = false,
        set             = function(self, val) self:IgnoreDepth(val) end,
        get             = function(self) return self:IsIgnoringDepth() end,
    } end

    --- Whether the joystick is enabled for the frame
    UI.Property         {
        name            = "JoystickEnabled",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:EnableJoystick(val) end,
        get             = function(self) return self:IsJoystickEnabled() end,
    }

    --- whether keyboard interactivity is enabled for the frame
    UI.Property         {
        name            = "EnableKeyboard",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:EnableKeyboard(val) end,
        get             = function(self) return self:IsKeyboardEnabled() end,
    }

    --- Whether the mouse click is enabled
    UI.Property         {
        name            = "EnableMouseClicks",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetMouseClickEnabled(val) end,
        get             = function(self) return self:IsMouseClickEnabled() end,
        override        = { "EnableMouse" },
    }

    --- whether mouse interactivity is enabled for the frame
    UI.Property         {
        name            = "EnableMouse",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:EnableMouse(val) end,
        get             = function(self) return self:IsMouseEnabled() end,
        override        = { "EnableMouseClicks", "EnableMouseMotion" },
    }

    --- Whether the mouse motion in enabled
    UI.Property         {
        name            = "EnableMouseMotion",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetMouseMotionEnabled(val) end,
        get             = function(self) return self:IsMouseMotionEnabled() end,
        override        = { "EnableMouse" },
    }

    --- whether mouse wheel interactivity is enabled for the frame
    UI.Property         {
        name            = "EnableMouseWheel",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:EnableMouseWheel(val) end,
        get             = function(self) return self:IsMouseWheelEnabled() end,
    }

    --- the minimum size of the frame for user resizing
    UI.Property         {
        name            = "MinResize",
        type            = Size,
        require         = Frame,
        default         = Size(0, 0),
        set             = Frame.SetMinResize
                        and function(self, val) self:SetMinResize(val.width, val.height) end
                        or  function(self, val)
                            local _, _, aw, ah = self:GetResizeBounds()
                            self:SetResizeBounds(val.width, val.height, aw or 0, ah or 0)
                        end,
        get             = Frame.GetMinResize
                        and function(self) return Size(self:GetMinResize()) end
                        or  function(self)
                            local iw, ih = self:GetResizeBounds()
                            return Size(iw or 0, ih or 0)
                        end ,
    }

    --- the maximum size of the frame for user resizing
    UI.Property         {
        name            = "MaxResize",
        type            = Size,
        require         = Frame,
        default         = Size(0, 0),
        set             = Frame.SetMaxResize
                        and function(self, val) self:SetMaxResize(val.width, val.height) end
                        or  function(self, val)
                            local iw, ih = self:GetResizeBounds()
                            self:SetResizeBounds(iw or val.width, ih or val.height, val.width, val.height)
                        end,
        get             = Frame.GetMaxResize
                        and function(self) return Size(self:GetMaxResize()) end
                        or  function(self)
                            local _, _, mw, mh = self:GetResizeBounds()
                            return Size(mw or 0, mh or 0)
                        end,
    }

    --- whether the frame can be moved by the user
    UI.Property         {
        name            = "Movable",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetMovable(val) end,
        get             = function(self) return self:IsMovable() end,
    }

    --- Whether the frame get the propagate keyboard input
    UI.Property         {
        name            = "PropagateKeyboardInput",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetPropagateKeyboardInput(val) end,
        get             = function(self) return self:GetPropagateKeyboardInput() end,
    }

    --- whether the frame can be resized by the user
    UI.Property         {
        name            = "Resizable",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetResizable(val) end,
        get             = function(self) return self:IsResizable() end,
    }

    --- whether the frame should automatically come to the front when clicked
    UI.Property         {
        name            = "Toplevel",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetToplevel(val) end,
        get             = function(self) return self:IsToplevel() end,
    }

    --- whether the frame should save/load custom position by the system
    UI.Property         {
        name            = "UserPlaced",
        type            = Boolean,
        require         = Frame,
        default         = false,
        secure          = true,
        set             = function(self, val) self:SetUserPlaced(val) end,
        get             = function(self) return self:IsUserPlaced() end,
    }
end

------------------------------------------------------------
--                         Button                         --
------------------------------------------------------------
do
    --- Whether the button is enabled
    UI.Property         {
        name            = "Enabled",
        type            = Boolean,
        require         = { Button, EditBox, Slider },
        default         = true,
        secure          = true,
        set             = function(self, val) self:SetEnabled(val) end,
        get             = function(self) return self:IsEnabled() end,
    }

    --- the FontString object used for the button's label text
    UI.Property         {
        name            = "ButtonText",
        type            = FontString,
        require         = Button,
        nilable         = true,
        childtype       = FontString,
        set             = function(self, val) self:SetFontString(val) end,
    }

    --- The button state
    UI.Property         {
        name            = "ButtonState",
        type            = ButtonStateType,
        require         = Button,
        default         = "NORMAL",
        secure          = true,
        set             = function(self, val) self:SetButtonState(val) end,
        get             = function(self) return self:GetButtonState() end,
    }

    --- Whether enable the motion script while disabled
    UI.Property         {
        name            = "MotionScriptsWhileDisabled",
        type            = Boolean,
        require         = Button,
        default         = false,
        set             = function(self, val) self:SetMotionScriptsWhileDisabled(val) end,
        get             = function(self) return self:GetMotionScriptsWhileDisabled() end,
    }

    --- The registered mouse key for click
    UI.Property         {
        name            = "RegisterForClicks",
        type            = struct { String },
        require         = Button,
        nilable         = true,
        secure          = true,
        set             = function(self, val) if val then self:RegisterForClicks(unpack(val)) else self:RegisterForClicks(nil) end end
    }

    --- The registered mouse key for drag
    UI.Property         {
        name            = "RegisterForDrag",
        type            = struct { String },
        require         = Button,
        nilable         = true,
        secure          = true,
        set             = function(self, val) if val then self:RegisterForDrag(unpack(val)) else self:RegisterForDrag(nil) end end
    }

    --- the offset for moving the button's label text when pushed
    UI.Property         {
        name            = "PushedTextOffset",
        type            = Dimension,
        require         = Button,
        default         = Dimension(1.5665, -1.5665),
        set             = function(self, val) self:SetPushedTextOffset(val.x, val.y) end,
        get             = function(self) return Dimension(self:GetPushedTextOffset()) end,
    }

    --- the texture object used when the button is pushed
    UI.Property         {
        name            = "PushedTexture",
        type            = Texture,
        require         = Button,
        nilable         = true,
        childtype       = Texture,
        clear           = Button.ClearPushedTexture and function(self) self:ClearPushedTexture() end,
        set             = function(self, val) self:SetPushedTexture(val) end,
    }

    --- the texture object used when the button is highlighted
    UI.Property         {
        name            = "HighlightTexture",
        type            = Texture,
        require         = Button,
        nilable         = true,
        childtype       = Texture,
        clear           = Button.ClearHighlightTexture and function(self) self:ClearHighlightTexture() end,
        set             = function(self, val) self:SetHighlightTexture(val) end,
    }

    --- the texture object used for the button's normal state
    UI.Property         {
        name            = "NormalTexture",
        type            = Texture,
        require         = Button,
        nilable         = true,
        childtype       = Texture,
        clear           = Button.ClearNormalTexture and function(self) self:ClearNormalTexture() end,
        set             = function(self, val) self:SetNormalTexture(val) end,
    }

    --- the texture object used when the button is disabled
    UI.Property         {
        name            = "DisabledTexture",
        type            = Texture,
        require         = Button,
        nilable         = true,
        childtype       = Texture,
        clear           = Button.ClearDisabledTexture and function(self) self:ClearDisabledTexture() end,
        set             = function(self, val) self:SetDisabledTexture(val) end,
    }

    --- the font object used when the button is highlighted
    UI.Property         {
        name            = "HighlightFont",
        type            = FontObject,
        require         = Button,
        nilable         = true,
        set             = function(self, val) self:SetHighlightFontObject(val) end,
        get             = function(self) return self:GetHighlightFontObject() end,
    }

    --- the font object used for the button's normal state
    UI.Property         {
        name            = "NormalFont",
        type            = FontObject,
        require         = Button,
        nilable         = true,
        set             = function(self, val) self:SetNormalFontObject(val) end,
        get             = function(self) return self:GetNormalFontObject() end,
    }

    --- the font object used for the button's disabled state
    UI.Property         {
        name            = "DisabledFont",
        type            = FontObject,
        require         = Button,
        nilable         = true,
        set             = function(self, val) self:SetDisabledFontObject(val) end,
        get             = function(self) return self:GetDisabledFontObject() end,
    }

    --- Lock the highlight
    if Button.SetHighlightLocked then
    UI.Property         {
        name            = "HighlightLocked",
        type            = Boolean,
        require         = Button,
        default         = false,
        set             = function(self, val) self:SetHighlightLocked(val) end,
    } end
end

------------------------------------------------------------
--                      CheckButton                       --
------------------------------------------------------------
do
    --- Whether the checkbutton is checked
    UI.Property         {
        name            = "Checked",
        type            = Boolean,
        require         = CheckButton,
        default         = false,
        set             = function(self, val) self:SetChecked(val) end,
        get             = function(self) return self:GetChecked() end,
    }

    --- the texture object used when the button is checked
    UI.Property         {
        name            = "CheckedTexture",
        type            = Texture,
        require         = CheckButton,
        nilable         = true,
        childtype       = Texture,
        set             = function(self, val) self:SetCheckedTexture(val) end,
    }

    --- the texture object used when the button is disabled and checked
    UI.Property         {
        name            = "DisabledCheckedTexture",
        type            = Texture,
        require         = CheckButton,
        nilable         = true,
        childtype       = Texture,
        set             = function(self, val) self:SetDisabledCheckedTexture(val) end,
    }
end

------------------------------------------------------------
--                      ColorSelect                       --
------------------------------------------------------------
do
    --- the HSV color value
    UI.Property         {
        name            = "ColorHSV",
        type            = HSVType,
        require         = ColorSelect,
        default         = HSVType(0, 0, 1),
        set             = function(self, val) self:SetColorHSV(val.h, val.s, val.v) end,
        get             = function(self) return HSVType(self:GetColorHSV()) end,
    }

    --- the RGB color value
    UI.Property         {
        name            = "ColorRGB",
        type            = ColorType,
        require         = ColorSelect,
        default         = Color.WHITE,
        set             = function(self, val) self:SetColorRGB(val.r, val.g, val.b, val.a) end,
        get             = function(self) return Color(self:GetColorRGB()) end,
    }

    --- the texture for the color picker's value slider background
    UI.Property         {
        name            = "ColorValueTexture",
        type            = Texture,
        require         = ColorSelect,
        nilable         = true,
        childtype       = Texture,
        set             = function(self, val) self:SetColorValueTexture(val) end,
    }

    --- the texture for the selection indicator on the color picker's hue/saturation wheel
    UI.Property         {
        name            = "ColorWheelThumbTexture",
        type            = Texture,
        require         = ColorSelect,
        nilable         = true,
        childtype       = Texture,
        set             = function(self, val) self:SetColorWheelThumbTexture(val) end,
    }

    --- the texture for the color picker's hue/saturation wheel
    UI.Property         {
        name            = "ColorWheelTexture",
        type            = Texture,
        require         = ColorSelect,
        nilable         = true,
        childtype       = Texture,
        set             = function(self, val) self:SetColorWheelTexture(val) end,
    }

    --- the texture for the color picker's value slider thumb
    UI.Property         {
        name            = "ColorValueThumbTexture",
        type            = Texture,
        require         = ColorSelect,
        nilable         = true,
        childtype       = Texture,
        set             = function(self, val) self:SetColorValueThumbTexture(val) end,
    }
end

------------------------------------------------------------
--                        Cooldown                        --
------------------------------------------------------------
do
    --- Sets the bling texture
    UI.Property         {
        name            = "BlingTexture",
        type            = TextureType,
        require         = Cooldown,
        set             = function(self, val) if val.color and val.file then self:SetBlingTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) elseif val.color then self:SetBlingTexture(val.color.r, val.color.g, val.color.b, val.color.a) else self:SetBlingTexture(val.file) end end,
    }

    --- the duration currently shown by the cooldown frame in milliseconds
    UI.Property         {
        name            = "CooldownDuration",
        type            = Number,
        require         = Cooldown,
        default         = 0,
        set             = function(self, val) self:SetCooldownDuration(val) end,
        get             = function(self) self:GetCooldownDuration() end,
    }

    --- Whether the cooldown 'bling' when finsihed
    UI.Property         {
        name            = "DrawBling",
        type            = Boolean,
        require         = Cooldown,
        default         = true,
        set             = function(self, val) self:SetDrawBling(val) end,
        get             = function(self) self:GetDrawBling() end,
    }

    --- Whether a bright line should be drawn on the moving edge of the cooldown animation
    UI.Property         {
        name            = "DrawEdge",
        type            = Boolean,
        require         = Cooldown,
        default         = true,
        set             = function(self, val) self:SetDrawEdge(val) end,
        get             = function(self) self:GetDrawEdge() end,
    }

    --- Whether a shadow swipe should be drawn
    UI.Property         {
        name            = "DrawSwipe",
        type            = Boolean,
        require         = Cooldown,
        default         = true,
        set             = function(self, val) self:SetDrawSwipe(val) end,
        get             = function(self) self:GetDrawSwipe() end,
    }

    -- The edge scale
    UI.Property         {
        name            = "EdgeScale",
        type            = Number,
        require         = Cooldown,
        default         = math.sin(45 / 180 * math.pi),
        set             = function(self, val) self:SetEdgeScale(val) end,
        get             = function(self) self:GetEdgeScale() end,
    }

    --- Sets the edge texture
    UI.Property         {
        name            = "EdgeTexture",
        type            = TextureType,
        require         = Cooldown,
        set             = function(self, val) if val.color and val.file then self:SetEdgeTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) elseif val.color then self:SetEdgeTexture(val.color.r, val.color.g, val.color.b, val.color.a) else self:SetEdgeTexture(val.file) end end,
    }

    --- Whether hide count down numbers
    UI.Property         {
        name            = "HideCountdownNumbers",
        type            = Boolean,
        require         = Cooldown,
        default         = false,
        set             = function(self, val) self:SetHideCountdownNumbers(val) end,
    }

    --- Whether the cooldown animation "sweeps" an area of darkness over the underlying image; false if the animation darkens the underlying image and "sweeps" the darkened area away
    UI.Property         {
        name            = "Reverse",
        type            = Boolean,
        require         = Cooldown,
        default         = false,
        set             = function(self, val) self:SetReverse(val) end,
        get             = function(self) self:GetReverse() end,
    }

    --- the swipe color
    UI.Property         {
        name            = "SwipeColor",
        type            = ColorType,
        require         = Cooldown,
        set             = function(self, val) self:SetSwipeColor(val.r, val.g, val.b) end,
        depends         = { "SwipeTexture" },
    }

    --- the swipe texture
    UI.Property         {
        name            = "SwipeTexture",
        type            = TextureType,
        require         = Cooldown,
        set             = function(self, val) if val.color and val.file then self:SetSwipeTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) elseif val.color then self:SetSwipeTexture(val.color.r, val.color.g, val.color.b, val.color.a) else self:SetSwipeTexture(val.file) end end,
    }

    --- Whether use circular edge
    UI.Property         {
        name            = "UseCircularEdge",
        type            = Boolean,
        require         = Cooldown,
        default         = false,
        set             = function(self, val) self:SetUseCircularEdge(val) end,
    }

    --- The tex coord range
    if Cooldown.SetTexCoordRange then
    UI.Property         {
        name            = "TexCoordRange",
        type            = Boolean,
        require         = Cooldown,
        default         = { low = Dimension(0, 0), high = Dimension(1, 1) },
        set             = function(self, val) self:SetTexCoordRange(val.low, val.high) end,
    }
    end
end

------------------------------------------------------------
--                        EditBox                         --
------------------------------------------------------------
do
    --- true if the arrow keys are ignored by the edit box unless the Alt key is held
    UI.Property         {
        name            = "AltArrowKeyMode",
        type            = Boolean,
        require         = EditBox,
        default         = false,
        set             = function(self, val) self:SetAltArrowKeyMode(val) end,
        get             = function(self) return self:GetAltArrowKeyMode() end,
    }

    --- true if the edit box automatically acquires keyboard input focus
    UI.Property         {
        name            = "AutoFocus",
        type            = Boolean,
        require         = EditBox,
        default         = true,
        set             = function(self, val) self:SetAutoFocus(val) end,
        get             = function(self) return self:IsAutoFocus() end,
    }

    --- the rate at which the text insertion blinks when the edit box is focused
    UI.Property         {
        name            = "BlinkSpeed",
        type            = Number,
        require         = EditBox,
        default         = 0.5,
        set             = function(self, val) self:SetBlinkSpeed(val) end,
        get             = function(self) return self:GetBlinkSpeed() end,
    }

    --- Whether count the invisible letters for max letters
    UI.Property         {
        name            = "CountInvisibleLetters",
        type            = Boolean,
        require         = EditBox,
        default         = false,
        set             = function(self, val) self:SetCountInvisibleLetters(val) end,
        get             = function(self) return self:IsCountInvisibleLetters() end,
    }

    UI.Property         {
        name            = "HighlightColor",
        type            = ColorType,
        require         = EditBox,
        set             = function(self, val) self:SetHighlightColor(val.r, val.g, val.b, val.a) end,
        get             = function(self) return Color(self:GetHighlightColor()) end,
    }

    --- the maximum number of history lines stored by the edit box
    UI.Property         {
        name            = "HistoryLines",
        type            = Number,
        require         = EditBox,
        default         = 0,
        set             = function(self, val) self:SetHistoryLines(val) end,
        get             = function(self) return self:GetHistoryLines() end,
    }

    --- the maximum number of bytes of text allowed in the edit box, default is 0(Infinite)
    UI.Property         {
        name            = "MaxBytes",
        type            = Integer,
        require         = EditBox,
        default         = 0,
        set             = function(self, val) self:SetMaxBytes(val) end,
        get             = function(self) return self:GetMaxBytes() end,
    }

    --- the maximum number of text characters allowed in the edit box
    UI.Property         {
        name            = "MaxLetters",
        type            = Integer,
        require         = EditBox,
        default         = 0,
        set             = function(self, val) self:SetMaxLetters(val) end,
        get             = function(self) return self:GetMaxLetters() end,
    }

    --- true if the edit box shows more than one line of text
    UI.Property         {
        name            = "MultiLine",
        type            = Boolean,
        require         = EditBox,
        default         = false,
        set             = function(self, val) self:SetMultiLine(val) end,
        get             = function(self) return self:IsMultiLine() end,
    }

    --- true if the edit box only accepts numeric input
    UI.Property         {
        name            = "Numeric",
        type            = Boolean,
        require         = EditBox,
        default         = false,
        set             = function(self, val) self:SetNumeric(val) end,
        get             = function(self) return self:IsNumeric() end,
    }

    --- the contents of the edit box as a number
    UI.Property         {
        name            = "Number",
        type            = Number,
        require         = EditBox,
        default         = 0,
        set             = function(self, val) self:SetNumber(val) end,
        get             = function(self) return self:GetNumber() end,
    }

    --- true if the text entered in the edit box is masked
    UI.Property         {
        name            = "Password",
        type            = Boolean,
        require         = EditBox,
        default         = false,
        set             = function(self, val) self:SetPassword(val) end,
        get             = function(self) return self:IsPassword() end,
    }

    --- the insets from the edit box's edges which determine its interactive text area
    UI.Property         {
        name            = "TextInsets",
        type            = Inset,
        require         = EditBox,
        set             = function(self, val) self:SetTextInsets(val.left, val.right, val.top, val.bottom) end,
        get             = function(self) return Inset(self:GetTextInsets()) end,
    }

    UI.Property         {
        name            = "VisibleTextByteLimit",
        type            = Boolean,
        require         = EditBox,
        default         = false,
        set             = function(self, val) self:SetVisibleTextByteLimit(val) end,
        get             = function(self) return self:GetVisibleTextByteLimit() end,
    }
end

------------------------------------------------------------
--                      MessageFrame                      --
------------------------------------------------------------
do
    --- the duration of the fade-out animation for disappearing messages
    UI.Property         {
        name            = "FadeDuration",
        type            = Number,
        require         = MessageFrame,
        default         = 3,
        set             = function(self, val) self:SetFadeDuration(val) end,
        get             = function(self) return self:GetFadeDuration() end,
    }

    --- whether messages added to the frame automatically fade out after a period of time
    UI.Property         {
        name            = "Fading",
        type            = Boolean,
        require         = MessageFrame,
        default         = true,
        set             = function(self, val) self:SetFading(val) end,
        get             = function(self) return self:GetFading() end,
    }

    --- The power of the fade-out animation for disappearing messages
    UI.Property         {
        name            = "FadePower",
        type            = Number,
        require         = MessageFrame,
        default         = 1,
        set             = function(self, val) self:SetFadePower(val) end,
        get             = function(self) return self:GetFadePower() end,
    }

    --- the position at which new messages are added to the frame
    UI.Property         {
        name            = "InsertMode",
        type            = InsertMode,
        require         = MessageFrame,
        default         = "BOTTOM",
        set             = function(self, val) self:SetInsertMode(val) end,
        get             = function(self) return self:GetInsertMode() end,
    }

    --- the amount of time for which a message remains visible before beginning to fade out
    UI.Property         {
        name            = "DisplayDuration",
        type            = Number,
        require         = MessageFrame,
        default         = 10,
        set             = function(self, val) self:SetTimeVisible(val) end,
        get             = function(self) return self:GetTimeVisible() end,
    }
end

------------------------------------------------------------
--                      ScrollFrame                       --
------------------------------------------------------------
do
    --- the scroll frame's current horizontal scroll position
    UI.Property         {
        name            = "HorizontalScroll",
        type            = Number,
        require         = ScrollFrame,
        default         = 0,
        set             = function(self, val) self:SetHorizontalScroll(val) end,
        get             = function(self) return self:GetHorizontalScroll() end,
    }

    --- the scroll frame's vertical scroll position
    UI.Property         {
        name            = "VerticalScroll",
        type            = Number,
        require         = ScrollFrame,
        default         = 0,
        set             = function(self, val) self:SetVerticalScroll(val) end,
        get             = function(self) return self:GetVerticalScroll() end,
    }
end

------------------------------------------------------------
--                       SimpleHTML                       --
------------------------------------------------------------
do
    UI.Property         {
        name            = "HyperlinkFormat",
        type            = String,
        require         = SimpleHTML,
        default         = "%s",
        set             = function(self, val) self:SetHyperlinkFormat(val) end,
        get             = function(self) return self:GetHyperlinkFormat() end,
    }
end

------------------------------------------------------------
--                         Slider                         --
------------------------------------------------------------
do
    local smoothValueDelay      = Toolset.newtable(true)
    local smoothRealValue       = Toolset.newtable(true)
    local smoothValueFinal      = Toolset.newtable(true)

    __Service__(true)
    function ProcessSmoothValueUpdate()
        while true do
            while next(smoothRealValue) do
                local now       = GetTime()

                for self, real in pairs(smoothRealValue) do
                    local diff  = smoothValueFinal[self] - now

                    if diff <= 0 then
                        self:SetValue(real)
                        smoothRealValue[self] = nil
                    else
                        diff    = diff / (smoothValueDelay[self] or 1)
                        if diff > 1 then diff = 1 end
                        self:SetValue(self:GetValue() * diff + real * (1 - diff))
                    end
                end

                Next()
            end

            NextEvent("SCORPIO_UI_SMOOTH_VALUE_PROCESS")
        end
    end

    --- the texture object for the slider thumb
    UI.Property         {
        name            = "ThumbTexture",
        type            = Texture,
        require         = Slider,
        nilable         = true,
        childtype       = Texture,
        set             = function(self, val) self:SetThumbTexture(val) end,
    }

    --- the minimum and maximum values of the slider bar
    UI.Property         {
        name            = "MinMaxValues",
        type            = MinMax,
        require         = { Slider, StatusBar },
        set             = function(self, val) self:SetMinMaxValues(val.min, val.max) end,
        get             = function(self) return MinMax(self:GetMinMaxValues()) end,
    }

    --- the orientation of the slider
    UI.Property         {
        name            = "Orientation",
        type            = Orientation,
        require         = { Slider, StatusBar },
        set             = function(self, val) self:SetOrientation(val) end,
        get             = function(self) return self:GetOrientation() end,
    }

    --- the steps per page of the slider bar
    UI.Property         {
        name            = "StepsPerPage",
        type            = Number,
        require         = Slider,
        default         = 0,
        set             = function(self, val) self:SetStepsPerPage(val) end,
        get             = function(self) return self:GetStepsPerPage() end,
    }

    --- Whether obey the step setting when drag the slider bar
    UI.Property         {
        name            = "ObeyStepOnDrag",
        type            = Boolean,
        require         = Slider,
        default         = false,
        set             = function(self, val) self:SetObeyStepOnDrag(val) end,
        get             = function(self) return self:GetObeyStepOnDrag() end,
    }

    --- the value representing the current position of the slider thumb
    UI.Property         {
        name            = "Value",
        type            = Number,
        require         = { Slider, StatusBar },
        default         = 0,
        set             = function(self, val) self:SetValue(val) end,
        get             = function(self) return self:GetValue() end,
    }

    --- the minimum increment between allowed slider values
    UI.Property         {
        name            = "ValueStep",
        type            = Number,
        require         = Slider,
        default         = 0,
        set             = function(self, val) self:SetValueStep(val) end,
        get             = function(self) return self:GetValueStep() end,
    }

    --- A smooth value accessor instead of the Value
    UI.Property         {
        name            = "SmoothValue",
        type            = Number,
        require         = { Slider, StatusBar },
        default         = 0,
        set             = function(self, val)
            if not next(smoothRealValue) then
                FireSystemEvent("SCORPIO_UI_SMOOTH_VALUE_PROCESS")
            end

            smoothRealValue[self]  = val
            smoothValueFinal[self] = GetTime() + (smoothValueDelay[self] or 1)
        end,
    }

    --- The smooth value delay
    UI.Property         {
        name            = "SmoothValueDelay",
        type            = Number,
        require         = { Slider, StatusBar },
        default         = 1,
        set             = function(self, val)
            smoothValueDelay[self] = val
        end,
        get             = function(self)
            return smoothValueDelay[self] or 1
        end,
    }
end

------------------------------------------------------------
--                       StatusBar                        --
------------------------------------------------------------
do
    --- whether the status bar's texture is rotated to match its orientation
    UI.Property         {
        name            = "RotatesTexture",
        type            = Boolean,
        require         = StatusBar,
        default         = false,
        set             = function(self, val) self:SetRotatesTexture(val) end,
        get             = function(self) return self:GetRotatesTexture() end,
    }

    --- Whether the status bar's texture is reverse filled
    UI.Property         {
        name            = "ReverseFill",
        type            = Boolean,
        require         = StatusBar,
        default         = false,
        set             = function(self, val) self:SetReverseFill(val) end,
        get             = function(self) return self:GetReverseFill() end,
    }

    UI.Property         {
        name            = "FillStyle",
        type            = FillStyle,
        require         = StatusBar,
        default         = "STANDARD",
        set             = function(self, val) self:SetFillStyle(val) end,
        get             = function(self) return self:GetFillStyle() end,
    }

    --- The texture atlas
    if StatusBar.SetStatusBarAtlas then
    UI.Property         {
        name            = "StatusBarAtlas",
        type            = String,
        require         = StatusBar,
        set             = function(self, val) self:SetStatusBarAtlas(val) end,
        get             = function(self) return self:GetStatusBarAtlas() end,
    } end

    --- the color shading for the status bar's texture
    UI.Property         {
        name            = "StatusBarColor",
        type            = ColorType,
        require         = StatusBar,
        default         = Color.WHITE,
        set             = function(self, val) self:SetStatusBarColor(val.r, val.g, val.b, val.a) end,
        get             = function(self) return Color(self:GetStatusBarColor()) end,
    }

    --- The texture
    UI.Property         {
        name            = "StatusBarTexture",
        type            = Texture,
        require         = StatusBar,
        nilable         = true,
        childtype       = Texture,
        set             = function(self, val) self:SetStatusBarTexture(val) end,
    }

    --- The desaturation
    if StatusBar.SetStatusBarDesaturation then
    UI.Property         {
        name            = "StatusBarDesaturation",
        type            = Number,
        require         = StatusBar,
        default         = 0,
        get             = function(self) return self:GetStatusBarDesaturation() end,
        set             = function(self, val) self:SetStatusBarDesaturation(val) end,
    } end

    --- Whether desaturated
    if StatusBar.SetStatusBarDesaturated then
    UI.Property         {
        name            = "StatusBarDesaturation",
        type            = Boolean,
        require         = StatusBar,
        default         = false,
        get             = function(self) return self:IsStatusBarDesaturated() end,
        set             = function(self, val) self:SetStatusBarDesaturated(val) end,
    } end
end

------------------------------------------------------------
--                         Model                          --
------------------------------------------------------------
do
    --- The model's camera
    UI.Property         {
        name            = "Camera",
        type            = Number,
        require         = Model,
        set             = function(self, val) self:SetCamera(val) end,
    }

    --- The model's camera distance
    UI.Property         {
        name            = "CameraDistance",
        type            = Number,
        require         = Model,
        set             = function(self, val) self:SetCameraDistance(val) end,
        get             = function(self) return self:GetCameraDistance() end,
    }

    --- The model's camera facing
    UI.Property         {
        name            = "CameraFacing",
        type            = Number,
        require         = Model,
        default         = 0,
        set             = function(self, val) self:SetCameraFacing(val) end,
        get             = function(self) return self:GetCameraFacing() end,
    }

    --- The model's camera position
    UI.Property         {
        name            = "CameraPosition",
        type            = Position,
        require         = { Model, ModelScene },
        set             = function(self, val) self:SetCameraPosition(val.x, val.y, val.z) end,
        get             = function(self) return Position(self:GetCameraPosition()) end,
    }

    --- The model's camera target position
    UI.Property         {
        name            = "CameraTarget",
        type            = Position,
        require         = Model,
        set             = function(self, val) self:SetCameraTarget(val.x, val.y, val.z) end,
        get             = function(self) return Position(self:GetCameraTarget()) end,
    }

    --- The model's camera roll
    UI.Property         {
        name            = "CameraRoll",
        type            = Number,
        require         = Model,
        default         = 0,
        set             = function(self, val) self:SetCameraRoll(val) end,
        get             = function(self) return self:GetCameraRoll() end,
    }

    --- Whether has custom camera
    UI.Property         {
        name            = "CustomCamera",
        type            = Boolean,
        require         = Model,
        default         = false,
        set             = function(self, val) self:SetCustomCamera(val) end,
        get             = function(self) return self:HasCustomCamera() end,
    }

    --- the model's current fog color
    UI.Property         {
        name            = "FogColor",
        type            = ColorType,
        require         = { Model, ModelScene },
        default         = Color.WHITE,
        set             = function(self, val) self:SetFogColor(val.r, val.g, val.b, val.a) end,
        get             = function(self) return Color(self:GetFogColor()) end,
    }

    --- the far clipping distance for the model's fog
    UI.Property         {
        name            = "FogFar",
        type            = Number,
        require         = { Model, ModelScene },
        default         = 1,
        set             = function(self, val) self:SetFogFar(val) end,
        get             = function(self) return self:GetFogFar() end,
    }

    --- the near clipping distance for the model's fog
    UI.Property         {
        name            = "FogNear",
        type            = Number,
        require         = { Model, ModelScene },
        default         = 0,
        set             = function(self, val) self:SetFogNear(val) end,
        get             = function(self) return self:GetFogNear() end,
    }

    --- The model's facing
    UI.Property         {
        name            = "Facing",
        type            = Number,
        require         = Model,
        default         = 0,
        set             = function(self, val) self:SetFacing(val) end,
        get             = function(self) return self:GetFacing() end,
    }

    --- the light sources used when rendering the model
    UI.Property         {
        name            = "Light",
        type            = LightType,
        require         = Model,
        set             = function(self, val)
            local enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB

            enabled = set.enabled or false
            omni = set.omni or false

            if set.dir then
                dirX, dirY, dirZ = set.dir.x, set.dir.y, set.dir.z

                if set.ambIntensity and set.ambColor then
                    ambIntensity = set.ambIntensity
                    ambR, ambG, ambB = set.ambColor.r, set.ambColor.g, set.ambColor.b

                    if set.dirIntensity and set.dirColor then
                        dirIntensity = set.dirIntensity
                        dirR, dirG, dirB = set.dirColor.r, set.dirColor.g, set.dirColor.b
                    end
                end
            end

            return self:SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
        end,
        get             = function(self)
            local enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB = self:GetLight()
            return LightType(
                enabled,
                omni,
                Position(dirX, dirY, dirZ),
                ambIntensity,
                Color(ambR, ambG, ambB),
                dirIntensity,
                Color(dirR, dirG, dirB)
            )
        end,
    }

    --- The model to be display
    UI.Property         {
        name            = "Model",
        type            = String,
        require         = Model,
        set             = function(self, val) self:SetModel(val) end,
        clear           = function(self) self:ClearModel() end,
    }

    --- The model's alpha
    UI.Property         {
        name            = "ModelAlpha",
        type            = ColorFloat,
        require         = Model,
        default         = 1,
        set             = function(self, val) self:SetModelAlpha(val) end,
        get             = function(self) return self:GetModelAlpha() end,
    }

    UI.Property         {
        name            = "ModelCenterToTransform",
        type            = Boolean,
        require         = Model,
        default         = false,
        set             = function(self, val) self:UseModelCenterToTransform(val) end,
        get             = function(self) return self:IsUsingModelCenterToTransform() end,
    }

    --- The model's draw layer
    UI.Property         {
        name            = "ModelDrawLayer",
        type            = DrawLayer,
        require         = Model,
        default         = "ARTWORK",
        set             = function(self, val) self:SetModelDrawLayer(val) end,
        get             = function(self) return self:GetModelDrawLayer() end,
    }

    --- the scale factor determining the size at which the 3D model appears
    UI.Property         {
        name            = "ModelScale",
        type            = Number,
        require         = Model,
        default         = 1,
        set             = function(self, val) self:SetModelScale(val) end,
        get             = function(self) return self:GetModelScale() end,
    }

    --- the position of the 3D model within the frame
    UI.Property         {
        name            = "Position",
        type            = Position,
        require         = Model,
        default         = Position(0, 0, 0),
        set             = function(self, val) self:SetPosition(val.x, val.y, val.z) end,
        get             = function(self) return Position(self:GetPosition()) end,
    }

    UI.Property         {
        name            = "Paused",
        type            = Boolean,
        require         = Model,
        default         = false,
        set             = function(self, val) self:SetPaused(val) end,
        get             = function(self) return self:GetPaused() end,
    }

    UI.Property         {
        name            = "ParticlesEnabled",
        type            = Boolean,
        require         = Model,
        default         = false,
        set             = function(self, val) self:SetParticlesEnabled(val) end,
    }

    --- The model's pitch
    UI.Property         {
        name            = "Pitch",
        type            = Number,
        require         = Model,
        default         = 0,
        set             = function(self, val) self:SetPitch(val) end,
        get             = function(self) return self:GetPitch() end,
    }

    --- The model's roll
    UI.Property         {
        name            = "Roll",
        type            = Number,
        require         = Model,
        default         = 0,
        set             = function(self, val) self:SetRoll(val) end,
        get             = function(self) return self:GetRoll() end,
    }

    --- The shadow effect
    UI.Property         {
        name            = "ShadowEffect",
        type            = Number,
        require         = Model,
        default         = 0,
        set             = function(self, val) self:SetShadowEffect(val) end,
        get             = function(self) return self:GetShadowEffect() end,
    }

    UI.Property         {
        name            = "ViewInsets",
        type            = Inset,
        require         = { Model, ModelScene },
        default         = Inset(0, 0, 0, 0),
        set             = function(self, val) self:SetViewInsets(val.left, val.right, val.top, val.bottom) end,
        get             = function(self) return Inset(self:GetViewInsets()) end,
    }

    UI.Property         {
        name            = "ViewTranslation",
        type            = Dimension,
        require         = { Model, ModelScene },
        default         = Dimension(0, 0),
        set             = function(self, val) self:SetViewTranslation(val.x, val.y) end,
        get             = function(self) return Dimension(self:GetViewTranslation()) end,
    }
end

------------------------------------------------------------
--                       ModelScene                       --
------------------------------------------------------------
do
    UI.Property         {
        name            = "CameraFarClip",
        type            = Number,
        require         = ModelScene,
        default         = 100,
        set             = function(self, val) self:SetCameraFarClip(val) end,
        get             = function(self) return self:GetCameraFarClip() end,
    }

    UI.Property         {
        name            = "CameraNearClip",
        type            = Number,
        require         = ModelScene,
        default         = 0.2,
        set             = function(self, val) self:SetCameraNearClip(val) end,
        get             = function(self) return self:GetCameraNearClip() end,
    }

    UI.Property         {
        name            = "LightAmbientColor",
        type            = ColorType,
        require         = ModelScene,
        default         = Color(0.7, 0.7, 0.7),
        set             = function(self, val) self:SetLightAmbientColor(val.r, val.g, val.b) end,
        get             = function(self) return Color(self:GetLightAmbientColor()) end,
    }

    UI.Property         {
        name            = "LightPosition",
        type            = Position,
        require         = ModelScene,
        default         = Position(0, 0, 0),
        set             = function(self, val) self:SetLightPosition(val.x, val.y, val.z) end,
        get             = function(self) return Position(self:GetLightPosition()) end,
        }

    UI.Property         {
        name            = "LightType",
        type            = Number,
        require         = ModelScene,
        default         = 1,
        set             = function(self, val) self:SetLightType(val) end,
        get             = function(self) return self:GetLightType() end,
    }

    UI.Property         {
        name            = "LightDirection",
        type            = Position,
        require         = ModelScene,
        default         = Position(0, 1, 0),
        set             = function(self, val) self:SetLightDirection(val.x, val.y, val.z) end,
        get             = function(self) return Position(self:GetLightDirection()) end,
    }

    UI.Property         {
        name            = "CameraFieldOfView",
        type            = Number,
        require         = ModelScene,
        default         = 0.94,
        set             = function(self, val) self:SetCameraFieldOfView(val) end,
        get             = function(self) return self:GetCameraFieldOfView() end,
    }

    UI.Property         {
        name            = "LightDiffuseColor",
        type            = ColorType,
        require         = ModelScene,
        default         = Color(0.8, 0.8, 0.64),
        set             = function(self, val) self:SetLightDiffuseColor(val.r, val.g, val.b) end,
        get             = function(self) return Color(self:GetLightDiffuseColor()) end,
    }

    UI.Property         {
        name            = "LightVisible",
        type            = Number,
        require         = ModelScene,
        default         = true,
        set             = function(self, val) self:SetLightVisible(val) end,
        get             = function(self) return self:IsLightVisible() end,
    }
end

------------------------------------------------------------
--                      PlayerModel                       --
------------------------------------------------------------
do
    --- The model's camera
    UI.Property         {
        name            = "Camera",
        type            = Number,
        require         = Model,
        set             = function(self, val) self:SetCamera(val) end,
        depends         = { "Unit" },
    }

    UI.Property         {
        name            = "Unit",
        type            = String,
        require         = PlayerModel,
        nilable         = true,
        set             = function(self, val) self:SetUnit(val) end,
    }

end

------------------------------------------------------------
--                      DressUpModel                      --
------------------------------------------------------------
do
    --- Whether auto dress
    UI.Property         {
        name            = "AutoDress",
        type            = Boolean,
        require         = DressUpModel,
        default         = true,
        set             = function(self, val) self:SetAutoDress(val) end,
        get             = function(self) return self:GetAutoDress() end,
    }

    --- Whether sheathed the weapon
    UI.Property         {
        name            = "Sheathed",
        type            = Boolean,
        require         = DressUpModel,
        default         = false,
        set             = function(self, val) self:SetSheathed(val) end,
        get             = function(self) return self:GetSheathed() end,
    }

    --- Whether use transmog skin
    UI.Property         {
        name            = "UseTransmogSkin",
        type            = Boolean,
        require         = DressUpModel,
        default         = false,
        set             = function(self, val) self:SetUseTransmogSkin(val) end,
        get             = function(self) return self:GetUseTransmogSkin() end,
    }
end

------------------------------------------------------------
--                Useful Child Properties                 --
------------------------------------------------------------
do
    -- The left background texture
    UI.Property         {
        name            = "LeftBGTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The right background texture
    UI.Property         {
        name            = "RightBGTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The middle background texture
    UI.Property         {
        name            = "MiddleBGTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The top left background texture
    UI.Property         {
        name            = "TopLeftBGTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The top right background texture
    UI.Property         {
        name            = "TopRightBGTexture",
        require         = Frame,
        childtype       = Texture,
    }
    -- The top background texture
    UI.Property         {
        name            = "TopBGTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The bottom left background texture
    UI.Property         {
        name            = "BottomLeftBGTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The bottom right background texture
    UI.Property         {
        name            = "BottomRightBGTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The bottom background texture
    UI.Property         {
        name            = "BottomBGTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The background texture
    UI.Property         {
        name            = "BackgroundTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The icon texture
    UI.Property         {
        name            = "IconTexture",
        require         = Frame,
        childtype       = Texture,
    }

    -- The background frame
    UI.Property         {
        name            = "BackgroundFrame",
        require         = Frame,
        childtype       = Frame,
    }

    UI.Property         {
        name            = "IconFrame",
        require         = Frame,
        childtype       = Frame,
    }

    UI.Property         {
        name            = "PlayerModel",
        require         = Frame,
        childtype       = PlayerModel,
    }
end

------------------------------------------------------------
--          Useful Child Properties - Animation           --
------------------------------------------------------------
do
    --- The animation group
    UI.Property         {
        name            = "AnimationGroup",
        require         = LayoutFrame,
        childtype       = AnimationGroup,
    }

    UI.Property         {
        name            = "AnimationGroupIn",
        require         = LayoutFrame,
        childtype       = AnimationGroup,
    }

    UI.Property         {
        name            = "AnimationGroupOut",
        require         = LayoutFrame,
        childtype       = AnimationGroup,
    }

    --- The animations
    for i = 0, 3 do
        UI.Property     {
            name        = "Alpha" .. (i == 0 and "" or i),
            require     = AnimationGroup,
            childtype   = Alpha,
        }

        UI.Property     {
            name        = "Path" .. (i == 0 and "" or i),
            require     = AnimationGroup,
            childtype   = Path,
        }

        UI.Property     {
            name        = "ControlPoint" .. (i == 0 and "" or i),
            require     = AnimationGroup,
            childtype   = ControlPoint,
        }

        UI.Property     {
            name        = "Rotation" .. (i == 0 and "" or i),
            require     = AnimationGroup,
            childtype   = Rotation,
        }

        UI.Property     {
            name        = "Scale" .. (i == 0 and "" or i),
            require     = AnimationGroup,
            childtype   = Scale,
        }

        UI.Property     {
            name        = "LineScale" .. (i == 0 and "" or i),
            require     = AnimationGroup,
            childtype   = LineScale,
        }

        UI.Property     {
            name        = "Translation" .. (i == 0 and "" or i),
            require     = AnimationGroup,
            childtype   = Translation,
        }

        UI.Property     {
            name        = "LineTranslation" .. (i == 0 and "" or i),
            require     = AnimationGroup,
            childtype   = LineTranslation,
        }
    end
end

------------------------------------------------------------
--                     Label Widget                       --
------------------------------------------------------------
__Sealed__()
__ChildProperty__(Frame, "Label")
__ChildProperty__(Frame, "Label1")
__ChildProperty__(Frame, "Label2")
__ChildProperty__(Frame, "Label3")
class "UIPanelLabel"    { FontString }

Style.UpdateSkin("Default",     {
    [UIPanelLabel]              = {
        drawLayer               = "BACKGROUND",
        fontObject              = GameFontHighlight,
        justifyH                = "RIGHT",
    },
})

------------------------------------------------------------
--                     Frame Header                       --
------------------------------------------------------------
--- The header of frames
__Sealed__() __ChildProperty__(Frame, "Header")
__Template__(Frame)
class "UIFrameHeader"           {
    HeaderText                  = FontString,

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

Style.UpdateSkin("Default",     {
    [UIFrameHeader]             = {
        location                = { Anchor("TOPLEFT"), Anchor("TOPRIGHT") },
        height                  = 36,

        HeaderText              = {
            fontObject          = OptionsFontHighlight,
            location            = { Anchor("TOPLEFT", 16, -16) },
        },

        BottomBGTexture         = {
            height              = 1,
            color               = Color(1, 1, 1, 0.2),
            location            = { Anchor("TOPLEFT", 0, -3, "HeaderText", "BOTTOMLEFT"), Anchor("RIGHT", -16, 0) },
        },
    },
})

------------------------------------------------------------
--                  Backdrop Properties                   --
------------------------------------------------------------
if Frame.SetBackdrop then  -- For 8.0 and classic
    --- the backdrop graphic for the frame
    UI.Property         {
        name            = "Backdrop",
        type            = BackdropType,
        require         = Frame,
        nilable         = true,
        set             = function(self, val) self:SetBackdrop(val or nil) end,
        get             = function(self) return self:GetBackdrop() end,
    }

    --- the shading color for the frame's border graphic
    UI.Property         {
        name            = "BackdropBorderColor",
        type            = ColorType,
        require         = Frame,
        default         = Color.TRANSPARENT,
        set             = function(self, val) self:SetBackdropBorderColor(val.r, val.g, val.b, val.a) end,
        get             = function(self) local r, g, b, a = self:GetBackdropBorderColor() if r then return Color(r, g, b, a) end end,
        depends         = { "Backdrop" },
    }

    --- the shading color for the frame's background graphic
    UI.Property         {
        name            = "BackdropColor",
        type            = ColorType,
        require         = Frame,
        default         = Color.TRANSPARENT,
        set             = function(self, val) self:SetBackdropColor(val.r, val.g, val.b, val.a) end,
        get             = function(self) local r, g, b, a = self:GetBackdropColor() if r then return Color(r, g, b, a) end end,
        depends         = { "Backdrop" },
    }
else  -- For 9.0
    local clone             = Toolset.clone
    local getPropertyChild  = UIObject.GetPropertyChild

    local coordStart        = 0.0625
    local coordEnd          = 1 - coordStart
    local textureUVs        = {
        BackdropTopLeft     = { setWidth = true, setHeight = true, ULx = 0.5078125, ULy = coordStart, LLx = 0.5078125, LLy = coordEnd,  URx = 0.6171875, URy = coordStart, LRx = 0.6171875, LRy = coordEnd,   anchors = { Anchor("TOPLEFT") } },
        BackdropTopRight    = { setWidth = true, setHeight = true, ULx = 0.6328125, ULy = coordStart, LLx = 0.6328125, LLy = coordEnd,  URx = 0.7421875, URy = coordStart, LRx = 0.7421875, LRy = coordEnd,   anchors = { Anchor("TOPRIGHT") } },
        BackdropBottomLeft  = { setWidth = true, setHeight = true, ULx = 0.7578125, ULy = coordStart, LLx = 0.7578125, LLy = coordEnd,  URx = 0.8671875, URy = coordStart, LRx = 0.8671875, LRy = coordEnd,   anchors = { Anchor("BOTTOMLEFT") } },
        BackdropBottomRight = { setWidth = true, setHeight = true, ULx = 0.8828125, ULy = coordStart, LLx = 0.8828125, LLy = coordEnd,  URx = 0.9921875, URy = coordStart, LRx = 0.9921875, LRy = coordEnd,   anchors = { Anchor("BOTTOMRIGHT") } },
        BackdropTop         = { setWidth = false,setHeight = true, ULx = 0.2578125, ULy = "repeatX",  LLx = 0.3671875, LLy = "repeatX", URx = 0.2578125, URy = coordStart, LRx = 0.3671875, LRy = coordStart, anchors = { Anchor("TOPLEFT", 0, 0, "BackdropTopLeft", "TOPRIGHT"), Anchor("TOPRIGHT", 0, 0, "BackdropTopRight", "TOPLEFT") } },
        BackdropBottom      = { setWidth = false,setHeight = true, ULx = 0.3828125, ULy = "repeatX",  LLx = 0.4921875, LLy = "repeatX", URx = 0.3828125, URy = coordStart, LRx = 0.4921875, LRy = coordStart, anchors = { Anchor("BOTTOMLEFT", 0, 0, "BackdropBottomLeft", "BOTTOMRIGHT"), Anchor("BOTTOMRIGHT", 0, 0, "BackdropBottomRight", "BOTTOMLEFT") } },
        BackdropLeft        = { setWidth = true, setHeight = false,ULx = 0.0078125, ULy = coordStart, LLx = 0.0078125, LLy = "repeatY", URx = 0.1171875, URy = coordStart, LRx = 0.1171875, LRy = "repeatY",  anchors = { Anchor("TOPLEFT", 0, 0, "BackdropTopLeft", "BOTTOMLEFT"), Anchor("BOTTOMLEFT", 0, 0, "BackdropBottomLeft", "TOPLEFT") } },
        BackdropRight       = { setWidth = true, setHeight = false,ULx = 0.1328125, ULy = coordStart, LLx = 0.1328125, LLy = "repeatY", URx = 0.2421875, URy = coordStart, LRx = 0.2421875, LRy = "repeatY",  anchors = { Anchor("TOPRIGHT", 0, 0, "BackdropTopRight", "BOTTOMRIGHT"), Anchor("BOTTOMRIGHT", 0, 0, "BackdropBottomRight", "TOPRIGHT") } },
        BackdropCenter      = { setWidth = false,setHeight = false,ULx = 0,         ULy = 0,          LLx = 0,         LLy = "repeatY", URx = "repeatX", URy = 0,          LRx = "repeatX", LRy = "repeatY"  },
    }
    local defaultEdgeSize   = 39     -- the old default

    for name in pairs(textureUVs) do
        UI.Property         {
            name            = name,
            require         = Frame,
            childtype       = Texture,
        }
    end

    local backdropHookded   = Toolset.newtable(true)
    local backdropInfo      = Toolset.newtable(true)
    local backdropColor     = Toolset.newtable(true)
    local backdropBrdColor  = Toolset.newtable(true)
    local backdropBrdBlend  = Toolset.newtable(true)

    local function getCoordValue(coord, pieceSetup, repeatX, repeatY)
        local value         = textureUVs[pieceSetup][coord]
        if value == "repeatX" then
            return repeatX
        elseif value == "repeatY" then
            return repeatY
        else
            return value
        end
    end

    local function setupCoordinates(pieceSetup, repeatX, repeatY)
        return getCoordValue("ULx", pieceSetup, repeatX, repeatY), getCoordValue("ULy", pieceSetup, repeatX, repeatY),
            getCoordValue("LLx", pieceSetup, repeatX, repeatY), getCoordValue("LLy", pieceSetup, repeatX, repeatY),
            getCoordValue("URx", pieceSetup, repeatX, repeatY), getCoordValue("URy", pieceSetup, repeatX, repeatY),
            getCoordValue("LRx", pieceSetup, repeatX, repeatY), getCoordValue("LRy", pieceSetup, repeatX, repeatY)
    end

    local function applyTextureCoords(self, retryCnt)
        local backdrop          = backdropInfo[self[0]]
        if not backdrop then return end

        local width             = self:GetWidth()
        local height            = self:GetHeight()
        local effectiveScale    = self:GetEffectiveScale()
        local edgeSize          = backdrop.edgeSize or defaultEdgeSize
        local edgeRepeatX       = edgeSize > 0 and max(0, (width / edgeSize) * effectiveScale - 2 - coordStart) or 1
        local edgeRepeatY       = edgeSize > 0 and max(0, (height / edgeSize) * effectiveScale - 2 - coordStart) or 1

        local repeatX           = 1
        local repeatY           = 1

        if backdrop.tile then
            local divisor       = backdrop.tileSize
            if not divisor or divisor == 0 then
                divisor         = edgeSize
            end
            if divisor ~= 0 then
                repeatX         = (width / divisor) * effectiveScale
                repeatY         = (height / divisor) * effectiveScale
            end
        end

        local ok                = true
        for name in pairs(textureUVs) do
            local texture       = getPropertyChild(self, name)
            if texture then
                if name == "BackdropCenter" then
                    ok          = pcall(texture.SetTexCoord, texture, setupCoordinates(name, repeatX, repeatY))
                else
                    ok          = pcall(texture.SetTexCoord, texture, setupCoordinates(name, edgeRepeatX, edgeRepeatY))
                end
                if not ok then
                    retryCnt    = (type(retryCnt) == "number" and retryCnt or 0) + 1
                    if type(retryCnt) == "number" and retryCnt > 5 then return end
                    return Next(applyTextureCoords, self, retryCnt)
                end
            end
        end
    end

    local function applyBackdrop(self)
        local backdrop          = backdropInfo[self[0]]

        if backdrop == false then
            backdropInfo[self[0]] = nil

            -- Clear the backdrop settings
            if getPropertyChild(self, "BackdropTopLeft") then
                for name in pairs(textureUVs) do
                    local texture       = getPropertyChild(self, name)
                    if texture then
                        -- Not using the style to reduce the cost for dynamic settings
                        texture:ClearAllPoints()
                        texture:SetDrawLayer("ARTWORK")
                        texture:SetBlendMode("ADD")
                        texture:SetTexCoord(0, 1, 0, 1)
                        texture:SetTexture(nil)
                        texture:SetVertexColor(1, 1, 1)
                    end
                end

                Style[self] = {
                    BackdropTopLeft     = NIL,
                    BackdropTopRight    = NIL,
                    BackdropBottomLeft  = NIL,
                    BackdropBottomRight = NIL,
                    BackdropTop         = NIL,
                    BackdropBottom      = NIL,
                    BackdropLeft        = NIL,
                    BackdropRight       = NIL,
                    BackdropCenter      = NIL,
                }
            end
        elseif backdrop then
            local x, y, x1, y1      = 0, 0, 0, 0
            local edgeSize          = backdrop.edgeSize or defaultEdgeSize

            if backdrop.bgFile then
                x                   = -edgeSize
                y                   =  edgeSize
                x1                  =  edgeSize
                y1                  = -edgeSize

                if backdrop.insets then
                    x               = x  + (backdrop.insets.left   or 0)
                    y               = y  - (backdrop.insets.top    or 0)
                    x1              = x1 - (backdrop.insets.right  or 0)
                    y1              = y1 + (backdrop.insets.bottom or 0)
                end
            end

            local tileWrapMode      = backdrop.tile and "REPEAT" or nil
            local edgeWrapMode      = backdrop.tileEdge ~= false and "REPEAT" or nil

            for name, set in pairs(textureUVs) do
                getPropertyChild(self, name, true)
            end

            for name, set in pairs(textureUVs) do
                local texture       = getPropertyChild(self, name)

                texture:SetSnapToPixelGrid(false)
                texture:SetTexelSnappingBias(0)

                if name == "BackdropCenter" then
                    texture:SetDrawLayer("BACKGROUND")
                    texture:SetTexture(backdrop.bgFile, tileWrapMode, tileWrapMode)
                    texture:SetLocation{
                        Anchor("TOPLEFT", x, y, "BackdropTopLeft", "BOTTOMRIGHT"),
                        Anchor("BOTTOMRIGHT", x1, y1, "BackdropBottomRight", "TOPLEFT"),
                    }
                else
                    texture:SetDrawLayer("BORDER")
                    texture:SetTexture(backdrop.edgeFile, edgeWrapMode, edgeWrapMode)
                    texture:SetLocation(set.anchors)
                    if set.setWidth then texture:SetWidth(edgeSize) end
                    if set.setHeight then texture:SetHeight(edgeSize) end
                end
            end

            return applyTextureCoords(self)
        end
    end

    local function applyBackdropColor(self)
        local texture           = getPropertyChild(self, "BackdropCenter")
        local color             = backdropColor[self[0]] or Color.WHITE
        if texture then
            texture:SetVertexColor(color.r, color.g, color.b, color.a)
        end
    end

    local function applyBackdropBorderColor(self)
        local color             = backdropBrdColor[self[0]] or Color.WHITE
        for name in pairs(textureUVs) do
            if name ~= "BackdropCenter" then
                local texture   = getPropertyChild(self, name)
                if texture then
                    texture:SetVertexColor(color.r, color.g, color.b, color.a)
                end
            end
        end
    end

    local function applyBackdropBorderBlendMode(self)
        local alphaMode         = backdropBrdBlend[self[0]] or "ADD"
        for name in pairs(textureUVs) do
            if name ~= "BackdropCenter" then
                local texture   = getPropertyChild(self, name)
                if texture then
                    texture:SetBlendMode(alphaMode)
                end
            end
        end
    end

    --- the backdrop graphic for the frame
    UI.Property             {
        name                = "Backdrop",
        type                = BackdropType,
        require             = Frame,
        nilable             = true,
        set                 = function(self, val)
            if val and (val.edgeFile or val.bgFile) then
                backdropInfo[self[0]] = clone(val, true)

                if not backdropHookded[self[0]] then
                    backdropHookded[self[0]] = true
                    self:HookScript("OnSizeChanged", applyTextureCoords)
                end
            elseif backdropInfo[self[0]] then
                backdropInfo[self[0]] = false
            end

            return applyBackdrop(self)
        end,
        get                 = function(self)
            return clone(backdropInfo[self[0]], true)
        end,
    }

    --- the shading color for the frame's border graphic
    UI.Property             {
        name                = "BackdropBorderColor",
        type                = ColorType,
        require             = Frame,
        default             = Color.WHITE,
        set                 = function(self, val)
            local color     = backdropBrdColor[self[0]]
            if not color then
                backdropBrdColor[self[0]] = val and Color(val.r, val.g, val.b, val.a)
            else
                color.r     = val.r
                color.g     = val.g
                color.b     = val.b
                color.a     = val.a
            end
            return applyBackdropBorderColor(self)
        end,
        get                 = function(self)
            local color     = backdropBrdColor[self[0]]
            return color and Color(color.r, color.g, color.b, color.a)
        end,
        depends             = { "Backdrop" },
    }

    --- the shading color for the frame's background graphic
    UI.Property             {
        name                = "BackdropColor",
        type                = ColorType,
        require             = Frame,
        default             = Color.WHITE,
        set                 = function(self, val)
            local color     = backdropColor[self[0]]
            if not color then
                backdropColor[self[0]] = val and Color(val.r, val.g, val.b, val.a)
            else
                color.r     = val.r
                color.g     = val.g
                color.b     = val.b
                color.a     = val.a
            end
            return applyBackdropColor(self)
        end,
        get                 = function(self)
            local color     = backdropColor[self[0]]
            return color and Color(color.r, color.g, color.b, color.a)
        end,
        depends             = { "Backdrop" },
    }

    --- The blend mode of the backdrop border
    UI.Property             {
        name                = "BackdropBorderBlendMode",
        type                = AlphaMode,
        require             = Frame,
        default             = "ADD",
        set                 = function(self, val)
            if backdropInfo[self[0]] then
                backdropBrdBlend[self[0]] = val
            else
                backdropBrdBlend[self[0]] = nil
            end
            return applyBackdropBorderBlendMode(self)
        end,
        get                 = function(self)
            return backdropBrdBlend[self[0]]
        end,
        depends             = { "Backdrop" },
    }
end