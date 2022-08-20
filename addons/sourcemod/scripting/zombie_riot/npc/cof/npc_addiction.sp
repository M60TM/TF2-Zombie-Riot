#define ADDICTION_LIGHTNING_RANGE 150.0

#define ADDICTION_CHARGE_TIME 4.1
#define ADDICTION_CHARGE_SPAN 1.5

static char g_HurtSounds[][] =
{
	"cof/addiction/hurt1.mp3",
	"cof/addiction/hurt2.mp3"
};

static char g_PassiveSounds[][] =
{
	"cof/addiction/passive1.mp3",
	"cof/addiction/passive2.mp3"
};

static char g_ThunderSounds[][] =
{
	"cof/addiction/thunder_attack1.wav",
	"cof/addiction/thunder_attack2.wav",
	"cof/addiction/thunder_attack3.wav"
};

static char g_MeleeHitSounds[][] =
{
	"weapons/halloween_boss/knight_axe_hit.wav",
};

static char g_MeleeMissSounds[][] =
{
	"weapons/cbar_miss1.wav",
};

public void Addiction_OnMapStart_NPC()
{
	for (int i = 0; i < (sizeof(g_MeleeMissSounds));	   i++) { PrecacheSound(g_MeleeMissSounds[i]);	   }
	for (int i = 0; i < (sizeof(g_MeleeHitSounds));	   i++) { PrecacheSound(g_MeleeHitSounds[i]);	   }
}
methodmap Addicition < CClotBody
{
	public void PlayIdleSound()
	{
		if(this.m_flNextIdleSound > GetGameTime())
			return;
		
		this.m_flNextIdleSound = GetGameTime() + 3.5;
		EmitSoundToAll(g_PassiveSounds[GetRandomInt(0, sizeof(g_PassiveSounds) - 1)], this.index);
	}
	public void PlayHurtSound()
	{
		if(this.m_flNextHurtSound > GetGameTime())
			return;
		
		this.m_flNextHurtSound = GetGameTime() + 2.0;
		
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayMeleeHitSound() 
	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}

	public void PlayMeleeMissSound()
	{
		EmitSoundToAll(g_MeleeMissSounds[GetRandomInt(0, sizeof(g_MeleeMissSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayDeathSound()
	{
		EmitSoundToAll("cof/addiction/death.mp3");
		EmitSoundToAll("cof/addiction/death.mp3");
	}
	public void PlayIntroSound()
	{
		EmitSoundToAll("cof/simon/Intro.mp3");
		EmitSoundToAll("cof/simon/Intro.mp3");
	}
	public void PlayAttackSound()
	{
		this.m_flNextHurtSound = GetGameTime() + 2.0;
		EmitSoundToAll("cof/simon/attack.mp3", this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayLightningSound()
	{
		EmitSoundToAll(g_ThunderSounds[GetRandomInt(0, sizeof(g_ThunderSounds) - 1)], this.index, SNDCHAN_AUTO, 120, _, BOSS_ZOMBIE_VOLUME);
		EmitSoundToAll(g_ThunderSounds[GetRandomInt(0, sizeof(g_ThunderSounds) - 1)], this.index, SNDCHAN_AUTO, 120, _, BOSS_ZOMBIE_VOLUME);
		EmitSoundToAll(g_ThunderSounds[GetRandomInt(0, sizeof(g_ThunderSounds) - 1)], this.index, SNDCHAN_AUTO, 120, _, BOSS_ZOMBIE_VOLUME);
	}
	
	public Addicition(int client, float vecPos[3], float vecAng[3], bool ally, const char[] data)
	{
		Addicition npc = view_as<Addicition>(CClotBody(vecPos, vecAng, "models/zombie_riot/aom/david_monster.mdl", "1.15", data[0] == 'f' ? "250000" : "10000", ally, false, false, true));
		i_NpcInternalId[npc.index] = THEADDICTION;
		
		npc.m_iState = -1;
		npc.SetActivity("ACT_SPAWN");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		
		SDKHook(npc.index, SDKHook_OnTakeDamage, Addicition_ClotDamaged);
		SDKHook(npc.index, SDKHook_Think, Addicition_ClotThink);
		
		npc.m_bisWalking = false;
		npc.m_bThisNpcIsABoss = true;
		npc.m_flSpeed = 100.0;
		npc.m_iTarget = -1;
		npc.m_flNextMeleeAttack = 0.0;
		npc.m_flAttackHappens = 0.0;
		npc.m_flRangedSpecialDelay = 1.0;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_flReloadDelay = GetGameTime() + 2.0;
		npc.m_flNextRangedSpecialAttack = npc.m_flReloadDelay + 0.0;
		npc.m_bLostHalfHealth = false;
		npc.m_bDissapearOnDeath = true;
		npc.m_iChanged_WalkCycle = 0;
		npc.m_flNextThinkTime = GetGameTime() + 2.5;
		
		if(data[0])
			npc.SetHalfLifeStats();
		
		return npc;
	}
	
	public void SetHalfLifeStats()
	{
		this.m_bLostHalfHealth = true;
		this.m_flSpeed = 220.0;
	}
}
/*
public void Addicition_ClotThink(int iNPC)
{
	Addicition npc = view_as<Addicition>(iNPC);
	
	float gameTime = GetGameTime();
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.04;
	npc.Update();
	npc.PlayIdleSound();
	
	if(npc.m_bLostHalfHealth)
	{
		npc.m_flMeleeArmor = 1.0 - Pow(0.98, float(Zombies_Currently_Still_Ongoing));
		npc.m_flRangedArmor = npc.m_flMeleeArmor;
	}
	else if(GetEntProp(npc.index, Prop_Data, "m_iHealth") < GetEntProp(npc.index, Prop_Data, "m_iMaxHealth")/2)
	{
		npc.SetHalfLifeStats();
	}
	
	if(npc.m_flRangedSpecialDelay > 1.0)
	{
		if(npc.m_flRangedSpecialDelay < gameTime)
		{
			npc.m_flRangedSpecialDelay = 1.0;
			
			float vecMe[3];
			GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", vecMe); 
			vecMe[2] += 45;
			
			makeexplosion(npc.index, npc.index, vecMe, "", 2000, 1000, 1000.0);
			
			npc.m_flRangedSpecialDelay = 0.0;
			npc.PlayLightningSound();
		}
		
		return;
	}
	
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < gameTime)
		{
			npc.m_flAttackHappens = 0.0;
			
			if(IsValidEnemy(npc.index, npc.m_iTarget))
			{
				Handle swingTrace;
				npc.FaceTowards(WorldSpaceCenter(npc.m_iTarget), 15000.0);
				if(npc.DoSwingTrace(swingTrace, npc.m_iTarget))
				{
					int target = TR_GetEntityIndex(swingTrace);	
					
					float vecHit[3];
					TR_GetEndPosition(vecHit, swingTrace);
					
					if(target > 0) 
					{
						SDKHooks_TakeDamage(target, npc.index, npc.index, 600.0, DMG_CLUB);
					}
				}
				delete swingTrace;
			}
		}
		
		return;
	}
	
	if(npc.m_flReloadDelay > gameTime)
	{
		if(npc.m_bPathing)
		{
			PF_StopPathing(npc.index);
			npc.m_bPathing = false;
		}
		return;
	}
	
	if(npc.m_flRangedSpecialDelay == 1.0)
		npc.m_flRangedSpecialDelay = 0.0;
	
	if(npc.m_flGetClosestTargetTime < gameTime)
	{
		npc.m_flGetClosestTargetTime = gameTime + 0.5;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}
	
	if(npc.m_iTarget > 0)
	{
		if(!IsValidEnemy(npc.index, npc.m_iTarget))
		{
			//Stop chasing dead target.
			npc.m_iTarget = 0;
			npc.m_flGetClosestTargetTime = 0.0;
		}
		else
		{
			float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
			
			float distance = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
			if(distance < 40000.0 && npc.m_flNextMeleeAttack < gameTime)
			{
				npc.FaceTowards(vecTarget, 15000.0);
				
				npc.SetActivity("ACT_IDLE");
				npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE");
				npc.PlayAttackSound();
				
				npc.m_flAttackHappens = gameTime + 0.4;
				npc.m_flReloadDelay = gameTime + 0.6;
				npc.m_flNextMeleeAttack = gameTime + 1.3;
				
				if(npc.m_bPathing)
				{
					PF_StopPathing(npc.index);
					npc.m_bPathing = false;
				}
			}
			else if(distance < 200000.0 && npc.m_flNextRangedSpecialAttack < gameTime)
			{
				npc.SetActivity("ACT_LIGHTNING");
				
				npc.m_flRangedSpecialDelay = gameTime + 3.0;
				npc.m_flReloadDelay = gameTime + 5.0;
				npc.m_flNextRangedSpecialAttack = gameTime + 30.0;
				
				if(npc.m_bPathing)
				{
					PF_StopPathing(npc.index);
					npc.m_bPathing = false;
				}
			}
			else
			{
				npc.SetActivity(npc.m_bLostHalfHealth ? "ACT_RUN_HALFLIFE" : "ACT_RUN");
				
				if(distance > 29000.0)
				{
					PF_SetGoalEntity(npc.index, npc.m_iTarget);
				}
				else
				{
					float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, npc.m_iTarget);
					PF_SetGoalVector(npc.index, vPredictedPos);
				}
				npc.StartPathing();
			}
			
			return;
		}
	}
	
	if(npc.m_bPathing)
	{
		PF_StopPathing(npc.index);
		npc.m_bPathing = false;
	}
	
	npc.m_flGetClosestTargetTime = 0.0;
	npc.SetActivity("ACT_IDLE");
}
*/

public void Addicition_ClotThink(int iNPC)
{
	Addicition npc = view_as<Addicition>(iNPC);
	/*
	if(npc.m_flNextDelayTime > GetGameTime())
	{
		return;
	}
	
	npc.m_flNextDelayTime = GetGameTime() + DEFAULT_UPDATE_DELAY_FLOAT;
	*/
	npc.Update();
	
	
	if(npc.m_bLostHalfHealth)
	{
		float Armor_Stats = 1.0 * Pow(0.98, float(Zombies_Currently_Still_Ongoing))
		
		if(Armor_Stats > 1.0)
		{
			Armor_Stats = 1.0;
		}
		else if(Armor_Stats < 0.4)
		{
			Armor_Stats = 0.4;
		}
		
		npc.m_flMeleeArmor = Armor_Stats;
		npc.m_flRangedArmor = Armor_Stats;
	}
	else if(GetEntProp(npc.index, Prop_Data, "m_iHealth") < GetEntProp(npc.index, Prop_Data, "m_iMaxHealth")/2)
	{
		npc.SetHalfLifeStats();
	}
	
	if(npc.m_blPlayHurtAnimation)
	{
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}
	
	if(npc.m_flNextThinkTime > GetGameTime())
	{
		return;
	}
	
	npc.m_flNextThinkTime = GetGameTime() + 0.1;

	
	if(npc.m_flGetClosestTargetTime < GetGameTime())
	{
		npc.m_iTarget = GetClosestTarget(npc.index, true);
		npc.m_flGetClosestTargetTime = GetGameTime() + 1.0;
	}
	
	if(IsValidEnemy(npc.index, npc.m_iTarget))
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
			
		float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
				
		if(flDistanceToTarget < npc.GetLeadRadius())
		{
			float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, npc.m_iTarget);
			PF_SetGoalVector(npc.index, vPredictedPos);
		}
		else
		{
			PF_SetGoalEntity(npc.index, npc.m_iTarget);
		}
		
		if(npc.m_bLostHalfHealth)
		{
			if(npc.m_iChanged_WalkCycle != 2 && npc.m_flReloadDelay < GetGameTime()) 	
			{
				npc.SetActivity("ACT_RUN_HALFLIFE");
				npc.m_iChanged_WalkCycle = 2;
				npc.StartPathing();
				npc.m_bisWalking = true;
			}		
		}
		else
		{
			if(npc.m_iChanged_WalkCycle != 1 && npc.m_flReloadDelay < GetGameTime()) 	
			{
				npc.SetActivity("ACT_RUN");
				npc.m_iChanged_WalkCycle = 1;
				npc.StartPathing();
				npc.m_bisWalking = true;
			}
		}
		
		if(npc.m_bLostHalfHealth)
		{
			if(flDistanceToTarget < 200000.0 && npc.m_flNextRangedSpecialAttack < GetGameTime())
			{
				int Enemy_I_See;
				
				Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
				//Target close enough to hit
				if(IsValidEnemy(npc.index, npc.m_iTarget) && npc.m_iTarget == Enemy_I_See)
				{
					if(npc.m_iChanged_WalkCycle != 3) 	
					{
						npc.SetActivity("ACT_LIGHTNING");
						npc.m_bisWalking = false;
						npc.m_iChanged_WalkCycle = 3;
						PF_StopPathing(npc.index);
						npc.m_bPathing = false;
					}
					npc.PlayLightningSound();
					
					float vEnd[3];
					
					vEnd = GetAbsOrigin(npc.m_iTarget);
					Handle pack;
					CreateDataTimer(ADDICTION_CHARGE_SPAN, Smite_Timer_Addiction, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(pack, EntIndexToEntRef(npc.index));
					WritePackFloat(pack, 0.0);
					WritePackFloat(pack, vEnd[0]);
					WritePackFloat(pack, vEnd[1]);
					WritePackFloat(pack, vEnd[2]);
					WritePackFloat(pack, 1000.0);
						
					spawnRing_Vectors(vEnd, ADDICTION_LIGHTNING_RANGE * 2.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 50, 50, 200, 1, ADDICTION_CHARGE_TIME, 6.0, 0.1, 1, 1.0);
					npc.m_flRangedSpecialDelay = GetGameTime() + 3.0;
					npc.m_flReloadDelay = GetGameTime() + 5.0;
					npc.m_flNextRangedSpecialAttack = GetGameTime() + 15.0;
					npc.m_flNextMeleeAttack = GetGameTime() + 5.0;
				}
			}
		}
		if(flDistanceToTarget < 10000.0 || npc.m_flAttackHappenswillhappen)
		{
			if(npc.m_flNextMeleeAttack < GetGameTime() || npc.m_flAttackHappenswillhappen)
			{
				if (!npc.m_flAttackHappenswillhappen)
				{
					npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE");
					npc.PlayAttackSound();
					npc.m_flAttackHappens = GetGameTime()+0.3;
					npc.m_flAttackHappens_bullshit = GetGameTime()+0.43;
					npc.m_flAttackHappenswillhappen = true;
					npc.m_flNextMeleeAttack = GetGameTime() + 1.2;
				}
				
				if (npc.m_flAttackHappens < GetGameTime() && npc.m_flAttackHappens_bullshit >= GetGameTime() && npc.m_flAttackHappenswillhappen)
				{
					Handle swingTrace;
					npc.FaceTowards(vecTarget, 20000.0);
					if(npc.DoSwingTrace(swingTrace, npc.m_iTarget,_,_,_,_, 1))
					{
						int target = TR_GetEntityIndex(swingTrace);	
						float vecHit[3];
						TR_GetEndPosition(vecHit, swingTrace);
						if(target > 0) 
						{
							if(target <= MaxClients)
								SDKHooks_TakeDamage(target, npc.index, npc.index, 150.0, DMG_CLUB, -1, _, vecHit);
							else
								SDKHooks_TakeDamage(target, npc.index, npc.index, 500.0, DMG_CLUB, -1, _, vecHit);					
							
							npc.PlayMeleeHitSound();
						}
						else
						{
							npc.PlayMeleeMissSound();
						}
					}
					delete swingTrace;
					npc.m_flAttackHappenswillhappen = false;
				}
				else if (npc.m_flAttackHappens_bullshit < GetGameTime() && npc.m_flAttackHappenswillhappen)
				{
					npc.m_flAttackHappenswillhappen = false;
				}
			}
			
		}
	}
	else
	{
//		PF_StopPathing(npc.index);
//		npc.m_bPathing = false;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index, true);
	}
	npc.PlayIdleSound();
}
	
public Action Addicition_ClotDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
//	if(damage < 9999999.0 && view_as<Addicition>(victim).m_flRangedSpecialDelay == 1.0)
//		return Plugin_Handled;
	
	view_as<Addicition>(victim).PlayHurtSound();
	return Plugin_Continue;
}

public void Addicition_NPCDeath(int entity)
{
	Addicition npc = view_as<Addicition>(entity);
	
	SDKUnhook(npc.index, SDKHook_OnTakeDamage, Addicition_ClotDamaged);
	SDKUnhook(npc.index, SDKHook_Think, Addicition_ClotThink);
	
	PF_StopPathing(npc.index);
	npc.m_bPathing = false;
	
	npc.PlayDeathSound();
	
	int entity_death = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(entity_death))
	{
		float pos[3], angles[3];
		GetEntPropVector(npc.index, Prop_Data, "m_angRotation", angles);
		GetEntPropVector(npc.index, Prop_Send, "m_vecOrigin", pos);
		
		TeleportEntity(entity_death, pos, angles, NULL_VECTOR);
		
//		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		DispatchKeyValue(entity_death, "model", "models/zombie_riot/aom/david_monster.mdl");
		DispatchKeyValue(entity_death, "skin", "0");
		
		DispatchSpawn(entity_death);
		
		SetEntPropFloat(entity_death, Prop_Send, "m_flModelScale", 1.15); 
		SetEntityCollisionGroup(entity_death, 2);
		SetVariantString("death");
		AcceptEntityInput(entity_death, "SetAnimation");
		
		CreateTimer(1.0, Timer_RemoveEntityOverlord, EntIndexToEntRef(entity_death), TIMER_FLAG_NO_MAPCHANGE);
	}
}


public Action Smite_Timer_Addiction(Handle Smite_Logic, DataPack pack)
{
	ResetPack(pack);
	int entity = EntRefToEntIndex(ReadPackCell(pack));
	
	if (!IsValidEntity(entity))
	{
		return Plugin_Stop;
	}
		
	float NumLoops = ReadPackFloat(pack);
	float spawnLoc[3];
	for (int GetVector = 0; GetVector < 3; GetVector++)
	{
		spawnLoc[GetVector] = ReadPackFloat(pack);
	}
	
	float damage = ReadPackFloat(pack);
	
	if (NumLoops >= ADDICTION_CHARGE_TIME)
	{
		float secondLoc[3];
		for (int replace = 0; replace < 3; replace++)
		{
			secondLoc[replace] = spawnLoc[replace];
		}
		
		for (int sequential = 1; sequential <= 5; sequential++)
		{
			spawnRing_Vectors(secondLoc, 1.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 50, 50, 120, 1, 0.33, 6.0, 0.4, 1, (ADDICTION_LIGHTNING_RANGE * 5.0)/float(sequential));
			secondLoc[2] += 150.0 + (float(sequential) * 20.0);
		}
		
		secondLoc[2] = 1500.0;
		
		spawnBeam(0.8, 255, 50, 50, 255, "materials/sprites/laserbeam.vmt", 4.0, 6.2, _, 2.0, secondLoc, spawnLoc);	
		spawnBeam(0.8, 255, 50, 50, 200, "materials/sprites/lgtning.vmt", 4.0, 5.2, _, 2.0, secondLoc, spawnLoc);	
		spawnBeam(0.8, 255, 50, 50, 200, "materials/sprites/lgtning.vmt", 3.0, 4.2, _, 2.0, secondLoc, spawnLoc);	
		
		EmitAmbientSound("cof/addiction/lightning_hit.mp3", spawnLoc, _, 120);
		EmitAmbientSound("cof/addiction/lightning_hit.mp3", spawnLoc, _, 120);
		EmitAmbientSound("cof/addiction/lightning_hit.mp3", spawnLoc, _, 120);
		EmitAmbientSound("cof/addiction/lightning_hit.mp3", spawnLoc, _, 120);
		
		DataPack pack_boom = new DataPack();
		pack_boom.WriteFloat(spawnLoc[0]);
		pack_boom.WriteFloat(spawnLoc[1]);
		pack_boom.WriteFloat(spawnLoc[2]);
		pack_boom.WriteCell(0);
		RequestFrame(MakeExplosionFrameLater, pack_boom);
		
		Explode_Logic_Custom(damage, entity, entity, -1, spawnLoc, ADDICTION_LIGHTNING_RANGE,_,0.9,false);
		
		return Plugin_Stop;
	}
	else
	{
		spawnRing_Vectors(spawnLoc, ADDICTION_LIGHTNING_RANGE * 2.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 50, 50, 120, 1, 0.33, 6.0, 0.1, 1, 1.0);
	//	EmitAmbientSound(SOUND_WAND_LIGHTNING_ABILITY_PAP_CHARGE, spawnLoc, _, 60, _, _, GetRandomInt(80, 110));
		
		ResetPack(pack);
		WritePackCell(pack, EntIndexToEntRef(entity));
		WritePackFloat(pack, NumLoops + ADDICTION_CHARGE_TIME);
		WritePackFloat(pack, spawnLoc[0]);
		WritePackFloat(pack, spawnLoc[1]);
		WritePackFloat(pack, spawnLoc[2]);
		WritePackFloat(pack, damage);
	}
	
	return Plugin_Continue;
}

static void spawnBeam(float beamTiming, int r, int g, int b, int a, char sprite[PLATFORM_MAX_PATH], float width=2.0, float endwidth=2.0, int fadelength=1, float amp=15.0, float startLoc[3] = {0.0, 0.0, 0.0}, float endLoc[3] = {0.0, 0.0, 0.0})
{
	int color[4];
	color[0] = r;
	color[1] = g;
	color[2] = b;
	color[3] = a;
		
	int SPRITE_INT = PrecacheModel(sprite, false);

	TE_SetupBeamPoints(startLoc, endLoc, SPRITE_INT, 0, 0, 0, beamTiming, width, endwidth, fadelength, amp, color, 0);
	
	TE_SendToAll();
}

static void spawnRing_Vectors(float center[3], float range, float modif_X, float modif_Y, float modif_Z, char sprite[255], int r, int g, int b, int alpha, int fps, float life, float width, float amp, int speed, float endRange = -69.0) //Spawns a TE beam ring at a client's/entity's location
{
	center[0] += modif_X;
	center[1] += modif_Y;
	center[2] += modif_Z;
			
	int ICE_INT = PrecacheModel(sprite);
		
	int color[4];
	color[0] = r;
	color[1] = g;
	color[2] = b;
	color[3] = alpha;
		
	if (endRange == -69.0)
	{
		endRange = range + 0.5;
	}
	
	TE_SetupBeamRingPoint(center, range, endRange, ICE_INT, ICE_INT, 0, fps, life, width, amp, color, speed, 0);
	TE_SendToAll();
}