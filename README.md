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

**Scorpio** is an addon module class, `Scorpio "ScorpioTest"` means create a module named **ScorpioTest**, the module will be used to handle things like system event, slash commands and system hook. It's also designed to be an **environment** that used to execute code.

The common environment is the _G, normally all addon codes are executed in the _G. Using a private environment will have a tiny memory cost, but if the addon's files all use the same environment, it's useful to share features between all those files and global features defined in the private environment won't taint anything in the _G. Also some special tricks can be used in the private environment.

In `Scorpio "ScorpioTest" "1.0.0"`, the last string means version check and **change the environment to the module**. If version check failed(the module is already exstied and with a equal or big version), error will be raised. If use a empty string, the version check will be ignored and only change the environment. A version string could be anything with a serials of numbers like "alpha 1.0.1.11" "r12.01.02".

All code files in a **Scorpio** addon should have their own module for each file. The main file will use a root module, and others will use sub-modules, the sub-modules share the features defined in the root module.

As an example, create the file **ScorpioTestMdl.lua**, its first line should be like

    Scorpio "ScorpioTest.Mdl" "1.0.0"

It means create a sub-module named **Mdl** and it's parent module is **ScorpioTest**. The sub-module will share the global features defined in it's parent module and keep it's own private features. Also you can create sub-module of the sub-module like

    Scorpio "ScorpioTest.Mdl.SubMdl" "1.0.0"

---------------------------------------

## System Event Handler ##

The wow will notify us about what happened in the game world by system events. Like **UNIT_SPELLCAST_START** tell us an unit is casting a spell, it'd also give us several arguments to tell who cast it and which spell it is. You can find a full list in [Events_Full_List](http://wowwiki.wikia.com/wiki/Events_A-Z_(Full_List)).

The **Scorpio** module can use **RegisterEvent** API to register and handle the system events, but I'll show the common way in another page, here we'll see a simple way to do it, take the `UNIT_SPELLCAST_START` and `UNIT_SPELLCAST_CHANNEL_START` as the examples.

We can handle each system events by each handlers:

    __SystemEvent__()
    function UNIT_SPELLCAST_START(unit, spell)
        print(unit .. " cast " .. spell)
    end

    __SystemEvent__()
    function UNIT_SPELLCAST_CHANNEL_START(unit, spell)
        print(unit .. " cast " .. spell)
    end

The `__SystemEvent__` is an attribute class.  `__SystemEvent__()` means create an **Attribute**.

The attributes are used to bind information or do some background operations for features.

Here `__SystemEvent__()` is used to mark the next defined function as a system event handler, the system event's name is given by the function's name. So when an unit(like player self) casting a spell(not instant spell), the function would be called and event arguments would be passed in. You may test it by yourselves.

Since the code we handle the `UNIT_SPELLCAST_START` and `UNIT_SPELLCAST_CHANNEL_START` is the same, we can combine it like

    __SystemEvent__ "UNIT_SPELLCAST_START" "UNIT_SPELLCAST_CHANNEL_START"
    function UNIT_SPELLCAST(unit, spell)
        print(unit .. " cast " .. spell)
    end

So, the two system events would use the same handler.

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

    There is a problem, if you need call the TestFunc also in the module, We don't which one it should be use, so we need hook it with different name like

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
    function EnableModule()
        -- _Enabled is a property of the module, we can directly set it since the environment is the module
        -- when the module is disabled, its system event and hook handlers won't be called.
        _Enabled = true
    end

    -- /sct(scptest) disable    -- disable the module
    __SlashCmd__ "scptest" "disable"
    __SlashCmd__ "sct" "disable"
    function DisableModule()
        _Enabled = false
    end

 The two slash commands is follow the `/cmd option` pattern, the command and option are all case ignored, each hander match two commands `/sct` and `/scptest`.

    -- /sct(scptest) cd 10      -- count down from 10 to 1 per sec
    __Thread__()                -- Mark the function as a thread, explained later
    __SlashCmd__ "scptest" "cd"
    __SlashCmd__ "sct" "cd"
    function CountDown(cnt)
        cnt = tonumber(cnt)
        if cnt then
            for i = floor(cnt), 1, -1 do
                print(i)
                Delay(1)        -- Delay 1 sec, explained later
            end
        end
    end

