local version  = "{{version}}"

--=========================================

-- BIG NOTE!!!
-- This script only works properly in DCS when it's being run on a Dedicated Server.
-- This is due to a player slot or a client slot that has the same userID (when run from the game itself) the unit commands on the host don't work.

--=========================================


--============================================
-- Config
--============================================

local Config = {

    -- Delimiter of callsign. Messages to GCI will show as: "Hacker 1-1" as opposed to "Hacker 1-1 | Dutchie"
    CallSignDelimiter = "|",

    -- If AI are hit they will be set to:
    -- NonEvasive
    -- NonAggressive
    -- RTB (If last waypoint in route is "Land" it will land there)
    -- Done on a unit basis
    PlayersOnly = false,
    
    -- Mad Dog behaviour of AA missiles
    -- CURRENTLY NOT IMPLEMENTED
    MadDog = {
        Behaviour = 0 --DEFAULT: 0
    },
    DeadUnitWeapons = { -- Behaviour of weapons when launched by a dead unit
        AAWeaponsBehaviour = 0, --DEFAULT: 0
        AGWeaponsBehaviour = 0  --DEFAULT: 0
    },
    -- Delays are in seconds
    Delays = {
        MissDelay = 5,           -- Message TO the shooter, to the target any hits are always instant
        MissileKillDelay = 3,    -- Message TO the shooter, to the target any hits are always instant
        GunKillDelay = 0,        -- Message TO the shooter, to the target any hits are always instant
        MissMessageOnScreen = 5, -- Message TO the shooter
        DeathMessageOnScreenSeconds = 120
    },
    Messages = {
        --- replaceable variables:
        --- {{ callsign }} => replaces with the callsign (delimited first part)

        --- If you want to disable a message, simply replace the string with nil 
        --- example: 
        ---  UnitKilled = nil
        PlayerMessages = {
            UnitKilled = "{{ callsign }}, You are dead, flow away from the action",
            MissileMissed = "{{ callsign }}, PK Miss",
            ConfirmKill = "{{ callsign }}, PK Hit",
            ConfirmKillGunKill = "{{ callsign }}, good guns, splash one",
            CopyShotMessage = "{{ callsign }}, Copy Shot",
            ReviveMessage = "{{ callsign }}, you have been reset and are cleared to enter the action"
        },
        --- Messages that are sent to the server for LotATC, Olympus and other tool users.
        ControllerMessages = {
            UnitKilled = "{{ callsign }}, dead", -- callsign of the unit that died
            MissileMissed = "{{ callsign }} , PK MISS", -- callsign of the unit that missed 
            ConfirmKill = "{{ callsign }}, PK HIT", -- callsign of the unit whos missile hit
            ConfirmKillGunKill = "{{ callsign }}, GUN KILL" -- callsign of the shooter
        }
    },
    -- Amount of registered hits before "death"
    KillParameters = {
        Bullets = 8,
        Missiles = 1,

        ---If you want the Gun solution checker to ONLY work when the shooter is behind the target
        GunKillOnlyRearAspect = true
    },
    -- REVIVE NOT IMPLEMENTED YET
    Revive = {
        -- Revive player after taking first fuel from a tanker
        TankerConnect = true,

        --After landing, if an aircraft is still on the ground 30 seconds after landing. (No Touch and goes)
        Landing = true,
        
        -- Respawn zones need to start with "REVIVE_" so "REVIVE_<zoneName>"
        InRespawnZone = true,
    },
    AutoInvulnerableSettings = {
        -- Automatically manages invulnerablity. 
        Enabled = true,

        -- Players only
        PlayersOnly = false,

        -- Invulnerable when outside trigger zones starting with name "vulnerablezone_"
        OutsideVulnerableZone = true,

        -- NOT IMPLEMENTED YET!!
        -- Invulnerable when inside trigger zones starting with name "invulnerablezone_"
        -- (Doesn't really do anything if OutsideVulnerableZone is set to true as well)
        InsideInvulnerablezone = true,
        
        -- Detects whether or not a unit has hit the ground or scenery object when invulnerable. 
        -- If a unit indeed hit the ground in an "excessive way" it will explode 
        GroundCollisionDetection = true,
        ObjectCollisionDetection = true
    },
    DebugLog = false,
    DebugOutText = false,
}

--============================================
-- Devs TODO list
--============================================

--[[


MissileTracker:
TODO: MadDogged missiles.
TODO: Destroyed missiles

CrashManager:
TODO: Over G ? 

BombTracker: 

TODO: Practice Bombs 
(This might better help with "unlimited weapons" options)

]]--

--============================================
-- Script starts here
--============================================


local isSinglePlayer = false
if net.get_my_player_id() == 0 then
    isSinglePlayer = true
end

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

    function Util.distance(a, b)
        return math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
    end

    ---comment
    ---@param a Vec3
    ---@param b Vec3
    ---@return number
    function Util.getDistance3D(a, b)
        return Util.vectorMagnitude({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z })
    end

    function Util.vectorMagnitude(vec)
        return (vec.x ^ 2 + vec.y ^ 2 + vec.z ^ 2) ^ 0.5
    end

    ---@param str string
    ---@param findable string
    ---@param ignoreCase boolean?
    ---@return boolean
    function Util.startsWith(str, findable, ignoreCase)

        if ignoreCase == true then
            return string.lower(str):find('^' .. string.lower(findable)) ~= nil
        end

        return str:find('^' .. findable) ~= nil
    end

    ---@param number number
    ---@return string
    function Util.roundNumber(number)
        return string.format("%.2f", number)
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

local Helpers = {}
do
    local function table_print(tt, indent, done)
        done = done or {}
        indent = indent or 0
        if type(tt) == "table" then
            local sb = {}
            for key, value in pairs(tt) do
                table.insert(sb, string.rep(" ", indent)) -- indent it
                if type(value) == "table" and not done[value] then
                    done[value] = true
                    table.insert(sb, key .. " = {\n");
                    table.insert(sb, table_print(value, indent + 2, done))
                    table.insert(sb, string.rep(" ", indent)) -- indent it
                    table.insert(sb, "}\n");
                elseif "number" == type(key) then
                    table.insert(sb, string.format("\"%s\"\n", tostring(value)))
                else
                    table.insert(sb, string.format(
                        "%s = \"%s\"\n", tostring(key), tostring(value)))
                end
            end
            return table.concat(sb)
        else
            return tt .. "\n"
        end
    end

    Helpers.toString = function(something)
        if something == nil then
            return "nil"
        elseif "table" == type(something) then
            return table_print(something)
        elseif "string" == type(something) then
            return something
        else
            return tostring(something)
        end
    end


    Helpers.vecSub = function(vec1, vec2)
        return { x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = vec1.z - vec2.z }
    end

    ---comment
    ---@param a Vec3
    ---@param b Vec3
    Helpers.vecAdd = function (a, b)
        return {x=a.x+b.x, y=a.y+b.y, z=a.z+b.z}
    end

    Helpers.normVec = function(vec)
        local magnitude = Util.vectorMagnitude(vec)

        return {
            x = vec.x / magnitude,
            y = vec.y / magnitude,
            z = vec.z / magnitude
        }
    end

    ---@param posA Vec3 Bullet
    ---@param speedA Vec3 Bullet
    ---@param posB Vec3 Jet
    ---@param speedB Vec3 Jet
    ---@param acc Vec3 JetAcceleration
    ---@return boolean
    Helpers.vecCollision = function(posA, speedA, posB, speedB, acc)
        
        ---@param bulletX number bullet position
        ---@param jetX number jet position
        ---@param bulletV number
        ---@param jetV number
        ---@param jetA number
        ---@return number, number
        local dimensionCollision = function(bulletX, jetX, bulletV, jetV, jetA)
            
            local closestToZero = function(a, b)

                if a == b then
                    if a > 0 then return a end
                    return b
                end
                if math.abs(a) < math.abs(b) then return a end
                if math.abs(b) < math.abs(a) then return b end
                return 0
            end
            
            local SolveAccelerated = function(a, b, c, d, e)

                -- local a = bulletX
                -- local b = bulletV
                -- local c = jetX
                -- local d = jetV
                -- local e = jetA
                local underRoot = math.pow((2 * d -2 * b),2) - 4 * e * (2 * c - 2 * a)

                local first = (-2 * d + 2 * b + math.sqrt(underRoot)) / (2 * e)
                local second = (-2 * d + 2 * b - math.sqrt(underRoot)) / (2 * e)

                -- The most logical solution is the one that lies closest to 0 (as it's all short ranges and t should be very low)
                return closestToZero(first, second)
            end

            local minx1 = bulletX - 0.5
            local maxx1 = bulletX + 0.5

            local minx2 = jetX - 20
            local maxx2 = jetX + 20

            if jetA == 0 then
                Log.debugOutText("Solving linear",1)
                local xA = (maxx2 - minx1) / (bulletV - jetV)
                local xB = (minx2 - maxx1) / (bulletV - jetV)

                local minTime = math.min(xA, xB)
                local maxTime = math.max(xA, xB)

                return minTime, maxTime
            end

            local xA = SolveAccelerated(minx1, bulletV, maxx2, jetV, jetA)
            local xB = SolveAccelerated(maxx1, bulletV, minx2,  jetV, jetA)
            
            local minTime = math.min(xA, xB)
            local maxTime = math.max(xA, xB)
            return minTime, maxTime

        end

        local xTimeMin, xTimeMax = dimensionCollision(posA.x, posB.x, speedA.x, speedB.x, acc.x)
        local yTimeMin, yTimeMax = dimensionCollision(posA.y, posB.y, speedA.y, speedB.y, acc.y)
        local zTimeMin, zTimeMax = dimensionCollision(posA.z, posB.z, speedA.z, speedB.z, acc.z)

        Log.debugOutText("[" .. Util.roundNumber(xTimeMin) .. ",".. Util.roundNumber(xTimeMax) .. "]" ..
                "[" .. Util.roundNumber(yTimeMin) .. ",".. Util.roundNumber(yTimeMax) .. "]" ..
            "[" .. Util.roundNumber(zTimeMin) .. ",".. Util.roundNumber(zTimeMax) .. "]", 1)

        return
            (xTimeMin <= yTimeMax and yTimeMin <= xTimeMax)
            and (yTimeMin <= zTimeMax and zTimeMin <= yTimeMax)
            and (xTimeMin <= zTimeMax and zTimeMin <= yTimeMax)
    end

    ---@param vec Vec3
    ---@param magnitude number
    ---@return Vec3
    Helpers.vecSetMagnitude = function(vec, magnitude)
        local oldMag = Helpers.vectorMagnitude(vec)

        return {
            x = vec.x / oldMag * magnitude,
            y = vec.y / oldMag * magnitude,
            z = vec.z / oldMag * magnitude,
        }
    end

    Helpers.vectorMagnitude = function(vec)
        return (vec.x ^ 2 + vec.y ^ 2 + vec.z ^ 2) ^ 0.5
    end

    ---returns a number in range [-1,1]. > 0 same direction. < 0 opposite direction
    ---@param vec1 any
    ---@param vec2 any
    ---@return number
    Helpers.vecAlignment = function(vec1, vec2)
        local vec1Norm = Helpers.normVec(vec1)
        local vec2Norm = Helpers.normVec(vec2)

        return ((vec1Norm.x * vec2Norm.x) + (vec1Norm.y * vec2Norm.y) + (vec1Norm.z * vec2Norm.z))
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
            for i = 0, 2 do
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

local AIHelpers = {}

do
    AIHelpers.setDocile = function(unit)
        Log.info("Setting unit docile: " .. unit:getName())

        local con = unit:getController()

        if isSinglePlayer == true then
            con = unit:getGroup():getController()
        end

        con:setOption(0, 4) --hold fire
        con:setOption(1, 0) --No reaction to threat
        con:setOption(3, 1) --No radar using
    end

    local finalAirbases = {}
    do -- load final airbases
        for coalition_name, coalition_data in pairs(env.mission.coalition) do
            if coalition_data.country then
                for country_index, country_data in pairs(coalition_data.country) do
                    if country_data.plane and country_data.plane.group then
                        for _, group in ipairs(country_data.plane.group) do
                            if group.route and group.route.points then
                                local count = 0
                                for _, point in ipairs(group.route.points) do
                                    count = count + 1
                                end

                                if #group.route.points > 0 then
                                    local lastpoint = group.route.points[count]
                                    if lastpoint.action and lastpoint.action == "Landing" then
                                        local landingPoint = {
                                            airdromeId = lastpoint.airdromeId,
                                            x = lastpoint.x,
                                            y = lastpoint.y,
                                            alt = lastpoint.alt,
                                            speed = lastpoint.speed,
                                        }

                                        finalAirbases[group.name] = landingPoint
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    AIHelpers.sendRTB = function(unit)
        local groupName = unit:getGroup():getName()
        local airbaseData = finalAirbases[groupName]

        if airbaseData == nil then
            return --TODO: If no RTB base was added
        end

        local currentPosition = unit:getPoint()

        local task = {
            id = "Mission",
            params = {
                airborne = true, -- RTB mission generally are given to airborne units
                route = {
                    points = {
                        [1] = {
                            ["alt"] = 2000,
                            ["action"] = "Turning Point",
                            ["alt_type"] = "BARO",
                            ["speed"] = 220.97222222222,
                            ["task"] = 
                            {
                                ["id"] = "ComboTask",
                                ["params"] = 
                                {
                                    ["tasks"] = 
                                    {
                                        [1] = 
                                        {
                                            ["enabled"] = true,
                                            ["auto"] = false,
                                            ["id"] = "WrappedAction",
                                            ["number"] = 1,
                                            ["params"] = 
                                            {
                                                ["action"] = 
                                                {
                                                    ["id"] = "Option",
                                                    ["params"] = 
                                                    {
                                                        ["value"] = 4,
                                                        ["name"] = 0,
                                                    }, -- end of ["params"]
                                                }, -- end of ["action"]
                                            }, -- end of ["params"]
                                        }, -- end of [1]
                                        [2] = 
                                        {
                                            ["enabled"] = true,
                                            ["auto"] = false,
                                            ["id"] = "WrappedAction",
                                            ["number"] = 2,
                                            ["params"] = 
                                            {
                                                ["action"] = 
                                                {
                                                    ["id"] = "Option",
                                                    ["params"] = 
                                                    {
                                                        ["value"] = 0,
                                                        ["name"] = 3,
                                                    }, -- end of ["params"]
                                                }, -- end of ["action"]
                                            }, -- end of ["params"]
                                        }, -- end of [2]
                                        [3] = 
                                        {
                                            ["enabled"] = true,
                                            ["auto"] = false,
                                            ["id"] = "WrappedAction",
                                            ["number"] = 3,
                                            ["params"] = 
                                            {
                                                ["action"] = 
                                                {
                                                    ["id"] = "Option",
                                                    ["params"] = 
                                                    {
                                                        ["value"] = 0,
                                                        ["name"] = 1,
                                                    }, -- end of ["params"]
                                                }, -- end of ["action"]
                                            }, -- end of ["params"]
                                        }, -- end of [3]
                                    }, -- end of ["tasks"]
                                }, -- end of ["params"]
                            }, -- end of ["task"]
                            ["type"] = "Turning Point",
                            ["ETA"] = 419.83667467719,
                            ["ETA_locked"] = false,
                            ["y"] = airbaseData.y,
                            ["x"] = airbaseData.x,
                            ["speed_locked"] = true,
                            ["formation_template"] = "",
                        },
                        [2] = {
                            alt = airbaseData.alt,
                            action = "Landing",
                            alt_type = "BARO",
                            speed = airbaseData.speed,
                            ETA = 0,
                            ETA_locked = false,
                            x = airbaseData.x,
                            y = airbaseData.y,
                            speed_locked = true,
                            formation_template = "",
                            airdromeId = airbaseData.airdromeId,
                            type = "Land",
                            task = {
                                id = "ComboTask",
                                params = {
                                    tasks = {}
                                }
                            }
                        }
                    }
                }
            }
        }

        local con = unit:getController()
        con:setTask(task)

        Log.info("Sending Unit RTB: " .. unit:getName())

    end
end

---@class Notifier
---@field private config NotificationConfig
local Notifier = {}
do

    ---@class NotificationConfig
    ---@field CallsignDelimiter string

    ---comment
    ---@param config NotificationConfig
    ---@return Notifier
    function Notifier.New(config)
        Notifier.__index = Notifier
        local self = setmetatable({}, Notifier)
        self.config = config

        return self
    end

    ---@private
    function Notifier:NameToCallSign(name)
        local split = Util.split_string(name or "", Config.CallSignDelimiter)
        local controllerFriendlyName = split[1]
        return controllerFriendlyName
    end

    ---@private
    ---@param template string
    ---@param key string
    ---@param value string
    ---@returns string
    function Notifier:Format(template, key, value)
        if not template or not key or not value then return template end

        return template:gsub("{{ " .. key .. " }}", value):gsub("{{" .. key .. "}}", value)
    end

    ---@param shooter table
    function Notifier:NotifyMissed(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = self:NameToCallSign(name)

        if Config.Messages.ControllerMessages.MissileMissed ~= nil then
            local message = self:Format(Config.Messages.ControllerMessages.MissileMissed, "callsign", friendlyName)
            net.send_chat(message, true)
        end

        if Config.Messages.PlayerMessages.MissileMissed ~= nil then
            local message = self:Format(Config.Messages.PlayerMessages.MissileMissed, "callsign", friendlyName)
            trigger.action.outTextForUnit(shooter:getID(), message, Config.Delays.MissMessageOnScreen)
        end

    end

    ---@param shooter table
    ---@param delaySeconds number
    function Notifier:NotifyMissedDelayed(shooter, delaySeconds)
        
        local notify = function(input, time)
            input.notifier:NotifyMissed(input.shooter)
            return nil
        end

        timer.scheduleFunction(notify, { notifier = self, shooter = shooter }, timer.getTime() + delaySeconds)
    end

    ---@param target table
    function Notifier:NotifyKilled(target)
        local name = target:getName()
        if target.getPlayerName then
            name = target:getPlayerName() or target:getName()
        end
        local friendlyName = self:NameToCallSign(name)

        if Config.Messages.ControllerMessages.UnitKilled ~= nil then
            local controllerMessage = self:Format(Config.Messages.ControllerMessages.UnitKilled, "callsign", friendlyName)
            net.send_chat(controllerMessage, true)            
        end

        if target.getID and Config.Messages.PlayerMessages.UnitKilled ~= nil then
            local message = self:Format(Config.Messages.PlayerMessages.UnitKilled, "callsign", friendlyName)
            trigger.action.outTextForUnit(target:getID(), message, Config.Delays.DeathMessageOnScreenSeconds, true)
        end
    end

    ---@param shooter table
    function Notifier:NotifyKill(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = self:NameToCallSign(name)

        if Config.Messages.ControllerMessages.ConfirmKill ~= nil then
            
            local message = self:Format(Config.Messages.ControllerMessages.ConfirmKill, "callsign", friendlyName)
            net.send_chat(message, true)
        end
        
        if Config.Messages.PlayerMessages.ConfirmKill ~= nil then
            local message = self:Format(Config.Messages.PlayerMessages.ConfirmKill, "callsign", friendlyName)
            trigger.action.outTextForUnit(shooter:getID(), message, 5)
        end
    end

    ---@param shooter table
    ---@param delaySeconds number
    function Notifier:NotifyKillDelayed(shooter, delaySeconds)

        if delaySeconds <= 1 then
            self:NotifyKill(shooter)
        else
            local notify = function(input, time)
                input.notifier:NotifyKill(input.shooter)
                return nil
            end
    
            timer.scheduleFunction(notify, { notifier = self, shooter = shooter } , timer.getTime() + delaySeconds)
        end
    end

    ---@param shooter table
    function Notifier:NotifyGunKill(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = self:NameToCallSign(name)

        if Config.Messages.ControllerMessages.ConfirmKill ~= nil then
            local message = self:Format(Config.Messages.ControllerMessages.ConfirmKillGunKill, "callsign", friendlyName)
            net.send_chat(message, true)
        end

        if Config.Messages.PlayerMessages.ConfirmKill ~= nil then
            local message = self:Format(Config.Messages.PlayerMessages.ConfirmKillGunKill, "callsign", friendlyName)
            trigger.action.outTextForUnit(shooter:getID(), message, 8)
        end

    end

    ---@param shooter table
    ---@param delaySeconds number
    function Notifier:NotifyGunKillDelayed(shooter, delaySeconds)
        if delaySeconds <= 1 then
            self:NotifyGunKill(shooter)
        else
            local notify = function(input, time)
                input.notifier:NotifyGunKill(input.shooter)
                return nil
            end

            timer.scheduleFunction(notify, { notifier = self, shooter = shooter }, timer.getTime() + delaySeconds)
        end
    end

    ---@param shooter table
    function Notifier:CopyShot(shooter)
        if Config.Messages.PlayerMessages.CopyShotMessage ~= nil then 
            local name = shooter:getPlayerName() or shooter:getCallsign()
            local friendlyName = self:NameToCallSign(name)
            local message = self:Format(Config.Messages.PlayerMessages.CopyShotMessage, "callsign", friendlyName)
            trigger.action.outTextForUnit(shooter:getID(), message, 5)
        end
    end

    ---@param shooter table
    ---@param delaySeconds number
    function Notifier:CopyShotDelayed(shooter, delaySeconds)

        local notify = function(input, time)
            input.notifier:CopyShot(input.shooter)
            return nil
        end

        timer.scheduleFunction(notify, { notifier = self, shooter = shooter }, timer.getTime() + delaySeconds)
    end

    ---@param shooter table
    function Notifier:DenyShot(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = self:NameToCallSign(name)
        trigger.action.outTextForUnit(shooter:getID(), friendlyName .. " " .. "Shot scrapped", 5)
    end
    
    function Notifier:NotifyRevived(unit)

        if Config.Messages.PlayerMessages.ReviveMessage == nil then
            return
        end

        local name = unit:getPlayerName() or unit:getCallsign()
        local friendlyName = self:NameToCallSign(name)
        local message = self:Format(Config.Messages.PlayerMessages.ReviveMessage, "callsign", friendlyName)
        trigger.action.outTextForUnit(unit:getID(), message, 10)
    end

    ---@param unit table
    function Notifier:NotifyInvinsible(unit)
        Log.info("Set unit immortal: " .. unit:getName())
        trigger.action.outTextForUnit(unit:getID(), "Invinsibility activated", 3)
    end

    ---@param unit table
    function Notifier:NotifyNotInvinsible(unit)
        Log.info("Set unit not immortal: " .. unit:getName())
        trigger.action.outTextForUnit(unit:getID(), "Invinsibility de-activated", 3)
    end
end

Log.info("Initiating ...")

---@class UnitManager
---@field private dead_players table<string, boolean>
---@field private dead_units table<string, boolean>
---@field private crashed_units table<string, boolean>
---@field private bullet_hits table<string, integer>
---@field private missile_hits table<string, integer>
---@field private _notifier Notifier
---@field private invincibilityManager InvincibilityManager
local UnitManager = {}
do --- UnitManager
    

    ---comment
    ---@param invincibilityManager InvincibilityManager
    ---@param notifier Notifier
    ---@return UnitManager
    function UnitManager.New(invincibilityManager, notifier)
        UnitManager.__index = UnitManager
        local self = setmetatable({}, UnitManager)

        self.dead_players = {}
        self.dead_units = {}
        self.crashed_units = {}
        self.bullet_hits = {}
        self.missile_hits = {}
        self.invincibilityManager = invincibilityManager
        self._notifier = notifier
        
        return self
    end

    ---Checks if unit is alive according to the simulation
    ---@param unitName string
    ---@return boolean
    function UnitManager:isUnitAlive(unitName)
        if self.dead_units[unitName] == true then
            return false
        end
        return true
    end

    ---comment
    ---@return Array<string>
    function UnitManager:getDeadPlayers()
        local result = {}
        for unitName, isDead in pairs(self.dead_players) do
            if isDead == true then
                table.insert(result, unitName)
            end
        end
        return result
    end

    ---comment
    ---@param shooter Unit
    ---@param target Unit
    function UnitManager:registerGunKill(shooter, target)

        if self:isUnitAlive(shooter:getName()) == false then
            return --if hit by a bullet from a dead unit the hit does not count
        end

        if not self.bullet_hits[target:getName()] then
            self.bullet_hits[target:getName()] = 0
        end

        if self:isUnitAlive(target:getName()) == false then
            return --if a unit is already dead there's no need to do anything
        end

        self.bullet_hits[target:getName()] = Config.KillParameters.Bullets

        if self.bullet_hits[target:getName()] >= Config.KillParameters.Bullets then
            self:markUnitDead(target)
            self._notifier:NotifyGunKillDelayed(shooter, Config.Delays.GunKillDelay)
        end
    end

    ---Registers a hit
    ---@param target Unit
    ---@param shooter Unit
    ---@param weapon Weapon
    function UnitManager:registerHit(target, shooter, weapon)
        if Object.getCategory(weapon) == Object.Category.WEAPON then

            if weapon:getDesc().category == Weapon.Category.SHELL then
                if self:isUnitAlive(shooter:getName()) == false then
                    return --if hit by a bullet from a dead unit the hit does not count
                end
    
                if not self.bullet_hits[target:getName()] then
                    self.bullet_hits[target:getName()] = 0
                end
    
                self.bullet_hits[target:getName()] = self.bullet_hits[target:getName()] + 1
    
                if self.bullet_hits[target:getName()] >= Config.KillParameters.Bullets then
                    self:markUnitDead(target)
                    self._notifier:NotifyGunKillDelayed(shooter, Config.Delays.GunKillDelay)
                end
            elseif weapon:getDesc().category == Weapon.Category.MISSILE then
                if not self.missile_hits[target:getName()] then
                    self.missile_hits[target:getName()] = 0
                end
    
                self.missile_hits[target:getName()] = self.missile_hits[target:getName()] + 1
    
                if self.missile_hits[target:getName()] >= Config.KillParameters.Missiles then
                    self._notifier:NotifyKillDelayed(shooter, Config.Delays.MissileKillDelay)
                    self:markUnitDead(target)
                end
            end
        elseif Object.getCategory(weapon) == Object.Category.UNIT then
            local targetName = "nil"
            if target.getName then
                targetName = target:getName()
            end

            local unitName = weapon:getName()
            if self.crashed_units[unitName] == true then -- only crash and explode unit once
                return
            end

            self.crashed_units[unitName] = true

            self.invincibilityManager:setMortal(weapon)
            trigger.action.explosion(weapon:getPoint(), 5)

        end
    end

    ---@param unit table
    ---@param notify boolean
    function UnitManager:markUnitAlive(unit, notify)
        Log.info("Marking " .. unit:getName() .. " as alive")
        self.dead_units[unit:getName()] = false
        self.bullet_hits[unit:getName()] = 0
        self.missile_hits[unit:getName()] = 0
        self.crashed_units[unit:getName()] = false

        if Helpers.isPlayer(unit:getID(), unit:getCoalition()) == true then
            self.dead_players[unit:getName()] = false
        end

        self:setInvisible(unit, false)

        if notify == true then
            self._notifier:NotifyRevived(unit)
        end
    end

    ---comment
    ---@param unit table
    function UnitManager:markUnitDead(unit)
        Log.info("Marking " .. unit:getName() .. " as dead")
        self._notifier:NotifyKilled(unit)

        self:setInvisible(unit, true)

        local function SendAIRtb(unit)
            AIHelpers.setDocile(unit)
            AIHelpers.sendRTB(unit)
            AIHelpers.setDocile(unit)
        end

        self.dead_units[unit:getName()] = true
        self.bullet_hits[unit:getName()] = 0
        self.missile_hits[unit:getName()] = 0

        if Helpers.isPlayer(unit:getID(), unit:getCoalition()) == true then
            self.dead_players[unit:getName()] = true
        else
            SendAIRtb(unit)
        end
    end

    ---comment
    ---@param unit Unit
    function UnitManager:OnUnitBirth(unit)
        self:markUnitAlive(unit, false)
        self.invincibilityManager:resetUnit(unit)

        trigger.action.outTextForUnit(unit:getID(), "Reset unit...", 1, true)
    end

    ---@private
    ---@param unit table
    ---@param isInvisible boolean
    function UnitManager:setInvisible(unit, isInvisible)
        local commmand = {
            id = 'SetInvisible',
            params = {
                value = isInvisible
            }
        }

        if unit.getController then
            if isSinglePlayer == true then
                unit:getGroup():getController():setCommand(commmand)
            else
                unit:getController():setCommand(commmand)
            end
        end
    end

end

---@class RespawnManager
---@field private _config RespawnManagerConfig
---@field private _triggerZones Array<TriggerZone>
---@field private _unitManager UnitManager
local RespawnManager = {}
do

    ---@class RespawnManagerConfig
    ---@field inReviveZone boolean
    ---@field onTankerConnect boolean
    ---@field onLanding boolean


    ---@class RedFlagTriggerZone
    ---@field name string
    ---@field id string
    ---@field private type string
    ---@field private radius number
    ---@field private verticies Array<Vec3>
    ---@field private position Vec3
    local TriggerZone = {}
    do
        ---comment
        ---@param triggerZoneObject table
        ---@returns TriggerZone
        function TriggerZone.New(triggerZoneObject)

            TriggerZone.__index = TriggerZone
            local self = setmetatable({}, TriggerZone)

            self.name = triggerZoneObject["name"]
            self.id = triggerZoneObject["zoneId"]

            self.position = { x = triggerZoneObject["x"], z = triggerZoneObject["y"], y = 0 }
            self.type = triggerZoneObject["type"]
            self.radius =  triggerZoneObject["radius"]

            if self.type == 2 then
                -- load verticies

                local verts = triggerZoneObject["verticies"]
                if verts and #verts > 0 then
                    self.verticies = {}
                    self.verticies[1] = { x = verts[4].x, y = 0, z = verts[4].z }
                    self.verticies[2] = { x = verts[3].x, y = 0, z = verts[3].z }
                    self.verticies[3] = { x = verts[2].x, y = 0, z = verts[2].z }
                    self.verticies[4] = { x = verts[1].x, y = 0, z = verts[1].z }
                end
            end
            return self
        end

        ---@param pos Vec3
        ---@returns boolean
        function TriggerZone:isInZone(pos)

            if self.type == 2 then
                return self:isInPolygon(pos)
            end

            return self:isInCilinder(pos)
        end

        ---@private
        ---@param point Vec3
        ---@returns boolean
        function TriggerZone:isInPolygon(point)

            ---@param polygon Array<Vec3>
            ---@param x number
            ---@param z number
            ---@return boolean
            local function isInComplexPolygon(polygon, x, z)
                local function getEdges(poly)
                    local result = {}
                    for i = 1, #poly do
                        local point1 = poly[i]
                        local point2Index = i + 1
                        if point2Index > #poly then point2Index = 1 end
                        local point2 = poly[point2Index]
                        local edge = { x1 = point1.x, z1 = point1.z, x2 = point2.x, z2 = point2.z }
                        table.insert(result, edge)
                    end
                    return result
                end
    
                local edges = getEdges(polygon)
                local count = 0;
                for _, edge in pairs(edges) do
                    if (x < edge.x1) ~= (x < edge.x2) and z < edge.z1 + ((x - edge.x1) / (edge.x2 - edge.x1)) * (edge.z2 - edge.z1) then
                        count = count + 1
                        -- if (yp < y1) != (yp < y2) and xp < x1 + ((yp-y1)/(y2-y1))*(x2-x1) then
                        --     count = count + 1
                    end
                end
                return count % 2 == 1
            end
            return isInComplexPolygon(self.verticies, point.x, point.z)
        end

        ---@private
        ---@param point Vec3
        ---@returns boolean
        function TriggerZone:isInCilinder(point)
            if (((point.x - self.position.x) ^ 2 + (point.z - self.position.z) ^ 2) ^ 0.5 <= self.radius) then
                return true
            end
            return false
        end
    end

    ---@param self RespawnManager
    local checkZonesTask = function (self, time)
        self:CheckUnits()
        return time + 5
    end

    ---@param respawnManagerConfig RespawnManagerConfig
    ---@param unitManager UnitManager
    ---@returns RespawnManager
    RespawnManager.New = function(respawnManagerConfig, unitManager)
        RespawnManager.__index = RespawnManager
        local self = setmetatable({}, RespawnManager)
        self:LoadZones()
        self._unitManager = unitManager
        self._config = respawnManagerConfig

        if self._config.inReviveZone == true then
            timer.scheduleFunction(checkZonesTask, self, timer.getTime() + 5)
        end

        return self
    end

    function RespawnManager:CheckUnits()
        local players = self._unitManager:getDeadPlayers()

        Log.debug("Dead Units: " .. tostring(#players))

        for _, unitName in pairs(players) do
            local unit = Unit.getByName(unitName)
            if unit then
                for _, zone in pairs(self._triggerZones) do
                    if zone:isInZone(unit:getPoint()) == true then
                        self._unitManager:markUnitAlive(unit, true)
                    end
                end
            end
        end
    end

    ---@private
    function RespawnManager:LoadZones()
        self._triggerZones = {}
        for i, trigger_zone in pairs(env.mission.triggers.zones) do
            local triggerZone = TriggerZone.New(trigger_zone)

            if Util.startsWith(triggerZone.name, "respawnzone_", true) == true then
                table.insert(self._triggerZones, triggerZone)
            end
        end
    end

    function RespawnManager:OnRefuelingStart(unit)
        if unit and unit:inAir() == true then
            if self._config.onTankerConnect == true then
                self._unitManager:markUnitAlive(unit, true)
            end
        end
    end

    ---@param unit table
    ---@param base table
    function RespawnManager:OnUnitLanded(unit, base)

        if base == nil then return end
        if unit == nil then return end

        if self._config.onLanding == true then
            self._unitManager:markUnitAlive(unit, true)
        end
    end
end

---@class InvincibilityManager
---@field autoCheckInterval number
---@field private _forcedUnits table<string, boolean>
---@field private _config InvincibleConfig
---@field private _invincibleUnits table<string, boolean>
---@field private _notifier Notifier
local InvincibilityManager = {}
do -- InvincibilityManager

    ---comment
    ---@param self InvincibilityManager
    ---@param time any
    local checkInvinsibilityTask = function(self, time)

        local checkGroups = function(groups)
            for _, group in ipairs(groups) do
                if group and group:isExist() then
                    for _, unit in ipairs(group:getUnits()) do
                            if unit then
                            self:CheckUnit(unit)
                        end
                    end
                end
            end
        end

        local checkAll = function()
            -- Check all coalitions
            for i = 0, 2 do
                local groups = coalition.getGroups(i, 0)
                checkGroups(groups)

                local helos = coalition.getGroups(i, 1)
                checkGroups(helos)
            end
        end


        checkAll()
        return time + self.autoCheckInterval
    end

    ---@class InvincibleConfig
    ---@field autoEnable boolean
    ---@field autoOutsideZone boolean

    ---comment
    ---@param config InvincibleConfig
    ---@param notifier Notifier
    ---@return InvincibilityManager
    function InvincibilityManager.New(config, notifier)
        InvincibilityManager.__index = InvincibilityManager
        local self = setmetatable({}, InvincibilityManager)
        self._config = config
        self._forcedUnits = {}
        self._invincibleUnits = {}
        self._notifier = notifier
        self.autoCheckInterval = 5

        if config.autoEnable == true then
            timer.scheduleFunction(checkInvinsibilityTask, self, timer.getTime() + 5)
        end
        return self
    end 

    function InvincibilityManager:resetUnit(unit)
        self._forcedUnits[unit:getName()] = nil
        self._invincibleUnits[unit:getName()] = false
    end

    function InvincibilityManager:resetUnitDelayed(unit, delaySeconds)

        ---comment
        ---@param input table
        local task = function(input, time)
            input.self:resetUnit(input.unit)
            return nil
        end

        timer.scheduleFunction(task, {self = self, unit = unit }, timer.getTime() + 5)
    end

    ---comment
    ---@param unit table
    function InvincibilityManager:setMortal(unit, force)
        SetImmortal = {
            id = 'SetImmortal',
            params = {
                value = false
            }
        }

        if unit.getController and unit.getName and (self._forcedUnits[unit:getName()] ~= true or force == true) then
            if isSinglePlayer == true then 
                unit:getGroup():getController():setCommand(SetImmortal)
            else
                unit:getController():setCommand(SetImmortal)
            end
            
            self._invincibleUnits[unit:getName()] = false

            if force == true then
                self._forcedUnits[unit:getName()] = true
            end

            self._notifier:NotifyNotInvinsible(unit)
        end
    end

    
    function InvincibilityManager:setImmortal(unit, force)
        SetImmortal = {
            id = 'SetImmortal',
            params = {
                value = true
            }
        }

        if unit.getController and unit.getName and (self._forcedUnits[unit:getName()] ~= true or force == true) then
            if isSinglePlayer == true then 
                unit:getGroup():getController():setCommand(SetImmortal)
            else
                unit:getController():setCommand(SetImmortal)
            end
            
            self._invincibleUnits[unit:getName()] = true
            
            if force == true then
                self._forcedUnits[unit:getName()] = true
            end

            self._notifier:NotifyInvinsible(unit)
        end
    end

    function InvincibilityManager:CheckUnit(unit)
        if self._forcedUnits[unit:getName()] == true then
            return
        end

        local isPlayer = function(unit)
            local players = coalition.getPlayers(unit:getCoalition())
            for _, player in pairs(players) do
                if player:getID() == unit:getID() then
                    return true
                end
            end
            return false
        end

        ---@return boolean
        local shouldBeInvinsible = function(u)
            if unit:inAir() == true then
                return true
            end

            return false
        end

        if unit:getDesc().category == Unit.Category.AIRPLANE or unit:getDesc().category == Unit.Category.HELICOPTER then
            if shouldBeInvinsible(unit) == true then
                if self._invincibleUnits[unit:getName()] ~= true then
                    self:setImmortal(unit)
                end
            else
                if self._invincibleUnits[unit:getName()] ~= false then
                    self:setMortal(unit)
                end
            end
        end
    end
end

---@class CrashManager
---@field private _invincibilityManager InvincibilityManager
---@field private _fpms table<string, table<integer,fpmData>>
local CrashManager = {}
do

    ---@class fpmData
    ---@field time number
    ---@field MperS number

    ---comment
    ---@param self CrashManager
    ---@param time any
    ---@return unknown
    local backgroundTask = function(self, time)
        self:UpdateVectors()
        return time + 1
    end

    ---comment
    ---@param invincibilityManager InvincibilityManager
    ---@return CrashManager
    function CrashManager.New(invincibilityManager)

        CrashManager.__index = CrashManager
        local self = setmetatable({}, CrashManager)

        self._invincibilityManager = invincibilityManager
        self._fpms = {}

        timer.scheduleFunction(backgroundTask, self, timer.getTime() + 2)

        return self
    end

    function CrashManager:UpdateVectors()

        local updategroups = function(groups)
            for _ , group in pairs(groups) do
                for _, unit in pairs(group:getUnits()) do
                    local vec = unit:getVelocity()
                    
                    local name = unit:getName()
                    if not self._fpms[name] then self._fpms[name] = {} end
                    
                    local count = #self._fpms[name]

                    if count == 0 then
                        self._fpms[name][1] = {
                            time = timer.getTime(),
                            MperS = vec.y
                        }
                    else
                        if #self._fpms[name] > 1 then
                            self._fpms[name][2] = self._fpms[name][1]
                        end

                        self._fpms[name][2] = {
                            time = timer.getTime(),
                            MperS = vec.y
                        }
                    end

                end
            end
        end

        -- Check all coalitions
        for i = 0, 2 do
            local groups = coalition.getGroups(i, 0)
            updategroups(groups)

            local helos = coalition.getGroups(i, 1)
            updategroups(helos)
        end

    end

    function CrashManager:OnGroundTouch(unit, location)
        self._invincibilityManager:setMortal(unit, true)
        self._invincibilityManager:resetUnitDelayed(unit, 5)

        local isGearDown = unit:getDrawArgumentValue(0) > 0.5

        local fpmData = self._fpms[unit:getName()]
        if fpmData and #fpmData >= 1 then
            Log.debugOutText("checking crash", 10)


            if isGearDown == true then
                -- a little more leniency or maybe just disregard it entirely
                Log.debugOutText("checking crash with gear down", 10)

                local last = fpmData[#fpmData]
                if timer.getTime() - last.time < 0.3 then
                    last = fpmData[#fpmData-1]
                end

                if last.MperS < -15 then --- 15m/s is about 3000fpm
                    trigger.action.explosion(unit:getPoint(), 1000)
                end
            else 
                -- when "crashing"
                Log.debugOutText("checking crash with gear up", 10)

                local last = fpmData[#fpmData]
                if timer.getTime() - last.time < 0.3 then
                    last = fpmData[#fpmData-1]
                end

                Log.debugOutText("last fpms: " .. last.MperS, 10)
                if last.MperS < -8 then --- 8m/s is about 1500fpm
                    trigger.action.explosion(unit:getPoint(), 1000)
                end
    
            end

        end
    end

end


---@class WeaponManager
---@field private _deletedWeapons Array<Weapon>
---@field private _missileSpeeds table<string, number>
---@field private _closingSpeeds table<string, table<integer, number>>
---@field private _notifier Notifier
---@field private _unitManager UnitManager
---@field private _config WeaponManagementConfig
local WeaponManager = {}
do

    ---@class WeaponManagementConfig
    ---@field deadUnitAAMissileBehaviour integer
    ---@field deadUnitAGWeaponBehaviour integer

    ---comment
    ---@param notifier Notifier
    ---@param unitManager UnitManager
    ---@param config WeaponManagementConfig
    ---@return WeaponManager
    function WeaponManager.New(notifier, unitManager, config)
        WeaponManager.__index = WeaponManager
        local self = setmetatable({}, WeaponManager)

        self._missileSpeeds = {}
        self._closingSpeeds = {}
        self._notifier = notifier
        self._unitManager = unitManager
        self._config = config

        self._deletedWeapons = {}
        return self
    end

    local function destroyWeaponForSure(weapon, time)
        if weapon and weapon:isExist() then
            local pos = weapon:getPoint()
            trigger.action.explosion(pos, 30)
        end
        
        return nil
    end

    do -- Guns

        local activeShooters = {}
        
        ---@type table<string, boolean>
        local gunKill = {}

        ---@type table<string, number>
        local gunHits = {}
        
        ---@class GunTrackingData
        ---@field shooter Unit
        ---@field target Unit
        ---@field unitManager UnitManager
        ---@field checkIndex integer
        ---@field lastVelocity Vec3
        ---@field lastTime number 

        ---comment
        ---@param data GunTrackingData
        ---@param time number
        local function TrackPossibleHitsTask(data, time)

            local shooter = data.shooter
            local target = data.target

            if Helpers.isPlayer(shooter:getID(), shooter:getCoalition()) ~= true then
                return nil
            end

            if shooter == nil or target == nil then
                return
            end

            if shooter:isExist() ~= true or target:isExist() ~= true then
                return
            end

            if data.checkIndex > 0 and activeShooters[shooter:getName()] == false then
                return
            end

            local shooterV = shooter:getVelocity()
            local targetV = target:getVelocity()

            if Config and Config.KillParameters and Config.KillParameters.GunKillOnlyRearAspect == true then
                    
                local aspect = Helpers.vecAlignment(shooterV, targetV)

                if aspect < 0.1 then
                    Log.debugOutText("Shot scrapped, only tail aspect shots count", 1)
                    return
                end
            end

            data.checkIndex = data.checkIndex + 1

            local magnitude = Helpers.vectorMagnitude(shooterV)
            local bulletStartPos = shooter:getPoint()

            ---@param unit Unit
            local getBulletVelocity = function(unit)

                local unitType = unit:getTypeName()
                
                local gunData = {}
                gunData["MiG-29A"] = 900

                local velocity = 1000

                if gunData[unitType] ~= nil then
                    velocity = gunData[unitType]
                end

                Log.debugOutText("using unit type: " .. unitType .. " and vel: " .. velocity, 1)

                return velocity
            end

            local bulletVelocity = getBulletVelocity(shooter)

            local bulletV = Helpers.vecSetMagnitude(shooterV, magnitude + bulletVelocity)
            local targetPos = target:getPoint()
            
            local currentTime = timer.getTime()

            local multiplier = 1 / (currentTime - data.lastTime)

            local acceleration = {
                x = (targetV.x - data.lastVelocity.x) * multiplier,
                y = (targetV.y - data.lastVelocity.y) * multiplier,
                z = (targetV.z - data.lastVelocity.z) * multiplier
            }

            data.lastVelocity = targetV
            data.lastTime = currentTime

            local isHit = Helpers.vecCollision(bulletStartPos, bulletV, targetPos, targetV, acceleration)

            Log.debugOutText("hit: " .. tostring(isHit), 1)

            if isHit == true then
                if not gunHits[target:getName()] then gunHits[target:getName()] = 0 end

                gunHits[target:getName()] = gunHits[target:getName()] + 1

                if gunHits[target:getName()] > 3 then
                    data.unitManager:registerGunKill(shooter, target)
                end
            end

            return time + 0.2
        end

        ---comment
        ---@param shooter Unit
        function WeaponManager:StartTrackingGun(shooter)

            if self._unitManager:isUnitAlive(shooter:getName()) == false then
                self._notifier:DenyShot(shooter)
                return
            end

            activeShooters[shooter:getName()] = true

            local maxRange = 2000 --meters
            ---@type VolumePyramid
            local volumeArea = {
                id = world.VolumeType.PYRAMID,
                params = {
                    pos = shooter:getPosition(),
                    length = maxRange,
                    halfAngleHor = math.rad(20),
                    halfAngleVer = math.rad(20)
                }
            }

            ---@type Unit
            local foundAircraft = nil

            ---@param foundItem Object
            ---@param originObject Unit
            local foundObject = function(foundItem, originObject)
                if
                    foundAircraft == nil
                    and foundItem:getCategory() == Object.Category.UNIT
                    and Unit.getDesc(foundItem).category == Unit.Category.AIRPLANE
                    and foundItem:getName() ~= originObject:getName()
                then
                    foundAircraft = foundItem --[[@as Unit]]
                end
            end

            world.searchObjects(Object.Category.UNIT, volumeArea, foundObject, shooter)

            if foundAircraft == nil then return end
            Log.debugOutText("found target: " .. foundAircraft:getName(), 2)

            local velocity = foundAircraft:getVelocity()

            ---@type GunTrackingData
            local data = {
                shooter = shooter,
                target = foundAircraft,
                checkIndex = 0,
                lastVelocity = {
                    x = velocity.x,
                    y = velocity.y,
                    z = velocity.z
                },
                lastTime = timer.getTime(),
                unitManager = self._unitManager
            }

            timer.scheduleFunction(TrackPossibleHitsTask, data, timer.getTime() + 0.2)
        end

        function WeaponManager:StopTrackingGun(shooter)
            activeShooters[shooter:getName()] = false
        end
    
    end


    function WeaponManager.ExplodeWeapon(weapon)
        local pos = weapon:getPoint()
        trigger.action.explosion(pos, 5)
        timer.scheduleFunction(destroyWeaponForSure, weapon, timer.getTime() + 2)
    end

    function WeaponManager:weaponFired(shooter, weapon)

        local isShooterDead = self._unitManager:isUnitAlive(shooter:getName()) == false

        if weapon and weapon:getDesc().category == Weapon.Category.MISSILE
        and weapon:getDesc().missileCategory == Weapon.MissileCategory.AAM then
            
            -- AA Missiles
            if isShooterDead == false or self._config.deadUnitAAMissileBehaviour == 1 then
                self._notifier:CopyShotDelayed(shooter, 2)
                local target = weapon:getTarget() -- can be nil
                self:startTrackingMissile(shooter, target, weapon)
            elseif isShooterDead == true then
                
                self.ExplodeWeapon(weapon)
                self._deletedWeapons[weapon:getName()] = weapon

                self._notifier:DenyShot(shooter)
            end
        else

            -- AG WEAPONS
            if Helpers.isPlayer(shooter:getID(), shooter:getCoalition()) == true then
                if isShooterDead == true then
                    if self._config.deadUnitAGWeaponBehaviour == 1 then
                        self:startTrackingAgMunitionForDeletion(shooter, weapon)
                    elseif self._config.deadUnitAGWeaponBehaviour == 2 then
                        -- do nothing special
                    else
                        -- destroy and deny shot
                        weapon:destroy()
                        self._notifier:DenyShot(shooter)
                    end
                end
            end

        end
    end

    ---@class MissileTrackingData
    ---@field self WeaponManager
    ---@field shooter Unit
    ---@field missile Weapon
    ---@field shotlocation Vec3
    ---@field target Unit
    ---@field shotTime number
    ---@field lastValidTargetTime number
    ---@field lastPositiveClosure number
    ---@field checkIncrement integer

    ---@param missile Weapon
    ---@param target Unit
    local getClosingSpeed = function(missile, target)
        
        local relative =  Helpers.vecSub(missile:getVelocity(), target:getVelocity())
        local missileAlign = Helpers.vecAlignment(relative, missile:getVelocity())

        if missileAlign > 0 then
            return Util.vectorMagnitude(relative)
        end
        
        return 0 - Util.vectorMagnitude(relative)
    end

    ---@param data MissileTrackingData
    ---@param time unknown
    ---@return number?
    function WeaponManager:trackMissile(data, time)

        data.checkIncrement = data.checkIncrement + 1
        local missile = data.missile

        if missile == nil or missile:isExist() ~= true then
            self._notifier:NotifyMissedDelayed(data.shooter, 0)
            return nil
        end

        local target = missile:getTarget()

        -- if after 20 seconds a missile does not have a target it's not likely to hit anything. 
        -- not likely enough for a red flag scenario anyway
        if target == nil and timer.getTime() - data.lastValidTargetTime > 10 then
            self._notifier:NotifyMissed(data.shooter)
            return nil
        end

        target = data.target
        if target == nil or target:isExist() == false then
            return time + 0.5
        end

        data.lastValidTargetTime = timer.getTime()
        local closingSpeed = getClosingSpeed(missile, target --[[@as Unit]])

        if closingSpeed > 0 then
            data.lastPositiveClosure = timer.getTime()
        elseif timer.getTime() - data.lastPositiveClosure > 5 then
            self._notifier:NotifyMissedDelayed(data.shooter, 3)
            return nil
        end

        local distance = Util.getDistance3D(missile:getPoint(), target:getPoint())
        local tot = distance / closingSpeed

        Log.debugOutText("closure: " .. tostring(closingSpeed) .. "tot: " .. tostring(tot), 5)
        local checkInterval = distance / (closingSpeed * 2)

        if tot < 0.20 and closingSpeed > 20 then
            self._unitManager:registerHit(target --[[@as Unit]], data.shooter, missile)
            return nil
        end

        checkInterval = math.abs(checkInterval)
        if checkInterval > 5 then checkInterval = 5 end
        if data.checkIncrement < 10 then checkInterval = 0.2 end
        return time + checkInterval
    end

    ---@private
    ---@param shooter Unit
    ---@param target Unit
    ---@param missile Weapon
    function WeaponManager:startTrackingMissile(shooter, target, missile)
        ---@type MissileTrackingData
        local data = {
            self = self,
            target = target,
            missile = missile,
            shotlocation = shooter:getPoint(),
            shooter = shooter,
            shotTime = timer.getTime(),
            lastValidTargetTime = timer.getTime(),
            lastPositiveClosure = timer.getTime(),
            checkIncrement = 0
        }

        local missileTask = function(passedData, time)
            return data.self:trackMissile(passedData, time)
        end

        self._closingSpeeds[Object.getName(missile)] = {} 
        timer.scheduleFunction(missileTask, data, timer.getTime() + 0.3)
    end
    

    ---@class AgMunitionData
    ---@field self WeaponManager
    ---@field shooter table
    ---@field weapon table

    ---@param data AgMunitionData
    function WeaponManager:trackAgMunitionForDeletion(data, time)

        if not data or not data.weapon then return nil end
        local weapon = data.weapon

        if not weapon then return nil end

        local pos = weapon:getPoint()
        local ground = land.getHeight({ x = pos.x, y = pos.z })
        local MpS = weapon:getVelocity().y * 2 -- increase the speed to make sure you don't miss it.

        if MpS > 0 then
            return time + 3
        end

        local nextInterval = (pos.y - ground) / math.abs(MpS)

        local deletableByDistance = false
        if weapon.getTarget and weapon:getTarget() ~= nil then
            local target = weapon:getTarget()
            
            if Util.distance(weapon:getPoint(), target:getPoint()) < 100 then
                deletableByDistance = true
            end
        end

        Log.debugOutTextForUnit(data.shooter:getID(), "agl: " .. pos.y - ground .. " || speed: " .. MpS .. " || nextInterval: " .. nextInterval .. " || " .. tostring(deletableByDistance) , 3)

        if nextInterval < 0.5 or deletableByDistance == true then
            weapon:destroy()
            return nil
        end

        if nextInterval > 5 then
            nextInterval = 5
        end

        return time + nextInterval
    end

    ---@private
    ---@param shooter table
    ---@param weapon table
    function WeaponManager:startTrackingAgMunitionForDeletion(shooter, weapon)

        ---@type AgMunitionData
        local data = {
            self = self,
            weapon = weapon,
            shooter = shooter
        }

        local weaponTrackTask = function(data, time)
            return self:trackAgMunitionForDeletion(data, time)
        end

        timer.scheduleFunction(weaponTrackTask, data, timer.getTime() + 0.5)
    end
end

---@class EventHandler
---@field private _unitManager UnitManager
---@field private _notifier Notifier
---@field private _crashManager CrashManager
---@field private _weaponsManager WeaponManager
---@field private _respawnManager RespawnManager
local EventHandler = {}
do -- Event Handler

    ---comment
    ---@param unitManger UnitManager
    ---@param notifier Notifier
    ---@param crashManager CrashManager
    ---@param weaponManager WeaponManager
    ---@param respawnManager RespawnManager
    ---@return EventHandler
    function EventHandler.New(unitManger, notifier, crashManager, weaponManager, respawnManager)
        EventHandler.__index = EventHandler
        local self = setmetatable({}, EventHandler)
        self._unitManager = unitManger
        self._notifier = notifier
        self._crashManager = crashManager
        self._weaponsManager = weaponManager
        self._respawnManager = respawnManager
        return self
    end

    function EventHandler:onEvent(e)
        local id = e.id

        if id == nil or id == 0 then
            return
        end 

        Log.debug("Receiving event: " .. tostring(id))

        if id == world.event.S_EVENT_SHOOTING_START then
            local shooter = e.initiator
            if self._unitManager:isUnitAlive(shooter:getName()) == false then
                self._notifier:DenyShot(shooter)
            else 
                self._weaponsManager:StartTrackingGun(shooter)
            end
        elseif id == world.event.S_EVENT_SHOOTING_END then
            local shooter = e.initiator
            self._weaponsManager:StopTrackingGun(shooter)

        elseif id == world.event.S_EVENT_SHOT then
            local shooter = e.initiator
            local weapon = e.weapon
            self._weaponsManager:weaponFired(shooter, weapon)
        elseif id == world.event.S_EVENT_HIT then
            local shooter = e.initiator
            local target = e.target
            local weapon = e.weapon
            Log.debug("unit got hit: " .. target:getName())
            self._unitManager:registerHit(target, shooter, weapon)
        elseif id == world.event.S_EVENT_BIRTH then
            local unit = e.initiator
            if unit:getCategory() == Object.Category.UNIT then
                if unit:getDesc().category == Unit.Category.AIRPLANE or unit:getDesc().category == Unit.Category.HELICOPTER then
                    self._unitManager:OnUnitBirth(e.initiator)
                end
            end
        elseif id == world.event.S_EVENT_RUNWAY_TOUCH then
            local unit = e.initiator

            self._crashManager:OnGroundTouch(unit)
        elseif id == world.event.S_EVENT_REFUELING then
            local unit = e.initiator
            self._respawnManager:OnRefuelingStart(unit)
        elseif id == world.event.S_EVENT_LAND then
            local unit = e.initiator
            local airbase = e.place
            self._respawnManager:OnUnitLanded(unit, airbase)
        end
    end
end


do -- init config
    if Config == nil then
        Config = {}
    end

    if Config.AutoInvulnerableSettings == nil then
        Config.AutoInvulnerableSettings = {}
    end

    if Config.DeadUnitWeapons == nil then
        Config.DeadUnitWeapons = {}
    end

    if Config.Revive == nil then
        Config.Revive = {}
    end
end

---@type NotificationConfig
local notificationConfig = {
    CallsignDelimiter = Config.CallSignDelimiter or "|"
}
local notifier = Notifier.New(notificationConfig)

---@type InvincibleConfig
local invincibilityConfig = {
    autoEnable = Config.AutoInvulnerableSettings.Enabled or true,
    autoOutsideZone = Config.AutoInvulnerableSettings.OutsideVulnerableZone or true
}

---@type WeaponManagementConfig
local weaponManagerConfig = {
    deadUnitAAMissileBehaviour = Config.DeadUnitWeapons.AAWeaponsBehaviour or 0,
    deadUnitAGWeaponBehaviour = Config.DeadUnitWeapons.AGWeaponsBehaviour or 0
}

local invisibilityManager = InvincibilityManager.New(invincibilityConfig, notifier)
local unitManager = UnitManager.New(invisibilityManager, notifier)
local weaponsManager = WeaponManager.New(notifier, unitManager, weaponManagerConfig)

local crashManager = CrashManager.New(invisibilityManager)

---@type RespawnManagerConfig
local respawnManagerConfig = {
    onLanding = Config.Revive.Landing or true,
    onTankerConnect = Config.Revive.TankerConnect or true,
    inReviveZone = Config.Revive.InRespawnZone or true
}

local respawnManager = RespawnManager.New(respawnManagerConfig, unitManager)

local eventHandler = EventHandler.New(unitManager, notifier, crashManager, weaponsManager, respawnManager)
world.addEventHandler(eventHandler)

Log.info("Version: " .. version)
Log.info("Started")