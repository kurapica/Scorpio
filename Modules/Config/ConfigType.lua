--========================================================--
--                Scorpio SavedVariable Config Data Type  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/06/25                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config.Type"             "1.0.0"
--========================================================--

--- The range value like RangeValue[{0, 1, 0.01}] - min 0, max 1, step 0.01
__Sealed__() __Arguments__{ Number, Number, Number/nil }
struct "RangeValue"             (function(_ENV, min, max, step)
    __base                      = Number

    local errorMsg              = nil
    function __valid(value, onlyvalid)
        if value < min or value > max then
            if onlyvalid then return true end

            errorMsg            = errorMsg or "The %s must between [" .. min .. ", " .. max .. "]"
            return errorMsg
        end
    end
end)
