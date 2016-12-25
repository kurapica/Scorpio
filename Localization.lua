--========================================================--
--                Scorpio Localization                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/23                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Localization"            "1.0.0"
--========================================================--

------------------------------------------------------------
--                        Locale                          --
------------------------------------------------------------
enum "Locale" {
    "deDE",             -- German
    enGB = "enUS",      -- British English
    "enUS",             -- American English
    "esES",             -- Spanish (European)
    "esMX",             -- Spanish (Latin American)
    "frFR",             -- French
    "koKR",             -- Korean
    "ruRU",             -- Russian
    "zhCN",             -- Chinese (simplified; mainland China)
    "zhTW",             -- Chinese (traditional; Taiwan)
}

------------------------------------------------------------
--                        Locale                          --
------------------------------------------------------------
class "Localization" (function(_ENV)
    _Localizations = {}

    ----------------------------------------------
    ----------------- Constructor ----------------
    ----------------------------------------------
    __Arguments__( NEString )
    function Localization(self, name)
        _Localizations[name] = self
    end

    ----------------------------------------------
    ----------------- Meta-Method ----------------
    ----------------------------------------------
    __Arguments__{ NEString }
    function __exist(name)
        return _Localizations[name]
    end

    __Arguments__{ String }
    function __index(self, key)
        rawset(self, key, key)
        return key
    end

    __Arguments__{ NEString + Number, NEString }
    function __newindex(self, key, value)
        rawset(self, key, value)
    end

    __Arguments__{ NEString, RawBoolean }
    function __newindex(self, key, value)
        rawset(self, key, key)
    end

    function __call(self, key)
        return self[key]
    end
end)

------------------------------------------------------------
--                   Scorpio.GetLocale                    --
------------------------------------------------------------
__Static__() __Arguments__ {
    Argument(NEString, false, nil, "addonName"),
    Argument(Locale, false, nil, "language"),
    Argument(Boolean, true, false, "asDefault"),
}
function Scorpio.GetLocale(addonName, language, asDefault)
    if not asDefault then
        local locale = GetLocale()
        if locale == "enGB" then locale = "enUS" end
        if locale ~= language then return end
    end
    return Localization(addonName)
end