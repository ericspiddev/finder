-- import the luassert.mock module
local mock = require('luassert.mock')
local stub = require('luassert.stub')
local debug = require('lib.finder_debug')
local consts = require('lib.consts')

describe("Search bar", function()
    local test_finder_config = {
        debug_level = debug.DEBUG_LEVELS.INFO,
        width_percentage = 0.25
    }
    SEARCH_BAR_BUF_ID = 1
    SEARCH_BAR_WIN_ID = 1005

    -- STUBS to mock out so we aren't hitting the real API
    stub(vim.api, "nvim_create_buf").returns(SEARCH_BAR_BUF_ID)
    stub(vim.api, "nvim_open_win").returns(SEARCH_BAR_WIN_ID)
    stub(vim.api, "nvim_buf_attach").returns()
    stub(vim.api, "nvim_buf_delete").returns()
    stub(vim.api, "nvim_win_close").returns()
    stub(vim.keymap, "set").returns()
    stub(vim.keymap, "del").returns()

    local test_finder = require("init")
    test_finder.setup(test_finder_config)

    before_each(function()
        test_finder.search_bar:close()
    end)

    function open_asserts()
        assert.equals(test_finder.search_bar.query_buffer, SEARCH_BAR_BUF_ID)
        assert.equals(test_finder.search_bar.win_id, SEARCH_BAR_WIN_ID)
        assert.equals(test_finder.search_bar:is_open(), true)
    end

    function closed_asserts()
        assert.equals(test_finder.search_bar.query_buffer, consts.buffer.INVALID_BUFFER)
        assert.equals(test_finder.search_bar.win_id, consts.window.INVALID_WINDOW_ID)
        assert.equals(test_finder.search_bar:is_open(), false)
    end

    it('can open a search window and assign it a valid ID', function()
        test_finder.search_bar:open()
        open_asserts()
    end)

    it('properly reports when it is open and closed', function()
        test_finder.search_bar:close()
        assert.equals(test_finder.search_bar:is_open(), false)
        test_finder.search_bar:open()
        assert.equals(test_finder.search_bar:is_open(), true)
        test_finder.search_bar:open()
        test_finder.search_bar:open()
        assert.equals(test_finder.search_bar:is_open(), true)
        test_finder.search_bar:close()
        test_finder.search_bar:close()
        test_finder.search_bar:close()
        test_finder.search_bar:close()
        assert.equals(test_finder.search_bar:is_open(), false)
    end)

    it('has invalid values when the window is closed', function()
        test_finder.search_bar:close()
        closed_asserts()
    end)

    it('toggles correctly', function()
        test_finder.search_bar:close()
        closed_asserts()

        test_finder.search_bar:toggle()
        open_asserts()

        test_finder.search_bar:toggle()
        closed_asserts()
        test_finder.search_bar:toggle()
        test_finder.search_bar:toggle()
        test_finder.search_bar:toggle()
        test_finder.search_bar:toggle()
        test_finder.search_bar:toggle()
        open_asserts()

    end)

end)
