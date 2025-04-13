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