local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ProPadEvent = Remotes:WaitForChild("ProPad")
local CombatEvent = Remotes:WaitForChild("Combat")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GunFramework = Modules:WaitForChild("GunFramework")
local GunModules = GunFramework:WaitForChild("Modules")
local ProjectileModule = GunModules:WaitForChild("Projectile")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Highlights, ServiceConnections = {}, {}

local Environment = getgenv().Env or {}
if not Environment then
	getgenv().Env = {}
	Environment = getgenv().Env
end

local Destinations = {
	["Gun Buyer"] = CFrame.new(1054, 58, -116),
	["The Yacht"] = CFrame.new(894, 53, -1825),
	["Oil Rig"] = CFrame.new(-217, 40, -1691),
	["Pier"] = CFrame.new(843, 52, -1020),
	["Dealership"] = CFrame.new(540, 52, 57),
	["The Bank"] = CFrame.new(395, 53, 93),
	["Apartments1"] = CFrame.new(552, -41, -134),
	["Apartments2"] = CFrame.new(376, -41, -470),
	["Apartments3"] = CFrame.new(544, -59, 365),
	["Apartments4"] = CFrame.new(-21, -54, -354),
	["Uphill"] = CFrame.new(886, 70, 597),
	["Gunstore1"] = CFrame.new(652, 52, -385),
	["Gunstore2"] = CFrame.new(33, 70, 583),
	["The Jew Store"] = CFrame.new(3, 53, -242),
	["Black Market"] = CFrame.new(857, 52, -712),
	["Loot Buyer"] = CFrame.new(304, 52, 293)
}

local Drawings = {
	ESP = {},
	Tracers = {},
	Boxes = {},
	Healthbars = {},
	Names = {},
	Distances = {},
	Snaplines = {},
	Skeleton = {}
}

local Colors = {
	Enemy = Color3.fromRGB(255, 25, 25),
	Ally = Color3.fromRGB(25, 255, 25),
	Neutral = Color3.fromRGB(255, 255, 255),
	Selected = Color3.fromRGB(255, 210, 0),
	Health = Color3.fromRGB(0, 255, 0),
	Distance = Color3.fromRGB(200, 200, 200)
}

local ESPSettings = {
	Enabled = true,
	TeamCheck = false,
	ShowTeam = false,
	VisibilityCheck = true,
	BoxESP = false,
	BoxStyle = "Corner",
	BoxOutline = true,
	BoxFilled = false,
	BoxFillTransparency = 0.5,
	BoxThickness = 1,
	TracerESP = false,
	TracerOrigin = "Bottom",
	TracerStyle = "Line",
	TracerThickness = 1,
	HealthESP = false,
	HealthStyle = "Bar",
	HealthBarSide = "Left",
	HealthTextSuffix = "HP",
	NameESP = false,
	NameMode = "DisplayName",
	ShowDistance = true,
	DistanceUnit = "studs",
	TextSize = 14,
	TextFont = 2,
	MaxDistance = 1000,
	RefreshRate = 1/144,
	Snaplines = false,
	SnaplineStyle = "Straight",
	RainbowEnabled = false,
	RainbowBoxes = false,
	RainbowTracers = false,
	RainbowText = false,
	ChamsEnabled = false,
	ThermalEnabled = false,
	ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
	ChamsFillColor = Color3.fromRGB(255, 0, 0),
	ChamsOccludedColor = Color3.fromRGB(150, 0, 0),
	ChamsTransparency = 0.5,
	ChamsOutlineTransparency = 0,
	ChamsOutlineThickness = 0.1,
	SkeletonESP = false,
	SkeletonColor = Color3.fromRGB(255, 255, 255),
	SkeletonThickness = 1.5,
	SkeletonTransparency = 1
}

local AimbotSettings = {
	Enabled = true,
	FFCheck = true,
	AlwaysActive = false,
	TeamCheck = false,
	AllyCheck = true,
	AliveCheck = true,
	WallCheck = false, -- Laggy
	TriggerKey = "MouseButton2",
	Toggle = false,
	LockPart = "Head" -- Body part to lock on
}

local FOVSettings = {
	Enabled = true,
	Visible = true,
	Amount = 90,
	Color = Color3.fromRGB(255, 255, 255),
	LockedColor = Color3.fromRGB(255, 70, 70),
	Transparency = 0.5,
	Sides = 9,
	Thickness = 1,
	Filled = false
}

local LocalFriends, LocalID = {}, Player.UserId
local function CreateESP(OtherPlayer)
	if OtherPlayer == Player then
		return
	end

	LocalFriends[OtherPlayer] = OtherPlayer:IsFriendsWithAsync(LocalID)
	local box = {
		TopLeft = Drawing.new("Line"),
		TopRight = Drawing.new("Line"),
		BottomLeft = Drawing.new("Line"),
		BottomRight = Drawing.new("Line"),
		Left = Drawing.new("Line"),
		Right = Drawing.new("Line"),
		Top = Drawing.new("Line"),
		Bottom = Drawing.new("Line")
	}

	for _, line in pairs(box) do
		line.Visible = false
		line.Color = Colors.Enemy
		line.Thickness = ESPSettings.BoxThickness
		if line == box.Fill then
			line.Filled = true
			line.Transparency = ESPSettings.BoxFillTransparency
		end
	end

	local tracer = Drawing.new("Line")
	tracer.Visible = false
	tracer.Color = Colors.Enemy
	tracer.Thickness = ESPSettings.TracerThickness

	local healthBar = {
		Outline = Drawing.new("Square"),
		Fill = Drawing.new("Square"),
		Text = Drawing.new("Text")
	}

	for _, obj in pairs(healthBar) do
		obj.Visible = false
		if obj == healthBar.Fill then
			obj.Color = Colors.Health
			obj.Filled = true
		elseif obj == healthBar.Text then
			obj.Center = true
			obj.Size = ESPSettings.TextSize
			obj.Color = Colors.Health
			obj.Font = ESPSettings.TextFont
		end
	end

	local info = {
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text")
	}

	for _, text in pairs(info) do
		text.Visible = false
		text.Center = true
		text.Size = ESPSettings.TextSize
		text.Color = Colors.Enemy
		text.Font = ESPSettings.TextFont
		text.Outline = true
	end

	local snapline = Drawing.new("Line")
	snapline.Visible = false
	snapline.Color = Colors.Enemy
	snapline.Thickness = 1

	local highlight = Instance.new("Highlight")
	highlight.FillColor = ESPSettings.ChamsFillColor
	highlight.OutlineColor = ESPSettings.ChamsOutlineColor
	highlight.FillTransparency = ESPSettings.ChamsTransparency
	highlight.OutlineTransparency = ESPSettings.ChamsOutlineTransparency
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = ESPSettings.ChamsEnabled

	Highlights[OtherPlayer] = highlight

	local skeleton = {
		-- Spine & Head
		Head = Drawing.new("Line"),
		Neck = Drawing.new("Line"),
		UpperSpine = Drawing.new("Line"),
		LowerSpine = Drawing.new("Line"),

		-- Left Arm
		LeftShoulder = Drawing.new("Line"),
		LeftUpperArm = Drawing.new("Line"),
		LeftLowerArm = Drawing.new("Line"),
		LeftHand = Drawing.new("Line"),

		-- Right Arm
		RightShoulder = Drawing.new("Line"),
		RightUpperArm = Drawing.new("Line"),
		RightLowerArm = Drawing.new("Line"),
		RightHand = Drawing.new("Line"),

		-- Left Leg
		LeftHip = Drawing.new("Line"),
		LeftUpperLeg = Drawing.new("Line"),
		LeftLowerLeg = Drawing.new("Line"),
		LeftFoot = Drawing.new("Line"),

		-- Right Leg
		RightHip = Drawing.new("Line"),
		RightUpperLeg = Drawing.new("Line"),
		RightLowerLeg = Drawing.new("Line"),
		RightFoot = Drawing.new("Line")
	}

	for _, line in pairs(skeleton) do
		line.Visible = false
		line.Color = ESPSettings.SkeletonColor
		line.Thickness = ESPSettings.SkeletonThickness
		line.Transparency = ESPSettings.SkeletonTransparency
	end

	Drawings.Skeleton[OtherPlayer] = skeleton

	Drawings.ESP[OtherPlayer] = {
		Box = box,
		Tracer = tracer,
		HealthBar = healthBar,
		Info = info,
		Snapline = snapline
	}
