--@author: Logan H. [fq_d]
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
				Commands:WrapCommand(v)
			end
		end
		for _, module in pairs(Settings.ExternalModules) do
			for i, v in next, require(module)(self) do
				self.Commands[#self.Commands + 1] = tostring(i) .. " " .. table.concat(v.Parameters, " ")
				Commands:WrapCommand(v)
			end
		end
	end,
	TransmitSignal = function(self, plrs, port, async, onReceive, ...)
		if plrs == "all" and async == true then
			EventTransmitter:FireAllClients(port, ...)
			return
		end
		for i, v in pairs(plrs) do
			if async == true and onReceive == nil then
				InvokeTransmitter:InvokeClient(v, port, ...)
			elseif async == false and onReceive == nil then
				InvokeTransmitter:InvokeClient(v, port, ...)
			elseif async == true and onReceive ~= nil then
				coroutine.wrap(function(...)
					onReceive(v, InvokeTransmitter:InvokeClient(v, port, ...))
				end)(...)
			elseif async == false and onReceive ~= nil then
				onReceive(v, InvokeTransmitter:InvokeClient(v, port, ...))
			end
		end
	end,
	AdminRanks = {
		["Player"] = 0,
		["Temporary Admin"] = 1,
		["Admin"] = 3,
		["Head Admin"] = 4,
		["Owner"] = 5,
		FindByRank = function(self, rank)
			for i, v in pairs(self) do
				if v == rank then
					return i
				end
			end
		end
	},
	ValidateAdmin = function(self, plr)
		if not self.Admins[plr.UserId] then
			local highestRank = 0
			for i, v in pairs(Settings.GroupAdmin) do
				if plr:GetRankInGroup(v.Group) >= v.GroupRank and self.AdminRanks[v.AdminRank] > highestRank then
					highestRank = self.AdminRanks[v.AdminRank]
				end
			end
			for i, v in pairs(Settings.StaticAdmins) do
				if plr.Name:lower() == (type(i) == "string" and i:lower() or "") or plr.UserId == i then
					if self.AdminRanks[v] > highestRank then
						highestRank = self.AdminRanks[v]
					end
				end
			end
			if highestRank > 0 then
				self.Admins[plr.UserId] = {
					Name = plr.Name,
					Rank = highestRank
				}
			end
		end
	end,
	
	SetAdmin = function(self, plr, rank)
		if type(rank) == "string" then
			self.Admins[plr.UserId] = self.AdminRanks[rank]
		elseif type(rank) == "number" then
			self.Admins[plr.UserId] = rank
		end
	end,
	
	Serverlock = false,
	Logs = { },
	Admins = { },
	Banned = { },
	Transmitters = { },
	
	GeneratedItems = {
		Add = table.insert,
		Wipe = function(self)
			for i, v in ipairs(self) do
				self[i] = nil
			end
		end
	}
}

