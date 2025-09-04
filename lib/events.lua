finder_events = {}

finder_events.__index = finder_events
function finder_events:new(valid_events)
    local obj = {
        valid_events = valid_events,
        event_table = {}
    }
    return setmetatable(obj, self)
end

function finder_events:add_event(event_name, instance, event_handler)

    if self:is_valid_event(event_name) and event_handler ~= nil then
        self.event_table[event_name] = function(...)
            instance[event_handler](instance,...)
        end
        Finder_Logger:info_print("Registered event handler for event ", event_name)
    else
        Finder_Logger.error_print("Failed to register event ", event_name)
        if event_handler == nil then
            Finder_Logger:error_print("Nil event handler for event ", event_name)
        else
            Finder_Logger:error_print("Unsupported event supported events are ", self.valid_events)
        end
    end
end

function finder_events:is_valid_event(event_name)
    for _, name in ipairs(self.valid_events) do
        if event_name == name then
            return true
        end
    end
    Finder_Logger.error_print("Unsupported event ", event_name)
    return false
end

return finder_events
