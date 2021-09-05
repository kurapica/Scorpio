--========================================================--
--                Scorpio Message System                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/09/05                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Message"                      ""
--========================================================--

SCORPIO_ADDON_PREFIX            = "SCORPIO"

MESSAGE_OVERHEAD                = 40
MAX_BYTE_SECOND                 = 2000
MAX_AVAILABLE                   = 8000

_WorldBeginTime                 = 0
_Available                      = 0
_LastUpdate                     = 0

_Recycle                        = Recycle()

_ProcessQueue                   = false
_AddonMessageQueue              = Queue()
_ResultMessages                 = {}

_ModulePrefixHandler            = {}


------------------------------------------------------------
--                        Helpers                         --
------------------------------------------------------------
export { min = math.min, ceil = math.ceil, floor = math.floor, random = math.random, format = string.format, char = string.char, byte = string.byte, concat = table.concat }

function updateAvailable()
    local now               = GetTime()
    _Available              = min(MAX_AVAILABLE, _Available + floor(MAX_BYTE_SECOND * (now - _LastUpdate)))
    _LastUpdate             = now
end

function toNumber(str)
    local b1, b2            = byte(str, 1, 2)
    return (b1 - 65) * 26 + b2 - 65
end

function toString(index)
    return char(65 + floor(index / 26), 65 + index % 26)
end

------------------------------------------------------------
--                  Message Enumeration                   --
------------------------------------------------------------
if Scorpio.IsRetail then
    __Sealed__() enum "ChatType"    { "PARTY", "RAID", "INSTANCE_CHAT", "GUILD", "OFFICER", "WHISPER", "CHANNEL" }
else
    __Sealed__() enum "ChatType"    { "PARTY", "RAID", "INSTANCE_CHAT", "GUILD", "OFFICER", "WHISPER", "SAY", "YELL" }
end

------------------------------------------------------------
--                 Message Event Handler                  --
------------------------------------------------------------
function OnEnable()
    OnEnable                    = nil
    C_ChatInfo.RegisterAddonMessagePrefix(SCORPIO_ADDON_PREFIX)
end

__SystemEvent__()
function PLAYER_ENTERING_WORLD()
    _WorldBeginTime             = GetTime()
    _LastUpdate                 = GetTime()
    _Available                  = 0
end

