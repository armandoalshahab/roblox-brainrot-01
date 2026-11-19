-- Game.client: the client boot. Binds E (buy / steal / slap, whichever is
-- nearest) and L (lock your base) through ContextActionService, scans for the
-- nearest interactable brainrot, and wires every server event to the UI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local player = Players.LocalPlayer
local ClientUI = require(script.Parent.ClientUI)
local ClientEffects = require(script.Parent.ClientEffects)

local BuyBrainrot = ReplicatedStorage:WaitForChild("BuyBrainrot")
local StealBrainrot = ReplicatedStorage:WaitForChild("StealBrainrot")
local SlapPlayer = ReplicatedStorage:WaitForChild("SlapPlayer")
local LockBase = ReplicatedStorage:WaitForChild("LockBase")
local BuyUpgrade = ReplicatedStorage:WaitForChild("BuyUpgrade")
local Rebirth = ReplicatedStorage:WaitForChild("Rebirth")
local UpdateHUD = ReplicatedStorage:WaitForChild("UpdateHUD")
local Notify = ReplicatedStorage:WaitForChild("Notify")
local StormWarning = ReplicatedStorage:WaitForChild("StormWarning")
local LeaderboardUpdate = ReplicatedStorage:WaitForChild("LeaderboardUpdate")

local currentTarget = nil -- {Kind = "buy"|"steal"|"slap", ModelId, TargetPlayer, Label}

local function getRoot()
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

-- Find the nearest thing E can do: buy from the conveyor, steal from a
-- rival base, or slap the thief carrying your brainrot.
local function findNearestInteractable()
	local root = getRoot()
	if not root then
		return nil
	end
	local folder = workspace:FindFirstChild("BrainrotModels")
	if not folder then
		return nil
	end
	local best = nil
	local bestDistance = 13
	local slap = nil
	local slapDistance = 9
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model.PrimaryPart then
			local state = model:GetAttribute("State")
			local distance = (model.PrimaryPart.Position - root.Position).Magnitude
			if state == "conveyor" and distance < bestDistance then
				local price = model:GetAttribute("Price") or 0
				local charId = model:GetAttribute("CharId") or ""
				local char = BrainrotData.getCharacter(charId)
				local displayName = char and char.Name or charId
				best = { Kind = "buy", ModelId = model:GetAttribute("BrainrotId"), CharId = charId, Price = price }
				best.Label = "[E] Beli " .. displayName .. " - $" .. tostring(price)
				bestDistance = distance
			elseif state == "base" and distance < bestDistance then
				local owner = model:GetAttribute("Owner") or 0
				if owner ~= 0 and owner ~= player.UserId then
					best = { Kind = "steal", ModelId = model:GetAttribute("BrainrotId") }
					best.Label = "[E] CURI brainrot ini!"
					bestDistance = distance
				end
			elseif state == "carried" and distance < slapDistance then
				local owner = model:GetAttribute("Owner") or 0
				local carrier = model:GetAttribute("Carrier") or 0
				if owner == player.UserId and carrier ~= 0 and carrier ~= player.UserId then
					local target = Players:GetPlayerByUserId(carrier)
					if target then
						slap = { Kind = "slap", TargetPlayer = target, ModelId = model:GetAttribute("BrainrotId") }
						slap.Label = "[E] TAMPAR pencuri!"
						slapDistance = distance
					end
				end
			end
		end
	end
	if slap then
		return slap
	end
	return best
end

local function doInteract()
	local target = currentTarget or findNearestInteractable()
	if not target then
		return
	end
	if target.Kind == "buy" then
		BuyBrainrot:FireServer(target.ModelId)
	elseif target.Kind == "steal" then
		StealBrainrot:FireServer(target.ModelId)
	elseif target.Kind == "slap" then
		SlapPlayer:FireServer(target.TargetPlayer)
	end
end

local function onInteract(_action, state, _input)
	if state == Enum.UserInputState.Begin then
		doInteract()
	end
	return Enum.ContextActionResult.Sink
end

local function onLock(_action, state, _input)
	if state == Enum.UserInputState.Begin then
		LockBase:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BrainrotInteract", onInteract, false, Enum.KeyCode.E)
ContextActionService:BindAction("BrainrotLockBase", onLock, false, Enum.KeyCode.L)

ClientUI.setInteractCallback(doInteract)
ClientUI.setLockCallback(function()
	LockBase:FireServer()
end)
ClientUI.setUpgradeCallback(function(upgradeId)
	BuyUpgrade:FireServer(upgradeId)
end)
ClientUI.setRebirthCallback(function()
	Rebirth:FireServer()
end)

UpdateHUD.OnClientEvent:Connect(function(data)
	ClientUI.updateHUD(data)
end)

Notify.OnClientEvent:Connect(function(message, kind, position)
	ClientUI.showToast(message, kind)
	if kind == "buy" or kind == "steal" then
		if position then
			ClientEffects.playBuyBurst(position)
		end
	elseif kind == "rebirth" then
		ClientEffects.pulseCash()
	end
end)

StormWarning.OnClientEvent:Connect(function(seconds)
	ClientEffects.showStormWarning(seconds)
	ClientUI.showToast("BRAINROT STORM! Lari ke base!", "storm")
end)

LeaderboardUpdate.OnClientEvent:Connect(function(rows)
	ClientUI.updateLeaderboard(rows)
end)

-- Refresh the hint label a few times a second.
RunService.RenderStepped:Connect(function()
	currentTarget = findNearestInteractable()
	if currentTarget then
		ClientUI.setHint(currentTarget.Label)
	else
		ClientUI.setHint("[E] Beli / Curi  -  [L] Kunci Base  -  Conveyor di selatan, base kamu di utara!")
	end
end)