The slash command match the pattern `/cmd option info`, the info are the rest string beside the command and option, here is used as the count down.

For the pattern `/cmd`, normally used to show the command list like

    __SlashCmd__ "scptest"
    __SlashCmd__ "sct"
    function Help()
        print("/sct(scptest) enable")
        print("/sct(scptest) disable")
        print("/sct(scptest) cd N")
    end

---------------------------------------

## Saved Variables ##

Normally, the author could handle the saved variables by themselves, but the **Scorpio** also provide a **SVManager** to easy the life.

The **ScorpioTest** addon has two saved variables : *ScorpioTest_DB* for account, *ScorpioTest_DB_Char* for character.

The saved variables'll be loaded when the addon is already loaded, so we can't handle it directly, the addon module provide a **OnLoad** event(not system event), we need handle the saved variables in it like

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

BTW. the values can also be tables, and if value if not table, only boolean, number, string will be accepted.

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

## Task API & Thread ##

The **Scorpio** Library also provide a full set APIS called **Task API**, like **Delay** we used on previous example.

* All task api will be used in thread or start a thread. The thread will be treated as a task.

* Normally those threads are get from a thread pool defined in [PLoop]. So you can ignore the cost of those thread's creation, also them would be reused when it finished the job, so you shouldn't keep it for other use.

* The tasks are controlled by the system to make sure not too many tasks are resumed that cause fps drops. We'll see examples later.

* Those APIS can be used outside the **Scorpio**'s addon, but you need use `Scorpio.` before them to access it.

