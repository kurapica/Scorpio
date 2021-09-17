--========================================================--
--                Scorpio SavedVariable Manager           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/20                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.SVManager"               "2.0.0"
--========================================================--

__Sealed__() __SuperObject__(false):AsInheritable()
local SVProxy                   = class (function(_ENV)

    local _RawData              = {}
    local _Manager              = {}
    local _Default              = {}

    local clone                 = Toolset.clone

    local function copydefault(tar, default, clonefunc)
        if type(tar) ~= "table" then tar = {} end

        if default then
            for k, v in pairs(default) do
                local ty        = type(v)

                if ty == "table" then
                    tar[k]      = copydefault(tar[k], v, clonefunc)
                elseif tar[k] == nil then
                    if ty == "function" and clonefunc then
                        tar[k]  = v
                    else
                        if ty == "function" then
                            v   = v()
                            ty  = type(v)
                        end
                        if ty == "table" then
                            tar[k]  = copydefault(tar[k], v, clonefunc)
                        elseif ty == "string" or ty == "boolean" or ty == "number" then
                            tar[k]  = v
                        end
                    end
                end
            end
        end
        return tar
    end

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    --- Gets the clone data
    function GetData(self)
        return clone(_RawData[self], true)
    end

    --- Wipes and Sets the new data
    __Arguments__{ Table }
    function SetData(self, data)
        copydefault(wipe(_RawData[self]), data)
        copydefault(_RawData[self], _Default[self])
    end

    --- Sets the default value for the account saved variable
    __Arguments__{ NEString + Number, Table }
    function SetDefault(self, key, default)
        local sDefault          = _Default[self]
        sDefault[key]           = copydefault(sDefault[key], default, true)

        for p, d in pairs(_Default) do
            if d == sDefault then
                _RawData[p][key]= copydefault(_RawData[p][key], default)
            end
        end
    end

    __Arguments__{ Table }
    function SetDefault(self, default)
        local sDefault          = _Default[self]
        copydefault(sDefault, default, true)

        for p, d in pairs(_Default) do
            if d == sDefault then
                copydefault(_RawData[p], default)
            end
        end
    end

    --- Reset the saved variable with default
    function Reset(self)
        copydefault(wipe(_RawData[self]), _Default[self])
    end

    --- Reset all saved variable proxies with the same default
    function ResetAll(self)
        local sDefault          = _Default[self]

        for p, d in pairs(_Default) do
            if d == sDefault then p:Reset() end
        end
    end

    ----------------------------------------------
    --                Constructor               --
    ----------------------------------------------
    __Arguments__{ Table, Table/nil }
    function __ctor(self, data, default)
        _RawData[self]          = data
        _Manager[data]          = self
        _Default[self]          = default or {}

        if default then copydefault(data, default) end
    end

    __Arguments__{ NEString, Table/nil }
    function __ctor(self, name, default)
        local data              = _G[name]
        if not data then
            data                = {}
            _G[name]            = data
        end
        _RawData[self]          = data
        _Manager[data]          = self
        _Default[self]          = default or {}

        if default then copydefault(data, default) end
    end

    __Arguments__{ Table, Any * 0 }
    function __exist(_, data)
        return _Manager[data]
    end

    __Arguments__{ NEString, Any * 0 }
    function __exist(_, name)
        return _Manager[_G[name]]
    end

    ----------------------------------------------
    --                Meta-method               --
    ----------------------------------------------
    function __index(self, key)
        return _RawData[self][key]
    end

    function __newindex(self, key, value)
        _RawData[self][key]     = value
    end
end)

