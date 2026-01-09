finder_highlighter = {}
finder_highlighter.__index = finder_highlighter
local consts = require("lib.consts")
local match_obj = require("lib.match")

function finder_highlighter:new(editor_window, result_hl_style, selected_hl_style, hl_namespace, mode_mgr)
    local obj = {
        hl_buf = vim.api.nvim_win_get_buf(editor_window),
        hl_win = editor_window,
        hl_context = consts.buffer.NO_CONTEXT,
        hl_namespace = hl_namespace,
        result_hl_style = result_hl_style,
        selected_hl_style = selected_hl_style,
        hl_fns = self:get_hl_fns(),
        hl_wc_ext_id = consts.highlight.NO_WORD_COUNT_EXTMARK,
        matches = {},
        match_index = 1,
        mode_mgr = mode_mgr
    }
    return setmetatable(obj, self)
end

-------------------------------------------------------------
--- highlighter.get_hls_fns: gets highlight functions table
--- that is responsible for any highlight operations this
--- table currently returns extmark api functions
--- operation           function
--- highlight           nvim_buf_set_extmark
--- get_highlights      nvim_buf_get_extmarks
--- remove              nvim_buf_del_extmark
---
function finder_highlighter:get_hl_fns()
    local fns = {
        highlight = vim.api.nvim_buf_set_extmark,
        get_all_highlights = vim.api.nvim_buf_get_extmarks, -- (highlightBuf, finderNamespace, 0, -1, {})
        remove_highlight = vim.api.nvim_buf_del_extmark
    }
    return fns
end

-------------------------------------------------------------
--- highlight.update_hl_context: clears the search
--- result numbers in the search_bar and then reads the buffer
--- id into hl_context field
--- @hl_buf: the buffer that will have it's contents loaded into hl_context
--- @finder_buf: search bar buffer this is used to clear search numbers
--- (rename to query_buffer or use buf directly?)
--- @return: whether or not the context was updated
---
function finder_highlighter:update_hl_context(hl_buf, finder_buf)
    self:clear_match_count(finder_buf)
    return self:populate_hl_context(hl_buf)
end

-------------------------------------------------------------
--- highlighter.populate_hl_context: loads the content of the
--- buffer into the 'hl_context' field. This field is used
--- when seraching for the pattern in the query buffer
--- @buf_id: the buffer to load into highlight context field
--- @return: whether or not the context was populated
---
function finder_highlighter:populate_hl_context(buf_id)
    if not vim.api.nvim_buf_is_valid(buf_id) then
        Finder_Logger.warning_print("Attempting to populate context with invalid buffer id")
        self.hl_context = consts.buffer.NO_CONTEXT
        self.hl_buf = consts.buffer.INVALID_BUFFER
        return false
    end
    local total_lines = vim.api.nvim_buf_line_count(buf_id)
    if total_lines > 0 then
        self.hl_buf = buf_id
        self.hl_win = vim.fn.bufwinid(buf_id)

        Finder_Logger:debug_print("Populating context with " .. total_lines .. " total lines")

        Finder_Logger:debug_print("Populating context with " .. total_lines .. " total lines")
        self.hl_context = vim.api.nvim_buf_get_lines(buf_id, consts.lines.START, total_lines, false)
        Finder_Logger:debug_print("HL context set too " .. vim.inspect(self.hl_context))
        return true
    else
        Finder_Logger:warning_print("No valid lines found to populate highlight context")
        self.hl_context = consts.buffer.NO_CONTEXT
        self.hl_buf = consts.buffer.INVALID_BUFFER
        return false
    end
end

