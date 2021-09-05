--========================================================--
--                Scorpio Encoder System                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/09/05                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Encoder"                      ""
--========================================================--

import "System.Text"

export { concat = table.concat }

_Recycle                        = Recycle()

__Static__()
function Scorpio.Base64Encode(str)
    if coroutine.running() then
        local index             = 0
        local cache             = _Recycle()
        local tindex            = 0
        local temp              = _Recycle()

        for c in Base64.Encodes(str) do
            tindex              = tindex + 1
            temp[tindex]        = c

            if tindex == 256 then
                index           = index + 1
                cache[index]    = concat(temp)

                tindex          = 0
                wipe(temp)

                Continue()
            end
        end

        if tindex > 0 then
            index               = index + 1
            cache[index]        = concat(temp)
            wipe(temp)
        end

        local result            = concat(cache)
        _Recycle(wipe(cache))
        _Recycle(temp)

        return result
    else
        return Base64.Encode(str)
    end
end

__Static__()
function Scorpio.Base64Decode(str)
    if coroutine.running() then
        local index             = 0
        local cache             = _Recycle()
        local tindex            = 0
        local temp              = _Recycle()

        for c in Base64.Decodes(str) do
            tindex              = tindex + 1
            temp[tindex]        = c

            if tindex == 256 then
                index           = index + 1
                cache[index]    = concat(temp)

                tindex          = 0
                wipe(temp)

                Continue()
            end
        end

        if tindex > 0 then
            index               = index + 1
            cache[index]        = concat(temp)
            wipe(temp)
        end

        local result            = concat(cache)
        _Recycle(wipe(cache))
        _Recycle(temp)

        return result
    else
        return Base64.Decode(str)
    end
end

__Static__()
function Scorpio.DeflateEncode(str)
    if coroutine.running() then
        local index             = 0
        local cache             = _Recycle()

        for c in Deflate.Encodes(str) do
            index               = index + 1
            cache[index]        = c

            Continue()
        end

        local result            = concat(cache)
        _Recycle(wipe(cache))

        return result
    else
        return Deflate.Encode(str)
    end
end

__Static__()
function Scorpio.DeflateDecode(str)
    if coroutine.running() then
        local index             = 0
        local cache             = _Recycle()

        for c in Deflate.Decodes(str) do
            index               = index + 1
            cache[index]        = c

            Continue()
        end

        local result            = concat(cache)
        _Recycle(wipe(cache))

        return result
    else
        return Deflate.Decode(str)
    end
end