local ClientDelegate = require(script.client.ClientDelegate)
local ClientEvent = require(script.client.ClientEvent)
local ServerDelegate = require(script.server.ServerDelegate)
local getRuntimeRemote = require(script.getRuntimeRemote)
local ServerEvent = require(script.server.ServerEvent)

local types = require(script.types)
local TicketBooth = require(script.util.TicketBooth)

export type ServerEvent<T...=...any> = types.ServerEvent<T...>
export type ClientDelegate<T...=...any> = types.ClientDelegate<T...>
export type ServerDelegate = types.ServerDelegate

local function createLibrary(getRemote)
    local function scopeChannel(Class)
        return function(identifier: string)
            return Class(getRemote(), identifier)
        end
    end

    return {
        ClientDelegate = scopeChannel(ClientDelegate),
        ServerDelegate = scopeChannel(ServerDelegate),
        ServerEvent = scopeChannel(ServerEvent),
        ClientEvent = scopeChannel(ClientEvent),
        PlayerFilters = require(script.PlayerFilters),

        Util = {
            Scope = require(script.util.Scope),
            TicketBooth = require(script.util.TicketBooth),
            doCleanup = require(script.util.doCleanup),
            RateLimit = require(script.util.RateLimit),
            TypeGuard = require(script.util.TypeGuard),
        },
        
        nextTicket = TicketBooth(),

        --- Creates a new isolated instance of Talkie - useful for running tests!
        createMock = function()
            local remote = Instance.new("RemoteEvent")
            
            return createLibrary(function()
                return remote
            end)
        end,
    }
end

return createLibrary(getRuntimeRemote)