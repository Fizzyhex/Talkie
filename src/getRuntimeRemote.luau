--!strict
local RunService = game:GetService("RunService")

local REMOTE_NAME = "RemoteEvent"

local function getRuntimeRemote(): RemoteEvent
    if RunService:IsClient() and RunService:IsRunMode() then
        return script:WaitForChild(REMOTE_NAME)
    else
        local remote = script:FindFirstChild(REMOTE_NAME)

        if remote then
            return remote :: RemoteEvent
        end

        remote = Instance.new("RemoteEvent")
        remote.Name = REMOTE_NAME
        remote.Archivable = false
        remote.Parent = script
        return remote
    end
end

return getRuntimeRemote