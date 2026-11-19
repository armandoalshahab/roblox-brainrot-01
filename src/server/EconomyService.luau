-- EconomyService: cash in, cash out. Buys from the conveyor, the one-second
-- income tick, upgrades and rebirths (reset for a permanent multiplier).

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local StateService = require(script.Parent.StateService)
local BaseService = require(script.Parent.BaseService)
-- Circular with SpawnerService (it calls buyBrainrotFromConveyor from its
-- click handler): safe because both sides only call each other at run time,
-- never while loading.
local SpawnerService = require(script.Parent.SpawnerService)

local EconomyService = {}

EconomyService.Notify = nil -- set by init: RemoteEvent for toast messages
EconomyService.UpdateHUD = nil -- set by init: RemoteEvent for HUD numbers
EconomyService.LeaderboardUpdate = nil -- set by init

local function notify(player, message, kind, position)
	if EconomyService.Notify then
		EconomyService.Notify:FireClient(player, message, kind, position)
	end
end

local function notifyAll(message, kind)
	if EconomyService.Notify then
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			EconomyService.Notify:FireClient(player, message, kind, nil)
		end
	end
end

-- Buy the brainrot riding the conveyor. Clicking it, or pressing E near it,
-- both land here. The model moves onto the buyer's base and starts earning.
function EconomyService.buyBrainrotFromConveyor(player, modelId)
	local record = StateService.getModel(modelId)
	local data = StateService.getData(player)
	if not record or not data then
		return false
	end
	if record.State ~= "conveyor" then
		return false
	end
	if data.Cash < record.Price then
		notify(player, "Butuh $" .. tostring(record.Price) .. " untuk " .. BrainrotData.getDisplayName(BrainrotData.getCharacter(record.CharId), record.Mutation) .. "!", "error", nil)
		return false
	end
	if StateService.getFreeSlotCount(player) <= 0 then
		notify(player, "Base penuh! Upgrade Bigger Base dulu.", "error", nil)
		return false
	end
	data.Cash = data.Cash - record.Price
	SpawnerService.ConveyorModels[modelId] = nil
	local placed = BaseService.placeBrainrotOnBase(record, player)
	if not placed then
		-- Extremely rare (two buyers racing): put it back on the belt.
		data.Cash = data.Cash + record.Price
		SpawnerService.ConveyorModels[modelId] = record
		return false
	end
	local char = BrainrotData.getCharacter(record.CharId)
	local pos = record.Model:GetPivot().Position
	notify(player, "Beli " .. BrainrotData.getDisplayName(char, record.Mutation) .. " seharga $" .. tostring(record.Price) .. "!", "buy", pos)
	EconomyService.pushHUD(player)
	return true
end

-- One of the three upgrade tracks. Each has three levels.
function EconomyService.buyUpgrade(player, upgradeId)
	local data = StateService.getData(player)
	local track = Config.Upgrades[upgradeId]
	if not data or not track then
		return false
	end
	local level = data.Upgrades[upgradeId] or 0
	if level >= #track.Costs then
		notify(player, track.Name .. " sudah max!", "error", nil)
		return false
	end
	local cost = track.Costs[level + 1]
	if data.Cash < cost then
		notify(player, "Butuh $" .. tostring(cost) .. " untuk " .. track.Name .. " Lv" .. tostring(level + 1) .. "!", "error", nil)
		return false
	end
	data.Cash = data.Cash - cost
	data.Upgrades[upgradeId] = level + 1
	notify(player, track.Name .. " naik ke Lv" .. tostring(level + 1) .. "!", "buy", nil)
	EconomyService.pushHUD(player)
	return true
end

