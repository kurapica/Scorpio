--========================================================--
--             Scorpio Layout Frame Widget                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/06/30                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Widget.LayoutFrame"          "1.0.0"
--========================================================--

--- The layout manager
__Sealed__() __AnonymousClass__()
interface "ILayoutManager" (function(_ENV)

	--- Acquire the location and size for the given UI element
	__Abstract__()
	function AcquireLayout(self, ui)
	end

	--- Inited the layout for all elements
	__Abstract__()
	function InitLayout(self)
	end
end)

--- The layout frame
__Sealed__()
class "LayoutFrame" (function(_ENV)
	inherit "Frame"

	local function OnStyleApplied(self, child, taskid)
		-- Wait for several cycle to avoid frequently refreshing
		for i = 1, 5 do
			if taskid ~= self.__RefreshTask then return end
			Next()
		end

		-- Refresh the layouts
		local manager 			= self.LayoutManager
		manager:InitLayout()
	end

	local function OnChildChanged(self, child, isAdd)
		if isAdd then
			child.OnStyleApplied= child.OnStyleApplied + self.OnChildStyleApplied
		else
			child.OnStyleApplied= child.OnStyleApplied - self.OnChildStyleApplied
		end
	end

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    function AddLayoutChild(self, child)
    end

    function RemoveLayoutChild(self, child)
    end

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The layout manager
    property "LayoutManager" 	{ type = ILayoutManager, default = function() return ILayoutManager() end }

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    function __ctor(self)
    	self.OnChildChanged 	= self.OnChildChanged + OnChildChanged
    	self.OnChildStyleApplied= function(child)
    		self.__RefreshTask  = (self.__RefreshTask or 0) + 1
    		return Next(OnStyleApplied, self, child, self.__RefreshTask)
    	end
    end
end)
