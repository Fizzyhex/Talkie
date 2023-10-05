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

--[=[
    Returns a new TypeGuard function for validating data types.

    ```lua
    local function isRoundNumber(number)
        return typeof(number) == "number" and math.round(number) == number
    end

    local guard = TypeGuard.new("string", "number", isRoundNumber)

    print(guard("hi", 25, 50)) --> true
    print(guard(workspace, 25, 50)) --> false, 1
    print(guard("hi", 25, 50.5)) --> false, 2
    print(guard("hi", 25, 50, "extra argument")) --> false, 4
    ```
]=]
function TypeGuard.new(...): ((...any) -> (boolean, any))
    local guards = { ... }
    
    return function(...)
        for index, value in { ... } do
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

--- Returns true if the filter is past or the value is nil.
function TypeGuard.Optional(guard: any)
    return function(check)
        return check == nil or runGuard(guard, check)
    end
end

--- Returns true no matter what.
function TypeGuard.Any()
    return any
end

--- Returns true if any of the filters pass.
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