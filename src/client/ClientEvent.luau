--!strict
local RunService = game:GetService("RunService")

local ClientNetworker = require(script.Parent.ClientNetworker)

local IS_CLIENT = RunService:IsClient()
local METATABLE = {
    __tostring = function(self)
        return `ClientEvent<{self.name}>`
    end
}

local function ClientEvent(remote: RemoteEvent, name: string)
    assert(IS_CLIENT, "Attempt to construct a ClientEvent on the server")
    local clientNetworker = ClientNetworker(remote, name)
    local clientEvent = {
        type = "event",
        name = name,
    }
    setmetatable(clientEvent, METATABLE)

    local function fireServer(...)
        remote:FireServer(clientNetworker:getId(), ...)
    end

    function clientEvent:send(...)
        fireServer(...)
    end

    clientEvent.subscribe = clientNetworker.subscribe
    clientEvent.subscribeOnce = clientNetworker.subscribeOnce
    return clientEvent
end

return ClientEvent