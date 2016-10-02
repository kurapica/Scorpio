--========================================================--
--                IFHook                                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/09/09                              --
--========================================================--

--========================================================--
Module                "Scorpio.IFHook"               "1.0.0"
--========================================================--

__Sealed__() interface "IFHook" (function(_ENV)

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local FireObjectEvent = System.Reflector.FireObjectEvent

	_HookManager = {}
	_HookDistribution = {}

	-- Normal Hook API

	function _HookManager:Hook(obj, target, targetFunc, handler)
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

				cache[0] = function(...)
					for obj, func in pairs(cache) do
						if obj ~= 0 then
							if func == true then
								FireObjectEvent(obj, "OnHook", targetFunc, ...)
							elseif type(func) == "function" then
								local chk, ret = pcall(func, self, ...)
								if not chk then errorhandler(ret) end
							else
								func = obj[func]
								if type(func) == "function" then
									local chk, ret = pcall(func, self, ...)
									if not chk then errorhandler(ret) end
								end
							end
						end
					end

					return _orig(...)
				end

				target[targetFunc] = cache[0]
			end

			cache[obj] = (type(handler) == "function" or type(handler) == "string") and handler or true
		else
			error(("No method named '%s' can be found."):format(targetFunc), 3)
		end
	end

	function _HookManager:UnHook(obj, target, targetFunc)
		if _HookDistribution[target] then
			if type(targetFunc) == "string" then
				if _HookDistribution[target][targetFunc] then
					_HookDistribution[target][targetFunc][obj] = nil
				end
			elseif targetFunc == nil then
				for _, store in pairs(_HookDistribution[target]) do
					store[obj] = nil
				end
			end
		end
	end

	function _HookManager:UnHookAll(obj)
		for _, pool in pairs(_HookDistribution) do
			for _, store in pairs(pool) do
				store[obj] = nil
			end
		end
	end

	-- Secure Hook API
	_SecureHookDistribution = {}

	function _HookManager:SecureHook(obj, target, targetFunc, handler)
		if type(target[targetFunc]) == "function" or (_SecureHookDistribution[target] and _SecureHookDistribution[target][targetFunc]) then
			_SecureHookDistribution[target] = _SecureHookDistribution[target] or {}

			local _store = _SecureHookDistribution[target][targetFunc]

			if not _store then
				_SecureHookDistribution[target][targetFunc] = setmetatable({}, _MetaWK)

				_store = _SecureHookDistribution[target][targetFunc]

				_SecureHookDistribution[target][targetFunc][0] = function(...)
					for mdl, func in pairs(_store) do
						if mdl ~= 0 and not _Addon_Disabled[mdl] then
							if func == true then
								Object.Fire(mdl, "OnHook", targetFunc, ...)
							else
								Object.Fire(mdl, "OnHook", func, ...)
							end
						end
					end
				end

				hooksecurefunc(target, targetFunc, _SecureHookDistribution[target][targetFunc][0])
			end

			_store[obj] = (type(handler) == "function" or type(handler) == "string") and handler or true
		else
			error(("No method named '%s' can be found."):format(targetFunc), 3)
		end
	end

	function _HookManager:SecureUnHook(obj, target, targetFunc)
		if _SecureHookDistribution[target] then
			if type(targetFunc) == "string" then
				if _SecureHookDistribution[target][targetFunc] then
					_SecureHookDistribution[target][targetFunc][obj] = nil
				end
			elseif targetFunc == nil then
				for _, store in pairs(_SecureHookDistribution[target]) do
					store[obj] = nil
				end
			end
		end
	end

	function _HookManager:SecureUnHookAll(obj)
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
		<param name="function">the hooked function name</param>
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
		<param name="handler">string|function the hook handler</param>
	]]
	__Arguments__{ Table, String, Argument(String + Function, true) }
	function Hook(self, target, targetFunc, handler) _HookManager:Hook(self, target, targetFunc, handler) end

	__Arguments__{ String, Argument(String + Function, true) }
	function Hook(self, targetFunc, handler) _HookManager:Hook(self, _G, targetFunc, handler) end

	__Doc__[[
		<desc>Un-hook a table's function</desc>
		<format>[target, ]targetFunction</format>
		<param name="target" type="table">the target table, default _G</param>
		<param name="targetFunction" type="string">the hook function name</param>
	]]
	__Arguments__{ Table, String }
	function UnHook(self, target, targetFunc) _HookManager:UnHook(self, target, targetFunc) end

	__Arguments__{ String }
	function UnHook(self, targetFunc) _HookManager:UnHook(self, _G, targetFunc) end

	__Doc__[[Un-hook all functions]]
	function UnHookAll(self) _HookManager:UnHookAll(self) end

	__Doc__[[
		<desc>Secure hook a table's function</desc>
		<format>[target, ]targetFunction[, handler]</format>
		<param name="target" type="table">the target table, default _G</param>
		<param name="targetFunction" type="string">the hook function name</param>
		<param name="handler">string|function, the hook handler</param>
	]]
	__Arguments__{ Table, String, Argument(String + Function, true) }
	function SecureHook(self, target, targetFunc, handler) _HookManager:SecureHook(self, target, targetFunc, handler) end

	__Arguments__{ String, Argument(String + Function, true) }
	function SecureHook(self, targetFunc, handler) _HookManager:SecureHook(self, _G, targetFunc, handler) end

	__Doc__[[
		<desc>Un-hook a table's function</desc>
		<format>[target, ]targetFunction</format>
		<param name="target" type="table">the target table, default _G</param>
		<param name="targetFunction" type="string">the hook function name</param>
	]]
	__Arguments__{ Table, String }
	function SecureUnHook(self, target, targetFunc) _HookManager:SecureUnHook(self, target, targetFunc) end

	__Arguments__{ String }
	function SecureUnHook(self, targetFunc) _HookManager:SecureUnHook(self, _G, targetFunc) end

	__Doc__[[Un-hook all functions]]
	function SecureUnHookAll(self) _HookManager:SecureUnHookAll(self) end
end)