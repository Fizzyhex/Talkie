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
    function serverNetworker:subscribe(cleanupTable: { [any]: any }, callback, filter: ((...any) -> any)?)
        local cleanupKey = newproxy(true)
        local connection = remote.OnServerEvent:Connect(function(player, identifier, ...)
            if identifier ~= remoteIdentifier or (filter ~= nil and not filter(player, ...)) then
                return
            end

            callback(player, ...)
        end)

        --- Unsubscribes from the channel.
        local function unsubscribe()
            cleanupTable[cleanupKey] = nil
            connection:Disconnect()
        end

        cleanupTable[cleanupKey] = connection
        return unsubscribe
    end

    --- Subscribes to the channel and unsubscribers after the callback is called once.
    function serverNetworker:subscribeOnce(cleanupTable: { [any]: any }, callback, filter)
        local unsubscribe
        unsubscribe = serverNetworker:subscribe(cleanupTable, function(...)
            unsubscribe()
            callback(...)
        end, filter)

        return unsubscribe
    end

    return serverNetworker
end

return ServerNetworker