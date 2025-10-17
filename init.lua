local events = require("finder.lib.events")
local window = require("finder.lib.window")
local highlighter = require("finder.lib.highlighter")
local M = {}

function M.setup(config)

    _G.Finder_Logger = require("finder.lib.finder_debug"):new(config.debug_level, vim.print)
    local win_config = {
        relative='win',
        row=0,
        col=50, -- TODO: come back to me
        width=100,
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
    local hl_buf = vim.api.nvim_win_get_buf(0) -- get current window's buffer
    local hl_win = vim.api.nvim_get_current_win()
    local hl_namespace = vim.api.nvim_create_namespace("finder")
    local test_w = vim.api.nvim_win_get_width(hl_win)
    vim.print("Test w is " .. test_w)
    local test_h = vim.api.nvim_win_get_height(hl_win)
    win_config.col = 98
    vim.print("Test h is " .. test_h)

    vim.print("Win position is " .. vim.inspect(vim.api.nvim_win_get_position(hl_win)))

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
        Finder_Logger:debug_print("Current index ", M.highlighter.match_index)
        Finder_Logger:debug_print("Current matches ", M.highlighter.matches)
        M.highlighter:clear_highlights(M.find_window.window_buffer)
        M.highlighter:update_search_results(M.find_window.window_buffer, M.highlighter.match_index, M.highlighter.matches)
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.next_match()
    if M.highlighter.matches ~= nil and #M.highlighter.matches > 0 then
        M.highlighter:move_cursor()
        Finder_Logger:debug_print("Current index ", M.highlighter.match_index)
        Finder_Logger:debug_print("Current matches ", M.highlighter.matches)
        M.highlighter:clear_highlights(M.find_window.window_buffer)
        M.highlighter:update_search_results(M.find_window.window_buffer, M.highlighter.match_index, M.highlighter.matches)
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.clear_search()
    vim.api.nvim_buf_set_lines(M.find_window.window_buffer, 0, -1, false, {})
end

function M.toggle()
    M.find_window:toggle()
end

function M.main()
    vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave" }, {
        callback = function(ev)
            local win = vim.api.nvim_get_current_win() -- this gets the current window....
            if M.find_window.win_id ~= win and ev.event == "WinEnter" then
                M.find_window.highlighter:update_context(win)
                M.highlighter:clear_highlights(M.find_window.window_buffer)
                local finder_col = vim.api.nvim_win_get_position(M.find_window.win_id)[2] -- get find window column and where it is
                local new_win_col = vim.api.nvim_win_get_position(win)[2] -- if find window id is not win and the event is WinEnter...
                vim.print("Finder pos is " .. vim.inspect(finder_col))
                vim.print("New window pos " .. vim.inspect(new_win_col))
                --vim.print("Event Win position is " .. vim.inspect(vim.api.nvim_win_get_position(win)))
                if new_win_col >= finder_col then
                    M.find_window:move_window(new_win_col)
                end
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