Here is the list of those apis(Those examples can be test in in-game editor like [Cube](https://wow.curseforge.com/projects/igas-cube) or [WOWLua]())

# Continue #

API                               |Description
----------------------------------|------------------------------------
Continue(func[, ...])             |Call the func with arguments as soon as possible, you should noticed that the func would be running in a thread.
Continue()                        |Can only be used in a thread, it'll try to continue the thread if it still have time to execute it or send it to next phase.

    -- You can use Continue directly if those code run in a Scorpio module
    Scorpio.Continue(
        function ()
            local time = GetTime()
            local prev = 0
            for i = 1, 10^7 do
                if i%10 == 0 then
                    Scorpio.Continue()

                    if time ~= GetTime() then
                        time = GetTime()

                        -- Print the new phase's time and the cycled count in previous phase
                        print(time, i - prev)
                        prev = i
                    end
                end
            end
        end
    )

You may find no fps drops and the cycled count for one phase is about 12500 on my laptop.

# Next #

API                               |Description
----------------------------------|------------------------------------
Next(func[, ...])                 |Call the func with arguments in the next phase.
Next()                            |Can only be used in a thread, it'll resume the thread in next phase.

    print(GetTime())
    Scorpio.Next(
        function()
            for i = 1, 10 do
                Scorpio.Next()
                print(GetTime())
            end
        end
    )

You may find the *GetTime*'s result are all different, it's a better way to do animations if you don't want create any animation widgets, also can be used in some special conditions : In the [Cube](), you can double click on a word to choose it, it's handed in the editbox's *OnMouseDown* event, but from wow 7.0, the wow would modify the highlights after the event, so my action is canceled. To make sure my action is done after the orginal behavior, the **Next** API is the better choice.

# Delay #

API                               |Description
----------------------------------|------------------------------------
Delay(delay, func[, ...])         |Call the func with arguments after a delay(second).
Delay(delay)                      |Can only be used in a thread, it'll resume the thread after a delay(second). We already have an example in the slash command.

# Event #

API                               |Description
----------------------------------|------------------------------------
Event(event, func[, ...])         |Call the func when an system event is fired. If there is no arguments, the system event's argument should be used.
Event(event)                      |Can only be used in a thread, it'll resume the thread when an system event is fired, the system event's argument will be returned.

    local addon = "Blizzard_AuctionUI"
    Scorpio.Continue(
        function()
            while Scorpio.Event("ADDON_LOADED") ~= addon do end
            print(addon .. " is loaded.")
        end
    )

The code is used to notify us when the Blizzard_AuctionUI loaded.

# Wait #

API                               |Description
----------------------------------|------------------------------------
Wait(func[,delay][,event[, ...]]) |Call the func when one of the registered events fired or meet the delay time, if it's resumed by a system event, the name and its arguments would be passed to the func.
Wait([delay,][event[,...]])       |Can only be used in a thread, it'll resume the thread when one of the registered events fired or meet the delay time, if it's resumed by a system event, the name and its arguments would be returned.

    Scorpio.Continue(
        function()
            while true do
                print(Scorpio.Wait("UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START"))
            end
        end
    )

The code is used to catch all spell (not instant spell) and channel spell's casting. The event's name and other arguments would be print out.

# NoCombat #

API                               |Description
----------------------------------|------------------------------------
NoCombat(func[, ...])             |Call the func when not in combat.
NoCombat()                        |Can only be used in a thread, it'll resume the thread when not in combat.

---------------------------------------

## Some Other Attribtues ##

In the previous examples, we have see attributes like `__SystemEvent__`, `__SecureHook__`. The **Scorpio** & **PLoop** also provided many useful attributes, here I'll show three useful attributes that you may using.

* `__NoCombat__`  -- Mark the global function(also the module event handler like OnLoad) defined in a Scorpio module, so it'll be real called when out of combat.

        Scorpio "ScorpioTest" "1.0.0"

        __NoCombat__()
        __SystemEvent__ "GROUP_ROSTER_UPDATE"
        function UpdatePanel()
            -- Update panel like grids
        end

    The `GROUP_ROSTER_UPDATE` system event means the raid|party group is changed, so we may need to update the panel, but we can't do it during the combat, so give it `__NoCombat__` attribute will make sure it'll only be real called out of combat. (It's just an example, in the real addon, we can handle it by using secure templates).

* `__Thread__`  -- Mark the global function defined in a Scorpio module, so it would be called as a thread.

        Scorpio "ScorpioTest" "1.0.0"

        __Thread__() __SystemEvent__()
        function PLAYER_REGEN_DISABLED()
            local i = 1

            print("In Combat")

            -- If meet the delay, nothing would be returned by Wait
            while not Wait(1, "PLAYER_REGEN_ENABLED") do
                print("In Combat about " .. i .. " Sec")
                i = i + 1
            end

            print("Out of combat.")
        end

    So we'll call the function when `PLAYER_REGEN_DISABLED` fired, that means the player is in combat now. Since the function is called as thread, so we can use **Wait** directly in the code.

* `__Iterator__`   -- Mark the global function as an iterator that can be used in `for do - end`. The function will be run as a thread, so in it, need use coroutine.yield to yield values like :

        Scorpio "ScorpioTest" "1.0.0"

        __Iterator__()
        function Fib(i, j, max)
            local prev, nxt = i, j
            local cnt = 1

            while cnt <= max do
                local s = prev + nxt
                prev, nxt = nxt, s

                coroutine.yield(cnt, s)

                cnt = cnt + 1
            end
        end

        for i, f in Fib(1, 1), 10 do
            print(i, f)
        end

    Here is a code to calc the fibnacci array, in the `for do - end`, the arguments in the brackets and outside the brackets would be combined and then send to the function. So you can also use it like :

        for i, f in Fib(1, 1, 10) do
            print(i, f)
        end

    Please notice, there can be only max to 2 arguments can be usded outside the brackets.

    It's useful to create producer, I also use it in my container bag addon.

---------------------------------------

## The Localization ##



---------------------------------------

## Logger System ##




