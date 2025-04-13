
local Log = {}
do
    Log.info = function(string)
        env.info("[TDCS Red Flag] " .. (string or "nil"))
    end

    Log.warn = function(string)
        env.warn("[TDCS Red Flag] " .. (string or "nil"))
    end

    Log.error = function(string)
        env.error("[TDCS Red Flag] " .. (string or "nil"))
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