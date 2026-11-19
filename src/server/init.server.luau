-- init.server: boots Brainrot Base Rush.
-- Creates the RemoteEvents and the BrainrotModels folder, wires every remote
-- to its service, assigns bases on join, and starts the conveyor, the income
-- tick, the carry heartbeat and the storm timer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local StateService = require(script.Parent.StateService)
local BaseService = require(script.Parent.BaseService)
local EconomyService = require(script.Parent.EconomyService)
local SpawnerService = require(script.Parent.SpawnerService)
local StealService = require(script.Parent.StealService)
local EventService = require(script.Parent.EventService)

-- All brainrot models live in one folder so the client can find them.
local modelsFolder = Instance.new("Folder")
modelsFolder.Name = "BrainrotModels"
modelsFolder.Parent = workspace

-- Client <-> server channel.
local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local BuyBrainrot = makeRemote("BuyBrainrot")
local StealBrainrot = makeRemote("StealBrainrot")
local SlapPlayer = makeRemote("SlapPlayer")
local LockBase = makeRemote("LockBase")
local BuyUpgrade = makeRemote("BuyUpgrade")
local Rebirth = makeRemote("Rebirth")
local UpdateHUD = makeRemote("UpdateHUD")
local Notify = makeRemote("Notify")
local StormWarning = makeRemote("StormWarning")
local LeaderboardUpdate = makeRemote("LeaderboardUpdate")

EconomyService.Notify = Notify
EconomyService.UpdateHUD = UpdateHUD
EconomyService.LeaderboardUpdate = LeaderboardUpdate
StealService.Notify = Notify
EventService.Notify = Notify
EventService.StormWarning = StormWarning

-- Break the EconomyService <-> SpawnerService require cycle: the spawner
-- never requires the economy module; init hands it the buy function instead.
SpawnerService.BuyHandler = EconomyService.buyBrainrotFromConveyor

-- E near a conveyor brainrot buys it; E near a rival base brainrot steals it;
-- E near a thief carrying your brainrot slaps them. The client picks which.
BuyBrainrot.OnServerEvent:Connect(function(player, modelId)
	if typeof(modelId) == "string" then
		EconomyService.buyBrainrotFromConveyor(player, modelId)
	end
end)

StealBrainrot.OnServerEvent:Connect(function(player, modelId)
	if typeof(modelId) == "string" then
		StealService.stealBrainrotFromRivalBase(player, modelId)
	end
end)

SlapPlayer.OnServerEvent:Connect(function(player, targetPlayer)
	if typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") then
		StealService.slapBrainrotThief(player, targetPlayer)
	end
end)

LockBase.OnServerEvent:Connect(function(player)
	local duration, reason = BaseService.lockOwnBase(player)
	if duration then
		Notify:FireClient(player, "Base terkunci " .. tostring(duration) .. " detik!", "lock", nil)
		EconomyService.pushHUD(player)
	elseif reason == "cooldown" then
		Notify:FireClient(player, "Lock masih cooldown!", "error", nil)
	end
end)

BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	if typeof(upgradeId) == "string" then
		EconomyService.buyUpgrade(player, upgradeId)
	end
end)

Rebirth.OnServerEvent:Connect(function(player)
	EconomyService.rebirthPlayerForMultiplier(player)
end)

local function setupPlayer(player)
	local baseIndex = BaseService.assignBaseToPlayer(player)
	if not baseIndex then
		Notify:FireClient(player, "Semua base penuh, kamu jadi penonton dulu!", "error", nil)
		return
	end
	StateService.createPlayerData(player, baseIndex)
	Notify:FireClient(player, "Base #" .. tostring(baseIndex) .. " milikmu! Beli brainrot di conveyor (E / klik).", "info", nil)
	EconomyService.pushHUD(player)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			StealService.dropCarriedBrainrot(player)
		end)
		-- A reborn player keeps their crown after every respawn.
		task.wait(0.5)
		EconomyService.applyRebirthCrown(player)
	end)
end

local function cleanupPlayer(player)
	local data = StateService.getData(player)
	if data then
		if data.Carrying then
			StealService.dropCarriedBrainrot(player)
		end
		for i = #data.Brainrots, 1, -1 do
			StateService.destroyModelRecord(data.Brainrots[i].Id)
		end
	end
	-- Free the base and reset its gate, so the next player gets a clean plot.
	local freedIndex = BaseService.freeBaseOfPlayer(player)
	if freedIndex then
		BaseService.setGateLocked(freedIndex, false)
	end
	StateService.removePlayerData(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

SpawnerService.start()
EconomyService.startIncomeTick()
StealService.startCarryHeartbeat()
EventService.start()

-- Rojo project files cannot carry UDim2 values, so the welcome sign's label
-- gets its full-face size here at boot instead.
local signText = workspace:FindFirstChild("WelcomeSign")
if signText then
	local gui = signText:FindFirstChild("SignGui")
	if gui then
		local label = gui:FindFirstChild("SignText")
		if label then
			label.Size = UDim2.fromScale(1, 1)
		end
	end
end

print("Brainrot Base Rush is running: 8 bases, 12 brainrots, storm every " .. tostring(Config.StormInterval) .. "s.")
print("Brainrot Base Rush tuning: conveyor " .. tostring(Config.ConveyorSpeed) .. " studs/s, start cash $" .. tostring(Config.StartCash) .. ", first rebirth $" .. tostring(Config.RebirthBaseCost) .. ".")
