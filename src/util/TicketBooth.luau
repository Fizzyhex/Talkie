local UNICODE_CODEPOINTS = 1114112

--- A unique utf-8 token generator.
local function TicketBooth()
    local lastTicket = string.char(0)

    --- Returns the next unique ticket, composed of utf-8 characters.
    local function nextTicket()
        local codepaths = {}
        local newTicket = ""
        local unmodified = true
        
        for _, codepath in utf8.codes(lastTicket) do
            table.insert(codepaths, codepath)
        end
    
        for index, codepath in codepaths do
            if unmodified and codepath < UNICODE_CODEPOINTS - 1 then
                unmodified = false
                newTicket = newTicket .. utf8.char(codepath + 1)
            else
                newTicket = newTicket .. utf8.char(codepath)
            end
        end
    
        if unmodified then
            newTicket = string.rep(utf8.char(0), #newTicket + 1)
        end
    
        lastTicket = newTicket
        return newTicket
    end

    return nextTicket
end

return TicketBooth