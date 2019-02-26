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
--                      LayoutFrame                       --
------------------------------------------------------------
do
    --- the frame's transparency value(0-1)
    Style.Property  {
        name    = "Alpha",
        type    = ColorFloat,
        require = { LayoutFrame, Line },
        default = 1,
        get     = function(self) return self:GetAlpha() end,
        set     = function(self, alpha) self:SetAlpha(alpha) end,
    }

    --- the height of the LayoutFrame
    Style.Property  {
        name    = "Height",
        type    = Number,
        require = { LayoutFrame, Line },
        get     = function(self) return self:GetHeight() end,
        set     = function(self, height) self:SetHeight(height) end,
    }

    --- Whether ignore parent's alpha settings
    Style.Property  {
        name    = "ParentAlphaIgnored",
        type    = Boolean,
        require = { LayoutFrame, Line },
        default = false,
        get     = function(self) return self:IsIgnoringParentAlpha() end,
        set     = function(self, flag) self:SetIgnoreParentAlpha(flag) end,
    }

    --- Whether ignore prent's scal settings
    Style.Property  {
        name    = "ParentScaleIgnored",
        type    = Boolean,
        require = { LayoutFrame, Line },
        default = false,
        get     = function(self) return self:IsIgnoringParentScale() end,
        set     = function(self, flag) self:SetIgnoreParentScale(flag) end,
    }

    --- the location of the LayoutFrame
    Style.Property  {
        name    = "Location",
        type    = Anchors,
        require = LayoutFrame,
        get     = function(self) return LayoutFrame.GetLocation(GetProxyUI(self)) end,
        set     = function(self, loc)   LayoutFrame.SetLocation(GetProxyUI(self), loc) end,
        clear   = function(self) self:ClearAllPoints() end,
    }

    --- the frame's scale factor or the scale animation's setting
    Style.Property  {
        name    = "Scale",
        type    = PositiveNumber,
        require = { LayoutFrame, Scale },
        default = 1,
        get     = function(self) return self:GetScale() end,
        set     = function(self, scale) self:SetScale(scale) end,
    }

    --- The size of the LayoutFrame
    Style.Property  {
        name    = "Size",
        type    = Size,
        require = { LayoutFrame, Line },
        get     = function(self) return Size(self:GetSize()) end,
        set     = function(self, size) self:SetSize(size.width, size.height) end,
    }

    --- wheter the LayoutFrame is shown or not.
    Style.Property  {
        name    = "Visible",
        type    = Boolean,
        require = { LayoutFrame, Line },
        default = true,
        get     = function(self) return self:IsShown() and true or false end,
        set     = function(self, visible) self:SetShown(visible) end,
    }

    --- the width of the LayoutFrame
    Style.Property  {
        name    = "Width",
        type    = Number,
        require = { LayoutFrame, Line },
        get     = function(self) return self:GetWidth() end,
        set     = function(self, width) self:SetWidth(width) end,
    }
end

------------------------------------------------------------
--                      LayeredFrame                      --
------------------------------------------------------------
do
    --- the layer at which the LayeredFrame's graphics are drawn relative to others in its frame
    Style.Property  {
        name    = "DrawLayer",
        type    = DrawLayer,
        require = { Texture, FontString, ModelScene, Line },
        default = "ARTWORK",
        get     = function(self) return self:GetDrawLayer() end,
        set     = function(self, layer) return self:SetDrawLayer(layer) end,
    }

    --- the color shading for the LayeredFrame's graphics
    Style.Property  {
        name    = "VertexColor",
        type    = ColorType,
        require = { Texture, FontString, Line },
        default = Color(1, 1, 1),
        get     = function(self) if self.GetVertexColor then return Color(self:GetVertexColor()) end end,
        set     = function(self, color) self:SetVertexColor(color.r, color.g, color.b, color.a) end,
    }
end

------------------------------------------------------------
--                       FontFrame                        --
------------------------------------------------------------
do
    FONT_TYPES  = { EditBox, FontString, MessageFrame, SimpleHTML }

    --- the font settings
    Style.Property  {
        name    = "Font",
        type    = FontType,
        require = FONT_TYPES,
        get     = function(self)
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
        set     = function(self, font)
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
    }

    --- the Font object
    Style.Property  {
        name    = "FontObject",
        type    = FontObject,
        require = FONT_TYPES,
        get     = function(self) return self:GetFontObject() end,
        set     = function(self, fontObject) self:SetFontObject(fontObject) end,
    }

    --- the fontstring's horizontal text alignment style
    Style.Property  {
        name    = "JustifyH",
        type    = JustifyHType,
        require = FONT_TYPES,
        default = "CENTER",
        get     = function(self) return self:GetJustifyH() end,
        set     = function(self, justifyH) self:SetJustifyH(justifyH) end,
    }

    --- the fontstring's vertical text alignment style
    Style.Property  {
        name    = "JustifyV",
        type    = JustifyVType,
        require = FONT_TYPES,
        default = "MIDDLE",
        get     = function(self) return self:GetJustifyV() end,
        set     = function(self, justifyV) self:SetJustifyV(justifyV) end,
    }

    --- the color of the font's text shadow
    Style.Property  {
        name    = "ShadowColor",
        type    = Color,
        require = FONT_TYPES,
        default = Color(0, 0, 0, 0),
        get     = function(self) return Color(self:GetShadowColor()) end,
        set     = function(self, color) self:SetShadowColor(color.r, color.g, color.b, color.a) end,
    }

    --- the offset of the fontstring's text shadow from its text
    Style.Property  {
        name    = "ShadowOffset",
        type    = Dimension,
        require = FONT_TYPES,
        default = Dimension(0, 0),
        get     = function(self) return Dimension(self:GetShadowOffset()) end,
        set     = function(self, offset) self:SetShadowOffset(offset.x, offset.y) end,
    }

    --- the fontstring's amount of spacing between lines
    Style.Property  {
        name    = "Spacing",
        type    = Number,
        require = FONT_TYPES,
        default = 0,
        get     = function(self) return self:GetSpacing() end,
        set     = function(self, spacing) self:SetSpacing(spacing) end,
    }

    --- the fontstring's default text color
    Style.Property  {
        name    = "TextColor",
        type    = Color,
        require = FONT_TYPES,
        default = Color(1, 1, 1),
        get     = function(self) return Color(self:GetTextColor()) end,
        set     = function(self, color) self:SetTextColor(color.r, color.g, color.b, color.a) end,
    }

    --- whether the text wrap will be indented
    Style.Property  {
        name    = "IndentedWordWrap",
        type    = Boolean,
        require = FONT_TYPES,
        default = false,
        get     = function(self) return self:GetIndentedWordWrap() end,
        set     = function(self, flag) self:SetIndentedWordWrap(flag) end,
    }
end

