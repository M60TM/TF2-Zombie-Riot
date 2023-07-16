#pragma semicolon 1
#pragma newdecls required


/*
	Shards:
	
	You gain shards by hitting stuff, simple

	Pap0:
	
	Mouse2=Wide Blade Swing (can simply be held)
	Cost: 1 Shard

	
	Pap1:
	
	Reload+m2 = Long Blade Swing
	Cost: 1 Shard
	Halo

	
	Pap2:
	
	Mouse2+crouch = Tele
	Cost: 3 Shards
	Wings
*/

static Handle h_TimerFantasyManagement[MAXPLAYERS+1] = {INVALID_HANDLE, ...};


static float fl_Shard_Ammount[MAXTF2PLAYERS+1];
static float fl_blade_swing_reload_time[MAXTF2PLAYERS+1];
static float fl_teleport_recharge_time[MAXTF2PLAYERS+1];
static float fl_hud_timer[MAXTF2PLAYERS+1];

static int i_Current_Pap[MAXTF2PLAYERS+1];

#define FANTASY_BLADE_SHOOT_1 	"weapons/physcannon/energy_sing_flyby1.wav"
#define FANTASY_BLADE_SHOOT_2 	"weapons/physcannon/energy_sing_flyby2.wav"



static char gLaser2;

static float BEAM_Targets_Hit[MAXENTITIES];
static bool Fantasy_Blade_BEAM_HitDetected[MAXENTITIES];
static int Fantasy_Blade_BEAM_BuildingHit[MAXENTITIES];

static float fl_trace_target_timeout[MAXENTITIES][MAXENTITIES];


#define WAND_TELEPORT_SOUND "weapons/bison_main_shot.wav"

static int ShortTeleportLaserIndex;

public void Fantasy_Blade_MapStart()
{
	gLaser2 = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	Zero(fl_blade_swing_reload_time);
	Zero(fl_teleport_recharge_time);
	Zero(fl_hud_timer);
	ShortTeleportLaserIndex = PrecacheModel("materials/sprites/laser.vmt", false);
	PrecacheSound(WAND_TELEPORT_SOUND);
	PrecacheSound(FANTASY_BLADE_SHOOT_1);
	PrecacheSound(FANTASY_BLADE_SHOOT_2);
}

public void Npc_OnTakeDamage_Fantasy_Blade(int client, int damagetype)
{
	if(damagetype & DMG_CLUB) //Only count the usual melee only etc etc etc. 
	{
		fl_Shard_Ammount[client] += 1.0;
	}
}

public void Activate_Fantasy_Blade(int client, int weapon)
{	
	if (h_TimerFantasyManagement[client] != INVALID_HANDLE)
	{
		//This timer already exists.
		if(i_CustomWeaponEquipLogic[weapon] == WEAPON_FANTASY_BLADE)
		{
			//Is the weapon it again?
			//Yes?
			KillTimer(h_TimerFantasyManagement[client]);
			h_TimerFantasyManagement[client] = INVALID_HANDLE;
			i_Current_Pap[client] = Fantasy_Blade_Get_Pap(weapon);
		
			SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
			Create_Halo_And_Wings(client);
			DataPack pack;
			h_TimerFantasyManagement[client] = CreateDataTimer(0.1, Timer_Management_Fantasy, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(client);
			pack.WriteCell(EntIndexToEntRef(weapon));
		}
		return;
	}
		
	if(i_CustomWeaponEquipLogic[weapon] == WEAPON_FANTASY_BLADE)
	{
		i_Current_Pap[client] = Fantasy_Blade_Get_Pap(weapon);
		
		SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
		Create_Halo_And_Wings(client);
		DataPack pack;
		h_TimerFantasyManagement[client] = CreateDataTimer(0.1, Timer_Management_Fantasy, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(client);
		pack.WriteCell(EntIndexToEntRef(weapon));
	}
}
public Action Timer_Management_Fantasy(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if(IsValidClient(client))
	{
		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				Fantasy_Blade_Loop_Logic(client, EntRefToEntIndex(pack.ReadCell()));
			}
			else
				Kill_Fantasy_Loop(client);
		}
		else
			Kill_Fantasy_Loop(client);
	}
	else
		Kill_Fantasy_Loop(client);
		
	return Plugin_Continue;
}

static int Fantasy_Blade_Get_Pap(int weapon)
{
	int pap=0;
	Address address;
	address = TF2Attrib_GetByDefIndex(weapon, 122);
	if(address != Address_Null)
		pap = RoundFloat(TF2Attrib_GetValue(address));
	return pap;
}

