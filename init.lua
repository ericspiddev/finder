local events = require("plugins.custom.finder.lib.events")
local window = require("plugins.custom.finder.lib.window")
local highlighter = require("plugins.custom.finder.lib.highlighter")
local constants = require("plugins.custom.finder.lib.consts")
local M = {}

function M.setup(config)

    _G.Finder_Logger = require("plugins.custom.finder.lib.finder_debug"):new(config.debug_level, vim.print)
    local search_bar_config = {
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
    local search_bar_buffer = vim.api.nvim_create_buf(true, false) -- buflisted, scratch buffer
    local file_buffer = vim.api.nvim_win_get_buf(constants.window.CURRENT_WINDOW) -- get current window's buffer
    local file_window = vim.api.nvim_get_current_win()
    local hl_namespace = vim.api.nvim_create_namespace("finder")

    M.highlighter = highlighter:new(file_buffer, file_window, hl_namespace, "Search")
    M.find_window = window:new(search_bar_buffer, search_bar_config, config.width_percentage, true, M.highlighter)
    M.find_window.highlighter:populate_hl_context(constants.window.CURRENT_WINDOW)
    M.window_events = events:new(window.VALID_WINDOW_EVENTS)
    M.window_events:add_event("on_lines", M.find_window, "on_lines_handler")
    M.find_window:set_event_handlers(M.window_events)

    M.main()
end


function M.previous_match()
    if M.highlighter.matches ~= nil and #M.highlighter.matches > 0 then
        M.reset_search()
        M.highlighter:move_cursor(constants.search.BACKWARD)
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.next_match()
    if M.highlighter.matches ~= nil and #M.highlighter.matches > 0 then
        M.reset_search()
        M.highlighter:move_cursor(constants.search.FORWARD)
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.reset_search()
    M.highlighter:clear_match_count(M.find_window.window_buffer)
    M.highlighter:update_search_results(M.find_window.window_buffer, M.highlighter.match_index, M.highlighter.matches)
end

function M.finder_clear_search()
    vim.api.nvim_buf_set_lines(M.find_window.window_buffer, constants.lines.START, constants.lines.END,
                              true, constants.buffer.EMPTY_BUFFER)
end

function M.toggle()
    M.find_window:toggle()
end

function M.refocus_search()
    if M.find_window:is_open() and vim.api.nvim_win_is_valid(M.find_window.win_id) then
        vim.api.nvim_set_current_win(M.find_window.win_id)
    end
end

function M.resize_finder_window(ev)
    if vim.api.nvim_win_is_valid(M.highlighter.hl_win) then
        local width = vim.api.nvim_win_get_width(M.highlighter.hl_win)
        vim.api.nvim_win_call(M.highlighter.hl_win, function()
            M.find_window:move_window(width)
        end)
    end
end

function M.update_finder_context(ev)
    local enterBuf = ev.buf
    if vim.api.nvim_buf_is_valid(enterBuf) and enterBuf ~= M.find_window.window_buffer then
        M.highlighter:update_hl_context(ev.buf, M.find_window.window_buffer)
    end
end

function M.main()
    vim.api.nvim_create_autocmd({constants.events.WINDOW_RESIZED}, {
        callback = M.resize_finder_window
    })
    vim.api.nvim_create_autocmd({constants.events.WINDOW_LEAVE_EVENT}, {
        callback = function(ev)
            if ev.buf == M.find_window.window_buffer then
                M.highlighter:clear_highlights(M.highlighter.hl_buf)
            end
        end
    })
    vim.api.nvim_create_autocmd({constants.events.BUFFER_ENTER}, {
        callback = M.update_finder_context
    })
    vim.keymap.set('n', '<leader>f', M.toggle, {})
    vim.keymap.set('n', 'f', M.refocus_search, {})
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
    vim.keymap.set('n', 'c', M.finder_clear_search, {
        buffer = M.find_window.window_buffer,
        nowait = true,
        noremap = true,
    })
end
return M