------------------------------------------------------------
--                        Texture                         --
------------------------------------------------------------
do
    --- the atlas setting of the texture
    Style.Property  {
        name    = "Atlas",
        type    = AtlasType,
        require = { Texture, Line },
        get     = function(self) return AtlasType(self:GetAtlas()) end,
        set     = function(self, val) self:SetAtlas(val.atlas, val.useAtlasSize) end,
        clear   = function(self) self:SetAtlas(nil) end,
    }

    --- the blend mode of the texture
    Style.Property  {
        name    = "BlendMode",
        type    = AlphaMode,
        require = { Texture, Line },
        default = "ADD",
        get     = function(self) return self:GetBlendMode() end,
        set     = function(self, val) self:SetBlendMode(val) end,
    }

    --- the texture's color
    Style.Property  {
        name    = "Color",
        type    = ColorType,
        require = { Texture, Line },
        get     = function(self)
            local val               = self:GetTexture()
            if type(val) == string then
                local r, g, b, a    = val:match("^Color%-(%x%x)(%x%x)(%x%x)(%x%x)")
                if r then
                    r, g, b, a      = tonumber(r, 16)/255, tonumber(g, 16)/255, tonumber(b, 16)/255, tonumber(a, 16)/255
                    return Color(r, g, b, a)
                end
            end
        end,
        set     = function(self, color) self:SetColorTexture(color.r, color.g, color.b, color.a) end,
        clear   = function(self) self:SetTexture(nil) end,
    }

    --- whether the texture image should be displayed with zero saturation
    Style.Property  {
        name    = "Desaturated",
        type    = Boolean,
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:IsDesaturated() end,
        set     = function(self, val) self:SetDesaturated(val) end,
    }

    --- The texture's desaturation
    Style.Property  {
        name    = "Desaturation",
        type    = ColorFloat,
        require = { Texture, Line, Model },
        default = 0,
        get     = function(self) return self:GetDesaturation() end,
        set     = function(self, val) self:SetDesaturation(val) end,
    }

    --- Whether the texture is horizontal tile
    Style.Property  {
        name    = "HorizTile",
        type    = Boolean,
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:GetHorizTile() end,
        set     = function(self, val) self:SetHorizTile(val) end,
    }

    --- The gradient color shading for the texture
    Style.Property  {
        name    = "Gradient",
        type    = GradientType,
        require = { Texture, Line },
        set     = function(self, val) self:SetGradient(val.orientation, val.mincolor.r, val.mincolor.g, val.mincolor.b, val.maxcolor.r, val.maxcolor.g, val.maxcolor.b) end,
        clear   = function(self) self:SetGradient("HORIZONTAL", 1, 1, 1, 1, 1, 1) end,
    }

    --- The gradient color shading (including opacity in the gradient) for the texture
    Style.Property  {
        name    = "GradientAlpha",
        type    = GradientType,
        require = { Texture, Line },
        set     = function(self, val) self:SetGradientAlpha(val.orientation, val.mincolor.r, val.mincolor.g, val.mincolor.b, val.mincolor.a, val.maxcolor.r, val.maxcolor.g, val.maxcolor.b, val.maxcolor.a) end,
        clear   = function(self) self:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 1, 1, 1, 1, 1) end,
    }

    --- whether the texture object loads its image file in the background
    Style.Property  {
        name    = "NonBlocking",
        type    = Boolean,
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:GetNonBlocking() end,
        set     = function(self, val) self:SetNonBlocking(val) end,
    }

    --- The rotation of the texture
    Style.Property  {
        name    = "Rotation",
        type    = Number,
        require = { Texture, Line, Cooldown },
        get     = function(self) return self:GetRotation() end,
        set     = function(self, val) self:SetRotation(val) end,
    }

    --- whether snap to pixel grid
    Style.Property  {
        name    = "SnapToPixelGrid",
        type    = Boolean,
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:IsSnappingToPixelGrid() end,
        set     = function(self, val) self:SetSnapToPixelGrid(val) end,
    }

    --- the texel snapping bias
    Style.Property  {
        name    = "TexelSnappingBias",
        type    = Number,
        require = { Texture, Line },
        default = 0,
        get     = function(self) return self:GetTexelSnappingBias() end,
        set     = function(self, val) self:SetTexelSnappingBias(val) end,
    }

    --- The corner coordinates for scaling or cropping the texture image
    Style.Property  {
        name    = "TexCoord",
        type    = RectType,
        require = { Texture, Line },
        get     = function(self) return RectType(self:GetTexCoord()) end,
        set     = function(self, val) self:SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy) end,
        clear   = function(self) self:SetTexCoord(0, 1, 0, 1) end,
    }

    --- The texture file id
    Style.Property  {
        name    = "TextureFileID",
        type    = Number,
        require = { Texture, Line },
        get     = function(self) return self:GetTextureFileID() end,
        set     = function(self, val) self:SetTexture(val) end,
        clear   = function(self) self:SetTexture(nil) end,
    }

    --- The texture file path
    Style.Property  {
        name    = "TextureFilePath",
        type    = String,
        require = { Texture, Line },
        get     = function(self) return self:GetTextureFilePath() end,
        set     = function(self, val) self:SetTexture(val) end,
        clear   = function(self) self:SetTexture(nil) end,
    }

    --- The vertex offset of upperleft corner
    Style.Property  {
        name    = "VertexOffsetUpperLeft",
        type    = Dimension,
        require = { Texture, Line },
        get     = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.UpperLeft)) end,
        set     = function(self, val) self:SetVertexOffset(VertexIndexType.UpperLeft, val.x, val.y) end,
        clear   = function(self) self:SetVertexOffset(VertexIndexType.UpperLeft, 0, 0) end,
    }

    --- The vertex offset of lowerleft corner
    Style.Property  {
        name    = "VertexOffsetLowerLeft",
        type    = Dimension,
        require = { Texture, Line },
        get     = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.LowerLeft)) end,
        set     = function(self, val) self:SetVertexOffset(VertexIndexType.LowerLeft, val.x, val.y) end,
        clear   = function(self) self:SetVertexOffset(VertexIndexType.LowerLeft, 0, 0) end,
    }

    --- The vertex offset of upperright corner
    Style.Property  {
        name    = "VertexOffsetUpperRight",
        type    = Dimension,
        require = { Texture, Line },
        get     = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.UpperRight)) end,
        set     = function(self, val) self:SetVertexOffset(VertexIndexType.UpperRight, val.x, val.y) end,
        clear   = function(self) self:SetVertexOffset(VertexIndexType.UpperRight, 0, 0) end,
    }

    --- The vertex offset of lowerright corner
    Style.Property  {
        name    = "VertexOffsetLowerRight",
        type    = Dimension,
        require = { Texture, Line },
        get     = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.LowerRight)) end,
        set     = function(self, val) self:SetVertexOffset(VertexIndexType.LowerRight, val.x, val.y) end,
        clear   = function(self) self:SetVertexOffset(VertexIndexType.LowerRight, 0, 0) end,
    }

    --- Whether the texture is vertical tile
    Style.Property  {
        name    = "VertTile",
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:GetVertTile() end,
        set     = function(self, val) self:SetVertTile(val) end,
    }
end

