finder_match = {}

finder_match.__index = finder_match
function finder_match:new(line, word_start, word_end)
    local obj = {
        row = line,
        m_start = word_start,
        m_end = word_end,
    }
    return setmetatable(obj, self)
end

return finder_match

