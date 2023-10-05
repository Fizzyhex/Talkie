--!strict
local RunService = game:GetService("RunService")

local package = script.Parent.Parent
local ClientNetworker = require(script.Parent.ClientNetworker)
local Promise = require(package.Parent.Promise)
local TicketBooth = require(package.util.TicketBooth)

local IS_CLIENT = RunService:IsClient()
local METATABLE = {
    __tostring = function(self)
        return `ClientDelegate<{self.name}>`
    end
}

local function ClientDelegate(remote: RemoteEvent, name: string)
    assert(IS_CLIENT, "Attempt to construct a ClientDelegate on the server")
    local clientDelegate = {
        type = "delegate",
        name = name,
    }
    setmetatable(clientDelegate, METATABLE)
    local clientNetworker = ClientNetworker(remote, name)
    local nextTicket = TicketBooth()
    local isCallbackRegistered = false

    --- Ask the server for a response by opening a ticket.
    function clientDelegate:request(...)
        local ticket = nextTicket()
        remote:FireServer({clientNetworker:getId(), ticket}, ...)

        return Promise.new(function(resolve, reject, onCancel)
            local connection
            connection = remote.OnClientEvent:Connect(function(identifierTable, ...)
                if typeof(identifierTable) == "table" then
                    if identifierTable[1] == clientNetworker:getId() and identifierTable[2] == ticket then
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
        end)
    end

    function clientDelegate:setCallback(callback)
        assert(not isCallbackRegistered, "A callback has already been registered")
        isCallbackRegistered = true

        local connection = remote.OnClientEvent:Connect(function(identifierTable, ...)
            if typeof(identifierTable) == "table" and identifierTable[1] == clientNetworker:getId() then
                local unanswered = true
                local identifier = identifierTable[1]
                local ticket = identifierTable[2]
                
                local function resolve(...)
                    assert(unanswered, "A ticket cannot be replied to multiple times")
                    unanswered = false
                    remote:FireServer({ identifier, ticket }, ...)
                end

                local function reject(...)
                    assert(unanswered, "A ticket cannot be replied to multiple times")
                    unanswered = false
                    remote:FireServer({ identifier, ticket, true }, ...)
                end
                
                callback(resolve, reject)(...)
            end
        end)

        return function()
            connection:Disconnect()
        end
    end

    clientDelegate.subscribe = clientNetworker.subscribe
    clientDelegate.subscribeOnce = clientNetworker.subscribeOnce
    return clientDelegate
end

return ClientDelegate