local stub = require('luassert.stub')
local debug = require('lib.finder_debug')

describe("Finder", function()

    it('sets the width and debug level based on the passed in config', function()
        stub(vim.api, "nvim_win_get_width").returns(250)
        local test_finder_config = {
            debug_level = debug.DEBUG_LEVELS.INFO,
            width_percentage = 0.15
        }

        local test_finder = require("init")
        test_finder.setup(test_finder_config)
        test_finder.search_bar:open()
        assert.equals(test_finder.search_bar.query_win_config.width, math.floor(250 * 0.15))
        assert.equals(Finder_Logger.debug_level, debug.DEBUG_LEVELS.INFO)
        test_finder.search_bar:close()

        test_finder_config.debug_level = debug.DEBUG_LEVELS.ERROR
        test_finder_config.width_percentage = 0.35
        test_finder.setup(test_finder_config)
        test_finder.search_bar:open()
        assert.equals(test_finder.search_bar.query_win_config.width, math.floor(250 * 0.35))
        assert.equals(Finder_Logger.debug_level, debug.DEBUG_LEVELS.ERROR)
        test_finder.search_bar:close()

        test_finder_config.debug_level = debug.DEBUG_LEVELS.DEBUG
        test_finder_config.width_percentage = 0.635
        test_finder.setup(test_finder_config)
        test_finder.search_bar:open()
        assert.equals(test_finder.search_bar.query_win_config.width, math.floor(250 * 0.635))
        assert.equals(Finder_Logger.debug_level, debug.DEBUG_LEVELS.DEBUG)
        test_finder.search_bar:close()

        test_finder_config.debug_level = debug.DEBUG_LEVELS.WARNING
        test_finder_config.width_percentage = 0.05
        test_finder.setup(test_finder_config)
        test_finder.search_bar:open()
        assert.equals(test_finder.search_bar.query_win_config.width, math.floor(250 * test_finder.search_bar.MIN_WIDTH))
        assert.equals(Finder_Logger.debug_level, debug.DEBUG_LEVELS.WARNING)
        test_finder.search_bar:close()

        test_finder_config.debug_level = debug.DEBUG_LEVELS.OFF
        test_finder_config.width_percentage = 0.95
        test_finder.setup(test_finder_config)
        test_finder.search_bar:open()
        assert.equals(test_finder.search_bar.query_win_config.width, math.floor(250 * 0.95))
        assert.equals(Finder_Logger.debug_level, debug.DEBUG_LEVELS.OFF)
        test_finder.search_bar:close()

    end)



end)
