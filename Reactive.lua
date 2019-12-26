--========================================================--
--                Scorpio Reactive Extension              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/12/03                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Reactive"                     ""
--========================================================--

import "System.Reactive"

__Async__() function processInterval(observer, interval, max)
	local i 					= 0
	max 						= max or math.huge

	while not observer.IsUnsubscribed and i <= max do
		observer:OnNext(i)
		Delay(interval)
		i 						= i + 1
	end
end

__Async__() function processTimer(observer, delay)
	Delay(delay)

	if observer.IsUnsubscribed then return end
	observer:OnNext(0)
	if observer.IsUnsubscribed then return end
	observer:OnCompleted()
end

__Async__() function delayResume(observer, delay, ...)
	Delay(delay)
	if observer.IsUnsubscribed then return end
	observer:OnNext(...)
end

__Async__() function delayFin(observer, delay)
	Delay(delay)
	if observer.IsUnsubscribed then return end
	observer:OnCompleted()
end

--- Create an Observable that emits a sequence of integers spaced by a given time interval
__Static__() __Arguments__{ Number, Number/nil }
function Observable.Interval(interval, max)
    return Observable(function(observer) return processInterval(observer, interval, max) end)
end

--- Creates an Observable that emits a particular item after a given delay
__Static__() __Arguments__{ Number }
function Observable.Timer(delay)
    return Observable(function(observer) return processTimer(observer, delay) end)
end

--- The Delay extension method is a purely a way to time-shift an entire sequence
__Arguments__{ Number }
function IObservable:Delay(delay)
	return Operator(self, function(observer, ...)
		return delayResume(observer, delay, ...)
	end, function(observer)
		return delayFin(observer, delay)
	end
end

--- The Timeout extension method allows us terminate the sequence with an error if
-- we do not receive any notifications for a given period
__Arguments__{ Number }
function IObservable:Timeout(dueTime)
	return Observable(function(observer)
		local timer 			= Observable.Timer(dueTime):Subscribe(function() observer:OnError("The operation is time out") end)

		self:Subscribe(function(...)
			timer:Unsubscribe()
			observer:OnNext(...)
		end, function()
			observer:OnCompleted()
		end, function(ex)
			observer:OnError(ex)
		end)
	end)
end