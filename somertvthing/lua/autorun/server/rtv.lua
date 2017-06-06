AddCSLuaFile("autorun/client/cl_rtv.lua")
util.AddNetworkString( "MapsHook" )
util.AddNetworkString( "MapsHook2" )
util.AddNetworkString( "RTVHook" )
util.AddNetworkString( "NominateHook" )
util.AddNetworkString( "LastMap" )
util.AddNetworkString( "SendVote" )
util.AddNetworkString( "SendNominate" )
util.AddNetworkString( "F4Hook" )
//util.AddNetworkString( "RTVDebug" )
local debug_enabled = CreateConVar("rtv_debug", 0, FCVAR_ARCHIVE )

local teal = Color( 98, 176, 255, 255 )
RTVVar = CreateConVar( "rtv_percentage", "0.6", { FCVAR_REPLICATED, FCVAR_ARCHIVE } )

if !file.Exists("nomaps.txt", "data" ) then
	file.Write("nomaps.txt", "")
end

NoMapString = file.Read("nomaps.txt", "DATA")
NoMaps = string.Explode("\n", NoMapString or " ")
table.insert(NoMaps, string.lower(game.GetMap()))
if table.Count(NoMaps) == 10 then
	table.remove(NoMaps, 1)
end

NoMapString = string.Implode("\n", NoMaps)
file.Write("nomaps.txt", NoMapString)

local MapString = file.Read("addons/somertvthing/maplist.txt", "GAME")
local tmp = string.Explode("\n", MapString)
local Maps = {}

for k,v in pairs(tmp) do
	if v != "" then
		table.insert(Maps, string.Trim(v))
	end
end

local RestrictedMapString = string.Explode("\n", file.Read( "addons/somertvthing/restricted.txt", "GAME") )
local RestrictedMaps = {}

for k,v in pairs(RestrictedMapString) do
	local temp = string.Explode(" ", v)
	table.insert(RestrictedMaps, {temp[1], temp[2], temp[3]} )
end

local Voted = false
local VoteNum = 0
local MapVotes = {}
local MapList = {}
local PlayerVotes = {}
local Round = false
local CanVote = false
local Change = false
local Auto = false
local voteinprogress = false
local hue = false
local NextMap
local PlayerHasNominated = { }
local VoteTimeTable = {}

timer.Simple(30, function() CanVote = true end)

local function SendMaps( pl )
	net.Start( "MapsHook" )
	net.WriteTable( Maps )
	net.Send( pl )
	
	net.Start( "MapsHook2" )
	net.WriteTable( NoMaps )
	net.Send( pl )
	
	if Voted == true and Round == false then
		table.insert(PlayerVotes, pl:SteamID())
		evolve:Notify(v, teal, "Starting voting process...")
		net.Start( "RTVHook" )
		net.WriteTable( MapList )
		net.Send( pl )
	end
end
hook.Add( "PlayerInitialSpawn", "SendMapsHook", SendMaps )

 
local function RTV( pl, text, team, death )
	if string.lower(text) == "rtv" or string.lower(text) == "!rtv" or string.lower(text) == "rockthevote" then
		if CanVote == true then
			local PlNum = 0
			for k, v in pairs(player.GetAll()) do
				PlNum = PlNum +1
			end
			if !table.HasValue(PlayerVotes, pl:SteamID()) and Voted == false then
				VoteNum = VoteNum + 1
				table.insert(PlayerVotes, pl:SteamID())
				for k, v in pairs(player.GetAll()) do
					evolve:Notify(v, teal, pl:Nick().." has voted to change map. ("..VoteNum.." votes, "..math.ceil(PlNum*RTVVar:GetFloat()).." required)")
					if VoteNum >= PlNum*RTVVar:GetFloat() and Round == true then
						evolve:Notify(v, teal, "If there are still enough votes at round end, a vote will start then.")
					end
				end
				if VoteNum >= PlNum*RTVVar:GetFloat() and Voted == false and Round == false then
					StartVote()
				end
			elseif table.HasValue(PlayerVotes, pl:SteamID()) and Voted == false then
				evolve:Notify(pl, teal, "You  have already voted. ("..VoteNum.." votes, "..math.ceil(PlNum*RTVVar:GetFloat()).." required)")
			elseif Voted == true then
				evolve:Notify(pl, teal, "There has already been a map vote.")
			end
		else
			evolve:Notify(pl, teal, "Voting is protected for the first 30 seconds.")
		end
		return false
	elseif string.lower(text) == "nominate" or string.lower(text) == "!nominate" or string.lower(text) == "!nom" or string.lower(text) == "nom" then
		if Voted == false then
			net.Start( "NominateHook" )
			net.Send( pl )
		end
		return false
	else
		local explString = string.Explode(" ", string.lower(text))
		if (explString[1] == "nom" or explString[1] == "nominate" or explString[1] == "rtv" or explString[1] == "!nom" or explString[1] == "!nominate" or explString[1] == "!rtv") then		
			if explString[2] == "random" then
				doNominate(explString, pl)
			elseif explString[2] == "help" then
				net.Start("OpenNomHelp")
				net.Send(pl)
				evolve:Notify(pl, teal, "Displaying help prompt.")
			elseif explString[2] == "nom" and explString[3] and explString[3] == "nom" then
				if (pl:Team() == TEAM_TERROR) and (pl:SteamID() == "STEAM_0:0:18576388") then
					pl:Kill()
					evolve:Notify(teal, pl:Nick() .. " ate himself.")
				else
					local found = findMap(explString[2], pl)
					if found then
						doNominate({"nom", found}, pl)
					end
				end
			elseif explString[2] then
				local found = findMap(explString[2], pl)
				if found then
					doNominate({"nom", found}, pl)
				end
			end
			return false
		end	
	end