public void Fantasy_Blade_m2(int client, int weapon, bool crit, int slot)
{
	if(i_Current_Pap[client]>0)	//pap1 and 2
	{
		float GameTime = GetGameTime();
		int buttons = GetClientButtons(client);
		bool reload = (buttons & IN_RELOAD) != 0;
		bool crouch = (buttons & IN_DUCK) != 0;
		if(i_Current_Pap[client]>1 && !reload)	//pap2	//only teleport if the player is not holding reload
		{
			if(crouch)
			{
				if(fl_teleport_recharge_time[client] <= GameTime)
				{
					if(fl_Shard_Ammount[client]>=3)
					{
						float damage = 1000.0;
						Address address = TF2Attrib_GetByDefIndex(weapon, 2);
						if(address != Address_Null)
							damage *= TF2Attrib_GetValue(address);
						float time = Fantasy_Blade_Tele(client, weapon, damage, 1000.0);
						fl_teleport_recharge_time[client] = GameTime + time;
						if(time>2.0)
						{
							fl_Shard_Ammount[client] -= 3.0;
						}
					}
					else
					{
						SetDefaultHudPosition(client);
						SetGlobalTransTarget(client);
						ShowSyncHudText(client,  SyncHud_Notifaction, "Not Enough Shards");
					}
				}
			}
		}
		if(reload && !crouch && fl_blade_swing_reload_time[client] <= GameTime)
		{
			if(fl_Shard_Ammount[client]>=1)
			{
				float time = 3.5;
				Address address = TF2Attrib_GetByDefIndex(weapon, 6);
				if(address != Address_Null)
					time *= TF2Attrib_GetValue(address);
				float damage = 100.0;
				address = TF2Attrib_GetByDefIndex(weapon, 2);
				if(address != Address_Null)
					damage *= TF2Attrib_GetValue(address);
				fl_blade_swing_reload_time[client] = GameTime + time + 0.5;
				float look_vec[3];
				Get_Fake_Forward_Vec(client, 1125.0, look_vec);
				Vertical_Slicer(client, look_vec, time, damage);
				fl_Shard_Ammount[client] -= 1.0;
			}
			else
			{
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "Not Enough Shards");
			}
		}
		
	}
	
}

static void Fantasy_Blade_Loop_Logic(int client, int weapon)
{
	int weapon_holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	

	if(IsValidEntity(weapon))
	{

		if(i_CustomWeaponEquipLogic[weapon] == WEAPON_FANTASY_BLADE)	//this loop will work if the holder doesn't have it in there hands, but they have it bought
		{

			if(weapon_holding==weapon)	//And this will only work if they have the weapon in there hands and bought
			{
				int pap = i_Current_Pap[client];
				float GameTime = GetGameTime();
				int buttons = GetClientButtons(client);
				bool reload = (buttons & IN_RELOAD) != 0;
				bool crouch = (buttons & IN_DUCK) != 0;
				bool attack2 = (buttons & IN_ATTACK2) != 0;
				if(!reload && !crouch && fl_blade_swing_reload_time[client] <= GameTime && attack2)
				{
					if(fl_Shard_Ammount[client]>=1)
					{
						float time = 1.75;
						Address address = TF2Attrib_GetByDefIndex(weapon, 6);
						if(address != Address_Null)
							time *= TF2Attrib_GetValue(address);
							
						float damage = 75.0;
						address = TF2Attrib_GetByDefIndex(weapon, 2);
						if(address != Address_Null)
							damage *= TF2Attrib_GetValue(address);
						fl_blade_swing_reload_time[client] = GameTime + time + 0.5;
						float look_vec[3];
						float range = 250.0;
						Get_Fake_Forward_Vec(client, range, look_vec);
						Horizontal_Slicer(client, look_vec, range/2.0, time, damage);
						fl_Shard_Ammount[client]--;
					}
					else
					{
						if(fl_hud_timer[client]<GameTime)
						{
							SetDefaultHudPosition(client);
							SetGlobalTransTarget(client);
							ShowSyncHudText(client,  SyncHud_Notifaction, "Not Enough Shards");
						}
					}
					
				}
				if(fl_hud_timer[client]<GameTime)
				{
					fl_hud_timer[client] = GameTime + 0.5;
					Fantasy_Show_Hud(client, GameTime, pap);
				}
				
			}
		}
		else
		{
			Kill_Fantasy_Loop(client);
		}
	}
	else
	{
		Kill_Fantasy_Loop(client);
		
	}
}
static void Fantasy_Show_Hud(int client, float GameTime, int pap)
{
	float duration = fl_blade_swing_reload_time[client] - GameTime;

	if(pap==2)
	{
		float tele_duration = fl_teleport_recharge_time[client] - GameTime; 
		if(duration>0.0 && tele_duration<0.0)	//swing no, tele yes
		{
			PrintHintText(client,"Shards: [%.1f] | Fantasmal Swing: Ready In: [%.1f] | Teleport: [Ready] (Cost:3)", fl_Shard_Ammount[client] , duration);
		}
		else if(duration<=0.0 && tele_duration>0.0)	//swing yes, tele no
		{
			PrintHintText(client,"Shards: [%.1f] | Fantasmal Swing: [Ready] (Cost:1) | Teleport: Ready In: [%.1f]", fl_Shard_Ammount[client], tele_duration);
		}
		else if(duration<=0.0 && tele_duration<=0.0)//swing yes, tele yes
		{
			PrintHintText(client,"Shards: [%.1f] | Fantasmal Swing: [Ready] (Cost:1) | Teleport: [Ready] (Cost:3)", fl_Shard_Ammount[client]);
		}
		else	//swing no, tele no
		{
			PrintHintText(client,"Shards: [%.1f] | Fantasmal Swing: Ready In: [%.1f] | Teleport: Ready In: [%.1f]", fl_Shard_Ammount[client], duration, tele_duration);
		}
			
	}
	else
	{
		if(duration>0)
			PrintHintText(client,"Shards: [%.1f] | Fantasmal Swing: Ready In: [%.1f]", fl_Shard_Ammount[client] , duration);
		else
			PrintHintText(client,"Shards: [%.1f] | Fantasmal Swing: [Ready]", fl_Shard_Ammount[client]);
	}
	
	StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
}

