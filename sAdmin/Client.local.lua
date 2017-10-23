--@author: Logan H. [fq_d]
--@date: 10.22.2017
--@optimizations
local game = game
local Instance = Instance
local assert = assert
local spawn = spawn
local UDim2 = UDim2
local wait = wait
local Color3 = Color3
local script = script
local require = require
local pairs, ipairs = pairs, ipairs
local tostring, tonumber = tostring, tonumber
local type = type
local table, math = table, math
local unpack, select = unpack, select
--@services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--@main
local Create = LoadLibrary("RbxUtility").Create --ewwwww
local RenderStepped = RunService.RenderStepped
local Transmission = ReplicatedStorage:WaitForChild("Transmission")
local EventTransmitter, InvokeTransmitter = Transmission:WaitForChild("EventTransmitter"), Transmission:WaitForChild("InvokeTransmitter")
local Modules = script:WaitForChild("Modules"):GetChildren()
local ScreenGui = Instance.new("ScreenGui") ScreenGui.Name = "AdminGui" ScreenGui.Parent = script.Parent
local BaseMessage = script:WaitForChild("MessageFrame")
local BaseHint = script:WaitForChild("HintFrame")
local BaseList = script:WaitForChild("ListFrame")
local BasePrompt = script:WaitForChild("PromptFrame")

local function GetAllDescendants(inst)
	local selection = { }
	for i, v in pairs(inst:GetChildren()) do
		selection[#selection + 1] = v
		for i, v in pairs(GetAllDescendants(v)) do
			selection[#selection + 1] = v
		end
	end
	return selection
end
