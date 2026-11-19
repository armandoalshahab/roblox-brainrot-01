-- Config: every tuning number for Brainrot Base Rush in one place.

local Config = {}

Config.StartCash = 100

-- The conveyor runs along X at this Z, carrying fresh brainrots past the plaza.
Config.ConveyorStartX = -45
Config.ConveyorEndX = 45
Config.ConveyorZ = 10
Config.ConveyorY = 2
Config.ConveyorSpeed = 4.5 -- studs per second: a brainrot crosses in 20 seconds
Config.SpawnIntervalBase = 4 -- seconds between spawns at conveyor level 0

-- Eight base plots in a row on the north side of the plaza.
Config.BaseZ = -35
Config.BaseCentersX = { -70, -50, -30, -10, 10, 30, 50, 70 }
Config.BaseColors = {
	Color3.fromRGB(235, 80, 80),
	Color3.fromRGB(255, 150, 50),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(110, 200, 90),
	Color3.fromRGB(80, 180, 220),
	Color3.fromRGB(120, 110, 235),
	Color3.fromRGB(200, 90, 220),
	Color3.fromRGB(255, 120, 180),
}

-- Base slots: 6 to start, +2 per slots upgrade level, 12 at most.
-- Slot positions come from BaseService.getSlotCFrame (a 3 x 4 grid on the pad).
Config.BaseSlotsBase = 6
Config.SlotsPerUpgrade = 2
Config.MaxSlots = 12

-- Base lock: L locks your own base so nobody can steal from it.
Config.LockDurationBase = 30 -- seconds, +15 per lock upgrade level
Config.LockDurationPerLevel = 15
Config.LockCooldown = 60 -- seconds before you can lock again

-- The Brainrot Storm: a wave sweeps the plaza on a timer.
-- 95s between storms (tuned down from 100): frequent enough to matter, rare
-- enough that a new player is not swept twice in one shopping trip.
Config.StormInterval = 95 -- seconds between storms
Config.StormWarningSeconds = 5
Config.StormWaveSpeed = 15 -- studs per second
Config.StormKnockback = 55

-- Movement.
Config.NormalWalkSpeed = 16
Config.CarryWalkSpeed = 10 -- slowed while hauling a stolen brainrot

-- Rebirth: reset cash and brainrots for a permanent income multiplier.
-- Multiplier is 1 + rebirths, so the first rebirth doubles all income.
Config.RebirthBaseCost = 25000
function Config.rebirthCost(rebirths)
	return Config.RebirthBaseCost * (rebirths + 1)
end

-- Upgrades: three tracks, three levels each.
Config.Upgrades = {
	conveyor = {
		Name = "Conveyor Speed",
		Desc = "Brainrots spawn faster",
		Costs = { 500, 2000, 8000 },
	},
	lock = {
		Name = "Longer Lock",
		Desc = "+15s base lock per level",
		Costs = { 750, 3000, 12000 },
	},
	slots = {
		Name = "Bigger Base",
		Desc = "+2 brainrot slots per level",
		Costs = { 1000, 5000, 20000 },
	},
}

function Config.spawnInterval(conveyorLevel)
	-- Level 0: 4.0s, 1: 3.2s, 2: 2.6s, 3: 2.2s
	return Config.SpawnIntervalBase - (conveyorLevel * 0.6) - (conveyorLevel * conveyorLevel * 0.2)
end

function Config.lockDuration(lockLevel)
	return Config.LockDurationBase + (lockLevel * Config.LockDurationPerLevel)
end

function Config.maxSlots(slotsLevel)
	local slots = Config.BaseSlotsBase + (slotsLevel * Config.SlotsPerUpgrade)
	if slots > Config.MaxSlots then
		slots = Config.MaxSlots
	end
	return slots
end

return Config
