#pragma semicolon 1
#pragma newdecls required

static bool MaxMiniBoss;
static int CurrentModifActive = 0;

#define CHAOS_INTRUSION 1
#define OLD_TIMES 2

void Modifier_MiniBossSpawn(bool &spawns)
{
	if(MaxMiniBoss)
		spawns = true;
}

public void Modifier_Collect_MaxMiniBoss()
{
	MaxMiniBoss = true;
}

public void Modifier_Remove_MaxMiniBoss()
{
	MaxMiniBoss = false;
}

public void Modifier_Collect_ChaosIntrusion()
{
	CurrentModifActive = CHAOS_INTRUSION;
}

public void Modifier_Remove_ChaosIntrusion()
{
	CurrentModifActive = 0;
}

public void Modifier_Collect_OldTimes()
{
	CurrentModifActive = OLD_TIMES;
}

public void Modifier_Remove_OldTimes()
{
	CurrentModifActive = 0;
}


public void ZRModifs_ChaosIntrusionNPC(int iNpc)
{
	fl_Extra_Damage[iNpc] *= 1.12;
	int Health = GetEntProp(iNpc, Prop_Data, "m_iMaxHealth");
	SetEntProp(iNpc, Prop_Data, "m_iHealth", RoundToCeil(float(Health) * 1.30));
	SetEntProp(iNpc, Prop_Data, "m_iMaxHealth", RoundToCeil(float(Health) * 1.30));
	fl_GibVulnerablity[iNpc] *= 1.30;
	fl_Extra_Speed[iNpc] *= 1.05;
}


public void ZRModifs_OldTimesNPC(int iNpc)
{
	fl_Extra_Damage[iNpc] *= 1.20;
	int Health = GetEntProp(iNpc, Prop_Data, "m_iMaxHealth");
	SetEntProp(iNpc, Prop_Data, "m_iHealth", RoundToCeil(float(Health) * 1.50));
	SetEntProp(iNpc, Prop_Data, "m_iMaxHealth", RoundToCeil(float(Health) * 1.50));
	fl_GibVulnerablity[iNpc] *= 1.50;
	fl_Extra_Speed[iNpc] *= 1.07;
}

float ZRModifs_MaxSpawnsAlive()
{
	switch(CurrentModifActive)
	{
		case CHAOS_INTRUSION:
		{
			return 1.10;
		}
		case OLD_TIMES:
		{
			return 1.20;
		}
	}
	return 1.0;
}

float ZRModifs_SpawnSpeedModif()
{
	switch(CurrentModifActive)
	{
		case CHAOS_INTRUSION:
		{
			return 0.85;
		}
		case OLD_TIMES:
		{
			return 0.75;
		}
	}
	return 1.0;
}

float ZRModifs_MaxSpawnWaveModif()
{
	switch(CurrentModifActive)
	{
		case CHAOS_INTRUSION:
		{
			return 1.35;
		}
		case OLD_TIMES:
		{
			return 1.45;
		}
	}
	return 1.0;
}

void ZRModifs_CharBuffToAdd(char[] data)
{
	switch(CurrentModifActive)
	{
		case CHAOS_INTRUSION:
		{
			FormatEx(data, 6, "C");
		}
		case OLD_TIMES:
		{
			FormatEx(data, 6, "O");
		}
	}
}

int CurrentModifOn()
{
	return CurrentModifActive;
}
