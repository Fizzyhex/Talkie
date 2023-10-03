--- Only allows `[requests]` requests per `[per]` seconds.
local function RateLimit(requests: number, per: number)
    local history = {}
    
    return function()
        local now = os.clock()
        local budget = requests

        for index, timestamp in history do
            if now - timestamp > per then
                table.remove(history, index)
            else
                budget -= 1

                if budget <= 0 then
                    return false
                end
            end
        end

        table.insert(history, now)
        return true
    end
end

return RateLimit