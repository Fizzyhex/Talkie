local ClientChannel = require(script.ClientChannel)
local ServerChannel = require(script.ServerChannel)
local getRuntimeRemote = require(script.getRuntimeRemote)

local types = require(script.types)

export type ServerChannel<T...=...any> = types.ServerChannel<T...>

local function createLibrary(getRemote)
    local function scopeChannel(Class)
        return function(identifier: string)
            return Class(getRemote(), identifier)
        end
    end

    return {
        ClientChannel = scopeChannel(ClientChannel),
        ServerChannel = scopeChannel(ServerChannel),

        Util = {
            Scope = require(script.util.Scope),
            doCleanup = require(script.util.doCleanup),
        },

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