__SecureHook__"SendChatMessage"
function Hook_SendChatMessage(message, chatType, language, target)
    _Available                  = _Available - (#tostring(message or "") + #tostring(target or "") + MESSAGE_OVERHEAD)
end

__SecureHook__(_G.C_ChatInfo, "SendAddonMessage")
function Hook_SendAddonMessage(prefix, message, chatType, target)
    _Available                  = _Available - (#tostring(prefix or "") + #tostring(message or "") + #tostring(target or "") + MESSAGE_OVERHEAD)
end

__Async__()
function DistributeMessages(packet, channel, sender, target)
    local data                  = Toolset.parsestring(DeflateDecode(Base64Decode(concat(packet))))
    if data then
        for _, item in ipairs(data) do
            local prefix        = item[1]
            local message       = item[2] and Toolset.parsestring(item[2])

            if prefix and message then
                local handlers  = _ModulePrefixHandler[prefix]

                if handlers then
                    for owner, handler in pairs(handlers) do
                        local ok, err = pcall(handler, message, channel, sender, target)
                        if not ok then geterrorhandler()(err) end
                    end
                end
            end
        end
    end
end

__SystemEvent__()
function CHAT_MSG_ADDON(prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)
    if prefix ~= SCORPIO_ADDON_PREFIX then return end

    local pid, count, id, msg   = text:match("^(%w+):(%w+):(%w+):(.*)$")
    pid                         = pid and tonumber(pid, 16)
    count                       = count and toNumber(count)
    id                          = id and toNumber(id)

    if pid and count and id then
        local now               = GetTime()
        local dist              = _ResultMessages[pid]

        if dist and ((now - dist.time) >= 10 or dist.count ~= count or (#dist + 1 ~= id)) then
            dist                = nil
            _ResultMessages[pid]= nil
        end

        if not dist then
            if id == 1 then
                dist            = { time = now, count = count, [1] = msg }
                _ResultMessages[pid] = dist
            else
                return -- Abandon, no more check, no ack for now
            end
        else
            dist[#dist + 1]     = msg
        end

        if id == dist.count then
            -- All received
            _ResultMessages[pid]= nil
            DistributeMessages(dist, channel, sender, target)
        end
    end
end

__Iterator__()
function iterdist(packets)
    local yield                 = coroutine.yield

    for chatType, dist in pairs(packets) do
        if chatType == "WHISPER" or chatType == "CHANNEL" then
            for target, sdist in pairs(dist) do
                yield(sdist, chatType, target)
                _Recycle(wipe(sdist))
            end
        else
            yield(dist, chatType)
        end
        _Recycle(wipe(dist))
    end

    _Recycle(wipe(packets))
end

__Service__(true)
function ProcessMessages()
    while true do
        while _AddonMessageQueue.Count == 0 do Next() end

        local packets           = _Recycle()
        local callbacks         = _Recycle()
        local total             = 0

        -- Build the distribution
        repeat
            local chatType, prefix, message, target, callback = _AddonMessageQueue:Dequeue(5)

            if callback then tasks[callback] = true end

            local dist          = packets[chatType] or _Recycle()
            packets[chatType]   = dist

            local temp          = _Recycle()
            message             = Toolset.tostring(message)

            total               = total + #message

            temp[1]             = prefix
            temp[2]             = message

            if target ~= -1 then
                local subDist   = dist[target] or _Recycle()
                dist[target]    = subDist

                subDist[#subDist + 1] = temp
            else
                dist[#dist + 1] = temp
            end

            -- Not too big
            if total >= 256 then break end
        until _AddonMessageQueue.Count <= 0

        -- Send the packets
        for dist, chatType, target in iterdist(packets) do
            local extra         = #SCORPIO_ADDON_PREFIX + (target and #tostring(target) or 0)
            local maxlen        = 238 - extra
            local message       = Base64Encode(DeflateEncode(Toolset.tostring(dist)))
            local length        = #message
            local count         = ceil(length / maxlen) -- 12bit for header
            local header        = format("%06X:", random(0xffffff)) .. toString(count) .. ":"

            updateAvailable()

            -- Send the messages
            for i = 1, count do
                local msg       = header .. toString(i) .. ":" .. message:sub(1 + (i-1) * maxlen, i * maxlen)
                local len       = #msg + extra

                while _Available < len do
                    local delay = (len - _Available) / MAX_BYTE_SECOND
                    if delay >= 0.1 then Delay(delay) else Next() end
                    updateAvailable()
                end

                C_ChatInfo.SendAddonMessage(SCORPIO_ADDON_PREFIX, msg, chatType, target)
            end
        end

        -- Invoke the callback or resume the coroutine
        for callback in pairs(callbacks) do
            if type(callback) == "function" then
                local ok, err   = pcall(callback)
                if not ok then geterrorhandler()(err) end
            else
                coroutine.resume(callback)
            end
        end

        _Recycle(callbacks)

        Next()
    end
end

------------------------------------------------------------
--                   Message Attribute                    --
------------------------------------------------------------
--- Register a handler for the prefix message
-- @usage
--      Scorpio "MyAddon" "v1.0.1"
--
--      __Message__()
--      function PLAYER_COOLDOWN_UPDATE(cooldown, sender)
--          print(cooldown.spellid, cooldown.start, cooldown.duration)
--      end
--
--      __Message__ "PLAYER_COOLDOWN_START" "PLAYER_COOLDOWN_UPDATE"
--      function PLAYER_COOLDOWN(cooldown, sender)
--      end
--
--      SendAddonMessage("PLAYER_COOLDOWN_UPDATE", { spellid = 1923, start = GetTime(), duration = 3 })
__Sealed__()
class "__Message__" (function(_ENV)
    extend "IAttachAttribute"

    function AttachAttribute(self, target, targettype, owner, name, stack)
        if Class.IsObjectType(owner, Scorpio) then
            if #self > 0 then
                for _, evt in ipairs(self) do
                    _ModulePrefixHandler[evt]       = _ModulePrefixHandler[evt] or {}
                    _ModulePrefixHandler[evt][owner]= target
                end
            else
                _ModulePrefixHandler[name]          = _ModulePrefixHandler[name] or {}
                _ModulePrefixHandler[name][owner]   = target
            end
        else
            error("__Message__ can only be applyed to objects of Scorpio.", stack + 1)
        end
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    property "AttributeTarget"  { default = AttributeTargets.Function }

    ----------------------------------------------
    --                Constructor               --
    ----------------------------------------------
    __Arguments__{ NEString * 0 }
    function __new(cls, ...)
        return { ... }, true
    end

    ----------------------------------------------
    --                Meta-Method               --
    ----------------------------------------------
    __Arguments__{ NEString }
    function __call(self, other)
        tinsert(self, other)
        return self
    end
end)

------------------------------------------------------------
--                     Message Method                     --
------------------------------------------------------------
__Static__()
function Scorpio.SendAddonMessage(prefix, message, chatType, target, callback)
    if not Struct.ValidateValue(NEString, prefix) then error("Usage: SendAddonMessage(prefix, message[, chatType[, target]][, callback]) - The prefix must be a non-empty string", 2) end
    if not (message and Struct.ValidateValue(Serialization.Serializable, message)) then error("Usage: SendAddonMessage(prefix, message[, chatType[, target]][, callback]) - The message must be serializable", 2) end

    if type(chatType) == "function" or chatType == true then
        callback                = chatType
        chatType                = "PARTY"
    elseif type(target) == "function" or target == true then
        callback                = target
        target                  = nil
    end

    if chatType and not Enum.ValidateValue(ChatType, chatType) then error("Usage: SendAddonMessage(prefix, message[, chatType[, target]][, callback]) - The chatType is not valid", 2) end
    if chatType == "WHISPER" and not Struct.ValidateValue(NEString, target) then error("Usage: SendAddonMessage(prefix, message[, chatType[, target]][, callback]) - The target must be target user name", 2) end
    if chatType == "CHANNEL" and not Struct.ValidateValue(NaturalNumber, target) then error("Usage: SendAddonMessage(prefix, message[, chatType[, target]][, callback]) - The target must be a channel id", 2) end
    if callback and callback ~= true and type(callback) ~= "function" then error("Usage: SendAddonMessage(prefix, message[, chatType[, target]][, callback]) - The callback must be a function", 2) end

    local thread                = callback == true and coroutine.running()
    chatType                    = chatType or "PARTY"

    if chatType == "WHISPER" or chatType == "CHANNEL" then
        _AddonMessageQueue:Enqueue(chatType, prefix, message, target, thread or callback or false)
    else
        _AddonMessageQueue:Enqueue(chatType, prefix, message,     -1, thread or callback or false)
    end

    -- Waiting the result
    if thread then return coroutine.yield() end
end