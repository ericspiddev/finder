local debug = require('lib.finder_debug')
local mock = require('luassert.mock')
local match = require('luassert.match')
local consts = require('lib.consts')
local search_mode = require('lib.search_mode')
spec_utils = {}

spec_utils.__index = spec_utils
local mock_debug = nil

function spec_utils:compare_matches(m1, m2)
    if not (m1.row == m2.row and
            m1.m_start == m2.m_start and
            m1.m_end == m2.m_end) then
        vim.print("Match 1 is " .. vim.inspect(m1))
        vim.print("Match 2 is " .. vim.inspect(m2))
    else
        return true
    end
end

function spec_utils:table_contains(table, check)
   for _, value in pairs(table) do
        if value == check then
            return true
        end
    end
    return false
end

function spec_utils:mock_debug_prints()
    mock_debug = mock(debug, true)
    mock_debug.debug_print.returns()
    mock_debug.info_print.returns()
    mock_debug.warning_print.returns()
    mock_debug.error_print.returns()
end

function spec_utils:lists_are_equal(t1, t2)
    if #t1 ~= #t2 then
        return false
    end
    for index = 1, #t1 do
        if t1[index] ~= t2[index] then
            return false
        end
    end
    return true
end

function spec_utils:finder_print_was_called(level, message, var)
    if mock_debug == nil then
        assert(false)
    end
    local print_fn = nil
    if level == debug.DEBUG_LEVELS.ERROR then
        print_fn = mock_debug.error_print
    elseif level == debug.DEBUG_LEVELS.WARNING then
        print_fn = mock_debug.warning_print
    elseif level == debug.DEBUG_LEVELS.INFO then
        print_fn = mock_debug.info_print
    elseif level == debug.DEBUG_LEVELS.DEBUG then
        print_fn = mock_debug.debug_print
    else
        return
    end

    if var == nil then
        assert.stub(print_fn).was_called_with(match.is_table(), message)
    else
        if type(var) == 'table' then
            assert.stub(print_fn).was_called_with(match.is_table(), message, match.is_table())
        else
            assert.stub(print_fn).was_called_with(match.is_table(), message, match.is_equal(var))
        end
    end
    print_fn:clear() -- clears the call history

end

function spec_utils:register_global_logger()
    if _G.Finder_Logger == nil then
        _G.Finder_Logger = require("lib.finder_debug"):new(debug.DEBUG_LEVELS.OFF, vim.print)
    end
end

function spec_utils:revert_debug_prints()
    if mock_debug ~= nil then
        mock_debug.debug_print:revert()
        mock_debug.info_print:revert()
        mock_debug.warning_print:revert()
        mock_debug.error_print:revert()
        mock_debug = nil
    end
end

function spec_utils:get_supported_modes(namespace_id)
    local search_modes = {}
    search_modes[consts.modes.regex] = search_mode:new("Regex", "R", namespace_id, consts.modes.regex_color)
    search_modes[consts.modes.case_sensitive] = search_mode:new("Match Case", "C", namespace_id, consts.modes.case_sensitive_color)
    return search_modes
end

return spec_utils
