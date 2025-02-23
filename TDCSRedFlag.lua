--=========================================

-- BIG NOTE!!!
-- This script only works in DCS when it's being run a Dedicated Server.
-- This is due to a player slot or a client slot that has the same userID (when run from the game itself) the unit commands on the host don't work.


--[[

TDCS Red Flag is meant to create an environment where players can practice and fly without having to respawn like one would in a RED Flag event. 

Currently Implemented: 

- Killed calls
- Hit calls (delayed)
- PK Miss for missiles
- Gun kills (after X rounds)
- Missile kills

- AI RTB after being killed

- When dead all weapons will be deleted after being fired.

- Invisible after being shot. (No AI will shoot you)
- Auto immortal

- Respawn:
 - zones
 - AAR
 - Landing
]]--

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
    
    -- Delays are in seconds
    Delays = {
        MissDelay = 6,
        MissileKillDelay = 3,    -- Message TO the shooter, to the target any hits are always instant
        GunKillDelay = 0,        -- Message TO the shooter, to the target any hits are always instant
        MissMessageOnScreen = 5, -- Message TO the shooter
        DeathMessageOnScreenSeconds = 180
    },
    Messages = {
        --- replaceable variables:
        --- {{ callsign }} => replaces with the callsign (delimited first part)

        KilledMessage = "{{ callsign }}, You are dead, flow away from the action",
        MissMessage = "PK Miss",
        HitMessage = "PK Hit",
        CopyShotMessage = "{{ callsign }}, Copy Shot",
        GunKillMessage = "{{ callsign }}, Good guns, splash one",

        --- Messages that are sent to the server for LotATC and other tool users.
        ServerMessages = {
            UnitKilled = "{{ callsign }}, killed"
            
        }
    },
    -- Amount of registered hits before "death"
    KillParameters = {
        Bullets = 8,
        Missiles = 1
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
    DebugLog = true
}

--============================================
-- Devs TODO list
--============================================

