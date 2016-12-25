--========================================================--
--                Scorpio SavedVariable Manager           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/20                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.SVManager"               "1.0.0"
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
                if ty == "function" then
                    if clonefunc then
                        tar[k] = v
                    else
                        tar[k] = v()
                    end
                elseif ty == "string" or ty == "boolean" or ty == "number" then
                    tar[k] = v
                end
            end
        end
    end
    return tar
end

------------------------------------------------------------
--                       SVManager                        --
------------------------------------------------------------
__Sealed__()
class "SVManager" (function(_ENV)

    _DBMap = {}
    _DBCharMap = {}

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Arguments__{ NEString, Table }
    function SetDefault(self, key, default)
        _DBMap[self][key] = copydefault(_DBMap[self][key], default)
    end

    __Arguments__{ Table}
    function SetDefault(self, default)
        _DBMap[self] = copydefault(_DBMap[self], default)
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
        end
    }

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        if _DBCharMap[self] then
            _DBCharMap[self]:Dispose()
            _DBCharMap[self] = nil
        end

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
        SetDefault = SetDefault

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

            _DBSpecDefault = {}

            ----------------------------------------------
            ------------------- Method -------------------
            ----------------------------------------------
            __Arguments__{ NEString, Table }
            function SetDefault(self, key, default)
                local cache = _DBSpecDefault[self] or {}
                _DBSpecDefault[self] = cache
                cache[key] = copydefault(cache[key], default, true)

                for i, v in pairs(_DBMap[self]) do
                    if type(i) == "number" then
                        v[key] = copydefault(v[key], default)
                    end
                end
            end

            __Arguments__{ Table}
            function SetDefault(self, default)
                local cache = _DBSpecDefault[self] or {}
                _DBSpecDefault[self] = cache
                cache[self] = copydefault(cache[self], default, true)

                for i, v in pairs(_DBMap[self]) do
                    if type(i) == "number" then
                        v = copydefault(v, default)
                    end
                end
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
                local set = _DBMap[self][GetSpecialization() or 1]
                if not set then
                    set = {}

                    if _DBSpecDefault[self] then
                        for k, v in pairs(_DBSpecDefault[self]) do
                            if k == self then
                                set = copydefault(set, v)
                            else
                                set[k] = copydefault(set[k], v)
                            end
                        end
                    end

                    _DBMap[self][GetSpecialization() or 1] = set
                end
                return set[key]
            end

            function __newindex(self, key, value)
                local set = _DBMap[self][GetSpecialization() or 1]
                if not set then
                    set = {}

                    if _DBSpecDefault[self] then
                        for k, v in pairs(_DBSpecDefault[self]) do
                            if k == self then
                                set = copydefault(set, v)
                            else
                                set[k] = copydefault(set[k], v)
                            end
                        end
                    end

                    _DBMap[self][GetSpecialization() or 1] = set
                end
                set[key] = value
            end
        end)
    end)
end)