# Scorpio

The Scorpio Project is used to build an addon platform for World of Warcraft.

It's designed based on the [PLoop](https://github.com/kurapica/PLoop), although the Lib is created based on
the OOP system, it provided a pure functional programming style to easy the addon development. 

The Scorpio provides several features to simple and power the addons:

1. A declarative functional programming style to register and handle the system events, secure hooks and slash commands.

    ```lua
    -- Use a Scorpio Module to change the code environment
    -- so the declarative functional style can be used
    Scorpio "Test" ""

    -- Register UNIT_SPELLCAST_START system event and bind its handler
    __SystemEvent__()
    function UNIT_SPELLCAST_START(unit, spell)
        print(unit .. " cast " .. spell)
    end
    ```

2. A full addon life-cycle management. Addons can split their features into several modules for management.

    ```lua
    -- Addon Module can have sub-modules, the sub-modules can share all global variables defined in its parent module
    Scorpio "Test.SubModule" ""

    -- Triggered when the addon(module) and it's saved variables is loaded
    function OnLoad()
    end

    -- Triggered when the addon(module) is enabled or player logined, so all player data can be accessed
    function OnEnable()
    end

    -- Triggered when player specialization changed or player logined, we can check the player's specialization
    function OnSpecChanged(spec)
    end

    -- Triggered when the addon(module) is disabled, normally no use, the module will disable its event handlers
    -- when it's disabled.
    function OnDisable()
    end

    -- Triggered when the player logout, we can modify the saved variables for the last time
    function OnQuit()
    end
    ```

3. An asynchronous framework to avoid the using of callbacks, and have all the asynchronous tasks controlled under
a task schedule system, so the FPS will be smooth and almost no dropping caused by the Lua codes.

    ```lua
    Scorpio "Test" ""

    -- So the endless task will be started when player logined
    __Async__()
    function OnEnable()
        local count = 0

        while true do
            -- Delay the code execution for 10s, only works in
            -- function with `__Async__` declaration
            Delay(10)

            count = count + 10
            print("you have played for " .. count .. " sec")
        end
    end
    ```

4. A new UI & Skin system, It'll split the functionality and display of the widgets, so we can create functionality
UIs in one addons, and let's other authors do the skin parts very easily.

    ```lua
    Scorpio "Test" ""

    Style[UIParent]     = {
        -- Here a fontstring will be created on the center of the screen
        -- widget like Label are property child, they can be released and re-used
        -- Change the code to `Label = NIL`, it'll be released and waiting for the next usage
        -- So we don't need create those ui elements in the core logic, it's just a skin settings
        -- We'll see more in the observable introduction
        Label           = {
            location    = { Anchor("CENTER") },

            -- Bind the label's text to observe the player's unit health
            -- Need lose some hp to trigger the UNIT_HEALTH event
            text        = Wow.FromEvent("UNIT_HEALTH")  -- An observable generate from the UNIT_HEALTH event
                        :MatchUnit("player")            -- A filter operation that only allow player
                        :Map(UnitHealth),               -- A map operation that change the unit -> health
        }
    }
    ```

5. A well designed secure template framework, so we can enjoy the power of the secure template system provided by
the blizzard and stay away the hard part.

* Check the [Aim](../ashtoash) for nameplates, use its defaultskin.lua can
    simply change all the skins.
* Check the [AshToAsh](../ashtoash) for raid panel, it can smoothly relayout
    during combat.
* Check the [ShadowDancer](../shadowdancer) for action bars, it provide
    all your need for the action bars, also with special features.
* Check the [BagView](../shadowdancer) for containers.


## Documents

You can find the documents in [Scorpio Documents](https://github.com/kurapica/Scorpio/tree/master/Docs)