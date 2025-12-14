finder_keymaps = {}

local constants = require("plugins.custom.finder.lib.consts")
finder_keymaps.__index = finder_keymaps

function finder_keymaps:new(search_bar)
    local obj = {
        search_bar = search_bar
    }
    return setmetatable(obj, self)
end

function finder_keymaps:setup_search_keymaps()
    vim.keymap.set('n', 'n', function() self.search_bar:next_match() end, {
        buffer = self.search_bar.query_buffer,
        nowait = true,
        noremap = true})

    vim.keymap.set('n', 'N', function() self.search_bar:previous_match() end, {
        buffer = self.search_bar.query_buffer,
        nowait = true,
        noremap = true})
    vim.keymap.set('n', 'c', function() self.search_bar:clear_search() end, {
        buffer = self.search_bar.query_buffer,
        nowait = true,
        noremap = true})
end

function finder_keymaps:teardown_search_keymaps()
    vim.keymap.del('n', 'n', {buffer = self.search_bar.query_buffer })
    vim.keymap.del('n', 'N', {buffer = self.search_bar.query_buffer})
    vim.keymap.del('n', 'c', {buffer = self.search_bar.query_buffer})
end

return finder_keymaps
