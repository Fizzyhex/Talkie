--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Identifiers = require(script.Parent.Identifiers)
local Promise = require(script.Parent.Packages.Promise)

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

    local function fireAllClients(...)
        remote:FireAllClients(remoteIdentifier, ...)
    end

    local function fireClient(player: Player, ...)
        remote:FireClient(player, remoteIdentifier, ...)
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

    end

    return serverChannel
end

return ServerChannel