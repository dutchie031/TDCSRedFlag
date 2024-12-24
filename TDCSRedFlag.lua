


--============================================
-- Config
--============================================

--Delimiter of callsign. Messages to GCI will show as: "Hacker 1-1" as opposed to "Hacker 1-1 | Dutchie"
local CallsignDelimiter = "|"

--Sets all units invulnerable
--Will set all units/groups to invulnerable after takeoff.
local SetAutoInvulnerable = true

-- If AI are hit they will be set to: 
-- NonEvasive
-- NonAggressive
-- RTB (If last waypoint in route is "Land" it will land there)
local PlayersOnly = false

-- Amount of bullets to have hit before a kill event
local BulletHitsForKill = 8

-- Amount of Missiles to have hit before a kill counts
local MissileHitsForKill = 1


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

Log.info("Initiating ...")

local UnitManager = {}
do
    local dead_units = {}

    local bullethits = {}

    
    ---Checks if unit is alive according to the simulation
    ---@param unitId integer
    ---@return boolean
    UnitManager.isUnitAlive = function(unitId)
        local id = tostring(unitId)
        if dead_units[id] == true then
            return true
        end
        return true
    end

    ---Registers a hit
    ---@param unitId integer
    ---@param weapon table
    UnitManager.registerHit = function(unitId, weapon)

    end

    UnitManager.markUnitDead = function(unitId)

    end

end

local Helpers = {}
do
    Helpers.SetInvulnerable = function(groupName)
        SetImmortal = { 
            id = 'SetImmortal',
            params = {
                value = true 
            }
        }

        local group = Group.getByName(groupName)
        if group then
            group:getController():setCommand(SetImmortal)
        end
    end

end




local MissileManager = {}
do 


end


local EventHandler = {}
do
    
end

Log.info("Started")