local search_bar = require("nvim-scout.lib.search_bar")
local consts = require("nvim-scout.lib.consts")
local M = {}

function M.setup(user_options)

    _G.Scout_Logger = require("nvim-scout.lib.scout_logger"):new(user_options.log_level, vim.print, vim.notify)
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

    --Scout_Logger:debug_print("window: making a new window with config ", search_bar_config)

    M.search_bar = search_bar:new(search_bar_config, user_options.width_percentage, true)
    M.search_bar.highlighter:populate_hl_context(consts.window.CURRENT_WINDOW)
    M.main()
end

function M.toggle()
    M.search_bar:toggle()
end

function M.refocus_search()
    if M.search_bar:is_open() and vim.api.nvim_win_is_valid(M.search_bar.win_id) then
        vim.api.nvim_set_current_win(M.search_bar.win_id)
    end
end

function M.resize_scout_window(ev)
    if vim.api.nvim_win_is_valid(M.search_bar.highlighter.hl_win) then
        local width = vim.api.nvim_win_get_width(M.search_bar.highlighter.hl_win)
        vim.api.nvim_win_call(M.search_bar.highlighter.hl_win, function()
            M.search_bar:move_window(width)
        end)
    end
end

function M.update_scout_context(ev)
    local enterBuf = ev.buf
    if vim.api.nvim_buf_is_valid(enterBuf) and enterBuf ~= M.search_bar.query_buffer then
        M.search_bar.highlighter:update_hl_context(ev.buf, M.search_bar.query_buffer)
    end
end

function M.main()
    vim.api.nvim_create_autocmd({consts.events.WINDOW_RESIZED}, {
        callback = M.resize_scout_window
    })
    vim.api.nvim_create_autocmd({consts.events.WINDOW_LEAVE_EVENT}, {
        callback = function(ev)
            if ev.buf == M.search_bar.query_buffer then
                M.search_bar.highlighter:clear_highlights(M.search_bar.highlighter.hl_buf)
            end
        end
    })
    vim.api.nvim_create_autocmd({consts.events.BUFFER_ENTER}, {
        callback = M.update_scout_context
    })

    vim.keymap.set('n', '/', M.toggle, {}) -- likely change for obvious reasons later
    vim.keymap.set('n', 'f', M.refocus_search, {})
end
return M
