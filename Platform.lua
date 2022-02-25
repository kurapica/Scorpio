PLOOP_PLATFORM_SETTINGS = {
    --- Whether the type validation should be disabled. The value should be
    -- false during development, toggling it to true will make the system
    -- ignore the value valiation in several conditions for speed.
    TYPE_VALIDATION_DISABLED            = false,

    --- Whether the attribute system use warning instead of error for
    -- invalid attribute target type.
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    ATTR_USE_WARN_INSTEAD_ERROR         = false,

    --- Whether the environmet allow global variable be nil, if false,
    -- things like ture(spell error) could trigger error.
    -- Default true
    -- @owner       PLOOP_PLATFORM_SETTINGS
    ENV_ALLOW_GLOBAL_VAR_BE_NIL         = true,

    --- Whether allow old style of type definitions like :
    --      class "A"
    --          -- xxx
    --      endclass "A"
    --
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    TYPE_DEFINITION_WITH_OLD_STYLE      = true,

    --- Whether all old objects keep using new features when their
    -- classes or extend interfaces are re-defined.
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    CLASS_NO_MULTI_VERSION_CLASS        = true,

    --- Whether all interfaces & classes only use the classic format
    -- `super.Method(obj, ...)` to call super's features, don't use new
    -- style like :
    --      super[obj].Name = "Ann"
    --      super[obj].OnNameChanged = super[obj].OnNameChanged + print
    --      super[obj]:Greet("King")
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    CLASS_NO_SUPER_OBJECT_STYLE         = true,

    --- Whether all interfaces has anonymous class, so it can be used
    -- to generate object
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    INTERFACE_ALL_ANONYMOUS_CLASS       = false,

    --- Whether all class objects can't save value to fields directly,
    -- So only init fields, properties, events can be set during runtime.
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    OBJECT_NO_RAWSEST                   = false,

    --- Whether all class objects can't fetch nil value from it, combine it
    -- with @OBJ_NO_RAWSEST will force a strict mode for development.
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    OBJECT_NO_NIL_ACCESS                = false,

    --- Whether save the creation places (source and line) for all objects
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    OBJECT_DEBUG_SOURCE                 = false,

    --- The Log level used in the Prototype core part.
    --          1 : Trace
    --          2 : Debug
    --          3 : Info
    --          4 : Warn
    --          5 : Error
    --          6 : Fatal
    -- Default 3(Info)
    -- @owner       PLOOP_PLATFORM_SETTINGS
    CORE_LOG_LEVEL                      = 3,

    --- The core log handler works like :
    --      function CORE_LOG_HANDLER(message, loglevel)
    --          -- message  : the log message
    --          -- loglevel : the log message's level
    --      end
    -- Default print
    -- @owner       PLOOP_PLATFORM_SETTINGS
    CORE_LOG_HANDLER                    = print,

    --- Whether try to save the stack data into the exception object, so
    -- we can have more details about the exception.
    -- Default false
    -- @owner       PLOOP_PLATFORM_SETTINGS
    EXCEPTION_SAVE_STACK_DATA           = false,

    --- The max pool size of the thread pool
    -- Default 40
    -- @owner       PLOOP_PLATFORM_SETTINGS
    THREAD_POOL_MAX_SIZE                = 40,
}