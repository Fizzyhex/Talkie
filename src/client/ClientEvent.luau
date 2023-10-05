--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Promise = require(ReplicatedStorage.Packages.Promise)
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

    function clientEvent:expect(filter)
        return Promise.new(function(resolve, _, onCancel)
            local unsubscribe = clientEvent:subscribeOnce(function(...)
                resolve(...)
            end, filter)

            onCancel(unsubscribe)
        end)
    end

    function clientEvent:expectFrom(player: Player)
        return clientEvent:expect(function(sender)
            return sender == player
        end)
    end

    clientEvent.subscribe = clientNetworker.subscribe
    clientEvent.subscribeOnce = clientNetworker.subscribeOnce
    return clientEvent
end

return ClientEvent