--- The saved variables mananger
__Sealed__() class "SVManager" (function(_ENV)
    inherit (SVProxy)

    local _Root                 = {}

    ----------------------------------------------
    --               SVCharManager              --
    ----------------------------------------------
    __Sealed__() class "SVCharManager" (function(_ENV)
        inherit (SVProxy)

        if Scorpio.IsRetail then
            ----------------------------------------------
            --               SVSpecManager              --
            ----------------------------------------------
            __Sealed__() class "SVSpecManager" (function(_ENV)
                inherit (SVProxy)

                ----------------------------------------------
                --             SVWarModeManager             --
                ----------------------------------------------
                __Sealed__() class "SVWarModeManager" (function(_ENV)
                    inherit (SVProxy)

                    local _RTDefault        = {}

                    ----------------------------------------------
                    --                Constructor               --
                    ----------------------------------------------
                    __Arguments__{ Table + NEString, SVProxy/nil }
                    function __ctor(self, sv, root)
                        if root then
                            root            = _Root[root] or root
                            _RTDefault[root]= _RTDefault[root] or {}

                            super(self, sv, _RTDefault[root])
                        else
                            super(self, sv)
                        end
                    end
                end)

                local WarMode_PVE       = WarMode.PVE
                local WarMode_PVP       = WarMode.PVP
                local IsWarModeDesired  = C_PvP.IsWarModeDesired

                local _CurrentWarMode   = WarMode.PVE
                local _DBModeMap        = {}
                local _RTDefault        = {}

                ----------------------------------------------
                --                   Method                 --
                ----------------------------------------------
                function GetData(self)
                    local modes         = self.__ScorpioModes
                    self.__ScorpioModes = nil

                    local data          = super.GetData(self)

                    self.__ScorpioModes = modes

                    return data
                end

                __Arguments__{ Table }
                function SetData(self, data)
                    local modes         = self.__ScorpioModes
                    self.__ScorpioModes = nil

                    super.SetData(self, data)

                    self.__ScorpioModes = modes
                end

                --- Reset current specialization saved variable with default
                function Reset(self)
                    local modes         = self.__ScorpioModes

                    super.Reset(self)

                    self.__ScorpioModes = modes
                end

                ----------------------------------------------
                --                 Property                 --
                ----------------------------------------------
                --- The char's specialization saved variable
                property "WarMode"      {
                    get                 = function(self)
                        local cmode     = IsWarModeDesired() and WarMode_PVP or WarMode_PVE
                        if _CurrentWarMode ~= cmode then
                            _CurrentWarMode = cmode
                            wipe(_DBModeMap)
                        end

                        local mode      = _DBModeMap[self]
                        if not mode then
                            self.__ScorpioModes                 = self.__ScorpioModes or {}
                            self.__ScorpioModes[_CurrentWarMode]= self.__ScorpioModes[_CurrentWarMode] or {}
                            mode        = SVWarModeManager(self.__ScorpioModes[_CurrentWarMode], self)
                            _DBModeMap[self]= mode
                        end
                        return mode
                    end
                }

                --- The specialization sv mananger
                __Indexer__(WarMode)
                property "WarModes"     {
                    get                 = function(self, index)
                        local modes     = self.__ScorpioModes
                        local mode      = modes and modes[index]
                        return mode and SVWarModeManager(mode, self)
                    end,
                }

                ----------------------------------------------
                --                Constructor               --
                ----------------------------------------------
                __Arguments__{ Table + NEString, SVProxy/nil }
                function __ctor(self, sv, root)
                    if root then
                        root            = _Root[root] or root
                        _Root[self]     = root
                        _RTDefault[root]= _RTDefault[root] or {}

                        self.Default = _RTDefault[root]

                        super(self, sv, _RTDefault[root])
                    else
                        super(self, sv)
                    end
                end
            end)

            local _CurrentSpec  = 1
            local _DBSpecMap    = {}

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            --- The char's specialization saved variable
            property "Spec"     {
                get             = function(self)
                    local nowSpec                           = GetSpecialization() or 1
                    if _CurrentSpec ~= nowSpec then
                        _CurrentSpec                        = nowSpec
                        wipe(_DBSpecMap)
                    end

                    local spec  = _DBSpecMap[self]
                    if not spec then
                        self.__ScorpioSpecs                 = self.__ScorpioSpecs or {}
                        self.__ScorpioSpecs[_CurrentSpec]   = self.__ScorpioSpecs[_CurrentSpec] or {}
                        spec                                = SVSpecManager(self.__ScorpioSpecs[_CurrentSpec], self)
                        _DBSpecMap[self]                    = spec
                    end
                    return spec
                end
            }

            --- The specialization sv mananger
            __Indexer__(Number)
            property "Specs"    {
                get             = function(self, index)
                    local specs = self.__ScorpioSpecs
                    local spec  = specs and specs[index]
                    return spec and SVSpecManager(spec, self)
                end,
            }
        end

        local _RTDefault        = {}

        ----------------------------------------------
        --                  Method                  --
        ----------------------------------------------
        function GetData(self)
            local specs         = self.__ScorpioSpecs
            self.__ScorpioSpecs = nil

            local data          = super.GetData(self)

            self.__ScorpioSpecs = specs

            return data
        end

        __Arguments__{ Table }
        function SetData(self, data)
            local specs         = self.__ScorpioSpecs
            self.__ScorpioSpecs = nil

            super.SetData(self, data)

            self.__ScorpioSpecs = specs
        end

        --- Reset the character saved variable with default
        function Reset(self)
            local specs         = self.__ScorpioSpecs

            super.Reset(self)

            self.__ScorpioSpecs = specs
        end

        ----------------------------------------------
        --                Constructor               --
        ----------------------------------------------
        __Arguments__{ Table + NEString, SVProxy/nil }
        function __ctor(self, sv, root)
            if root then
                root            = _Root[root] or root
                _Root[self]     = root
                _RTDefault[root]= _RTDefault[root] or {}

                super(self, sv, _RTDefault[root])
            else
                super(self, sv)
            end
        end
    end)

    local _DBCharMap            = {}
    local yield                 = coroutine.yield

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    --- Get saved characters
    __Iterator__()
    function GetCharacters(self)
        local chars             = self.__ScorpioChars
        if chars then for name in pairs(chars) do yield(name) end end
    end

    function GetData(self)
        local chars             = self.__ScorpioChars
        self.__ScorpioChars     = nil

        local data              = super.GetData(self)

        self.__ScorpioChars     = chars

        return data
    end

    __Arguments__{ Table }
    function SetData(self, data)
        local chars             = self.__ScorpioChars
        self.__ScorpioChars     = nil

        super.SetData(self, data)

        self.__ScorpioChars     = chars
    end

    --- Reset the account saved variable with default
    function Reset(self)
        local chars             = self.__ScorpioChars

        super.Reset(self)

        self.__ScorpioChars     = chars
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The char's saved variable
    property "Char"             {
        get                     = function(self)
            local char          = _DBCharMap[self]
            if not char then
                local name      = GetRealmName() .. "-" .. UnitName("player")

                -- Char data should saved in the account data
                self.__ScorpioChars       = self.__ScorpioChars       or {}
                self.__ScorpioChars[name] = self.__ScorpioChars[name] or {}

                char            = SVCharManager(self.__ScorpioChars[name], self)
                _DBCharMap[self]= char
            end
            return char
        end,
    }

    --- The chars saved variable access
    __Indexer__(NEString)
    property "Chars"            {
        get                     = function(self, name)
            local chars         = self.__ScorpioChars
            local char          = chars and chars[name]
            return char and SVCharManager(char, self)
        end,
    }

    ----------------------------------------------
    --                Constructor               --
    ----------------------------------------------
    __Arguments__{ NEString, NEString/nil }
    function __ctor(self, sv, svchar)
        super(self, sv)

        if svchar then
            _DBCharMap[self]    = SVCharManager(svchar, self)
        end
    end
end)