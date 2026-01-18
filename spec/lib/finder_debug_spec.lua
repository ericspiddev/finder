local debug = require('lib.finder_debug')
local stub = require('luassert.stub')

local levels = debug.DEBUG_LEVELS

local stringify_table = function(table)
    return vim.inspect(table)
end

function create_debug_logger(level, print_func, error_func)
    print_func = print_func or vim.print
    error_func = error_func or vim.notify
    return debug:new(level, print_func, error_func)
end

describe('debug', function()

    it('successfully evaluates the debug level', function()

        stub(vim, "print")
        local dbg = create_debug_logger(levels.OFF)

        assert(not dbg:check_debug_level(nil))
        assert(not dbg:check_debug_level())

        assert(not dbg:check_debug_level(levels.ERROR))
        assert(not dbg:check_debug_level(levels.INFO))
        assert(not dbg:check_debug_level(levels.WARNING))
        assert(not dbg:check_debug_level(levels.DEBUG))

        dbg = create_debug_logger(levels.ERROR)
        assert(dbg:check_debug_level(levels.ERROR))
        assert(not dbg:check_debug_level(levels.INFO))
        assert(not dbg:check_debug_level(levels.WARNING))
        assert(not dbg:check_debug_level(levels.DEBUG))

        dbg = create_debug_logger(levels.WARNING)
        assert(dbg:check_debug_level(levels.ERROR))
        assert(not dbg:check_debug_level(levels.INFO))
        assert(dbg:check_debug_level(levels.WARNING))
        assert(not dbg:check_debug_level(levels.DEBUG))

        dbg = create_debug_logger(levels.INFO)
        assert( dbg:check_debug_level(levels.ERROR))
        assert( dbg:check_debug_level(levels.INFO))
        assert( dbg:check_debug_level(levels.WARNING))
        assert(not dbg:check_debug_level(levels.DEBUG))

        dbg = create_debug_logger(levels.DEBUG)
        assert(dbg:check_debug_level(levels.ERROR))
        assert(dbg:check_debug_level(levels.INFO))
        assert(dbg:check_debug_level(levels.WARNING))
        assert(dbg:check_debug_level(levels.DEBUG))
        assert(not dbg:check_debug_level('string'))
        assert(not dbg:check_debug_level({}))
        assert(not dbg:check_debug_level(function() end))

        vim.print:revert()
    end)

    it('is able to print different variable types', function()
        local last_msg = ""
        local NO_PREFIX =""
        local fake_print = function(message) last_msg = message end

        local dbg = create_debug_logger(levels.DEBUG, fake_print, fake_print)

        dbg:finder_print(levels.ERROR, NO_PREFIX, "Test message")
        assert.equals(last_msg, "Test message")

        local test_var = 2430
        dbg:finder_print(levels.WARNING, NO_PREFIX, "My favorite number is ", test_var)
        assert.equals(last_msg, "My favorite number is 2430")

        local test_table = {
            eric = "cool",
            answer = 32.10,
        }

        dbg:finder_print(levels.WARNING, NO_PREFIX, "Can this thing print tables? ", test_table)
        assert.equals(last_msg, "Can this thing print tables? " .. stringify_table(test_table))

        local nested_table = {
            eric = "awesome",
            answer = -213,
            table2 = {
                search = true,
                giveup = "never",
            }
        }

        local func_var = function () return 0 end

        dbg:finder_print(levels.WARNING, NO_PREFIX, "What about nested? ", nested_table)
        assert.equals(last_msg, "What about nested? " .. stringify_table(nested_table))

        dbg:finder_print(levels.WARNING, NO_PREFIX, "Functions? ", func_var)
        assert.equals(last_msg, "Functions? " .. stringify_table(func_var))

    end)

    it('prefixes messages with the proper log level tag', function()
        local last_msg = ""
        local name = "eric"
        local some_table = {
            name = "eric",
            middle = "j",
            last = "spidle"
        }
        local fake_print = function (message) last_msg = message end
            --print = function(message) last_msg = message end
        local dbg = create_debug_logger(levels.DEBUG, fake_print, fake_print)
        dbg:debug_print("Who is the coolest person ever? ", name)
        assert.equals(last_msg, "[FINDER DBG]: Who is the coolest person ever? eric")

        dbg:info_print("Who is the coolest person ever? ", name)
        assert.equals(last_msg, "[FINDER INFO]: Who is the coolest person ever? eric")

        dbg:warning_print("Who is the coolest person ever? ", name)
        assert.equals(last_msg, "[FINDER WARN]: Who is the coolest person ever? eric")

        dbg:error_print("Who is the coolest person ever? ", name)
        assert.equals(last_msg, "[FINDER ERR]: Who is the coolest person ever? eric")

        dbg:debug_print("Can we tag tables? ", some_table)
        assert.equals(last_msg, "[FINDER DBG]: Can we tag tables? " .. stringify_table(some_table))

        dbg:info_print("Can we tag tables? ", some_table)
        assert.equals(last_msg, "[FINDER INFO]: Can we tag tables? " .. stringify_table(some_table))

        dbg:error_print("Can we tag tables? ", some_table)
        assert.equals(last_msg, "[FINDER ERR]: Can we tag tables? " .. stringify_table(some_table))

    end)

    it('properly supresses print on different debug levels', function()
        local last_msg = ""
        local name = "Eric?"

        local fake_print = function(message) last_msg = message end
        local dbg = create_debug_logger(levels.OFF, fake_print, fake_print)
        dbg:debug_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:info_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:warning_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:error_print("Did you get this message, ", name)
        assert.equals(last_msg, "")

        dbg = create_debug_logger(levels.ERROR, fake_print, fake_print)
        dbg:debug_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:info_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:warning_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:error_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER ERR]: Did you get this message, Eric?")
        last_msg = ""

        dbg = create_debug_logger(levels.WARNING, fake_print, fake_print)
        dbg:debug_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:info_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:warning_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER WARN]: Did you get this message, Eric?")
        dbg:error_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER ERR]: Did you get this message, Eric?")
        last_msg = ""

        dbg = create_debug_logger(levels.INFO, fake_print, fake_print)
        dbg:debug_print("Did you get this message, ", name)
        assert.equals(last_msg, "")
        dbg:info_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER INFO]: Did you get this message, Eric?")
        dbg:warning_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER WARN]: Did you get this message, Eric?")
        dbg:error_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER ERR]: Did you get this message, Eric?")
        last_msg = ""

        dbg = create_debug_logger(levels.DEBUG, fake_print, fake_print)
        dbg:debug_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER DBG]: Did you get this message, Eric?")
        dbg:info_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER INFO]: Did you get this message, Eric?")
        dbg:warning_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER WARN]: Did you get this message, Eric?")
        dbg:error_print("Did you get this message, ", name)
        assert.equals(last_msg, "[FINDER ERR]: Did you get this message, Eric?")
        last_msg = ""

    end)

end)
