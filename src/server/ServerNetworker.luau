--!strict
local RunService = game:GetService("RunService")

local package = script.Parent.Parent
local Identifiers = require(package.Identifiers)

local IS_SERVER = RunService:IsServer()
local METATABLE = {
    __tostring = function(self)
        return `ServerNetworker<{self.identifier}>`
    end
}

local function ServerNetworker(remote: RemoteEvent, name: string)
    assert(IS_SERVER, "Attempt to construct a ServerEvent on the client")
    local serverNetworker = setmetatable({ type = "event", name = name }, METATABLE)
    local remoteIdentifier = Identifiers.registerIdentifier(remote, name)
    serverNetworker.id = remoteIdentifier

    --- Subscribes to the channel - running the callback whenever a player sends data through it.
    function serverNetworker:subscribe(callback, filter: ((...any) -> any)?)
        local connection = remote.OnServerEvent:Connect(function(player, identifier, ...)
            if identifier ~= remoteIdentifier or (filter ~= nil and not filter(player, ...)) then
                return
            end

            callback(player, ...)
        end)

        --- Unsubscribes from the channel.
        local function unsubscribe()
            connection:Disconnect()
        end

        return unsubscribe
    end

    --- Subscribes to the channel and unsubscribers after the callback is called once.
    function serverNetworker:subscribeOnce(callback, filter)
        local unsubscribe
        unsubscribe = serverNetworker:subscribe(function(...)
            unsubscribe()
            callback(...)
        end, filter)

        return unsubscribe
    end

    return serverNetworker
end

return ServerNetworker