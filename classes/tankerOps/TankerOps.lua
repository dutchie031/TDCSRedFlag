

---@class ConnectionData
---@field connectedAt number
---@field unit Unit
---@field fuelAtStart number

---@class TankerOpsManager : TankerDisconnectHandler, TankerConnectHandler
---@field private _connectedUnits table<string, ConnectionData>
local TankerOpsManager = {}

---@class TankerOpsManager
function TankerOpsManager.New()

    TankerOpsManager.__index = TankerOpsManager
    local self = setmetatable({}, TankerOpsManager)

    self._connectedUnits = {}
    


    return self
end



---@param unit Unit
function TankerOpsManager:OnTankerConnect(unit)

    self._connectedUnits[unit:getName()] = {
        unit = unit,
        connectedAt = timer.getTime(),
        fuelAtStart = unit:getFuel()
    }

end

---@param unit Unit
function TankerOpsManager:OnTankerDisconnect(unit)

end
