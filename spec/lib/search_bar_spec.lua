-- import the luassert.mock module
local stub = require('luassert.stub')
local consts = require('lib.consts')
local search_bar_t = require('lib.search_bar')
local util = require('spec.spec_utils')

-- test constants
SEARCH_BAR_BUF_ID = 1
SEARCH_BAR_WIN_ID = 1005
SEARCH_BAR_WINDOW_WIDTH = 100
SEARCH_BAR_WIDTH_PERCENT = 0.25

-- hepler functions
function setup_search_tests()
    util:mock_debug_prints()
    -- STUBS to mock out so we aren't hitting the real API
    stub(vim.api, "nvim_create_buf").returns(SEARCH_BAR_BUF_ID)
    stub(vim.api, "nvim_open_win").returns(SEARCH_BAR_WIN_ID)
    stub(vim.api, "nvim_buf_attach").returns()
    stub(vim.api, "nvim_buf_delete").returns()
    stub(vim.api, "nvim_win_close").returns()
    stub(vim.api, "nvim_buf_get_lines").returns({"first", "second", "third"})
    stub(vim.api, "nvim_win_get_width").returns(SEARCH_BAR_WINDOW_WIDTH)
    stub(vim.api, "nvim_win_set_config").returns()
    stub(vim.keymap, "set").returns()
    stub(vim.keymap, "del").returns()
end

function open_asserts(search)
    assert.equals(search.query_buffer, SEARCH_BAR_BUF_ID)
    assert.equals(search.win_id, SEARCH_BAR_WIN_ID)
    assert.equals(search:is_open(), true)
end

function closed_asserts(search)
    assert.equals(search.query_buffer, consts.buffer.INVALID_BUFFER)
    assert.equals(search.win_id, consts.window.INVALID_WINDOW_ID)
    assert.equals(search:is_open(), false)
end

describe("Search bar", function()

    setup_search_tests()

    local search_bar = search_bar_t:new({}, SEARCH_BAR_WIDTH_PERCENT, true)

    before_each(function()
        search_bar:close()
    end)

    it('can open a search window and assign it a valid ID', function()
        search_bar:open()
        open_asserts(search_bar)
    end)

    it('properly reports when it is open and closed', function()
        search_bar:close()
        assert.equals(search_bar:is_open(), false)
        search_bar:open()
        assert.equals(search_bar:is_open(), true)
        search_bar:open()
        search_bar:open()
        assert.equals(search_bar:is_open(), true)
        search_bar:close()
        search_bar:close()
        search_bar:close()
        search_bar:close()
        assert.equals(search_bar:is_open(), false)
    end)

    it('caps the search window between it\'s min and max value', function()
        assert.equals(search_bar.MAX_WIDTH, search_bar:cap_width(100))
        assert.equals(search_bar.MIN_WIDTH, search_bar:cap_width(0.05))
        assert.equals(0.75, search_bar:cap_width(0.75))
        assert.equals(0.15, search_bar:cap_width(0.15))
        assert.equals(search_bar.MAX_WIDTH, search_bar:cap_width(2))
        assert.equals(search_bar.MIN_WIDTH, search_bar:cap_width(-1000))
    end)

    it('has invalid values when the window is closed', function()
        search_bar:close()
        closed_asserts(search_bar)
    end)

    it('properly calculates width percentage ', function()
        search_bar:open()
        assert.equals(search_bar.query_win_config.width, SEARCH_BAR_WINDOW_WIDTH * SEARCH_BAR_WIDTH_PERCENT)
    end)

    it('properly moves the window over based on the new column', function()

        search_bar:close()
        search_bar:move_window(250)
        assert.equals(search_bar.query_win_config.col, 100)
        search_bar:move_window(300)
        assert.equals(search_bar.query_win_config.col, 100)

        search_bar:open()
        search_bar:move_window(250)
        assert.equals(search_bar.query_win_config.col, 224)
        search_bar:move_window(300)
        assert.equals(search_bar.query_win_config.col, 274)
    end)

    it('toggles correctly', function()
        search_bar:close()
        closed_asserts(search_bar)

        search_bar:toggle()
        open_asserts(search_bar)

        search_bar:toggle()
        closed_asserts(search_bar)
        search_bar:toggle()
        search_bar:toggle()
        search_bar:toggle()
        search_bar:toggle()
        search_bar:toggle()
        open_asserts(search_bar)

    end)

    it('gets the first result of the buffer only', function ()
        assert.equals("first", search_bar:get_window_contents())
    end)

end)
