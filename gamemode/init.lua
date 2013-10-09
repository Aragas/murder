AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_footsteps.lua")
AddCSLuaFile("cl_respawn.lua")
AddCSLuaFile("cl_murderer.lua")
AddCSLuaFile("cl_player.lua")
AddCSLuaFile("cl_fixplayercolor.lua")
AddCSLuaFile("cl_ragdoll.lua")
AddCSLuaFile("cl_chattext.lua")
AddCSLuaFile("cl_voicepanels.lua")
AddCSLuaFile("cl_rounds.lua")
AddCSLuaFile("cl_endroundboard.lua")

include("shared.lua")
include("sv_player.lua")
include("sv_parkour.lua")
include("sv_spawns.lua")
include("sv_stealth.lua")
include("sv_ragdoll.lua")
include("sv_respawn.lua")
include("sv_murderer.lua")
include("sv_rounds.lua")
include("sv_footsteps.lua")
include("sv_chattext.lua")
include("sv_loot.lua")

resource.AddFile("materials/thieves/footprint.vmt")

util.AddNetworkString("your_are_a_murderer")

function GM:Initialize() 
	self:LoadSpawns()
	self.DeathRagdolls = {}
	self:StartNewRound()
	self:LoadLootData()
end

function GM:InitPostEntity() 
	local canAdd = self:CountLootItems() <= 0
	for k, ent in pairs(ents.FindByClass("mu_loot")) do
		if canAdd then
			self:AddLootItem(ent)
		end
	end
	self:InitPostEntityAndMapCleanup()
end

function GM:InitPostEntityAndMapCleanup() 
	for k, ent in pairs(ents.GetAll()) do
		if ent:GetClass():find("door") then
			ent:Fire("unlock","",0)
		end
	end

	for k, ent in pairs(ents.FindByClass("mu_loot")) do
		ent:Remove()
	end
	self:SpawnLoot()
end

function GM:Think()
	self:ParkourThink()
	self:RoundThink()
	self:MurdererThink()
end

function GM:AllowPlayerPickup( ply, ent )
	return true
end

function GM:PlayerNoClip( ply )
	return ply:IsAdmin() || ply:GetMoveType() == MOVETYPE_NOCLIP
end

function GM:PlayerSwitchFlashlight(ply, turningOn)
	return true
end

function GM:OnEndRound()

end

function GM:OnStartRound()
	
end

function GM:SendMessageAll(msg) 
	for k,v in pairs(player.GetAll()) do
		v:ChatPrint(msg)
	end
end