------------------------------------------------------------
--                          Line                          --
------------------------------------------------------------
do
    local function toAnchor(self, p, f, x, y)
        local t = self:GetParent()
        if IsSameUI(f, t) then
            f   = nil
        else
            f   = f:GetName(not IsSameUI(f:GetParent(), t))
            if not f then return nil end
        end
        return Anchor(p, x, y, f)
    end

    local function fromAnchor(self, anchor)
        local f = anchor.relativeTo
        local t = self:GetParent()

        if f then
            f   = t and UIObject.GetChild(t, f) or UIObject.FromName(f)
            if not f then f = t end
        else
            f   = t
        end

        return anchor.point, f, anchor.x or 0, anchor.y or 0
    end

    --- the start point of the line
    Style.Property  {
        name    = "StartPoint",
        type    = Anchor,
        require = Line,
        set     = function(self, anchor) self:SetStartPoint(fromAnchor(anchor)) end,
        get     = function(self) return toAnchor(self:GetStartPoint()) end,
    }

    --- the end point of the line
    Style.Property  {
        name    = "EndPoint",
        type    = Anchor,
        require = Line,
        set     = function(self, anchor) self:SetEndPoint(fromAnchor(anchor)) end,
        get     = function(self) return toAnchor(self:GetEndPoint()) end,
    }

    --- the thickness of the line
    Style.Property  {
        name    = "Thickness",
        type    = Number,
        require = Line,
        default = 1,
        set     = function(self, val) self:SetThickness(val) end,
        get     = function(self) return self:GetThickness() end,
    }
end

------------------------------------------------------------
--                       FontString                       --
------------------------------------------------------------
do
    --- The alpha gradient
    Style.Property  {
        name    = "AlphaGradient",
        type    = AlphaGradientType,
        require = FontString,
        set     = function(self, val) self:SetAlphaGradient(val.start, val.length) end,
        clear   = function(self) self:SetAlphaGradient(0, 10^6) end,
    }

    --- the max lines of the text
    Style.Property  {
        name    = "MaxLines",
        type    = Number,
        require = FontString,
        default = 0,
        set     = function(self, val) self:SetMaxLines(val) end,
        get     = function(self) return self:GetMaxLines() end,
    }

    --- whether long lines of text will wrap within or between words
    Style.Property  {
        name    = "NonSpaceWrap",
        type    = Boolean,
        require = FontString,
        default = false,
        set     = function(self, val) self:SetNonSpaceWrap(val) end,
        get     = function(self) return self:CanNonSpaceWrap() end,
    }

    --- the text to be displayed in the font string
    Style.Property  {
        name    = "Text",
        type    = String,
        require = { FontString, Button, EditBox },
        default = "",
        set     = function(self, val) self:SetText(val) end,
        get     = function(self) return self:GetText() end,
    }

    --- the height of the text displayed in the font string
    Style.Property  {
        name    = "TextHeight",
        type    = Boolean,
        require = FontString,
        set     = function(self, val) self:SetTextHeight(val) end,
        get     = function(self) return self:GetLineHeight() end,
    }

    --- whether long lines of text in the font string can wrap onto subsequent lines
    Style.Property  {
        name    = "WordWrap",
        type    = Boolean,
        require = FontString,
        default = true,
        set     = function(self, val) self:SetWordWrap(val) end,
        get     = function(self) return self:CanWordWrap() end,
    }
end

------------------------------------------------------------
--                      Animation                         --
------------------------------------------------------------
do
    --- looping type for the animation group: BOUNCE , NONE  , REPEAT
    Style.Property  {
        name    = "Looping",
        type    = AnimLoopType,
        require = AnimationGroup,
        default = "NONE",
        set     = function(self, val) self:SetLooping(val) end,
        get     = function(self) return self:GetLooping() end,
    }

    --- Whether to final alpha is set
    Style.Property  {
        name    = "ToFinalAlpha",
        type    = Boolean,
        require = AnimationGroup,
        default = false,
        set     = function(self, val) self:SetToFinalAlpha(val) end,
        get     = function(self) return self:IsSetToFinalAlpha() end,
    }

    --- Time for the animation to progress from start to finish (in seconds)
    Style.Property  {
        name    = "Duration",
        type    = Number,
        require = Animation,
        default = 0,
        set     = function(self, val) self:SetDuration(val) end,
        get     = function(self) return self:GetDuration() end,
    }

    --- Time for the animation to delay after finishing (in seconds)
    Style.Property  {
        name    = "EndDelay",
        type    = Number,
        require = Animation,
        set     = function(self, val) self:SetEndDelay(val) end,
        get     = function(self) return self:GetEndDelay() end,
    }

    --- Position at which the animation will play relative to others in its group (between 0 and 100)
    Style.Property  {
        name    = "Order",
        type    = Integer,
        require = { Animation, ControlPoint },
        set     = function(self, val) self:SetOrder(val) end,
        get     = function(self) return self:GetOrder() end,
    }

    --- The smooth progress of the animation
    Style.Property  {
        name    = "SmoothProgress",
        type    = Number,
        require = Animation,
        set     = function(self, val) self:SetSmoothProgress(val) end,
        get     = function(self) return self:GetSmoothProgress() end,
    }

    --- Type of smoothing for the animation, IN, IN_OUT, NONE, OUT
    Style.Property  {
        name    = "Smoothing",
        type    = AnimSmoothType,
        require = Animation,
        default = "NONE",
        set     = function(self, val) self:SetSmoothing(val) end,
        get     = function(self) return self:GetSmoothing() end,
    }

    --- Amount of time the animation delays before its progress begins (in seconds)
    Style.Property  {
        name    = "StartDelay",
        type    = Number,
        require = Animation,
        default = 0,
        set     = function(self, val) self:SetStartDelay(val) end,
        get     = function(self) return self:GetStartDelay() end,
    }

    --- the animation's amount of alpha (opacity) start from
    Style.Property  {
        name    = "FromAlpha",
        type    = ColorFloat,
        require = Alpha,
        default = 0,
        set     = function(self, val) self:SetFromAlpha(val) end,
        get     = function(self) return self:GetFromAlpha() end,
    }

    --- the animation's amount of alpha (opacity) end to
    Style.Property  {
        name    = "ToAlpha",
        type    = ColorFloat,
        require = Alpha,
        default = 0,
        set     = function(self, val) self:SetToAlpha(val) end,
        get     = function(self) return self:GetToAlpha() end,
    }

    --- The curve type of the path
    Style.Property  {
        name    = "Curve",
        type    = AnimCurveType,
        require = Path,
        default = "NONE",
        set     = function(self, val) self:SetCurve(val) end,
        get     = function(self) return self:GetCurve() end,
    }

    --- the offsets settings
    Style.Property  {
        name    = "Offset",
        type    = Dimension,
        require = { ControlPoint, Translation },
        set     = function(self, val) self:SetOffset(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetOffset()) end,
    }

    --- the animation's rotation amount (in degrees)
    Style.Property  {
        name    = "Degrees",
        type    = Number,
        require = Rotation,
        get     = function(self) return self:GetDegrees() end,
        set     = function(self, val) self:SetDegrees(val) end,
    }

    --- the rotation animation's origin point
    Style.Property  {
        name    = "Origin",
        type    = AnimOriginType,
        require = { Rotation, Scale },
        get     = function(self) return AnimOriginType(self:GetOrigin()) end,
        set     = function(self, val) self:SetOrigin(val.point, val.x, val.y) end,
    }

    --- the animation's rotation amount (in radians)
    Style.Property  {
        name    = "Radians",
        type    = Number,
        require = Rotation,
        get     = function(self) return self:GetRadians() end,
        set     = function(self, val) self:SetRadians(val) end,
    }

    --- the animation's scaling factors
    Style.Property  {
        name    = "KeepScale",
        type    = Dimension,
        require = Scale,
        default = Dimension(1, 1),
        set     = function(self, val) self:SetScale(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetScale()) end,
    }

    --- the animation's scale amount that start from
    Style.Property  {
        name    = "FromScale",
        type    = Dimension,
        require = Scale,
        default = Dimension(1, 1),
        set     = function(self, val) self:SetFromScale(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetFromScale()) end,
    }

    --- the animation's scale amount that end to
    Style.Property  {
        name    = "ToScale",
        type    = Dimension,
        require = Scale,
        default = Dimension(1, 1),
        set     = function(self, val) self:SetToScale(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetToScale()) end,
    }
