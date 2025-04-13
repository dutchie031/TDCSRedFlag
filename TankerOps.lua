

---@class ConnectionData
---@field connectedAt number
---@field unit Unit
---@field fuelAtStart number
---@field isConnected boolean

---@class TankerOpsManager : EventHandler
---@field private _connectedUnits table<string, ConnectionData>
local TankerOpsManager = {}

---@return TankerOpsManager
function TankerOpsManager.createAndStart()

    TankerOpsManager.__index = TankerOpsManager
    local self = setmetatable({}, TankerOpsManager)

    self._connectedUnits = {}
    
    world.addEventHandler(self)

    return self
end

---@param e Event
function TankerOpsManager:onEvent(e)

    

    
end


---@param unit Unit
function TankerOpsManager:onTankerConnect(unit)

    if self._connectedUnits[unit:getName()] == nil then
        self._connectedUnits[unit:getName()] = {
            unit = unit,
            connectedAt = timer.getTime(),
            fuelAtStart = unit:getFuel(),
            isConnected = true
        }
    end

end

---@param unit Unit
function TankerOpsManager:onTankerDisconnect(unit)

end
