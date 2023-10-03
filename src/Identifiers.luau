--!strict
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Promise)

local Identifiers = {}

function Identifiers.registerIdentifier(remote: RemoteEvent, name: string)
    assert(RunService:IsServer(), "registerIdentifier can only be called on the server")
    local attributes = remote:GetAttributes()
    local attributeCount = 0
    
    for identifier, attributeName in attributes do
        if attributeName == name then
            return utf8.char(tonumber(identifier) :: number)
        end

        attributeCount += 1
    end

    local newIndex = attributeCount + 1
    remote:SetAttribute(tostring(newIndex), name)
    return utf8.char(newIndex)
end

function Identifiers.awaitRegistry(remote: RemoteEvent, name: string)
    do
        for identifier, attributeName in remote:GetAttributes() do
            if attributeName == name then
                return Promise.resolve(utf8.char(tonumber(identifier) :: number))
            end
        end
    end

    return Promise.new(function(resolve)
        while true do
            local identifier = remote.AttributeChanged:Wait()
            local attributeName = remote:GetAttribute(identifier)

            if attributeName == name then
                resolve(utf8.char(tonumber(identifier) :: number))
                break
            end
        end
    end)
end

return Identifiers