-------------------------------------------------------------
--- highlight.highlight_file_by_pattern: highlights the current
--- hl_context if it matches the pattern. It also updates the
--- search_results virtual text in the search buffer
--- @win_buf: the buffer to update the search results ex (3/5) in
--- @pattern: the pattern to highlight within the hl_context
---
function finder_highlighter:highlight_file_by_pattern(win_buf, pattern)

    if pattern == nil or pattern == "" then
        Finder_Logger:warning_print("Nil or empty pattern cancelling search")
        return
    end
    if self.hl_context == consts.buffer.NO_CONTEXT then
        Finder_Logger:warning_print("No context to search through")
        return
    end

    local exact_match = self.mode_mgr:apply_regex_mode()

    for line_number, line in ipairs(self.hl_context) do
        local search_index = 1
        line, pattern = self.mode_mgr:apply_modes_to_search_text(line, pattern)

        local pattern_start, pattern_end = string.find(line, pattern, 1, exact_match) -- find the pattern here...
        while pattern_start ~= nil do
            -- highlight with start index and end index
            self:highlight_pattern_in_line(line_number - 1, pattern_start - 1, pattern_end)
            search_index = pattern_end + 1
            pattern_start, pattern_end = string.find(line, pattern, search_index, exact_match) -- hmmm
        end
    end
    if #self.matches > 0 then
        --vim.print("matches > 0... index is " .. self.match_index .. " and matches holds " .. #self.matches)
        self:update_match_count(win_buf)
    end
end

-------------------------------------------------------------
--- highlighter.clear_match_count: clear the match count that
--- tracks current search result in the search window
--- @buffer: the buffer that the match count is present in (query buf)
---
function finder_highlighter:clear_match_count(buffer)
    if self.hl_wc_ext_id ~= consts.highlight.NO_WORD_COUNT_EXTMARK
    and buffer ~= nil
    and vim.api.nvim_buf_is_valid(buffer) then
        self.hl_fns.remove_highlight(buffer, self.hl_namespace, self.hl_wc_ext_id)
        self.hl_wc_ext_id = consts.highlight.NO_WORD_COUNT_EXTMARK
    end
end

--------------------------------------------------------------
--- highlighter.update_match_count: responsible for updating
--- the virt text with the current match index e.x(3/5) that shows
--- in the search bar buffer
--- @buffer: the buffer where the search count is located (query_buffer)
---
function finder_highlighter:update_match_count(buffer)
    local match = self.match_index
    local match_list = self.matches
    if match ~= nil and match > -1
        and match_list ~= nil and #match_list > 0
        and match <= #match_list
        and buffer ~= consts.buffer.INVALID_BUFFER then
       local virt_text_str = match .. "/" .. #match_list
       self.hl_wc_ext_id = self.hl_fns.highlight(buffer, self.hl_namespace, 0, -1, {
            virt_text = { { virt_text_str, "Comment" } },
            virt_text_pos = "right_align",
        })
        return virt_text_str
    end
end

--------------------------------------------------------------
--- highlighter.highlight_pattern_in_line: using the line number
--- and start/end of the word this highlights the word on that
--- line and then creates a new match object and inserts it
--- into the self.matches table for bookkeeping of all matches
--- @line_number: the line number (row) that the word is located on
--- @word_start: start index (col) of the word on the line
--- @word_end: end index (col) of the word on the line
---
function finder_highlighter:highlight_pattern_in_line(line_number, word_start, word_end)
    local extmark_id = self.hl_fns.highlight(self.hl_buf, self.hl_namespace, line_number, word_start,
        { end_col = word_end, hl_group = self.result_hl_style })
    table.insert(self.matches, match_obj:new(line_number + 1, word_start, word_end, extmark_id))
end

-------------------------------------------------------------
--- highligher.move_cursor: moves the user's cursor along matched
--- patterns throughout the hl_context it also updates the current
--- search result to be highlighted differently to show it's selected
--- @direction: which way to iterate through matches (forward or backward)
---
function finder_highlighter:move_cursor(index)
    if not index then
        Finder_Logger:error_print("Nil index!")
        return
    end
    if index <= 0 or index > #self.matches then
        Finder_Logger:error_print("Invalid index: ", index)
        return
    end

    if self.hl_win == consts.window.INVALID_WINDOW_ID then
        Finder_Logger:error_print("Invalid window id to move cursor through" )
        return
    end

    local buf_window = vim.fn.bufwinid(self.hl_buf)
    if self.hl_win ~= buf_window then
        Finder_Logger:warning_print("Window id holding buffer and stored highlight window mismatch!")
        Finder_Logger:warning_print("Expected to move cursor for window ", buf_window)
        Finder_Logger:warning_print("Actually moving through ", self.hl_win)
    end

    self:set_match_highlighting(self.matches[self.match_index], self.result_hl_style)
    self.match_index = index

    local match = self.matches[self.match_index]

    self.hl_fns.remove_highlight(self.hl_buf, self.hl_namespace, match.extmark_id)
    vim.api.nvim_win_set_cursor(self.hl_win, {match:get_cursor_row(), match.m_start})
    self:set_match_highlighting(match, self.selected_hl_style)
    vim.api.nvim_buf_call(self.hl_buf, function () vim.cmd(consts.cmds.CENTER_SCREEN) end)
    return true
end

-------------------------------------------------------------
--- highligher.set_match_highlighting:
--- patterns throughout the hl_context it also updates the current
--- search result to be highlighted differently to show it's selected
--- @match: which way to iterate through matches (forward or backward)
--- @hl: the style to highlight the passed in match
--- (move me to match class??? weird spot with this one)
function finder_highlighter:set_match_highlighting(match, hl)
    if match ~= nil then
        local ext_id = self.hl_fns.highlight(self.hl_buf, self.hl_namespace, match:get_highlight_row(), match.m_start,
        { id = match.extmark_id, end_col = match.m_end, hl_group = hl })
        match:update_extmark_id(ext_id)
    end
end

-------------------------------------------------------------
--- highlighter.get_buffer_current_hls: gets all of the current
--- highlighted text extmarks and loads them into a table this
--- only effects extmarks this class sets because of the namespace
--- @buffer: the buffer with the highlight extmarks to retrieve
---
function finder_highlighter:get_buffer_current_hls(buffer)
    local ids = {}
    if buffer == nil or not vim.api.nvim_buf_is_valid(buffer) then
        Finder_Logger:warning_print("Invalid buffer to serach", buffer)
        return nil
    end
    if self.matches ~= nil then
        for _, match in ipairs(self.matches) do
            table.insert(ids, match.extmark_id)
        end
    end
    return ids
end

function finder_highlighter:get_closest_match(search_direction)
    if #self.matches == 0 then
        return nil
    end

    local cursor_pos = vim.api.nvim_win_get_cursor(self.hl_win)
    local line = cursor_pos[1]
    local w_start = cursor_pos[2]
    local index
    local curr_match

    if search_direction == consts.search.FORWARD then
        if self.matches[#self.matches].row == line and self.matches[#self.matches].m_start == w_start then
            return 1
        end
        index = 1
        curr_match = self.matches[index]
        while(curr_match.row < line and index < #self.matches) do
            index = index + 1
            curr_match = self.matches[index]
        end

        while(curr_match.row == line
            and curr_match.m_start <= w_start
            and index < #self.matches) do
                index = index + 1
                curr_match = self.matches[index]
        end
    elseif search_direction == consts.search.BACKWARD then
        if self.matches[1].row == line and self.matches[1].m_start == w_start then
            return #self.matches
        end

        index = #self.matches
        curr_match = self.matches[index]
        while(curr_match.row > line and index > 1) do
            index = index - 1
            curr_match = self.matches[index]
        end

        while(curr_match.row == line
            and curr_match.m_start >= w_start
            and index > 1) do
                index = index - 1
                curr_match = self.matches[index]
        end
    end

    return index
end

-------------------------------------------------------------
--- highlighter.clear_highlights: clears all of the currently
--- highlighted text in a buffer. Also clears the match_count
--- in the search window
--- @hl_buf: buffer that is currently being searched (likely shown in current window)
--- @win_buf: query buffer that holds the match count e.x. (3/5)
---
function finder_highlighter:clear_highlights(hl_buf, win_buf)
    self:clear_match_count(win_buf)
    for _, match_id in ipairs(self:get_buffer_current_hls(hl_buf)) do
        self.hl_fns.remove_highlight(self.hl_buf, self.hl_namespace, match_id)
    end
end

function finder_highlighter:dump_context()
    vim.print("Dump context: ")
    if self.hl_context ~= nil then
        for line_number, line in ipairs(self.hl_context) do
            vim.print("Line " .. line_number .. " :" .. line .. "total cols: " .. #line)
        end
    end

    vim.print("----------------------------------------")
    vim.print("Dump window: " .. self.hl_win)
    if vim.api.nvim_win_is_valid(self.hl_win) then
        local buf = vim.api.nvim_win_get_buf(self.hl_win)
        if vim.api.nvim_buf_is_valid then
            local total_lines = vim.api.nvim_buf_line_count(buf)
            for line_number, line in ipairs(vim.api.nvim_buf_get_lines(buf, consts.lines.START, total_lines, false)) do
                vim.print("Line " .. line_number .. " :" .. line .. "total cols: " .. #line)
            end
        end
    end
end

return finder_highlighter
