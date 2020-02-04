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
    Property    {
        name    = "Alpha",
        type    = ColorFloat,
        require = { LayoutFrame, Line },
        default = 1,
        get     = function(self) return self:GetAlpha() end,
        set     = function(self, alpha) self:SetAlpha(alpha) end,
    }

    --- the height of the LayoutFrame
    Property    {
        name    = "Height",
        type    = Number,
        require = { LayoutFrame, Line },
        get     = function(self) return self:GetHeight() end,
        set     = function(self, height) self:SetHeight(height) end,
    }

    --- Whether ignore parent's alpha settings
    Property    {
        name    = "ParentAlphaIgnored",
        type    = Boolean,
        require = { LayoutFrame, Line },
        default = false,
        get     = function(self) return self:IsIgnoringParentAlpha() end,
        set     = function(self, flag) self:SetIgnoreParentAlpha(flag) end,
    }

    --- Whether ignore prent's scal settings
    Property    {
        name    = "ParentScaleIgnored",
        type    = Boolean,
        require = { LayoutFrame, Line },
        default = false,
        get     = function(self) return self:IsIgnoringParentScale() end,
        set     = function(self, flag) self:SetIgnoreParentScale(flag) end,
    }

    --- the location of the LayoutFrame
    Property    {
        name    = "Location",
        type    = Anchors,
        require = LayoutFrame,
        get     = function(self) return LayoutFrame.GetLocation(GetProxyUI(self)) end,
        set     = function(self, loc)   LayoutFrame.SetLocation(GetProxyUI(self), loc) end,
        clear   = function(self) self:ClearAllPoints() end,
    }

    --- the frame's scale factor or the scale animation's setting
    Property    {
        name    = "Scale",
        type    = PositiveNumber,
        require = { LayoutFrame, Scale },
        default = 1,
        get     = function(self) return self:GetScale() end,
        set     = function(self, scale) self:SetScale(scale) end,
    }

    --- The size of the LayoutFrame
    Property    {
        name    = "Size",
        type    = Size,
        require = { LayoutFrame, Line },
        get     = function(self) return Size(self:GetSize()) end,
        set     = function(self, size) self:SetSize(size.width, size.height) end,
    }

    --- wheter the LayoutFrame is shown or not.
    Property    {
        name    = "Visible",
        type    = Boolean,
        require = { LayoutFrame, Line },
        default = true,
        get     = function(self) return self:IsShown() and true or false end,
        set     = function(self, visible) self:SetShown(visible) end,
    }

    --- the width of the LayoutFrame
    Property    {
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
    Property    {
        name    = "DrawLayer",
        type    = DrawLayer,
        require = { Texture, FontString, ModelScene, Line },
        default = "ARTWORK",
        get     = function(self) return self:GetDrawLayer() end,
        set     = function(self, layer) return self:SetDrawLayer(layer) end,
    }

    --- the color shading for the LayeredFrame's graphics
    Property    {
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
    Property    {
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
    Property    {
        name    = "FontObject",
        type    = FontObject,
        require = FONT_TYPES,
        get     = function(self) return self:GetFontObject() end,
        set     = function(self, fontObject) self:SetFontObject(fontObject) end,
    }

    --- the fontstring's horizontal text alignment style
    Property    {
        name    = "JustifyH",
        type    = JustifyHType,
        require = FONT_TYPES,
        default = "CENTER",
        get     = function(self) return self:GetJustifyH() end,
        set     = function(self, justifyH) self:SetJustifyH(justifyH) end,
    }

    --- the fontstring's vertical text alignment style
    Property    {
        name    = "JustifyV",
        type    = JustifyVType,
        require = FONT_TYPES,
        default = "MIDDLE",
        get     = function(self) return self:GetJustifyV() end,
        set     = function(self, justifyV) self:SetJustifyV(justifyV) end,
    }

    --- the color of the font's text shadow
    Property    {
        name    = "ShadowColor",
        type    = Color,
        require = FONT_TYPES,
        default = Color(0, 0, 0, 0),
        get     = function(self) return Color(self:GetShadowColor()) end,
        set     = function(self, color) self:SetShadowColor(color.r, color.g, color.b, color.a) end,
    }

    --- the offset of the fontstring's text shadow from its text
    Property    {
        name    = "ShadowOffset",
        type    = Dimension,
        require = FONT_TYPES,
        default = Dimension(0, 0),
        get     = function(self) return Dimension(self:GetShadowOffset()) end,
        set     = function(self, offset) self:SetShadowOffset(offset.x, offset.y) end,
    }

    --- the fontstring's amount of spacing between lines
    Property    {
        name    = "Spacing",
        type    = Number,
        require = FONT_TYPES,
        default = 0,
        get     = function(self) return self:GetSpacing() end,
        set     = function(self, spacing) self:SetSpacing(spacing) end,
    }

    --- the fontstring's default text color
    Property    {
        name    = "TextColor",
        type    = Color,
        require = FONT_TYPES,
        default = Color(1, 1, 1),
        get     = function(self) return Color(self:GetTextColor()) end,
        set     = function(self, color) self:SetTextColor(color.r, color.g, color.b, color.a) end,
    }

    --- whether the text wrap will be indented
    Property    {
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
    Property    {
        name    = "Atlas",
        type    = AtlasType,
        require = { Texture, Line },
        get     = function(self) return AtlasType(self:GetAtlas()) end,
        set     = function(self, val) self:SetAtlas(val.atlas, val.useAtlasSize) end,
        clear   = function(self) self:SetAtlas(nil) end,
    }

    --- the blend mode of the texture
    Property    {
        name    = "BlendMode",
        type    = AlphaMode,
        require = { Texture, Line },
        default = "ADD",
        get     = function(self) return self:GetBlendMode() end,
        set     = function(self, val) self:SetBlendMode(val) end,
    }

    --- the texture's color
    Property    {
        name    = "Color",
        type    = ColorType,
        require = { Texture, Line },
        set     = function(self, color) self:SetColorTexture(color.r, color.g, color.b, color.a) end,
        clear   = function(self) self:SetTexture(nil) end,
    }

    --- whether the texture image should be displayed with zero saturation
    Property    {
        name    = "Desaturated",
        type    = Boolean,
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:IsDesaturated() end,
        set     = function(self, val) self:SetDesaturated(val) end,
    }

    --- The texture's desaturation
    Property    {
        name    = "Desaturation",
        type    = ColorFloat,
        require = { Texture, Line, Model },
        default = 0,
        get     = function(self) return self:GetDesaturation() end,
        set     = function(self, val) self:SetDesaturation(val) end,
    }

    --- Whether the texture is horizontal tile
    Property    {
        name    = "HorizTile",
        type    = Boolean,
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:GetHorizTile() end,
        set     = function(self, val) self:SetHorizTile(val) end,
    }

    --- The gradient color shading for the texture
    Property    {
        name    = "Gradient",
        type    = GradientType,
        require = { Texture, Line },
        set     = function(self, val) self:SetGradient(val.orientation, val.mincolor.r, val.mincolor.g, val.mincolor.b, val.maxcolor.r, val.maxcolor.g, val.maxcolor.b) end,
        clear   = function(self) self:SetGradient("HORIZONTAL", 1, 1, 1, 1, 1, 1) end,
    }

    --- The gradient color shading (including opacity in the gradient) for the texture
    Property    {
        name    = "GradientAlpha",
        type    = GradientType,
        require = { Texture, Line },
        set     = function(self, val) self:SetGradientAlpha(val.orientation, val.mincolor.r, val.mincolor.g, val.mincolor.b, val.mincolor.a, val.maxcolor.r, val.maxcolor.g, val.maxcolor.b, val.maxcolor.a) end,
        clear   = function(self) self:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 1, 1, 1, 1, 1) end,
    }

    --- whether the texture object loads its image file in the background
    Property    {
        name    = "NonBlocking",
        type    = Boolean,
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:GetNonBlocking() end,
        set     = function(self, val) self:SetNonBlocking(val) end,
    }

    --- The rotation of the texture
    Property    {
        name    = "Rotation",
        type    = Number,
        require = { Texture, Line, Cooldown },
        get     = function(self) return self:GetRotation() end,
        set     = function(self, val) self:SetRotation(val) end,
    }

    --- whether snap to pixel grid
    Property    {
        name    = "SnapToPixelGrid",
        type    = Boolean,
        require = { Texture, Line },
        default = false,
        get     = function(self) return self:IsSnappingToPixelGrid() end,
        set     = function(self, val) self:SetSnapToPixelGrid(val) end,
    }

    --- the texel snapping bias
    Property    {
        name    = "TexelSnappingBias",
        type    = Number,
        require = { Texture, Line },
        default = 0,
        get     = function(self) return self:GetTexelSnappingBias() end,
        set     = function(self, val) self:SetTexelSnappingBias(val) end,
    }

    --- The corner coordinates for scaling or cropping the texture image
    Property    {
        name    = "TexCoord",
        type    = RectType,
        require = { Texture, Line },
        get     = function(self) local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = self:GetTexCoord() if URx then return { ULx = ULx, ULy = ULy, LLx = LLx, LLy = LLy, URx = URx, URy = URy, LRx = LRx, LRy = LRy } elseif ULx then return { left = ULx, right = ULy, top = LLx, bottom = LLy } end end,
        set     = function(self, val) if val.left then self:SetTexCoord(val.left, val.right, val.top, val.bottom) else self:SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy) end end,
        clear   = function(self) self:SetTexCoord(0, 1, 0, 1) end,
    }

    --- The texture settings
    Position    {
        name    = "Texture",
        type    = Number + String + TextureType,
        require = { Texture, Line },
        get     = function(self) return self:GetTexture() end,
        set     = function(self, val)
                    if type(val) ~= "table" then
                        self:SetTexture(val)
                    else
                        self:SetTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        clear   = function(self) self:SetTexture(nil) end,
    }

    --- The texture file id
    Property    {
        name    = "TextureFileID",
        type    = Number,
        require = { Texture, Line },
        get     = function(self) return self:GetTextureFileID() end,
        set     = function(self, val) self:SetTexture(val) end,
        clear   = function(self) self:SetTexture(nil) end,
    }

    --- The texture file path
    Property    {
        name    = "TextureFilePath",
        type    = String,
        require = { Texture, Line },
        get     = function(self) return self:GetTextureFilePath() end,
        set     = function(self, val) self:SetTexture(val) end,
        clear   = function(self) self:SetTexture(nil) end,
    }

    --- The vertex offset of upperleft corner
    Property    {
        name    = "VertexOffsetUpperLeft",
        type    = Dimension,
        require = { Texture, Line },
        get     = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.UpperLeft)) end,
        set     = function(self, val) self:SetVertexOffset(VertexIndexType.UpperLeft, val.x, val.y) end,
        clear   = function(self) self:SetVertexOffset(VertexIndexType.UpperLeft, 0, 0) end,
    }

    --- The vertex offset of lowerleft corner
    Property    {
        name    = "VertexOffsetLowerLeft",
        type    = Dimension,
        require = { Texture, Line },
        get     = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.LowerLeft)) end,
        set     = function(self, val) self:SetVertexOffset(VertexIndexType.LowerLeft, val.x, val.y) end,
        clear   = function(self) self:SetVertexOffset(VertexIndexType.LowerLeft, 0, 0) end,
    }

    --- The vertex offset of upperright corner
    Property    {
        name    = "VertexOffsetUpperRight",
        type    = Dimension,
        require = { Texture, Line },
        get     = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.UpperRight)) end,
        set     = function(self, val) self:SetVertexOffset(VertexIndexType.UpperRight, val.x, val.y) end,
        clear   = function(self) self:SetVertexOffset(VertexIndexType.UpperRight, 0, 0) end,
    }

    --- The vertex offset of lowerright corner
    Property    {
        name    = "VertexOffsetLowerRight",
        type    = Dimension,
        require = { Texture, Line },
        get     = function(self) return Dimension(self:GetVertexOffset(VertexIndexType.LowerRight)) end,
        set     = function(self, val) self:SetVertexOffset(VertexIndexType.LowerRight, val.x, val.y) end,
        clear   = function(self) self:SetVertexOffset(VertexIndexType.LowerRight, 0, 0) end,
    }

    --- Whether the texture is vertical tile
    Property    {
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
    Property    {
        name    = "StartPoint",
        type    = Anchor,
        require = Line,
        set     = function(self, anchor) self:SetStartPoint(fromAnchor(anchor)) end,
        get     = function(self) return toAnchor(self:GetStartPoint()) end,
    }

    --- the end point of the line
    Property    {
        name    = "EndPoint",
        type    = Anchor,
        require = Line,
        set     = function(self, anchor) self:SetEndPoint(fromAnchor(anchor)) end,
        get     = function(self) return toAnchor(self:GetEndPoint()) end,
    }

    --- the thickness of the line
    Property    {
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
    Property    {
        name    = "AlphaGradient",
        type    = AlphaGradientType,
        require = FontString,
        set     = function(self, val) self:SetAlphaGradient(val.start, val.length) end,
        clear   = function(self) self:SetAlphaGradient(0, 10^6) end,
    }

    --- the max lines of the text
    Property    {
        name    = "MaxLines",
        type    = Number,
        require = FontString,
        default = 0,
        set     = function(self, val) self:SetMaxLines(val) end,
        get     = function(self) return self:GetMaxLines() end,
    }

    --- whether long lines of text will wrap within or between words
    Property    {
        name    = "NonSpaceWrap",
        type    = Boolean,
        require = FontString,
        default = false,
        set     = function(self, val) self:SetNonSpaceWrap(val) end,
        get     = function(self) return self:CanNonSpaceWrap() end,
    }

    --- the text to be displayed in the font string
    Property    {
        name    = "Text",
        type    = String,
        require = { FontString, Button, EditBox },
        default = "",
        set     = function(self, val) self:SetText(val) end,
        get     = function(self) return self:GetText() end,
    }

    --- the height of the text displayed in the font string
    Property    {
        name    = "TextHeight",
        type    = Boolean,
        require = FontString,
        set     = function(self, val) self:SetTextHeight(val) end,
        get     = function(self) return self:GetLineHeight() end,
    }

    --- whether long lines of text in the font string can wrap onto subsequent lines
    Property    {
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
    Property    {
        name    = "Looping",
        type    = AnimLoopType,
        require = AnimationGroup,
        default = "NONE",
        set     = function(self, val) self:SetLooping(val) end,
        get     = function(self) return self:GetLooping() end,
    }

    --- Whether to final alpha is set
    Property    {
        name    = "ToFinalAlpha",
        type    = Boolean,
        require = AnimationGroup,
        default = false,
        set     = function(self, val) self:SetToFinalAlpha(val) end,
        get     = function(self) return self:IsSetToFinalAlpha() end,
    }

    --- Time for the animation to progress from start to finish (in seconds)
    Property    {
        name    = "Duration",
        type    = Number,
        require = Animation,
        default = 0,
        set     = function(self, val) self:SetDuration(val) end,
        get     = function(self) return self:GetDuration() end,
    }

    --- Time for the animation to delay after finishing (in seconds)
    Property    {
        name    = "EndDelay",
        type    = Number,
        require = Animation,
        set     = function(self, val) self:SetEndDelay(val) end,
        get     = function(self) return self:GetEndDelay() end,
    }

    --- Position at which the animation will play relative to others in its group (between 0 and 100)
    Property    {
        name    = "Order",
        type    = Integer,
        require = { Animation, ControlPoint },
        set     = function(self, val) self:SetOrder(val) end,
        get     = function(self) return self:GetOrder() end,
    }

    --- The smooth progress of the animation
    Property    {
        name    = "SmoothProgress",
        type    = Number,
        require = Animation,
        set     = function(self, val) self:SetSmoothProgress(val) end,
        get     = function(self) return self:GetSmoothProgress() end,
    }

    --- Type of smoothing for the animation, IN, IN_OUT, NONE, OUT
    Property    {
        name    = "Smoothing",
        type    = AnimSmoothType,
        require = Animation,
        default = "NONE",
        set     = function(self, val) self:SetSmoothing(val) end,
        get     = function(self) return self:GetSmoothing() end,
    }

    --- Amount of time the animation delays before its progress begins (in seconds)
    Property    {
        name    = "StartDelay",
        type    = Number,
        require = Animation,
        default = 0,
        set     = function(self, val) self:SetStartDelay(val) end,
        get     = function(self) return self:GetStartDelay() end,
    }

    --- the animation's amount of alpha (opacity) start from
    Property    {
        name    = "FromAlpha",
        type    = ColorFloat,
        require = Alpha,
        default = 0,
        set     = function(self, val) self:SetFromAlpha(val) end,
        get     = function(self) return self:GetFromAlpha() end,
    }

    --- the animation's amount of alpha (opacity) end to
    Property    {
        name    = "ToAlpha",
        type    = ColorFloat,
        require = Alpha,
        default = 0,
        set     = function(self, val) self:SetToAlpha(val) end,
        get     = function(self) return self:GetToAlpha() end,
    }

    --- The curve type of the path
    Property    {
        name    = "Curve",
        type    = AnimCurveType,
        require = Path,
        default = "NONE",
        set     = function(self, val) self:SetCurve(val) end,
        get     = function(self) return self:GetCurve() end,
    }

    --- the offsets settings
    Property    {
        name    = "Offset",
        type    = Dimension,
        require = { ControlPoint, Translation },
        set     = function(self, val) self:SetOffset(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetOffset()) end,
    }

    --- the animation's rotation amount (in degrees)
    Property    {
        name    = "Degrees",
        type    = Number,
        require = Rotation,
        get     = function(self) return self:GetDegrees() end,
        set     = function(self, val) self:SetDegrees(val) end,
    }

    --- the rotation animation's origin point
    Property    {
        name    = "Origin",
        type    = AnimOriginType,
        require = { Rotation, Scale },
        get     = function(self) return AnimOriginType(self:GetOrigin()) end,
        set     = function(self, val) self:SetOrigin(val.point, val.x, val.y) end,
    }

    --- the animation's rotation amount (in radians)
    Property    {
        name    = "Radians",
        type    = Number,
        require = Rotation,
        get     = function(self) return self:GetRadians() end,
        set     = function(self, val) self:SetRadians(val) end,
    }

    --- the animation's scaling factors
    Property    {
        name    = "KeepScale",
        type    = Dimension,
        require = Scale,
        default = Dimension(1, 1),
        set     = function(self, val) self:SetScale(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetScale()) end,
    }

    --- the animation's scale amount that start from
    Property    {
        name    = "FromScale",
        type    = Dimension,
        require = Scale,
        default = Dimension(1, 1),
        set     = function(self, val) self:SetFromScale(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetFromScale()) end,
    }

    --- the animation's scale amount that end to
    Property    {
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
    Property    {
        name    = "Backdrop",
        type    = BackdropType,
        require = Frame,
        nilable = true,
        set     = function(self, val) self:SetBackdrop(val) end,
        get     = function(self) return self:GetBackdrop() end,
    }

    --- the shading color for the frame's border graphic
    Property    {
        name    = "BackdropBorderColor",
        type    = ColorType,
        require = Frame,
        default = Color.TRANSPARENT,
        set     = function(self, val) self:SetBackdropBorderColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) local r, g, b, a = self:GetBackdropBorderColor() if r then return Color(r, g, b, a) end end,
    }

    --- the shading color for the frame's background graphic
    Property    {
        name    = "BackdropColor",
        type    = ColorType,
        require = Frame,
        default = Color.TRANSPARENT,
        set     = function(self, val) self:SetBackdropColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) local r, g, b, a = self:GetBackdropColor() if r then return Color(r, g, b, a) end end,
    }

    --- whether the frame's boundaries are limited to those of the screen
    Property    {
        name    = "ClampedToScreen",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetClampedToScreen(val) end,
        get     = function(self) return self:IsClampedToScreen() end,
    }

    --- offsets from the frame's edges used when limiting user movement or resizing of the frame
    Property    {
        name    = "ClampRectInsets",
        type    = Inset,
        require = Frame,
        default = Inset(0, 0, 0, 0),
        set     = function(self, val) self:SetClampRectInsets(val.left, val.right, val.top, val.bottom) end,
        get     = function(self) return Inset(self:GetClampRectInsets()) end,
    }

    --- Whether the children is limited to draw inside the frame's boundaries
    Property    {
        name    = "ClipChildren",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetClipsChildren(val) end,
        get     = function(self) return self:DoesClipChildren() end,
    }

    --- the 3D depth of the frame (for stereoscopic 3D setups)
    Property    {
        name    = "Depth",
        type    = Number,
        require = Frame,
        default = 0,
        set     = function(self, val) self:SetDepth(val) end,
        get     = function(self) return self:GetDepth() end,
    }

    --- Whether the frame don't save its location in layout-cache
    Property    {
        name    = "DontSavePosition",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetDontSavePosition(val) end,
        get     = function(self) return self:GetDontSavePosition() end,
    }

    --- Whether the frame's child is render in flattens layers
    Property    {
        name    = "FlattensRenderLayers",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetFlattensRenderLayers(val) end,
        get     = function(self) return self:GetFlattensRenderLayers() end,
    }

    --- the level at which the frame is layered relative to others in its strata
    Property    {
        name    = "FrameLevel",
        type    = Number,
        require = Frame,
        default = 1,
        set     = function(self, val) self:SetFrameLevel(val) end,
        get     = function(self) return self:GetFrameLevel() end,
    }

    --- the general layering strata of the frame
    Property    {
        name    = "FrameStrata",
        type    = FrameStrata,
        require = Frame,
        default = "MEDIUM",
        set     = function(self, val) self:SetFrameStrata(val) end,
        get     = function(self) return self:GetFrameStrata() end,
    }

    --- the insets from the frame's edges which determine its mouse-interactable area
    Property    {
        name    = "HitRectInsets",
        type    = Inset,
        require = Frame,
        default = Inset(0, 0, 0, 0),
        set     = function(self, val) self:SetHitRectInsets(val.left, val.right, val.top, val.bottom) end,
        get     = function(self) return Inset(self:GetHitRectInsets()) end,
    }

    --- Whether the hyper links are enabled
    Property    {
        name    = "HyperlinksEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetHyperlinksEnabled(val) end,
        get     = function(self) return self:GetHyperlinksEnabled() end,
    }

    --- a numeric identifier for the frame
    Property    {
        name    = "ID",
        type    = Number,
        require = Frame,
        default = 0,
        set     = function(self, val) self:SetID(val) end,
        get     = function(self) return self:GetID() end,
    }

    --- whether the frame's depth property is ignored (for stereoscopic 3D setups)
    Property    {
        name    = "IgnoringDepth",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:IgnoreDepth(val) end,
        get     = function(self) return self:IsIgnoringDepth() end,
    }

    --- Whether the joystick is enabled for the frame
    Property    {
        name    = "JoystickEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:EnableJoystick(val) end,
        get     = function(self) return self:IsJoystickEnabled() end,
    }

    --- whether keyboard interactivity is enabled for the frame
    Property    {
        name    = "KeyboardEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:EnableKeyboard(val) end,
        get     = function(self) return self:IsKeyboardEnabled() end,
    }

    --- the maximum size of the frame for user resizing
    Property    {
        name    = "MaxResize",
        type    = Size,
        require = Frame,
        default = Size(0, 0),
        set     = function(self, val) self:SetMaxResize(val.width, val.height) end,
        get     = function(self) return Size(self:GetMaxResize()) end,
    }

    --- Whether the mouse click is enabled
    Property    {
        name    = "MouseClickEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetMouseClickEnabled(val) end,
        get     = function(self) return self:IsMouseClickEnabled() end,
    }

    --- whether mouse interactivity is enabled for the frame
    Property    {
        name    = "MouseEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:EnableMouse(val) end,
        get     = function(self) return self:IsMouseEnabled() end,
    }

    --- Whether the mouse motion in enabled
    Property    {
        name    = "MouseMotionEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetMouseMotionEnabled(val) end,
        get     = function(self) return self:IsMouseMotionEnabled() end,
    }

    --- whether mouse wheel interactivity is enabled for the frame
    Property    {
        name    = "MouseWheelEnabled",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:EnableMouseWheel(val) end,
        get     = function(self) return self:IsMouseWheelEnabled() end,
    }

    --- the minimum size of the frame for user resizing
    Property    {
        name    = "MinResize",
        type    = Size,
        require = Frame,
        default = Size(0, 0),
        set     = function(self, val) self:SetMinResize(val.width, val.height) end,
        get     = function(self) return Size(self:GetMinResize()) end,
    }

    --- whether the frame can be moved by the user
    Property    {
        name    = "Movable",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetMovable(val) end,
        get     = function(self) return self:IsMovable() end,
    }

    --- Whether the frame get the propagate keyboard input
    Property    {
        name    = "PropagateKeyboardInput",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetPropagateKeyboardInput(val) end,
        get     = function(self) return self:GetPropagateKeyboardInput() end,
    }

    --- whether the frame can be resized by the user
    Property    {
        name    = "Resizable",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetResizable(val) end,
        get     = function(self) return self:IsResizable() end,
    }

    --- whether the frame should automatically come to the front when clicked
    Property    {
        name    = "Toplevel",
        type    = Boolean,
        require = Frame,
        default = false,
        set     = function(self, val) self:SetToplevel(val) end,
        get     = function(self) return self:IsToplevel() end,
    }

    --- whether the frame should save/load custom position by the system
    Property    {
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
    Property    {
        name    = "Enabled",
        type    = Boolean,
        require = { Button, EditBox, Slider },
        default = true,
        set     = function(self, val) self:SetEnabled(val) end,
        get     = function(self) return self:IsEnabled() end,
    }

    --- the FontString object used for the button's label text
    Property    {
        name    = "FontString",
        type    = FontString,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetFontString(val) end,
        get     = function(self) return self:GetFontString() end,
    }

    --- The button state
    Property    {
        name    = "ButtonState",
        type    = ButtonStateType,
        require = Button,
        default = "NORMAL",
        set     = function(self, val) self:SetButtonState(val) end,
        get     = function(self) return self:GetButtonState() end,
    }

    --- Whether enable the motion script while disabled
    Property    {
        name    = "MotionScriptsWhileDisabled",
        type    = Boolean,
        require = Button,
        default = false,
        set     = function(self, val) self:SetMotionScriptsWhileDisabled(val) end,
        get     = function(self) return self:GetMotionScriptsWhileDisabled() end,
    }

    --- the offset for moving the button's label text when pushed
    Property    {
        name    = "PushedTextOffset",
        type    = Dimension,
        require = Button,
        default = Dimension(1.5665, -1.5665),
        set     = function(self, val) self:SetPushedTextOffset(val.x, val.y) end,
        get     = function(self) return Dimension(self:GetPushedTextOffset()) end,
    }

    --- the texture object used when the button is pushed
    Property    {
        name    = "PushedTexture",
        type    = Number + String + TextureType + Texture,
        require = Button,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetPushedTexture(val)
                    else
                        self:SetPushedTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetPushedTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetPushedTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetPushedTexture() end,
    }

    --- the texture object used when the button is highlighted
    Property    {
        name    = "HighlightTexture",
        type    = Number + String + TextureType + Texture,
        require = Button,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetHighlightTexture(val)
                    else
                        self:SetHighlightTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetHighlightTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetHighlightTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetHighlightTexture() end,
    }

    --- the texture object used for the button's normal state
    Property    {
        name    = "NormalTexture",
        type    = Number + String + TextureType + Texture,
        require = Button,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetNormalTexture(val)
                    else
                        self:SetNormalTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetNormalTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetNormalTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetNormalTexture() end,
    }

    --- the texture object used when the button is disabled
    Property    {
        name    = "DisabledTexture",
        type    = Number + String + TextureType + Texture,
        require = Button,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetDisabledTexture(val)
                    else
                        self:SetDisabledTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetDisabledTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetDisabledTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetDisabledTexture() end,
    }

    --- the font object used when the button is highlighted
    Property    {
        name    = "HighlightFontObject",
        type    = FontObject,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetHighlightFontObject(val) end,
        get     = function(self) return self:GetHighlightFontObject() end,
    }

    --- the font object used for the button's normal state
    Property    {
        name    = "NormalFontObject",
        type    = FontObject,
        require = Button,
        nilable = true,
        set     = function(self, val) self:SetNormalFontObject(val) end,
        get     = function(self) return self:GetNormalFontObject() end,
    }

    --- the font object used for the button's disabled state
    Property    {
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
    Property    {
        name    = "Checked",
        type    = Boolean,
        require = CheckButton,
        default = false,
        set     = function(self, val) self:SetChecked(val) end,
        get     = function(self) return self:GetChecked() end,
    }

    --- the texture object used when the button is checked
    Property    {
        name    = "CheckedTexture",
        type    = Number + String + TextureType + Texture,
        require = CheckButton,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetCheckedTexture(val)
                    else
                        self:SetCheckedTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetCheckedTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetCheckedTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetCheckedTexture() end,
    }

    --- the texture object used when the button is disabled and checked
    Property    {
        name    = "DisabledCheckedTexture",
        type    = Number + String + TextureType + Texture,
        require = CheckButton,
        nilable = true,
        set     = function(self, val) self:SetDisabledCheckedTexture(val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetDisabledCheckedTexture(val)
                    else
                        self:SetDisabledCheckedTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetDisabledCheckedTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetDisabledCheckedTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetDisabledCheckedTexture() end,
    }
end

------------------------------------------------------------
--                      ColorSelect                       --
------------------------------------------------------------
do
    --- the HSV color value
    Property    {
        name    = "ColorHSV",
        type    = HSVType,
        require = ColorSelect,
        default = HSVType(0, 0, 1),
        set     = function(self, val) self:SetColorHSV(val.h, val.s, val.v) end,
        get     = function(self) return HSVType(self:GetColorHSV()) end,
    }

    --- the RGB color value
    Property    {
        name    = "ColorRGB",
        type    = ColorType,
        require = ColorSelect,
        default = Color.WHITE,
        set     = function(self, val) self:SetColorRGB(val.r, val.g, val.b, val.a) end,
        get     = function(self) return Color(self:GetColorRGB()) end,
    }

    --- the texture for the color picker's value slider background
    Property    {
        name    = "ColorValueTexture",
        type    = Number + String + TextureType + Texture,
        require = ColorSelect,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetColorValueTexture(val)
                    else
                        self:SetColorValueTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetColorValueTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetColorValueTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetColorValueTexture() end,
    }

    --- the texture for the selection indicator on the color picker's hue/saturation wheel
    Property    {
        name    = "ColorWheelThumbTexture",
        type    = Number + String + TextureType + Texture,
        require = ColorSelect,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetColorWheelThumbTexture(val)
                    else
                        self:SetColorWheelThumbTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetColorWheelThumbTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetColorWheelThumbTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetColorWheelThumbTexture() end,
    }

    --- the texture for the color picker's hue/saturation wheel
    Property    {
        name    = "ColorWheelTexture",
        type    = Number + String + TextureType + Texture,
        require = ColorSelect,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetColorWheelTexture(val)
                    else
                        self:SetColorWheelTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetColorWheelTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetColorWheelTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetColorWheelTexture() end,
    }

    --- the texture for the color picker's value slider thumb
    Property    {
        name    = "ColorValueThumbTexture",
        type    = Number + String + TextureType + Texture,
        require = ColorSelect,
        nilable = true,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetColorValueThumbTexture(val)
                    else
                        self:SetColorValueThumbTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetColorValueThumbTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetColorValueThumbTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetColorValueThumbTexture() end,
    }
end

------------------------------------------------------------
--                        Cooldown                        --
------------------------------------------------------------
do
    --- Sets the bling texture
    Property    {
        name    = "BlingTexture",
        type    = TextureType,
        require = Cooldown,
        set     = function(self, val) if val.color then self:SetBlingTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) else self:SetBlingTexture(val) end end,
    }

    --- the duration currently shown by the cooldown frame in milliseconds
    Property    {
        name    = "CooldownDuration",
        type    = Number,
        require = Cooldown,
        default = 0,
        set     = function(self, val) self:SetCooldownDuration(val) end,
        get     = function(self) self:GetCooldownDuration() end,
    }

    --- Whether the cooldown 'bling' when finsihed
    Property    {
        name    = "DrawBling",
        type    = Boolean,
        require = Cooldown,
        default = true,
        set     = function(self, val) self:SetDrawBling(val) end,
        get     = function(self) self:GetDrawBling() end,
    }

    --- Whether a bright line should be drawn on the moving edge of the cooldown animation
    Property    {
        name    = "DrawEdge",
        type    = Boolean,
        require = Cooldown,
        default = true,
        set     = function(self, val) self:SetDrawEdge(val) end,
        get     = function(self) self:GetDrawEdge() end,
    }

    --- Whether a shadow swipe should be drawn
    Property    {
        name    = "DrawSwipe",
        type    = Boolean,
        require = Cooldown,
        default = true,
        set     = function(self, val) self:SetDrawSwipe(val) end,
        get     = function(self) self:GetDrawSwipe() end,
    }

    -- The edge scale
    Property    {
        name    = "EdgeScale",
        type    = Number,
        require = Cooldown,
        default = math.sin(45 / 180 * math.pi),
        set     = function(self, val) self:SetEdgeScale(val) end,
        get     = function(self) self:GetEdgeScale() end,
    }

    --- Sets the edge texture
    Property    {
        name    = "EdgeTexture",
        type    = TextureType,
        require = Cooldown,
        set     = function(self, val) if val.color then self:SetEdgeTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) else self:SetEdgeTexture(val) end end,
    }

    --- Whether hide count down numbers
    Property    {
        name    = "HideCountdownNumbers",
        type    = Boolean,
        require = Cooldown,
        default = false,
        set     = function(self, val) self:SetHideCountdownNumbers(val) end,
    }

    --- Whether the cooldown animation "sweeps" an area of darkness over the underlying image; false if the animation darkens the underlying image and "sweeps" the darkened area away
    Property    {
        name    = "Reverse",
        type    = Boolean,
        require = Cooldown,
        default = false,
        set     = function(self, val) self:SetReverse(val) end,
        get     = function(self) self:GetReverse() end,
    }

    --- the swipe color
    Property    {
        name    = "SwipeColor",
        type    = ColorType,
        require = Cooldown,
        set     = function(self, val) self:SetSwipeColor(val) end,
    }

    --- the swipe texture
    Property    {
        name    = "SwipeTexture",
        type    = TextureType,
        require = Cooldown,
        set     = function(self, val) if val.color then self:SetSwipeTexture(val.file, val.color.r, val.color.g, val.color.b, val.color.a) else self:SetSwipeTexture(val) end end,
    }

    --- Whether use circular edge
    Property    {
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
    Property    {
        name    = "AltArrowKeyMode",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetAltArrowKeyMode(val) end,
        get     = function(self) return self:GetAltArrowKeyMode() end,
    }

    --- true if the edit box automatically acquires keyboard input focus
    Property    {
        name    = "AutoFocus",
        type    = Boolean,
        require = EditBox,
        default = true,
        set     = function(self, val) self:SetAutoFocus(val) end,
        get     = function(self) return self:IsAutoFocus() end,
    }

    --- the rate at which the text insertion blinks when the edit box is focused
    Property    {
        name    = "BlinkSpeed",
        type    = Number,
        require = EditBox,
        default = 0.5,
        set     = function(self, val) self:SetBlinkSpeed(val) end,
        get     = function(self) return self:GetBlinkSpeed() end,
    }

    --- Whether count the invisible letters for max letters
    Property    {
        name    = "CountInvisibleLetters",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetCountInvisibleLetters(val) end,
        get     = function(self) return self:IsCountInvisibleLetters() end,
    }

    Property    {
        name    = "HighlightColor",
        type    = ColorType,
        require = EditBox,
        set     = function(self, val) self:SetHighlightColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) return Color(self:GetHighlightColor()) end,
    }

    --- the maximum number of history lines stored by the edit box
    Property    {
        name    = "HistoryLines",
        type    = Number,
        require = EditBox,
        default = 0,
        set     = function(self, val) self:SetHistoryLines(val) end,
        get     = function(self) return self:GetHistoryLines() end,
    }

    --- the maximum number of bytes of text allowed in the edit box, default is 0(Infinite)
    Property    {
        name    = "MaxBytes",
        type    = Integer,
        require = EditBox,
        default = 0,
        set     = function(self, val) self:SetMaxBytes(val) end,
        get     = function(self) return self:GetMaxBytes() end,
    }

    --- the maximum number of text characters allowed in the edit box
    Property    {
        name    = "MaxLetters",
        type    = Integer,
        require = EditBox,
        default = 0,
        set     = function(self, val) self:SetMaxLetters(val) end,
        get     = function(self) return self:GetMaxLetters() end,
    }

    --- true if the edit box shows more than one line of text
    Property    {
        name    = "MultiLine",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetMultiLine(val) end,
        get     = function(self) return self:IsMultiLine() end,
    }

    --- true if the edit box only accepts numeric input
    Property    {
        name    = "Numeric",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetNumeric(val) end,
        get     = function(self) return self:IsNumeric() end,
    }

    --- the contents of the edit box as a number
    Property    {
        name    = "Number",
        type    = Number,
        require = EditBox,
        default = 0,
        set     = function(self, val) self:SetNumber(val) end,
        get     = function(self) return self:GetNumber() end,
    }

    --- true if the text entered in the edit box is masked
    Property    {
        name    = "Password",
        type    = Boolean,
        require = EditBox,
        default = false,
        set     = function(self, val) self:SetPassword(val) end,
        get     = function(self) return self:IsPassword() end,
    }

    --- the insets from the edit box's edges which determine its interactive text area
    Property    {
        name    = "TextInsets",
        type    = Inset,
        require = EditBox,
        set     = function(self, val) self:SetTextInsets(val.left, val.right, val.top, val.bottom) end,
        get     = function(self) return Inset(self:GetTextInsets()) end,
    }

    Property    {
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
    Property    {
        name    = "FadeDuration",
        type    = Number,
        require = MessageFrame,
        default = 3,
        set     = function(self, val) self:SetFadeDuration(val) end,
        get     = function(self) return self:GetFadeDuration() end,
    }

    --- whether messages added to the frame automatically fade out after a period of time
    Property    {
        name    = "Fading",
        type    = Boolean,
        require = MessageFrame,
        default = true,
        set     = function(self, val) self:SetFading(val) end,
        get     = function(self) return self:GetFading() end,
    }

    --- The power of the fade-out animation for disappearing messages
    Property    {
        name    = "FadePower",
        type    = Number,
        require = MessageFrame,
        default = 1,
        set     = function(self, val) self:SetFadePower(val) end,
        get     = function(self) return self:GetFadePower() end,
    }

    --- the position at which new messages are added to the frame
    Property    {
        name    = "InsertMode",
        type    = InsertMode,
        require = MessageFrame,
        default = "BOTTOM",
        set     = function(self, val) self:SetInsertMode(val) end,
        get     = function(self) return self:GetInsertMode() end,
    }

    --- the amount of time for which a message remains visible before beginning to fade out
    Property    {
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
    Property    {
        name    = "HorizontalScroll",
        type    = Number,
        require = ScrollFrame,
        default = 0,
        set     = function(self, val) self:SetHorizontalScroll(val) end,
        get     = function(self) return self:GetHorizontalScroll() end,
    }

    --- the scroll frame's vertical scroll position
    Property    {
        name    = "VerticalScroll",
        type    = Number,
        require = ScrollFrame,
        default = 0,
        set     = function(self, val) self:SetVerticalScroll(val) end,
        get     = function(self) return self:GetVerticalScroll() end,
    }

    --- The frame scrolled by the scroll frame
    Property    {
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
    Property    {
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
    Property    {
        name    = "ThumbTexture",
        type    = Number + String + TextureType + Texture,
        require = Slider,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetThumbTexture(val)
                    else
                        self:SetThumbTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetThumbTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetThumbTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetThumbTexture() end,
    }

    --- the minimum and maximum values of the slider bar
    Property    {
        name    = "MinMaxValues",
        type    = MinMax,
        require = { Slider, StatusBar },
        set     = function(self, val) self:SetMinMaxValues(val.min, val.max) end,
        get     = function(self) return MinMax(self:GetMinMaxValues()) end,
    }

    --- the orientation of the slider
    Property    {
        name    = "Orientation",
        type    = Orientation,
        require = { Slider, StatusBar },
        set     = function(self, val) self:SetOrientation(val) end,
        get     = function(self) return self:GetOrientation() end,
    }

    --- the steps per page of the slider bar
    Property    {
        name    = "StepsPerPage",
        type    = Number,
        require = Slider,
        default = 0,
        set     = function(self, val) self:SetStepsPerPage(val) end,
        get     = function(self) return self:GetStepsPerPage() end,
    }

    --- Whether obey the step setting when drag the slider bar
    Property    {
        name    = "ObeyStepOnDrag",
        type    = Boolean,
        require = Slider,
        default = false,
        set     = function(self, val) self:SetObeyStepOnDrag(val) end,
        get     = function(self) return self:GetObeyStepOnDrag() end,
    }

    --- the value representing the current position of the slider thumb
    Property    {
        name    = "Value",
        type    = Number,
        require = { Slider, StatusBar },
        default = 0,
        set     = function(self, val) self:SetValue(val) end,
        get     = function(self) return self:GetValue() end,
    }

    --- the minimum increment between allowed slider values
    Property    {
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
    Property    {
        name    = "RotatesTexture",
        type    = Boolean,
        require = StatusBar,
        default = false,
        set     = function(self, val) self:SetRotatesTexture(val) end,
        get     = function(self) return self:GetRotatesTexture() end,
    }

    --- Whether the status bar's texture is reverse filled
    Property    {
        name    = "ReverseFill",
        type    = Boolean,
        require = StatusBar,
        default = false,
        set     = function(self, val) self:SetReverseFill(val) end,
        get     = function(self) return self:GetReverseFill() end,
    }

    Property    {
        name    = "FillStyle",
        type    = FillStyle,
        require = StatusBar,
        default = "STANDARD",
        set     = function(self, val) self:SetFillStyle(val) end,
        get     = function(self) return self:GetFillStyle() end,
    }

    --- The texture atlas
    Property    {
        name    = "StatusBarAtlas",
        type    = String,
        require = StatusBar,
        set     = function(self, val) self:SetStatusBarAtlas(val) end,
        get     = function(self) return self:GetStatusBarAtlas() end,
    }

    --- the color shading for the status bar's texture
    Property    {
        name    = "StatusBarColor",
        type    = ColorType,
        require = StatusBar,
        default = Color.WHITE,
        set     = function(self, val) self:SetStatusBarColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) return Color(self:GetStatusBarColor()) end,
    }

    Property    {
        name    = "StatusBarTexture",
        type    = Number + String + TextureType + Texture,
        require = StatusBar,
        set     = function(self, val)
                    if type(val) ~= "table" or getmetatable(val) ~= nil then
                        self:SetStatusBarTexture(val)
                    else
                        self:SetStatusBarTexture(val.file)
                        val = val.texcoord
                        if val then
                            if val.left then
                                self:GetStatusBarTexture():SetTexCoord(val.left, val.right, val.top, val.bottom)
                            else
                                self:GetStatusBarTexture():SetTexCoord(val.ULx, val.ULy, val.LLx, val.LLy, val.URx, val.URy, val.LRx, val.LRy)
                            end
                        end
                    end
                end,
        get     = function(self) return self:GetStatusBarTexture() end,
    }
end

------------------------------------------------------------
--                         Model                          --
------------------------------------------------------------
do
    --- The model's camera distance
    Property    {
        name    = "CameraDistance",
        type    = Number,
        require = Model,
        set     = function(self, val) self:SetCameraDistance(val) end,
        get     = function(self) return self:GetCameraDistance() end,
    }

    --- The model's camera facing
    Property    {
        name    = "CameraFacing",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetCameraFacing(val) end,
        get     = function(self) return self:GetCameraFacing() end,
    }

    --- The model's camera position
    Property    {
        name    = "CameraPosition",
        type    = Position,
        require = { Model, ModelScene },
        set     = function(self, val) self:SetCameraPosition(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetCameraPosition()) end,
    }

    --- The model's camera target position
    Property    {
        name    = "CameraTarget",
        type    = Position,
        require = Model,
        set     = function(self, val) self:SetCameraTarget(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetCameraTarget()) end,
    }

    --- The model's camera roll
    Property    {
        name    = "CameraRoll",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetCameraRoll(val) end,
        get     = function(self) return self:GetCameraRoll() end,
    }

    --- Whether has custom camera
    Property    {
        name    = "CustomCamera",
        type    = Boolean,
        require = Model,
        default = false,
        set     = function(self, val) self:SetCustomCamera(val) end,
        get     = function(self) return self:HasCustomCamera() end,
    }

    --- the model's current fog color
    Property    {
        name    = "FogColor",
        type    = ColorType,
        require = { Model, ModelScene },
        default = Color.WHITE,
        set     = function(self, val) self:SetFogColor(val.r, val.g, val.b, val.a) end,
        get     = function(self) return Color(self:GetFogColor()) end,
    }

    --- the far clipping distance for the model's fog
    Property    {
        name    = "FogFar",
        type    = Number,
        require = { Model, ModelScene },
        default = 1,
        set     = function(self, val) self:SetFogFar(val) end,
        get     = function(self) return self:GetFogFar() end,
    }

    --- the near clipping distance for the model's fog
    Property    {
        name    = "FogNear",
        type    = Number,
        require = { Model, ModelScene },
        default = 0,
        set     = function(self, val) self:SetFogNear(val) end,
        get     = function(self) return self:GetFogNear() end,
    }

    --- The model's facing
    Property    {
        name    = "Facing",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetFacing(val) end,
        get     = function(self) return self:GetFacing() end,
    }

    --- the light sources used when rendering the model
    Property    {
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
    Property    {
        name    = "Model",
        type    = String,
        require = Model,
        set     = function(self, val) self:SetModel(val) end,
        clear   = function(self) self:ClearModel() end,
    }

    --- The model's alpha
    Property    {
        name    = "ModelAlpha",
        type    = ColorFloat,
        require = Model,
        default = 1,
        set     = function(self, val) self:SetModelAlpha(val) end,
        get     = function(self) return self:GetModelAlpha() end,
    }

    Property    {
        name    = "ModelCenterToTransform",
        type    = Boolean,
        require = Model,
        default = false,
        set     = function(self, val) self:UseModelCenterToTransform(val) end,
        get     = function(self) return self:IsUsingModelCenterToTransform() end,
    }

    --- The model's draw layer
    Property    {
        name    = "ModelDrawLayer",
        type    = DrawLayer,
        require = Model,
        default = "ARTWORK",
        set     = function(self, val) self:SetModelDrawLayer(val) end,
        get     = function(self) return self:GetModelDrawLayer() end,
    }

    --- the scale factor determining the size at which the 3D model appears
    Property    {
        name    = "ModelScale",
        type    = Number,
        require = Model,
        default = 1,
        set     = function(self, val) self:SetModelScale(val) end,
        get     = function(self) return self:GetModelScale() end,
    }

    --- the position of the 3D model within the frame
    Property    {
        name    = "Position",
        type    = Position,
        require = Model,
        default = Position(0, 0, 0),
        set     = function(self, val) self:SetPosition(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetPosition()) end,
    }

    Property    {
        name    = "Paused",
        type    = Boolean,
        require = Model,
        default = false,
        set     = function(self, val) self:SetPaused(val) end,
        get     = function(self) return self:GetPaused() end,
    }

    Property    {
        name    = "ParticlesEnabled",
        type    = Boolean,
        require = Model,
        default = false,
        set     = function(self, val) self:SetParticlesEnabled(val) end,
    }

    --- The model's pitch
    Property    {
        name    = "Pitch",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetPitch(val) end,
        get     = function(self) return self:GetPitch() end,
    }

    --- The model's roll
    Property    {
        name    = "Roll",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetRoll(val) end,
        get     = function(self) return self:GetRoll() end,
    }

    --- The shadow effect
    Property    {
        name    = "ShadowEffect",
        type    = Number,
        require = Model,
        default = 0,
        set     = function(self, val) self:SetShadowEffect(val) end,
        get     = function(self) return self:GetShadowEffect() end,
    }

    Property    {
        name    = "ViewInsets",
        type    = Inset,
        require = { Model, ModelScene },
        default = Inset(0, 0, 0, 0),
        set     = function(self, val) self:SetViewInsets(val.left, val.right, val.top, val.bottom) end,
        get     = function(self) return Inset(self:GetViewInsets()) end,
    }

    Property    {
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
    Property    {
        name    = "CameraFarClip",
        type    = Number,
        require = ModelScene,
        default = 100,
        set     = function(self, val) self:SetCameraFarClip(val) end,
        get     = function(self) return self:GetCameraFarClip() end,
    }

    Property    {
        name    = "CameraNearClip",
        type    = Number,
        require = ModelScene,
        default = 0.2,
        set     = function(self, val) self:SetCameraNearClip(val) end,
        get     = function(self) return self:GetCameraNearClip() end,
    }

    Property    {
        name    = "LightAmbientColor",
        type    = ColorType,
        require = ModelScene,
        default = Color(0.7, 0.7, 0.7),
        set     = function(self, val) self:SetLightAmbientColor(val.r, val.g, val.b) end,
        get     = function(self) return Color(self:GetLightAmbientColor()) end,
    }

    Property    {
        name    = "LightPosition",
        type    = Position,
        require = ModelScene,
        default = Position(0, 0, 0),
        set     = function(self, val) self:SetLightPosition(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetLightPosition()) end,
        }

    Property    {
        name    = "LightType",
        type    = Number,
        require = ModelScene,
        default = 1,
        set     = function(self, val) self:SetLightType(val) end,
        get     = function(self) return self:GetLightType() end,
    }

    Property    {
        name    = "LightDirection",
        type    = Position,
        require = ModelScene,
        default = Position(0, 1, 0),
        set     = function(self, val) self:SetLightDirection(val.x, val.y, val.z) end,
        get     = function(self) return Position(self:GetLightDirection()) end,
    }

    Property    {
        name    = "CameraFieldOfView",
        type    = Number,
        require = ModelScene,
        default = 0.94,
        set     = function(self, val) self:SetCameraFieldOfView(val) end,
        get     = function(self) return self:GetCameraFieldOfView() end,
    }

    Property    {
        name    = "LightDiffuseColor",
        type    = ColorType,
        require = ModelScene,
        default = Color(0.8, 0.8, 0.64),
        set     = function(self, val) self:SetLightDiffuseColor(val.r, val.g, val.b) end,
        get     = function(self) return Color(self:GetLightDiffuseColor()) end,
    }

    Property    {
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
    Property    {
        name    = "AutoDress",
        type    = Boolean,
        require = DressUpModel,
        default = true,
        set     = function(self, val) self:SetAutoDress(val) end,
        get     = function(self) return self:GetAutoDress() end,
    }

    --- Whether sheathed the weapon
    Property    {
        name    = "Sheathed",
        type    = Boolean,
        require = DressUpModel,
        default = false,
        set     = function(self, val) self:SetSheathed(val) end,
        get     = function(self) return self:GetSheathed() end,
    }

    --- Whether use transmog skin
    Property    {
        name    = "UseTransmogSkin",
        type    = Boolean,
        require = DressUpModel,
        default = false,
        set     = function(self, val) self:SetUseTransmogSkin(val) end,
        get     = function(self) return self:GetUseTransmogSkin() end,
    }
end