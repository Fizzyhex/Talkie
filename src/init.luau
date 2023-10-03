local ClientChannel = require(script.ClientChannel)
local ServerChannel = require(script.ServerChannel)
local getRuntimeRemote = require(script.getRuntimeRemote)

local types = require(script.types)
local TicketBooth = require(script.util.TicketBooth)

export type ServerChannel<serverChannelSend, serverChannelReceive> = types.ServerChannel<serverChannelSend, serverChannelReceive>

local function createLibrary(getRemote)
    local function scopeChannel(Class)
        return function(identifier: string)
            return Class(getRemote(), identifier)
        end
    end

    return {
        ClientChannel = scopeChannel(ClientChannel),
        ServerChannel = scopeChannel(ServerChannel),
        PlayerFilters = require(script.PlayerFilters),

        Util = {
            Scope = require(script.util.Scope),
            TicketBooth = require(script.util.TicketBooth),
            doCleanup = require(script.util.doCleanup),
            RateLimit = require(script.util.RateLimit),
        },
        
        nextTicket = TicketBooth(),

        --- Creates a new isolated instance of Talkie - useful for running tests!
        createMock = function()
            local remote = Instance.new("RemoteEvent")
            
            return createLibrary(function()
                return remote
            end)
        end
    }
end

return createLibrary(getRuntimeRemote)