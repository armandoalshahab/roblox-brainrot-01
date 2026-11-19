-- ClientUI: every pixel of the Brainrot Base Rush HUD.
-- Cash and income top-center, shop / upgrades / rebirth bottom-center,
-- lock and interact bottom-right, hints bottom-left, leaderboard right.
-- The top-left corner stays clear: Roblox's own menu buttons sit there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)

local ClientUI = {}

local player = Players.LocalPlayer
local gui = nil
local cashLabel = nil
local incomeLabel = nil
local hintLabel = nil
local toastLabel = nil
local lockButton = nil
local rebirthButton = nil
local shopFrame = nil
local upgradesFrame = nil
local leaderboardRows = nil
local toastToken = 0

local interactCallback = nil
local lockCallback = nil
local upgradeCallback = nil
local rebirthCallback = nil
local buyByCharIdCallback = nil

function ClientUI.setInteractCallback(fn)
	interactCallback = fn
end

function ClientUI.setLockCallback(fn)
	lockCallback = fn
end

function ClientUI.setUpgradeCallback(fn)
	upgradeCallback = fn
end

function ClientUI.setRebirthCallback(fn)
	rebirthCallback = fn
end

function ClientUI.setBuyByCharIdCallback(fn)
	buyByCharIdCallback = fn
end

local function makeLabel(parent, name, text, size, position, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = size
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(400, 34)
	label.Position = position
	if anchor then
		label.AnchorPoint = anchor
	end
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, anchor)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	button.BorderSizePixel = 0
	button.Size = size
	button.Position = position
	if anchor then
		button.AnchorPoint = anchor
	end
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local function buildShop()
	shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Size = UDim2.fromOffset(520, 430)
	shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	shopFrame.Position = UDim2.fromScale(0.5, 0.5)
	shopFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	shopFrame.BorderSizePixel = 0
	shopFrame.Visible = false
	shopFrame.Parent = gui

	local title = makeLabel(shopFrame, "ShopTitle", "BRAINROT SHOP - cari di conveyor!", 22, UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0))
	title.Size = UDim2.fromOffset(500, 30)

	local list = Instance.new("ScrollingFrame")
	list.Name = "ShopList"
	list.Size = UDim2.new(1, -16, 1, -56)
	list.Position = UDim2.new(0, 8, 0, 44)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, #BrainrotData.Characters * 34)
	list.Parent = shopFrame

	for i, char in ipairs(BrainrotData.Characters) do
		local rarity = BrainrotData.Rarities[char.Rarity]
		local row = Instance.new("Frame")
		row.Name = "ShopRow" .. char.Id
		row.Size = UDim2.new(1, 0, 0, 30)
		row.Position = UDim2.new(0, 0, 0, (i - 1) * 34)
		row.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		row.BorderSizePixel = 0
		row.Parent = list
		local info = Instance.new("TextLabel")
		info.Name = "ShopInfo"
		info.Size = UDim2.new(1, -132, 1, 0)
		info.Position = UDim2.new(0, 6, 0, 0)
		info.BackgroundTransparency = 1
		info.Font = Enum.Font.SourceSansBold
		info.TextSize = 16
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextColor3 = Color3.fromRGB(255, 255, 255)
		info.Text = char.Name .. "  |  " .. char.Rarity .. "  |  $" .. tostring(char.Cost) .. "  |  $" .. tostring(char.Income) .. "/s"
		info.Parent = row
		local strip = Instance.new("Frame")
		strip.Size = UDim2.new(0, 6, 1, 0)
		strip.BackgroundColor3 = rarity.Color
		strip.BorderSizePixel = 0
		strip.Parent = row
		-- Real BELI button: buys a brainrot of this character ONLY if one is
		-- riding the conveyor right now (same remote as the E key). If none
		-- is on the belt, the callback shows an error toast instead.
		local buy = makeButton(row, "Buy" .. char.Id, "BELI $" .. tostring(char.Cost), UDim2.fromOffset(116, 24), UDim2.new(1, -8, 0.5, 0), Vector2.new(1, 0.5))
		buy.BackgroundColor3 = Color3.fromRGB(30, 130, 60)
		buy.TextSize = 16
		buy.MouseButton1Click:Connect(function()
			if buyByCharIdCallback then
				buyByCharIdCallback(char.Id)
			end
		end)
	end

	local close = makeButton(shopFrame, "CloseShop", "TUTUP", UDim2.fromOffset(90, 34), UDim2.new(1, -8, 0, 8), Vector2.new(1, 0))
	close.MouseButton1Click:Connect(function()
		shopFrame.Visible = false
	end)
end

