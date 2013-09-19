local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

function GM:PlayerInitialSpawn( ply )

	ply:SetTeam(2)

end

function GM:PlayerSpawn( ply )

	-- If the player doesn't have a team
	-- then spawn him as a spectator
	if ply:Team() == 1 || ply:Team() == TEAM_UNASSIGNED then

		GAMEMODE:PlayerSpawnAsSpectator( ply )
		return
	
	end

	-- Stop observer mode
	ply:UnSpectate()

	player_manager.OnPlayerSpawn( ply )
	player_manager.RunClass( ply, "Spawn" )

	hook.Call( "PlayerLoadout", GAMEMODE, ply )
	hook.Call( "PlayerSetModel", GAMEMODE, ply )

	ply:CalculateSpeed()

	local oldhands = ply:GetHands()
	if ( IsValid( oldhands ) ) then oldhands:Remove() end

	local hands = ents.Create( "gmod_hands" )
	if ( IsValid( hands ) ) then
		ply:SetHands( hands )
		hands:SetOwner( ply )

		-- Which hands should we use?
		local cl_playermodel = ply:GetInfo( "cl_playermodel" )
		local info = player_manager.TranslatePlayerHands( cl_playermodel )
		if ( info ) then
			hands:SetModel( info.model )
			hands:SetSkin( info.skin )
			hands:SetBodyGroups( info.body )
		end

		-- Attach them to the viewmodel
		local vm = ply:GetViewModel( 0 )
		hands:AttachToViewmodel( vm )

		vm:DeleteOnRemove( hands )
		ply:DeleteOnRemove( hands )

		hands:Spawn()
 	end

 	local spawnPoint = self:PlayerSelectTeamSpawn(ply:Team(), ply)
 	if IsValid(spawnPoint) then
 		ply:SetPos(spawnPoint:GetPos())
 	end

 	local vec = Vector(0,0,0)
 	vec.x = math.Rand(0, 1)
 	vec.y = math.Rand(0, 1)
 	vec.z = math.Rand(0, 1)
 	ply:SetPlayerColor(vec)
end

function GM:PlayerLoadout(ply)

	ply:Give("weapon_rp_hands")

	if ply:GetMurderer() then
		ply:Give("weapon_crowbar")
	end

	print(ply, "loadout")


end

local thiefModels = {
"male03",
"male04",
"male05",
"male07",
"male06",
"male09",
"male01",
"male02",
"male08",
"female05",
"female06",
"female01",
"female03",
"female02",
"female04",
"refugee01",
"refugee02",
"refugee03",
"refugee04"
}

function GM:PlayerSetModel( ply )

	local cl_playermodel = ply:GetInfo( "cl_playermodel" )

	cl_playermodel = table.Random(thiefModels)

	local modelname = player_manager.TranslatePlayerModel( cl_playermodel )
	util.PrecacheModel( modelname )
	ply:SetModel( modelname )

end

function GM:DoPlayerDeath( ply, attacker, dmginfo )

	ply:CreateRagdoll()

	local ent = ply:GetNWEntity("DeathRagdoll")
	if IsValid(ent) then
		ply:SpectateEntity( ent )
		ply:Spectate( OBS_MODE_CHASE )
		ply.Spectating = ent
	end

	ply:AddDeaths( 1 )

	if ( attacker:IsValid() && attacker:IsPlayer() ) then

		if ( attacker == ply ) then
			attacker:AddFrags( -1 )
		else
			attacker:AddFrags( 1 )
		end

	end

end

local plyMeta = FindMetaTable("Player")

function plyMeta:CalculateSpeed()
	// set the defaults
	local walk,run,canrun = 250,300,false
	local jumppower = 200

	if self:GetMurderer() then
		canrun = true
	end

	// handcuffs
	-- if self:GetHandcuffed() then
	-- 	walk = walk * 0.3
	-- 	jumppower = 150
	-- 	canrun = false
	-- end
	-- if self:GetTasered() then
	-- 	walk = 40
	-- 	jumppower = 100
	-- 	canrun = false
	-- end

	// set out new speeds
	if canrun then
		self:SetRunSpeed(run)
	else
		self:SetRunSpeed(walk)
	end
	self.CanRun = canrun
	self:SetWalkSpeed(walk)
	self:SetJumpPower(jumppower)
end

function plyMeta:CanParkour()
	return true
end

local function isValid() return true end
local function getPos(self) return self.pos end

local function generateSpawnEntities(spawnList)
	local tbl = {}

	for k, pos in pairs(spawnList) do
		local t = {}
		t.IsValid = isValid
		t.GetPos = getPos
		t.pos = pos
		table.insert(tbl, t)
	end

	return tbl
end

function GM:PlayerSelectTeamSpawn( TeamID, pl )

	local SpawnPoints = team.GetSpawnPoints( TeamID )

	SpawnPoints = generateSpawnEntities(TeamSpawns["spawns"])

	if ( !SpawnPoints || table.Count( SpawnPoints ) == 0 ) then return end
	
	local ChosenSpawnPoint = nil
	
	for i=0, 6 do
	
		local ChosenSpawnPoint = table.Random( SpawnPoints )
		if ( GAMEMODE:IsSpawnpointSuitable( pl, ChosenSpawnPoint, i==6 ) ) then
			return ChosenSpawnPoint
		end
	
	end
	
	return ChosenSpawnPoint

end


function GM:PlayerDeathSound()
	// don't play sound
	return true
end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
	// Don't scale it depending on hitgroup
end

function GM:PlayerDeath(victim, Inflictor, Attacker )

	victim.NextSpawnTime = CurTime() + 30
	victim.DeathTime = CurTime()
	victim.SpectateTime = CurTime() + 12

	umsg.Start("rp_death", victim)
	umsg.Long(30)
	umsg.Long(12)
	umsg.End()
	
	if ( Inflictor && Inflictor == Attacker && (Inflictor:IsPlayer() || Inflictor:IsNPC()) ) then
	
		Inflictor = Inflictor:GetActiveWeapon()
		if ( !Inflictor || Inflictor == NULL ) then Inflictor = Attacker end
	
	end

	self:RagdollSetDeathDetails(victim, Inflictor, Attacker)
end

function GM:PlayerDeathThink( ply )

	if self:CanRespawn(ply) then
		ply:Spawn()
	end

	if (ply.SpectateTime < CurTime() && ply:KeyPressed(IN_ATTACK))
	 || !IsValid(ply.Spectating) || (ply.Spectating:IsPlayer() && !ply.Spectating:Alive()) then

		// recalculate spectating
		local players = team.GetPlayers(2)
		for k,v in pairs(players) do
			if !(v:Alive()) then
				players[k] = nil
			end
		end

		local ent = table.Random(players)
		if IsValid(ent) then
			ply:SpectateEntity( ent )
			ply:Spectate( OBS_MODE_IN_EYE )
			ply.Spectating = ent
		elseif IsValid(ply.Spectating) then
			if ply.Spectating != ply:GetRagdollEntity() then
				ply:SpectateEntity( ply:GetRagdollEntity() )
				ply:Spectate( OBS_MODE_CHASE )
				ply.Spectating = ply:GetRagdollEntity()
			end
		elseif ply.Spectating then
			ply.Spectating = nil
			ply:Spectate( OBS_MODE_ROAMING )
		end
	end
	
end

function EntityMeta:GetPlayerColor()
	return self.playerColor or Vector()
end

function EntityMeta:SetPlayerColor(vec)
	self.playerColor = vec
	self:SetNWVector("playerColor", vec)
end

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
	self:FootstepsOnFootstep(ply, pos, foot, sound, volume, filter)
end