-- Rebirth: wipe cash and brainrots, keep a permanent income multiplier and
-- wear a gold crown so everyone can see the rebirth count.
function EconomyService.rebirthPlayerForMultiplier(player)
	local data = StateService.getData(player)
	if not data then
		return false
	end
	local cost = Config.rebirthCost(data.Rebirths)
	if data.Cash < cost then
		notify(player, "Rebirth butuh $" .. tostring(cost) .. "! Kamu punya $" .. tostring(math.floor(data.Cash)) .. ".", "error", nil)
		return false
	end
	for i = #data.Brainrots, 1, -1 do
		local record = data.Brainrots[i]
		StateService.destroyModelRecord(record.Id)
	end
	data.Brainrots = {}
	data.Cash = 0
	data.Rebirths = data.Rebirths + 1
	EconomyService.applyRebirthCrown(player)
	notifyAll(player.DisplayName .. " REBIRTH ke-" .. tostring(data.Rebirths) .. "! Income sekarang x" .. tostring(StateService.getRebirthMultiplier(data)) .. "!", "rebirth")
	EconomyService.pushHUD(player)
	return true
end

function EconomyService.applyRebirthCrown(player)
	local data = StateService.getData(player)
	if not data or data.Rebirths <= 0 then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	if head:FindFirstChild("RebirthCrown") then
		return
	end
	local crown = Instance.new("Part")
	crown.Name = "RebirthCrown"
	crown.Size = Vector3.new(1.3, 0.45, 1.3)
	crown.Color = Color3.fromRGB(255, 215, 0)
	crown.Material = Enum.Material.Neon
	crown.Anchored = false
	crown.CanCollide = false
	crown.Parent = head
	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = crown
	weld.C0 = CFrame.new(0, 0.75, 0)
	weld.Parent = crown
	data.CrownApplied = true
end

-- Send one player's HUD numbers to their client.
function EconomyService.pushHUD(player)
	if not EconomyService.UpdateHUD then
		return
	end
	local data = StateService.getData(player)
	if not data then
		return
	end
	local now = os.clock()
	local lockLeft = 0
	if now < data.LockedUntil then
		lockLeft = math.floor(data.LockedUntil - now)
	end
	local cooldownLeft = 0
	if now < data.LockCooldownUntil then
		cooldownLeft = math.floor(data.LockCooldownUntil - now)
	end
	EconomyService.UpdateHUD:FireClient(player, {
		Cash = math.floor(data.Cash),
		IncomePerSecond = StateService.getIncomePerSecond(player),
		Rebirths = data.Rebirths,
		Multiplier = StateService.getRebirthMultiplier(data),
		RebirthCost = Config.rebirthCost(data.Rebirths),
		LockLeft = lockLeft,
		LockCooldownLeft = cooldownLeft,
		Upgrades = { conveyor = data.Upgrades.conveyor, lock = data.Upgrades.lock, slots = data.Upgrades.slots },
		BaseIndex = data.BaseIndex,
		FreeSlots = StateService.getFreeSlotCount(player),
	})
end

function EconomyService.pushLeaderboard()
	if not EconomyService.LeaderboardUpdate then
		return
	end
	local rows = {}
	for player, data in pairs(StateService.PlayersData) do
		table.insert(rows, { Name = player.DisplayName, Cash = math.floor(data.Cash), Rebirths = data.Rebirths })
	end
	table.sort(rows, function(a, b)
		return a.Cash > b.Cash
	end)
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		EconomyService.LeaderboardUpdate:FireClient(player, rows)
	end
end

-- The one-second income tick: every brainrot on every base pays out.
function EconomyService.startIncomeTick()
	task.spawn(function()
		while true do
			task.wait(1)
			for player, _ in pairs(StateService.PlayersData) do
				local income = StateService.getIncomePerSecond(player)
				if income > 0 then
					local data = StateService.PlayersData[player]
					-- Player may have left mid-tick; never index a gone record.
					if data then
						data.Cash = data.Cash + income
					end
				end
				EconomyService.pushHUD(player)
			end
			EconomyService.pushLeaderboard()
		end
	end)
end

return EconomyService
