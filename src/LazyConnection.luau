--!strict
local function LazyConnection(signal: RBXScriptSignal, Processor: (() -> ()) -> (() -> ()))
    local subscribers: { [any]: () -> () } = {}
    local connection: RBXScriptConnection?

    local function dispatch(...)
        for _, callback in subscribers do
            callback(...)
        end
    end

    local processor = Processor(dispatch)

    return function(callback)
        local uid = {}
        subscribers[uid] = callback

        if not connection then
            connection = signal:Connect(function(...)
                processor(...)
            end)
        end

        return function()
            if subscribers[uid] then
                return
            end

            subscribers[uid] = nil

            if connection and not next(subscribers) then
                connection:Disconnect()
                connection = nil
            end
        end
    end
end

return LazyConnection