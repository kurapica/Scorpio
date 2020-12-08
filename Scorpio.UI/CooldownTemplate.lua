--========================================================--
--             Scorpio Cooldown Template                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/12/07                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.CooldownTemplate"      "1.0.0"
--========================================================--

----------------------------------------------
-- Data Type
----------------------------------------------
__Sealed__() struct "CooldownStatus" {
    { name = "start",   type = Number },
    { name = "duration",type = Number },
}

----------------------------------------------
-- Template
----------------------------------------------
__Sealed__() __ChildProperty__(Frame, "CooldownLabel")
class "CooldownLabel" (function(_ENV)
    inherit "FontString"

    --- Whether use auto color on the label based on the duration
    property "AutoColor"        { type = Boolean,   default = true }

    --- The alert second that used to notify the user
    property "AlertSecond"      { type = Number,    default = 10 },

    --- The color for duration over 1 day
    property "DayColor"         { type = ColorType, default = Color(0.4, 0.4, 0.4) }

    --- The color for duration over 1 hour
    property "HourColor"        { type = ColorType, default = Color(0.6, 0.4, 0) }

    --- The color for duration over 1 min
    property "MinuteColor"      { type = ColorType, default = Color(0.8, 0.6, 0) }

    --- The color for duration over the alert second
    property "SecondColor"      { type = ColorType, default = Color(1, 0.82, 0) }

    --- The shine color for duration less than the alert second
    property "AlertInColor"     { type = ColorType, default = Color(1, 0.82, 0.12) }

    --- The shine color for duration less than the alert second
    property "AlertOutColor"    { type = ColorType, default = Color(1, 0.12, 0.12) }

    --- The day suffix text
    property "DaySuffix"        { type = String,    default = "d" }

    --- The hour suffix text
    property "HourSuffix"       { type = String,    default = "h" }

    --- The miniute suffix text
    property "MinuteSuffix"     { type = String,    default = "m" }

    --- Set the cooldown status
    __AsyncSingle__(true)
    function SetCooldown(self, start, duration)
        local total             = start and duration and (start + duration) or 0
        local now               = GetTime()

        while total > now do
            local remain        = total - now

            if remain < self.AlertSecond then
                if self.AutoColor then
                    self:SetText((remain - floor(remain) > 0.5 and self.AlertInColor or self.AlertOutColor) .. strformat("%.1f", remain))
                else
                    self:SetText(strformat("%.1f", remain))
                end
                Delay(0.1)
            elseif remain < 60 then
                if self.AutoColor then
                    self:SetText(self.SecondColor .. ceil(remain))
                else
                    self:SetText(ceil(remain))
                end
                Delay(1)
            elseif remain < 3600 then
                if self.AutoColor then
                    self:SetText(self.MinuteColor .. ceil(remain / 60) .. self.MinuteSuffix)
                else
                    self:SetText(ceil(remain / 60) .. self.MinuteSuffix)
                end
                remain          = remain % 60
                Delay(remain > 0 and remain or 60)
            elseif (remain < 86400) then
                if self.AutoColor then
                    self:SetText(self.HourColor .. ceil(remain / 3600) .. self.HourSuffix)
                else
                    self:SetText(ceil(remain / 3600) .. self.HourSuffix)
                end
                remain          = remain % 3600
                Delay(remain > 0 and remain or 3600)
            else
                if self.AutoColor then
                    self:SetText(self.HourColor .. ceil(remain / 86400) .. self.DaySuffix)
                else
                    self:SetText(ceil(remain / 86400) .. self.DaySuffix)
                end
                remain          = remain % 86400
                Delay(remain > 0 and remain or 86400)
            end

            now                 = GetTime()
        end

        self:SetText("")
    end
end)

__Sealed__() __ChildProperty__(Frame, "CooldownStatusBar")
class "CooldownStatusBar" (function(_ENV)
    inherit "StatusBar"

    --- Whether the status bar is reversed
    property "Reverse"      { type = Boolean }

    --- Whether auto hide the status bar when cooldown finished
    property "AutoHide"     { type = Boolean, default = true }

    __AsyncSingle__(true)
    function SetCooldown(self, start, duration)
        Next() -- waiting the reverse settings to be applied at the same time

        local now               = GetTime()
        local fin               = start and duration and (start + duration) or 0
        local reversed          = self.Reverse

        if fin > now then
            self:SetMinMaxValues(0, duration)

            while fin > now do
                local remain    = now - start
                self:SetValue(reversed and (fin - now) or remain)

                Delay(max(0.1, remain / 100))

                now             = GetTime()
            end
        end

        -- Reset
        self:SetMinMaxValues(0, 100)
        self:SetValue(reversed and 100 or 0)
        if self.AutoHide then self:Hide() end
    end
end)

----------------------------------------------
-- Property
----------------------------------------------
--- The start and duration settings
UI.Property                     {
    name                        = "Cooldown",
    type                        = CooldownStatus,
    require                     = { Cooldown, CooldownLabel, CooldownStatusBar },
    nilable                     = true,
    set                         = function(self, val)
        if val and val.duration then
            self:SetCooldown(val.start or GetTime(), val.duration)
        else
            self:SetCooldown(GetTime(), 0)
        end
    end,
}

----------------------------------------------
-- Default Style
----------------------------------------------
Style.UpdateSkin("Default",     {
    [CooldownLabel]             = {
        drawLayer               = "ARTWORK",
        fontObject              = CombatTextFont,
        textColor               = Color.WHITE,
    }
}