end

local RainbowColor
local function GetPlayerColor(OtherPlayer)
	if ESPSettings.RainbowEnabled and RainbowColor then
		if ESPSettings.RainbowBoxes and ESPSettings.BoxESP then return RainbowColor:Get() end
		if ESPSettings.RainbowTracers and ESPSettings.TracerESP then return RainbowColor:Get() end
		if ESPSettings.RainbowText and (ESPSettings.NameESP or ESPSettings.HealthESP) then return RainbowColor:Get() end
	end
	local Character = OtherPlayer.Character
	return (LocalFriends[OtherPlayer] or (Character and Character:FindFirstChildWhichIsA("ForceField"))) and Colors.Ally or Colors.Enemy
end

local function GetBoxCorners(cf, size)
	local corners = {
		Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
		Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
		Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
		Vector3.new(-size.X/2, size.Y/2, size.Z/2),
		Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
		Vector3.new(size.X/2, -size.Y/2, size.Z/2),
		Vector3.new(size.X/2, size.Y/2, -size.Z/2),
		Vector3.new(size.X/2, size.Y/2, size.Z/2)
	}

	for i, corner in ipairs(corners) do
		corners[i] = cf:PointToWorldSpace(corner)
	end

	return corners
end

local function GetTracerOrigin()
	local origin = ESPSettings.TracerOrigin
	if origin == "Bottom" then
		return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
	elseif origin == "Top" then
		return Vector2.new(Camera.ViewportSize.X/2, 0)
	elseif origin == "Mouse" then
		return UserInputService:GetMouseLocation()
	else
		return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	end
end

local function RemoveESP(OtherPlayer)
	LocalFriends[OtherPlayer] = nil
	local esp = Drawings.ESP[OtherPlayer]
	if esp then
		for _, obj in pairs(esp.Box) do obj:Remove() end
		esp.Tracer:Remove()
		for _, obj in pairs(esp.HealthBar) do obj:Remove() end
		for _, obj in pairs(esp.Info) do obj:Remove() end
		esp.Snapline:Remove()
		Drawings.ESP[OtherPlayer] = nil
	end

	local highlight = Highlights[OtherPlayer]
	if highlight then
		highlight:Destroy()
		Highlights[OtherPlayer] = nil
	end

	local skeleton = Drawings.Skeleton[OtherPlayer]
	if skeleton then
		for _, line in pairs(skeleton) do
			line:Remove()
		end
		Drawings.Skeleton[OtherPlayer] = nil
	end
end

