--!strict
local RunService = game:GetService("RunService")

local package = script.Parent.Parent
local Promise = require(package.Parent.Promise)
local ServerNetworker = require(script.Parent.ServerNetworker)
local TicketBooth = require(package.util.TicketBooth)

local IS_SERVER = RunService:IsServer()
local METATABLE = {
    __tostring = function(self)
        return `ServerDelegate<{self.identifier}>`
    end
}

local function ServerDelegate(remote: RemoteEvent, name: string)
    assert(IS_SERVER, "Attempt to construct a ServerDelegate on the client")
    local serverDelegate = { type = "channel", name = name }
    setmetatable(serverDelegate, METATABLE)
    local serverNetworker = ServerNetworker(remote, name)
    local remoteIdentifier = serverNetworker.id
    local nextTicket = TicketBooth()
    local isCallbackRegistered = false

    --- Ask a client for a response by opening a ticket. A timeout is required to prevent clients from hanging forever!
    function serverDelegate:request(player: Player, timeoutInSeconds: number)
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

    function serverDelegate:setCallback(callback)
        assert(not isCallbackRegistered, "A callback has already been registered")
        isCallbackRegistered = true

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
                
                callback(resolve, reject)(sender, ...)
            end
        end)

        return function()
            connection:Disconnect()
        end
    end

    serverDelegate.subscribe = serverNetworker.subscribe
    serverDelegate.subscribeOnce = serverNetworker.subscribeOnce
    return serverDelegate
end

return ServerDelegate