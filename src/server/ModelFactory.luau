-- ModelFactory: assembles each brainrot character from plain parts.
-- No uploaded images, decals or sounds: body, eyes, accessory and a
-- BillboardGui label (readable name, rarity and money per second).

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local ModelFactory = {}

local function makePart(name, size, color, position, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

-- One small accessory per character, built from blocks on the body.
local function addAccessory(model, accessory, size, bodyColor)
	local s = size
	local top = Vector3.new(0, s * 0.55, 0)
	if accessory == "ears" then
		makePart("EarL", Vector3.new(s * 0.22, s * 0.3, s * 0.12), bodyColor, top + Vector3.new(-s * 0.28, s * 0.08, 0), model)
		makePart("EarR", Vector3.new(s * 0.22, s * 0.3, s * 0.12), bodyColor, top + Vector3.new(s * 0.28, s * 0.08, 0), model)
	elseif accessory == "headphones" then
		local dark = Color3.fromRGB(40, 40, 45)
		makePart("PhoneL", Vector3.new(s * 0.14, s * 0.34, s * 0.3), dark, Vector3.new(-s * 0.55, s * 0.1, 0), model)
		makePart("PhoneR", Vector3.new(s * 0.14, s * 0.34, s * 0.3), dark, Vector3.new(s * 0.55, s * 0.1, 0), model)
		makePart("PhoneTop", Vector3.new(s * 1.1, s * 0.1, s * 0.16), dark, top + Vector3.new(0, s * 0.14, 0), model)
	elseif accessory == "hat" then
		local dark = Color3.fromRGB(35, 35, 40)
		makePart("HatTop", Vector3.new(s * 0.6, s * 0.34, s * 0.6), dark, top + Vector3.new(0, s * 0.1, 0), model)
		makePart("HatBrim", Vector3.new(s * 1.05, s * 0.08, s * 1.05), dark, top + Vector3.new(0, -s * 0.06, 0), model)
	elseif accessory == "crown" then
		local gold = Color3.fromRGB(255, 215, 0)
		makePart("CrownBand", Vector3.new(s * 0.7, s * 0.16, s * 0.7), gold, top + Vector3.new(0, s * 0.05, 0), model)
		makePart("CrownSpike", Vector3.new(s * 0.16, s * 0.3, s * 0.16), gold, top + Vector3.new(0, s * 0.22, 0), model)
	elseif accessory == "glasses" then
		local dark = Color3.fromRGB(25, 25, 30)
		makePart("GlassL", Vector3.new(s * 0.3, s * 0.2, s * 0.06), dark, Vector3.new(-s * 0.22, s * 0.12, s * 0.52), model)
		makePart("GlassR", Vector3.new(s * 0.3, s * 0.2, s * 0.06), dark, Vector3.new(s * 0.22, s * 0.12, s * 0.52), model)
	elseif accessory == "bowtie" then
		local red = Color3.fromRGB(220, 40, 60)
		makePart("BowL", Vector3.new(s * 0.26, s * 0.18, s * 0.08), red, Vector3.new(-s * 0.16, -s * 0.28, s * 0.52), model)
		makePart("BowR", Vector3.new(s * 0.26, s * 0.18, s * 0.08), red, Vector3.new(s * 0.16, -s * 0.28, s * 0.52), model)
	elseif accessory == "scarf" then
		local red = Color3.fromRGB(220, 60, 60)
		makePart("Scarf", Vector3.new(s * 1.02, s * 0.18, s * 1.02), red, Vector3.new(0, -s * 0.3, 0), model)
	elseif accessory == "antenna" then
		local silver = Color3.fromRGB(200, 200, 210)
		makePart("Antenna", Vector3.new(s * 0.08, s * 0.6, s * 0.08), silver, top + Vector3.new(0, s * 0.3, 0), model)
		local tip = makePart("AntennaTip", Vector3.new(s * 0.24, s * 0.24, s * 0.24), Color3.fromRGB(255, 90, 90), top + Vector3.new(0, s * 0.62, 0), model)
		tip.Shape = Enum.PartType.Ball
	elseif accessory == "backpack" then
		local pack = Color3.fromRGB(255, 200, 40)
		makePart("Pack", Vector3.new(s * 0.5, s * 0.6, s * 0.24), pack, Vector3.new(0, 0, -s * 0.6), model)
	end
end

-- Build a brainrot model at the origin; the caller positions it with PivotTo.
function ModelFactory.buildBrainrotModel(char, mutation, modelId)
	local data = BrainrotData.Mutations[mutation] or BrainrotData.Mutations.Normal
	local bodyColor = data.Color or char.Color
	local size = char.Size

	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. modelId

	local body = makePart("Body", Vector3.new(size, size, size), bodyColor, Vector3.new(0, size * 0.5, 0), model)
	body.CanCollide = true
	model.PrimaryPart = body

	-- Two eyes on the front (+Z) face, white with black pupils.
	local eyeY = size * 0.68
	local eyeZ = size * 0.52
	local eyeSize = Vector3.new(size * 0.2, size * 0.26, size * 0.06)
	makePart("EyeL", eyeSize, Color3.fromRGB(255, 255, 255), Vector3.new(-size * 0.2, eyeY, eyeZ), model)
	makePart("EyeR", eyeSize, Color3.fromRGB(255, 255, 255), Vector3.new(size * 0.2, eyeY, eyeZ), model)
	local pupilSize = Vector3.new(size * 0.1, size * 0.14, size * 0.06)
	makePart("PupilL", pupilSize, Color3.fromRGB(20, 20, 20), Vector3.new(-size * 0.2, eyeY, eyeZ + size * 0.02), model)
	makePart("PupilR", pupilSize, Color3.fromRGB(20, 20, 20), Vector3.new(size * 0.2, eyeY, eyeZ + size * 0.02), model)

	addAccessory(model, char.Accessory, size, bodyColor)

	-- A golden shimmer block under mutated brainrots so they read at a glance.
	if mutation ~= "Normal" then
		local glow = makePart("MutationGlow", Vector3.new(size * 1.15, size * 0.12, size * 1.15), data.Color, Vector3.new(0, size * 0.06, 0), model)
		glow.Transparency = 0.35
	end

	-- Readable label: name, rarity and money per second.
	local rarity = BrainrotData.Rarities[char.Rarity]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(0, 170, 0, 56)
	gui.StudsOffset = Vector3.new(0, size + 1.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body

	local label = Instance.new("TextLabel")
	label.Name = "NameLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	label.BackgroundTransparency = 0.35
	label.BorderSizePixel = 0
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = BrainrotData.getDisplayName(char, mutation) .. "\n" .. char.Rarity .. " - $" .. tostring(BrainrotData.getIncome(char, mutation)) .. "/s"
	label.Parent = gui

	-- A second, rarity-coloured strip under the name so the tier reads by colour.
	local strip = Instance.new("Frame")
	strip.Name = "RarityStrip"
	strip.Size = UDim2.new(1, 0, 0, 5)
	strip.Position = UDim2.new(0, 0, 1, -5)
	strip.BackgroundColor3 = rarity.Color
	strip.BorderSizePixel = 0
	strip.Parent = label

	local click = Instance.new("ClickDetector")
	click.Name = "BuyClick"
	click.MaxActivationDistance = 40
	click.Parent = body

	model:SetAttribute("BrainrotId", modelId)
	model:SetAttribute("CharId", char.Id)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("State", "conveyor")
	model:SetAttribute("Price", char.Cost)
	model:SetAttribute("Owner", 0)
	model:SetAttribute("Carrier", 0)

	return model
end

return ModelFactory
