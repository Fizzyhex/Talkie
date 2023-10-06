--!strict

--[=[
    A utility function for creating channel names.

    ```lua
    local Scope = Talkie.Util.Scope
    local playersScope = Scope("players")

    print(playersScope()) -- "players"

    print(playersScope "playerAdded") -- "players/playerAdded"
    print(playersScope("playerRemoving")) -- "players/playerRemoving"
    
    -- It's possible to create scopes off of other scopes too!
    local economyScope = Scope(playersScope "economy")
    print(economyScope "giveMoney") -- "players/economy/giveMoney"
    ```
]=]
local function Scope(baseName: string)
    return function(name: string?)
        if name then
            return `{baseName}/{name}`
        else
            return baseName
        end
    end
end

return Scope