end

------------------------------------------------------------
--                         Frame                          --
------------------------------------------------------------
do
    --- the backdrop graphic for the frame
    Style.Property  {
        name    = "Backdrop",
        type    = BackdropType,
        require = Frame,
        nilable = true,
        set     = function(self, val) self:SetBackdrop(val) end,
        get     = function(self) return self:GetBackdrop() end,
    }

    --- the shading color for the frame's border graphic
    Style.Property  {
        name    = "BackdropBorderColor",
        type    = ColorType,
        require = Frame,
        default = Color.TRANSPARENT,
        set     = function(self, val) self:SetBackdropBorderColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) local r, g, b, a = self:GetBackdropBorderColor() if r then return Color(r, g, b, a) end end,
    }

    --- the shading color for the frame's background graphic
    Style.Property  {
        name    = "BackdropColor",
        type    = ColorType,
        require = Frame,
        default = Color.TRANSPARENT,
        set     = function(self, val) self:SetBackdropColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) local r, g, b, a = self:GetBackdropColor() if r then return Color(r, g, b, a) end end,
    }

    --- whether the frame's boundaries are limited to those of the screen
    Style.Property  {
        name    = "ClampedToScreen",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetClampedToScreen(val) end,
        get     = function(self) return self:IsClampedToScreen() end,
    }

    --- offsets from the frame's edges used when limiting user movement or resizing of the frame
    Style.Property  {
        name    = "ClampRectInsets",
        type    = Inset,
        require = Frame,
        default = Inset(0, 0, 0, 0),
        set     = function(self, val) self:SetClampRectInsets(val.left, val.right, val.top, val.bottom) end,
        get     = function(self) return Inset(self:GetClampRectInsets()) end,
    }

    --- Whether the children is limited to draw inside the frame's boundaries
    Style.Property  {
        name    = "ClipChildren",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetClipsChildren(val) end,
        get     = function(self) return self:DoesClipChildren() end,
    }

    --- the 3D depth of the frame (for stereoscopic 3D setups)
    Style.Property  {
        name    = "Depth",
        type    = Number,
        require = Frame,
        default = 0,
        set     = function(self, val) self:SetDepth(val) end,
        get     = function(self) return self:GetDepth() end,
    }

    --- Whether the frame don't save its location in layout-cache
    Style.Property  {
        name    = "DontSavePosition",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetDontSavePosition(val) end,
        get     = function(self) return self:GetDontSavePosition() end,
    }

    --- Whether the frame's child is render in flattens layers
    Style.Property  {
        name    = "FlattensRenderLayers",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetFlattensRenderLayers(val) end,
        get     = function(self) return self:GetFlattensRenderLayers() end,
    }

    --- the level at which the frame is layered relative to others in its strata
    Style.Property  {
        name    = "FrameLevel",
        type    = Number,
        require = Frame,
        default = 1,
        set     = function(self, val) self:SetFrameLevel(val) end,
        get     = function(self) return self:GetFrameLevel() end,
    }

    --- the general layering strata of the frame
    Style.Property  {
        name    = "FrameStrata",
        type    = FrameStrata,
        require = Frame,
        default = "MEDIUM",
        set     = function(self, val) self:SetFrameStrata(val) end,
        get     = function(self) return self:GetFrameStrata() end,
    }

    --- the insets from the frame's edges which determine its mouse-interactable area
    Style.Property  {
        name    = "HitRectInsets",
        type    = Inset,
        require = Frame,
        default = Inset(0, 0, 0, 0),
        set     = function(self, val) self:SetHitRectInsets(val.left, val.right, val.top, val.bottom) end,
        get     = function(self) return Inset(self:GetHitRectInsets()) end,
    }

    --- Whether the hyper links are enabled
    Style.Property  {
        name    = "HyperlinksEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetHyperlinksEnabled(val) end,
        get     = function(self) return self:GetHyperlinksEnabled() end,
    }

    --- a numeric identifier for the frame
    Style.Property  {
        name    = "ID",
        type    = Number,
        require = Frame,
        default = 0,
        set     = function(self, val) self:SetID(val) end,
        get     = function(self) return self:GetID() end,
    }

    --- whether the frame's depth property is ignored (for stereoscopic 3D setups)
    Style.Property  {
        name    = "IgnoringDepth",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:IgnoreDepth(val) end,
        get     = function(self) return self:IsIgnoringDepth() end,
    }

    --- Whether the joystick is enabled for the frame
    Style.Property  {
        name    = "JoystickEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:EnableJoystick(val) end,
        get     = function(self) return self:IsJoystickEnabled() end,
    }

    --- whether keyboard interactivity is enabled for the frame
    Style.Property  {
        name    = "KeyboardEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:EnableKeyboard(val) end,
        get     = function(self) return self:IsKeyboardEnabled() end,
    }

    --- the maximum size of the frame for user resizing
    Style.Property  {
        name    = "MaxResize",
        type    = Size,
        require = Frame,
        default = Size(0, 0),
        set     = function(self, val) self:SetMaxResize(val.width, val.height) end,
        get     = function(self) return Size(self:GetMaxResize()) end,
    }

    --- Whether the mouse click is enabled
    Style.Property  {
        name    = "MouseClickEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetMouseClickEnabled(val) end,
        get     = function(self) return self:IsMouseClickEnabled() end,
    }

    --- whether mouse interactivity is enabled for the frame
    Style.Property  {
        name    = "MouseEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:EnableMouse(val) end,
        get     = function(self) return self:IsMouseEnabled() end,
    }

    --- Whether the mouse motion in enabled
    Style.Property  {
        name    = "MouseMotionEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetMouseMotionEnabled(val) end,
        get     = function(self) return self:IsMouseMotionEnabled() end,
    }

    --- whether mouse wheel interactivity is enabled for the frame
    Style.Property  {
        name    = "MouseWheelEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:EnableMouseWheel(val) end,
        get     = function(self) return self:IsMouseWheelEnabled() end,
    }

    --- the minimum size of the frame for user resizing
    Style.Property  {
        name    = "MinResize",
        type    = Size,
        require = Frame,
        default = Size(0, 0),
        set     = function(self, val) self:SetMinResize(val.width, val.height) end,
        get     = function(self) return Size(self:GetMinResize()) end,
    }

    --- whether the frame can be moved by the user
    Style.Property  {
        name    = "Movable",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetMovable(val) end,
        get     = function(self) return self:IsMovable() end,
    }

    --- Whether the frame get the propagate keyboard input
    Style.Property  {
        name    = "PropagateKeyboardInput",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetPropagateKeyboardInput(val) end,
        get     = function(self) return self:GetPropagateKeyboardInput() end,
    }

    --- whether the frame can be resized by the user
    Style.Property  {
        name    = "Resizable",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetResizable(val) end,
        get     = function(self) return self:IsResizable() end,
    }

    --- whether the frame should automatically come to the front when clicked
    Style.Property  {
        name    = "Toplevel",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetToplevel(val) end,
        get     = function(self) return self:IsToplevel() end,
    }

    --- whether the frame should save/load custom position by the system
    Style.Property  {
        name    = "UserPlaced",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetUserPlaced(val) end,
        get     = function(self) return self:IsUserPlaced() end,
    }