local HasRecolored, LastTime, Times = false, {}, 50
local function UpdateESP(OtherPlayer)
	if not ESPSettings.Enabled then return end

	local esp = Drawings.ESP[OtherPlayer]
	if not esp then return end

	local character = OtherPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChild("Humanoid")
	local _, isOnScreen = rootPart and Camera:WorldToViewportPoint(rootPart.Position)
	local distance = rootPart and (rootPart.Position - Camera.CFrame.Position).Magnitude
	if not character and not rootPart and not humanoid or humanoid and humanoid.Health <= 0 then 

		-- Hide all drawings if character doesn't exist
		for _, obj in pairs(esp.Box) do obj.Visible = false end
		esp.Tracer.Visible = false
		for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
		for _, obj in pairs(esp.Info) do obj.Visible = false end
		esp.Snapline.Visible = false

		local skeleton = Drawings.Skeleton[OtherPlayer]
		if skeleton then
			for _, line in pairs(skeleton) do
				line.Visible = false
			end
		end
		return
	end

    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not onScreen or distance > ESPSettings.MaxDistance or ESPSettings.TeamCheck and player.Team == LocalPlayer.Team and not ESPSettings.ShowTeam then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end

	local color = GetPlayerColor(OtherPlayer)
	local size = character:GetExtentsSize()
	local cf = rootPart.CFrame

	local top, top_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, size.Y/2, 0).Position)
	local bottom, bottom_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, -size.Y/2, 0).Position)

	if not top_onscreen or not bottom_onscreen then
		for _, obj in pairs(esp.Box) do obj.Visible = false end
		return
	end

	local screenSize = bottom.Y - top.Y
	local boxWidth = screenSize * 0.65
	local boxPosition = Vector2.new(top.X - boxWidth/2, top.Y)
	local boxSize = Vector2.new(boxWidth, screenSize)

	-- Hide all box parts by default
	for _, obj in pairs(esp.Box) do
		obj.Visible = false
	end

	if ESPSettings.BoxESP then
		if ESPSettings.BoxStyle == "ThreeD" then
			local front = {
				TL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2)).Position),
				TR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2)).Position),
				BL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)).Position),
				BR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2)).Position)
			}

			local back = {
				TL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2)).Position),
				TR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, size.Z/2)).Position),
				BL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2)).Position),
				BR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2)).Position)
			}

			if not (front.TL.Z > 0 and front.TR.Z > 0 and front.BL.Z > 0 and front.BR.Z > 0 and
				back.TL.Z > 0 and back.TR.Z > 0 and back.BL.Z > 0 and back.BR.Z > 0) then
				for _, obj in pairs(esp.Box) do obj.Visible = false end
				return
			end

			-- Convert to Vector2
			local function toVector2(v3) return Vector2.new(v3.X, v3.Y) end
			front.TL, front.TR = toVector2(front.TL), toVector2(front.TR)
			front.BL, front.BR = toVector2(front.BL), toVector2(front.BR)
			back.TL, back.TR = toVector2(back.TL), toVector2(back.TR)
			back.BL, back.BR = toVector2(back.BL), toVector2(back.BR)

			-- Front face
			esp.Box.TopLeft.From = front.TL
			esp.Box.TopLeft.To = front.TR
			esp.Box.TopLeft.Visible = true

			esp.Box.TopRight.From = front.TR
			esp.Box.TopRight.To = front.BR
			esp.Box.TopRight.Visible = true

			esp.Box.BottomLeft.From = front.BL
			esp.Box.BottomLeft.To = front.BR
			esp.Box.BottomLeft.Visible = true

			esp.Box.BottomRight.From = front.TL
			esp.Box.BottomRight.To = front.BL
			esp.Box.BottomRight.Visible = true

			-- Back face
			esp.Box.Left.From = back.TL
			esp.Box.Left.To = back.TR
			esp.Box.Left.Visible = true

			esp.Box.Right.From = back.TR
			esp.Box.Right.To = back.BR
			esp.Box.Right.Visible = true

			esp.Box.Top.From = back.BL
			esp.Box.Top.To = back.BR
			esp.Box.Top.Visible = true

			esp.Box.Bottom.From = back.TL
			esp.Box.Bottom.To = back.BL
			esp.Box.Bottom.Visible = true

			-- Connecting lines
			local function drawConnectingLine(from, to, visible)
				local line = Drawing.new("Line")
				line.Visible = visible
				line.Color = color
				line.Thickness = ESPSettings.BoxThickness
				line.From = from
				line.To = to
				return line
			end

			-- Connect front to back
			local connectors = {
				drawConnectingLine(front.TL, back.TL, true),
				drawConnectingLine(front.TR, back.TR, true),
				drawConnectingLine(front.BL, back.BL, true),
				drawConnectingLine(front.BR, back.BR, true)
			}

			-- Clean up connecting lines after frame
			task.spawn(function()
				task.wait()
				for _, line in ipairs(connectors) do
					line:Remove()
				end
			end)

		elseif ESPSettings.BoxStyle == "Corner" then
			local cornerSize = boxWidth * 0.2

			esp.Box.TopLeft.From = boxPosition
			esp.Box.TopLeft.To = boxPosition + Vector2.new(cornerSize, 0)
			esp.Box.TopLeft.Visible = true

			esp.Box.TopRight.From = boxPosition + Vector2.new(boxSize.X, 0)
			esp.Box.TopRight.To = boxPosition + Vector2.new(boxSize.X - cornerSize, 0)
			esp.Box.TopRight.Visible = true

			esp.Box.BottomLeft.From = boxPosition + Vector2.new(0, boxSize.Y)
			esp.Box.BottomLeft.To = boxPosition + Vector2.new(cornerSize, boxSize.Y)
			esp.Box.BottomLeft.Visible = true

			esp.Box.BottomRight.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
			esp.Box.BottomRight.To = boxPosition + Vector2.new(boxSize.X - cornerSize, boxSize.Y)
			esp.Box.BottomRight.Visible = true

			esp.Box.Left.From = boxPosition
			esp.Box.Left.To = boxPosition + Vector2.new(0, cornerSize)
			esp.Box.Left.Visible = true

			esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
			esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, cornerSize)
			esp.Box.Right.Visible = true

			esp.Box.Top.From = boxPosition + Vector2.new(0, boxSize.Y)
			esp.Box.Top.To = boxPosition + Vector2.new(0, boxSize.Y - cornerSize)
			esp.Box.Top.Visible = true

			esp.Box.Bottom.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
			esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y - cornerSize)
			esp.Box.Bottom.Visible = true

		else -- Full box
			esp.Box.Left.From = boxPosition
			esp.Box.Left.To = boxPosition + Vector2.new(0, boxSize.Y)
			esp.Box.Left.Visible = true

			esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
			esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
			esp.Box.Right.Visible = true

			esp.Box.Top.From = boxPosition
			esp.Box.Top.To = boxPosition + Vector2.new(boxSize.X, 0)
			esp.Box.Top.Visible = true

			esp.Box.Bottom.From = boxPosition + Vector2.new(0, boxSize.Y)
			esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
			esp.Box.Bottom.Visible = true

			esp.Box.TopLeft.Visible = false
			esp.Box.TopRight.Visible = false
			esp.Box.BottomLeft.Visible = false
			esp.Box.BottomRight.Visible = false
		end

		for _, obj in pairs(esp.Box) do
			if obj.Visible then
				obj.Color = color
				obj.Thickness = ESPSettings.BoxThickness
			end
		end
	end

	if ESPSettings.TracerESP then
		esp.Tracer.From = GetTracerOrigin()
		esp.Tracer.To = Vector2.new(pos.X, pos.Y)
		esp.Tracer.Color = color
		esp.Tracer.Visible = true
	else
		esp.Tracer.Visible = false
	end

	if ESPSettings.HealthESP then
		local health = humanoid.Health
		if ESPSettings.HealthStyle ~= "Text" then
			local maxHealth = humanoid.MaxHealth
			local healthPercent = health/maxHealth

			local barHeight = screenSize * 0.8
			local barWidth = 4
			local barPos = Vector2.new(
				boxPosition.X - barWidth - 2,
				boxPosition.Y + (screenSize - barHeight)/2
			)

			esp.HealthBar.Outline.Size = Vector2.new(barWidth, barHeight)
			esp.HealthBar.Outline.Position = barPos
			esp.HealthBar.Outline.Visible = true

			esp.HealthBar.Fill.Size = Vector2.new(barWidth - 2, barHeight * healthPercent)
			esp.HealthBar.Fill.Position = Vector2.new(barPos.X + 1, barPos.Y + barHeight * (1-healthPercent))
			esp.HealthBar.Fill.Color = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
			esp.HealthBar.Fill.Visible = true
		end

		if ESPSettings.HealthStyle == "Both" then
			esp.HealthBar.Text.Text = math.floor(health) .. ESPSettings.HealthTextSuffix
			esp.HealthBar.Text.Position = Vector2.new(barPos.X + barWidth + 2, barPos.Y + barHeight/2)
			esp.HealthBar.Text.Visible = true
		elseif ESPSettings.HealthStyle == "Text" then
			esp.HealthBar.Text.Text = math.floor(health) .. ESPSettings.HealthTextSuffix
			esp.HealthBar.Text.Position = Vector2.new(barPos.X + barWidth + 2, barPos.Y + barHeight/2)
			esp.HealthBar.Text.Visible = true
			esp.HealthBar.Outline.Visible = false
			esp.HealthBar.Fill.Visible = false
		else
			esp.HealthBar.Text.Visible = false
		end
	else
		for _, obj in pairs(esp.HealthBar) do
			obj.Visible = false
		end
	end

	if ESPSettings.NameESP then
		esp.Info.Name.Text = OtherPlayer.DisplayName
		esp.Info.Name.Position = Vector2.new(
			boxPosition.X + boxWidth/2,
			boxPosition.Y - 20
		)
		esp.Info.Name.Color = color
		esp.Info.Name.Visible = true
	else
		esp.Info.Name.Visible = false
	end

	if ESPSettings.Snaplines then
		esp.Snapline.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
		esp.Snapline.To = Vector2.new(pos.X, pos.Y)
		esp.Snapline.Color = color
		esp.Snapline.Visible = true
	else
		esp.Snapline.Visible = false
	end

	local highlight = Highlights[OtherPlayer]
	if highlight then
		if ESPSettings.ChamsEnabled and character then
			if ESPSettings.ThermalEnabled then
				HasRecolored = false
				if not LastTime[OtherPlayer] then
					LastTime[OtherPlayer] = tick()
				end

				if (tick() - LastTime[OtherPlayer]) >= 5 then
					for i = 1, Times do
						highlight.FillColor = highlight.FillColor:Lerp(Color3.fromRGB(220, 37, 0), 1/Times)
						task.wait()
					end

					LastTime[OtherPlayer] = tick()
				else
					local Times = Times / 2
					for i = 1, Times do
						highlight.FillColor = highlight.FillColor:Lerp(Color3.fromRGB(122, 19, 19), 1/Times)
						task.wait()
					end
				end

				highlight.FillTransparency = -1
			else
				highlight.FillColor = color --ESPSettings.ChamsFillColor
				highlight.FillTransparency = ESPSettings.ChamsTransparency
			end

			highlight.OutlineColor = ESPSettings.ChamsOutlineColor
			highlight.OutlineTransparency = ESPSettings.ChamsOutlineTransparency
			highlight.Enabled = true
			highlight.Parent = character
		else
			highlight.Enabled = false
		end
	else
		Highlights[OtherPlayer] = Instance.new("Highlight")
	end

	if ESPSettings.SkeletonESP then
		local function getBonePositions(character)
			if not character then return nil end

			local bones = {
				Head = character:FindFirstChild("Head"),
				UpperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
				LowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso"),
				RootPart = character:FindFirstChild("HumanoidRootPart"),

				-- Left Arm
				LeftUpperArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
				LeftLowerArm = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm"),
				LeftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"),

				-- Right Arm
				RightUpperArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
				RightLowerArm = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm"),
				RightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"),

				-- Left Leg
				LeftUpperLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
				LeftLowerLeg = character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("Left Leg"),
				LeftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"),

				-- Right Leg
				RightUpperLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
				RightLowerLeg = character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("Right Leg"),
				RightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
			}

			-- Verify we have the minimum required bones
			if not (bones.Head and bones.UpperTorso) then return nil end

			return bones
		end

		local function drawBone(from, to, line)
			if not from or not to then 
				line.Visible = false
				return 
			end

			-- Get center positions of the parts
			local fromPos = (from.CFrame * CFrame.new(0, 0, 0)).Position
			local toPos = (to.CFrame * CFrame.new(0, 0, 0)).Position

			-- Convert to screen positions with proper depth check
			local fromScreen, fromVisible = Camera:WorldToViewportPoint(fromPos)
			local toScreen, toVisible = Camera:WorldToViewportPoint(toPos)

			-- Only show if both points are visible and in front of camera
			if not (fromVisible and toVisible) or fromScreen.Z < 0 or toScreen.Z < 0 then
				line.Visible = false
				return
			end

			-- Check if points are within screen bounds
			local screenBounds = Camera.ViewportSize
			if fromScreen.X < 0 or fromScreen.X > screenBounds.X or
				fromScreen.Y < 0 or fromScreen.Y > screenBounds.Y or
				toScreen.X < 0 or toScreen.X > screenBounds.X or
				toScreen.Y < 0 or toScreen.Y > screenBounds.Y then
				line.Visible = false
				return
			end

			-- Update line with screen positions
			line.From = Vector2.new(fromScreen.X, fromScreen.Y)
			line.To = Vector2.new(toScreen.X, toScreen.Y)
			line.Color = ESPSettings.SkeletonColor
			line.Thickness = ESPSettings.SkeletonThickness
			line.Transparency = ESPSettings.SkeletonTransparency
			line.Visible = true
		end

		local bones = getBonePositions(character)
		if bones then
			local skeleton = Drawings.Skeleton[OtherPlayer]
			if skeleton then
				-- Spine & Head
				drawBone(bones.Head, bones.UpperTorso, skeleton.Head)
				drawBone(bones.UpperTorso, bones.LowerTorso, skeleton.UpperSpine)

				-- Left Arm Chain
				drawBone(bones.UpperTorso, bones.LeftUpperArm, skeleton.LeftShoulder)
				drawBone(bones.LeftUpperArm, bones.LeftLowerArm, skeleton.LeftUpperArm)
				drawBone(bones.LeftLowerArm, bones.LeftHand, skeleton.LeftLowerArm)

				-- Right Arm Chain
				drawBone(bones.UpperTorso, bones.RightUpperArm, skeleton.RightShoulder)
				drawBone(bones.RightUpperArm, bones.RightLowerArm, skeleton.RightUpperArm)
				drawBone(bones.RightLowerArm, bones.RightHand, skeleton.RightLowerArm)

				-- Left Leg Chain
				drawBone(bones.LowerTorso, bones.LeftUpperLeg, skeleton.LeftHip)
				drawBone(bones.LeftUpperLeg, bones.LeftLowerLeg, skeleton.LeftUpperLeg)
				drawBone(bones.LeftLowerLeg, bones.LeftFoot, skeleton.LeftLowerLeg)

				-- Right Leg Chain
				drawBone(bones.LowerTorso, bones.RightUpperLeg, skeleton.RightHip)
				drawBone(bones.RightUpperLeg, bones.RightLowerLeg, skeleton.RightUpperLeg)
				drawBone(bones.RightLowerLeg, bones.RightFoot, skeleton.RightLowerLeg)
			end
		end
	else
		local skeleton = Drawings.Skeleton[OtherPlayer]
		if skeleton then
			for _, line in pairs(skeleton) do
				line.Visible = false
			end
		end
	end
