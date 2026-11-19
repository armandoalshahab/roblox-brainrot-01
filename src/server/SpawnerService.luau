-- SpawnerService: rolls fresh brainrots onto the conveyor on a timer and
-- slides them along it. A brainrot that reaches the end unbought despawns.
-- Clicking one buys it (see EconomyService.buyBrainrotFromConveyor).

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local StateService = require(script.Parent.StateService)
local ModelFactory = require(script.Parent.ModelFactory)

local SpawnerService = {}

SpawnerService.ConveyorModels = {} -- modelId -> record, for the slide loop
SpawnerService.Running = false
-- Set by init.server: the buy function (EconomyService.buyBrainrotFromConveyor).
-- Kept as an injected callback so this module never requires EconomyService
-- back -- that top-level circular require broke the whole game at boot.
SpawnerService.BuyHandler = nil

local function getConveyorCFrame(x)
	return CFrame.new(x, Config.ConveyorY, Config.ConveyorZ)
end

-- Spawn one brainrot at the start of the conveyor and wire its click.
function SpawnerService.spawnBrainrotOnConveyor()
	local char = BrainrotData.rollCharacter()
	local mutation = BrainrotData.rollMutation()
	local modelId = StateService.nextModelId()
	local model = ModelFactory.buildBrainrotModel(char, mutation, modelId)
	model:PivotTo(getConveyorCFrame(Config.ConveyorStartX))
	model.Parent = workspace:WaitForChild("BrainrotModels")

	local record = {
		Id = modelId,
		CharId = char.Id,
		Mutation = mutation,
		Price = char.Cost,
		Model = model,
		State = "conveyor",
		Owner = nil,
		Carrier = nil,
		BaseIndex = nil,
		SlotIndex = nil,
		StealCooldownUntil = 0,
	}
	StateService.registerModel(record)
	SpawnerService.ConveyorModels[modelId] = record

	local click = model.PrimaryPart:FindFirstChild("BuyClick")
	if click then
		click.MouseClick:Connect(function(player)
			local buy = SpawnerService.BuyHandler
			if buy then
				buy(player, modelId)
			end
		end)
	end
	return record
end

function SpawnerService.despawnConveyorBrainrot(modelId)
	local record = SpawnerService.ConveyorModels[modelId]
	if not record then
		return
	end
	SpawnerService.ConveyorModels[modelId] = nil
	StateService.destroyModelRecord(modelId)
end

-- Slide every conveyor brainrot toward the end; despawn what arrives.
function SpawnerService.slideConveyorBrainrots(dt)
	local step = Config.ConveyorSpeed * dt
	for modelId, record in pairs(SpawnerService.ConveyorModels) do
		if record.Model and record.Model.Parent then
			local cf = record.Model:GetPivot()
			local nextX = cf.Position.X + step
			if nextX >= Config.ConveyorEndX then
				SpawnerService.despawnConveyorBrainrot(modelId)
			else
				record.Model:PivotTo(CFrame.new(nextX, Config.ConveyorY, Config.ConveyorZ))
			end
		else
			SpawnerService.ConveyorModels[modelId] = nil
		end
	end
end

function SpawnerService.start()
	if SpawnerService.Running then
		return
	end
	SpawnerService.Running = true

	task.spawn(function()
		while true do
			local interval = Config.SpawnIntervalBase
			-- Use the fastest conveyor upgrade any player owns, so one rich
			-- player speeds the belt up for everyone on the server.
			for _, data in pairs(StateService.PlayersData) do
				local mine = Config.spawnInterval(data.Upgrades.conveyor)
				if mine < interval then
					interval = mine
				end
			end
			task.wait(interval)
			SpawnerService.spawnBrainrotOnConveyor()
		end
	end)

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(0.1)
			local now = os.clock()
			SpawnerService.slideConveyorBrainrots(now - last)
			last = now
		end
	end)
end

return SpawnerService
