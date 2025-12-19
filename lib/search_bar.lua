
local constants = require("plugins.custom.finder.lib.consts")
local highlighter = require("plugins.custom.finder.lib.highlighter")
local keymaps = require("plugins.custom.finder.lib.keymaps")
keymap_mgr = nil
finder_search_bar = {}
finder_search_bar.__index = finder_search_bar

finder_search_bar.VALID_WINDOW_EVENTS = {"on_lines", "on_bytes", "on_changedtick", "on_detach", "on_reload"}

function finder_search_bar:new(window_config, width_percent, should_enter)
    local current_editing_win = vim.api.nvim_get_current_win()
    vim.print("current editing win is " .. current_editing_win)
    local obj = {
        query_buffer = constants.buffer.INVALID_BUFFER,
        query_win_config = window_config,
        width_percent = width_percent,
        should_enter = should_enter or true,
        send_buffer = false, -- unused since we use lua cbs
        highlighter = highlighter:new(current_editing_win, constants.highlight.MATCH_HIGHLIGHT, constants.highlight.CURR_MATCH_HIGHLIGHT),
        win_id = constants.window.INVALID_WINDOW_ID,
    }
    t = setmetatable(obj, self)
    keymap_mgr = keymaps:new(t)
    return t
end

function finder_search_bar:set_event_handlers(events)
    self.window_events = events.event_table
end

function finder_search_bar:toggle_case_sensitivity()
    self.highlighter:toggle_ignore_case(self.query_buffer)
end

function finder_search_bar:on_lines_handler(...)
  local event, bufnr, changedtick,
    first_line, last_line,
    new_lastline, bytecount = ...

    local search = self:get_window_contents() --grab the current contents of the window
    vim.schedule(function()
        self.highlighter:clear_highlights(self.highlighter.hl_buf, self.query_buffer)
        -- anytime we search update in case the file changed... this needs to be optimized for better performance
        self.highlighter:update_hl_context(self.highlighter.hl_buf, self.query_buffer)
        self.highlighter.match_index = 0
        self.highlighter.matches = {}
        Finder_Logger:debug_print("Searching buffer for pattern ", search)
        self.highlighter:highlight_file_by_pattern(self.query_buffer, search)

    end)
end

function finder_search_bar:is_open()
    return self.win_id ~= constants.window.INVALID_WINDOW_ID
end

function finder_search_bar:get_window_contents()
    return vim.api.nvim_buf_get_lines(self.query_buffer, 0, 1, true)[1]
end

function finder_search_bar:toggle()
    if self:is_open() then
        self:close()
    else
        self:open()
    end
end

function finder_search_bar:move_window(new_col)
    if self:is_open() then
        if new_col > 0 then
            self.query_win_config.col = new_col - self.query_win_config.width - 1
            vim.api.nvim_win_set_config(self.win_id, self.query_win_config)
        end
    end
end

function finder_search_bar:attach_events()
    if self.window_events ~= nil then
        vim.api.nvim_buf_attach(self.query_buffer, true, self.window_events)
    end
end

function finder_search_bar:open()
    if not self:is_open() then
        Finder_Logger:debug_print("Opening window")
        local window = vim.api.nvim_get_current_win()
        self.query_buffer = vim.api.nvim_create_buf(constants.buffer.LIST_BUFFER, constants.buffer.SCRATCH_BUFFER)
        self.query_win_config.width = math.floor(vim.api.nvim_win_get_width(window) * self.width_percent)
        self.query_win_config.col = vim.api.nvim_win_get_width(window)
        self.search_window = window
        self.win_id = vim.api.nvim_open_win(self.query_buffer, self.should_enter, self.query_win_config)
        if self.highlighter.hl_context == constants.buffer.NO_CONTEXT then
            Finder_Logger:warning_print("No valid context found attempting to populate now")
            self.highlighter:update_hl_context(window, self.win_id)
        end
        self:attach_events() -- pass through like {on_lines: lines_handler}
        vim.cmd('startinsert') -- allow for typing right away
        keymap_mgr:setup_search_keymaps()
    else
        Finder_Logger:debug_print("Attempted to open an already open window ignoring...")
    end
end

function finder_search_bar:close()
    if self:is_open() then
        close_id = self.win_id
        self.win_id = constants.window.INVALID_WINDOW_ID
        Finder_Logger:debug_print("Closing open window")

        keymap_mgr:teardown_search_keymaps()
        vim.api.nvim_win_close(close_id, false)
        vim.api.nvim_buf_delete(self.query_buffer, {force = true}) -- buffer must be deleted after window otherwise window_close gives bad id
        self.query_buffer = constants.window.INVALID_WINDOW_ID
    else
        Finder_Logger:debug_print("Attempted to close a but now window was open ignoring...")
    end
end

function finder_search_bar:previous_match()
    self:move_selected_match(constants.search.BACKWARD)
end

function finder_search_bar:next_match()
    self:move_selected_match(constants.search.FORWARD)
end

function finder_search_bar:move_selected_match(direction)
    if self.highlighter.matches ~= nil and #self.highlighter.matches > 0 then
        self.highlighter:clear_match_count(self.query_buffer)
        self.highlighter:update_search_results(self.query_buffer,
                                               self.highlighter.match_index,
                                               self.highlighter.matches)
        self.highlighter:move_cursor(direction)
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function finder_search_bar:clear_search()
    vim.api.nvim_buf_set_lines(self.query_buffer, constants.lines.START, constants.lines.END,
                              true, constants.buffer.EMPTY_BUFFER)
end

return finder_search_bar
