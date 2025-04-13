
---@class TankerConnectHandler
---@field OnTankerConnect fun(self:TankerConnectHandler, unit: Unit)

---@class TankerDisconnectHandler
---@field OnTankerDisconnect fun(self:TankerDisconnectHandler, unit: Unit)

---@class RedFlagEventHandler : EventHandler
---@field private _onTankerConnectedHandlers Array<TankerConnectHandler>
---@field private _onTankerDisconnectHandlers Array<TankerDisconnectHandler>
local RedFlagEventHandler = {}


local redFlagEventHandlerSingleton = nil

---@return RedFlagEventHandler
RedFlagEventHandler.GetOrCreate = function()

    if redFlagEventHandlerSingleton ~= nil then
        return redFlagEventHandlerSingleton
    end

    RedFlagEventHandler.__index = RedFlagEventHandler
    local self = setmetatable({}, RedFlagEventHandler)

    self._onTankerConnectedHandlers = {}
    self._onTankerDisconnectHandlers = {}

    world.addEventHandler(self)

    redFlagEventHandlerSingleton = self

    return self

end


function RedFlagEventHandler:onEvent(event)

    if event.id == world.event.S_EVENT_REFUELING then
        local unit = event.initiator --[[@as Unit]]
        for _, handler in ipairs(self._onTankerConnectedHandlers) do
            pcall(function()
                handler:OnTankerConnect(unit)
            end)
        end
    elseif event.id == world.event.S_EVENT_REFUELING_STOP then
        local unit = event.initiator --[[@as Unit]]
        for _, handler in ipairs(self._onTankerDisconnectHandlers) do
            pcall(function()
                handler:OnTankerDisconnect(unit)
            end)
        end
    end
end

---comment
---@param handler TankerConnectHandler
function RedFlagEventHandler:addTankerConnectHandler(handler)
    table.insert(self._onTankerConnectedHandlers, handler)
end

---comment
---@param handler TankerDisconnectHandler
function RedFlagEventHandler:addTankerDisconnectHandler(handler)
    table.insert(self._onTankerConnectedHandlers, handler)
end





if not RedFlag then RedFlag = {} end
RedFlag.EventHandler = RedFlagEventHandler