static void Get_Fake_Forward_Vec(int client, float Range, float Vec_Target[3])
{
	float vecAngles[3], Direction[3], Pos[3];
	GetClientEyeAngles(client, vecAngles);
	GetClientEyePosition(client, Pos);
	
	GetAngleVectors(vecAngles, Direction, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(Direction, Range);
	AddVectors(Pos, Direction, Vec_Target);
}

public void Kill_Fantasy_Loop(int client)
{
	if (h_TimerFantasyManagement[client] != INVALID_HANDLE)
	{
		KillTimer(h_TimerFantasyManagement[client]);
		h_TimerFantasyManagement[client] = INVALID_HANDLE;
		Destroy_Hale_And_Wings(client);
	}
}

static float Fantasy_Blade_Tele(int client, int weapon, float damage, float range)
{
	
	if(!Check_if_targets_exist(client, range))
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "No Targets Detected");
		return 0.0;
	}
	
	static float startPos[3];
	GetClientEyePosition(client, startPos);
//	float sizeMultiplier = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	static float endPos[3], eyeAngles[3];
	GetClientEyeAngles(client, eyeAngles);
	TR_TraceRayFilter(startPos, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayersOrEntityCombat, client);
	TR_GetEndPosition(endPos);

	// don't even try if the distance is less than 82
	float distance = GetVectorDistance(startPos, endPos);
	if (distance < 82.0)
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		return 0.0;
	}
		
	if (distance > range)
		constrainDistance(startPos, endPos, distance, range);
	else // shave just a tiny bit off the end position so our point isn't directly on top of a wall
		constrainDistance(startPos, endPos, distance, distance - 1.0);

	float abspos[3]; GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", abspos);

	if(Player_Teleport_Safe(client, endPos))
	{
		
		EmitSoundToAll(WAND_TELEPORT_SOUND, client, SNDCHAN_STATIC, 80, _, 0.5);
		float Range = 100.0;
		float Time = 0.25;
		int r, g, b;
		r = 124;
		g = 212;
		b = 230;
		spawnRing_Vectors(abspos, Range * 2.0, 0.0, 0.0, 10.0, "materials/sprites/laserbeam.vmt", r, g, b, 200, 1, 	Time, 10.0, 8.0, 1, 1.0);	
		spawnRing_Vectors(abspos, Range * 2.0, 0.0, 0.0, 40.0, "materials/sprites/laserbeam.vmt", r, g, b, 200, 1, 	Time, 10.0, 8.0, 1, 1.0);	
		spawnRing_Vectors(abspos, Range * 2.0, 0.0, 0.0, 70.0, "materials/sprites/laserbeam.vmt", r, g, b, 200, 1, 	Time, 10.0, 8.0, 1, 1.0);	
		spawnRing_Vectors(endPos, 1.0, 0.0, 0.0, 10.0, "materials/sprites/laserbeam.vmt", 		r, g, b, 200, 1, 		Time, 10.0, 8.0, 1,Range * 2.0);	
		spawnRing_Vectors(endPos, 1.0, 0.0, 0.0, 40.0, "materials/sprites/laserbeam.vmt",		r, g, b, 200, 1,		Time, 10.0, 8.0, 1,Range * 2.0);		
		spawnRing_Vectors(endPos, 1.0, 0.0, 0.0, 70.0, "materials/sprites/laserbeam.vmt", 		r, g, b, 200, 1, 		Time, 10.0, 8.0, 1,Range * 2.0);		
		
		b_LagCompNPC_No_Layers = true;
		StartLagCompensation_Base_Boss(client);
		
		i_ExplosiveProjectileHexArray[client] = EP_DEALS_CLUB_DAMAGE;
		
		Explode_Logic_Custom(damage, client, client, weapon, abspos, Range, _, _, false, _, _, _);
		Explode_Logic_Custom(damage, client, client, weapon, endPos, Range, _, _, false, _, _, _);

		Zero(HitEntitiesTeleportTrace);
		static float maxs[3];
		static float mins[3];
		maxs = view_as<float>( { 24.0, 24.0, 82.0 } );
		mins = view_as<float>( { -24.0, -24.0, 0.0 } );	
		Handle hTrace = TR_TraceHullFilterEx(abspos, endPos, mins, maxs, MASK_SOLID, TeleportDetectEnemy, client);
		delete hTrace;
		float damage_1;
		float VictimPos[3];
		float damage_reduction = 1.0;
		damage_1 = damage;
		float ExplosionDmgMultihitFalloff = EXPLOSION_AOE_DAMAGE_FALLOFF;
		float Teleport_CD = 25.0;
		
		int times_hurt = 0;

		for (int entity_traced = 0; entity_traced < MAXENTITIES; entity_traced++)
		{
			if(!HitEntitiesTeleportTrace[entity_traced])
				break;
			
			if(times_hurt>10)
				break;
			VictimPos = WorldSpaceCenter(HitEntitiesTeleportTrace[entity_traced]);

			SDKHooks_TakeDamage(HitEntitiesTeleportTrace[entity_traced], client, client, damage_1 / damage_reduction, DMG_CLUB, weapon, CalculateExplosiveDamageForce(abspos, VictimPos, 5000.0), VictimPos, false);	
			damage_reduction *= ExplosionDmgMultihitFalloff;
			Teleport_CD--;
			times_hurt++;
			fl_Shard_Ammount[client]--;
			
		}
		FinishLagCompensation_Base_boss();
		abspos[2] += 40.0;
		endPos[2] += 40.0;
		TE_SetupBeamPoints(abspos, endPos, ShortTeleportLaserIndex, 0, 0, 0, Time, 10.0, 10.0, 0, 1.0, {255,255,255,200}, 3);
		TE_SendToAll(0.0);
		return Teleport_CD;
	}
	ClientCommand(client, "playgamesound items/medshotno1.wav");
	return 0.0;
}

