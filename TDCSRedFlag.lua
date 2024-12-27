


--============================================
-- Config
--============================================

local Config = {

    -- Delimiter of callsign. Messages to GCI will show as: "Hacker 1-1" as opposed to "Hacker 1-1 | Dutchie"
    CallSignDelimiter = "|",

    -- Sets all units invulnerable
    -- Will set all units/groups to invulnerable after takeoff.
    SetAutoInvulnerable = true,

    -- If AI are hit they will be set to: 
    -- NonEvasive
    -- NonAggressive
    -- RTB (If last waypoint in route is "Land" it will land there)
    PlayersOnly = false,
    
    -- Revives are not Implemented Yet
    Revive = {
        -- Revive player after taking first fuel from a tanker
        TankerConnect = false
    },
    -- Delays are in seconds
    Delays = {
        MissDelay = 6,

        DeathMessageOnScreenSeconds = 180
    },
    Messages = {
        KilledMessage = "You are dead, flow away from the action",
        MissMessage = "PK Miss",
        CopyShotMessage = "Copy Shot"
    },
    -- Amount of registered hits before "death"
    KillParameters = {
        Bullets = 8,
        Missiles = 1
    }
}

--============================================
-- Script starts here
--============================================

local Util = {}
do
    function Util.split_string(input, separator)
        if separator == nil then
            separator = " "
        end

        local result = {}
        if input == nil then
            return result
        end

        for str in string.gmatch(input, "[^" .. separator .. "]+") do
            table.insert(result, str)
        end
        return result
    end

end

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

local Helpers = {}
do
    Helpers.setInvulnerable = function(groupName)
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

    
    Helpers.isPlayer = function(unitId, coalitionId)

        if coalitionId == nil then

            local players = coalition.getPlayers(coalitionId)
            for i, player in ipairs(players) do
                if player:getID() == unitId then
                    return true
                end
            end
        else
            -- Check all coalitions
            for i = 0,2 do
                local players = coalition.getPlayers(i)
                for key, player in pairs(players) do
                    if player:getID() == unitId then
                        return true
                    end
                end
            end
        end
        return false
    end
end