end

------------------------------------------------------------
--                         Button                         --
------------------------------------------------------------
do
    --- Whether the button is enabled
    Style.Property  {
        name    = "Enabled",
        type    = Boolean,
        require = { Button, EditBox, Slider },
        default = true,
        set     = function(self, val) self:SetEnabled(val) end,
        get     = function(self) return self:IsEnabled() end,
    }

    --- the FontString object used for the button's label text
    Style.Property  {
        name    = "FontString",
        type    = FontString,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetFontString(val) end,
        get     = function(self) return self:GetFontString() end,
    }

    --- The button state
    Style.Property  {
        name    = "ButtonState",
        type    = ButtonStateType,
        require = Button,
        default = "NORMAL",
        set     = function(self, val) self:SetButtonState(val) end,
        get     = function(self) return self:GetButtonState() end,
    }

    --- Whether enable the motion script while disabled
    Style.Property  {
        name    = "MotionScriptsWhileDisabled",
        type    = Boolean,
        require = Button,
        default = false,
        set     = function(self, val) self:SetMotionScriptsWhileDisabled(val) end,
        get     = function(self) return self:GetMotionScriptsWhileDisabled() end,
    }

    --- the offset for moving the button's label text when pushed
    Style.Property  {
        name    = "PushedTextOffset",
        type    = Dimension,
        require = Button,
        default = Dimension(1.5665, -1.5665),
        set     = function(self, val) self:SetPushedTextOffset(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetPushedTextOffset()) end,
    }

    --- the texture object used when the button is pushed
    Style.Property  {
        name    = "PushedTexture",
        type    = Texture,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetPushedTexture(val) end,
        get     = function(self) return self:GetPushedTexture() end,
    }

    --- the texture object used when the button is highlighted
    Style.Property  {
        name    = "HighlightTexture",
        type    = Texture,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetHighlightTexture(val) end,
        get     = function(self) return self:GetHighlightTexture() end,
    }

    --- the texture object used for the button's normal state
    Style.Property  {
        name    = "NormalTexture",
        type    = Texture,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetNormalTexture(val) end,
        get     = function(self) return self:GetNormalTexture() end,
    }

    --- the texture object used when the button is disabled
    Style.Property  {
        name    = "DisabledTexture",
        type    = Texture,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetDisabledTexture(val) end,
        get     = function(self) return self:GetDisabledTexture() end,
    }

    --- the font object used when the button is highlighted
    Style.Property  {
        name    = "HighlightFontObject",
        type    = FontObject,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetHighlightFontObject(val) end,
        get     = function(self) return self:GetHighlightFontObject() end,
    }

    --- the font object used for the button's normal state
    Style.Property  {
        name    = "NormalFontObject",
        type    = FontObject,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetNormalFontObject(val) end,
        get     = function(self) return self:GetNormalFontObject() end,
    }

    --- the font object used for the button's disabled state
    Style.Property  {
        name    = "DisabledFontObject",
        type    = FontObject,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetDisabledFontObject(val) end,
        get     = function(self) return self:GetDisabledFontObject() end,
    }
end

------------------------------------------------------------
--                      CheckButton                       --
------------------------------------------------------------
do
    --- Whether the checkbutton is checked
    Style.Property  {
        name    = "Checked",
        type    = Boolean,
        require = CheckButton,
        default = false,
        set     = function(self, val) self:SetChecked(val) end,
        get     = function(self) return self:GetChecked() end,
    }

    --- the texture object used when the button is checked
    Style.Property  {
        name    = "CheckedTexture",
        type    = Texture,
        require = CheckButton,
        nilable = true,
        set     = function(self, val) self:SetCheckedTexture(val) end,
        get     = function(self) return self:GetCheckedTexture() end,
    }

    --- the texture object used when the button is disabled and checked
    Style.Property  {
        name    = "DisabledCheckedTexture",
        type    = Texture,
        require = CheckButton,
        nilable = true,
        set     = function(self, val) self:SetDisabledCheckedTexture(val) end,
        get     = function(self) return self:GetDisabledCheckedTexture() end,
    }
end

------------------------------------------------------------
--                      ColorSelect                       --
------------------------------------------------------------
do
    --- the HSV color value
    Style.Property  {
        name    = "ColorHSV",
        type    = HSVType,
        require = ColorSelect,
        default = HSVType(0, 0, 1),
        set     = function(self, val) self:SetColorHSV(val.h, val.s, val.v) end,
        get     = function(self) return HSVType(self:GetColorHSV()) end,
    }

    --- the RGB color value
    Style.Property  {
        name    = "ColorRGB",
        type    = ColorType,
        require = ColorSelect,
        default = Color.WHITE,
        set     = function(self, val) self:SetColorRGB(val.r, val.g, val.b, val.a) end,
        get     = function(self) return Color(self:GetColorRGB()) end,
    }

    --- the texture for the color picker's value slider background
    Style.Property  {
        name    = "ColorValueTexture",
        type    = Texture,
        require = ColorSelect,
        nilable = true,
        set     = function(self, val) self:SetColorValueTexture(val) end,
        get     = function(self) return self:GetColorValueTexture() end,
    }

    --- the texture for the selection indicator on the color picker's hue/saturation wheel
    Style.Property  {
        name    = "ColorWheelThumbTexture",
        type    = Texture,
        require = ColorSelect,
        nilable = true,
        set     = function(self, val) self:SetColorWheelThumbTexture(val) end,
        get     = function(self) return self:GetColorWheelThumbTexture() end,
    }

    --- the texture for the color picker's hue/saturation wheel
    Style.Property  {
        name    = "ColorWheelTexture",
        type    = Texture,
        require = ColorSelect,
        nilable = true,
        set     = function(self, val) self:SetColorWheelTexture(val) end,
        get     = function(self) return self:GetColorWheelTexture() end,
    }

    --- the texture for the color picker's value slider thumb
    Style.Property  {
        name    = "ColorValueThumbTexture",
        type    = Texture,
        require = ColorSelect,
        nilable = true,
        set     = function(self, val) self:SetColorValueThumbTexture(val) end,
        get     = function(self) return self:GetColorValueThumbTexture() end,
    }
end