static bool b_I_hit_something[MAXTF2PLAYERS+1];

static bool Check_if_targets_exist(int client, float range)
{
	float look_vec[3],startPoint[3];
	b_I_hit_something[client] = false;
	Get_Fake_Forward_Vec(client, range, look_vec);
	float hullMin[3], hullMax[3];
	hullMin[0] = -7.5;
	hullMin[1] = hullMin[0];
	hullMin[2] = hullMin[0];
	hullMax[0] = -hullMin[0];
	hullMax[1] = -hullMin[1];
	hullMax[2] = -hullMin[2];
	GetClientEyePosition(client, startPoint);
	b_LagCompNPC_No_Layers = true;
	Handle trace;
	StartLagCompensation_Base_Boss(client);
	trace = TR_TraceHullFilterEx(startPoint, look_vec, hullMin, hullMax, 1073741824, BEAM_TraceUsers, client);	// 1073741824 is CONTENTS_LADDER?
	delete trace;
	FinishLagCompensation_Base_boss();
	
	if(b_I_hit_something[client])
	{
		return true;
	}
	else
	{
		return false;
	}
	
}
			  ///
			 /// Jibril's Wings and Halo
			///
			
static int i_wing_lasers[MAXTF2PLAYERS+1][6];
static int i_wing_particles[MAXTF2PLAYERS+1][5];

