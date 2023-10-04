--!strict
local RunService = game:GetService("RunService")

local package = script.Parent.Parent
local Identifiers = require(package.Identifiers)

local IS_CLIENT = RunService:IsClient()
local MAX_REGISTRY_WAIT = 5

local function ClientNetworker(remote: RemoteEvent, name: string)
    assert(IS_CLIENT, "Attempt to construct a ClientEvent on the server")
    local clientNetworker = {}
    local getId

    do
        local id

        function getId()
            if id then
                return id
            end

            local timeoutWarning = task.delay(MAX_REGISTRY_WAIT, function()
                warn(debug.traceback(`Talkie: {clientNetworker} has not been registered on the server for {MAX_REGISTRY_WAIT} seconds - did you forget to create a channel on the server?`))
            end)

            id = Identifiers.awaitRegistry(remote, name):expect()
            task.cancel(timeoutWarning)
            return id
        end
    end

    --- Subscribes to the channel - running the callback whenever we receive server data through it.
    function clientNetworker:subscribe(cleanupTable: { [any]: any }, callback, filter: ((...any) -> any)?)
        local connection = remote.OnClientEvent:Connect(function(identifier, ...)
            if identifier ~= getId() or (filter ~= nil and filter(...)) then
                return
            end

            callback(...)
        end)

        --- Unsubscribes from the channel.
        local function unsubscribe()
            local cleanupIndex = table.find(cleanupTable, unsubscribe)

            if cleanupIndex then
                table.remove(cleanupTable, cleanupIndex)
            end

            connection:Disconnect()
        end

        table.insert(cleanupTable, unsubscribe)
        return unsubscribe
    end

    --- Subscribes to the channel and unsubscribers after the callback is called once.
    function clientNetworker:subscribeOnce(cleanupTable: { [any]: any }, callback, filter)
        local unsubscribe
        unsubscribe = clientNetworker:subscribe(cleanupTable, function(...)
            unsubscribe()
            callback(...)
        end, filter)

        return unsubscribe
    end

    function clientNetworker:getId()
        return getId()
    end

    return clientNetworker
end

return ClientNetworker