--[[


MissileTracker:
TODO: MadDogged missiles.
TODO: Destroyed missiles

CrashManager:
TODO: Helicopter Difference?
TODO: Gear up parameters fpm
TODO: Landing on buildings?
TODO: Over G ? 

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
        if Config.DebugLog == true then
            trigger.action.outText(string, time)
        end
    end

    Log.debugOutTextForUnit = function(unitId, string, time)
        if Config.DebugLog == true then
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

    Helpers.vecToMs = function(vec)
        return (vec.x ^ 2 + vec.y ^ 2 + vec.z ^ 2) ^ 0.5
    end

    Helpers.vecSub = function(vec1, vec2)
        return { x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = vec1.z - vec2.z }
    end

    Helpers.normVec = function(vec)
        local magnitude = Helpers.vecToMs(vec)

        return {
            x = vec.x / magnitude,
            y = vec.y / magnitude,
            z = vec.z / magnitude
        }
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
        return template:gsub("{{ " .. key .. " }}", value):gsub("{{" .. key .. "}}", value)
    end

    ---@param shooter table
    function Notifier:NotifyMissed(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = self:NameToCallSign(name)
        net.send_chat_to(friendlyName .. ": " .. "PK Miss", 1)
        local message = self:Format(Config.Messages.MissMessage, "callsign", friendlyName)
        trigger.action.outTextForUnit(shooter:getID(), message, Config.Delays.MissMessageOnScreen)
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

        local message = self:Format(Config.Messages.KilledMessage, "callsign", friendlyName)
        net.send_chat_to(friendlyName .. ": " .. Config.Messages.KilledMessage, 1)

        if target.getID then
            trigger.action.outTextForUnit(target:getID(), message, Config.Delays.DeathMessageOnScreenSeconds)
        end
    end

    ---@param shooter table
    function Notifier:NotifyKill(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = self:NameToCallSign(name)
        net.send_chat_to(friendlyName .. ": " .. "PK Hit", 1)

        local message = self:Format(Config.Messages.HitMessage, "callsign", friendlyName)
        trigger.action.outTextForUnit(shooter:getID(), message, Config.Delays.MissMessageOnScreen)
    end

    ---@param shooter table
    ---@param delaySeconds number
    function Notifier:NotifyKillDelayed(shooter, delaySeconds)
        local notify = function(input, time)
            input.notifier:NotifyKill(input.shooter)
            return nil
        end

        timer.scheduleFunction(notify, { notifier = self, shooter = shooter } , timer.getTime() + delaySeconds)
    end

    ---@param shooter table
    function Notifier:NotifyGunKill(shooter)
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = self:NameToCallSign(name)
        net.send_chat_to(friendlyName .. ": " .. "Gun kill", 1)
        local message = self:Format(Config.Messages.GunKillMessage, "callsign", friendlyName)
        trigger.action.outTextForUnit(shooter:getID(), message, Config.Delays.MissMessageOnScreen)
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
        local name = shooter:getPlayerName() or shooter:getCallsign()
        local friendlyName = self:NameToCallSign(name)
        local message = self:Format(Config.Messages.CopyShotMessage, "callsign", friendlyName)
        trigger.action.outTextForUnit(shooter:getID(), message, 5)
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

    function UnitManager:getDeadPlayers()
        local result = {}
        for unitName, isDead in pairs(self.dead_players) do
            if isDead == true then
                table.insert(result, unitName)
            end
        end
    end

    ---Registers a hit
    ---@param target table
    ---@param shooter table
    ---@param weapon table
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

            self.invincibilityManager:setMortal(weapon)
            trigger.action.explosion(weapon:getPoint(), 30)

        end
    end

    function UnitManager:markUnitAlive(unit)
        Log.info("Marking " .. unit:getName() .. " as alive")
        self.dead_units[unit:getName()] = false
        self.bullet_hits[unit:getName()] = 0
        self.missile_hits[unit:getName()] = 0
    end

    ---comment
    ---@param unit table
    function UnitManager:markUnitDead(unit)
        Log.info("Marking " .. unit:getName() .. " as dead")
        self._notifier:NotifyKilled(unit)

        local commmand = {
            id = 'SetInvisible',
            params = {
                value = true
            }
        }

        if unit.getController then
            if isSinglePlayer == true then
                unit:getGroup():getController():setCommand(commmand)
            else
                unit:getController():setCommand(commmand)
            end
        end

        local function SendAIRtb(unit)
            AIHelpers.setDocile(unit)
            AIHelpers.sendRTB(unit)
            AIHelpers.setDocile(unit)
        end

        self.dead_units[unit:getName()] = true
        self.bullet_hits[unit:getName()] = 0
        self.missile_hits[unit:getName()] = 0


        if Helpers.isPlayer(unit:getID(), unit:getCoalition()) == false then
            SendAIRtb(unit)
        end
    end

    function UnitManager:OnUnitBirth(unit)
        self.dead_units[unit:getName()] = false
        self.bullet_hits[unit:getName()] = 0
        self.missile_hits[unit:getName()] = 0
    end

end


local RespawnManager = {}
do
    --[[
        TODO: Implement
    ]]

    RespawnManager.OnRefuelingStart = function(unit)
        
    end


    do
        local checkInterval = 5
        local checkDeadUnits = function(null, time)



            return time + checkInterval
        end

        timer.scheduleFunction(checkDeadUnits, {}, timer.getTime() + 5)
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

                    --[[
                        TODO: DEBUG LINE
                    ]]
                    trigger.action.outTextForUnit(unit:getID(), vec.y, 1)
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

                trigger.action.outText("last fpms: " .. last.MperS, 10) --[[ TODO: DEBUG ]]--
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


---@class MissileManager
---@field private _missileSpeeds table<string, number>
---@field private _closingSpeeds table<string, table<integer, number>>
---@field private _notifier Notifier
local MissileManager = {}
do
    ---comment
    ---@param notifier Notifier
    ---@return MissileManager
    function MissileManager.New(notifier)
        MissileManager.__index = MissileManager
        local self = setmetatable({}, MissileManager)

        self._missileSpeeds = {}
        self._closingSpeeds = {}
        self._notifier = notifier

        return self
    end


    ---@class MissileTrackingData
    ---@field shooter table
    ---@field missile table
    ---@field shotlocation table
    ---@field target table
    
    ---@param data MissileTrackingData
    ---@param time unknown
    ---@return nil
    function MissileManager:trackMissile(data, time)
        local distance = function(a, b)
            return math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
        end

        local isMissilePastTarget = function(shotLocation, missileLocation, targetLocation)
            local a = shotLocation
            local b = targetLocation
            local c = missileLocation

            local ab = distance(a, b)
            local ac = distance(a, c)

            if ac - 100 > ab then
                return true
            end

            return false
        end

        local isDecelerating = function(missile)
            local id = tostring(Object.getName(missile))

            local velocityVec = missile:getVelocity()
            local currentSpeed = Helpers.vecToMs(velocityVec)

            if not self._missileSpeeds[id] then
                self._missileSpeeds[id] = currentSpeed
            end

            local lastSpeed =self._missileSpeeds[id]
            local isSlowing = lastSpeed > currentSpeed

            return isSlowing, currentSpeed
        end


        local closingSpeed = function(missile, target)
            local relativeVector = Helpers.vecSub(missile:getVelocity(), target:getVelocity())

            local isCold = Helpers.vecAlignment(relativeVector, target:getVelocity()) > 0

            if isCold == false then
                return 0 - Helpers.vecToMs(relativeVector)
            else
                return Helpers.vecToMs(relativeVector)
            end
        end

        local target = data.target
        local missile = data.missile
        local shotLocation = data.shotlocation
        local shooter = data.shooter

        if missile:isExist() == false or target:isExist() == false then
            return nil
        end

        if isMissilePastTarget(shotLocation, missile:getPoint(), target:getPoint()) == true then
            self._notifier:NotifyMissedDelayed(shooter, Config.Delays.MissDelay or 5)
            return nil
        end

        local decelling, speed = isDecelerating(missile)
        if decelling == true and speed < 600 then
            local n = closingSpeed(missile, target)
            self._closingSpeeds[Object.getName(missile)][#self._closingSpeeds[Object.getName(missile)] + 1] = n
            if #self._closingSpeeds[Object.getName(missile)] >= 3 then
                local nMin1 = self._closingSpeeds[Object.getName(missile)][#self._closingSpeeds[Object.getName(missile)] - 1]
                local nMin2 = self._closingSpeeds[Object.getName(missile)][#self._closingSpeeds[Object.getName(missile)] - 2]

                Log.debug("Checking closing speeds " .. n .. " " .. nMin1 .. " " .. nMin2)

                if nMin2 < 0 and nMin1 < 0 and n < 0 and nMin2 > nMin1 and nMin1 > n then
                    -- when closing speed is negative and decreasing for 3 checks in a row the missile is trashed

                    --delete missile
                    missile:destroy()
                    self._notifier:NotifyMissedDelayed(shooter, Config.Delays.MissDelay or 5)
                    return nil
                end
            end
        end

        return time + 2
    end

    ---@param shooter any
    ---@param target any
    ---@param missile any
    function MissileManager:startTrackingMissile(shooter, target, missile)
        ---@type MissileTrackingData
        local data = {
            self = self,
            target = target,
            missile = missile,
            shotlocation = shooter:getPoint(),
            shooter = shooter,
            shotTime = timer.getTime()
        }

        local missileTask = function(passedData, time)
            return data.self:trackMissile(passedData, time)
        end

        self._closingSpeeds[Object.getName(missile)] = {} 
        timer.scheduleFunction(missileTask, data, timer.getTime() + 2)
    end

end

---@class EventHandler
---@field private _unitManager UnitManager
---@field private _notifier Notifier
---@field private _crashManager CrashManager
---@field private _missileManager MissileManager
local EventHandler = {}
do -- Event Handler

    ---comment
    ---@param unitManger UnitManager
    ---@param notifier Notifier
    ---@param crashManager CrashManager
    ---@param missileManager MissileManager
    ---@return EventHandler
    function EventHandler.New(unitManger, notifier, crashManager, missileManager)
        EventHandler.__index = EventHandler
        local self = setmetatable({}, EventHandler)
        self._unitManager = unitManger
        self._notifier = notifier
        self._crashManager = crashManager
        self._missileManager = missileManager
        return self
    end

    function EventHandler:onEvent(e)
        local id = e.id

        if id == nil or id == 0 then
            return
        end 

        Log.debugOutText("event: " .. e.id, 3)

        if id == world.event.S_EVENT_SHOOTING_START then
            local shooter = e.initiator
            if self._unitManager:isUnitAlive(shooter:getName()) == false then
                self._notifier:DenyShot(shooter)
            end
        elseif id == world.event.S_EVENT_SHOT then
            local shooter = e.initiator
            local weapon = e.weapon

            if self._unitManager:isUnitAlive(shooter:getName()) == false then
                weapon:destroy()
                self._notifier:DenyShot(shooter)
            elseif weapon and weapon:getDesc().category == Weapon.Category.MISSILE
                and weapon:getDesc().missileCategory == Weapon.MissileCategory.AAM
            then
                if Helpers.isPlayer(shooter:getID(), shooter:getCoalition()) == true then
                    self._notifier:CopyShotDelayed(shooter, 2)
                    local target = weapon:getTarget() -- can be nil
                    self._missileManager:startTrackingMissile(shooter, target, weapon)
                end
            end
        elseif id == world.event.S_EVENT_HIT then
            local shooter = e.initiator
            local target = e.target
            local weapon = e.weapon
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

local missileManager = MissileManager.New(notifier)
local invisibilityManager = InvincibilityManager.New(invincibilityConfig, notifier)
local crashManager = CrashManager.New(invisibilityManager)
local unitManager = UnitManager.New(invisibilityManager, notifier)
local eventHandler = EventHandler.New(unitManager, notifier, crashManager, missileManager)
world.addEventHandler(eventHandler)

Log.info("Started")