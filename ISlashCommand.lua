--========================================================--
--                Scorpio.ISlashCommand                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/09/09                              --
--========================================================--

--========================================================--
Module            "Scorpio.ISlashCommand"            "1.0.0"
--========================================================--

__Doc__[[The slash command system provider]]
__Sealed__() interface "ISlashCommand" (function(_ENV)

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local _SlashCmdList = _G.SlashCmdList

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
    __Delegate__(System.Threading.ThreadCall)
    event "OnSlashCommand"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Register some slash commands</desc>
        <param name="...">the slash command list</param>
        <usage>obj:RegisterSlashCommand("/test", "test_cmd")</usage>
    ]]
    __Arguments__{ Argument{ Type = String, IsList = true } }
    function RegisterSlashCommand(self, ...)
        local slashCmd = _SlashCmdNameMap[self]
        local slashFunc = _SlashCmdFuncMap[self]

        if not slashCmd then
            -- New Slash Command
            _SlashCmdCount = _SlashCmdCount + 1

            slashCmd = "Scorpio_SlashCommand_" .. _SlashCmdCount .. "_"

            slashFunc = function(msg, input)
                return OnSlashCommand(self, GetSlashCmdArgs(msg, input))
            end
        end

        -- Generate the command list
        local slash = {}

        for i = 1, select('#', ...) do
            local cmd = select(i, ...)
            cmd = "/" .. strtrim(cmd):match("^/?([%w_]+)")
            if #cmd > 0 then
                slash[cmd:upper()] = true
            end
        end

        -- Check existed
        local index = 1

        while type(_G["SLASH_"..slashCmd..index]) == "string" do
            slash[_G["SLASH_"..slashCmd..index]:upper()] = nil
            index = index + 1
        end

        if next(slash) then
            _SlashCmdNameMap[self] = slashCmd
            _SlashCmdFuncMap[self] = slashFunc

            for cmd in pairs(slash) do
                _G["SLASH_"..slashCmd..index] = cmd
                index = index + 1
            end

            -- Need to register the slash command each time to update
            _SlashCmdList[slashCmd] = slashFunc
        end
    end

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        if _SlashCmdNameMap[self] then
            -- Don't clear the map since it's a weak table
            -- Since we can't remove the slash commands
            -- Just make it useless
            _SlashCmdList[_SlashCmdNameMap[self]] = function() end
        end
    end
end)