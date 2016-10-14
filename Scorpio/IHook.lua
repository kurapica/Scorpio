--========================================================--
--                Scorpio.IHook                           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/09/09                              --
--========================================================--

--========================================================--
Module            "Scorpio.IHook"                    "1.0.0"
--========================================================--

__Doc__[[The hook & secure hook provider]]
__Sealed__() interface "IHook" (function(_ENV)

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local FireObjectEvent = System.Reflector.FireObjectEvent

	_HookDistribution = setmetatable({}, META_WEAKKEY)

	-- Normal Hook API
	local function doCommonHook(obj, target, targetFunc, handler)
		if type(target[targetFunc]) == "function" then
			if issecurevariable(target, targetFunc) then
				error(("'%s' is secure method, use SecureHook instead."):format(targetFunc), 3)
			end

			_HookDistribution[target] = _HookDistribution[target] or setmetatable({}, META_WEAKKEY)

			local cache = _HookDistribution[target][targetFunc]

			if not cache then
				_HookDistribution[target][targetFunc] = setmetatable({}, META_WEAKKEY)

				local _orig = target[targetFunc]

				cache = _HookDistribution[target][targetFunc]

				target[targetFunc] = function(...)
					for obj, func in pairs(cache) do
						FireObjectEvent(obj, "OnHook", func, ...)
					end

					return _orig(...)
				end
			end

			cache[obj] = handler
		else
			error(("No method named '%s' can be found."):format(targetFunc), 3)
		end
	end

	local function doCommonUnHook(obj, target, targetFunc)
		if _HookDistribution[target] and _HookDistribution[target][targetFunc] then
			_HookDistribution[target][targetFunc][obj] = nil
		end
	end

	local function doCommonUnHookAll(obj)
		for _, pool in pairs(_HookDistribution) do
			for _, store in pairs(pool) do
				store[obj] = nil
			end
		end
	end

	-- Secure Hook API
	_SecureHookDistribution = setmetatable({}, META_WEAKKEY)

	local function doSecureHook(obj, target, targetFunc, handler)
		if type(target[targetFunc]) == "function" then
			_SecureHookDistribution[target] = _SecureHookDistribution[target] or setmetatable({}, META_WEAKKEY)

			local cache = _SecureHookDistribution[target][targetFunc]

			if not cache then
				_SecureHookDistribution[target][targetFunc] = setmetatable({}, META_WEAKKEY)

				cache = _SecureHookDistribution[target][targetFunc]

				hooksecurefunc(target, targetFunc, function(...)
					for obj, func in pairs(cache) do
						FireObjectEvent(obj, "OnHook", func, ...)
					end
				end)
			end

			cache[obj] = handler
		else
			error(("No method named '%s' can be found."):format(targetFunc), 3)
		end
	end

	local function doSecureUnHook(obj, target, targetFunc)
		if _SecureHookDistribution[target] and _SecureHookDistribution[target][targetFunc] then
			_SecureHookDistribution[target][targetFunc][obj] = nil
		end
	end

	local function doSecureUnHookAll(obj)
		for _, pool in pairs(_SecureHookDistribution) do
			for _, store in pairs(pool) do
				store[obj] = nil
			end
		end
	end

    ----------------------------------------------
    ------------------- Event  -------------------
    ----------------------------------------------
	__Doc__[[
		<desc>Fired when the hooked function is called</desc>
		<param name="function" type="string">the hooked function name or registered name</param>
		<param name="...">arguments from the hooked function</param>
	]]
	event "OnHook"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
	__Doc__[[
		<desc>Hook a table's function</desc>
		<format>[target, ]targetFunction[, handler]</format>
		<param name="target" type="table">the target table, default _G</param>
		<param name="targetFunction" type="string">the hook function name</param>
		<param name="handler">string|function the hook handler, default the targetFunction</param>
	]]
	__Arguments__{ Table, String, Argument(String, true) }
	function Hook(self, target, targetFunc, handler)
		doCommonHook(self, target, targetFunc, handler or targetFunc)
	end

	__Arguments__{ String, Argument(String, true) }
	function Hook(self, targetFunc, handler)
		doCommonHook(self, _G, targetFunc, handler or targetFunc)
	end

	__Doc__[[
		<desc>Un-hook a table's function</desc>
		<format>[target, ]targetFunction</format>
		<param name="target" type="table">the target table, default _G</param>
		<param name="targetFunction" type="string">the hook function name</param>
	]]
	__Arguments__{ Table, String }
	function UnHook(self, target, targetFunc)
		doCommonUnHook(self, target, targetFunc)
	end

	__Arguments__{ String }
	function UnHook(self, targetFunc)
		doCommonUnHook(self, _G, targetFunc)
	end

	__Doc__[[Un-hook all functions]]
	function UnHookAll(self)
		doCommonUnHookAll(self)
	end

	__Doc__[[
		<desc>Secure hook a table's function</desc>
		<format>[target, ]targetFunction[, handler]</format>
		<param name="target" type="table">the target table, default _G</param>
		<param name="targetFunction" type="string">the hook function name</param>
		<param name="handler">string|function, the hook handler</param>
	]]
	__Arguments__{ Table, String, Argument(String, true) }
	function SecureHook(self, target, targetFunc, handler)
		doSecureHook(self, target, targetFunc, handler or targetFunc)
	end

	__Arguments__{ String, Argument(String, true) }
	function SecureHook(self, targetFunc, handler)
		doSecureHook(self, _G, targetFunc, handler or targetFunc)
	end

	__Doc__[[
		<desc>Un-hook a table's function</desc>
		<format>[target, ]targetFunction</format>
		<param name="target" type="table">the target table, default _G</param>
		<param name="targetFunction" type="string">the hook function name</param>
	]]
	__Arguments__{ Table, String }
	function SecureUnHook(self, target, targetFunc)
		doSecureUnHook(self, target, targetFunc)
	end

	__Arguments__{ String }
	function SecureUnHook(self, targetFunc)
		doSecureUnHook(self, _G, targetFunc)
	end

	__Doc__[[Un-hook all functions]]
	function SecureUnHookAll(self)
		doSecureUnHookAll(self)
	end

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        self:UnHookAll()
        self:SecureUnHookAll()
    end
end)