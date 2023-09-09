--!strict
local RunService = game:GetService("RunService")

local Identifiers = require(script.Parent.Identifiers)
local Promise = require(script.Parent.Packages.Promise)

local IS_CLIENT = RunService:IsClient()
local MAX_REGISTRY_WAIT = 5
local METATABLE = {
    __tostring = function(self)
        return `ClientChannel<{self.name}>`
    end
}

local function ClientChannel(remote: RemoteEvent, name: string)
    assert(IS_CLIENT, "Attempt to construct a ClientChannel on the server")
    local clientChannel = setmetatable({
        type = "channel",
        name = name,
    }, METATABLE)
    local getId

    do
        local id

        function getId()
            if id then
                return id
            end

            local timeoutWarning = task.delay(MAX_REGISTRY_WAIT, function()
                warn(debug.traceback(`Talkie: {clientChannel} has not been registered on the server for {MAX_REGISTRY_WAIT} seconds - did you forget to create a channel on the server?`))
            end)

            id = Identifiers.awaitRegistry(remote, name):expect()
            task.cancel(timeoutWarning)
            return id
        end
    end

    function clientChannel:send(...)
        remote:FireServer(getId(), ...)
    end

    function clientChannel:expect(filter: ((...any) -> (any))?)
        return Promise.new(function(resolve, reject, onCancel)
            local connection
            connection = remote.OnClientEvent:Connect(function(identifier, ...)
                if identifier ~= getId() then
                    return
                end

                if filter == nil or filter(...) then
                    connection:Disconnect()
                    resolve(...)
                end
            end)

            onCancel(function()
                connection:Disconnect()
            end)
        end)
    end

    --- Subscribes to the channel - running the callback whenever we receive server data through it.
    function clientChannel:subscribe(cleanupTable: { [any]: any }, callback)
        local connection = remote.OnClientEvent:Connect(function(identifier, ...)
            if identifier ~= getId() then
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

    return clientChannel
end

return ClientChannel