#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>

#pragma newdecls required
#pragma dynamic 131072

#define PLUGIN_VERSION "0.1.0"
#define FADE_IN  0x0001
#define FADE_OUT 0x0002

#define PLUGIN_PREFIX "{green}[ {red}Nuke {green}] "

bool g_bIsEnabled = true;
bool g_bIsNuking = false;

int g_iNukeTimer;
int g_iWaitTimer; 
int g_iPreviousNukeLauncher;

char g_sNukeTeam[5];

float g_fNukePosition[3];

// Textures
int g_iWhiteSprite;
int g_iHaloSprite;
int g_iExplosionSprite;

public Plugin myinfo = 
{
	name = "Nuke",
	author = "gemidyne",
	description = "Nuke plugin for TF2",
	version = PLUGIN_VERSION,
	url = "https://www.gemidyne.com/"
}

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	RegConsoleCmd("sm_nuke", Command_Nuke);
}

public void OnMapStart()
{
	g_iWhiteSprite = PrecacheModel("materials/sprites/white.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_iExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");

	PrecacheGeneric("dooms_nuke_collumn");
	PrecacheGeneric("base_destroyed_smoke_doomsday");
	PrecacheGeneric("flash_doomsday");
	
	PrecacheSound("ambient/explosions/explode_8.wav", true);
	PrecacheSound("ambient/machines/aircraft_distant_flyby3.wav", true);
	PrecacheSound("ambient/explosions/explode_6.wav", true);
	PrecacheSound("ambient/alarms/siren.wav", true);
	PrecacheSound("weapons/mortar/mortar_shell_incomming1.wav", true);
	PrecacheSound("weapons/stinger_fire1.wav", true);
	PrecacheSound("ambient/atmosphere/terrain_rumble1.wav", true);
	PrecacheSound("items/cart_explode_trigger.wav", true);
	PrecacheSound("ambient/atmosphere/city_skypass1.wav", true);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_bIsNuking)
	{
		g_iNukeTimer = -1;
	}

	return Plugin_Handled;
}

public Action Command_Nuke(int client, int args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if (!g_bIsEnabled)
	{
		RespondToCommand(client, "Nuke is disabled.");
		return Plugin_Handled;
	}

	if (g_bIsNuking)
	{
		RespondToCommand(client, "A Nuke has already been launched.");
		return Plugin_Handled;
	}

	if (client == g_iPreviousNukeLauncher)
	{
		RespondToCommand(client, "You launched a nuke recently and cannot launch another one just now.");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client))
	{
		RespondToCommand(client, "You must be alive to launch a Nuke.");
		return Plugin_Handled;
	}

	if (g_iWaitTimer > 0) 
	{
		RespondToCommand(client, "Nuke has been launched recently, please wait a bit before launching another.");
		return Plugin_Handled;
	}
	
	GetClientAbsOrigin(client, g_fNukePosition);

	TE_SetupBeamRingPoint(g_fNukePosition, 0.0, 2048.0, g_iWhiteSprite, g_iHaloSprite, 0, 10, 3.0, 1.0, 0.5, {188,220,255,255}, 10, 0);
  	TE_SendToAll();

	g_fNukePosition[2] += 25.0;

	if (GetClientTeam(client) == 2)
	{
		strcopy(g_sNukeTeam, sizeof(g_sNukeTeam), "Red");
	}
	else if (GetClientTeam(client) == 3)
	{
		strcopy(g_sNukeTeam, sizeof(g_sNukeTeam), "Blue");
	}

	g_iPreviousNukeLauncher = client;
	
	CPrintToChatAllEx(client, "%s{teamcolor}%N {default}has launched {teamcolor}%s Team{default}'s Nuke at %f, %f, %f!", PLUGIN_PREFIX, client, g_sNukeTeam, g_fNukePosition[0], g_fNukePosition[1], g_fNukePosition[2]);
	PrintCenterTextAll("%N has launched %s Team's Nuke at %f, %f, %f!", client, g_sNukeTeam, g_fNukePosition[0], g_fNukePosition[1], g_fNukePosition[2]);
	PrintToServer("[Nuke] %N has launched a nuke on the server at %f, %f, %f", client, g_fNukePosition[0], g_fNukePosition[1], g_fNukePosition[2]);
	EmitSoundToAll("weapons/stinger_fire1.wav");

	CreateTimer(2.0, Timer_Nuke);
	CreateTimer(3.0, Timer_Wait);

	g_bIsNuking = true;
	g_iNukeTimer = 12; 
	g_iWaitTimer = 230;

	return Plugin_Handled;
}

public Action Timer_Wait(Handle hTimer)
{
	if (g_iWaitTimer > 0)
	{
		g_iWaitTimer--;
		CreateTimer(1.0, Timer_Wait);
	}

	return Plugin_Handled;
}

