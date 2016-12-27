--========================================================--
--                Scorpio SavedVariable Manager           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/20                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.SVManager"               "1.0.1"
--========================================================--

----------------------------------------------
------------------- Prepare ------------------
----------------------------------------------
function copydefault(tar, default, clonefunc)
    if type(tar) ~= "table" then tar = {} end

    if default then
        for k, v in pairs(default) do
            local ty = type(v)

            if ty == "table" then
                tar[k] = copydefault(tar[k], v)
            elseif tar[k] == nil then
                if ty == "function" and clonefunc then
                    tar[k] = v
                else
                    if ty == "function" then
                        v = v()
                        ty = type(v)
                    end
                    if ty == "table" then
                        tar[k] = copydefault(tar[k], v)
                    elseif ty == "string" or ty == "boolean" or ty == "number" then
                        tar[k] = v
                    end
                end
            end
        end
    end
    return tar
end

------------------------------------------------------------
--                       SVManager                        --
------------------------------------------------------------
__Doc__[[The saved variables mananger]]
__Sealed__()
class "SVManager" (function(_ENV)

    _DBMap          = {}
    _DBSVDefault    = {}

    _DBCharMap      = {}

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[Set the default value for the account saved variable]]
    __Arguments__{ NEString + Number, Table }
    function SetDefault(self, key, default)
        _DBSVDefault[self] = _DBSVDefault[self] or {}
        _DBSVDefault[self][key] = copydefault(_DBSVDefault[self][key], default, true)

        _DBMap[self][key] = copydefault(_DBMap[self][key], default)
    end

    __Arguments__{ Table }
    function SetDefault(self, default)
        _DBSVDefault[self] = _DBSVDefault[self] or {}
        _DBSVDefault[self] = copydefault(_DBSVDefault[self], default, true)

        _DBMap[self] = copydefault(_DBMap[self], default)
    end

    __Doc__[[Reset the account saved variable with default]]
    function Reset(self)
        local cache = _DBMap[self]
        local chars = cache.__ScorpioChars

        wipe(cache)
        cache = copydefault(cache, _DBSVDefault[self])

        cache.__ScorpioChars = chars
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The char's saved variable]]
    property "Char" {
        Get = function(self)
            local char = _DBCharMap[self]
            if not char then
                local name, realm = UnitFullName("player")
                name = realm .. "-" .. name
                -- Char data should saved in the account data
                _DBMap[self].__ScorpioChars = _DBMap[self].__ScorpioChars or {}
                _DBMap[self].__ScorpioChars[name] = _DBMap[self].__ScorpioChars[name] or {}

                char = SVCharManager(_DBMap[self].__ScorpioChars[name])
                _DBCharMap[self] = char
            end
            return char
        end,
    }

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        if _DBCharMap[self] then
            _DBCharMap[self]:Dispose()
            _DBCharMap[self] = nil
        end

        _DBSVDefault[self] = nil
        _DBMap[self] = nil
    end

    ----------------------------------------------
    ----------------- Constructor ----------------
    ----------------------------------------------
    __Arguments__{ NEString }
    function SVManager(self, sv)
        _DBMap[self] = type(_G[sv] == "table") and _G[sv] or {}
        _G[sv] = _DBMap[self]
    end

    __Arguments__{ NEString, NEString }
    function SVManager(self, sv, svchar)
        _DBMap[self] = type(_G[sv] == "table") and _G[sv] or {}
        _G[sv] = _DBMap[self]

        _DBCharMap[self] = SVCharManager(svchar)
    end

    ----------------------------------------------
    ----------------- Meta-Method ----------------
    ----------------------------------------------
    function __index(self, key)
        return _DBMap[self][key]
    end

    function __newindex(self, key, value)
        _DBMap[self][key] = value
    end

    ----------------------------------------------
    ---------------- SVCharManager ---------------
    ----------------------------------------------
    class "SVCharManager" (function(_ENV)

        _DBSpecMap = {}

        ----------------------------------------------
        ------------------- Method -------------------
        ----------------------------------------------
        __Doc__[[Set the default value for the character saved variable]]
        SetDefault = SetDefault

        __Doc__[[Reset the character saved variable with default]]
        function Reset(self)
            local cache = _DBMap[self]
            local specs = cache.__ScorpioSpecs

            wipe(cache)
            cache = copydefault(cache, _DBSVDefault[self])

            cache.__ScorpioSpecs = specs
        end

        ----------------------------------------------
        ------------------ Property ------------------
        ----------------------------------------------
        __Doc__[[The char's specialization saved variable]]
        property "Spec" {
            Get = function(self)
                local spec = _DBSpecMap[self]
                if not spec then
                    _DBMap[self].__ScorpioSpecs = _DBMap[self].__ScorpioSpecs or {}

                    spec = SVSpecManager(_DBMap[self].__ScorpioSpecs)
                    _DBSpecMap[self] = spec
                end
                return spec
            end
        }

        ----------------------------------------------
        ------------------- Dispose ------------------
        ----------------------------------------------
        function Dispose(self)
            if _DBSpecMap[self] then
                _DBSpecMap[self]:Dispose()
                _DBSpecMap[self] = nil
            end

            _DBSVDefault[self] = nil
            _DBMap[self] = nil
        end
        ----------------------------------------------
        ----------------- Constructor ----------------
        ----------------------------------------------
        __Arguments__{ Table }
        function SVCharManager(self, sv)
            _DBMap[self] = sv
        end

        __Arguments__{ String }
        function SVCharManager(self, sv)
            _DBMap[self] = type(_G[sv] == "table") and _G[sv] or {}
            _G[sv] = _DBMap[self]
        end

        ----------------------------------------------
        ----------------- Meta-Method ----------------
        ----------------------------------------------
        function __index(self, key)
            return _DBMap[self][key]
        end

        function __newindex(self, key, value)
            _DBMap[self][key] = value
        end

        ----------------------------------------------
        ---------------- SVSpecManager ---------------
        ----------------------------------------------
        class "SVSpecManager" (function(_ENV)

            ----------------------------------------------
            ------------------- Method -------------------
            ----------------------------------------------
            __Doc__[[Set the default value for the specialization saved variable]]
            __Arguments__{ NEString + Number, Table }
            function SetDefault(self, key, default)
                _DBSVDefault[self] = _DBSVDefault[self] or {}
                _DBSVDefault[self][key] = copydefault(_DBSVDefault[self][key], default, true)

                for i, v in pairs(_DBMap[self]) do
                    if type(i) == "number" then
                        v[key] = copydefault(v[key], default)
                    end
                end
            end

            __Arguments__{ Table }
            function SetDefault(self, default)
                _DBSVDefault[self] = _DBSVDefault[self] or {}
                _DBSVDefault[self] = copydefault(_DBSVDefault[self], default, true)

                for i, v in pairs(_DBMap[self]) do
                    if type(i) == "number" then
                        v = copydefault(v, default)
                    end
                end
            end

            __Doc__[[Reset current specialization saved variable with default]]
            function Reset(self)
                local cache = _DBMap[self][GetSpecialization() or 1]
                if cache then
                    wipe(cache)
                    cache = copydefault(cache, _DBSVDefault[self])
                end
            end

            __Doc__[[Reset all specialization saved variables with default]]
            function ResetAll(self)
                for i, v in pairs(_DBMap[self]) do
                    if type(i) == "number" then
                        wipe(v)
                        v = copydefault(v, _DBSVDefault[self])
                    end
                end
            end

            ----------------------------------------------
            ------------------- Dispose ------------------
            ----------------------------------------------
            function Dispose(self)
                _DBSVDefault[self] = nil
                _DBMap[self] = nil
            end

            ----------------------------------------------
            ----------------- Constructor ----------------
            ----------------------------------------------
            __Arguments__{ Table }
            function SVSpecManager(self, sv)
                _DBMap[self] = sv
            end

            ----------------------------------------------
            ----------------- Meta-Method ----------------
            ----------------------------------------------
            function __index(self, key)
                local cache = _DBMap[self][GetSpecialization() or 1]
                if not cache then
                    cache = copydefault({}, _DBSVDefault[self])
                    _DBMap[self][GetSpecialization() or 1] = cache
                end
                return cache[key]
            end

            function __newindex(self, key, value)
                local cache = _DBMap[self][GetSpecialization() or 1]
                if not cache then
                    cache = copydefault({}, _DBSVDefault[self])
                    _DBMap[self][GetSpecialization() or 1] = cache
                end
                cache[key] = value
            end
        end)
    end)
end)