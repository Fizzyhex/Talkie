--!strict
local Symbols = require(script.Parent.Parent.Symbols)

local function runIfNotBlocked<Arg1, T...>(callback: (Arg1, T...) -> (), arg1: Arg1, ...: T...)    
    if arg1 == Symbols.Block then
        return nil
    end

    return callback(arg1, ...)
end

return runIfNotBlocked