------------------------------------------------------------
--                        Cooldown                        --
------------------------------------------------------------
do
    --- Sets the bling texture
    Style.Property  {
        name    = "BlingTexture",
        type    = TextureType,
        require = Cooldown,
        set     = function(self, val) if val.color then self:SetBlingTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) else self:SetBlingTexture(val) end end,
    }

    --- the duration currently shown by the cooldown frame in milliseconds
    Style.Property  {
        name    = "CooldownDuration",
        type    = Number,
        require = Cooldown,
        default = 0,
        set     = function(self, val) self:SetCooldownDuration(val) end,
        get     = function(self) self:GetCooldownDuration() end,
    }

    --- Whether the cooldown 'bling' when finsihed
    Style.Property  {
        name    = "DrawBling",
        type    = Boolean,
        require = Cooldown,
        default = true,
        set     = function(self, val) self:SetDrawBling(val) end,
        get     = function(self) self:GetDrawBling() end,
    }

    --- Whether a bright line should be drawn on the moving edge of the cooldown animation
    Style.Property  {
        name    = "DrawEdge",
        type    = Boolean,
        require = Cooldown,
        default = true,
        set     = function(self, val) self:SetDrawEdge(val) end,
        get     = function(self) self:GetDrawEdge() end,
    }

    --- Whether a shadow swipe should be drawn
    Style.Property  {
        name    = "DrawSwipe",
        type    = Boolean,
        require = Cooldown,
        default = true,
        set     = function(self, val) self:SetDrawSwipe(val) end,
        get     = function(self) self:GetDrawSwipe() end,
    }

    -- The edge scale
    Style.Property  {
        name    = "EdgeScale",
        type    = Number,
        require = Cooldown,
        default = math.sin(45 / 180 * math.pi),
        set     = function(self, val) self:SetEdgeScale(val) end,
        get     = function(self) self:GetEdgeScale() end,
    }

    --- Sets the edge texture
    Style.Property  {
        name    = "EdgeTexture",
        type    = TextureType,
        require = Cooldown,
        set     = function(self, val) if val.color then self:SetEdgeTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) else self:SetEdgeTexture(val) end end,
    }

    --- Whether hide count down numbers
    Style.Property  {
        name    = "HideCountdownNumbers",
        type    = Boolean,
        require = Cooldown,
        default = false,
        set     = function(self, val) self:SetHideCountdownNumbers(val) end,
    }

    --- Whether the cooldown animation "sweeps" an area of darkness over the underlying image; false if the animation darkens the underlying image and "sweeps" the darkened area away
    Style.Property  {
        name    = "Reverse",
        type    = Boolean,
        require = Cooldown,
        default = false,
        set     = function(self, val) self:SetReverse(val) end,
        get     = function(self) self:GetReverse() end,
    }

    --- the swipe color
    Style.Property  {
        name    = "SwipeColor",
        type    = ColorType,
        require = Cooldown,
        set     = function(self, val) self:SetSwipeColor(val) end,
    }

    --- the swipe texture
    Style.Property  {
        name    = "SwipeTexture",
        type    = TextureType,
        require = Cooldown,
        set     = function(self, val) if val.color then self:SetSwipeTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) else self:SetSwipeTexture(val) end end,
    }

    --- Whether use circular edge
    Style.Property  {
        name    = "UseCircularEdge",
        type    = Boolean,
        require = Cooldown,
        default = false,
        set     = function(self, val) self:SetUseCircularEdge(val) end,
    }
end

------------------------------------------------------------
--                        EditBox                         --
------------------------------------------------------------
do
    --- true if the arrow keys are ignored by the edit box unless the Alt key is held
    Style.Property  {
        name    = "AltArrowKeyMode",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetAltArrowKeyMode(val) end,
        get     = function(self) return self:GetAltArrowKeyMode() end,
    }

    --- true if the edit box automatically acquires keyboard input focus
    Style.Property  {
        name    = "AutoFocus",
        type    = Boolean,
        require = EditBox,
        default = true,
        set     = function(self, val) self:SetAutoFocus(val) end,
        get     = function(self) return self:IsAutoFocus() end,
    }

    --- the rate at which the text insertion blinks when the edit box is focused
    Style.Property  {
        name    = "BlinkSpeed",
        type    = Number,
        require = EditBox,
        default = 0.5,
        set     = function(self, val) self:SetBlinkSpeed(val) end,
        get     = function(self) return self:GetBlinkSpeed() end,
    }

    --- Whether count the invisible letters for max letters
    Style.Property  {
        name    = "CountInvisibleLetters",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetCountInvisibleLetters(val) end,
        get     = function(self) return self:IsCountInvisibleLetters() end,
    }

    Style.Property  {
        name    = "HighlightColor",
        type    = ColorType,
        require = EditBox,
        set     = function(self, val) self:SetHighlightColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) return Color(self:GetHighlightColor()) end,
    }

    --- the maximum number of history lines stored by the edit box
    Style.Property  {
        name    = "HistoryLines",
        type    = Number,
        require = EditBox,
        default = 0,
        set     = function(self, val) self:SetHistoryLines(val) end,
        get     = function(self) return self:GetHistoryLines() end,
    }

    --- the maximum number of bytes of text allowed in the edit box, default is 0(Infinite)
    Style.Property  {
        name    = "MaxBytes",
        type    = Integer,
        require = EditBox,
        default = 0,
        set     = function(self, val) self:SetMaxBytes(val) end,
        get     = function(self) return self:GetMaxBytes() end,
    }

    --- the maximum number of text characters allowed in the edit box
    Style.Property  {
        name    = "MaxLetters",
        type    = Integer,
        require = EditBox,
        default = 0,
        set     = function(self, val) self:SetMaxLetters(val) end,
        get     = function(self) return self:GetMaxLetters() end,
    }

    --- true if the edit box shows more than one line of text
    Style.Property  {
        name    = "MultiLine",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetMultiLine(val) end,
        get     = function(self) return self:IsMultiLine() end,
    }

    --- true if the edit box only accepts numeric input
    Style.Property  {
        name    = "Numeric",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetNumeric(val) end,
        get     = function(self) return self:IsNumeric() end,
    }

    --- the contents of the edit box as a number
    Style.Property  {
        name    = "Number",
        type    = Number,
        require = EditBox,
        default = 0,
        set     = function(self, val) self:SetNumber(val) end,
        get     = function(self) return self:GetNumber() end,
    }

    --- true if the text entered in the edit box is masked
    Style.Property  {
        name    = "Password",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetPassword(val) end,
        get     = function(self) return self:IsPassword() end,
    }

    --- the insets from the edit box's edges which determine its interactive text area
    Style.Property  {
        name    = "TextInsets",
        type    = Inset,
        require = EditBox,
        set     = function(self, val) self:SetTextInsets(val.left, val.right, val.top, val.bottom) end,
        get     = function(self) return Inset(self:GetTextInsets()) end,
    }

    Style.Property  {
        name    = "VisibleTextByteLimit",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetVisibleTextByteLimit(val) end,
        get     = function(self) return self:GetVisibleTextByteLimit() end,
    }
end

------------------------------------------------------------
--                      MessageFrame                      --
------------------------------------------------------------
do
    --- the duration of the fade-out animation for disappearing messages
    Style.Property  {
        name    = "FadeDuration",
        type    = Number,
        require = MessageFrame,
        default = 3,
        set     = function(self, val) self:SetFadeDuration(val) end,
        get     = function(self) return self:GetFadeDuration() end,
    }

    --- whether messages added to the frame automatically fade out after a period of time
    Style.Property  {
        name    = "Fading",
        type    = Boolean,
        require = MessageFrame,
        default = true,
        set     = function(self, val) self:SetFading(val) end,
        get     = function(self) return self:GetFading() end,
    }

    --- The power of the fade-out animation for disappearing messages
    Style.Property  {
        name    = "FadePower",
        type    = Number,
        require = MessageFrame,
        default = 1,
        set     = function(self, val) self:SetFadePower(val) end,
        get     = function(self) return self:GetFadePower() end,
    }

    --- the position at which new messages are added to the frame
    Style.Property  {
        name    = "InsertMode",
        type    = InsertMode,
        require = MessageFrame,
        default = "BOTTOM",
        set     = function(self, val) self:SetInsertMode(val) end,
        get     = function(self) return self:GetInsertMode() end,
    }

    --- the amount of time for which a message remains visible before beginning to fade out
    Style.Property  {
        name    = "TimeVisible",
        type    = Number,
        require = MessageFrame,
        default = 10,
        set     = function(self, val) self:SetTimeVisible(val) end,
        get     = function(self) return self:GetTimeVisible() end,
    }