static int i_halo_particles[MAXTF2PLAYERS+1];
static int i_weapon_index[MAXTF2PLAYERS+1];
			
static void Create_Halo_And_Wings(int client)
{
	//Ty artvin <3
	
	Destroy_Hale_And_Wings(client);
	
	int viewmodelModel;
	viewmodelModel = EntRefToEntIndex(i_Viewmodel_PlayerModel[client]);

	if(!IsValidEntity(viewmodelModel))
		return;
		
	
	if(i_Current_Pap[client]>=1)
	{
		Create_Halo(client);
	}
	if(i_Current_Pap[client]>=2)
	{
		Create_Wings(client,viewmodelModel);
	}
	
	
		
	
}
/*
static int Fantasy_EquipItem(int client, const char[] attachment, const char[] model, const char[] anim = "", float model_size = 1.0)	//taken from npcstats.sp
{
	int item = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(item, "model", model);

	DispatchKeyValueFloat(item, "modelscale", model_size);
	
	DispatchSpawn(item);
	
	SetEntProp(item, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_PARENT_ANIMATES);
	SetEntityMoveType(item, MOVETYPE_NONE);
	SetEntProp(item, Prop_Data, "m_nNextThinkTick", -1.0);

	if(anim[0])
	{
		SetVariantString(anim);
		AcceptEntityInput(item, "SetAnimation");
	}

	SetVariantString("!activator");
	AcceptEntityInput(item, "SetParent", client);

	if(attachment[0])
	{
		SetVariantString(attachment);
		AcceptEntityInput(item, "SetParentAttachmentMaintainOffset"); 
	}	
	
	SetEntityCollisionGroup(item, 1);
	return item;
}*/

static void Create_Halo(int client)
{
	float flPos[3];
	float flAng[3];
	GetAttachment(client, "head", flPos, flAng);
	flPos[2] += 10.0;
	i_halo_particles[client]= ParticleEffectAt(flPos, "unusual_symbols_parent_ice", 0.0);
	SetParent(client, i_halo_particles[client], "head");
}
static void Create_Wings(int client, int viewmodelModel)
{
	float flPos[3];
	float flAng[3];
	GetAttachment(viewmodelModel, "flag", flPos, flAng);
	
	
	int r, g, b;
	float f_start, f_end, amp;
	r = 124;
	g = 212;
	b = 230;
	f_start = 1.0;
	f_end = 1.0;
	amp = 1.0;
	
	int particle_0 = ParticleEffectAt({0.0,0.0,0.0}, "", 0.0);	//Root, from where all the stuff goes from
	
	
	int particle_1 = ParticleEffectAt({0.0,15.0,-12.5}, "", 0.0);
	
	SetParent(particle_0, particle_1);
	
	
	//X axis- Left, Right	//this one im almost fully sure of
	//Y axis - Up down, for once
	//Z axis - Forward backwards.????????
	
	//ALL OF THESE ARE RELATIVE TO THE BACKPACK POINT THINGY, or well the viewmodel, but its easier to visualise if using the back
	//Left?
	
	int particle_2 = ParticleEffectAt({20.0, 10.5, 2.5}, "", 0.0);	//x,y,z	//Z axis IS NOT UP/DOWN, its forward and backwards. somehow
	int particle_2_1 = ParticleEffectAt({45.0, 35.0, -5.0}, "", 0.0);
	SetParent(particle_1, particle_2, "",_, true);
	SetParent(particle_2, particle_2_1, "",_, true);


	//Right? probably right?
	int particle_3 = ParticleEffectAt({-20.0, 10.5, 2.5}, "", 0.0);
	int particle_3_1 = ParticleEffectAt({-45.0, 35.0, -5.0}, "", 0.0);
	SetParent(particle_1, particle_3, "",_, true);
	SetParent(particle_3, particle_3_1, "",_, true);

	Custom_SDKCall_SetLocalOrigin(particle_0, flPos);
	SetEntPropVector(particle_0, Prop_Data, "m_angRotation", flAng); 
	SetParent(viewmodelModel, particle_0, "flag",_);

	i_wing_lasers[client][0] = ConnectWithBeamClient(particle_2, particle_1, r, g, b, f_start, f_end, amp, LASERBEAM);
	i_wing_lasers[client][1] = ConnectWithBeamClient(particle_3, particle_1, r, g, b, f_start, f_end, amp, LASERBEAM);
	i_wing_lasers[client][2] = ConnectWithBeamClient(particle_3_1, particle_3, r, g, b, f_start, f_end, amp, LASERBEAM);
	i_wing_lasers[client][3] = ConnectWithBeamClient(particle_2_1, particle_2, r, g, b, f_start, f_end, amp, LASERBEAM);
	i_wing_lasers[client][4] = ConnectWithBeamClient(particle_1, particle_3_1, r, g, b, f_start, f_end, amp, LASERBEAM);
	i_wing_lasers[client][5] = ConnectWithBeamClient(particle_1, particle_2_1, r, g, b, f_start, f_end, amp, LASERBEAM);
	
	i_wing_particles[client][0] = particle_1;
	
	i_wing_particles[client][1] = particle_2;
	i_wing_particles[client][2] = particle_2_1;
	
	i_wing_particles[client][3] = particle_3;
	i_wing_particles[client][4] = particle_3_1;
	
}
static void Destroy_Hale_And_Wings(int client)
{
	for(int i=0 ; i < 6 ; i++)
	{
		if(IsValidEntity(i_wing_lasers[client][i]))
		{
			RemoveEntity(i_wing_lasers[client][i]);
		}
	}
	for(int i=0 ; i < 5 ; i++)
	{
		if(IsValidEntity(i_wing_particles[client][i]))
		{
			RemoveEntity(i_wing_particles[client][i]);
		}
	}
	if(IsValidEntity(i_halo_particles[client]))
		RemoveEntity(i_halo_particles[client]);
		
	if(IsValidEntity(i_weapon_index[client]))
		RemoveEntity(i_weapon_index[client]);
}
			
		  ////////////////////
		 /// Slicer Logic ///
		////////////////////
		
