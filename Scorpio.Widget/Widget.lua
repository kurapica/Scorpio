--========================================================--
--             Scorpio Widget                             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/04                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget"                   "1.0.0"
--========================================================--

-----------------------------------------------------------
--                    System Prepare                     --
-----------------------------------------------------------
__Final__() __Sealed__() interface "Scorpio.Widget" {}
Environment.RegisterGlobalNamespace("Scorpio.Widget")

namespace "Scorpio.Widget"

--- Define a child property based on the target ui class
__Sealed__() class "__ChildProperty__" (function(_ENV)
    extend "IAttachAttribute"

    -----------------------------------------------------------
    --                       property                        --
    -----------------------------------------------------------
    property "AttributeTarget"  { set = false, default = AttributeTargets.Class }

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    --- attach data on the target
    -- @param   target                      the target
    -- @param   targettype                  the target type
    -- @param   owner                       the target's owner
    -- @param   name                        the target's name in the owner
    -- @param   stack                       the stack level
    -- @return  data                        the attribute data to be attached
    function AttachAttribute(self, target, targettype, owner, name, stack)
        UI.Property             {
            name                = self.Name or Namespace.GetNamespaceName(target, true),
            require             = self.Require,
            childtype           = target,
        }
    end

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ - UIObject/Frame, NEString/nil }
    function __ctor(self, reqframe, name)
        self.Require            = reqframe
        self.Name               = name
    end
end)