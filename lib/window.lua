
finder_window = {}
finder_window.__index = finder_window

finder_window.VALID_WINDOW_EVENTS = {"on_lines", "on_bytes", "on_changedtick", "on_detach", "on_reload"}

function finder_window:new(window_buffer, window_config, should_enter, highlighter)
    local obj = {
        window_buffer = window_buffer,
        config = window_config,
        should_enter = should_enter or true,
        send_buffer = false, -- unused since we use lua cbs
        highlighter = highlighter,
        win_id = 0
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
    return self.win_id ~= 0
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

function finder_window:attach_events()
    if self.window_events ~= nil then
        vim.api.nvim_buf_attach(self.window_buffer, true, self.window_events)
    end
end

function finder_window:open()
    if not self:is_open() then
        Finder_Logger:debug_print("Opening window")
        self.win_id = vim.api.nvim_open_win(self.window_buffer, self.should_enter, self.config ) -- enter window upon opening it
        Finder_Logger:debug_print("Win id is ", self.win_id)
        self:attach_events() -- pass through like {on_lines: lines_handler}
    else
        Finder_Logger:debug_print("Attempted to open an already open window ignoring...")
    end
end

function finder_window:close()
    if self:is_open() then
        Finder_Logger:debug_print("Closing open window")
        vim.api.nvim_win_close(self.win_id, false)
        self.win_id = 0
    else
        Finder_Logger:debug_print("Attempted to close a but now window was open ignoring...")
    end
end

return finder_window
