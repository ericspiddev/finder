finder_pattern_handler = {}
finder_pattern_handler.__index = finder_pattern_handler


function finder_pattern_handler:new(escape_chars)
    local obj = {
        escape_chars = escape_chars
    }
    return setmetatable(obj, self)
end


function finder_pattern_handler:wait_to_search(pattern)
    local delay = false
    local open_count = 0
    local close_count = 0
    if string.sub(pattern, -1) == "%" then -- lua patterns can't end with %
        delay = true
    end
    for index = 1, #pattern do
        local char = pattern:sub(index, index)
        if char == "[" then
            open_count = open_count + 1
        elseif char == "]" then
            close_count = close_count + 1
        end
     end
    if open_count ~= close_count then
        delay = true
    end

    return delay
end

function finder_pattern_handler:escape_pattern_characters(pattern)

    for _, escape_char in ipairs(self.escape_chars) do
        pattern = string.gsub(pattern,"%" .. escape_char, "%%".. escape_char)
    end

    return pattern
end

return finder_pattern_handler
