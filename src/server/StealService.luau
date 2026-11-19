-- StealService: the heist loop. Grab a brainrot off a rival's base, haul it
-- home slowed, and hope its owner does not slap you before you get there.
-- A locked base cannot be stolen from. Dropping (slap, storm, death) sends
-- the brainrot straight back to its home slot.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local StateService = require(script.Parent.StateService)
local BaseService = require(script.Parent.BaseService)

local StealService = {}

StealService.Notify = nil -- set by init: RemoteEvent for toast messages

local function notify(player, message, kind)
	if StealService.Notify then
		StealService.Notify:FireClient(player, message, kind, nil)
	end
end

local function setCarrySpeed(player, carrying)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if carrying then
			humanoid.WalkSpeed = Config.CarryWalkSpeed
		else
			humanoid.WalkSpeed = Config.NormalWalkSpeed
		end
	end
end

-- Start hauling a brainrot off a rival base. Returns true when the grab lands.
function StealService.stealBrainrotFromRivalBase(player, modelId)
	local record = StateService.getModel(modelId)
	local data = StateService.getData(player)
	if not record or not data then
		return false
	end
	if record.State ~= "base" then
		return false
	end
	if record.Owner == player then
		return false
	end
	if data.Carrying then
		notify(player, "Kamu sudah bawa satu brainrot!", "error")
		return false
	end
	if record.Owner and StateService.isBaseLocked(record.Owner) then
		notify(player, "Base itu terkunci!", "error")
		return false
	end
	if os.clock() < record.StealCooldownUntil then
		return false
	end
	-- Lift it off the victim's base.
	local ownerData = StateService.getData(record.Owner)
	if ownerData then
		for i, owned in ipairs(ownerData.Brainrots) do
			if owned.Id == modelId then
				table.remove(ownerData.Brainrots, i)
				break
			end
		end
	end
	record.State = "carried"
	record.Carrier = player
	record.Model:SetAttribute("State", "carried")
	record.Model:SetAttribute("Carrier", player.UserId)
	data.Carrying = modelId
	setCarrySpeed(player, true)
	notify(player, "Lari! Bawa pulang ke base kamu!", "steal")
	if record.Owner then
		notify(record.Owner, player.DisplayName .. " mencuri brainrot kamu! Tampar dia (E)!", "error")
	end
	return true
end

-- Slap the thief carrying YOUR brainrot: it flies home, the thief is flung.
function StealService.slapBrainrotThief(player, targetPlayer)
	local targetData = StateService.getData(targetPlayer)
	if not targetData or not targetData.Carrying then
		return false
	end
	local record = StateService.getModel(targetData.Carrying)
	if not record or record.Owner ~= player then
		return false
	end
	StealService.returnCarriedBrainrotHome(targetPlayer, true)
	local character = targetPlayer.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.AssemblyLinearVelocity = Vector3.new(0, 35, 0) + (root.CFrame.LookVector * -30)
		end
	end
	notify(player, "Kena! Brainrot kamu balik ke base.", "buy")
	notify(targetPlayer, "Kamu ditampar! Brainrotnya kabur.", "error")
	return true
end

-- Send a carried brainrot back to its owner's base slot.
function StealService.returnCarriedBrainrotHome(carrierPlayer, slapped)
	local data = StateService.getData(carrierPlayer)
	if not data or not data.Carrying then
		return false
	end
	local record = StateService.getModel(data.Carrying)
	data.Carrying = nil
	setCarrySpeed(carrierPlayer, false)
	if not record or not record.Owner then
		return false
	end
	local owner = record.Owner
	local ownerData = StateService.getData(owner)
	if not ownerData then
		StateService.destroyModelRecord(record.Id)
		return false
	end
	record.StealCooldownUntil = os.clock() + 5
	if slapped then
		-- Straight home after a slap.
		local placed = BaseService.placeBrainrotOnBase(record, owner)
		if not placed then
			StateService.destroyModelRecord(record.Id)
		end
	else
		-- Dropped by storm or death: home, same slot if it is still free.
		local placed = BaseService.placeBrainrotOnBase(record, owner)
		if not placed then
			StateService.destroyModelRecord(record.Id)
		end
	end
	return true
end

-- Drop whatever the player is carrying (death, storm, reset).
function StealService.dropCarriedBrainrot(player)
	return StealService.returnCarriedBrainrotHome(player, false)
end

-- Heartbeat: carried brainrots hover above their thief, and a thief who
-- reaches their own base pad keeps the catch for good.
function StealService.startCarryHeartbeat()
	task.spawn(function()
		while true do
			task.wait(0.2)
			for player, data in pairs(StateService.PlayersData) do
				if data.Carrying then
					local record = StateService.getModel(data.Carrying)
					local character = player.Character
					if not record or not character then
						if record then
							StealService.dropCarriedBrainrot(player)
						end
					else
						local root = character:FindFirstChild("HumanoidRootPart")
						if root then
							record.Model:PivotTo(root.CFrame * CFrame.new(0, 3.5, 0))
						end
						if BaseService.isPlayerOnOwnBase(player) then
							-- Home safe: the brainrot is yours now.
							data.Carrying = nil
							setCarrySpeed(player, false)
							record.Owner = player
							record.Carrier = nil
							local placed = BaseService.placeBrainrotOnBase(record, player)
							if placed then
								notify(player, "Berhasil! Brainrot itu sekarang milikmu!", "buy")
							else
								StealService.returnCarriedBrainrotHome(player, false)
								notify(player, "Base penuh, brainrotnya balik ke pemilik lama.", "error")
							end
						end
					end
				end
			end
		end
	end)
end

return StealService
