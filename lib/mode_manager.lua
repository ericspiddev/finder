finder_mode_manager = {}
local consts = require("lib.consts")
local search_mode = require("lib.search_mode")

finder_mode_manager.__index = finder_mode_manager
function finder_mode_manager:new()
local modes = {}

    modes[consts.modes.regex] = search_mode:new("Regex", "R")
    modes[consts.modes.case_sensitive] = search_mode:new("Match Case", "C")

    local obj = {
        modes = modes,
        display_col = 1
    }

    return setmetatable(obj, self)
end

-- when each mode is active we should display a little window with a letter
-- toggling it to off should hide that window

function finder_mode_manager:validate_mode(mode_index)
    if self.modes[mode_index] == nil then
        Finder_Logger:error_print("Attempting to perform an operation on an unsupported mode")
        return false
    end
    return true
end

function finder_mode_manager:toggle_mode(mode_index)
    if not self:validate_mode(mode_index) then
        Finder_Logger:error_print("Cannot toggle mode")
        return
    end
    local target_mode = self.modes[mode_index] -- validated so should be ok to just use here
    if target_mode.active then
        self.display_col = target_mode:get_banner_display_col()
        target_mode:hide_banner()
    else
        target_mode:show_banner(self.display_col)
        self.display_col = self.display_col + 10
    end
    target_mode.active = not target_mode.active
end

function finder_mode_manager:set_mode(mode, value)
    if not self:validate_mode(mode) then
        Finder_Logger:error_print("Cannot set mode")
        return
    end
    self.modes[mode].active = value
end

function finder_mode_manager:get_mode(mode)
    if not self:validate_mode(mode) then
        Finder_Logger:error_print("Cannot get mode's value")
        return
    end
    return self.modes[mode].active
end

function finder_mode_manager:update_relative_window(win_id)
    local new_window = nil
    if vim.api.nvim_win_is_valid(win_id) then
        new_window = win_id
    else
        new_window = consts.window.INVALID_WINDOW_ID
    end

    if self.modes ~= nil then
        for _, mode in pairs(self.modes) do
            mode.search_bar_win = new_window
        end
    end
end

function finder_mode_manager:close_all_modes()
    if self.modes ~= nil then
        for _, mode in pairs(self.modes) do
            if mode.active then
                mode:hide_banner()
                mode.active = false
            end
        end
    end
end

function finder_mode_manager:apply_modes_to_search_text(line, pattern)
    if not self.modes[consts.modes.case_sensitive].active then
        line = string.lower(line)
        pattern = string.lower(pattern)
    end
    return line, pattern
end

function finder_mode_manager:apply_regex_mode()
    -- when set to false pattern matching is used when set to true only exact matches are shown...
    return not self.modes[consts.modes.regex].active
end
return finder_mode_manager