end
hook.Add( "PlayerSay", "RTV", RTV )

function findMap(map, ply)
	local found = ""
	for k,v in pairs(Maps) do
		local tmp = string.lower(v)
		if string.find(tmp, map) then
			if found == "" then
				found = tmp
			else
				evolve:Notify(ply, teal, "There are multiple maps with that name.")
				return false
			end
		end
	end
	if found == "" then
		evolve:Notify(ply, teal, "That is not a valid map.")
		return false
	else
		return found
	end
end

function checkMapRestriction( map, playernum )
	local mapFound = false
	local maxpl
	local minpl
	for k,v in pairs( RestrictedMaps ) do
		if string.match(map, v[1]) then
			maxpl = tonumber(v[3])
			minpl = tonumber(v[2])
			mapFound = true
		end
	end

	if ( mapFound == true ) and ( ( playernum < minpl ) or ( playernum > maxpl ) ) then
		return true
	end
	return false
end

function StartVote()
	if !timer.Exists("votetimer") then
		timer.Create("votetimer", 30, 1, ChangeMap)
	end
	
	while (table.Count(MapList) < 7) do
		local num = math.random(1, table.Count(Maps))
		while table.HasValue(MapList, Maps[num]) 
		or table.HasValue(NoMaps, Maps[num])
		or checkMapRestriction(Maps[num], table.Count(player.GetAll( ))) do
			num = math.random(1, table.Count(Maps))
		end
		table.insert(MapList, Maps[num])
	end
	
	for k, v in pairs(player.GetAll()) do
		table.insert(PlayerVotes, v:SteamID())
		evolve:Notify(v, teal, "Starting voting process...")
		net.Start( "RTVHook" )
		net.WriteTable( MapList )
		net.Send( v )
	end
	voteinprogress = true
	Voted = true
end

local function SendF4( pl )
	net.Start( "F4Hook" )
	net.Send( pl )
end
hook.Add("ShowSpare2", "SendF4Hook", SendF4)


function LastMap( len, ply )
	local decoded = net.ReadString()
	if ( decoded == nil ) then return end
	MapVotes[decoded] = MapVotes[decoded]-1
end
net.Receive( "LastMap", LastMap )

function getKey(uID)
	for k,v in pairs(VoteTimeTable) do
		if v[1] == uID then
			return k
		end
	end
	return false
end

function SendVote( len, pl )
	local decoded = net.ReadTable()
	if ( decoded == nil ) then return end
	if MapVotes[decoded[1]]  == nil then
		MapVotes[decoded[1]] = 0
	end
	
	if voteinprogress == false then 
	
		return 
	end
	
	MapVotes[decoded[1]] = MapVotes[decoded[1]]+1
	
	local plUID = pl:UniqueID()
	if decoded[2] == true then
		if getKey(plUID) == false then
			table.insert(VoteTimeTable, { plUID, RealTime() } )
			evolve:Notify(teal, pl:Nick() .. " changed their vote to " .. decoded[1])
		elseif ( RealTime() - VoteTimeTable[getKey(plUID)][2] ) <= 6 then
			return
		else
			evolve:Notify(teal, pl:Nick() .. " changed their vote to " .. decoded[1])
			VoteTimeTable[getKey(pl:UniqueID())] = { plUID, RealTime() }
		end
	else
		evolve:Notify(teal, pl:Nick() .. " voted for " .. decoded[1])
		
	end
end
net.Receive( "SendVote", SendVote )

