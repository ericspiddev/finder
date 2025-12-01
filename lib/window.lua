
local constants = require("plugins.custom.finder.lib.consts")
finder_window = {}
finder_window.__index = finder_window

finder_window.VALID_WINDOW_EVENTS = {"on_lines", "on_bytes", "on_changedtick", "on_detach", "on_reload"}

function finder_window:new(window_buffer, window_config, width_percent, should_enter, highlighter)
    local obj = {
        window_buffer = window_buffer,
        config = window_config,
        width_percent = width_percent,
        should_enter = should_enter or true,
        send_buffer = false, -- unused since we use lua cbs
        highlighter = highlighter,
        win_id = constants.window.INVALID_WINDOW_ID
    }
    return setmetatable(obj, self)
end

function finder_window:set_event_handlers(events)
    self.window_events = events.event_table
end

function finder_window:on_lines_handler(...)
  local event, bufnr, changedtick,
    first_line, last_line,
    new_lastline, bytecount = ...

    local search = self:get_window_contents(first_line, new_lastline) --grab the current contents of the window
    vim.schedule(function()
        Finder_Logger:debug_print("Clearing highlighting")
        self.highlighter:clear_highlights(self.highlighter.hl_buf)
        self.highlighter:clear_highlights(self.window_buffer)
        self.highlighter.match_index = 0
        self.highlighter.matches = {}
        Finder_Logger:debug_print("Searching buffer for pattern ", search)
        self.highlighter:highlight_file_by_pattern(self.window_buffer, search)

    end)
end

function finder_window:is_open()
    return self.win_id ~= constants.window.INVALID_WINDOW_ID
end

function finder_window:get_window_contents(first, last)
    return vim.api.nvim_buf_get_lines(self.window_buffer, first, last, true)[1]
end

function finder_window:toggle()
    if self:is_open() then
        self:close()
    else
        self:open()
    end
end

function finder_window:move_window(new_col)
    if self:is_open() then
        if new_col > 0 then
            self.config.col = 0 -- why does this work...?
            vim.api.nvim_win_set_config(self.win_id, self.config)
        end
    end
end

function finder_window:attach_events()
    if self.window_events ~= nil then
        vim.api.nvim_buf_attach(self.window_buffer, true, self.window_events)
    end
end

function finder_window:open()
    if not self:is_open() then
        Finder_Logger:debug_print("Opening window")
        local window = vim.api.nvim_get_current_win()
        self.config.width = math.floor(vim.api.nvim_win_get_width(window) * self.width_percent)
        self.config.col = vim.api.nvim_win_get_width(window)
        self.search_window = window
        self.win_id = vim.api.nvim_open_win(self.window_buffer, self.should_enter, self.config ) -- enter window upon opening it
        if self.highlighter.hl_context == constants.buffer.NO_CONTEXT then
            Finder_Logger:warning_print("No valid context found attempting to populate now")
            self.highlighter:update_context(window)
        end
        --Finder_Logger:debug_print("Win id is ", self.win_id)
        self:attach_events() -- pass through like {on_lines: lines_handler}
    else
        Finder_Logger:debug_print("Attempted to open an already open window ignoring...")
    end
end

function finder_window:close()
    if self:is_open() then
        close_id = self.win_id
        self.win_id = constants.window.INVALID_WINDOW_ID
        Finder_Logger:debug_print("Closing open window")
        vim.api.nvim_win_close(close_id, false)
    else
        Finder_Logger:debug_print("Attempted to close a but now window was open ignoring...")
    end
end

return finder_window
