


--============================================
-- Config
--============================================

--Delimiter of callsign. Messages to GCI will show as: "Hacker 1-1" as opposed to "Hacker 1-1 | Dutchie"
local CallsignDelimiter = "|"

--Sets all units invulnerable
local SetAutoInvulnerable = true

-- If AI are hit they will be set to: 
-- NonEvasive
-- NonAggressive
-- RTB (If last waypoint in route is "Land" it will land there)
local PlayersOnly = false

-- Message shown to the target
local KilledMessage = "You are dead, flow out of the action"




--============================================
-- Script starts here
--============================================

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
end

local UnitManager = {}
do
    local dead_units = {}

    UnitManager.isUnitAlive = function(unitId)
        local id = tostring(unitId)

        if dead_units[id] == nil or dead_units[id] == false then
            return true
        end

        

    end

end

local Helpers = {}
do 

    
    local SetInvulnerable = function(groupName)

    
    end

end




local MissileManager = {}
do 


end


local EventHandler = {}
do
    
end