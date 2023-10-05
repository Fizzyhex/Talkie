--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Promise = require(ReplicatedStorage.Packages.Promise)
local ServerNetworker = require(script.Parent.ServerNetworker)

local IS_SERVER = RunService:IsServer()
local METATABLE = {
    __tostring = function(self)
        return `ServerEvent<{self.identifier}>`
    end
}

local function ServerEvent(remote: RemoteEvent, name: string)
    assert(IS_SERVER, "Attempt to construct a ServerEvent on the client")
    local serverNetworker = ServerNetworker(remote, name)
    local serverEvent = { type = "event", name = name }
    setmetatable(serverEvent, METATABLE)
    local remoteIdentifier = serverNetworker.id

    local function fireAllClients(...)
        remote:FireAllClients(remoteIdentifier, ...)
    end

    local function fireClient(player: Player, ...)
        remote:FireClient(player, remoteIdentifier, ...)
    end

    function serverEvent:sendToAll(...)
        fireAllClients(...)
    end

    function serverEvent:expect(cleanupTable, filter)
        return Promise.new(function(resolve, _, onCancel)
            local unsubscribe = serverEvent:subscribeOnce(cleanupTable, function(...)
                resolve(...)
            end, filter)

            onCancel(unsubscribe)
        end)
    end

    function serverEvent:expectFrom(cleanupTable, player: Player)
        return serverEvent:expect(cleanupTable, function(sender)
            return sender == player
        end)
    end

    function serverEvent:sendToPlayer(playerOrPlayers: Player | { [any]: Player }, ...)
        if typeof(playerOrPlayers) == "table" then
            for _, player in playerOrPlayers do
                fireClient(player, ...)
            end
        else
            fireClient(playerOrPlayers, ...)
        end
    end

    function serverEvent:sendToAllExcept(player: Player, ...)
        for _, recipient in pairs(Players:GetPlayers()) do
            if player ~= recipient then
                fireClient(recipient, ...)
            end
        end
    end

    function serverEvent:sendFilter(filter, ...)
        for _, player in pairs(Players:GetPlayers()) do
            if filter(player) then
                fireClient(player, ...)
            end
        end
    end

    serverEvent.subscribe = serverNetworker.subscribe
    serverEvent.subscribeOnce = serverNetworker.subscribeOnce
    return serverEvent
end

return ServerEvent