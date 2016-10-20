--========================================================--
--                Scorpio Addon FrameWork                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/08/31                              --
--========================================================--

--========================================================--
Module            "Scorpio"                          "1.0.0"
--========================================================--

------------------------------------------------------------
--                Scorpio - Addon Class                   --
--                                                        --
-- Wrap the namespace to the addon module class, and also --
-- save it to the _G for quick access.                    --
--                                                        --
-- Usage :                                                --
------------------------------------------------------------

__Doc__[[The Scorpio Addon FrameWork]]
__Sealed__() __Final__() _G.Scorpio =
class (Scorpio) (function (_ENV)
    inherit "Module"
    extend "ISystemEvent" "IHook" "ISlashCommand" "ISavedVariableManager"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    -- Whether the player is already logined
    local _Logined   = false

    local _RootAddon = setmetatable({}, META_WEAKVAL)
    local _NotLoaded = setmetatable({}, META_WEAKKEY)
    local _DisabledModule = setmetatable({}, META_WEAKKEY)

    -- Event Handler
    local function OnEventOrHook(self, event, ...)
        if not _DisabledModule[self] and type(self[event]) == "function" then
            return self[event](self, ...)
        end
    end

    -- Special System Event Dispatcher
    local _EvtDispatcher = ISystemEvent()
    _EvtDispatcher:RegisterEvent("ADDON_LOADED")
    _EvtDispatcher:RegisterEvent("PLAYER_LOGIN")
    _EvtDispatcher:RegisterEvent("PLAYER_LOGOUT")

    local function Loading(self)
        if _NotLoaded[self] then
            _NotLoaded[self] = nil

            OnLoad(self)

            for _, mdl in self:GetModules() do Loading(mdl) end
        end
    end

    local function Enabling(self)
        if _NotLoaded[self] then Loading(self) end

        if not _DisabledModule[self] then
            OnEnable(self)

            for _, mdl in self:GetModules() do Enabling(mdl) end
        end
    end

    local function Disabling(self)
        if not _DisabledModule[self] then
            _DisabledModule[self] = true

            if _Logined then OnDisable(self) end

            for _, mdl in self:GetModules() do Disabling(mdl) end
        end
    end

    local function TryEnable(self)
        if _DisabledModule[self] and self._Enabled then
            if not self._Parent or (not _DisabledModule[self._Parent]) then
                _DisabledModule[self] = nil

                OnEnable(self)

                for _, mdl in self:GetModules() do
                    if mdl._Enabled then
                        Enabling(mdl)
                    end
                end
            end
        end
    end

    local function TryDisable(self)
    end

    local function Exiting(self)
        OnQuit(self)

        for _, mdl in self:GetModules() do Exiting(mdl) end
    end

    function _EvtDispatcher:OnEvent(event, name)
        if event == "ADDON_LOADED" then
            if _RootAddon[name] then
                Loading(_RootAddon[name])

                if _Logined then
                    Enabling(_RootAddon[name])
                end
            end
        elseif event == "PLAYER_LOGIN" then
            _Logined = true

            for _, addon in pairs(_RootAddon) do
                Enabling(addon)
            end
        elseif event == "PLAYER_LOGOUT" then
            for _, addon in pairs(_RootAddon) do
                Exiting(addon)
            end
        end
    end

    ----------------------------------------------
    ------------------- Event --------------------
    ----------------------------------------------
    __Doc__[[Fired when the addon(module) and it's saved variables is loaded]]
    __Delegate__(System.Threading.ThreadCall)
    event "OnLoad"

    __Doc__[[Fired when the addon(module) is enabled]]
    __Delegate__(System.Threading.ThreadCall)
    event "OnEnable"

    __Doc__[[Fired when the addon(module) is disabled]]
    __Delegate__(System.Threading.ThreadCall)
    event "OnDisable"

    __Doc__[[Fired when the player log out]]
    event "OnQuit"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Whether the module is enabled]]
    __Handler__(function(self, val) if val then return TryEnable(self) else return Disabling(self) end end)
    property "_Enabled" { Type = Boolean, Default = true }

    __Doc__[[Whether the module is disabled by itself or it's parent]]
    property "_Disabled" { Get = function (self) return _DisabledModule[self] end }

    __Doc__[[The addon of the module]]
    property "_Addon" { Get = function(self) while self._Parent do self = self._Parent end return self end }

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        _RootAddon[self._Name] = nil
        _NotLoaded[self] = nil
        _DisabledModule[self] = nil

        self.OnEvent = self.OnEvent - OnEventOrHook
        self.OnHook = self.OnHook - OnEventOrHook
    end

    ----------------------------------------------
    ----------------- Initializer ----------------
    ----------------------------------------------
    function IModule(self)
        if not self._Parent then
            -- Means this is an addon
            _RootAddon[self._Name] = self
            _NotLoaded[self] = true
        elseif _DisabledModule[self._Parent] then
            -- Register disabled modules
            _DisabledModule[self] = true
        end

        -- Default event & hook handler
        self.OnEvent = self.OnEvent + OnEventOrHook
        self.OnHook = self.OnHook + OnEventOrHook
    end
end)