finder_highlighter = {}
finder_highlighter.__index = finder_highlighter
local constants = require("plugins.custom.finder.lib.consts")
local match_obj = require("plugins.custom.finder.lib.match")

function finder_highlighter:new(editor_window, result_hl_style, selected_hl_style )
    local obj = {
        hl_buf = vim.api.nvim_win_get_buf(editor_window),
        hl_win = editor_window,
        hl_context = constants.buffer.NO_CONTEXT,
        hl_namespace = vim.api.nvim_create_namespace(constants.highlight.FINDER_NAMESPACE),
        result_hl_style = result_hl_style,
        selected_hl_style = selected_hl_style,
        hl_fns = self:get_hl_fns(),
        hl_wc_ext_id = constants.highlight.NO_WORD_COUNT_EXTMARK,
        matches = {},
        match_index = 0
    }
    return setmetatable(obj, self)
end

function finder_highlighter:get_hl_fns()
    local fns = {
        highlight = vim.api.nvim_buf_set_extmark,
        get_all_highlights = vim.api.nvim_buf_get_extmarks, -- (highlightBuf, finderNamespace, 0, -1, {})
        remove_highlight = vim.api.nvim_buf_del_extmark
    }
    return fns
end

function finder_highlighter:update_hl_context(hl_buf, finder_buf)
    self:clear_match_count(finder_buf)
    self:populate_hl_context(hl_buf)
end

function finder_highlighter:populate_hl_context(buf_id)
    if not vim.api.nvim_buf_is_valid(buf_id) then
        Finder_Logger.warning_print("Attempting to populate context with invalid buffer id")
        return
    end
    self.hl_buf = buf_id
    local total_lines = vim.api.nvim_buf_line_count(buf_id)
    if total_lines > 0 then
        Finder_Logger:debug_print("Populating context with " .. total_lines .. " total lines")
        self.hl_context = vim.api.nvim_buf_get_lines(buf_id, constants.lines.START, total_lines, false)
        Finder_Logger:debug_print("HL context set too " .. vim.inspect(self.hl_context))
    else
        Finder_Logger:warning_print("No valid lines found to populate highlight context")
        self.hl_context = constants.buffer.NO_CONTEXT
    end
end

function finder_highlighter:highlight_file_by_pattern(win_buf, pattern)

    if pattern == nil then
        Finder_Logger:warning_print("Nil pattern cancelling search")
        return
    end
    if self.hl_context == constants.buffer.NO_CONTEXT then
        Finder_Logger:warning_print("No context to search through")
        return
    end
    for line_number, line in ipairs(self.hl_context) do
        local search_index = 1
        local pattern_start, pattern_end = string.find(line, pattern)
        while pattern_start ~= nil and pattern ~= "" do
            self:highlight_pattern_in_line(line_number - 1, pattern_start - 1, pattern_end) -- highlight with start index and end index
            search_index = pattern_end + 1
            pattern_start, pattern_end = string.find(line, pattern, search_index)
        end
    end

    if #self.matches > 0 and pattern ~= "" then
        vim.print("matches > 0... index is " .. self.match_index .. " and matches holds " .. #self.matches)
        self:update_search_results(win_buf, self.match_index, self.matches)
    end
end

function finder_highlighter:clear_match_count(buffer)
    if self.hl_wc_ext_id ~= constants.highlight.NO_WORD_COUNT_EXTMARK
        and buffer ~= nil
        and vim.api.nvim_buf_is_valid(buffer) then
        self.hl_fns.remove_highlight(buffer, self.hl_namespace, self.hl_wc_ext_id)
        self.hl_wc_ext_id = constants.highlight.NO_WORD_COUNT_EXTMARK
    end
end

function finder_highlighter:update_search_results(buffer, match_index, list)
    if match_index ~= nil and match_index > -1 and list ~= nil and #list > 0 and buffer ~= constants.buffer.INVALID_BUFFER then
       self.hl_wc_ext_id = self.hl_fns.highlight(buffer, self.hl_namespace, 0, -1, {
            virt_text = { { match_index .. "/" .. #list, "Comment" } },
            virt_text_pos = "right_align",
        })
    end
end

function finder_highlighter:highlight_pattern_in_line(line_number, word_start, word_end)
    local extmark_id = self.hl_fns.highlight(self.hl_buf, self.hl_namespace, line_number, word_start,
        { end_col = word_end, hl_group = self.result_hl_style })
    table.insert(self.matches, match_obj:new(line_number + 1, word_start, word_end, extmark_id))
end

function finder_highlighter:move_cursor(direction)
    self:set_match_highlighting(self.matches[self.match_index], self.result_hl_style)
    self.match_index = ((self.match_index + direction) % (#self.matches + 1))
    if self.match_index < 1 then
        if direction == -1 then
            self.match_index = #self.matches
        else
            self.match_index = 1
        end
    end
    local match = self.matches[self.match_index]
    self.hl_fns.remove_highlight(self.hl_buf, self.hl_namespace, match.extmark_id)
    vim.api.nvim_win_set_cursor(self.hl_win, {match.row, match.m_start})
    self:set_match_highlighting(match, self.selected_hl_style)
    vim.cmd(constants.cmds.CENTER_SCREEN) -- center the screen on our cursor?
end

function finder_highlighter:set_match_highlighting(match, hl)
    if match ~= nil then
        local ext_id = self.hl_fns.highlight(self.hl_buf, self.hl_namespace, match.row -1, match.m_start,
        { id = match.extmark_id, end_col = match.m_end, hl_group = hl })
        match:update_extmark_id(ext_id)
    end
end

-- returns ID of all highlights (could be expanded if needed)
function finder_highlighter:get_buffer_current_hls(buffer)
    local ids = {}
    ID_INDEX = 1
    if buffer == nil or not vim.api.nvim_buf_is_valid(buffer) then
        Finder_Logger:warning_print("Invalid buffer to serach", buffer)
        return
    end
    for _, highlight in ipairs(self.hl_fns.get_all_highlights(buffer, self.hl_namespace, 0, -1, {})) do
        table.insert(ids, highlight[ID_INDEX])
    end
    return ids
end

function finder_highlighter:clear_highlights(hl_buf, win_buf)
    self:clear_match_count(win_buf)
    for _, highlight in ipairs(self:get_buffer_current_hls(hl_buf)) do
        self.hl_fns.remove_highlight(self.hl_buf, self.hl_namespace, highlight)
    end
end

return finder_highlighter
