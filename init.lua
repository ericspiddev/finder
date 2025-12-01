local events = require("finder.lib.events")
local window = require("finder.lib.window")
local highlighter = require("finder.lib.highlighter")
local M = {}

function M.setup(config)

    _G.Finder_Logger = require("finder.lib.finder_debug"):new(config.debug_level, vim.print)
    local win_config = {
        relative='win',
        row=0,
        col=200, -- TODO: come back to me
        width=50,
        zindex=1,
        anchor='NE',
        focusable=true,
        height=1,
        style="minimal",
        border={ "╔", "═","╗", "║", "╝", "═", "╚", "║" }, -- double border for now fix me later
        title_pos="center",
        title="Search"
    }

    Finder_Logger:debug_print("window: making a new window with config ", win_config)
    local win_buf = vim.api.nvim_create_buf(true, false) -- buflisted, scratch buffer
    local hl_buf = vim.api.nvim_win_get_buf(0) -- buflisted, scratch buffer
    local hl_win = vim.api.nvim_get_current_win()
    local hl_namespace = vim.api.nvim_create_namespace("finder")
    M.highlighter = highlighter:new(hl_buf, hl_win, hl_namespace, "Search")
    M.find_window = window:new(win_buf, win_config, true, M.highlighter)
    M.find_window.highlighter:populate_hl_context(0)
    M.window_events = events:new(window.VALID_WINDOW_EVENTS)
    M.window_events:add_event("on_lines", M.find_window, "on_lines_handler")
    M.find_window:set_event_handlers(M.window_events)


    M.main()
end


function M.previous_match()
    if M.highlighter.matches ~= nil and #M.highlighter.matches > 0 then
        M.highlighter:move_cursor(-1)
        M.reset_search()
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.next_match()
    if M.highlighter.matches ~= nil and #M.highlighter.matches > 0 then
        M.highlighter:move_cursor(1)
        M.reset_search()
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.reset_search()
    M.highlighter:clear_highlights(M.find_window.window_buffer)
    M.highlighter:update_search_results(M.find_window.window_buffer, M.highlighter.match_index, M.highlighter.matches)
end

function M.clear_search()
    vim.api.nvim_buf_set_lines(M.find_window.window_buffer, constants.lines.START, constants.lines.END,
                              true, constants.buffer.EMPTY_BUFFER)
end

function M.toggle()
    M.find_window:toggle()
end

function M.main()
    vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave" }, {
        callback = function(ev)
            local win = vim.api.nvim_get_current_win()
            vim.print("Window event: " .. ev.event .. " | win=" .. vim.api.nvim_get_current_win())
            vim.print("Window id for find is " .. M.find_window.win_id)
            if M.find_window.win_id ~= win and ev.event == "WinEnter" then
                M.find_window.highlighter:update_context(win)
                M.highlighter:clear_highlights(M.find_window.window_buffer)
            end
      end,
    })
    vim.keymap.set('n', '<leader>f', M.toggle, {})
    vim.keymap.set('n', '<CR>', M.next_match, {
        buffer = M.find_window.window_buffer,
        nowait = true,
        noremap = true,
    })
    vim.keymap.set('n', '<leader><CR>', M.previous_match, {
        buffer = M.find_window.window_buffer,
        nowait = true,
        noremap = true,
    })
    vim.keymap.set('n', 'c', M.clear_search, {
        buffer = M.find_window.window_buffer,
        nowait = true,
        noremap = true,
    })
end
return M
