--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Identifiers = require(script.Parent.Identifiers)
local LazyConnection = require(script.Parent.LazyConnection)
local Promise = require(script.Parent.Packages.Promise)
local runIfNotBlocked = require(script.Parent.middleware.runIfNotBlocked)
local runTransformers = require(script.Parent.middleware.runTransformers)

local IS_SERVER = RunService:IsServer()
local BLOCK = newproxy(true)
local METATABLE = {
    __tostring = function(self)
        return `ServerChannel<{self.identifier}>`
    end
}

local function ServerChannel(remote: RemoteEvent, name: string, middlewares: { [any]: (...any) -> ...any }?)
    assert(IS_SERVER, "Attempt to construct a ServerChannel on the client")
    local serverChannel = setmetatable({ type = "channel", name = name }, METATABLE)
    local remoteIdentifier = Identifiers.registerIdentifier(remote, name)
    
    local fireAllClientsTransformers = {}
    local beforeFireClientTransformers = {}
    local beforeOnServerEventTransformers = {}

    local subscribeToServerEvent = LazyConnection(remote.OnServerEvent, function(dispatch)
        return function(...)
            runTransformers(beforeOnServerEventTransformers)
        end
    end)

    local function fireAllClients(...)
        runIfNotBlocked(
            function(...)
                remote:FireAllClients(...)
            end,

            runTransformers(fireAllClientsTransformers, remoteIdentifier, ...)
        )
    end

    local function fireClient(player: Player, ...)
        runIfNotBlocked(
            function(...)
                remote:FireClient(...)
            end,

            runTransformers(fireAllClientsTransformers, player, remoteIdentifier, ...)
        )
    end

    if middlewares then
        for _, startMiddleware in middlewares do
            local middleware = startMiddleware() 
            
            if middleware.beforeFireAllClients then
                table.insert(fireAllClientsTransformers, middleware.beforeFireAllClients(BLOCK))
            end

            if middleware.beforeFireClient then
                table.insert(beforeFireClientTransformers, middleware.beforeFireClient(BLOCK))
            end

            if middleware.beforeOnServerEvent then
                table.insert(beforeOnServerEventTransformers, middleware.beforeOnServerEvent(BLOCK))
            end
        end
    end

    function serverChannel:sendToAll(...)
        fireAllClients(...)
    end

    function serverChannel:sendTo(playerOrPlayers: Player | { [any]: Player }, ...)
        if typeof(playerOrPlayers) == "table" then
            for _, player in playerOrPlayers do
                fireClient(player, ...)
            end
        else
            fireClient(playerOrPlayers, ...)
        end
    end

    function serverChannel:sendToAllExcept(player: Player, ...)
        for _, recipient in pairs(Players:GetPlayers()) do
            if player ~= recipient then
                fireClient(recipient, ...)
            end
        end
    end

    function serverChannel:sendFilter(filter, ...)
        for _, player in pairs(Players:GetPlayers()) do
            if filter(player) then
                fireClient(player, ...)
            end
        end
    end

    function serverChannel:expectFrom(player: Player, filter: ((player: Player, ...any) -> (any))?)
        return Promise.new(function(resolve, reject, onCancel)
            local connection

            local function onServerEvent(sender: Player, identifier, ...)
                if sender ~= player or identifier ~= remoteIdentifier then
                    return
                end

                if filter == nil or filter(player, ...) then
                    connection:Disconnect()
                    resolve(player, ...)
                end
            end

            connection = remote.OnServerEvent:Connect(function(...)
                runIfNotBlocked(onServerEvent, runTransformers(beforeOnServerEventTransformers, ...))
            end)

            onCancel(function()
                connection:Disconnect()
            end)
        end)
    end

    function serverChannel:expect(filter: ((player: Player, ...any) -> (any))?)
        return Promise.new(function(resolve, reject, onCancel)
            local connection
            connection = remote.OnServerEvent:Connect(function(sender, index, ...)
                if index ~= remoteIdentifier then
                    return
                end

                if filter == nil or filter(sender, ...) then
                    connection:Disconnect()
                    resolve(sender, ...)
                end
            end)

            onCancel(function()
                connection:Disconnect()
            end)
        end)
    end

    --- Subscribes to the channel - running the callback whenever a player sends data through it.
    function serverChannel:subscribe(cleanupTable: { [any]: any }, callback)
        local function onClientEvent(identifier, ...)
            if identifier ~= getId() then
                return
            end

            callback(...)
        end

        local connection = remote.OnServerEvent:Connect(function(...)
            runIfNotBlocked(onClientEvent, runTransformers(beforeOnServerEventTransformers, ...))
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

    return serverChannel
end

return ServerChannel