end

local function DisableESP()
	for Index, OtherPlayer in ipairs(Players:GetPlayers()) do
		local esp = Drawings.ESP[OtherPlayer]
		if esp then
			for _, obj in pairs(esp.Box) do obj.Visible = false end
			esp.Tracer.Visible = false
			for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
			for _, obj in pairs(esp.Info) do obj.Visible = false end
			esp.Snapline.Visible = false
		end

		-- Also hide skeleton
		local skeleton = Drawings.Skeleton[OtherPlayer]
		if skeleton then
			for _, line in pairs(skeleton) do
				line.Visible = false
			end
		end
	end
end

local function CleanupESP()
	for Index, OtherPlayer in ipairs(Players:GetPlayers()) do
		RemoveESP(OtherPlayer)
	end

	Drawings.ESP = {}
	Drawings.Skeleton = {}
	Highlights = {}
end

local function UpdateSkeletons(PropertyName, Value)
	for Index, OtherPlayer in ipairs(Players:GetPlayers()) do
		local Skeleton = Drawings.Skeleton[OtherPlayer]
		if Skeleton then
			for Index, Line in pairs(Skeleton) do
				Line[PropertyName] = Value
			end
		end
	end
end

local Vehicles = workspace:FindFirstChild("Vehicles")
local function GetVehicles()
	local VehicleList = {}
	if Vehicles then
		for Index, Vehicle in pairs(Vehicles:GetChildren()) do
			table.insert(VehicleList, Vehicle.Name)
		end
	end

	return VehicleList
