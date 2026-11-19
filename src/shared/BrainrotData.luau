-- BrainrotData: the cast of Brainrot Base Rush.
-- Twelve original characters on a six-rung rarity ladder, plus mutations.
-- Every character is built from plain parts by ModelFactory, so no uploaded
-- images or sounds are needed. Shared by server and client.

local BrainrotData = {}

BrainrotData.Rarities = {
	Common = { Weight = 55, Color = Color3.fromRGB(110, 200, 90) },
	Rare = { Weight = 26, Color = Color3.fromRGB(80, 150, 255) },
	Epic = { Weight = 12, Color = Color3.fromRGB(170, 90, 230) },
	Legendary = { Weight = 4.5, Color = Color3.fromRGB(255, 170, 30) },
	Mythic = { Weight = 1.8, Color = Color3.fromRGB(255, 80, 120) },
	Secret = { Weight = 0.7, Color = Color3.fromRGB(80, 230, 230) },
}

-- Cost is the conveyor price. Income is cash per second once the brainrot
-- stands on a base. Size is the body cube edge in studs.
BrainrotData.Characters = {
	{ Id = "capy", Name = "Capy Bara Boom", Rarity = "Common", Cost = 25, Income = 1, Size = 2.0, Color = Color3.fromRGB(150, 105, 60), Accessory = "ears" },
	{ Id = "banana", Name = "Banana Hammock", Rarity = "Common", Cost = 60, Income = 2, Size = 2.0, Color = Color3.fromRGB(250, 220, 60), Accessory = "bowtie" },
	{ Id = "cereal", Name = "Soggy Cereal", Rarity = "Common", Cost = 120, Income = 4, Size = 2.0, Color = Color3.fromRGB(220, 190, 150), Accessory = "scarf" },
	{ Id = "quack", Name = "Sir Quackleton", Rarity = "Rare", Cost = 300, Income = 10, Size = 2.4, Color = Color3.fromRGB(240, 240, 235), Accessory = "hat" },
	{ Id = "meowcha", Name = "DJ Meowcha", Rarity = "Rare", Cost = 650, Income = 20, Size = 2.4, Color = Color3.fromRGB(250, 140, 180), Accessory = "headphones" },
	{ Id = "pasta", Name = "Pasta La Vista", Rarity = "Rare", Cost = 1200, Income = 35, Size = 2.4, Color = Color3.fromRGB(250, 160, 60), Accessory = "glasses" },
	{ Id = "toilet", Name = "Toilet Tornado", Rarity = "Epic", Cost = 2500, Income = 70, Size = 3.0, Color = Color3.fromRGB(200, 230, 250), Accessory = "antenna" },
	{ Id = "croc", Name = "Crocodile Croissant", Rarity = "Epic", Cost = 5000, Income = 130, Size = 3.0, Color = Color3.fromRGB(90, 190, 90), Accessory = "backpack" },
	{ Id = "pickle", Name = "Professor Pickle", Rarity = "Epic", Cost = 9000, Income = 220, Size = 3.0, Color = Color3.fromRGB(60, 130, 60), Accessory = "glasses" },
	{ Id = "dino", Name = "Disco Dino", Rarity = "Legendary", Cost = 20000, Income = 450, Size = 3.6, Color = Color3.fromRGB(170, 90, 220), Accessory = "headphones" },
	{ Id = "wifi", Name = "Grandma's WiFi", Rarity = "Mythic", Cost = 60000, Income = 1100, Size = 4.0, Color = Color3.fromRGB(200, 170, 180), Accessory = "antenna" },
	{ Id = "quokka", Name = "Quantum Quokka", Rarity = "Secret", Cost = 180000, Income = 3500, Size = 4.4, Color = Color3.fromRGB(80, 220, 230), Accessory = "crown" },
}

BrainrotData.ById = {}
for _, char in ipairs(BrainrotData.Characters) do
	BrainrotData.ById[char.Id] = char
end

BrainrotData.Mutations = {
	Normal = { Multiplier = 1, Color = nil, Label = "" },
	Golden = { Multiplier = 2, Color = Color3.fromRGB(255, 215, 0), Label = "GOLDEN " },
	Diamond = { Multiplier = 5, Color = Color3.fromRGB(150, 220, 255), Label = "DIAMOND " },
	Rainbow = { Multiplier = 10, Color = Color3.fromRGB(255, 80, 200), Label = "RAINBOW " },
}

-- Roll a rarity by weight, then a random character of that rarity.
function BrainrotData.rollRarity()
	local roll = math.random() * 100
	local running = 0
	for name, data in pairs(BrainrotData.Rarities) do
		running = running + data.Weight
		if roll <= running then
			return name
		end
	end
	return "Common"
end

function BrainrotData.rollCharacter()
	local rarity = BrainrotData.rollRarity()
	local pool = {}
	for _, char in ipairs(BrainrotData.Characters) do
		if char.Rarity == rarity then
			table.insert(pool, char)
		end
	end
	if #pool == 0 then
		return BrainrotData.Characters[1]
	end
	return pool[math.random(1, #pool)]
end

-- 1% Rainbow, 4% Diamond, 12% Golden, the rest Normal.
function BrainrotData.rollMutation()
	local roll = math.random()
	if roll < 0.01 then
		return "Rainbow"
	elseif roll < 0.05 then
		return "Diamond"
	elseif roll < 0.17 then
		return "Golden"
	end
	return "Normal"
end

function BrainrotData.getCharacter(id)
	return BrainrotData.ById[id]
end

function BrainrotData.getIncome(char, mutation)
	local data = BrainrotData.Mutations[mutation] or BrainrotData.Mutations.Normal
	return char.Income * data.Multiplier
end

function BrainrotData.getDisplayName(char, mutation)
	local data = BrainrotData.Mutations[mutation] or BrainrotData.Mutations.Normal
	return data.Label .. char.Name
end

return BrainrotData
