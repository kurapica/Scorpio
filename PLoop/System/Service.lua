--===========================================================================--
--                                                                           --
--                      Service & Dependency Injection                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2022/02/20                                               --
-- Update Date  :   2022/02/20                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    __Sealed__()
    interface "System.IServiceProvider" (function(_ENV)
        --- Gets the service object of the specified type
        __Abstract__() __Arguments__{ AnyType }:AsInheritable()
        function GetService(self, type)
        end
    end)
end)