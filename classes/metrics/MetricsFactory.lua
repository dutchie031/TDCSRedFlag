

---@class MetricsFactory
---@field private _counters table<string, Counter>
local MetricsFactory = {}

do

    function MetricsFactory.New()
        MetricsFactory.__index = MetricsFactory
        local self = setmetatable({}, MetricsFactory)
        self._counters = {}
        return self
    end

    ---@param self MetricsFactory
    ---@param name string
    ---@return Counter
    function MetricsFactory:GetOrCreateCounter(name)
        if self._counters[name] then
            return self._counters[name]
        end

        local counter = RedFlag.classes.metrics.Counter.GetOrCreate(name)
        return counter
    end

    function MetricsFactory:WriteToFile(filename)
        local file = io.open(filename, "w+")
        if not file then
            error("Could not open file for writing: " .. filename)
        end

        for _, counter in pairs(self._counters) do
            file:write(counter:GetMetricString() .. "\n")
        end

        file:close()
    end
end

if RedFlag == nil then RedFlag = {} end
if RedFlag.classes == nil then RedFlag.classes = {} end
if RedFlag.classes.metrics == nil then RedFlag.classes.metrics = {} end
RedFlag.classes.metrics.MetricsFactory = MetricsFactory