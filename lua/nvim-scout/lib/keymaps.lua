scout_keymaps = {}
local consts = require("nvim-scout.lib.consts")

scout_keymaps.__index = scout_keymaps

function scout_keymaps:new(search_bar)
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
function scout_keymaps:setup_search_keymaps()
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

function scout_keymaps:setup_history_keymaps()
    vim.keymap.set('n', '<UP>', function() self.search_bar:next_history_entry() end, {
        buffer = self.search_bar.query_buffer,
        nowait = true,
        noremap = true})

    vim.keymap.set('n', '<DOWN>', function() self.search_bar:previous_history_entry() end, {
        buffer = self.search_bar.query_buffer,
        nowait = true,
        noremap = true})
end

function scout_keymaps:setup_mode_keymaps()
    vim.keymap.set('n', '<leader>c', function() self.search_bar.mode_manager:toggle_mode(consts.modes.case_sensitive) end, {
        buffer = self.search_bar.query_buffer,
        nowait = true,
        noremap = true})
    vim.keymap.set('n', '<leader>r', function() self.search_bar.mode_manager:toggle_mode(consts.modes.lua_pattern) end, {
        buffer = self.search_bar.query_buffer,
        nowait = true,
        noremap = true})
end

-------------------------------------------------------------
--- keymaps.teardown_search_keymaps: this function handles
--- deleting all of the keymaps that get setup for the search
--- window. It's important that
---
function scout_keymaps:teardown_search_keymaps()
    vim.keymap.del('n', 'n', {buffer = self.search_bar.query_buffer })
    vim.keymap.del('n', 'N', {buffer = self.search_bar.query_buffer})
    vim.keymap.del('n', 'c', {buffer = self.search_bar.query_buffer})
    vim.keymap.del('n', '<leader>d', {buffer = self.search_bar.query_buffer})
end

function scout_keymaps:teardown_history_keymaps()
    vim.keymap.del('n', '<UP>', {buffer = self.search_bar.query_buffer })
    vim.keymap.del('n', '<DOWN>', {buffer = self.search_bar.query_buffer})
end

function scout_keymaps:teardown_mode_keymaps()
    vim.keymap.del('n', '<leader>c', {buffer = self.search_bar.query_buffer})
    vim.keymap.del('n', '<leader>r', {buffer = self.search_bar.query_buffer})
end

function scout_keymaps:setup_scout_keymaps()
    self:setup_search_keymaps()
    self:setup_history_keymaps()
    self:setup_mode_keymaps()
end

function scout_keymaps:teardown_scout_keymaps()
    self:teardown_search_keymaps()
    self:teardown_history_keymaps()
    self:teardown_mode_keymaps()
end

return scout_keymaps
