--!strict

local function any()
    return true
end

local function runGuard(guard: any, value: any)
    if typeof(guard) == "function" then
        if not guard(value) then
            return false
        end
    elseif typeof(value) ~= guard then
        return false
    end

    return true
end

local TypeGuard = {}

function TypeGuard.new(...): ((...any) -> (boolean, any))
    local guards = { ... }
    
    return function(...)
        for index, value in ... do
            if index > #guards then
                return false, index
            end

            if not runGuard(guards[index], value) then
                return false, index
            end
        end

        return true
    end
end

function TypeGuard.Optional(guard: any)
    return function(check)
        return check == nil or runGuard(guard, check)
    end
end

function TypeGuard.Any()
    return any
end

function TypeGuard.Some(...)
    local guards = { ... }

    return function(check)
        for _, guard in guards do
            if runGuard(guard, check) then
                return true
            end
        end

        return false
    end
end

return TypeGuard