-- BaseService: hands each joining player one of the eight base plots,
-- places bought brainrots on its slots, and runs the lock gate.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local StateService = require(script.Parent.StateService)

local BaseService = {}

BaseService.TakenBases = {} -- baseIndex -> player

function BaseService.assignBaseToPlayer(player)
	for index = 1, #Config.BaseCentersX do
		if not BaseService.TakenBases[index] then
			BaseService.TakenBases[index] = player
			return index
		end
	end
	return nil
end

function BaseService.freeBaseOfPlayer(player)
	for index, owner in pairs(BaseService.TakenBases) do
		if owner == player then
			BaseService.TakenBases[index] = nil
			return index
		end
	end
	return nil
end

function BaseService.getBaseCenter(baseIndex)
	local x = Config.BaseCentersX[baseIndex]
	if not x then
		return Vector3.new(0, 0, Config.BaseZ)
	end
	return Vector3.new(x, 0, Config.BaseZ)
end

-- Slot positions on the pad: a 3 x 4 grid, first free slot wins. All twelve
-- slots fit on the 16 x 14 pad (x -7.5..7.5, z -38.5..-31.5).
function BaseService.getSlotCFrame(baseIndex, slotIndex)
	local center = BaseService.getBaseCenter(baseIndex)
	local row = math.floor((slotIndex - 1) / 4)
	local col = (slotIndex - 1) % 4
	local x = center.X - 7.5 + (col * 5)
	local z = center.Z - 3.5 + (row * 3.5)
	return CFrame.new(x, 2, z)
end

function BaseService.findFreeSlot(player)
	local data = StateService.getData(player)
	if not data then
		return nil
	end
	local used = {}
	for _, record in ipairs(data.Brainrots) do
		used[record.SlotIndex] = true
	end
	local maxSlots = StateService.getMaxSlots(player)
	for slot = 1, maxSlots do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

-- Place a brainrot record on its owner's base and mark it placed.
function BaseService.placeBrainrotOnBase(record, player)
	local data = StateService.getData(player)
	if not data then
		return false
	end
	if not record.Model then
		-- Model destroyed between buy and placement (race): refuse cleanly.
		return false
	end
	local slot = BaseService.findFreeSlot(player)
	if not slot then
		return false
	end
	record.SlotIndex = slot
	record.State = "base"
	record.Owner = player
	record.Carrier = nil
	record.Model:SetAttribute("State", "base")
	record.Model:SetAttribute("Owner", player.UserId)
	record.Model:SetAttribute("Carrier", 0)
	record.Model:PivotTo(BaseService.getSlotCFrame(data.BaseIndex, slot))
	table.insert(data.Brainrots, record)
	return true
end

-- The gate is the coloured part at the front of each base in the place file.
function BaseService.setGateLocked(baseIndex, locked)
	local gate = workspace:FindFirstChild("Base" .. tostring(baseIndex) .. "Gate")
	if not gate then
		return
	end
	if locked then
		gate.Color = Color3.fromRGB(220, 40, 40)
		gate.Transparency = 0
	else
		gate.Color = Config.BaseColors[baseIndex] or Color3.fromRGB(120, 120, 120)
		gate.Transparency = 0.4
	end
end

-- Lock your own base for Config.lockDuration seconds. Returns seconds left
-- on the lock, or nil plus a reason when it cannot lock.
function BaseService.lockOwnBase(player)
	local data = StateService.getData(player)
	if not data then
		return nil, "no base"
	end
	local now = os.clock()
	if now < data.LockCooldownUntil then
		return nil, "cooldown"
	end
	local duration = Config.lockDuration(data.Upgrades.lock)
	data.LockedUntil = now + duration
	data.LockCooldownUntil = now + Config.LockCooldown
	BaseService.setGateLocked(data.BaseIndex, true)
	task.delay(duration, function()
		if StateService.getData(player) then
			BaseService.setGateLocked(data.BaseIndex, false)
		end
	end)
	return duration, nil
end

function BaseService.isPlayerOnOwnBase(player)
	local data = StateService.getData(player)
	if not data or not player.Character then
		return false
	end
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local center = BaseService.getBaseCenter(data.BaseIndex)
	local pos = root.Position
	return math.abs(pos.X - center.X) < 9 and math.abs(pos.Z - center.Z) < 8
end

return BaseService
