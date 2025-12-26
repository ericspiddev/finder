local consts = require('lib.consts')
finder_events = {}

finder_events.__index = finder_events
function finder_events:new(valid_events)
    local obj = {
        valid_events = valid_events,
        event_table = {},
        event_buffer_id = consts.buffer.INVALID_BUFFER,
    }
    return setmetatable(obj, self)
end

-------------------------------------------------------------
--- events.add_event: adds an event_handler to the passed in
--- event on the instance table if that event is supported
--- @event_name: name of the event that wants to be registered
--- @instance: instance of object we're adding an event handler to
--- @event_handler: the handler of that will be invoked on each event
---
function finder_events:add_event(event_name, instance, event_handler)

    if not self:is_valid_event(event_name) or event_handler == nil or instance == nil then
        Finder_Logger:error_print("Failed to register event ", event_name)
        if event_handler == nil then
            Finder_Logger:error_print("Nil event handler for event ", event_name)
        elseif instance == nil then
            Finder_Logger:error_print("Nil object instance")
        else
            Finder_Logger:error_print("Unsupported event supported events are ", self.valid_events)
        end
        return false
    end

    if instance[event_handler] == nil then
        Finder_Logger:error_print("Instance is missing function handler with the name ", event_handler)
        return false
    end

    self.event_table[event_name] = function(...)
        instance[event_handler](instance,...)
    end
    Finder_Logger:info_print("Registered event handler for event ", event_name)
    return true
end

function finder_events:attach_buffer_events(buffer)
    if not vim.api.nvim_buf_is_valid(buffer) then
        Finder_Logger:error_print("Cannot attach to invalid nvim buffer ", buffer)
        return false
    elseif self.event_table == nil or next(self.event_table) == nil then
        Finder_Logger:error_print("Failed to attach buffer events empty or nil event table!")
        return false
    else
        -- shockingly there is no cleanup function to this as it's handled in the clenaup
        -- of the buffer so for now no detach though that may change
        local rc = vim.api.nvim_buf_attach(buffer, true, self.event_table)
        if not rc then
            Finder_Logger:error_print("Failed to attach events to buffer ", buffer)
            return false
        end

        self.event_table = {} -- clear
        self.event_buffer_id = buffer
        Finder_Logger:info_print("Successfully attached buffer events")
        return true
    end
end

-------------------------------------------------------------
--- events.is_valid_event: determines whether the event that
--- is attempting to be registered is a supported event
--- @event_name: name of the event that wants to be registered
---
function finder_events:is_valid_event(event_name)
    if self.valid_events == nil then
        Finder_Logger:error_print("Nil valid events table no events will be allowed")
        return false
    end
    for _, name in pairs(self.valid_events) do
        if event_name == name then
            return true
        end
    end
    Finder_Logger:error_print("Unsupported event ", event_name)
    return false
end

return finder_events