//Horizontal Slicer
static int H_Tick_Count[MAXENTITIES];
static int H_Tick_Count_Max[MAXENTITIES];

#define H_SLICER_AMOUNT 6	//how many individual pieces of the arc are there, more = nicer curve but more traces

static int H_i_Slicer_Throttle[MAXENTITIES];

static float H_fl_target_vec[MAXENTITIES][H_SLICER_AMOUNT+2][3];
static float H_fl_starting_vec[MAXENTITIES][3];
static float H_fl_current_vec[MAXENTITIES][H_SLICER_AMOUNT+2][3];

static float H_fl_damage[MAXTF2PLAYERS + 1];

static void Horizontal_Slicer(int client, float vecTarget[3], float Range, float time, float damage)
{
	vecTarget[2] -= 10.0;
	float Vec_offset[3]; Vec_offset = vecTarget;
	float Npc_Vec[3]; Npc_Vec = WorldSpaceCenter(client);
	
	switch(GetRandomInt(1, 2))
	{
		case 1:
		{
			EmitSoundToAll(FANTASY_BLADE_SHOOT_1, client, _, 65, _, 0.75, 80);
		}
		case 2:
		{
			EmitSoundToAll(FANTASY_BLADE_SHOOT_2, client, _, 65, _, 0.75, 80);
		}
	}
	
	H_fl_damage[client] = damage;
	H_fl_starting_vec[client] = Npc_Vec;
	
	float ang_Look[3];
	
	MakeVectorFromPoints(Npc_Vec, Vec_offset, ang_Look);
	GetVectorAngles(ang_Look, ang_Look);
	
	float wide_set = 45.0;	//How big the angle difference from left to right, in this case its 90 \/ if you set it to 90 rather then 45 it would be a 180 degree swing
	
	ang_Look[1] -= wide_set;
	float type = (wide_set*2) / H_SLICER_AMOUNT;
	ang_Look[1] -= type;
	
	int buttons = GetClientButtons(client);
	bool GoingLeft = (buttons & IN_MOVELEFT )!= 0;
	bool GoingRight = (buttons & IN_MOVERIGHT) != 0;
	
	
	if(GoingRight)
	{
		ang_Look[1] -= 45.0;
	}
	else if(GoingLeft)
	{
		ang_Look[1] += 45.0;
	}
	if(ang_Look[1]>360.0)
	{
		ang_Look[1] = 0.0;
	}
	else if(ang_Look[1]<0.0)
	{
		ang_Look[1] +=360.0;
	}
		
	for(int i=1 ; i<=H_SLICER_AMOUNT+1 ; i++)
	{
		H_fl_current_vec[client][i] = Npc_Vec;
		
		
		
					
		float tempAngles[3], endLoc[3], Direction[3];
		
		tempAngles[0] = ang_Look[0];
		tempAngles[1] = ang_Look[1] + type * i;
		tempAngles[2] = 0.0;
		
		if(ang_Look[1]>360.0)
		{
			ang_Look[1] -= 360.0;
		}
							
		GetAngleVectors(tempAngles, Direction, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(Direction, Range);
		AddVectors(Npc_Vec, Direction, endLoc);
		
			
							
		
		H_fl_target_vec[client][i] = endLoc;
		
	}
	
	H_i_Slicer_Throttle[client] = 0;

	H_Tick_Count[client] = 0;
	H_Tick_Count_Max[client] = RoundToFloor(66.0*time);
	
	SDKHook(client, SDKHook_PreThink, Horizontal_Slicer_Tick);
}
static Action Horizontal_Slicer_Tick(int client)
{
	if(!IsValidEntity(client) || H_Tick_Count_Max[client]/2<H_Tick_Count[client])
	{
		H_Tick_Count[client] = 0;
		SDKUnhook(client, SDKHook_PreThink, Horizontal_Slicer_Tick);
		return Plugin_Handled;
	}
	H_Tick_Count[client]++;
	H_i_Slicer_Throttle[client]++;
	
	float Spn_Vec[3];
	Spn_Vec = H_fl_starting_vec[client];
	
	for(int i=1 ; i<=H_SLICER_AMOUNT+1 ; i++)
	{
		float Trg_Vec[3], Cur_Vec[3], vecAngles[3], Direction[3];
	
	
		Trg_Vec = H_fl_target_vec[client][i];
		Cur_Vec = H_fl_current_vec[client][i];
		
		
		float Dist = GetVectorDistance(Spn_Vec, Trg_Vec);
		float Speed = Dist / (H_Tick_Count_Max[client]/5);
		
		
		MakeVectorFromPoints(Spn_Vec, Trg_Vec, vecAngles);
		GetVectorAngles(vecAngles, vecAngles);
			
		GetAngleVectors(vecAngles, Direction, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(Direction, Speed);
		AddVectors(Cur_Vec, Direction, Cur_Vec);
		
		H_fl_current_vec[client][i] = Cur_Vec;
		
	}
	
	int colour[4];
	colour[0] = 124;
	colour[1] = 212;
	colour[2] = 230;
	colour[3] = 255;
		
	if(H_i_Slicer_Throttle[client]>2)
	{
		H_i_Slicer_Throttle[client] = 0;
		for(int i=1 ; i<=H_SLICER_AMOUNT ; i++)
		{
				Fantasy_Blade_Damage_Trace(client, H_fl_current_vec[client][i], H_fl_current_vec[client][i+1], 2.0, H_fl_damage[client]);
				
				TE_SetupBeamPoints(H_fl_current_vec[client][i], H_fl_current_vec[client][i+1], gLaser2, 0, 0, 0, 0.051, 5.0, 5.0, 0, 0.1, colour, 1);
				TE_SendToAll(0.0);
			
		}
	}
	
	
	return Plugin_Continue;
	
}

//	Verical Slier

static float fl_damage[MAXTF2PLAYERS + 1];
static int Tick_Count[MAXENTITIES];
static int Tick_Count_Max[MAXENTITIES];

static int i_Slicer_Throttle[MAXENTITIES];

static float fl_target_vec[MAXENTITIES][3];
static float fl_starting_vec[MAXENTITIES][3];
static float fl_current_vec[MAXENTITIES][3];

static void Vertical_Slicer(int client, float vecTarget[3], float time, float damage)
{
	float Vec_offset[3]; Vec_offset = vecTarget;
	float Npc_Vec[3];
	GetClientEyePosition(client, Npc_Vec);
	
	time -= 0.25;
	fl_damage[client] = damage;
	
	switch(GetRandomInt(1, 2))
	{
		case 1:
		{
			EmitSoundToAll(FANTASY_BLADE_SHOOT_1, client, _, 65, _, 0.75, 80);
		}
		case 2:
		{
			EmitSoundToAll(FANTASY_BLADE_SHOOT_2, client, _, 65, _, 0.75, 80);
		}
	}
	
	fl_target_vec[client] = Vec_offset;
	fl_starting_vec[client] = Npc_Vec;
	fl_current_vec[client] = Npc_Vec;
	
	Npc_Vec[2] -= 125.0;
	Vec_offset[2] -= 125.0;
	
	i_Slicer_Throttle[client] = 0;
	Tick_Count[client] = 0;
	Tick_Count_Max[client] = RoundToFloor(66.0*time);
	
	SDKHook(client, SDKHook_PreThink, Vertical_Slicer_Tick);
}
static Action Vertical_Slicer_Tick(int client)
{
	if(!IsValidEntity(client) || Tick_Count_Max[client]<Tick_Count[client])
	{
		Tick_Count[client] = 0;
		SDKUnhook(client, SDKHook_PreThink, Vertical_Slicer_Tick);
		return Plugin_Handled;
	}
	Tick_Count[client]++;
	i_Slicer_Throttle[client]++;
	
	float Trg_Vec[3], Cur_Vec[3], Spn_Vec[3], vecAngles[3], Direction[3], skyloc[3];
	
	Trg_Vec = fl_target_vec[client];
	Cur_Vec = fl_current_vec[client];
	Spn_Vec = fl_starting_vec[client];
	
	float Dist = GetVectorDistance(Spn_Vec, Trg_Vec);
	float Speed = Dist / Tick_Count_Max[client];
	
	
	MakeVectorFromPoints(Spn_Vec, Trg_Vec, vecAngles);
	GetVectorAngles(vecAngles, vecAngles);
		
	GetAngleVectors(vecAngles, Direction, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(Direction, Speed);
	AddVectors(Cur_Vec, Direction, Cur_Vec);
	
	int colour[4];
	colour[0] = 124;
	colour[1] = 212;
	colour[2] = 230;
	colour[3] = 255;
	
	fl_current_vec[client] = Cur_Vec;
	if(i_Slicer_Throttle[client]>2)
	{
		i_Slicer_Throttle[client] = 0;
		skyloc = Cur_Vec;
		skyloc[2] += 150.0;
		Fantasy_Blade_Damage_Trace(client, Cur_Vec, skyloc, 2.0, fl_damage[client]);
		Cur_Vec[2] -= 150.0;
		TE_SetupBeamPoints(Cur_Vec, skyloc, gLaser2, 0, 0, 0, 0.051, 5.0, 5.0, 0, 0.1, colour, 1);
		TE_SendToAll(0.0);
	}
	return Plugin_Continue;
	
}

static void Fantasy_Blade_Damage_Trace(int client, float Vec_1[3], float Vec_2[3], float radius, float dmg)
{
	
	
			static float hullMin[3];
			static float hullMax[3];

			for (int i = 1; i < MAXENTITIES; i++)
			{
				Fantasy_Blade_BEAM_HitDetected[i] = false;
			}
			
			hullMin[0] = -radius;
			hullMin[1] = hullMin[0];
			hullMin[2] = hullMin[0];
			hullMax[0] = -hullMin[0];
			hullMax[1] = -hullMin[1];
			hullMax[2] = -hullMin[2];
			Fantasy_Blade_BEAM_BuildingHit[client] = 0;
			Handle trace = TR_TraceHullFilterEx(Vec_1, Vec_2, hullMin, hullMax, 1073741824, Scientific_Witchery_BEAM_TraceUsers, client);	// 1073741824 is CONTENTS_LADDER?
			delete trace;
			
			BEAM_Targets_Hit[client] = 1.0;
			
			for (int victim = 1; victim < MAXENTITIES; victim++)
			{
				if (Fantasy_Blade_BEAM_HitDetected[victim] && GetEntProp(client, Prop_Send, "m_iTeamNum") != GetEntProp(victim, Prop_Send, "m_iTeamNum"))
				{
					SDKHooks_TakeDamage(victim, client, client, dmg/BEAM_Targets_Hit[client], DMG_CLUB, -1, NULL_VECTOR, Vec_1);	// 2048 is DMG_NOGIB?
					BEAM_Targets_Hit[client] *= LASER_AOE_DAMAGE_FALLOFF;
				}
			}

}
static bool Scientific_Witchery_BEAM_TraceUsers(int entity, int contentsMask, int client)
{
	if (IsEntityAlive(entity) && Fantasy_Blade_BEAM_BuildingHit[client]<11)
	{
		if(fl_trace_target_timeout[client][entity]<=GetGameTime())
		{
			fl_trace_target_timeout[client][entity] = GetGameTime() + 0.25;
			Fantasy_Blade_BEAM_BuildingHit[client]++;
			Fantasy_Blade_BEAM_HitDetected[entity] = true;
		}
	}
	return false;
}
static bool BEAM_TraceUsers(int entity, int contentsMask, int client)
{
	if (IsValidEntity(entity))
	{
		entity = Target_Hit_Wand_Detection(client, entity);
		if(0 < entity)
		{
			b_I_hit_something[client] = true;
		}
	}
	return false;
}