local Notifier = {}
do
    local NameToCallSign = function(name)
        local split = Util.split_string(name or "", Config.CallSignDelimiter)
        local controllerFriendlyName = split[1]
        return controllerFriendlyName
    end

    local NotifyMissed = function(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = NameToCallSign(name)
        net.send_chat_to(friendlyName .. ": " .. "killed", 1)
        trigger.action.outTextForUnit(shooter:getID(), friendlyName .. " " .. Config.Messages.CopyShotMessage, Config.Delays.DeathMessageOnScreenSeconds)
        
    end

    Notifier.NotifyMissedDelayed = function(shooter, delaySeconds)
        timer.scheduleFunction(NotifyMissed, shooter, timer.getTime() + delaySeconds)
    end

    Notifier.NotifyKilled = function(target, delaySeconds)
        local name = target:getPlayerName() or target:getCallsign()
        local friendlyName = NameToCallSign(name)
        net.send_chat_to(friendlyName .. ": " .. Config.Messages.ShotMessage, 1)
        trigger.action.outTextForUnit(target:getID(), friendlyName .. " " .. Config.Messages.KilledMessage, Config.Delays.DeathMessageOnScreenSeconds)
    end

    Notifier.NotifyHit = function(target, delaySeconds)

    end

    local CopyShot = function(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = NameToCallSign(name)
        net.send_chat_to(friendlyName .. ": " .. "killed", 1)
        trigger.action.outTextForUnit(shooter:getID(), friendlyName .. " " .. Config.Messages.CopyShotMessage, 5)
    end

    Notifier.CopyShot = function(shooter, delaySeconds)
        timer.scheduleFunction(CopyShot, shooter, timer.getTime() + delaySeconds)
    end
end

Log.info("Initiating ...")

local UnitManager = {}
do
    local dead_units = {}
    local bullet_hits = {}
    local missile_hits = {}

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
    ---@param target table
    ---@param weapon table
    UnitManager.registerHit = function(target, shooter, weapon)
        if weapon:getDesc().category == Weapon.Category.SHELL then
            if not bullet_hits[target:getName()] then
                bullet_hits[target:getName()] = 0
            end
            
            bullet_hits[target:getName()] = bullet_hits[target:getName()] + 1

            if bullet_hits[target:getName()] >= Config.KillParameters.Bullets then
                UnitManager.markUnitDead(target)
            end
        end

        if weapon:getDesc().category == Weapon.Category.MISSILE then
            if not missile_hits[target:getName()] then
                missile_hits[target:getName()] = 0
            end

            missile_hits[target:getName()] = missile_hits[target:getName()] + 1

            if missile_hits[target:getName()] >= Config.KillParameters.Missiles then
                UnitManager.markUnitDead(target)
            end
        end

    end

    UnitManager.markUnitDead = function(unit)

        Log.info("Marking " .. unit:getName() .. " as dead")
        Notifier.NotifyKilled(unit)

        local function SetInvisible(unit)
            Parameters = { 
                id = 'SetInvisible', 
                params = { 
                    value = true 
                }
            }
            unit:getController():setCommand(Parameters)
        end

        local function SendAIRtb(unit)
            --TODO: Send AI RTB
        end

        dead_units[unit:getName()] = true
        bullet_hits[unit:getName()] = 0
        missile_hits[unit:getName()] = 0

        SetInvisible(unit)
        
        if Helpers.isPlayer(unit:getID(), unit:getCoalition()) == false then
            SendAIRtb(unit)
        end
    end

end

local MissileManager = {}
do 
    local trackMissile = function(data, time)

        local distance = function(a, b)
            return math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
        end

        local isMissilePastTarget = function(shotLocation, missileLocation, targetLocation)

            local a = shotLocation
            local b = targetLocation
            local c = missileLocation
            
            local ab = distance(a,b)
            local ac = distance(a,c)

            if ab - 100 > ac then
                return true
            end

            return false
        end

        local target = data.target
        local missile = data.missile
        local shotLocation = data.shotLocation
        local shooterName = data.shooterName

        if missile:isExist() == false or target:isExist() == false then
            return nil
        end

        if isMissilePastTarget(shotLocation, missile:getPoint(), target:getLocation()) == true then
            Notifier.NotifyMissedDelayed(shooterName, Config.Delays.MissDelay or 5)
            return nil
        end

        return time + 2
    end

    MissileManager.trackMissile = function (shooter, target, missile)

        local data = {
            target = target,
            missile = missile,
            shotLocation = shooter:getPoint(),
            shooterName = shooter:getName()
        }

        timer.scheduleFunction(trackMissile, data, timer.getTime() + 3)
    end
end

local EventHandler = {}
do
    function EventHandler:onEvent(e)
        local id = e.id
        if id == world.event.S_EVENT_SHOT then
            local shooter = e.initiator
            local weapon = e.weapon

            if UnitManager.isUnitAlive(shooter:getID()) == false then
                weapon:destroy()
            elseif weapon and weapon:getDesc().category == Weapon.Category.MISSILE then
                if Helpers.isPlayer(shooter:getID(), shooter:getCoalition()) == true then
                    Notifier.CopyShot(shooter, 2)
                    local target = weapon:getTarget() -- can be nil
                    MissileManager.trackMissile(shooter, target, weapon)
                end
            end
        elseif id == world.event.S_EVENT_HIT then
            local shooter = e.initiator
            local target = e.target
            local weapon = e.weapon
            UnitManager.registerHit(target, shooter, weapon)
        elseif id == world.event.S_EVENT_RUNWAY_TAKEOFF then
            if Config.SetAutoInvulnerable == true then
                local unit = e.initiator
                if unit then
                    --TODO: Set auto invulnerable
                end
            end
        end
    end

end

world.addEventHandler(EventHandler)

Log.info("Started")