

---The amount of seconds to regard it as 1 transfer in the overview (amount of pounds)
local DISCONNECT_GRACE_TIME_SECONDS = 30

local DEBUG = true

local OutTextDebug = function (message, time)
    if not time then time = 1 end
    if DEBUG == true then
        trigger.action.outText(message, time)
    end
end

---@class TankerConnectionData
---@field connectedAt number
---@field disconnectedAt number?
---@field unit Unit
---@field tanker Unit
---@field fuelMassMax number
---@field fuelAtStart number
---@field lastFuelState number
---@field lastFuelCheckTime number
---@field fuelAtDisconnect number
---@field isConnected boolean

---@class TankerOpsManager : EventHandler
---@field private _connectedUnits table<string, table<string, TankerConnectionData>> table<tankerName, table<unitName, connectedData>>
---@field private _unitConnectedTo table<string, string> table<unitName, tankerName>
local TankerOpsManager = {}

---@param self TankerOpsManager
local UpdateTankerStateTask = function (self, time)
    local interval = self:UpdateState()
    return time + interval
end

---@return TankerOpsManager
function TankerOpsManager.createAndStart()

    TankerOpsManager.__index = TankerOpsManager
    local self = setmetatable({}, TankerOpsManager)

    self._connectedUnits = {}
    self._unitConnectedTo = {}
    world.addEventHandler(self)

    timer.scheduleFunction(UpdateTankerStateTask, self, timer.getTime() + 5)

    return self
end

function TankerOpsManager:onEvent(e)

    if e.id == world.event.S_EVENT_REFUELING then
        local unit = e.initiator --[[@as Unit]]

        if unit ~= nil and unit.isExist and unit:isExist() == true and unit:inAir() == true then
            self:onTankerConnect(unit)
        end
    elseif e.id == world.event.S_EVENT_REFUELING_STOP then
        local unit = e.initiator --[[@as Unit]]

        if unit ~= nil and unit.isExist and unit:isExist() == true and unit:inAir() == true then
            self:onTankerDisconnect(unit)
        end
    end
end

---comment
---@return number nextDelay
function TankerOpsManager:UpdateState()
    local now = timer.getTime()
    for tankerName, connectedUnits in pairs(self._connectedUnits) do
        for unitName, data in pairs(connectedUnits) do
            if data.disconnectedAt and now - data.disconnectedAt > DISCONNECT_GRACE_TIME_SECONDS then
                self._connectedUnits[tankerName][unitName] = nil
            end
        end
    end
    self:SendMessage()
    return 2.2
end

---@private
function TankerOpsManager:SendMessage()

    ---@param data TankerConnectionData
    ---@return number?
    local calculateTakenFuel = function(data)

        if data.unit then
            local currentFuel = data.unit:getFuel()
            if data.disconnectedAt ~= nil then
                currentFuel = data.fuelAtDisconnect
            end
            
            local takenPercentage = currentFuel - data.fuelAtStart
            local absoluteFuel = takenPercentage * data.fuelMassMax
            local pounds = absoluteFuel * 2.20462
            return math.floor(pounds)
        end

        return nil
    end

    ---@param data TankerConnectionData
    ---@return number
    local calculateFuelFlowPerMinute = function (data)

        if data.disconnectedAt ~= nil then return 0 end

        if data.unit then
            local currentFuel = data.unit:getFuel()
            if data.disconnectedAt ~= nil then
                currentFuel = data.fuelAtDisconnect
            end

            local time = timer.getTime() - data.lastFuelCheckTime
            local fuelTaken = currentFuel - data.lastFuelState
            
            if time == 0 then return 0 end

            local absoluteFuel = fuelTaken * data.fuelMassMax
            local pounds = absoluteFuel * 2.20462
            local poundsPerMinute = (pounds / time) * 60

            return math.floor(poundsPerMinute)
        end
        return 0
    end

    ---comment
    ---@param tankerName string
    ---@param data table<string,TankerConnectionData>
    local formatTanker = function (tankerName, data)
        local text = tankerName .. "\n"

        local textAdded = false
        for unitName, connectionData in pairs(data) do
            if connectionData and connectionData.unit then
                textAdded = true
                local fuelTaken = calculateTakenFuel(connectionData)
                local fuelflow = calculateFuelFlowPerMinute(connectionData)
                text = text .. string.format("   %-10s %8s lbs %20s lbs/min", unitName, (tostring(fuelTaken) or "?" ), tostring(fuelflow)) .. " \n"
            end
        end

        if textAdded == false then
            text  = text .. "--- \n"
        end

        return text
    end

    local message = ""

    for tankerName, connectedUnits in pairs(self._connectedUnits) do
        local text = formatTanker(tankerName, connectedUnits)
        message = message .. text .. " \n"
    end

    if string.len(message) > 0 then
        trigger.action.outTextForCoalition(coalition.side.NEUTRAL, message, 2)

        if DEBUG then
            trigger.action.outText(message, 1)
        end
    end
end

---@private
---@param unit Unit
function TankerOpsManager:onTankerConnect(unit)

    ---@type Unit?
    local tanker = nil
    local tankerChecker = function(unit)

        if tanker == nil and Object.hasAttribute(unit, "Tankers") then
            tanker = unit --[[@as Unit]]
        end

    end

    ---@type Sphere
    local searchVolume = {
        id = world.VolumeType.SPHERE,
        params = {
            point = unit:getPoint(),
            radius = 100
        }
    }

    world.searchObjects(Object.Category.UNIT, searchVolume, tankerChecker)

    if tanker ~= nil then
        self._unitConnectedTo[unit:getName()] = tanker:getName()
        if self._connectedUnits[tanker:getName()] == nil then
            self._connectedUnits[tanker:getName()] = {}
        end
        if self._connectedUnits[tanker:getName()][unit:getName()] == nil then
            self._connectedUnits[tanker:getName()][unit:getName()] = {
                unit = unit,
                connectedAt = timer.getTime(),
                fuelAtStart = unit:getFuel(),
                isConnected = true,
                fuelMassMax = unit:getDesc().fuelMassMax,
                tanker = tanker,
                disconnectedAt = nil,
                fuelAtDisconnect = 0,
                lastFuelCheckTime = timer.getTime(),
                lastFuelState = unit:getFuel()
            }
        else
            self._connectedUnits[tanker:getName()][unit:getName()].disconnectedAt = nil
        end
    end
end

---@private
---@param unit Unit
function TankerOpsManager:onTankerDisconnect(unit)

    local tankerName = self._unitConnectedTo[unit:getName()]
    if tankerName == nil then return end
    if self._connectedUnits[tankerName] == nil then return end

    local data = self._connectedUnits[tankerName][unit:getName()]
    if data == nil then return end

    data.disconnectedAt = timer.getTime()
    data.fuelAtDisconnect = unit:getFuel()
end

env.info("[TankerOps] initialised")
local tankerOpsManager = TankerOpsManager.createAndStart()
env.info("[TankerOps] Started tanker ops")