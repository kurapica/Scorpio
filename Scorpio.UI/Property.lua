--========================================================--
--              Scorpio UI Widget Properties              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/01/09                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Property"              "1.0.0"
--========================================================--

Style.Property {
    name    = "Visible",
    type    = Boolean,
    get     = function(self) local isShown = self.IsShown if isShown then return isShown(self) and true or false end end,
    set     = function(self, visible) local mtd = self[visible and "Show" or "Hide"] if mtd then mtd(self) end end,
}

Style.Property {
    name    = "Width",
    type    = Number,
}