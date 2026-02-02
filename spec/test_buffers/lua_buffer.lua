-- test.lua - synthetic Lua file for syntax testing

-- Constants / locals
local APP_NAME = "LuaTestApp"
local VERSION = 1.0
local MAX_ITEMS = 10

-- Utility function
local function log(...)
    local args = {...}                 -- varargs + table constructor
    for i = 1, #args do
        io.write(tostring(args[i]), " ")
    end
    io.write("\n")
end

-- Enum-like table
local State = {
    INIT = 0,
    RUNNING = 1,
    STOPPED = 2
}

-- Table with mixed keys
local config = {
    ["app_name"] = APP_NAME,
    version = VERSION,
    enabled = true,
    limits = { min = 0, max = MAX_ITEMS },
    tags = { "test", "lua", "syntax" }
}

-- Metatable example
local Node = {}
Node.__index = Node

function Node:new(id, name)
    local obj = {
        id = id or 0,
        name = name or "unnamed",
        value = 0,
        next = nil
    }
    setmetatable(obj, self)
    return obj
end

function Node:setValue(v)
    self.value = v
end

function Node:toString()
    return string.format(
        "Node{id=%d, name=%s, value=%d}",
        self.id,
        self.name,
        self.value
    )
end

-- Linked list helpers
local function appendNode(head, node)
    if not head then
        return node
    end

    local cur = head
    while cur.next do
        cur = cur.next
    end
    cur.next = node
    return head
end

local function iterateNodes(head)
    local current = head
    return function()
        local tmp = current
        if tmp then
            current = tmp.next
        end
        return tmp
    end
end

-- Coroutine example
local function counterCoroutine(max)
    return coroutine.create(function()
        for i = 1, max do
            coroutine.yield(i)
        end
    end)
end

-- Error handling
local function riskyDivide(a, b)
    if b == 0 then
        error("division by zero")
    end
    return a / b
end

-- Main logic
local function main(...)
    local args = {...}
    local state = State.INIT

    log(APP_NAME, "starting with args:", #args)

    -- Arrays
    local numbers = {}
    for i = 1, MAX_ITEMS do
        numbers[i] = i * i
    end

    table.sort(numbers, function(a, b)
        return a > b
    end)

    for i, v in ipairs(numbers) do
        log("numbers[" .. i .. "] =", v)
    end

    -- Linked list
    local head = nil
    head = appendNode(head, Node:new(1, "alpha"))
    head = appendNode(head, Node:new(2, "beta"))
    head = appendNode(head, Node:new(3, "gamma"))

    for node in iterateNodes(head) do
        node:setValue(node.id * 10)
        log(node:toString())
    end

    -- Coroutine usage
    local co = counterCoroutine(3)
    while coroutine.status(co) ~= "dead" do
        local ok, value = coroutine.resume(co)
        if ok then
            log("coroutine value:", value)
        end
    end

    -- pcall / xpcall
    local ok, result = pcall(riskyDivide, 10, 0)
    if not ok then
        log("pcall error:", result)
    end

    local function errorHandler(err)
        return "handled error: " .. tostring(err)
    end

    local ok2, result2 = xpcall(riskyDivide, errorHandler, 10, 2)
    if ok2 then
        log("xpcall result:", result2)
    end

    state = State.STOPPED
    log("state =", state)
end

-- Run
main("foo", "bar", 123)