Commands = {
	List = { },
	Get = function(self, command)
		return self.List[command and command:lower() or 0]
	end,
	FormatArguments = function(self, plr, commandObj, fields)
		local plrs = String:ParseTargetPlayers(plr, unpack(fields))
		local args = { }
		for i, v in pairs(commandObj.Parameters) do
			self.ParemeterHandlers[v](i, plrs, fields, args)
		end
		return unpack(args)
	end,
	
	ParemeterHandlers = {
		["plr"] = function(i, plrs, fields, args)
			args[i] = plrs[i]
		end,
		
		["str"] = function(i, plrs, fields, args)
			args[i] = fields[i]:match("%s*(%S+)%s*")
		end,
		
		["str..."] = function(i, plrs, fields, args)
			for i = i, #fields do
				args[i] = fields[i]:match("%s*(%S+)%s*")
			end
		end,
		
		["str,"] = function(i, plrs, fields, args)
			local str
			local li = {}
			for i = i, #fields do
				str = str and str .. fields[i] or fields[i]
			end
			for v in str:gmatch("[^,]+") do
				li[#li + 1] = v:match("%s*(%S+)%s*")
			end
			args[i] = li
		end,
		
		["str+"] = function(i, plrs, fields, args)
			local str
			for i = i, #fields do
				str = str and str .. fields[i] or fields[i]
			end
			args[i] = str
		end,
		
		["int"] = function(i, plrs, fields, args)
			args[i] = tonumber(fields[i])
		end,
		
		["int..."] = function(i, plr, fields, args)
			for i = i, #fields do
				args[i] = tonumber(fields[i])
			end
		end
	},
	
	WrapCommand = function(self, traits)
		for i, v in pairs(traits.Names) do
			self.List[v:lower()] = traits
		end
	end,
}

String = {	
	ParseTargetPlayers = function(self, selfPlr, ...)
		local results = { }
		local v
		for i = 1, select("#", ...) do
			v = select(i, ...)
			local group = { }
			local catch = { }
			for v in v:gmatch("[^%s,]+") do
				group[#group + 1] = v
			end
			for i, v in pairs(group) do
				local manipulatorStr, manipulator = ""
				for k, f in pairs(self.Search.BehaviorManipulators) do
					if v:match("^" .. k) then
						manipulatorStr, manipulator = k, f
						break
					end
				end
				local command, behavior, players = v:match("^" .. manipulatorStr .. "(.+)")
				if manipulator then
					behavior, players = manipulator(selfPlr, v, "^" .. manipulatorStr .. "(.*)")
				else
					behavior, players = self.Search.BehaviorManipulators[0](selfPlr, v)
				end

				for i, v in next, self.Search.BehaviorModes[behavior](players) do
					catch[i] = v
				end
			end
			local result = { }
			for i, v in pairs(catch) do
				if v == true then
					result[#result + 1] = i
				end
			end
			results[#results + 1] = result
		end
		return results
	end,
	Search = {
		Keywords = {
			["all"] = function() return Players:GetPlayers() end,
			["me"] = function(selfPlr) return { selfPlr } end,
			["random"] = function()
				local plrs = Players:GetPlayers()
				return { plrs[math.random(1, #plrs)] }
			end,
			["admins"] = function()
				local plrs = Players:GetPlayers()
				for i, v in pairs(plrs) do
					if Admin.Admins[v.Name] == nil or Admin.Admins[v.UserId] == nil or Admin.Admins[v.Name].Rank <= 0 or Admin.Admins[v.UserId].Rank <= 0 then
						table.remove(plrs, i)
					end
				end
				return plrs
			end,
			["nonadmins"] = function()
				local plrs = Players:GetPlayers()
				for i, v in pairs(plrs) do
					if (Admin.Admins[v.Name] and Admin.Admins[v.Name].Rank > 0) or (Admin.Admins[v.UserId] and Admin.Admins[v.UserId].Rank > 0) then
						table.remove(plrs, i)
					end
				end
				return plrs
			end,
			["guests"] = function()
				local plrs = Players:GetPlayers()
				for i, v in pairs(plrs) do
					if v.UserId > 0 then
						table.remove(plrs, i)
					end
				end
				return plrs
			end,
			["others"] = function(selfPlr)
				local plrs = Players:GetPlayers()
				for i, v in pairs(plrs) do
					if v == selfPlr then
						table.remove(plrs, i)
					end
				end
				return plrs
			end,
			["random%-(%d+)"] = function(selfPlr, num)
				local plrs, selection = Players:GetPlayers(), { }
				local num = tonumber(num)
				if #plrs > num then return plrs end
				local i = 0
				while #selection < num do
					i = i + 1
					if math.random(0, 1) == 1 then
						selection[i] = plrs[i % #plrs + 1]
					end
				end
				return { plrs[math.random(1, #plrs)] }
			end,
			["team%-(%w+)"] = function(selfPlr, name)
				local results = { }
				local team
				local pattern = "^" .. name
				for i, v in pairs(Teams:GetChildren()) do
					if v.Name:lower():match(pattern) then
						team = v
						for i, v in pairs(Players:GetPlayers()) do
							if v.TeamColor == team.TeamColor then
								results[#results + 1] = v
							end
						end
						break
					end
				end
				return results
			end,
			["group%-(%d+)"] = function(selfPlr, id)
				local results = { }
				local id = tonumber(id)
				if id then
					for i, v in pairs(Players:GetPlayers()) do
						if v:IsInGroup(id) then
							results[#results + 1] = v
						end
					end
				end
				return results
			end,
			["nbcs"] = function()
				local results = { }
				local plrs = Players:GetPlayers()
				for i, v in pairs(plrs) do
					if v.MembershipType == Enum.MembershipType.None then
						results[#results + 1] = v
					end
				end
				return results
			end,
			["bcs"] = function()
				local results = { }
				local plrs = Players:GetPlayers()
				for i, v in pairs(plrs) do
					if v.MembershipType == Enum.MembershipType.BuildersClub then
						results[#results + 1] = v
					end
				end
				return results
			end,
			["tbcs"] = function()
				local results = { }
				local plrs = Players:GetPlayers()
				for i, v in pairs(plrs) do
					if v.MembershipType == Enum.MembershipType.TurboBuildersClub then
						results[#results + 1] = v
					end
				end
				return results
			end,
			["obcs"] = function()
				local results = { }
				local plrs = Players:GetPlayers()
				for i, v in pairs(plrs) do
					if v.MembershipType == Enum.MembershipType.OutrageousBuildersClub then
						results[#results + 1] = v
					end
				end
				return results
			end,
		},
		BehaviorManipulators = {
			[0] = function(selfPlr, str, pattern)
				return "add", String.Search:Players(selfPlr, str, pattern)
			end,
			["!"] = function(selfPlr, str, pattern)
				return "prevent", String.Search:Players(selfPlr, str, pattern)
			end,
			["except%-"] = function(selfPlr, str, pattern)
				return "prevent", String.Search:Players(selfPlr, str, pattern)
			end
		},
		
		BehaviorModes = {
			["add"] = function(list)
				local result = { }
				for i, v in pairs(list) do
					if result[v] ~= false then
						result[v] = true
					end
				end
				return result
			end,
			
			["prevent"] = function(list)
				local result = { }
				for i, v in pairs(list) do
					result[v] = false
				end
				return result
			end
		},
		
		Players = function(self, selfPlr, str, pattern)
			local results = { }
			local str = pattern and str:match(pattern) or str
			for i, v in pairs(self.Keywords) do
				local capt = str:match("^" .. i .. "$")
				if capt then
					return v(selfPlr, capt)
				end
			end
			for i, v in pairs(Players:GetPlayers()) do
				if v.Name:lower():match("^" .. str) then
					results[#results + 1] = v
					return results
				end
			end
			return results
		end,
	}
}

local function Chatted(plr, msg)
	local command = msg:match("^" .. Settings.Prefix .. "(%w+)")
	if command then
		local fields = msg:match(command .. "%s+(.+)")
		command = Commands:Get(command)
		if command and (Admin.Admins[plr.UserId] and Admin.Admins[plr.UserId].Rank or 0) >= Admin.AdminRanks[command.Rank] then
			if fields then
				local breakPoints = { }
				local lastFBegin, lastFEnd, fBegin, fEnd = 0, 0, 0, 1
				while fEnd ~= nil and lastFEnd ~= nil do
					fBegin, fEnd = fields:find("[^,]?%s", fEnd + 1)
					local field = fields:sub(lastFEnd, fEnd):match("^%s*(%S+)%s*$")
					if field and field:match(",$") == nil and fEnd ~= #fields then
						breakPoints[#breakPoints + 1] = fEnd
					end
					lastFBegin, lastFEnd = fBegin, fEnd
				end
				breakPoints[#breakPoints + 1] = #fields
				local fieldList = { }
				local pointer = 1
				for i, v in pairs(breakPoints) do
					fieldList[i] = fields:sub(pointer, v)
					pointer = v + 1
				end
				command.Fire(plr, Commands:FormatArguments(plr, command, fieldList))
				if not msg:lower():match("logs") then
					Admin.Logs[#Admin.Logs + 1] = { plr, msg }
				end
			elseif command.OnInvalidParams then
				command.OnInvalidParams(plr)
			elseif #command.Parameters == 0 then
				command.Fire(plr)
				if not msg:lower():match("logs") then
					Admin.Logs[#Admin.Logs + 1] = { plr, msg }
				end
			end
		elseif command then
			Admin:TransmitSignal({ plr }, "ShowHint", false, nil, "You are not permitted to run this command.", 1.5)
		end
	end
end

local function PlayerAdded(plr)
	Admin:ValidateAdmin(plr)
	if (Admin.Serverlock == true and (Admin.Admins[plr.UserId].Rank or 0) <= 150) or Admin.Banned[plr.UserId] ~= nil then
		plr:Kick()
	end
	plr.Chatted:connect(function(msg)
		Chatted(plr, msg)
	end)
end

for i, v in pairs(Players:GetPlayers()) do
	PlayerAdded(v)
end

Players.PlayerAdded:connect(PlayerAdded)
Admin:ImportCommands()
