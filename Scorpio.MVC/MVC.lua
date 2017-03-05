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

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The model of the binding]]
    property "Model"        { Type = IModel }

    __Doc__[[The view of the binding]]
    property "View"         { Type = IView }

    __Doc__[[The algorithm used to translate the model datas to view datas]]
    property "GetAlgorithm" { Type = Callable }

    __Doc__[[The algorithm used to translate the view datas to model datas]]
    property "SetAlgorithm" { Type = Callable }

    ----------------------------------------------
    -------------------- Method ------------------
    ----------------------------------------------
    __Doc__[[Refresh the view]]
    function RefreshView(self)
        local view = self.View
        return view:ForceRefresh()
    end

    __Doc__[[Get current datas, it may be translated by the controller's get algorithm]]
    function GetModelData(self)
        if self.GetAlgorithm then
            return self.GetAlgorithm(self.Model:GetData())
        else
            return self.Model:GetData()
        end
    end

    __Doc__[[Set the datas, it may be translated by the controller's set algorithm]]
    function SetModelData(self, ...)
        if self.SetAlgorithm then
            return self.Model:SetData(self.SetAlgorithm(...))
        else
            return self.Model:SetData(...)
        end
    end

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        if self.Model then
            self.Model.Controllers:Remove(self)
        end
        if self.View then
            self.View.Controllers:Remove(self)
        end
        if #RECYCLE_CACHE < RECYCLE_MAX_CNT then
            tinsert(RECYCLE_CACHE, self)
        end
    end

    ----------------------------------------------
    ----------------- Constructor ----------------
    ----------------------------------------------
    __Arguments__{ IModel, IView, { Type = Callable, Nilable = true }, { Type = Callable, Nilable = true } }
    function Controller(self, model, view, getAlgorithm, setAlgorithm)
        self.Model = model
        self.View = view
        self.GetAlgorithm = getAlgorithm
        self.SetAlgorithm = setAlgorithm

        model.Controllers:Insert(self)
        view.Controllers:Insert(self)
    end

    ----------------------------------------------
    ----------------- Meta-Method ----------------
    ----------------------------------------------
    __Arguments__{ IModel, IView, { Type = Callable, Nilable = true }, { Type = Callable, Nilable = true } }
    function __exist(model, view, getAlgorithm, setAlgorithm)
        local self = tremove(RECYCLE_CACHE)
        if self then
            self.Disposed = nil
            self.Model = model
            self.View = view
            self.GetAlgorithm = getAlgorithm
            self.SetAlgorithm = setAlgorithm

            model.Controllers:Insert(self)
            view.Controllers:Insert(self)
        end
        return self
    end
end)

__Sealed__()
interface "IModel" (function(_ENV)

    ----------------------------------------------
    ------------------- Property -----------------
    ----------------------------------------------
    __Doc__[[The Controllers of the model]]
    property "Controllers" { Set = false, Default = function() return List() end }

    ----------------------------------------------
    -------------------- Method ------------------
    ----------------------------------------------
    __Doc__[[Get current datas, overridable, required]]
    __Require__()
    function GetData(self) end

    __Doc__[[Set the datas, overridable]]
    function SetData(self, ...) end

    __Doc__[[Trigger the controllers to update the views with new datas]]
    function RefreshViews(self)
        for _, ct in self.Controllers:GetIterator() do
            local view = ct.View
            if view then view:ForceRefresh() end
        end
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
    __Doc__[[The Controllers of the model]]
    property "Controllers" { Set = false, Default = function() return List() end }

    ----------------------------------------------
    -------------------- Method ------------------
    ----------------------------------------------
    __Doc__[[Update the view with new datas, overridable, required]]
    __Require__()
    function Refresh(self, ...) end

    __Doc__[[Force the view fetch the datas and refresh itself]]
    function ForceRefresh(self)
        for _, ct in self.Controllers:GetIterator() do
            if checkReturnAndRefresh(self, ct:GetModelData()) then return end
        end
    end

    __Doc__[[Trigger the controllers to update the models with new datas]]
    function SetModelData(self, ...)
        for _, ct in self.Controllers:GetIterator() do
            ct:SetModelData(...)
        end
    end

    function ClearBindings(self)
        return self.Controllers:ToList():Each("x=>x:Dispose()")
    end

    __Arguments__{ IModel, { Type = Callable, Nilable = true}, { Type = Callable, Nilable = true} }
    function Bind(self, model, getAlgorithm, setAlgorithm)
        return Controller(model, self, getAlgorithm, setAlgorithm)
    end
end)

------------------------------------------------------------
--                     Default Model                      --
------------------------------------------------------------
__Doc__[[The model used to provide default datas]]
__Sealed__()
class "DefaultModel" { IModel,
    -- Method
    GetData = unpack,

    -- Constructor
    function (self, ...)
        for i = 1, select('#', ...) do
            self[i] = select(i, ...)
        end
    end
}