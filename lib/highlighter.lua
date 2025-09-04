finder_highlighter = {}
finder_highlighter.__index = finder_highlighter

function finder_highlighter:new(hl_buf, hl_win, hl_namespace, hl_style)
    local obj = {
        hl_buf = hl_buf,
        hl_win = hl_win,
        hl_context = 0,
        hl_namespace = hl_namespace,
        hl_style = hl_style,
        hl_fns = self:get_hl_fns(),
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

function finder_highlighter:update_context(window)
    self:populate_hl_context(vim.api.nvim_win_get_buf(window))
end

function finder_highlighter:populate_hl_context(buf_id)
    self.hl_buf = buf_id
    local total_lines = vim.api.nvim_buf_line_count(buf_id)
    self.hl_context = vim.api.nvim_buf_get_lines(0, 0, total_lines, false)
end

function finder_highlighter:highlight_file_by_pattern(win_buf, pattern)
    if pattern == nil then
        Finder_Logger:warning_print("Nil pattern cancelling search")
        return
    end
    for line_number, line in ipairs(self.hl_context) do
        local pattern_start, pattern_end = string.find(line, pattern)
        if pattern_start then
            self:highlight_pattern_in_line(line_number -1, pattern_start -1, pattern_end) -- highlight with start index and end index
        end
    end
    if #self.matches > 0 then
        self:update_search_results(win_buf, self.match_index, self.matches)
    end
end

function finder_highlighter:update_search_results(buffer, curr, list)
    if curr ~= nil and curr > -1 and list ~= nil and #list > 0 then
        self.hl_fns.highlight(buffer, self.hl_namespace, 0, -1, {
            virt_text = { {curr .. "/" .. #list, "Comment"}},
            virt_text_pos = "right_align",
        })
    end
end

-- If I were calling this function how would I like to call it...?
function finder_highlighter:highlight_pattern_in_line(line_number, word_start, word_end)
    self.hl_fns.highlight(self.hl_buf, self.hl_namespace, line_number, word_start, {end_col=word_end, hl_group=self.hl_style})
    table.insert(self.matches, {line_number + 1, word_start})
end

function finder_highlighter:move_cursor()
    self.match_index = ((self.match_index % #self.matches)) + 1
    vim.api.nvim_win_set_cursor(self.hl_win, self.matches[self.match_index]) -- hmmmm
    vim.api.nvim_win_call(self.hl_win, function()
        vim.cmd("norm! zz")
    end)
end
 -- returns ID of all highlights (could be expanded if needed)
function finder_highlighter:get_buffer_current_hls(buffer)
    local ids = {}
    ID_INDEX = 1
    for _, highlight in ipairs(self.hl_fns.get_all_highlights(buffer, self.hl_namespace, 0, -1, {})) do
        table.insert(ids, highlight[ID_INDEX])
    end
    return ids
end

function finder_highlighter:clear_highlights(buffer)
    for _, highlight in ipairs(self:get_buffer_current_hls(buffer)) do
        self.hl_fns.remove_highlight(buffer, self.hl_namespace, highlight)
    end
end

return finder_highlighter
