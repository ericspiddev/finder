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
        M.highlighter:move_cursor(constants.search.BACKWARD)
        M.reset_search()
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.next_match()
    if M.highlighter.matches ~= nil and #M.highlighter.matches > 0 then
        M.highlighter:move_cursor(constants.search.FORWARD)
        M.reset_search()
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.reset_search()
    M.highlighter:clear_highlights(M.find_window.window_buffer)
    M.highlighter:update_search_results(M.find_window.window_buffer, M.highlighter.match_index, M.highlighter.matches)
end

function M.finder_clear_search()
    vim.api.nvim_buf_set_lines(M.find_window.window_buffer, constants.lines.START, constants.lines.END,
                              true, constants.buffer.EMPTY_BUFFER)
end

function M.toggle()
    M.find_window:toggle()
end

function M.main()
    vim.api.nvim_create_autocmd({ constants.events.WINDOW_ENTER_EVENT }, {
        callback = function(ev)
            local win = vim.api.nvim_get_current_win() -- this gets the current window....
            if M.find_window.win_id ~= constants.window.INVALID_WINDOW_ID and M.find_window.win_id ~= win then
                M.find_window.highlighter:update_context(win)
                M.highlighter:clear_highlights(M.find_window.window_buffer)
                local finder_col = vim.api.nvim_win_get_position(M.find_window.win_id)[constants.position.COL_INDEX] -- get find window column and where it is
                local new_win_col = vim.api.nvim_win_get_position(win)[constants.position.COL_INDEX] -- if find window id is not win and the event is WinEnter...
                M.find_window:move_window(new_win_col)
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
    vim.keymap.set('n', 'c', M.finder_clear_search, {
        buffer = M.find_window.window_buffer,
        nowait = true,
        noremap = true,
    })
end
return M
