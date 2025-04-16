
---@class Logger
---@field private _prefix string
local Log = {}
do

    function Log.New(name)
        Log.__index = Log
        local self = setmetatable({}, Log)

        self._prefix = "[TDCS Red Flag]"
        if name then
            self._prefix = self._prefix .. " [" .. name .. "]"
        end

        return self
    end

    function Log:info(string)
        if not string then return end
        env.info(self._prefix .. " " .. string)
    end

    function Log:error(string)
        if not string then return end
        env.error(self._prefix .. " " .. string)
    end

    function Log:warn(string)
        if not string then return end
        env.warning(self._prefix .. " " .. string)
    end

    Log.debug = function(string)
        if Config.DebugLog == false then
            return
        end
        env.info("[DEBUG][TDCS Red Flag] " .. (string or "nil"))
    end 

    Log.debugOutText = function(string, time)
        if Config.DebugOutText == true then
            trigger.action.outText("[DEBUG] " .. string, time)
        end
    end

    Log.debugOutTextForUnit = function(unitId, string, time)
        if Config.DebugOutText == true then
            trigger.action.outTextForUnit(unitId, string, time)
        end
    end
end

if RedFlag == nil then RedFlag = {} end
RedFlag.Log = Log
