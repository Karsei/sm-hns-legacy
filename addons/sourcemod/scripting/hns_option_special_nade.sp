/*==================================================================
	
	-------------------------------------------------------
	-*- [Hide and Seek] Option :: Seeker's Special Nade -*-
	-------------------------------------------------------
	
	Filename: hns_option_special_nade.sp
	Author: Karsei
	Description: Special nades for Seekers
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved.
	
==================================================================*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <hns>

#pragma semicolon 1


#define SOUND_FREEZE			"physics/glass/glass_impact_bullet4.wav"
#define SOUND_FREEZE_EXPLODE	"ui/freeze_cam.wav"

#define FreezeColor	{0,255,0,255}

#define SLAP_DISTANCE 1000.0


new BeamSprite, g_beamsprite, g_halosprite;
new maxents;


public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Option :: Special nades for Seeker",
	author		= HNS_CREATOR,
	description = "Adds Grenade Special Effects.",
	version		= HNS_VERSION,
	url			= HNS_CREATOR_URL
}

public OnPluginStart()
{
	HookEvent("smokegrenade_detonate", SmokeDetonate);
	AddNormalSoundHook(NormalSHook);
	
	PrintToServer("%s (Option) 'Special nades for Seeker' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnMapStart() 
{
	if (!HNS_IsEngineWork())	return;
	
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_FREEZE_EXPLODE);
}

public Action:SmokeDetonate(Handle:event, const String:name[], bool:dontBroadcast) 
{
	decl String:EdictName[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	maxents = GetMaxEntities();	
	for (new edict = MaxClients; edict <= maxents; edict++)
	{
		if (IsValidEdict(edict))
		{
			GetEdictClassname(edict, EdictName, sizeof(EdictName));
			if (!strcmp(EdictName, "smokegrenade_projectile", false))
				if (GetEntPropEnt(edict, Prop_Send, "m_hThrower") == client)
					AcceptEntityInput(edict, "Kill");
		}
	}
	
	new Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x"); 
	DetonateOrigin[1] = GetEventFloat(event, "y"); 
	DetonateOrigin[2] = GetEventFloat(event, "z");
	
	DetonateOrigin[2] += 30.0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && HNS_IsClientHider(i))
		{
			new Float:targetOrigin[3];
			GetClientAbsOrigin(i, targetOrigin);
			
			if (GetVectorDistance(DetonateOrigin, targetOrigin) <= SLAP_DISTANCE)
			{
				new Handle:trace = TR_TraceRayFilterEx(DetonateOrigin, targetOrigin, MASK_SHOT, RayType_EndPoint, FilterTarget, i);
				if (TR_DidHit(trace))
				{
					if (TR_GetEntityIndex(trace) == i) PushPlayerSlap(i);
				}
				
				else
				{
					GetClientEyePosition(i, targetOrigin);
					targetOrigin[2] -= 1.0;
			
					if (GetVectorDistance(DetonateOrigin, targetOrigin) <= SLAP_DISTANCE)
					{
						new Handle:trace2 = TR_TraceRayFilterEx(DetonateOrigin, targetOrigin, MASK_SHOT, RayType_EndPoint, FilterTarget, i);
						if (TR_DidHit(trace2))
						{
							if (TR_GetEntityIndex(trace2) == i) PushPlayerSlap(i);
						}
						
						CloseHandle(trace2);
					}
				}
				
				CloseHandle(trace);
			}
		}
	}
	
	TE_SetupBeamRingPoint(DetonateOrigin, 10.0, SLAP_DISTANCE, g_beamsprite, g_halosprite, 1, 10, 1.0, 5.0, 1.0, FreezeColor, 0, 0);
	TE_SendToAll();
	LightCreate(DetonateOrigin);
}

public bool:FilterTarget(entity, contentsMask, any:data)
{
	return (data == entity);
} 

PushPlayerSlap(client)
{
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	SlapPlayer(client, 0, false);
	SlapPlayer(client, 0, false);
	SlapPlayer(client, 0, false);
	SlapPlayer(client, 0, true);

	decl Float:velocity[3];
	velocity[0] = 0.0;
	velocity[1] = 0.0;
	velocity[2] = 50.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

public OnEntityCreated(Entity, const String:Classname[])
{
	if (StrEqual(Classname, "smokegrenade_projectile"))
	{
		BeamFollowCreate(Entity, FreezeColor);
		CreateTimer(2.0, SmokeCreateEvent, Entity, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (StrEqual(Classname, "env_particlesmokegrenade"))
		AcceptEntityInput(Entity, "Kill");
}

public Action:SmokeCreateEvent(Handle:timer, any:entity)
{
	if (IsValidEdict(entity) && IsValidEntity(entity))
	{
		decl String:clsname[64];
		GetEdictClassname(entity, clsname, sizeof(clsname));
		if (!strcmp(clsname, "smokegrenade_projectile", false))
		{
			new Float:SmokeOrigin[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", SmokeOrigin);
			new client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
			new userid = GetClientUserId(client);
		
			new Handle:event = CreateEvent("smokegrenade_detonate");
		
			SetEventInt(event, "userid", userid);
			SetEventFloat(event, "x", SmokeOrigin[0]);
			SetEventFloat(event, "y", SmokeOrigin[1]);
			SetEventFloat(event, "z", SmokeOrigin[2]);
			FireEvent(event);
		}
	}
}
		
BeamFollowCreate(Entity, Color[4])
{
	TE_SetupBeamFollow(Entity, BeamSprite,	0, Float:1.0, Float:10.0, Float:10.0, 5, Color);
	TE_SendToAll();	
}

LightCreate(Float:Pos[3])   
{  
	new iEntity = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	
	DispatchKeyValue(iEntity, "_light", "75 75 255 255");
	DispatchKeyValueFloat(iEntity, "distance", SLAP_DISTANCE);
	EmitSoundToAll(SOUND_FREEZE_EXPLODE, iEntity, SNDCHAN_WEAPON);
	CreateTimer(1.0, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);
	
	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, Pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
}

public Action:Delete(Handle:timer, any:entity)
{
	if (IsValidEdict(entity)) AcceptEntityInput(entity, "kill");
}

public Action:NormalSHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	if (StrEqual(sample, "^weapons/smokegrenade/sg_explode.wav"))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
