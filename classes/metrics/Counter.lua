

---@class Counter
---@field name string
---@field count number
---@field labelCounts table<string, number>
local Counter = {}

local _counters = {}

function Counter.GetOrCreate(name)

    if _counters[name] then
        return _counters[name]
    end

    if type(name) ~= "string" then
        error("Counter name must be a string")
    end

    if name == "" then
        error("Counter name cannot be empty")
    end

    if name:find("%s") then
        error("Counter name cannot contain spaces")
    end

    Counter.__index = Counter
    local self = setmetatable({}, Counter)

    self.name = name
    self.count = 0
    self.labelCounts = {}

    _counters[name] = self

    return self
end

---comment
---@param labels table<string,string> 
---@param amount number
function Counter:Increase(labels, amount)
    if amount == nil then amount = 1 end
    if type(amount) ~= "number" then
        error("Amount must be a number")
    end

    self.count = self.count + amount

    if labels and type(labels) == "table" then
        -- Serialize the labels table into a string key
        local labelKey = self:SerializeLabels(labels)
        self.labelCounts[labelKey] = (self.labelCounts[labelKey] or 0) + amount
    end
end

---@private
---@param labels table<string,string>
---@return string
function Counter:SerializeLabels(labels)
    -- Convert the labels table into a sorted string key
    local keys = {}
    for k in pairs(labels) do
        table.insert(keys, k)
    end
    table.sort(keys)

    local parts = {}
    for _, k in ipairs(keys) do
        table.insert(parts, k .. "=" .. tostring(labels[k]))
    end

    return table.concat(parts, ",")
end

function Counter:GetTotal()
    return self.count
end

---@return string
function Counter:GetMetricString()
    local metricString = self.name .. " " .. self.count

    for labelKey, labelCount in pairs(self.labelCounts) do
        metricString = "\n" .. metricString .. "{" .. labelKey .. "} " .. labelCount
    end

    return metricString
end

if RedFlag == nil then RedFlag = {} end
if RedFlag.classes == nil then RedFlag.classes = {} end
if RedFlag.classes.metrics == nil then RedFlag.classes.metrics = {} end
RedFlag.classes.metrics.Counter = Counter