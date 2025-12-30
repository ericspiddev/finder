finder_keymaps = {}

finder_keymaps.__index = finder_keymaps

function finder_keymaps:new(search_bar)
    local obj = {
        search_bar = search_bar
    }
    return setmetatable(obj, self)
end

-------------------------------------------------------------
--- keymaps.setup_search_keymaps: this function handles setting
--- up keymaps for the search_bar when it's open this should be
--- called when the search bar is opened so all keybinds work
--- while in the search buffer
---
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

    vim.keymap.set('n', '<leader>c', function() self.search_bar:toggle_case_sensitivity() end, {
        buffer = self.search_bar.query_buffer,
        nowait = true,
        noremap = true})

    vim.keymap.set('n', '<leader>d', function() self.search_bar.highlighter:dump_context() end, {
        buffer = self.search_bar.query_buffer,
        nowait = true})
end

-------------------------------------------------------------
--- keymaps.teardown_search_keymaps: this function handles
--- deleting all of the keymaps that get setup for the search
--- window. It's important that
---
function finder_keymaps:teardown_search_keymaps()
    vim.keymap.del('n', 'n', {buffer = self.search_bar.query_buffer })
    vim.keymap.del('n', 'N', {buffer = self.search_bar.query_buffer})
    vim.keymap.del('n', 'c', {buffer = self.search_bar.query_buffer})
    vim.keymap.del('n', '<leader>c', {buffer = self.search_bar.query_buffer})
    vim.keymap.del('n', '<leader>d', {buffer = self.search_bar.query_buffer})
end

return finder_keymaps