end

local function GetTeleports()
	local TeleportList = {}
	if Destinations then
		for Name, CFrame in pairs(Destinations) do
			table.insert(TeleportList, Name)
		end
	end

	return TeleportList
end

local function Teleport(CFrame)
	local Backpack = Player.Backpack

	local Character = Player.Character
	if Character and not Character:FindFirstChildWhichIsA("ForceField") then
		local Humanoid = Character:FindFirstChild("Humanoid")
		if Humanoid then
			local RootPart = Character:FindFirstChild("HumanoidRootPart")
			if RootPart then
				RootPart.Anchored = true
			end

			local FistTool = Backpack and Backpack:FindFirstChild("Fist")
			if FistTool then
				Humanoid:EquipTool(FistTool)
			end

			while true do
				if not Character or not Humanoid or Character:FindFirstChild("Stunned") then
					break
				end

				CombatEvent:FireServer("Push", Humanoid)
				task.wait(0.025)
			end

			if Character then
				Character:PivotTo(CFrame)
				if RootPart then
					RootPart.Anchored = false
				end
			end
		end
	end
end

local Functions = Environment.Functions
if Functions then
	Functions:Exit()
end

local FOVCircle = Drawing.new("Circle")
local HightlightCircle = Drawing.new("Circle")
HightlightCircle.Filled = true
HightlightCircle.Radius = 6
HightlightCircle.Color = FOVSettings.LockedColor
HightlightCircle.Stroke = 0

local PepsiLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hylician/Pepsis-UI-Library/master/main.lua"))()
Environment.Unload = PepsiLibrary.unload
PepsiLibrary.configuration.hideKeybind = Enum.KeyCode.K
PepsiLibrary.flags["__Designer.Background.UseBackgroundImage"] = false

local FolderName = "Rayfield Hood"
local Window = PepsiLibrary:CreateWindow({
	Name = FolderName
})

local QuickTab = Window:CreateTab({
	Name = "Quick"
})

local QuickSection = QuickTab:CreateSection({
	Name = "Scripts",
	Side = "Left"
})

QuickSection:CreateButton({
	Name = "Infinite Yield",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
	end
})

local ESPTab = Window:CreateTab({
	Name = "ESP"
})

local MainSection = ESPTab:AddSection({
	Name = "Main ESP",
	Side = "Left"
})

local EnabledToggle = MainSection:AddToggle({
	Name = "Enable ESP",
	Flag = "ESPEnabled",
	Value = ESPSettings.Enabled,
	Callback = function(Value)
		ESPSettings.Enabled = Value
		if not Value then
			CleanupESP()
		else
			for Index, OtherPlayer in ipairs(Players:GetPlayers()) do
				if OtherPlayer ~= Player then
					CreateESP(OtherPlayer)
				end
			end
		end
	end
})

local TeamCheckToggle = MainSection:AddToggle({
	Name = "Team Check",
	Flag = "TeamCheck",
	Value = ESPSettings.TeamCheck,
	Callback = function(Value)
		ESPSettings.TeamCheck = Value
	end
})

local ShowTeamToggle = MainSection:AddToggle({
	Name = "Show Team",
	Flag = "ShowTeam",
	Value = ESPSettings.ShowTeam,
	Callback = function(Value)
		ESPSettings.ShowTeam = Value
	end
})

local BoxSection = ESPTab:AddSection({
	Name = "Box ESP",
	Side = "Left"
})

local BoxESPToggle = BoxSection:AddToggle({
	Name = "Box ESP",
	Flag = "BoxEnabled",
	Value = ESPSettings.BoxESP,
	Callback = function(Value)
		ESPSettings.BoxESP = Value
	end
})

local BoxStyleDropdown = BoxSection:AddDropdown({
	Name = "Box Style",
	List = {"Corner", "Full", "ThreeD"},
	Flag = "BoxStyle",
	Value = ESPSettings.BoxStyle,
	Callback = function(Value)
		ESPSettings.BoxStyle = Value
	end
})

local TracerSection = ESPTab:AddSection({
	Name = "Tracer ESP",
	Side = "Right"
})

local TracerESPToggle = TracerSection:AddToggle({
	Name = "Tracer ESP",
	Flag = "TracerEnabled",
	Value = ESPSettings.TracerESP,
	Callback = function(Value)
		ESPSettings.TracerESP = Value
	end
})

local SnaplinesESPToggle = TracerSection:AddToggle({
	Name = "Snaplines ESP",
	Flag = "Snaplines",
	Value = ESPSettings.Snaplines,
	Callback = function(Value)
		ESPSettings.Snaplines = Value
	end
})

local TracerOriginDropdown = TracerSection:AddDropdown({
	Name = "Tracer Origin",
	Flag = "TracerOrigin",
	List = {"Bottom", "Top", "Mouse", "Center"},
	Value = ESPSettings.TracerOrigin,
	Callback = function(Value)
		ESPSettings.TracerOrigin = Value
	end
})

local ChamsSection = ESPTab:AddSection({
	Name = "Chams",
	Side = "Right"
})

local ChamsToggle = ChamsSection:AddToggle({
	Name = "Enable Chams",
	Flag = "ChamsEnabled",
	Value = ESPSettings.ChamsEnabled,
	Callback = function(Value)
		ESPSettings.ChamsEnabled = Value
	end
})

local ThermalChams = ChamsSection:AddToggle({
	Name = "Thermal Chams",
	Flag = "ThermalEnabled",
	Value = ESPSettings.ThermalEnabled,
	Callback = function(Value)
		ESPSettings.ThermalEnabled = Value
	end
})

local ChamsFillColor = ChamsSection:AddColorpicker({
	Name = "Fill Color",
	Description = "Color for visible parts",
	Value = ESPSettings.ChamsFillColor,
	Callback = function(Value)
		ESPSettings.ChamsFillColor = Value
	end
})

local ChamsOccludedColor = ChamsSection:AddColorpicker({
	Name = "Occluded Color",
	Description = "Color for parts behind walls",
	Value = ESPSettings.ChamsOccludedColor,
	Callback = function(Value)
		ESPSettings.ChamsOccludedColor = Value
	end
})

local ChamsOutlineColor = ChamsSection:AddColorpicker({
	Name = "Outline Color",
	Description = "Color for character outline",
	Value = ESPSettings.ChamsOutlineColor,
	Callback = function(Value)
		ESPSettings.ChamsOutlineColor = Value
	end
})

local ChamsTransparency = ChamsSection:AddSlider({
	Name = "Fill Transparency",
	Description = "Transparency of the fill color",
	Value = ESPSettings.ChamsTransparency,
	Min = 0,
	Max = 1,
	Decimals = 2,
	Callback = function(Value)
		ESPSettings.ChamsTransparency = Value
	end
})

