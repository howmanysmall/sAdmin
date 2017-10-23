--@author: Logan [fq_d]
--@date: 10.22.2017
--@optimizations
local game = game
local script = script
local require = require
local coroutine = coroutine
local pairs, ipairs, next = pairs, ipairs, next
local tostring, tonumber = tostring, tonumber
local type = type
local table, math = table, math
local unpack, select = unpack, select
--@services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--@main
local Client = script:WaitForChild("Client")
Client:Clone().Parent = StarterGui
local Transmission = script:WaitForChild("Transmission"):Clone()
Transmission.Parent = ReplicatedStorage
local EventTransmitter, InvokeTransmitter = Transmission:WaitForChild("EventTransmitter"), Transmission:WaitForChild("InvokeTransmitter")
local Settings = require(script:WaitForChild("Settings"))
local Admin, Commands, String
local CommandsFolder = script:WaitForChild("Commands")

Admin = {
	Commands = { },
	ImportCommands = function(self)
		for _, module in pairs(CommandsFolder:GetChildren()) do
			for i, v in next, require(module)(self) do
				self.Commands[#self.Commands + 1] = tostring(i) .. " " .. table.concat(v.Parameters, " ")
