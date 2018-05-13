--========================================================--
--                Scorpio MVC FrameWork                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2017/02/08                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.MVC"                   "1.0.0"
--========================================================--

namespace "Scorpio.MVC"

interface "IModel" {}
interface "IView"  {}

__Final__() __Sealed__()
class "Controller" (function(_ENV)

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    -- Recycle to reduce the costs
    RECYCLE_CACHE   = {}
    RECYCLE_MAX_CNT = 100

    local function refreshBinding(self, new, old)
        if old then old.Controllers:Remove(self) end
        if new then new.Controllers:Insert(self) end
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    --- The model of the binding
    property "Model" { Type = IModel, Handler = refreshBinding }

    --- The view of the binding
    property "View"  { Type = IView,  Handler = refreshBinding }

    ----------------------------------------------
    -------------------- Method ------------------
    ----------------------------------------------
    --- Refresh the view
    function RefreshView(self)
        local view = self.View
        if view then
            local ok, msg = pcall(IView.ForceRefresh, view)
            if not ok then pcall(geterrorhandler(), msg) end
        end
    end

    --- Get current datas, it may be translated by the controller's get algorithm
    function GetModelData(self)
        local model = self.Model

        if model then
            local getM = self.GetAlgorithm

            if getM then
                return getM(model:GetData())
            else
                return model:GetData()
            end
        end
    end

    --- Set the datas, it may be translated by the controller's set algorithm
    function SetModelData(self, ...)
        local model = self.Model

        if model then
            local setM = self.SetAlgorithm

            if setM then
                return model:SetData(setM(...))
            else
                return model:SetData(...)
            end
        end
    end

    --- Clear the bindings to the model and view
    function ClearBindings(self)
        self.Model        = nil
        self.View         = nil
        self.GetAlgorithm = nil
        self.SetAlgorithm = nil

        if #RECYCLE_CACHE < RECYCLE_MAX_CNT then
            tinsert(RECYCLE_CACHE, self)
        end
    end

    ----------------------------------------------
    ----------------- Constructor ----------------
    ----------------------------------------------
    __Arguments__{ IModel, IView, Variable.Optional(Callable), Variable.Optional(Callable) }
    function Controller(self, model, view, getAlgorithm, setAlgorithm)
        self.Model        = model
        self.View         = view
        self.GetAlgorithm = getAlgorithm
        self.SetAlgorithm = setAlgorithm
    end

    ----------------------------------------------
    ----------------- Meta-Method ----------------
    ----------------------------------------------
    __Arguments__{ IModel, IView, Variable.Optional(Callable), Variable.Optional(Callable) }
    function __exist(_, model, view, getAlgorithm, setAlgorithm)
        local self = tremove(RECYCLE_CACHE)
        if self then
            self.Model = model
            self.View = view
            self.GetAlgorithm = getAlgorithm
            self.SetAlgorithm = setAlgorithm
        end
        return self
    end
end)

__Sealed__()
interface "IModel" (function(_ENV)

    ----------------------------------------------
    ------------------- Property -----------------
    ----------------------------------------------
    --- The Controllers of the model
    property "Controllers" { Set = false, Default = function() return Array[Controller]() end }

    ----------------------------------------------
    -------------------- Method ------------------
    ----------------------------------------------
    --- Get current datas, overridable, required
    __Abstract__() function GetData(self) end

    --- Set the datas, overridable
    __Abstract__() function SetData(self, ...) end

    --- Trigger the controllers to update the views with new datas
    function RefreshViews(self)
        return self.Controllers:Each(Controller.RefreshView)
    end
end)

__Sealed__()
interface "IView" (function(_ENV)
    ----------------------------------------------
    -------------------- Helper ------------------
    ----------------------------------------------
    local function checkReturnAndRefresh(self, ...)
        if ... == nil then return end
        self:Refresh(...)
        return true
    end

    ----------------------------------------------
    ------------------- Property -----------------
    ----------------------------------------------
    --- The Controllers of the model
    property "Controllers" { Set = false, Default = function() return Array[Controller]() end }

    ----------------------------------------------
    -------------------- Method ------------------
    ----------------------------------------------
    --- Update the view with new datas, overridable, required
    __Abstract__() function Refresh(self, ...) end

    --- Force the view fetch the datas and refresh itself
    function ForceRefresh(self)
        for _, ct in ipairs(self.Controllers) do
            if checkReturnAndRefresh(self, ct:GetModelData()) then return end
        end
    end

    --- Trigger the controllers to update the models with new datas
    function SetModelData(self, ...)
        for _, ct in ipairs(self.Controllers) do
            ct:SetModelData(...)
        end
    end

    --- Clear bindings to the models
    function ClearBindings(self)
        if #self.Controllers > 0 then
            return self.Controllers:ToList():Each(Controllers.ClearBindings)
        end
    end

    __Arguments__{ IModel, Variable.Optional(Callable), Variable.Optional(Callable) }
    function Bind(self, model, getAlgorithm, setAlgorithm)
        Controller(model, self, getAlgorithm, setAlgorithm)
    end

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        return self:ClearBindings()
    end
end)

------------------------------------------------------------
--                     Default Model                      --
------------------------------------------------------------
--- The model used to provide default datas
__Sealed__()
class "Model" { IModel,
    -- Method
    GetData = unpack,

    -- Constructor
    function (self, ...)
        for i = 1, select('#', ...) do
            self[i] = select(i, ...)
        end
    end
}