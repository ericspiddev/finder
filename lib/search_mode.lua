finder_search_mode = {}
local consts = require("lib.consts")

finder_search_mode.__index = finder_search_mode
function finder_search_mode:new(mode_name, mode_symbol)
    local obj = {
        name = mode_name,
        symbol = mode_symbol,
        banner_window_id = consts.window.INVALID_WINDOW_ID,
        banner_buf = consts.buffer.INVALID_BUFFER,
        search_bar_win = consts.window.INVALID_WINDOW_ID,
        display_col = 0,
        active = false
    }

    return setmetatable(obj, self)
end

function finder_search_mode:show_banner(display_col, banner_width)

    if self.banner_window_id == consts.window.INVALID_WINDOW_ID and self.search_bar_win ~= consts.window.INVALID_WINDOW_ID then
        local banner_config = {
            relative='win',
            row=3,
            col=display_col,
            zindex=1,
            width=10,
            height=1,
            border = {"┌", "─","┐", "│", "┘", "─", "└", "│"},
            --border = { "┌", "─","┐", "│", "┘", "─", "└", "│"},
            focusable=false,
            footer="mod",
            style="minimal",
            win=self.search_bar_win,
        }
        self.display_col = display_col
        vim.print("height is " .. vim.api.nvim_win_get_height(self.search_bar_win))
        self.banner_buf = vim.api.nvim_create_buf(false, true)
        self.banner_window_id = vim.api.nvim_open_win(self.banner_buf, false, banner_config)
        -- TODO create namespace highlights then create extmarks and set them according to each mode's color
        vim.api.nvim_buf_set_lines(self.banner_buf, 0, 1, true, {"" .. self.name ..""})

    end
end

function finder_search_mode:get_banner_display_col()
    if self.display_col > 0 then
        vim.print("Returning col" .. self.display_col)
        return self.display_col
    end
end

function finder_search_mode:hide_banner()
    if self.banner_window_id ~= nil then
        local close_id = self.banner_window_id
        vim.api.nvim_win_close(close_id, false)
        vim.api.nvim_buf_delete(self.banner_buf, {force = true})
        self.banner_window_id = consts.window.INVALID_WINDOW_ID
        self.banner_buf = consts.buffer.INVALID_BUFFER
    end
end

return finder_search_mode
