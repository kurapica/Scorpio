When I make the [IGAS](https://www.curseforge.com/projects/21074/) library, I faced a problem: The whole system is based on an object-oriented program system [PLoop](https://wow.curseforge.com/projects/ploop), the more powerful I make it, the more classes and other features added, it makes it too difficult to be used by others. Since I can't roll back, I choose to go deep.

In the **Scorpio** project, the main purpose is creating a complex designed but easy-using platform for addon development.


### I. None-UI part ###

You can first download a test addon [ScorpioTest](https://github.com/kurapica/Scorpio/releases/download/a1.0/ScorpioTest.zip), it would show many details for the framework's none-ui part.

## Starting you project ##

1. Give your addon a name, I choose **ScorpioTest** as an example, create a folder named ScorpioTest under **World of Warcraft\Interface\Addons**.

2. Create a file **ScorpioTest.toc** under the folder, input some text in it like (you can find more details about it in [TOC_format](http://wowwiki.wikia.com/wiki/TOC_format), you should learn it first)

        ## Interface: 70000
        ## Title: Scorpio Test Addon
        ## Dependencies: Scorpio
        ## DefaultState: Enabled
        ## LoadOnDemand: 0
        ## SavedVariables: ScorpioTest_DB
        ## SavedVariablesPerCharacter: ScorpioTest_DB_Char

        # localization files
        Locale\enUS.lua
        Locale\zhCN.lua

        # main files
        ScorpioTest.lua
        ScorpioTestMdl.lua


3. Create a file **ScorpioTest.lua** under the folder too, it's our addon's main file, open it with a notepad or anything for text edit(my favor is sublime text).

---------------------------------------

## Init the main file ##

Normally to say, you can use the **Scorpio** as a common library, use its api like **Scorpio.Delay** directly, but it also provide a special code style that I strongly suggest to use. (The normal style will be introduced in other pages.)

The first line of the code file should be like :

    Scorpio "ScorpioTest" "1.0.0"

Then create the file **ScorpioTestMdl.lua**, and its first line should be like

    Scorpio "ScorpioTest.Mdl" "1.0.0"

So the code pattern should be

    Scorpio "AddonName[.ModuleName[.SubModuleName...]]" "[version]"

Here are the rules of the **Scorpio File-Module System** :

* All files with ".lua" suffix in an **Scorpio** addon are considered as module files.

* Each module file is a standalone module of operational codes.

* A module can have and only have one parent module, a module can have many child modules.

* The root module(the parent module of all others in the addon) are called the addon module.

* The child module can read all global features defined in it's parent module, the addon module can read all global features that defined in the `_G`. Those modules would cache the result so it won't search them again and for quick using.

* Writing a global variable will only save it in the module itself, so a child-module's global variable won't affect its parent module, so the `_G`. Normally to say, it's all the same like you write a common addon except you don't need take care the global variables that would taint the `_G`, and you can share your global features among your module files.

* `Scorpio "ScorpioTest"` means creating an module named **ScorpioTest**, it has no parent module, so it's the addons's root module.

* `Scorpio "ScorpioTest.Mdl"` means creating an module named **Mdl**, it's parent module is the **ScorpioTest**.

* The last string `"1.0.0"` means a version token. It's combined by any string with a serials of numbers, so you also can write it like `"r 1.0.12.1"`, also empty string can be used here. The version string is needed, you can use `Scorpio "ScorpioTest" ""`, but `Scorpio "ScorpioTest"` will cause code error.

* Each lua file should have a different module, if two files use the same module, the version will be used to check, error would be raised if failed, I don't want provide an embed library system, so if you use it, just keep in mind, give each file a different module.

* `Scorpio "ScorpioTest.Mdl"` will create a module, `Scorpio "ScorpioTest" "1.0.0"` means creating the module, then change the file's execution environment to the module itself, and after it, we can use some special features, we'll see it later.

* Also you can create a module like

        Scorpio "ScorpioTest.Mdl.SubMdl.SSubMdl.SSSubMdl" "1.0.0"

    There is no limit for it.

---------------------------------------

## System Event Handler ##

The wow will notify us about what happened in the game world by system events. Like `UNIT_SPELLCAST_START` tell us an unit is casting a spell, it also give us several arguments to tell who cast it and which spell it is. You can find a full list in [Events List](http://wowwiki.wikia.com/wiki/Events_A-Z_(Full_List)).

The **Scorpio** module can use **RegisterEvent** API to register and handle the system events, but I'll show the common way in another page, here we'll see a simple way to do it, take the `UNIT_SPELLCAST_START` and `UNIT_SPELLCAST_CHANNEL_START` as the examples.

We can handle each system events like:

    __SystemEvent__()
    function UNIT_SPELLCAST_START(unit, spell)
        print(unit .. " cast " .. spell)
    end

    __SystemEvent__()
    function UNIT_SPELLCAST_CHANNEL_START(unit, spell)
        print(unit .. " cast " .. spell)
    end

The `__SystemEvent__` is an attribute class.  `__SystemEvent__()` means creating an **Attribute**.

The attributes are used to bind information or do some background operations for features.

Here `__SystemEvent__()` is used to mark the next defined global function(in the module) as a system event handler, the system event's name is given by the function's name. So when an unit(like player self) casting a spell(not instant spell), the function would be called and event arguments would be passed in. You may test it by yourselves.

Since the code we handle the `UNIT_SPELLCAST_START` and `UNIT_SPELLCAST_CHANNEL_START` is the same, we can combine it like

    __SystemEvent__ "UNIT_SPELLCAST_START" "UNIT_SPELLCAST_CHANNEL_START"
    function UNIT_SPELLCAST(unit, spell)
        print(unit .. " cast " .. spell)
    end

Then, the two system events would use the same handler.

---------------------------------------

## Hook & SecureHook ##

A big part in addon development is modifying the wow's original ui. To do it, we need use **Hook**. There was two ways for it : un-secure and secure hook.

1. When you need replace some functions you could use un-secure hook. Normally you can only replaced function defined by the 3rd addons. Suppose we have some code defined in the _G like

        TestLib = {}
        function TestLib.DoJob()
            print("TestLib DoJob")
        end

        function TestFunc()
            print("TestFunc")
        end

    So we have a global function *TestFunc* and a in table function *TestLib.DoJob*, now let's hook them

        __Hook__()
        function TestFunc()
            print("Hook TestFunc")
        end

    Since we don't provide the *target table* and the *target function's name*, the target table should be _G, and the target function would be the same name. Now if anyone call the TestFunc, it's result would be

        Hook TestFunc
        TestFunc

    So our hooked function would be called first, then the original function.

    There is a problem, if you need call the TestFunc also in the module, We don't know which one should be used, so we need hook it with a different name like

        __Hook__ "TestFunc"
        function HookTestFunc()
            print("Hook TestFunc")
        end

    Like the `__SysteEvent__`, we can provide the target function's name with the attribute.

    For the TestLib.DoJob, we need also provide the target table like :

        __Hook__(TestLib, "DoJob")
        function Hook_DoJob(...)
            print("Hook_DoJob")
        end

    Or

        __Hook__(TestLib)
        function DoJob(...)
            print("Hook_DoJob")
        end


2. Since the un-secure hook can't handle the blz's code, it's normally useless, so we should focus on how to secure hook system's api.

    When you hook the system function, your hook function would be called after the system function.

    Take **ChatEdit_OnEditFocusGained** as an example, it's fired when you press enter and the chat frame's input edit box is shown.

        __SecureHook__()
        function ChatEdit_OnEditFocusGained(self)
            print("Start input text")
        end

    Like the `__Hook__`, also you can do it as

        __SecureHook__ "ChatEdit_OnEditFocusGained"
        function Hook_ChatEdit_OnEditFocusGained(self)
            print("Start input text")
        end

    If we try to hook AuctionFrameTab_OnClick, since it's defined in addon Blizzard_AuctionUI, we can't hook it before the addon is loaded, but it can be simply done with a new attribute :

        __AddonSecureHook__ "Blizzard_AuctionUI"
        function AuctionFrameTab_OnClick(self, button, down, index)
            print("Click " .. self:GetName() .. " Auction tab")
        end

    Or

        __AddonSecureHook__ ("Blizzard_AuctionUI", "AuctionFrameTab_OnClick")
        function Hook_AuctionFrameTab_OnClick(self, button, down, index)
            print("Click " .. self:GetName() .. " Auction tab")
        end

    It would make the system secure hook the target function until the **Blizzard_AuctionUI** is loaded. You can open the auction frame and toggle the tabpage to see the result.

    To modify the original code, you need be familiar with them first, you may find the sources in [wow-ui-source](https://github.com/tekkub/wow-ui-source). You can use `/fstack` command to know which frame you want modify and then search them in the source.

---------------------------------------

## Slash Commands ##

There are two ways that the user used to contact with the ui, the main part is through ui elements(it'd would come at a later time), another way is use slash commands, it is frequently used in the early time, but for now you can still use it in some conditions.

Take some commands like

    /cmd
    /cmd enable
    /cmd log 3

Normally the slash commands match the pattern like

    /cmd [option] [info]

Here is some examples

    -- /sct(scptest) enable     -- enable the module
    __SlashCmd__ "scptest" "enable"
    __SlashCmd__ "sct" "enable"
    function EnableModule(info)
        -- _Enabled is a property of the module, we can directly set it since the environment is the module
        -- when the module is disabled, its(and it's child-modules') system event and hook handlers won't be triggered.
        _Enabled = true
    end

    -- /sct(scptest) disable    -- disable the module
    __SlashCmd__ "scptest" "disable"
    __SlashCmd__ "sct" "disable"
    function DisableModule(info)
        _Enabled = false
    end

The two slash commands is follow the `/cmd option` pattern, the command and option are all case ignored, each hander match two commands `/sct` and `/scptest`.

For the pattern `/cmd`, normally used to show the command list like

    __SlashCmd__ "scptest"
    __SlashCmd__ "sct"
    function Help()
        print("/sct(scptest) enable   -- enable the addon")
        print("/sct(scptest) disable  -- disable the addon")
    end

From v006, you can only define the slash commands follow the `/cmd option[ info]` patterns with a decription, the system will provide a default slash commdn handler for `/cmd` used to generate the command list :

    Scorpio "ScorpioTest" ""

    __SlashCmd__ "sct" "enable" "- enable the module"
    function enableModule()
    end

    __SlashCmd__ "sct" "disable" "- disable the module"
    function disableModule()
    end

So when you enter the `/sct` command, the list will be displayed :

    --======================--
    /sct enable - enable the module
    /sct disable - disable the module
    --======================--

If you need use localization for the description, you can do it like :

    __SlashCmd__("sct", "enable", L["- enable the module"])
    function enableModule()
    end

---------------------------------------

## The module property ##

The module have several property that can be accessed like global variables:

Name       |Description
-----------|-----------
_M         |The module itself.
_Name      |The name of the module.
_Parent    |The parent module of the module.
_Version   |The module's version.
_Enabled   |Whether the module's enabled.
_Disabled  |Readonly, whether the module is disabled(the sub-module would be disabled if its parent module is disabled)
_Addon     |The root module of the addon
_Locale    |The localization manager

---------------------------------------

## The module event ##

Besides the OnLoad event, the addon module also provide some other event to help you manage it(*self* means the module itself) :

Event               |Description
--------------------|--------------------
OnLoad(self)        |Fired when the addon is loaded, the sub-module's OnLoad will be fired after it's parent.
OnSpecChanged(self) |Fired when the player changed specialization
OnEnable(self)      |Fired when the module is enabled and the player login into the game, or the module is re-enabled.
OnDisable(self)     |Fired when the module is disabled.
OnQuit(self)        |Fired when the player log out.

Here is an example for all those :

* ScorpioTest.lua

        Scorpio "ScorpioTest" "1.0.0"

        function OnLoad(self)
            -- SavedVariables Manager, explained later
            _SVDB = SVManager("ScorpioTest_DB", "ScorpioTest_DB_Char")

            _SVDB:SetDefault{ Enable = true }

            if _SVDB.Char.LastPlayed then
                print("The character is last played at " .. _SVDB.Char.LastPlayed)
            end

            _Enabled = _SVDB.Enable
        end

        function OnEnable(self)
            _SVDB.Enable = true
        end

        function OnDisable(self)
            _SVDB.Enable = false
        end

        function OnQuit(self)
            -- Save the last played time for the character
            _SVDB.Char.LastPlayed = date("%c")
        end

        __SlashCmd__ "sct" "enable"
        function EnableModule()
            _Enabled = true
        end

        __SlashCmd__ "sct" "disable"
        function DisableModule()
            _Enabled = false
        end

* ScorpioTestMdl.lua

        Scorpio "ScorpioTest.Mdl" "1.0.0"

        function OnLoad(self)
            _SVDB.Char:SetDefault{ MdlKey = true }
        end

        function OnEnable(self)
            print("Sub module is enabled")
        end

        function OnDisable(self)
            print("Sub module is disabled")
        end

The sub-module can have their own system event handler, hook handler, slash command handler and module event handlers. The only different is the sub-module can access the parent-module's global features directly, and the parent-module can enable/disable their sub-module's state with its.

---------------------------------------

## Saved Variables ##

**Saved Variables** are datas saved between the game sessions, normally used to save the addons' configuration.

Normally, the author could handle the saved variables by themselves, but the **Scorpio** also provide a **SVManager** to easy the life.

The **ScorpioTest** addon has two saved variables : *ScorpioTest_DB* for account, *ScorpioTest_DB_Char* for character.

The saved variables'll be loaded when the addon is already loaded, so we can't handle it directly, the addon module provide a **OnLoad** event(not system event), we need handle the saved variables in **OnLoad** event

    function OnLoad(self)
        _SVDB = SVManager("ScorpioTest_DB", "ScorpioTest_DB_Char")
    end

The **SVManager** can accept two arguments, the first is the account saved variable's name, it's **required**, the next is the character saved variable's name, it's **optional**, when the addon has no saved variables for character, the **SVMananger** would use the account saved variable to handle the character's, so you don't need to care the details of it.

After the _SVDB is defined, we can use it to access or write datas like

* Account Data :
    * _SVDB.Key = value
    * value = _SVDB.Key

* Character Data :
    * _SVDB.Char.Key = value
    * value = _SVDB.Char.Key

* Character-Specialization Data(The system would handle the specialization's changing) :
    * _SVDB.Char.Spec.Key = value
    * value = _SVDB.Char.Spec.Key

Besides the access, the other part for saved variable is given them default settings, since the real job is combine the saved variable with the default settings, so you can do it in multi-times and any time.

* Account Default :
    * _SVDB:SetDefault{ key1 = value1, key2 = value2 }
    * _SVDB:SetDefault( key, value )

* Character Default :
    * _SVDB.Char:SetDefault{ key1 = value1, key2 = value2 }
    * _SVDB.Char:SetDefault( key, value )

* Character-Specialization Default :
    * _SVDB.Char.Spec:SetDefault{ key1 = value1, key2 = value2 }
    * _SVDB.Char.Spec:SetDefault( key, value )

BTW. the values can also be tables, and only table, boolean, number, string value will be accepted. If the value is a function, it'll be used as a value factory.

If you decided reset the saved variables, you also can do it like :

* Account Reset :
    * _SVDB:Reset() -- Reset the account data with default, won't affect character data.

* Character Reset :
    * _SVDB.Char:Reset() -- Reset the character data with default, won't affect specialization data.

* Character-Specialization Reset :
    * _SVDB.Char.Spec:Reset() -- Reset current specialization data with default.
    * _SVDB.Char.Spec:ResetAll() -- Reset all specialization data with default.

You should handle the addon updating by yourselves after the data reseted.

---------------------------------------

## The Localization ##

There are two localization files defined in the **ScorpioTest.toc**.

    # localization files
    Locale\enUS.lua
    Locale\zhCN.lua

Since the localization system is very simple, let's see it in examples.

* Locale\enUS.lua

        Scorpio "ScorpioTest.Localization.enUS" "1.0.0"

        -- _Locale(language, asDefault)
        -- language -- The language token you can get from GetLocale() API
        -- asDefault -- Whether the language is the default, normally only true with "enUS"
        local L = _Locale("enUS", true)

        -- If the language don't match the client and is not the default language, L will be nil.
        if not L then return end

        L["A test message"] = true
        L[1] = "Another test message"

* Locale\zhCN.lua

        Scorpio "ScorpioTest.Localization.zhCN" "1.0.0"

        local L = _Locale("zhCN")

        if not L then return end

        L["A test message"] = "一条测试用消息"
        L[1] = "另一条测试用消息"

* **Usage** - ScorpioTest.lua

        Scorpio "ScorpioTest" "1.0.0"

        -- You can assign it to a new variable for easy using
        L = _Locale

        function OnLoad(self)
            print(_Locale["A test message"])
            print(_Locale[1])

            print(L["A test message"])
        end

---------------------------------------

## Some Other Attribtues ##

In the previous examples, we have see attributes like `__SystemEvent__`, `__SecureHook__`. The **Scorpio** & **PLoop** also provided many useful attributes, here I'll show three useful attributes that you may using.

* `__NoCombat__`  -- Mark the global function(also the module event handler like OnLoad) defined in a Scorpio module, so it'll be real called when out of combat.

        Scorpio "ScorpioTest" "1.0.0"

        __NoCombat__() __SystemEvent__()
        function GROUP_ROSTER_UPDATE()
            -- Update panel like grids
        end

    The `GROUP_ROSTER_UPDATE` system event means the raid|party group is changed, so we may need to update the panel, but we can't do it during the combat, so give it `__NoCombat__` attribute will make sure it'll only be real called out of combat. (It's just an example, in the real addon, we can handle it by using secure templates).

    We also can do it like

        Scorpio "ScorpioTest" "1.0.0"

        __NoCombat__()
        function UpdatePanel()
            -- Update panel like grids
        end

        __SystemEvent__()
        function GROUP_ROSTER_UPDATE()
            UpdatePanel()
        end

    You can apply those attribute on any global functions.


* `__Async__`  -- Mark the global function defined in a Scorpio module, so it would be called as a thread.

        Scorpio "ScorpioTest" "1.0.0"

        -- /sct cd 10               -- count down from 10 to 1 per sec
        __Async__() __SlashCmd__ "sct" "cd"
        function CountDown(cnt)
            cnt = tonumber(cnt)
            if cnt then
                for i = floor(cnt), 1, -1 do
                    print(i)
                    Delay(1)        -- Delay 1 sec, explained later
                end
            end
        end

    In the function, **Delay(1)** API is used to make the code stop and resume it after 1 sec, it requires the function must be run as a thread. So we use `__Async__()` mark the function as a thread, and use `__SlasCmd__"sct" "cd"` mark is as a slash command so we can test it.

* `__Iterator__`   -- Mark the global function as an iterator that can be used in `for do - end`. The function will be run as a thread, so in it, need use coroutine.yield to yield values like :

        Scorpio "ScorpioTest" "1.0.0"

        __Iterator__()
        function Fib(i, j, max)
            local prev, nxt = i, j

            for i = 1, max do
                local s = prev + nxt
                prev, nxt = nxt, s

                coroutine.yield(i, s)
            end
        end

        for i, f in Fib(1, 1, 10) do
            print(i, f)
        end

    So the Fib is used as an iterator, it's very useful to produce many values in many times just in one call. I also use it in my container bag addon to filter bag slots to each containers by rules.

---------------------------------------

## Thread & Task scheduling system ##

In common addon developments, we may face some problems that we need use system event and frame's OnUpdate to handle one task, we should register events, show the frame with OnUpdate, and run code in their handlers just for one task, after it finished, we need hide the frame, un-register the events. Don't forget the variables that we need use to keep those functions to work together.

So here is the thread, the best thing in the thread is it can be yield, and when the requirement is meet, we can resume it and continue its jobs without any more controls.

But also there are some disadvantages of it :

1. Creating a thread cost more than create a function, the more we use it, the more cost for it's creation and garbage collection.

2. There is no original system to help the authors to decide when yield or resume those threads, it's a hard work for authors to use them. Ann has an addon use OnUpdate to resume a thread so it won't freeze the game, Bob also have a thread do the same job, so the two authors won't know if those threads will freeze the game since they won't consider the operation time used by others.

**Scorpio** have provide a full solution for those conditions :

1. [PLoop]() has a well-designed thread pool, we can require a thread from it, run our function, after it done, the thread will be send back to the pool, re-use them will largely decrease the cost of thread.

2. **Scorpio** has provide a full list APIs to generate thread and send them to a **Task scheduling system**. The system will calculate the max operation time that won't cause the decrease of fps, and resume those scheduled threads by priorty, when the max time reached, it will stop the process, and wait to the next time(next OnUpdate).

3. Those apis can be used in non-scorpio addons, but you need add **Scorpio.** before them, like use **Scorpio.Delay(1)**.

Here is the list of those apis(Those examples can be test in in-game editor like [Cube](https://wow.curseforge.com/projects/igas-cube) or [WOWLua]())

# Starting a thread and call function under the conditions #

API                                                 |Description
----------------------------------------------------|----------------------------------------
Continue(func[, ...])                               |Call the func with arguments as soon as possible.
Next(func[, ...])                                   |Call the func with arguments in the next frame OnUpdate.
Delay(delay, func[, ...])                           |Call the func with arguments after a delay(second).
NextEvent(event, func[, ...])                       |Call the func when an system event is fired. If there is no arguments, the system event's argument should be used.
Wait(func[,delay][,event[, ...]])                   |Call the func when one of the registered events fired or meet the delay time, if it's resumed by a system event, the name and its arguments would be passed to the func.
Wait(func[,event[, ...]])                           |Call the func when one of the registered events fired, the event name and its arguments would be passed to the func.
NoCombat(func[, ...])                               |Call the func with arguments when not in combat.
NextCall([func, ][target, ]targetFunc[, ...])       |Call the func with arguments when the target's target un-secure method is called.
NextSecureCall([func, ][target, ]targetFunc[, ...]) |Call the func with arguments when the target's target secure method is called.


# Must be used in a thread, yield the current thread and resume it under the conditions #

API                                         |Description
--------------------------------------------|--------------------------------------------
Continue()                                  |Continue the thread as soon as possible.
Next()                                      |Continue the thread in next frame OnUpdate.
Delay(delay)                                |Continue the thread after a delay(second).
NextEvent(event)                            |Continue the thread when an system event is fired, the system event's argument will be returned.
Wait([delay,][event[,...]])                 |Continue the thread when one of the registered events fired or meet the delay time, if it's resumed by a system event, the name and its arguments would be returned.
Wait([event[,...]])                         |Continue the thread when one of the registered events fired, the event name and its arguments would be returned.
NoCombat()                                  |Continue the thread when not in combat.
NextCall([target, ]targetFunc[, ...])       |Continue the thread  when the target's target un-secure method is called.
NextSecureCall([target, ]targetFunc[, ...]) |Continue the thread  when the target's target secure method is called.


Here are some examples :

1. Big-cycle without fps drop

        Scorpio.Continue(
            function ()
                local time = GetTime()
                local prev = 0
                for i = 1, 10^7 do
                    if i%10 == 0 then
                        Scorpio.Continue() -- The frame will freeze if miss this

                        if time ~= GetTime() then
                            -- Means the thread is resumed in the next frame OnUpdate
                            time = GetTime()

                            -- Here is the current time and the cycle count of the previous phase
                            -- On my laptop, it's about 12500
                            print(time, i - prev)
                            prev = i
                        end
                    end
                end
            end
        )


2. Animation Simulation

        Scorpio "AlphaTest" ""

        -- create a 100*100 white frame in the center
        local frame = CreateFrame("Frame")
        frame:SetPoint("CENTER")
        frame:SetSize(100, 100)

        local txt = frame:CreateTexture("ARTWORK")
        txt:SetAllPoints()
        txt:SetColorTexture(1, 1, 1)

        -- cancel the fade when move mouse in
        function OnEnter(self)
           self:SetAlpha(1)
        end

        __Async__()
        function OnLeave(self)
            local start = GetTime()

            -- We should stop the thread when mouse is move in or the frame finished the fade out
            while not self:IsMouseOver() do
                -- The fade duration is 3
                local alpha = (GetTime() - start) / 3
                if alpha < 1 then
                    self:SetAlpha(1 - alpha)

                    Next() -- Wait the next OnUpdate
                else
                    -- almost fade out, stop the thread
                    self:SetAlpha(0)
                    break
                end
            end
        end

        frame:SetScript("OnEnter", OnEnter)
        frame:SetScript("OnLeave", OnLeave)

    Here is an example used to fade out the frame when mouse move away. You also can do it with animation widgets.

3. Wait Addon's loading

        local addon = "Blizzard_AuctionUI"
        Scorpio.Continue(
            function()
                while Scorpio.NextEvent("ADDON_LOADED") ~= addon do end
                print(addon .. " is loaded.")
            end
        )

    So, this is how the `__AddonSecureHook__` work.


4. System Event Scan

        Scorpio "ScanEvent" ""

        __Async__()
        function ScanEvent(...)
            while true do
                print( Wait(...) )
            end
        end

        ScanEvent("UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START")

    The code is used to catch all spell (not instant spell) and channel spell's casting. The event's name and other arguments would be print out.
