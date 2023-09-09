--!strict
export type Task = 
    Instance
    | RBXScriptConnection
    | { destroy: () -> () }
    | { Destroy: () -> () }
    | { [any]: Task }
    | () -> ()

--- Cleans up the given task or table of tasks.
local function doCleanup(task: Task)
	local taskType = typeof(task)
    local anyTask = task :: any

	if taskType == "Instance" then
		anyTask:Destroy()
	elseif taskType == "RBXScriptConnection" then
		anyTask:Disconnect()
	elseif taskType == "function" then
		anyTask()
	elseif taskType == "table" then
		if typeof(anyTask.destroy) == "function" then
			anyTask:destroy()
		elseif typeof(anyTask.Destroy) == "function" then
			anyTask:Destroy()
		elseif anyTask[1] ~= nil then
			for _, subtask in anyTask do
				doCleanup(subtask)
			end
		end
	end
end

return doCleanup