end

------------------------------------------------------------
--                      ScrollFrame                       --
------------------------------------------------------------
do
    --- the scroll frame's current horizontal scroll position
    Style.Property  {
        name    = "HorizontalScroll",
        type    = Number,
        require = ScrollFrame,
        default = 0,
        set     = function(self, val) self:SetHorizontalScroll(val) end,
        get     = function(self) return self:GetHorizontalScroll() end,
    }

    --- the scroll frame's vertical scroll position
    Style.Property  {
        name    = "VerticalScroll",
        type    = Number,
        require = ScrollFrame,
        default = 0,
        set     = function(self, val) self:SetVerticalScroll(val) end,
        get     = function(self) return self:GetVerticalScroll() end,
    }

    --- The frame scrolled by the scroll frame
    Style.Property  {
        name    = "ScrollChild",
        type    = LayoutFrame,
        require = ScrollFrame,
        set     = function(self, val) self:SetScrollChild(val) end,
        get     = function(self) return self:GetScrollChild() end,
    }
end

------------------------------------------------------------
--                       SimpleHTML                       --
------------------------------------------------------------
do
    Style.Property  {
        name    = "HyperlinkFormat",
        type    = String,
        require = SimpleHTML,
        default = "%s",
        set     = function(self, val) self:SetHyperlinkFormat(val) end,
        get     = function(self) return self:GetHyperlinkFormat() end,
    }
end

------------------------------------------------------------
--                         Slider                         --
------------------------------------------------------------
do
    --- the texture object for the slider thumb
    Style.Property  {
        name    = "ThumbTexture",
        type    = Texture,
        require = Slider,
        set     = function(self, val) self:SetThumbTexture(val) end,
        get     = function(self) return self:GetThumbTexture() end,
    }

    --- the minimum and maximum values of the slider bar
    Style.Property  {
        name    = "MinMaxValues",
        type    = MinMax,
        require = { Slider, StatusBar },
        set     = function(self, val) self:SetMinMaxValues(val.min, val.max) end,
        get     = function(self) return MinMax(self:GetMinMaxValues()) end,
    }

    --- the orientation of the slider
    Style.Property  {
        name    = "Orientation",
        type    = Orientation,
        require = { Slider, StatusBar },
        set     = function(self, val) self:SetOrientation(val) end,
        get     = function(self) return self:GetOrientation() end,
    }

    --- the steps per page of the slider bar
    Style.Property  {
        name    = "StepsPerPage",
        type    = Number,
        require = Slider,
        default = 0,
        set     = function(self, val) self:SetStepsPerPage(val) end,
        get     = function(self) return self:GetStepsPerPage() end,
    }

    --- Whether obey the step setting when drag the slider bar
    Style.Property  {
        name    = "ObeyStepOnDrag",
        type    = Boolean,
        require = Slider,
        default = false,
        set     = function(self, val) self:SetObeyStepOnDrag(val) end,
        get     = function(self) return self:GetObeyStepOnDrag() end,
    }

    --- the value representing the current position of the slider thumb
    Style.Property  {
        name    = "Value",
        type    = Number,
        require = { Slider, StatusBar },
        default = 0,
        set     = function(self, val) self:SetValue(val) end,
        get     = function(self) return self:GetValue() end,
    }

    --- the minimum increment between allowed slider values
    Style.Property  {
        name    = "ValueStep",
        type    = Number,
        require = Slider,
        default = 0,
        set     = function(self, val) self:SetValueStep(val) end,
        get     = function(self) return self:GetValueStep() end,
    }
end

------------------------------------------------------------
--                       StatusBar                        --
------------------------------------------------------------
do
    --- whether the status bar's texture is rotated to match its orientation
    Style.Property  {
        name    = "RotatesTexture",
        type    = Boolean,
        require = StatusBar,
        default = false,
        set     = function(self, val) self:SetRotatesTexture(val) end,
        get     = function(self) return self:GetRotatesTexture() end,
    }

    --- Whether the status bar's texture is reverse filled
    Style.Property  {
        name    = "ReverseFill",
        type    = Boolean,
        require = StatusBar,
        default = false,
        set     = function(self, val) self:SetReverseFill(val) end,
        get     = function(self) return self:GetReverseFill() end,
    }

    Style.Property  {
        name    = "FillStyle",
        type    = FillStyle,
        require = StatusBar,
        default = "STANDARD",
        set     = function(self, val) self:SetFillStyle(val) end,
        get     = function(self) return self:GetFillStyle() end,
    }

    --- The texture atlas
    Style.Property  {
        name    = "StatusBarAtlas",
        type    = String,
        require = StatusBar,
        set     = function(self, val) self:SetStatusBarAtlas(val) end,
        get     = function(self) return self:GetStatusBarAtlas() end,
    }

    --- the color shading for the status bar's texture
    Style.Property  {
        name    = "StatusBarColor",
        type    = ColorType,
        require = StatusBar,
        default = Color.WHITE,
        set     = function(self, val) self:SetStatusBarColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) return Color(self:GetStatusBarColor()) end,
    }

    Style.Property  {
        name    = "StatusBarTexture",
        type    = Texture,
        require = StatusBar,
        set     = function(self, val) self:SetStatusBarTexture(val) end,
        get     = function(self) return self:GetStatusBarTexture() end,
    }
end

