-- StateService: the single source of truth for all player and brainrot state.
-- In-memory only (no DataStore): cash, income, brainrots, rebirths, locks,
-- upgrades and the registry of every spawned brainrot model live here.

local Players = game:GetService("Players")

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local StateService = {}

StateService.PlayersData = {}
StateService.Models = {} -- modelId -> brainrot record
StateService.NextModelId = 1

function StateService.createPlayerData(player, baseIndex)
	local data = {
		Player = player,
		Cash = Config.StartCash,
		Rebirths = 0,
		BaseIndex = baseIndex,
		Brainrots = {}, -- array of brainrot records standing on this base
		Upgrades = { conveyor = 0, lock = 0, slots = 0 },
		LockedUntil = 0,
		LockCooldownUntil = 0,
		Carrying = nil, -- modelId the player is hauling, or nil
		CrownApplied = false,
	}
	StateService.PlayersData[player] = data
	return data
end

function StateService.getData(player)
	return StateService.PlayersData[player]
end

function StateService.removePlayerData(player)
	StateService.PlayersData[player] = nil
end

function StateService.getRebirthMultiplier(data)
	return 1 + data.Rebirths
end

function StateService.getIncomePerSecond(player)
	local data = StateService.PlayersData[player]
	if not data then
		return 0
	end
	local total = 0
	for _, record in ipairs(data.Brainrots) do
		local char = BrainrotData.getCharacter(record.CharId)
		if char then
			total = total + BrainrotData.getIncome(char, record.Mutation)
		end
	end
	return total * StateService.getRebirthMultiplier(data)
end

function StateService.getMaxSlots(player)
	local data = StateService.PlayersData[player]
	if not data then
		return Config.BaseSlotsBase
	end
	return Config.maxSlots(data.Upgrades.slots)
end

function StateService.getFreeSlotCount(player)
	local data = StateService.PlayersData[player]
	if not data then
		return 0
	end
	return StateService.getMaxSlots(player) - #data.Brainrots
end

function StateService.isBaseLocked(player)
	local data = StateService.PlayersData[player]
	if not data then
		return false
	end
	return os.clock() < data.LockedUntil
end

function StateService.nextModelId()
	local id = "B" .. tostring(StateService.NextModelId)
	StateService.NextModelId = StateService.NextModelId + 1
	return id
end

function StateService.registerModel(record)
	StateService.Models[record.Id] = record
end

function StateService.getModel(modelId)
	return StateService.Models[modelId]
end

function StateService.unregisterModel(modelId)
	StateService.Models[modelId] = nil
end

function StateService.destroyModelRecord(modelId)
	local record = StateService.Models[modelId]
	if not record then
		return
	end
	if record.Owner then
		local data = StateService.PlayersData[record.Owner]
		if data then
			for i, owned in ipairs(data.Brainrots) do
				if owned.Id == modelId then
					table.remove(data.Brainrots, i)
					break
				end
			end
		end
	end
	if record.Carrier then
		local carrierData = StateService.PlayersData[record.Carrier]
		if carrierData and carrierData.Carrying == modelId then
			carrierData.Carrying = nil
		end
	end
	if record.Model then
		record.Model:Destroy()
	end
	StateService.Models[modelId] = nil
end

-- Find a player object from a UserId (works even for a leaving player).
function StateService.findPlayerByUserId(userId)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end
	return nil
end

return StateService
