finder_debug = {}
finder_debug.__index = finder_debug

function finder_debug:new(debug_level, log_function)
    obj = { debug_level = debug_level, log_function = log_function}
    return setmetatable(obj, self)
end
finder_debug.DEBUG_LEVELS = {DEBUG = 0, INFO = 1, WARNING = 2, ERROR = 3, OFF = 4}

-------------------------------------------------------------
--- debug.debug_print: prints the message and optional variable
--- if the config debug level is set to DEBUG
--- @msg: the message to print
--- @variable: optional variable to print
---
function finder_debug:debug_print(msg, variable)
    self:finder_print(self.DEBUG_LEVELS.DEBUG, "[FINDER DBG]: ", msg, variable)
end

-------------------------------------------------------------
--- debug.info_print: prints the message and optional variable
--- only if the config debug level is set to INFO
--- or less
--- @msg: the message to print
--- @variable: optional variable to print
---
function finder_debug:info_print(msg, variable)
    self:finder_print(self.DEBUG_LEVELS.INFO, "[FINDER INFO]: ", msg, variable)
end

-------------------------------------------------------------
--- debug.warning_print: prints the message and optional variable
--- only if the config debug level is set to WARNING
--- or less
--- @msg: the message to print
--- @variable: optional variable to print
---
function finder_debug:warning_print(msg, variable)
    self:finder_print(self.DEBUG_LEVELS.WARNING, "[FINDER WARN]: ", msg, variable)
end

-------------------------------------------------------------
--- debug.error_print: prints the message and optional variable
--- always as it's meant to be used to notify an error to the
--- user
--- or less
--- @msg: the message to print
--- @variable: optional variable to print
---
function finder_debug:error_print(msg, variable)
    self:finder_print(self.DEBUG_LEVELS.ERROR, "[FINDER ERR]: ", msg, variable)
end

-------------------------------------------------------------
--- debug.finder_print: prints the debug message with a prefix
--- after checking if the current debug level should print
--- if the level is greater then the message will print. The
--- passed in variable may be a table and will be inspected
--- before printing automatically
--- @level: the debug level of the print message
--- @prefix: prefix appended to the message before printing
--- @msg: the message to print
--- @variable: the variable to print
---
function finder_debug:finder_print(level, prefix, msg, variable)
    variable = variable or {}
    local dbg_msg = prefix .. msg
    if self:check_debug_level(level) then
        if type(variable) == 'table' then
            if next(variable) ~= nil then
                dbg_msg = dbg_msg .. vim.inspect(variable)
            end

        elseif type(variable) == 'function' then
                dbg_msg = dbg_msg .. vim.inspect(variable)
        else
            dbg_msg = dbg_msg .. variable
        end
        if self.log_function == nil then
            vim.print("Unable to print, nil log function")
        elseif type(self.log_function) ~= 'function' then
            vim.print("Unable to print, internal log function is not a function type " .. type(self.log_function))
        else
            self.log_function(dbg_msg)
        end
    end
end

-------------------------------------------------------------
--- debug.check_debug_level: checks whether or not the debug
--- message should print based on the passed in debug level
--- if the level is greater then the message will print
--- @level: level of debug to comapre against our set level
---
function finder_debug:check_debug_level(level)
    if level == nil then
        vim.print("Nil level ignoring")
        return false
    elseif type(level) ~= "number" then
        vim.print("Type is not number cannot compare")
        return false
    else
        return level >= self.debug_level
    end
end

return finder_debug