public Action Timer_Nuke(Handle hTimer)
{
	if (!g_bIsNuking)
	{
		g_iNukeTimer = -1;
	}

	if (g_iNukeTimer > -1)
	{
		g_iNukeTimer -= 1;
		CreateTimer(1.0, Timer_Nuke);
	}

	if (g_iNukeTimer >= 0)
	{
		if (g_iNukeTimer == 6)
		{
			EmitSoundToAll("ambient/machines/aircraft_distant_flyby3.wav");
			EmitSoundToAll("ambient/machines/aircraft_distant_flyby3.wav");
		}

		if (g_iNukeTimer > 0 && g_iNukeTimer < 11)
		{
			if (g_iNukeTimer == 10)
			{
				EmitSoundToAll("ambient/alarms/siren.wav");
			}

			if (g_iNukeTimer != 1)
			{
				PrintCenterTextAll("%s Team's Nuke will land in %d seconds.", g_sNukeTeam, g_iNukeTimer);
			}
			else
			{
				PrintCenterTextAll("%s Team's Nuke will land in %d second.", g_sNukeTeam, g_iNukeTimer);
			}
			
			TE_SetupBeamRingPoint(g_fNukePosition, 0.0, 2048.0, g_iWhiteSprite, g_iHaloSprite, 0, 10, 1.0, 1.0, 0.5, {188,220,255,255}, 10, 0);
  			TE_SendToAll();
		}

		switch (g_iNukeTimer)
		{
			case 3:
			{
				EmitSoundToAll("ambient/atmosphere/city_skypass1.wav");
			}

			case 2: 
			{
				EmitSoundToAll("items/cart_explode_trigger.wav");
			}

			case 1:
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i))
					{
						EmitSoundToClient(i, "weapons/mortar/mortar_shell_incomming1.wav");
						EmitSoundToClient(i, "weapons/mortar/mortar_shell_incomming1.wav");
						EmitSoundToClient(i, "ambient/atmosphere/terrain_rumble1.wav");
						EmitSoundToClient(i, "ambient/atmosphere/terrain_rumble1.wav");

						if (IsPlayerAlive(i))
						{
							DoScreenShake(i, 105.0, 9000.0, 10.0, 150.0);
						} 
					}
				}
			}

			case 0: 
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i))
					{
						StopSound(i, SNDCHAN_AUTO, "ambient/alarms/siren.wav");
						StopSound(i, SNDCHAN_AUTO, "ambient/alarms/siren.wav");
						StopSound(i, SNDCHAN_AUTO, "ambient/alarms/siren.wav");
						StopSound(i, SNDCHAN_AUTO, "ambient/alarms/siren.wav");

						if (IsPlayerAlive(i)) 
						{
							DoScreenShake(i, 255.0, 9000.0, 10.0, 150.0);
						}

						EmitSoundToClient(i, "ambient/explosions/explode_6.wav");
						EmitSoundToClient(i, "ambient/explosions/explode_6.wav");
						PrintCenterText(i, "%s Team's Nuke has detonated!", g_sNukeTeam);
					}
				}

				DoScreenFade(1000, 1000, {250,250,250,255});
				Detonate(g_fNukePosition);
				g_bIsNuking = false;
			}
		}
	}

	return Plugin_Handled;
}

void Detonate(float nukePosition[3])
{
	float pos[3];
	float Flash[3];
	float Collumn[3];
	pos[0] = nukePosition[0];
	pos[1] = nukePosition[1];
	pos[2] = nukePosition[2];
	
	Flash[0] = pos[0];
	Flash[1] = pos[1];
	Flash[2] = pos[2];
	
	Collumn[0] = pos[0];
	Collumn[1] = pos[1];
	Collumn[2] = pos[2];
	
	pos[2] += 6.0;
	Flash[2] += 236.0;
	Collumn[2] += 1652.0;

	CreateParticle(pos, "base_destroyed_smoke_doomsday", 30.0);
	CreateParticle(Flash, "flash_doomsday", 10.0);
	CreateParticle(Collumn, "dooms_nuke_collumn", 30.0);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}

		float eyePos[3];

		GetClientEyePosition(i, eyePos);
		
		float distance = GetVectorDistance(nukePosition, eyePos);

		if (distance > 2048.0)
		{
			continue;
		}
				
		int damage = 2048;
		damage = RoundToFloor(damage * (2048 - distance) / 2048);
		SDKHooks_TakeDamage(i, g_iPreviousNukeLauncher, g_iPreviousNukeLauncher, float(damage), DMG_BLAST | DMG_RADIATION | DMG_ALWAYSGIB);
		
		if (g_iExplosionSprite > -1)
		{
			TE_SetupExplosion(nukePosition, g_iExplosionSprite, 0.05, 1, 0, 1, 1);
			TE_SendToAll();	
		}
	}
}

void DoScreenFade(int duration, int time, const int color[4])
{
	Handle message = StartMessageAll("Fade");

	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, time);
		BfWriteShort(message, FADE_IN);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
 		BfWriteByte(message, color[3]);
		EndMessage();
	}
}

void DoScreenShake(int client, float amplitude, float radius, float duration, float frequency)
{
	int entity = CreateEntityByName("env_shake");

	if (entity != -1)
	{
		DispatchKeyValueFloat(entity, "amplitude", amplitude);
		DispatchKeyValueFloat(entity, "radius", radius);
		DispatchKeyValueFloat(entity, "duration", duration);
		DispatchKeyValueFloat(entity, "frequency", frequency);

		SetVariantString("spawnflags 8");
		AcceptEntityInput(entity, "AddOutput");

		DispatchSpawn(entity);
		AcceptEntityInput(entity, "StartShake", client);

		float origin[3];

		GetClientAbsOrigin(client, origin);
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

		CreateTimer(duration, Timer_KillEntity, entity);
	}
}

void CreateParticle(float vector[3], const char effect[128], float duration)
{
    int particle = CreateEntityByName("info_particle_system");

    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, vector, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", effect);
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        
        CreateTimer(duration, Timer_KillEntity, particle);
    }
}

public Action Timer_KillEntity(Handle hTimer, int entityId) 
{
    if (IsValidEntity(entityId))
    {
        AcceptEntityInput(entityId, "Kill");
    }

    return Plugin_Stop;
}

void RespondToCommand(int client, const char[] message)
{
	CPrintToChat(client, "%s{default}%s", PLUGIN_PREFIX, message);
}