--========================================================--
--             Scorpio Draggable Widget                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.Draggable"          "1.0.0"
--========================================================--

-----------------------------------------------------------
--                   Draggable Widget                    --
-----------------------------------------------------------
__Sealed__() class "Mover" (function(_ENV)
    inherit "Frame"

    -- Fired when stop moving
    event "OnMoved"

    local function onMouseDown(self)
        local parent            = self:GetParent()
        if parent:IsMovable() then
            self.IsMoving       = true
            parent:StartMoving()
        end
    end

    local function onMouseUp(self)
        if self.IsMoving then
            self.IsMoving       = false
            self:GetParent():StopMovingOrSizing()
            OnMoved(self)
        end
    end

    function __ctor(self)
        self.OnMouseDown        = onMouseDown
        self.OnMouseUp          = onMouseUp
    end
end)

__Sealed__() class "Resizer" (function(_ENV)
    inherit "Button"

    -- Fired when stop resizing
    event "OnResized"

    local function onMouseDown(self)
        local parent            = self:GetParent()
        if parent:IsResizable() then
            self.IsResizing     = true
            parent:StartSizing("BOTTOMRIGHT")
        end
    end

    local function onMouseUp(self)
        if self.IsResizing then
            self.IsResizing     = false
            self:GetParent():StopMovingOrSizing()
            OnResized(self)
        end
    end

    function __ctor(self)
        self.OnMouseDown        = onMouseDown
        self.OnMouseUp          = onMouseUp
    end
end)

-----------------------------------------------------------
--                    Draggable Style                    --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [Mover]                     = {
        Location                = {
            Anchor("TOPLEFT"), Anchor("TOPRIGHT")
        },
        Height                  = 26,
    },
    [Resizer]                   = {
        Location                = { Anchor("BOTTOMRIGHT") },
        Size                    = Size(16, 16),
        NormalTexture           = {
            file                = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]],
        },
        PushedTexture           = {
            file                = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]],
        },
        HighlightTexture        = {
            file                = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]],
        }
    },
})

Style.ActiveSkin("Default",     Mover)
Style.ActiveSkin("Default",     Resizer)