--========================================================--
--                Scorpio Addon FrameWork                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/08/31                              --
--========================================================--

--========================================================--
Module                   "Scorpio"                   "1.0.0"
--========================================================--

namespace "Scorpio"

__Doc__[[The Scorpio Addon FrameWork]]
__Sealed__() __Final__() __Abstract__()
_G.Scorpio = class (Scorpio) {}

------------------------------------------------------------
--                       Useful  types                    --
------------------------------------------------------------
__Base__(Number)
struct "PositiveNumber" { function(val) assert(val > 0, "%s must be greater than zero.") end }

__Base__(Number)
struct "NegtiveNumber" { function(val) assert(val < 0, "%s must be less than zero.") end }

__Base__(Number)
struct "Integer" { function(val) assert(floor(val) == val, "%s must be an integer.") end }

__Base__(Integer)
struct "PositiveInteger" { function(val) assert(val > 0, "%s must be greater than zero.") end }

__Base__(Integer)
struct "NegtiveInteger" { function(val) assert(val < 0, "%s must be less than zero.") end }
