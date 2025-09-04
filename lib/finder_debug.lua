finder_debug = {}
finder_debug.__index = finder_debug

function finder_debug:new(debug_level, log_function)
    obj = { debug_level = debug_level, log_function = log_function}
    return setmetatable(obj, self)
end

DEBUG_LEVELS = {DEBUG = 0, INFO = 1, WARNING = 2, ERROR = 3, OFF = 4}

function finder_debug:debug_print(msg, variable)
    vim.print("debg var is " ..vim.inspect(variable))
    self:finder_print(DEBUG_LEVELS.DEBUG, "[FINDER DBG]: ", msg, variable)
end

function finder_debug:info_print(msg, variable)
    self:finder_print(DEBUG_LEVELS.INFO, "[FINDER INFO]: ", msg, variable)
end

function finder_debug:warning_print(msg, variable)
    self:finder_print(DEBUG_LEVELS.WARNING, "[FINDER WARN]: ", msg, variable)
end

function finder_debug:error_print(msg, variable)
    self:finder_print(DEBUG_LEVELS.ERROR, "[FINDER ERR]: ", msg, variable)
end

function finder_debug:finder_print(level, prefix, msg, variable)
    variable = variable or {}
    local dbg_msg = prefix .. msg
    if self:check_debug_level(level) then
        if type(variable) == 'table' then
            if next(variable) ~= nil then
                dbg_msg = dbg_msg .. vim.inspect(variable)
            end
        else
            dbg_msg = dbg_msg .. variable
        end
        self.log_function(dbg_msg)
    end
end

function finder_debug:check_debug_level(level)
    return level >= self.debug_level
end

return finder_debug
