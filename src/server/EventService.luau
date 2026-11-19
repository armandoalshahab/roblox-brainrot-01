-- EventService: the Brainrot Storm. On a timer a giant wave sweeps the plaza
-- from west to east. Anyone caught in it is flung and drops whatever they
-- were carrying. Outrun it, or get knocked back to your base.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local StateService = require(script.Parent.StateService)
local StealService = require(script.Parent.StealService)

local EventService = {}

EventService.Notify = nil -- set by init: RemoteEvent for toast messages
EventService.StormWarning = nil -- set by init: RemoteEvent for the vignette

local function notifyAll(message, kind)
	if EventService.Notify then
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			EventService.Notify:FireClient(player, message, kind, nil)
		end
	end
end

-- One storm: warn, then sweep a wave across the plaza, then clear it.
function EventService.triggerBrainrotStorm()
	notifyAll("BRAINROT STORM datang! Lari ke base!", "storm")
	if EventService.StormWarning then
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			EventService.StormWarning:FireClient(player, Config.StormWarningSeconds)
		end
	end
	task.wait(Config.StormWarningSeconds)

	local wave = Instance.new("Part")
	wave.Name = "StormWave"
	wave.Size = Vector3.new(10, 26, 120)
	wave.Color = Color3.fromRGB(60, 140, 255)
	wave.Transparency = 0.35
	wave.Material = Enum.Material.Neon
	wave.Anchored = true
	wave.CanCollide = false
	wave.CFrame = CFrame.new(-120, 8, 0)
	wave.Parent = workspace

	local waveX = -120
	local knocked = {}
	while waveX < 120 do
		task.wait(0.05)
		waveX = waveX + Config.StormWaveSpeed * 0.05
		wave.CFrame = CFrame.new(waveX, 8, 0)
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			local character = player.Character
			if character and not knocked[player] then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - waveX) < 8 and math.abs(root.Position.Z) < 55 then
					knocked[player] = true
					root.AssemblyLinearVelocity = Vector3.new(60, 30, 0)
					local data = StateService.getData(player)
					if data and data.Carrying then
						StealService.dropCarriedBrainrot(player)
						if EventService.Notify then
							EventService.Notify:FireClient(player, "Storm bikin brainrot curianmu kabur!", "error", nil)
						end
					end
				end
			end
		end
	end
	wave:Destroy()
	notifyAll("Storm lewat! Conveyor jalan lagi.", "info")
end

function EventService.start()
	task.spawn(function()
		while true do
			task.wait(Config.StormInterval)
			EventService.triggerBrainrotStorm()
		end
	end)
end

return EventService