local ChamsOutlineTransparency = ChamsSection:AddSlider({
	Name = "Outline Transparency",
	Description = "Transparency of the outline",
	Value = ESPSettings.ChamsOutlineTransparency,
	Min = 0,
	Max = 1,
	Decimals = 2,
	Callback = function(Value)
		ESPSettings.ChamsOutlineTransparency = Value
	end
})

local ChamsOutlineThickness = ChamsSection:AddSlider({
	Name = "Outline Thickness",
	Description = "Thickness of the outline",
	Value = ESPSettings.ChamsOutlineThickness,
	Min = 0,
	Max = 1,
	Decimals = 2,
	Callback = function(Value)
		ESPSettings.ChamsOutlineThickness = Value
	end
})

local HealthSection = ESPTab:AddSection({
	Name = "Health ESP",
	Side = "Left"
})

local HealthESPToggle = HealthSection:AddToggle({
	Name = "Health Bar",
	Flag = "HealthEnabled",
	Value = ESPSettings.HealthESP,
	Callback = function(Value)
		ESPSettings.HealthESP = Value
	end
})

local HealthStyleDropdown = HealthSection:AddDropdown({
	Name = "Health Style",
	List = {"Bar", "Text", "Both"},
	Flag = "HealthStyle",
	Value = ESPSettings.HealthStyle,
	Callback = function(Value)
		ESPSettings.HealthStyle = Value
	end
})

local SkeletonSection = ESPTab:AddSection({
	Name = "Skeleton ESP",
	Side = "Right"
})

local SkeletonESPToggle = SkeletonSection:AddToggle({
	Name = "Skeleton ESP",
	Flag = "SkeletonEnabled",
	Value = ESPSettings.SkeletonESP,
	Callback = function(Value)
		ESPSettings.SkeletonESP = Value
	end
})

local SkeletonColor = SkeletonSection:AddColorpicker({
	Name = "Skeleton Color",
	Flag = "SkeletonColor",
	Value = ESPSettings.SkeletonColor,
	Callback = function(Value)
		ESPSettings.SkeletonColor = Value
		UpdateSkeletons("Color", Value)
	end
})

local SkeletonThickness = SkeletonSection:AddSlider({
	Name = "Line Thickness",
	Flag = "SkeletonThickness",
	Value = ESPSettings.SkeletonThickness,
	Min = 1,
	Max = 3,
	Decimals = 1,
	Callback = function(Value)
		ESPSettings.SkeletonThickness = Value
		UpdateSkeletons("Thickness", Value)
	end
})

local SkeletonTransparency = SkeletonSection:AddSlider({
	Name = "Transparency",
	Flag = "SkeletonTransparency",
	Value = ESPSettings.SkeletonTransparency,
	Min = 0,
	Max = 1,
	Decimals = 2,
	Callback = function(Value)
		ESPSettings.SkeletonTransparency = Value
		UpdateSkeletons("Transparency", Value)
	end
})

local BoxSection = ESPTab:AddSection({
	Name = "Box Settings",
	Side = "Left"
})

local BoxThickness = BoxSection:AddSlider({
	Name = "Box Thickness",
	Flag = "BoxThickness",
	Value = ESPSettings.BoxThickness,
	Min = 1,
	Max = 5,
	Decimals = 1,
	Callback = function(Value)
		ESPSettings.BoxThickness = Value
	end
})

local BoxTransparency = BoxSection:AddSlider({
	Name = "Box Transparency",
	Flag = "BoxFillTransparency",
	Value = ESPSettings.BoxFillTransparency,
	Min = 0,
	Max = 1,
	Decimals = 2,
	Callback = function(Value)
		ESPSettings.BoxFillTransparency = Value
	end
})

local ESPSection = ESPTab:AddSection({
	Name = "ESP Settings",
	Side = "Left"
})

local MaxDistance = ESPSection:AddSlider({
	Name = "Max Distance",
	Flag = "ESPMaxDistance",
	Value = ESPSettings.MaxDistance,
	Min = 100,
	Max = 5000,
	Callback = function(Value)
		ESPSettings.MaxDistance = Value
	end
})

local TextSize = ESPSection:AddSlider({
	Name = "Text Size",
	Value = ESPSettings.TextSize,
	Min = 10,
	Max = 24,
	Callback = function(Value)
		ESPSettings.TextSize = Value
	end
})

local HealthTextFormat = ESPSection:AddDropdown({
	Name = "Health Format",
	List = {"Number", "Percentage", "Both"},
	Flag = "HealthTextFormat",
	Value = ESPSettings.HealthTextFormat,
	Callback = function(Value)
		ESPSettings.HealthTextFormat = Value
	end
})

local ColorsSection = ESPTab:AddSection({
	Name = "Colors",
	Side = "Left"
})

local EnemyColor = ColorsSection:AddColorpicker({
	Name = "Enemy Color",
	Description = "Color for enemy players",
	Flag = "EnemyColor",
	Value = Colors.Enemy,
	Callback = function(Value)
		Colors.Enemy = Value
	end
})

local AllyColor = ColorsSection:AddColorpicker({
	Name = "Ally Color",
	Description = "Color for team members",
	Flag = "AllyColor",
	Value = Colors.Ally,
	Callback = function(Value)
		Colors.Ally = Value
	end
})

local HealthColor = ColorsSection:AddColorpicker({
	Name = "Health Bar Color",
	Description = "Color for full health",
	Flag = "HealthBarColor",
	Value = Colors.Health,
	Callback = function(Value)
		Colors.Health = Value
	end
})

local EffectsSection = ESPTab:AddSection({
	Name = "Effects",
	Side = "Left"
})

local RainbowToggle = EffectsSection:AddToggle({
	Name = "Rainbow Mode",
	Flag = "RainbowEnabled",
	Value = ESPSettings.RainbowEnabled,
	Callback = function(Value)
		ESPSettings.RainbowEnabled = Value
	end
})

RainbowColor = EffectsSection:CreateColorpicker({
	Name = "Rainbow Color",
	Rainbow = true
})

local RainbowOptions = EffectsSection:AddDropdown({
	Name = "Rainbow Parts",
	List = {"All", "Box Only", "Tracers Only", "Text Only"},
	Value = "All",
	Multi = false,
	Callback = function(Value)
		if Value == "All" then
			ESPSettings.RainbowBoxes = true
			ESPSettings.RainbowTracers = true
			ESPSettings.RainbowText = true
		elseif Value == "Box Only" then
			ESPSettings.RainbowBoxes = true
			ESPSettings.RainbowTracers = false
			ESPSettings.RainbowText = false
		elseif Value == "Tracers Only" then
			ESPSettings.RainbowBoxes = false
			ESPSettings.RainbowTracers = true
			ESPSettings.RainbowText = false
		elseif Value == "Text Only" then
			ESPSettings.RainbowBoxes = false
			ESPSettings.RainbowTracers = false
			ESPSettings.RainbowText = true
		end
	end
})

local PerformanceSection = ESPTab:AddSection({
	Name = "Performance",
	Side = "Right"
})

