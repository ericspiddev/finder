local events = require("plugins.custom.finder.lib.events")
local search_bar = require("plugins.custom.finder.lib.search_bar")
local constants = require("plugins.custom.finder.lib.consts")
local M = {}

function M.setup(config)

    _G.Finder_Logger = require("plugins.custom.finder.lib.finder_debug"):new(config.debug_level, vim.print)
    local search_bar_config = {
        relative='editor',
        row=0,
        zindex=1,
        focusable=true,
        height=1,
        style="minimal",
        border={ "╔", "═","╗", "║", "╝", "═", "╚", "║" }, -- double border for now fix me later
        title_pos="center",
        title="Search"
    }

    Finder_Logger:debug_print("window: making a new window with config ", search_bar_config)

    M.search_bar = search_bar:new(search_bar_config, config.width_percentage, true)
    M.search_bar.highlighter:populate_hl_context(constants.window.CURRENT_WINDOW)
    M.window_events = events:new(search_bar.VALID_WINDOW_EVENTS)
    M.window_events:add_event("on_lines", M.search_bar, "on_lines_handler")
    M.search_bar:set_event_handlers(M.window_events)

    M.main()
end

function M.previous_match()
    if M.search_bar.highlighter.matches ~= nil and #M.search_bar.highlighter.matches > 0 then
        M.reset_search()
        M.search_bar.highlighter:move_cursor(constants.search.BACKWARD)
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.next_match()
    if M.search_bar.highlighter.matches ~= nil and #M.search_bar.highlighter.matches > 0 then
        M.reset_search()
        M.search_bar.highlighter:move_cursor(constants.search.FORWARD)
    else
        Finder_Logger:debug_print("Matches is either undefined or empty ignoring enter")
    end
end

function M.reset_search()
    M.search_bar.highlighter:clear_match_count(M.search_bar.query_buffer)
    M.search_bar.highlighter:update_search_results(M.search_bar.query_buffer, M.search_bar.highlighter.match_index, M.search_bar.highlighter.matches)
end

function M.finder_clear_search()
    vim.api.nvim_buf_set_lines(M.search_bar.query_buffer, constants.lines.START, constants.lines.END,
                              true, constants.buffer.EMPTY_BUFFER)
end

function M.toggle()
    M.search_bar:toggle()
end

function M.refocus_search()
    if M.search_bar:is_open() and vim.api.nvim_win_is_valid(M.search_bar.win_id) then
        vim.api.nvim_set_current_win(M.search_bar.win_id)
    end
end

function M.resize_finder_window(ev)
    if vim.api.nvim_win_is_valid(M.search_bar.highlighter.hl_win) then
        local width = vim.api.nvim_win_get_width(M.search_bar.highlighter.hl_win)
        vim.api.nvim_win_call(M.search_bar.highlighter.hl_win, function()
            M.search_bar:move_window(width)
        end)
    end
end

function M.update_finder_context(ev)
    local enterBuf = ev.buf
    if vim.api.nvim_buf_is_valid(enterBuf) and enterBuf ~= M.search_bar.query_buffer then
        M.search_bar.highlighter:update_hl_context(ev.buf, M.search_bar.query_buffer)
    end
end

function M.main()
    vim.api.nvim_create_autocmd({constants.events.WINDOW_RESIZED}, {
        callback = M.resize_finder_window
    })
    vim.api.nvim_create_autocmd({constants.events.WINDOW_LEAVE_EVENT}, {
        callback = function(ev)
            if ev.buf == M.search_bar.query_buffer then
                M.search_bar.highlighter:clear_highlights(M.search_bar.highlighter.hl_buf)
            end
        end
    })
    vim.api.nvim_create_autocmd({constants.events.BUFFER_ENTER}, {
        callback = M.update_finder_context
    })
    vim.keymap.set('n', '<leader>f', M.toggle, {})
    vim.keymap.set('n', 'f', M.refocus_search, {})
    vim.keymap.set('n', '<CR>', M.next_match, {
        buffer = M.search_bar.query_buffer,
        nowait = true,
        noremap = true,
    })
    vim.keymap.set('n', '<leader><CR>', M.previous_match, {
        buffer = M.search_bar.query_buffer,
        nowait = true,
        noremap = true,
    })
    vim.keymap.set('n', 'c', M.finder_clear_search, {
        buffer = M.search_bar.query_buffer,
        nowait = true,
        noremap = true,
    })
end
return M
