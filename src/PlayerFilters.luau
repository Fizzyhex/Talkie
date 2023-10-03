--!strict
local PlayerFilters = {}

--[=[
    Returns true if the player is not the list.

    ```lua
    local filter = PlayerFilters.Except(Players.builderman, Players.Shedletsky)
    
    print(filter(Players.builderman)) -- false
    print(filter(Players.moded)) -- true
    ```
]=]
function PlayerFilters.Except(...: Player)
    local players = { ... }

    return function(player: Player)
        return table.find(players, player) == nil
    end
end

return PlayerFilters