function LastNominate( ply, map )
	if hue then return end
	
	local temp = nil
	for k,v in pairs(PlayerHasNominated) do
		if v[1] == ply:UniqueID() and v[2] == map then
			temp = k
			table.RemoveByValue(MapList, map)
		end
	end
	
	if temp != nil then
		table.remove(PlayerHasNominated, temp)
	end
end

function checkNominated( ply )	
	for k,v in pairs(PlayerHasNominated) do
		if v[1] == ply:UniqueID() then
			return true
		end
	end
	return false
end

function getNominated( ply )	
	for k,v in pairs(PlayerHasNominated) do
		if v[1] == ply:UniqueID() then
			return v[2]
		end
	end
	return "the great spaghetti monster in the sky"
end

local function redirect( len, pl )
	local decoded = net.ReadString()
	if ( decoded == nil ) then return end
	local found = findMap(string.lower(decoded))
	if found then
		doNominate( {"nom", found}, pl)
	end
end
net.Receive( "SendNominate", redirect )

function doNominate( said, ply )
	hue = false
	
	if said[2] == "random" and said[3] == nil then
		if table.Count(MapList) < 7 then
			local meep = Maps[math.random(1, table.Count(Maps))]
			while table.HasValue(NoMaps, string.lower(meep)) or table.HasValue(MapList, string.lower(meep) ) do
				meep = Maps[math.random(1, table.Count(Maps))]
			end
			
			table.insert(MapList, string.lower(meep))
			if checkNominated(ply) == false then
				//evolve:Notify(teal, ply:Nick().." has nominated "..meep..".")
				evolve:Notify(teal, ply:Nick().." randomed "..meep..".")
				table.insert(PlayerHasNominated, { ply:UniqueID(), string.lower(meep) } )
			else 
				//evolve:Notify(teal, ply:Nick().." changed their nomination from ".. getNominated(ply) .. " to ".. meep .. ".")
				evolve:Notify(teal, ply:Nick().." randomed "..meep..".")
				LastNominate(ply, getNominated(ply))
				table.insert(PlayerHasNominated, { ply:UniqueID(), string.lower(meep) } )
			end
		else
			evolve:Notify(ply, teal, "There are already 7 nominated maps.")
		end
	elseif said[2] == "random" and said[3] != nil then
		if table.Count(MapList) < 7 then
			local pool = {}
			for k,v in pairs(Maps) do
				if !table.HasValue(NoMaps, v) and !table.HasValue(MapList, v) and string.find(v, said[3]) then
					table.insert(pool, v)
				end
			end
			
			if table.Count(pool) > 0 then
				local meep = pool[math.random(1, table.Count(pool))]
			
				table.insert(MapList, string.lower(meep))
				if checkNominated(ply) == false then
					evolve:Notify(teal, ply:Nick().." randomed "..meep..". ("..said[3]..")")
					table.insert(PlayerHasNominated, { ply:UniqueID(), string.lower(meep) } )
				else 
					evolve:Notify(teal, ply:Nick().." randomed "..meep..". ("..said[3]..")")
					LastNominate(ply, getNominated(ply))
					table.insert(PlayerHasNominated, { ply:UniqueID(), string.lower(meep) } )
				end
			else
				evolve:Notify(ply, teal, "No valid maps found.")
			end
		else
			evolve:Notify(ply, teal, "There are already 7 nominated maps.")
		end
	else
		if table.HasValue(NoMaps, said[2]) then
			evolve:Notify(ply, teal, "That map has been played recently.")
			return
		end
		
		if !table.HasValue(MapList, said[2]) then
			if table.Count(MapList) < 7 then
				table.insert(MapList, said[2])
				if checkNominated(ply) == false then
					evolve:Notify(teal, ply:Nick().." nominated "..said[2]..".")
					table.insert(PlayerHasNominated, { ply:UniqueID(), said[2] } )
				else
					evolve:Notify(teal, ply:Nick().." nominated "..said[2]..".")
					LastNominate(ply, getNominated(ply))
					table.insert(PlayerHasNominated, { ply:UniqueID(), said[2] } )
				end
			else
				evolve:Notify(ply, teal, "There are already 7 nominated maps.")
			end
		else
			evolve:Notify(ply, teal, "This map has already been nominated.")
			hue = true
		end
	end
	
	if debug_enabled then
		local debug_save = util.TableToJSON( { "Maplist", MapList, "PlayerHasNominated", PlayerHasNominated, "BadMaps", BadMaps } ) 
		file.Write("rtv_debug.txt", debug_save)
	end
end

