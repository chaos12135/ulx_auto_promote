---------------------------------------------------------------
// APromoteGUI by Lead4u, Modified and Fixed by Mr. Apple    //
// Version: 3.5 Full Release                                 //
---------------------------------------------------------------

resource.AddFile("materials/gui/silkicons/cog.vmt")

ULib.ucl.registerAccess( "apromote_settings", "superadmin", "Allows managing all settings related to APromote.", "XGUI" )

local APromote = {}
local set = {} APromote["set"] = set
local grp = {} APromote["grp"] = grp

util.AddNetworkString( "doApShinys" )

local function Save()
	file.Write( "ulx/apromote.txt", ULib.makeKeyValues( APromote ) )
end

local function APUpdateGroups()
	//for added groups
		for k, v in pairs(ULib.ucl.groups) do
			if ( APromote["grp"][k] == nil and k != "user") then
				print("Added " .. k .. " to APromote.")
				APromote["grp"][k] = -1
			end
		end
		for k, v in pairs(APromote["grp"]) do
			if ( k != nil and !ULib.ucl.groups[k]) or k == "user" then
				print("Removed " .. k .. " from APromote.")
				APromote["grp"][k] = nil
			end
		end
		xgui.sendDataTable( {}, "AP_SendData" )
		Save()
end

local function loadAP()
	xgui.addDataType( "AP_SendData", function() return APromote["grp"] end, "apromote_settings", 0, 0 )
	
// File Stuffs
	if not file.Exists( "ulx/apromote.txt", "DATA" ) then
		for k, v in pairs(ULib.ucl.groups) do
			APromote["grp"][k] = -1
		end
		APromote["set"]["ap_enabled"] = 1
		APromote["set"]["ap_snd_enabled"] = 1
		APromote["set"]["ap_snd_scope"] = 1
		APromote["set"]["ap_effect_enabled"] = 1
		APromote["set"]["ap_auto_demote"] = 0
		Save()
	else 
		APromote = ULib.parseKeyValues( file.Read( "ulx/apromote.txt" ) )
	end
// ConVars
	ULib.replicatedWritableCvar("ap_enabled","rep_ap_enabled", APromote["set"]["ap_enabled"],false,false,"apromote_settings")
	ULib.replicatedWritableCvar("ap_snd_enabled","rep_ap_snd_enabled",APromote["set"]["ap_snd_enabled"] ,false,false,"apromote_settings")
	ULib.replicatedWritableCvar("ap_snd_scope","rep_ap_snd_scope",APromote["set"]["ap_snd_scope"] ,false,false,"apromote_settings")
	ULib.replicatedWritableCvar("ap_effect_enabled","rep_ap_effect_enabled",APromote["set"]["ap_effect_enabled"] ,false,false,"apromote_settings")
	ULib.replicatedWritableCvar("ap_auto_demote","rep_ap_auto_demote",APromote["set"]["ap_auto_demote"] ,false,false,"apromote_settings")
// Data and Hook Add	
	xgui.sendDataTable( {}, "AP_SendData" )
	hook.Add( "UCLChanged", "doApUpdateSV", APUpdateGroups )
end

local function cVarChange( sv_cvar, cl_cvar, ply, old_val, new_val )
	if ( sv_cvar =="ap_enabled" or sv_cvar=="ap_snd_enabled" or sv_cvar=="ap_snd_scope" or sv_cvar=="ap_effect_enabled" or sv_cvar=="ap_auto_demote" ) then
		APromote["set"][sv_cvar] = new_val
		Save()
	end
end

local function PlayRankSound( ply )
	if ( GetConVarNumber( "ap_effect_enabled" ) == 1 ) then
		net.Start( "doApShinys" )
		net.WriteEntity( ply )
		net.Broadcast()
	end
	if ( GetConVarNumber( "ap_snd_enabled" ) == 1) then
		if ( GetConVarNumber( "ap_snd_scope" ) == 1 ) then
			for k, v in pairs(player.GetAll()) do
				v:SendLua("surface.PlaySound( \"/garrysmod/save_load1.wav\" )")
			end
		elseif ( GetConVarNumber( "ap_snd_scope" ) == 0) then
			ply:SendLua("surface.PlaySound( \"/garrysmod/save_load1.wav\" )")
		end
	end
end
	
local function isValidCommand( command, compare )
	for k, v in pairs( compare ) do
		if ( command[1] == k ) then
			if ( type( command[2] == "number")) then
				return true
			end
		end
	end	
	return false
end

concommand.Add("APGroup", function( ply, cmd, args )
	if (ply:query( "apromote_settings" ) and isValidCommand( args, APromote["grp"] )) then
		APromote["grp"][args[1]] = tonumber(args[2])
		xgui.sendDataTable( {}, "AP_SendData" )
		Save()
	end
end)
 
local function checkPlayer( ply ) 
	local plyhours = math.floor( ply:GetUTimeTotalTime() / 3600 )
	local usrgrp = ply:GetUserGroup()
	local Rank = ""
	local Hours = 0

	for k, v in pairs( APromote["grp"] ) do 
		if plyhours >= tonumber( v ) and tonumber( v ) >= Hours then
			if tonumber( v ) >= 0 then
				Rank = k
				Hours = tonumber( v )
			end
		end
	end
	if (!ply:IsUserGroup(Rank) and Rank != "") then
		if tonumber( APromote["grp"][usrgrp]) != -1 then
			if not tobool( GetConVarNumber( "ap_auto_demote" ) ) and APromote["grp"][usrgrp] != nil 
			and Hours < tonumber( APromote["grp"][usrgrp] ) then
				return
			else
				if ply:IsConnected() then 
					RunConsoleCommand( "ulx", "adduserid", ply:SteamID(), Rank )
					PlayRankSound( ply )
				end
			end
		end
	end
end

timer.Create("doAPUpdateTimer", 10, 0, function()
if not tobool( GetConVarNumber( "ap_enabled" ) ) then return end
	for k, v in pairs( player.GetAll() ) do
		if (v:IsPlayer() and v:IsValid() and !v:IsBot()) then
			ULib.queueFunctionCall(	checkPlayer, v )
		end
	end
end)

xgui.addSVModule( "AP_LoadAP", loadAP )
hook.Add( "ULibReplicatedCvarChanged", "APGroupCVAR", cVarChange )