local function buildUpgrades()
	upgradesFrame = Instance.new("Frame")
	upgradesFrame.Name = "UpgradesFrame"
	upgradesFrame.Size = UDim2.fromOffset(440, 250)
	upgradesFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	upgradesFrame.Position = UDim2.fromScale(0.5, 0.5)
	upgradesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	upgradesFrame.BorderSizePixel = 0
	upgradesFrame.Visible = false
	upgradesFrame.Parent = gui

	local title = makeLabel(upgradesFrame, "UpgradesTitle", "UPGRADES", 22, UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0))
	title.Size = UDim2.fromOffset(420, 30)

	local order = { "conveyor", "lock", "slots" }
	for i, id in ipairs(order) do
		local track = Config.Upgrades[id]
		local row = Instance.new("Frame")
		row.Name = "UpgradeRow" .. id
		row.Size = UDim2.new(1, -16, 0, 52)
		row.Position = UDim2.new(0, 8, 0, 44 + (i - 1) * 60)
		row.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		row.BorderSizePixel = 0
		row.Parent = upgradesFrame

		local label = Instance.new("TextLabel")
		label.Name = "UpgradeLabel"
		label.Size = UDim2.new(1, -130, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = track.Name .. " - " .. track.Desc .. " (Lv0/3)"
		label.Parent = row

		local buy = makeButton(row, "Buy" .. id, "BELI $?", UDim2.fromOffset(110, 36), UDim2.new(1, -8, 0.5, 0), Vector2.new(1, 0.5))
		buy.MouseButton1Click:Connect(function()
			if upgradeCallback then
				upgradeCallback(id)
			end
		end)
	end

	local close = makeButton(upgradesFrame, "CloseUpgrades", "TUTUP", UDim2.fromOffset(90, 34), UDim2.new(1, -8, 0, 8), Vector2.new(1, 0))
	close.MouseButton1Click:Connect(function()
		upgradesFrame.Visible = false
	end)
end

local function buildHUD()
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Cash top-center: big enough to read once the screenshot scales down.
	cashLabel = makeLabel(gui, "CashLabel", "$100", 30, UDim2.new(0.5, 0, 0, 10), Vector2.new(0.5, 0))
	cashLabel.Size = UDim2.fromOffset(400, 40)
	incomeLabel = makeLabel(gui, "IncomeLabel", "$0/s  -  Rebirth x1", 18, UDim2.new(0.5, 0, 0, 48), Vector2.new(0.5, 0))
	incomeLabel.Size = UDim2.fromOffset(400, 26)

	toastLabel = makeLabel(gui, "ToastLabel", "", 20, UDim2.new(0.5, 0, 0, 84), Vector2.new(0.5, 0))
	toastLabel.Size = UDim2.fromOffset(560, 30)
	toastLabel.Visible = false

	hintLabel = makeLabel(gui, "HintLabel", "", 18, UDim2.new(0, 12, 1, -12), Vector2.new(0, 1))
	hintLabel.Size = UDim2.fromOffset(560, 26)
	hintLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Bottom-center action buttons.
	local shopButton = makeButton(gui, "ShopButton", "SHOP", UDim2.fromOffset(120, 46), UDim2.new(0.5, -190, 1, -60), Vector2.new(0.5, 1))
	shopButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = not shopFrame.Visible
		upgradesFrame.Visible = false
	end)
	local upgradesButton = makeButton(gui, "UpgradesButton", "UPGRADES", UDim2.fromOffset(120, 46), UDim2.new(0.5, -60, 1, -60), Vector2.new(0.5, 1))
	upgradesButton.MouseButton1Click:Connect(function()
		upgradesFrame.Visible = not upgradesFrame.Visible
		shopFrame.Visible = false
	end)
	rebirthButton = makeButton(gui, "RebirthButton", "REBIRTH $25,000", UDim2.fromOffset(170, 46), UDim2.new(0.5, 70, 1, -60), Vector2.new(0.5, 1))
	rebirthButton.BackgroundColor3 = Color3.fromRGB(120, 40, 160)
	rebirthButton.MouseButton1Click:Connect(function()
		if rebirthCallback then
			rebirthCallback()
		end
	end)

	-- Bottom-right: interact + lock (touch-friendly, and the E / L keys).
	local interactButton = makeButton(gui, "InteractButton", "INTERACT (E)", UDim2.fromOffset(170, 46), UDim2.new(1, -12, 1, -114), Vector2.new(1, 1))
	interactButton.BackgroundColor3 = Color3.fromRGB(30, 130, 60)
	interactButton.MouseButton1Click:Connect(function()
		if interactCallback then
			interactCallback()
		end
	end)
	lockButton = makeButton(gui, "LockButton", "LOCK BASE (L)", UDim2.fromOffset(170, 46), UDim2.new(1, -12, 1, -60), Vector2.new(1, 1))
	lockButton.BackgroundColor3 = Color3.fromRGB(180, 60, 40)
	lockButton.MouseButton1Click:Connect(function()
		if lockCallback then
			lockCallback()
		end
	end)

	-- Leaderboard, right side under the top.
	local board = Instance.new("Frame")
	board.Name = "Leaderboard"
	board.Size = UDim2.fromOffset(200, 190)
	board.Position = UDim2.new(1, -12, 0, 110)
	board.AnchorPoint = Vector2.new(1, 0)
	board.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	board.BackgroundTransparency = 0.25
	board.BorderSizePixel = 0
	board.Parent = gui
	local boardTitle = makeLabel(board, "BoardTitle", "TOP PLAYERS", 18, UDim2.new(0.5, 0, 0, 6), Vector2.new(0.5, 0))
	boardTitle.Size = UDim2.fromOffset(190, 24)
	leaderboardRows = Instance.new("Frame")
	leaderboardRows.Name = "BoardRows"
	leaderboardRows.Size = UDim2.new(1, 0, 1, -34)
	leaderboardRows.Position = UDim2.new(0, 0, 0, 34)
	leaderboardRows.BackgroundTransparency = 1
	leaderboardRows.Parent = board

	buildShop()
	buildUpgrades()