------------------------------------------------------------
--                         Model                          --
------------------------------------------------------------
do
    --- The model's camera distance
    Style.Property  {
        name    = "CameraDistance",
        type    = Number,
        require = Model,
        set     = function(self, val) self:SetCameraDistance(val) end,
        get     = function(self) return self:GetCameraDistance() end,
    }

    --- The model's camera facing
    Style.Property  {
        name    = "CameraFacing",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetCameraFacing(val) end,
        get     = function(self) return self:GetCameraFacing() end,
    }

    --- The model's camera position
    Style.Property  {
        name    = "CameraPosition",
        type    = Position,
        require = { Model, ModelScene },
        set     = function(self, val) self:SetCameraPosition(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetCameraPosition()) end,
    }

    --- The model's camera target position
    Style.Property  {
        name    = "CameraTarget",
        type    = Position,
        require = Model,
        set     = function(self, val) self:SetCameraTarget(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetCameraTarget()) end,
    }

    --- The model's camera roll
    Style.Property  {
        name    = "CameraRoll",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetCameraRoll(val) end,
        get     = function(self) return self:GetCameraRoll() end,
    }

    --- Whether has custom camera
    Style.Property  {
        name    = "CustomCamera",
        type    = Boolean,
        require = Model,
        default = false,
        set     = function(self, val) self:SetCustomCamera(val) end,
        get     = function(self) return self:HasCustomCamera() end,
    }

    --- the model's current fog color
    Style.Property  {
        name    = "FogColor",
        type    = ColorType,
        require = { Model, ModelScene },
        default = Color.WHITE,
        set     = function(self, val) self:SetFogColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) return Color(self:GetFogColor()) end,
    }

    --- the far clipping distance for the model's fog
    Style.Property  {
        name    = "FogFar",
        type    = Number,
        require = { Model, ModelScene },
        default = 1,
        set     = function(self, val) self:SetFogFar(val) end,
        get     = function(self) return self:GetFogFar() end,
    }

    --- the near clipping distance for the model's fog
    Style.Property  {
        name    = "FogNear",
        type    = Number,
        require = { Model, ModelScene },
        default = 0,
        set     = function(self, val) self:SetFogNear(val) end,
        get     = function(self) return self:GetFogNear() end,
    }

    --- The model's facing
    Style.Property  {
        name    = "Facing",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetFacing(val) end,
        get     = function(self) return self:GetFacing() end,
    }

    --- the light sources used when rendering the model
    Style.Property  {
        name    = "Light",
        type    = LightType,
        require = Model,
        set     = function(self, val)
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
        get     = function(self)
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
    Style.Property  {
        name    = "Model",
        type    = String,
        require = Model,
        set     = function(self, val) self:SetModel(val) end,
        clear   = function(self) self:ClearModel() end,
    }

    --- The model's alpha
    Style.Property  {
        name    = "ModelAlpha",
        type    = ColorFloat,
        require = Model,
        default = 1,
        set     = function(self, val) self:SetModelAlpha(val) end,
        get     = function(self) return self:GetModelAlpha() end,
    }

    Style.Property  {
        name    = "ModelCenterToTransform",
        type    = Boolean,
        require = Model,
        default = false,
        set     = function(self, val) self:UseModelCenterToTransform(val) end,
        get     = function(self) return self:IsUsingModelCenterToTransform() end,
    }

    --- The model's draw layer
    Style.Property  {
        name    = "ModelDrawLayer",
        type    = DrawLayer,
        require = Model,
        default = "ARTWORK",
        set     = function(self, val) self:SetModelDrawLayer(val) end,
        get     = function(self) return self:GetModelDrawLayer() end,
    }

    --- the scale factor determining the size at which the 3D model appears
    Style.Property  {
        name    = "ModelScale",
        type    = Number,
        require = Model,
        default = 1,
        set     = function(self, val) self:SetModelScale(val) end,
        get     = function(self) return self:GetModelScale() end,
    }

    --- the position of the 3D model within the frame
    Style.Property  {
        name    = "Position",
        type    = Position,
        require = Model,
        default = Position(0, 0, 0),
        set     = function(self, val) self:SetPosition(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetPosition()) end,
    }

    Style.Property  {
        name    = "Paused",
        type    = Boolean,
        require = Model,
        default = false,
        set     = function(self, val) self:SetPaused(val) end,
        get     = function(self) return self:GetPaused() end,
    }

    Style.Property  {
        name    = "ParticlesEnabled",
        type    = Boolean,
        require = Model,
        default = false,
        set     = function(self, val) self:SetParticlesEnabled(val) end,
    }

    --- The model's pitch
    Style.Property  {
        name    = "Pitch",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetPitch(val) end,
        get     = function(self) return self:GetPitch() end,
    }

    --- The model's roll
    Style.Property  {
        name    = "Roll",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetRoll(val) end,
        get     = function(self) return self:GetRoll() end,
    }

    --- The shadow effect
    Style.Property  {
        name    = "ShadowEffect",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetShadowEffect(val) end,
        get     = function(self) return self:GetShadowEffect() end,
    }

    Style.Property  {
        name    = "ViewInsets",
        type    = Inset,
        require = { Model, ModelScene },
        default = Inset(0, 0, 0, 0),
        set     = function(self, val) self:SetViewInsets(val.left, val.right, val.top, val.bottom) end,
        get     = function(self) return Inset(self:GetViewInsets()) end,
    }

    Style.Property  {
        name    = "ViewTranslation",
        type    = Dimension,
        require = { Model, ModelScene },
        default = Dimension(0, 0),
        set     = function(self, val) self:SetViewTranslation(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetViewTranslation()) end,
    }
end

------------------------------------------------------------
--                       ModelScene                       --
------------------------------------------------------------
do
    Style.Property  {
        name    = "CameraFarClip",
        type    = Number,
        require = ModelScene,
        default = 100,
        set     = function(self, val) self:SetCameraFarClip(val) end,
        get     = function(self) return self:GetCameraFarClip() end,
    }

    Style.Property  {
        name    = "CameraNearClip",
        type    = Number,
        require = ModelScene,
        default = 0.2,
        set     = function(self, val) self:SetCameraNearClip(val) end,
        get     = function(self) return self:GetCameraNearClip() end,
    }

    Style.Property  {
        name    = "LightAmbientColor",
        type    = ColorType,
        require = ModelScene,
        default = Color(0.7, 0.7, 0.7),
        set     = function(self, val) self:SetLightAmbientColor(val.r, val.g, val.b) end,
        get     = function(self) return Color(self:GetLightAmbientColor()) end,
    }

    Style.Property  {
        name    = "LightPosition",
        type    = Position,
        require = ModelScene,
        default = Position(0, 0, 0),
        set     = function(self, val) self:SetLightPosition(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetLightPosition()) end,
        }

    Style.Property  {
        name    = "LightType",
        type    = Number,
        require = ModelScene,
        default = 1,
        set     = function(self, val) self:SetLightType(val) end,
        get     = function(self) return self:GetLightType() end,
    }

    Style.Property  {
        name    = "LightDirection",
        type    = Position,
        require = ModelScene,
        default = Position(0, 1, 0),
        set     = function(self, val) self:SetLightDirection(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetLightDirection()) end,
    }

    Style.Property  {
        name    = "CameraFieldOfView",
        type    = Number,
        require = ModelScene,
        default = 0.94,
        set     = function(self, val) self:SetCameraFieldOfView(val) end,
        get     = function(self) return self:GetCameraFieldOfView() end,
    }

    Style.Property  {
        name    = "LightDiffuseColor",
        type    = ColorType,
        require = ModelScene,
        default = Color(0.8, 0.8, 0.64),
        set     = function(self, val) self:SetLightDiffuseColor(val.r, val.g, val.b) end,
        get     = function(self) return Color(self:GetLightDiffuseColor()) end,
    }

    Style.Property  {
        name    = "LightVisible",
        type    = Number,
        require = ModelScene,
        default = true,
        set     = function(self, val) self:SetLightVisible(val) end,
        get     = function(self) return self:IsLightVisible() end,
    }
end

------------------------------------------------------------
--                      DressUpModel                      --
------------------------------------------------------------
do
    --- Whether auto dress
    Style.Property  {
        name    = "AutoDress",
        type    = Boolean,
        require = DressUpModel,
        default = true,
        set     = function(self, val) self:SetAutoDress(val) end,
        get     = function(self) return self:GetAutoDress() end,
    }

    --- Whether sheathed the weapon
    Style.Property  {
        name    = "Sheathed",
        type    = Boolean,
        require = DressUpModel,
        default = false,
        set     = function(self, val) self:SetSheathed(val) end,
        get     = function(self) return self:GetSheathed() end,
    }

    --- Whether use transmog skin
    Style.Property  {
        name    = "UseTransmogSkin",
        type    = Boolean,
        require = DressUpModel,
        default = false,
        set     = function(self, val) self:SetUseTransmogSkin(val) end,
        get     = function(self) return self:GetUseTransmogSkin() end,
    }
end