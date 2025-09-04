
finder_searcher = {}
finder_searcher.__index = finder_searcher

function finder_searcher:new(highlighter)
    local obj = {
        highlighter = highlighter
    }
    return setmetatable(obj, self)
end

function finder_searcher:search_text(line, pattern) -- search text
    return string.find(line, pattern)
end

function finder_searcher:highlight_text()
    if start_idx then
        M.highlight(fileBuf, index, start_idx, end_idx)
    end
end

function clear_search()

end

return finder_searcher
