--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Identifiers = require(script.Parent.Identifiers)
local Promise = require(script.Parent.Parent.Promise)
local TicketBooth = require(script.Parent.util.TicketBooth)

local IS_SERVER = RunService:IsServer()
local METATABLE = {
    __tostring = function(self)
        return `ServerChannel<{self.identifier}>`
    end
}

local function ServerChannel(remote: RemoteEvent, name: string)
    assert(IS_SERVER, "Attempt to construct a ServerChannel on the client")
    local serverChannel = setmetatable({ type = "channel", name = name }, METATABLE)
    local remoteIdentifier = Identifiers.registerIdentifier(remote, name)
    local nextTicket = TicketBooth()
    local ticketHandlerRegistered = false

    local function fireAllClients(...)
        remote:FireAllClients(remoteIdentifier, ...)
    end

    local function fireClient(player: Player, ...)
        remote:FireClient(player, remoteIdentifier, ...)
    end

    function serverChannel:sendToAll(...)
        fireAllClients(...)
    end

    function serverChannel:sendToClient(playerOrPlayers: Player | { [any]: Player }, ...)
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

    function serverChannel:waitForDataFrom(player: Player, filter: ((player: Player, ...any) -> (any))?)
        return Promise.new(function(resolve, reject, onCancel)
            local connection
            connection = remote.OnServerEvent:Connect(function(sender: Player, identifier, ...)
                if sender ~= player or identifier ~= remoteIdentifier then
                    return
                end

                if filter == nil or filter(player, ...) then
                    connection:Disconnect()
                    resolve(player, ...)
                end
            end)

            onCancel(function()
                connection:Disconnect()
            end)
        end)
    end

    function serverChannel:waitForData(filter: ((player: Player, ...any) -> (any))?)
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

    --- Ask a client for a response by opening a ticket. A timeout is required to prevent clients from hanging forever!
    function serverChannel:openTicket(player: Player, timeoutInSeconds: number)
        return function(...)
            local ticket = nextTicket()
            remote:FireClient(player, { remoteIdentifier, ticket }, ...)
    
            return Promise.new(function(resolve, reject, onCancel)
                local connection
                connection = remote.OnServerEvent:Connect(function(sender: Player, identifierTable, sentTicket, ...)
                    if sender == player and typeof(identifierTable) == "table" then
                        if identifierTable[1] == remoteIdentifier and identifierTable[2] == sentTicket then
                            connection:Disconnect()
                            local isRejection = identifierTable[3]
    
                            if isRejection then
                                reject(...)
                            else
                                resolve(...)
                            end
                        end
                    end
                end)
    
                onCancel(function()
                    connection:Disconnect()
                end)
            end):timeout(timeoutInSeconds)
        end
    end

    function serverChannel:setTicketHandler(cleanupTable, callback)
        assert(not ticketHandlerRegistered, "A ticket handler has already been registered")
        ticketHandlerRegistered = true

        local connection = remote.OnServerEvent:Connect(function(sender, identifierTable, ...)
            if typeof(identifierTable) == "table" and identifierTable[1] == remoteIdentifier then
                local unanswered = true
                local identifier = identifierTable[1]
                local ticket = identifierTable[2]
                
                local function resolve(...)
                    assert(unanswered, "A ticket cannot be replied to multiple times")
                    unanswered = false
                    remote:FireClient(sender, { identifier, ticket }, ...)
                end

                local function reject(...)
                    assert(unanswered, "A ticket cannot be replied to multiple times")
                    unanswered = false
                    remote:FireClient(sender, { identifier, ticket, true }, ...)
                end
                
                callback(resolve, reject)(...)
            end
        end)

        table.insert(cleanupTable, connection)
    end

    --- Subscribes to the channel - running the callback whenever a player sends data through it.
    function serverChannel:subscribe(cleanupTable: { [any]: any }, callback)
        local cleanupKey = newproxy(true)
        local connection = remote.OnServerEvent:Connect(function(player, identifier, ...)
            if identifier ~= remoteIdentifier then
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

    return serverChannel
end

return ServerChannel