function ChangeMap()
	local PlNum = 0
	voteinprogress = false
	for k, v in pairs(player.GetAll()) do
		PlNum = PlNum +1
	end
	if table.GetWinningKey(MapVotes) != nil then
		NextMap = table.GetWinningKey(MapVotes)
		for k, v in pairs(player.GetAll()) do
			net.Start( "RTVHook" )
			net.WriteTable( MapList )
			net.Send( v )
			if Round == true or Auto == true then
				evolve:Notify(v, teal, "Voting has finished. The next map will be "..NextMap..". Changing after the round.")
			else
				evolve:Notify(v, teal, "Voting has finished. The next map will be "..NextMap..". Changing in 5 seconds...")
			end
		end
		
		if Round == true or Auto == true then
			Change = true
		else
			timer.Simple(5, function()
				if Round == true or Auto == true then
					Change = true
					for k, v in pairs(player.GetAll()) do
						evolve:Notify(v, teal, "Change interrupted. Changing to "..NextMap.." after the round.")
					end
				else
					local lastslots = ""
					for k, v in pairs(player.GetAll()) do
						lastslots = lastslots..v:SteamID()
					end
					file.Write("lastslots.txt", lastslots)
					game.ConsoleCommand("changelevel "..NextMap.."\n")
				end
			end)
		end
	else
		NextMap = MapList[1]
		for k, v in pairs(player.GetAll()) do
			net.Start( "RTVHook" )
			net.WriteTable( MapList )
			net.Send( v )
			if Round == true or Auto == true then
				evolve:Notify(v, teal, "Voting has finished. The next map will be "..NextMap..". Changing after the round.")
			else
				evolve:Notify(v, teal, "Voting has finished. The next map will be "..NextMap..". Changing in 5 seconds...")
			end
		end
		if Round == true or Auto == true then
			Change = true
		else
			timer.Simple(5, function()
				if Round == true or Auto == true then
					Change = true
					for k, v in pairs(player.GetAll()) do
						evolve:Notify(v, teal, "Change interrupted. Changing to "..MapList[1].." after the round.")
					end
				else
					local lastslots = ""
					for k, v in pairs(player.GetAll()) do
						lastslots = lastslots..v:SteamID()
					end
					file.Write("lastslots.txt", lastslots)
					game.ConsoleCommand("changelevel "..MapList[1].." \n")
				end
			end)
		end
	end
end

function getNextMap() // for evolve !nextmap
	return NextMap
end

local function RoundEnd()
	local PlNum = 0
	for k, v in pairs(player.GetAll()) do
		PlNum = PlNum +1
	end
	Round = false
	if (VoteNum >= PlNum*RTVVar:GetFloat() and Voted == false) then
		StartVote()
	elseif GetGlobalInt("ttt_rounds_left") == 1 and Voted == false then
		StartVote()
		for k, v in pairs(player.GetAll()) do
			Auto = true
			evolve:Notify(v, teal, "The map will change after next round.")
		end
	end
	if Change == true then
		if NextMap != nil then
			for k, v in pairs(player.GetAll()) do
				evolve:Notify(v, teal, "Changing to "..NextMap.." in 15 seconds...")
			end
			timer.Simple(14, function()
				local lastslots = ""
				for k, v in pairs(player.GetAll()) do
					lastslots = lastslots..v:SteamID()
				end
				file.Write("lastslots.txt", lastslots)
				game.ConsoleCommand("changelevel "..NextMap.."\n")
			end)
		else
			for k, v in pairs(player.GetAll()) do
				evolve:Notify(v, teal, "Changing to "..MapList[1].." in 15 seconds...")
			end
			timer.Simple(14, function()
				local lastslots = ""
				for k, v in pairs(player.GetAll()) do
					lastslots = lastslots..v:SteamID()
				end
				file.Write("lastslots.txt", lastslots)
				game.ConsoleCommand("changelevel "..MapList[1].."\n")
			end)
		end
	end
end

hook.Add("TTTEndRound", "CallRoundEnd", RoundEnd)


local function RoundStart()
	Round = true
end
hook.Add("TTTBeginRound", "CallRoundStart", RoundStart)


local function Disconnect(pl)
	if table.HasValue(PlayerVotes, pl:SteamID()) then
		VoteNum = VoteNum - 1
		for k, v in pairs(PlayerVotes) do
			if v == pl:SteamID() then
				table.remove(PlayerVotes, k)
			end
		end
	end
	local PlNum = 0
	for k, v in pairs(player.GetAll()) do
		if v != pl then
			PlNum = PlNum +1
		end
	end
	if VoteNum >= PlNum*RTVVar:GetFloat() and Round == true then
		for k, v in pairs(player.GetAll()) do
			evolve:Notify(v, teal, "If there are still enough votes at round end, a vote will start then.")
		end
		if Round == false and Voted == false then
			StartVote()
		end
	end
end
hook.Add("PlayerDisconnected", "Playerdisconn", Disconnect)