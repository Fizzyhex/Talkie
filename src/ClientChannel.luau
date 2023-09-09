--!strict
local RunService = game:GetService("RunService")

local Identifiers = require(script.Parent.Identifiers)
local Promise = require(script.Parent.Packages.Promise)
local Symbols = require(script.Parent.Symbols)
local runTransformers = require(script.Parent.middleware.runTransformers)

local IS_CLIENT = RunService:IsClient()
local MAX_REGISTRY_WAIT = 5
local METATABLE = {
    __tostring = function(self)
        return `ClientChannel<{self.name}>`
    end
}

local function runIfNotBlocked(callback, arg1, ...)
    if arg1 == Symbols.Block then
        return nil
    end

    return callback(arg1, ...)
end

local function ClientChannel(remote: RemoteEvent, name: string, middlewares: { [any]: (...any) -> ...any })
    assert(IS_CLIENT, "Attempt to construct a ClientChannel on the server")
    local clientChannel = setmetatable({
        type = "channel",
        name = name,
    }, METATABLE)
    local clientEventTransformers = {}
    local fireServerTransformers = {}
    local getId

    if middlewares then
        for _, startMiddleware in middlewares do
            local middleware = startMiddleware() 
            
            if middleware.beforeOnClientEvent then
                table.insert(clientEventTransformers, middleware.beforeOnClientEvent(Symbols.Block))
            end

            if middleware.beforeFireServer then
                table.insert(fireServerTransformers, middleware.beforeFireServer(Symbols.Block))
            end
        end
    end

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
        runIfNotBlocked(
            function(...)
                remote:FireServer(...) 
            end,

            runTransformers(fireServerTransformers, getId(), ...)
        )
    end

    function clientChannel:expect(filter: ((...any) -> (any))?)
        return Promise.new(function(resolve, reject, onCancel)
            local connection

            local function onClientEvent(identifier, ...)
                if identifier ~= getId() then
                    return
                end

                if filter == nil or filter(...) then
                    connection:Disconnect()
                    resolve(...)
                end
            end

            connection = remote.OnClientEvent:Connect(function(...)
                onClientEvent(runTransformers(clientEventTransformers, ...))
            end)

            onCancel(function()
                connection:Disconnect()
            end)
        end)
    end

    --- Subscribes to the channel - running the callback whenever we receive server data through it.
    function clientChannel:subscribe(cleanupTable: { [any]: any }, callback)
        local function onClientEvent(identifier, ...)
            if identifier ~= getId() then
                return
            end

            callback(...)
        end

        local connection = remote.OnClientEvent:Connect(function(...)
            runIfNotBlocked(onClientEvent, runTransformers(clientEventTransformers, ...))
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