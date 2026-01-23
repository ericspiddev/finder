local stub = require('luassert.stub')
local logger = require('nvim-scout.lib.scout_logger')

describe("Scout", function()

    it('sets the width and logger level based on the passed in config', function()
        stub(vim.api, "nvim_win_get_width").returns(250)
        local test_scout_config = {
            log_level = logger.LOG_LEVELS.INFO,
            width_percentage = 0.15
        }

        local test_scout = require("nvim-scout.init")
        test_scout.setup(test_scout_config)
        test_scout.search_bar:open()
        assert.equals(test_scout.search_bar.query_win_config.width, math.floor(250 * 0.15))
        assert.equals(Scout_Logger.log_level, logger.LOG_LEVELS.INFO)
        test_scout.search_bar:close()

        test_scout_config.log_level = logger.LOG_LEVELS.ERROR
        test_scout_config.width_percentage = 0.35
        test_scout.setup(test_scout_config)
        test_scout.search_bar:open()
        assert.equals(test_scout.search_bar.query_win_config.width, math.floor(250 * 0.35))
        assert.equals(Scout_Logger.log_level, logger.LOG_LEVELS.ERROR)
        test_scout.search_bar:close()

        test_scout_config.log_level = logger.LOG_LEVELS.DEBUG
        test_scout_config.width_percentage = 0.635
        test_scout.setup(test_scout_config)
        test_scout.search_bar:open()
        assert.equals(test_scout.search_bar.query_win_config.width, math.floor(250 * 0.635))
        assert.equals(Scout_Logger.log_level, logger.LOG_LEVELS.DEBUG)
        test_scout.search_bar:close()

        test_scout_config.log_level = logger.LOG_LEVELS.WARNING
        test_scout_config.width_percentage = 0.05
        test_scout.setup(test_scout_config)
        test_scout.search_bar:open()
        assert.equals(test_scout.search_bar.query_win_config.width, math.floor(250 * test_scout.search_bar.MIN_WIDTH))
        assert.equals(Scout_Logger.log_level, logger.LOG_LEVELS.WARNING)
        test_scout.search_bar:close()

        test_scout_config.log_level = logger.LOG_LEVELS.OFF
        test_scout_config.width_percentage = 0.95
        test_scout.setup(test_scout_config)
        test_scout.search_bar:open()
        assert.equals(test_scout.search_bar.query_win_config.width, math.floor(250 * 0.95))
        assert.equals(Scout_Logger.log_level, logger.LOG_LEVELS.OFF)
        test_scout.search_bar:close()

    end)



end)