local RefreshRate = PerformanceSection:AddSlider({
	Name = "Refresh Rate",
	Value = 144,
	Min = 1,
	Max = 144,
	Callback = function(Value)
		ESPSettings.RefreshRate = 1/Value
	end
})

local AimbotTab = Window:CreateTab({
	Name = "Aimbot"
})

local LeftAimbotSection = AimbotTab:CreateSection({
	Name = "Aimbot",
	Side = "Left"
})

local PersistenceProfileName = "Default"
local PersistenceFilePath = "./Pepsi Lib/" .. FolderName .. "/" .. PersistenceProfileName .. ".txt"

local AppPersistence = LeftAimbotSection:AddPersistence({
	Name = "ESP Persist",
	Workspace = FolderName,
	Value = PersistenceProfileName,
	Suffix = "Config",
	HideLoadButton = true
})

local RightAimbotSection = AimbotTab:CreateSection({
	Name = "Aimbot",
	Side = "Right"
})

LeftAimbotSection:CreateToggle({
	Name = "Aimbot Enabled",
	Flag = "AimbotEnabled",
	Value = AimbotSettings.Enabled,
	Callback = function(Value)
		AimbotSettings.Enabled = Value
	end
})

LeftAimbotSection:CreateToggle({
	Name = "Forcefield Check",
	Value = AimbotSettings.FFCheck,
	Callback = function(Value)
		AimbotSettings.FFCheck = Value
	end
})

LeftAimbotSection:CreateToggle({
	Name = "Always Active",
	Value = AimbotSettings.AlwaysActive,
	Callback = function(Value)
		AimbotSettings.AlwaysActive = Value
	end
})

LeftAimbotSection:CreateToggle({
	Name = "Team Check",
	Value = AimbotSettings.TeamCheck,
	Callback = function(Value)
		AimbotSettings.TeamCheck = Value
	end
})

LeftAimbotSection:CreateToggle({
	Name = "Ally Check",
	Value = AimbotSettings.AllyCheck,
	Callback = function(Value)
		AimbotSettings.AllyCheck = Value
	end
})

LeftAimbotSection:CreateToggle({
	Name = "Alive Check",
	Value = AimbotSettings.AliveCheck,
	Callback = function(Value)
		AimbotSettings.AliveCheck = Value
	end
})

LeftAimbotSection:CreateToggle({
	Name = "Wall Check",
	Value = AimbotSettings.WallCheck,
	Callback = function(Value)
		AimbotSettings.WallCheck = Value
	end
})

LeftAimbotSection:CreateTextBox({
	Name = "Trigger Key",
	Flag = "AimbotTriggerKey",
	Value = AimbotSettings.TriggerKey,
	Placeholder = AimbotSettings.TriggerKey,
	Callback = function(Value)
		AimbotSettings.TriggerKey = Value
	end
})

LeftAimbotSection:CreateTextBox({
	Name = "Lock Part",
	Flag = "LockPart",
	Value = AimbotSettings.LockPart,
	Placeholder = AimbotSettings.LockPart,
	Callback = function(Value)
		AimbotSettings.LockPart = Value
	end
})

local FOVAmount = RightAimbotSection:CreateSlider({
	Name = "FOV Amount",
	Flag = "FOV",
	Min = 1,
	Max = 180,
	Value = FOVSettings.Amount
})

RightAimbotSection:CreateSlider({
	Name = "FOV Transparency",
	Flag = "FOVTransparency",
	Min = 0,
	Max = 1,
	Decimals = 1,
	Value = FOVSettings.Transparency,
	Callback = function(Value)
		FOVSettings.Transparency = Value
	end
})

RightAimbotSection:CreateSlider({
	Name = "FOV Sides",
	Flag = "FOVSides",
	Min = 2,
	Max = 30,
	Value = FOVSettings.Sides,
	Callback = function(Value)
		FOVSettings.Sides = Value
	end
})

RightAimbotSection:CreateSlider({
	Name = "FOV Thickness",
	Flag = "FOVThickness",
	Min = 0.1,
	Max = 3,
	Decimals = 1,
	Value = FOVSettings.Thickness,
	Callback = function(Value)
		FOVSettings.Thickness = Value
	end
})

local FOVColor = RightAimbotSection:CreateColorpicker({
	Name = "FOV Color",
	Flag = "FOVColor",
	Value = FOVSettings.Color,
	Callback = function(Value)
		FOVSettings.Color = Value
	end
})

local LockedFOVColor = RightAimbotSection:CreateColorpicker({
	Name = "Locked FOV Color",
	Flag = "LockedFOVColor",
	Value = FOVSettings.LockedColor,
	Callback = function(Value)
		FOVSettings.LockedColor = Value
	end
})

local SelectedVehicle = nil
local SpecificTab = Window:CreateTab({
	Name = "Game Specific"
})

local LeftSpecificSection = SpecificTab:CreateSection({
	Name = "Specific",
	Side = "Left"
})

local RightSpecificSection = SpecificTab:CreateSection({
	Name = "Specific",
	Side = "Right"
})

local VehicleDropdown = LeftSpecificSection:CreateDropdown({
	Name = "Select Vehicle",
	List = GetVehicles(),
	CurrentOption = {},
	Callback = function(Option)
		SelectedVehicle = Option
	end
})

LeftSpecificSection:CreateButton({
	Name = "Steal Vehicle",
	Callback = function()
		if SelectedVehicle then
			local Character = Player.Character
			local Backpack = Player:WaitForChild("Backpack")
			local BackpackPad = Backpack:FindFirstChild("ProPad")
			if Character and (BackpackPad or Character:FindFirstChild("ProPad")) then
				local Humanoid = Character:FindFirstChild("Humanoid")
				if Humanoid and BackpackPad then
					Humanoid:EquipTool(BackpackPad)
				end

				task.delay(0.1, function()
					ProPadEvent:FireServer(Vehicles:FindFirstChild(SelectedVehicle), true)
				end)
			else
				PepsiLibrary:Notify({
					Text = "Error: Please purchase a ProPad!",
					Time = 4
				})
			end
		else
			PepsiLibrary:Notify({
				Text = "Error: Select a vehicle first!",
				Time = 4
			})
		end
	end
})

local InfiniteStamina = LeftSpecificSection:CreateToggle({
	Name = "Infinite Stamina",
	Value = true
})

local SelectedTP = nil
local TeleportDropdown = RightSpecificSection:CreateDropdown({
	Name = "Select Teleport",
	List = GetTeleports(),
	CurrentOption = {},
	Callback = function(Option)
		SelectedTP = Option
	end
})

RightSpecificSection:CreateButton({
	Name = "Teleport",
	Callback = function()
		if SelectedTP then
			local SelectedTP = Destinations[SelectedTP]
			if SelectedTP then
				Teleport(SelectedTP)
			end
		else
			PepsiLibrary:Notify({
				Text = "Error: Select a teleport first!",
				Time = 4
			})
		end
	end
})

Window:CreateDesigner()
local function UpdateVehicleDropdown()
	VehicleDropdown:UpdateList(GetVehicles())
