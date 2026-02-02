local init = require('nvim-scout.init')
local default_conf = require('nvim-scout.lib.config').defaults
local utils = require('spec.spec_utils')

describe('Functional: Scout ', function ()

    function test_global_keymaps(toggle_key, focus_key, scout)
        utils:emulate_user_keypress(toggle_key)
        assert(scout.search_bar:is_open())

        utils:emulate_user_keypress(toggle_key)
        assert.equals(false, scout.search_bar:is_open())

        utils:emulate_user_keypress(toggle_key)
        assert.equals(vim.api.nvim_get_current_buf(), scout.search_bar.query_buffer)

        utils:keycodes_user_keypress("<C-w>h") -- switch out of window
        assert.are_not.equal(vim.api.nvim_get_current_buf(), scout.search_bar.query_buffer)

        utils:emulate_user_keypress(focus_key)
        assert.equals(vim.api.nvim_get_current_buf(), scout.search_bar.query_buffer)

        scout.search_bar:close() -- reset for next tests
    end

    it('can be called with an empty setup and have no errors', function ()
        init.setup({})
    end)


    it('sets up keymaps from default config when no options are passed in', function ()
        local scout = init
        local keys = default_conf.keymaps
        scout.setup()
        test_global_keymaps(keys.toggle_search, keys.focus_search, scout)
    end)

    it('uses overridden global keymaps when passed in through the config', function ()
        local scout = init
        local opts = {
            keymaps = {
                toggle_search = "T",
                focus_search = "H",
            }
        }
        scout.setup(opts)
        test_global_keymaps("T", "H", scout)
    end)

    -- it('moves the scout window over if a split view is used', function ()
    --     --- TODO!
    --     assert(false)
    -- end)

end)