end

buildHUD()

function ClientUI.setHint(text)
	if hintLabel then
		hintLabel.Text = text
	end
end

function ClientUI.showToast(message, kind)
	if not toastLabel then
		return
	end
	toastToken = toastToken + 1
	local token = toastToken
	toastLabel.Text = message
	if kind == "error" then
		toastLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	elseif kind == "storm" then
		toastLabel.TextColor3 = Color3.fromRGB(120, 180, 255)
	elseif kind == "rebirth" then
		toastLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	else
		toastLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
	end
	toastLabel.Visible = true
	task.delay(3, function()
		if token == toastToken then
			toastLabel.Visible = false
		end
	end)
end

function ClientUI.updateHUD(data)
	if cashLabel then
		cashLabel.Text = "$" .. tostring(data.Cash)
	end
	if incomeLabel then
		incomeLabel.Text = "$" .. tostring(data.IncomePerSecond) .. "/s  -  Rebirth x" .. tostring(data.Multiplier) .. "  -  Base #" .. tostring(data.BaseIndex) .. "  -  Slot kosong: " .. tostring(data.FreeSlots)
	end
	if lockButton then
		if data.LockLeft > 0 then
			lockButton.Text = "TERKUNCI " .. tostring(data.LockLeft) .. "s"
		elseif data.LockCooldownLeft > 0 then
			lockButton.Text = "LOCK (" .. tostring(data.LockCooldownLeft) .. "s)"
		else
			lockButton.Text = "LOCK BASE (L)"
		end
	end
	if rebirthButton then
		rebirthButton.Text = "REBIRTH $" .. tostring(data.RebirthCost)
	end
	if upgradesFrame then
		for _, id in ipairs({ "conveyor", "lock", "slots" }) do
			local row = upgradesFrame:FindFirstChild("UpgradeRow" .. id)
			if row then
				local track = Config.Upgrades[id]
				local level = data.Upgrades[id] or 0
				local label = row:FindFirstChild("UpgradeLabel")
				local buy = row:FindFirstChild("Buy" .. id)
				if label then
					label.Text = track.Name .. " - " .. track.Desc .. " (Lv" .. tostring(level) .. "/3)"
				end
				if buy then
					if level >= #track.Costs then
						buy.Text = "MAX"
					else
						buy.Text = "BELI $" .. tostring(track.Costs[level + 1])
					end
				end
			end
		end
	end
end

function ClientUI.updateLeaderboard(rows)
	if not leaderboardRows then
		return
	end
	for _, child in ipairs(leaderboardRows:GetChildren()) do
		child:Destroy()
	end
	for i, row in ipairs(rows) do
		if i > 5 then
			break
		end
		local label = Instance.new("TextLabel")
		label.Name = "Row" .. tostring(i)
		label.Size = UDim2.new(1, -12, 0, 26)
		label.Position = UDim2.new(0, 6, 0, (i - 1) * 28)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = tostring(i) .. ". " .. row.Name .. "  $" .. tostring(row.Cash)
		label.Parent = leaderboardRows
	end
end

function ClientUI.getCashLabel()
	return cashLabel
end

return ClientUI
