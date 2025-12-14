finder_match = {}

finder_match.__index = finder_match
function finder_match:new(line, word_start, word_end, ext_mark_id)
    local obj = {
        row = line,
        m_start = word_start,
        m_end = word_end,
        extmark_id = ext_mark_id
    }
    return setmetatable(obj, self)
end

function finder_match:update_extmark_id(new_id)
    self.extmark_id = new_id
end

return finder_match