end

local function SaveSettings()
	AppPersistence:SaveFile(PersistenceProfileName)
end

local function getClosestPlayer()
	local Location = UserInputService:GetMouseLocation()
	local ClosestDistance, ClosestPart, ScreenPosition = FOVSettings.Enabled and FOVAmount:Get() or 2000, nil, nil
	for Index, OtherPlayer in ipairs(Players:GetPlayers()) do
		if OtherPlayer ~= Player then
			local OtherCharacter = OtherPlayer.Character
			if OtherCharacter then
				if AimbotSettings.FFCheck and OtherCharacter:FindFirstChildWhichIsA("ForceField") then
					continue
				end

				if AimbotSettings.TeamCheck and OtherPlayer.Team == Player.Team then
					continue
				end

				if AimbotSettings.AllyCheck and LocalFriends[OtherPlayer] then
					continue
				end

				local Humanoid = OtherCharacter:FindFirstChildWhichIsA("Humanoid")
				if AimbotSettings.AliveCheck and Humanoid and Humanoid.Health <= 0 then
					continue
				end

				local LockPart = OtherCharacter[AimbotSettings.LockPart]
				if AimbotSettings.WallCheck and LockPart and #(Camera:GetPartsObscuringTarget({LockPart.Position}, OtherCharacter:GetDescendants())) > 0 then
					continue
				end

				if LockPart then
					local ScreenPos, IsOnScreen = Camera:WorldToViewportPoint(LockPart.Position)
					if IsOnScreen then
						local ScreenPoint = Vector2.new(ScreenPos.X, ScreenPos.Y)
						local Distance = (ScreenPoint - Location).Magnitude
						if Distance < ClosestDistance then
							ClosestDistance, ClosestPart, ScreenPosition = Distance, LockPart, ScreenPoint
						end
					end
				end
			end
		end
	end

	return ClosestPart, ScreenPosition
end

local Running = false
local function Load()
	local Success, Projectile = pcall(require, ProjectileModule)
	if Success then
		newProjectile = hookfunction(Projectile.new, newcclosure(function(Parameters)
			if Parameters and Parameters.Origin and Parameters.Direction and Running or AimbotSettings.AlwaysActive then
				local ClosestPart = getClosestPlayer()
				if ClosestPart then
					Parameters.Direction = (ClosestPart.Position - Parameters.Origin).Unit
				end
			end

			return newProjectile(Parameters)
		end))
	end

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input, gameProcessedEvent)
		if not gameProcessedEvent and FOVCircle then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[AimbotSettings.TriggerKey] then
					if AimbotSettings.Toggle then
						Running = not Running
						if not Running then
							FOVCircle.Color = FOVColor:Get()
						end
					else
						Running = true
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[AimbotSettings.TriggerKey] then
					if AimbotSettings.Toggle then
						Running = not Running
						if not Running then
							FOVCircle.Color = FOVColor:Get()
						end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input, gameProcessedEvent)
		if not gameProcessedEvent and FOVCircle then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[AimbotSettings.TriggerKey] then
					if not AimbotSettings.Toggle then
						Running = false
						FOVCircle.Color = FOVColor:Get()
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[AimbotSettings.TriggerKey] then
					if not AimbotSettings.Toggle then
						Running = false
						FOVCircle.Color = FOVColor:Get()
					end
				end
			end)
		end
	end)
end

local Functions = {}
function Functions:Exit()
	for Index, Connection in pairs(ServiceConnections) do
		Connection:Disconnect()
	end

	local UnloadFunction = Environment.Unload
	if UnloadFunction then
		UnloadFunction()
	end

	Drawings = nil
	cleardrawcache()
	ESPSettings = nil
	AimbotSettings = nil
	FOVSettings = nil
	for k, v in pairs(getfenv(1)) do
		getfenv(1)[k] = nil
	end
end

Environment.Functions = Functions

do
	pcall(function()
		if Drawing and getgenv then
			task.spawn(Load)
		else
			PepsiLibrary:Notify({
				Text = "Aimbot: Your exploit does not support this script",
				Time = 3
			})
		end
	end)
end

do
	if isfile and isfile(PersistenceFilePath) then
		AppPersistence:LoadFile(PersistenceProfileName)
	else
		SaveSettings()
	end
end

do
	for Index, OtherPlayer in ipairs(Players:GetPlayers()) do
		if OtherPlayer ~= Player then
			task.spawn(CreateESP, OtherPlayer)
		end
	end

	local LastUpdate = 0
	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		if FOVCircle then
			local MouseLocation = UserInputService:GetMouseLocation()
			if FOVSettings.Enabled and AimbotSettings.Enabled then
				FOVCircle.Radius = FOVAmount:Get()
				FOVCircle.Thickness = FOVSettings.Thickness
				FOVCircle.Filled = FOVSettings.Filled
				FOVCircle.NumSides = FOVSettings.Sides
				FOVCircle.Color = FOVColor:Get()
				FOVCircle.Transparency = FOVSettings.Transparency
				FOVCircle.Visible = FOVSettings.Visible
				FOVCircle.Position = Vector2.new(MouseLocation.X, MouseLocation.Y)
			else
				FOVCircle.Visible = false
			end

			local ClosestPart, ScreenPosition = getClosestPlayer()
			if not ClosestPart then
				HightlightCircle.Visible = false
			end

			if (Running or AimbotSettings.AlwaysActive) and AimbotSettings.Enabled then
				if ClosestPart and ScreenPosition then
					HightlightCircle.Visible = true
					HightlightCircle.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
				end

				FOVCircle.Color = LockedFOVColor:Get()
			end
		end

		if not ESPSettings.Enabled then 
			DisableESP()
			return 
		end

		local CurrentTime = tick()
		if CurrentTime - LastUpdate >= ESPSettings.RefreshRate then
			for Index, OtherPlayer in ipairs(Players:GetPlayers()) do
				if OtherPlayer ~= Player then
					if not Drawings.ESP[OtherPlayer] then
						task.spawn(CreateESP, OtherPlayer)
					end

					task.spawn(UpdateESP, OtherPlayer)
				end
			end

			LastUpdate = CurrentTime
		end
	end)

	ServiceConnections.ESPPlayerAdded = Players.PlayerAdded:Connect(CreateESP)
	ServiceConnections.ESPPlayerRemoving = Players.PlayerRemoving:Connect(RemoveESP)
end

local MaxStamina = 100
do
	local __namecall
	__namecall = hookmetamethod(game, "__namecall", function(self, ...)
		if InfiniteStamina:Get() and self == Player.Character and getnamecallmethod() == "GetAttribute" and ({...})[1] == "Stamina" then
			return MaxStamina
		end

		return __namecall(self, ...)
	end)
end

do
	if Vehicles then
		ServiceConnections.VehicleAdded = Vehicles.ChildAdded:Connect(UpdateVehicleDropdown)
		ServiceConnections.VehicleRemoved = Vehicles.ChildRemoved:Connect(UpdateVehicleDropdown)
	end
end
