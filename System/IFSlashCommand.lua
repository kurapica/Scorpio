--========================================================--
--                IFSlashCommand                          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/09/09                              --
--========================================================--

--========================================================--
Module            "Scorpio.IFSlashCommand"           "1.0.0"
--========================================================--

__Doc__[[The slash command system provider]]
__Sealed__() interface "IFSlashCommand" (function(_ENV)

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local FireObjectEvent = System.Reflector.FireObjectEvent

    _SlashCmdCount = 0
    _SlashCmdNameMap = setmetatable({}, META_WEAKKEY)
    _SlashCmdFuncMap = setmetatable({}, META_WEAKKEY)

    -- SlashCmd Operation
    local function GetSlashCmdArgs(msg, input)
        local option, info

        if type(msg) == "string" then
            msg = strtrim(msg)

            if msg:sub(1, 1) == "\"" and msg:find("\"", 2) then
                option, info = msg:match("\"([^\"]+)\"%s*(.*)")
            else
                option, info = msg:match("(%S+)%s*(.*)")
            end

            if option == "" then option = nil end
            if info == "" then info = nil end
        end

        return option, info, input
    end

    ----------------------------------------------
    ------------------- Event  -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Fired when the registered slash commands is called</desc>
        <param name="option">the first word in slash command</param>
        <param name="info">remain string</param>
        <param name="input">the input editbox</param>
    ]]
    event "OnSlashCommand"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Register some slash commands</desc>
        <param name="...">the slash command list</param>
        <usage>obj:RegisterSlashCommand("/test", "test_cmd")</usage>
    ]]
    function RegisterSlashCommand(self, ...)
        if IsSlashCommandRegistered(self) then return end
        if select('#', ...) == 0 then return end

        local slashCmd = _SlashCmdNameMap[self]
        local slashFunc = _SlashCmdFuncMap[self]

        if not slashCmd then
            _SlashCmdCount = _SlashCmdCount + 1

            slashCmd = "Scorpio_SlashCommand_" .. _SlashCmdCount .. "_"
            _SlashCmdNameMap[self] = slashCmd

            slashFunc = function(msg, input)
                return FireObjectEvent(self, "OnSlashCommand", GetSlashCmdArgs(msg, input))
            end
        end

        local index = 0
        for i = 1, select('#', ...) do
            local cmd = select(1, ...)
            if type(cmd) == "string" then
                cmd = "/" .. strtrim(cmd):match("^/?([%w_]+)")
                if #cmd > 0 then
                    index = index + 1
                    _G["SLASH_"..slashCmd..index] = cmd
                end
            end
        end

        if index > 0 then
            _SlashCmdNameMap[self] = slashCmd
            _SlashCmdFuncMap[self] = slashFunc
            _G.SlashCmdList[slashCmd] = slashFunc
        end
    end

    __Doc__[[Whether the slash command is registered]]
    function IsSlashCommandRegistered(self)
        return _SlashCmdNameMap[self] and true or false
    end
end)