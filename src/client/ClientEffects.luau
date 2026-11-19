-- ClientEffects: juice. A gold particle burst where a brainrot is bought or
-- stolen, a red storm vignette, and a cash-label pulse on rebirth.

local TweenService = game:GetService("TweenService")

local ClientEffects = {}

local stormFrame = nil

function ClientEffects.playBuyBurst(position)
	local anchor = Instance.new("Part")
	anchor.Name = "BuyBurst"
	anchor.Size = Vector3.new(0.5, 0.5, 0.5)
	anchor.Position = position
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Size = NumberSequence.new(0.6)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(30)

	task.delay(1.5, function()
		anchor:Destroy()
	end)
end

function ClientEffects.showStormWarning(seconds)
	local Players = game:GetService("Players")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local hud = playerGui:FindFirstChild("BrainrotHUD")
	if not hud then
		return
	end
	if not stormFrame then
		stormFrame = Instance.new("Frame")
		stormFrame.Name = "StormVignette"
		stormFrame.Size = UDim2.fromScale(1, 1)
		stormFrame.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
		stormFrame.BackgroundTransparency = 0.8
		stormFrame.BorderSizePixel = 0
		stormFrame.Visible = false
		stormFrame.Parent = hud
	end
	stormFrame.Visible = true
	stormFrame.BackgroundTransparency = 0.55
	task.delay(seconds, function()
		local tween = TweenService:Create(stormFrame, TweenInfo.new(1.5), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Connect(function()
			stormFrame.Visible = false
		end)
	end)
end

function ClientEffects.pulseCash()
	local ClientUI = require(script.Parent.ClientUI)
	local cashLabel = ClientUI.getCashLabel()
	if not cashLabel then
		return
	end
	local tweenUp = TweenService:Create(cashLabel, TweenInfo.new(0.15), { TextSize = 38 })
	local tweenDown = TweenService:Create(cashLabel, TweenInfo.new(0.3), { TextSize = 30 })
	tweenUp:Play()
	tweenUp.Completed:Connect(function()
		tweenDown:Play()
	end)
end

return ClientEffects
