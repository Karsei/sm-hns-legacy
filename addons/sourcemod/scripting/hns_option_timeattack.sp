/*==================================================================
	
	---------------------------------------------
	-*- [Hide and Seek] Option :: Time Attack -*-
	---------------------------------------------
	
	Filename: hns_option_timeattack.sp
	Author: Karsei
	Description: Option Plugin
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved.
	
==================================================================*/

// Headers
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hns>


//  MUST. D'oh!
#pragma semicolon 1

// 핸들 변수
new Handle:tTimeAttack = INVALID_HANDLE;
new Handle:tBeacon = INVALID_HANDLE;

new Handle:cvMode = INVALID_HANDLE;
new Handle:cvBeaconSound = INVALID_HANDLE;
new Handle:cvToggleTime = INVALID_HANDLE;
new Handle:cvBeaconRadius = INVALID_HANDLE;


// 플러그인 정보
public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Option :: Time Attack",
	author		= HNS_CREATOR,
	description = "Option Plug-in",
	version		= HNS_VERSION,
	url			= HNS_CREATOR_URL
}

public OnPluginStart()
{
	// 콘솔 명령어.
	cvMode = CreateConVar("hns_timeattack_mode", "0", "0: Beacon mode | 1: Knife versus mode | 2: Model size change | 3: Random");
	cvBeaconSound = CreateConVar("hns_timeattack_beacon_sound", "0", "0: CT Only | 1: All");
	cvToggleTime = CreateConVar("hns_timeattack_toggle_time", "0.5", "Time to toggle the time attack. (based Remaining time.)");
	cvBeaconRadius = CreateConVar("hns_timeattack_beacon_radius", "500.0");

	// 게임 이벤트.
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_end", Event_RoundEnd);
	
	// 번역.
	LoadTranslations("plugin.hide_and_seek");
	
	// 알림.
	PrintToServer("%s (Option) 'Time Attack' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnMapStart()
{
	if (!HNS_IsEngineWork())	return;
	
	tTimeAttack = INVALID_HANDLE;
	tBeacon = INVALID_HANDLE;
}

public OnMapEnd()
{
	if (!HNS_IsEngineWork())	return;
	
	// 타이머 정지.
	if (tTimeAttack != INVALID_HANDLE)
	{
		KillTimer(tTimeAttack);
	}
	tTimeAttack = INVALID_HANDLE;

	if (tBeacon != INVALID_HANDLE)
	{
		KillTimer(tBeacon);
	}
	tBeacon = INVALID_HANDLE;
}


public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	if (tTimeAttack != INVALID_HANDLE)
	{
		KillTimer(tTimeAttack);
	}
	tTimeAttack = INVALID_HANDLE;

	if (tBeacon != INVALID_HANDLE)
	{
		KillTimer(tBeacon);
	}
	tBeacon = INVALID_HANDLE;

	// 플레이어 크기 초기화.
	for (new x = 1; x <= MaxClients; x++)
	{
		if (!IsClientInGame(x)) continue;
		if (!IsPlayerAlive(x)) continue;

		SetEntPropFloat(x, Prop_Send, "m_flModelScale", 1.0);
	}
	
	return Plugin_Continue;
}

public Action:Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	if (tTimeAttack != INVALID_HANDLE)
	{
		KillTimer(tTimeAttack);
	}
	
	// 라운드 시간을 60.0 초 단위로 변환하여 이를 타이머 발동 시간으로 지정
	new Float:server_roundtime = GetConVarFloat(FindConVar("mp_roundtime"));
	new Float:timeattack_detecttime;
	timeattack_detecttime = server_roundtime - GetConVarFloat(cvToggleTime); 
	timeattack_detecttime *= 60.0;
	
	tTimeAttack = CreateTimer(timeattack_detecttime, Timer_StartTimeAttack, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	if (tTimeAttack != INVALID_HANDLE)
	{
		KillTimer(tTimeAttack);
	}
	tTimeAttack = INVALID_HANDLE;

	if (tBeacon != INVALID_HANDLE)
	{
		KillTimer(tBeacon);
	}
	tBeacon = INVALID_HANDLE;
	
	return Plugin_Continue;
}

public Action:Timer_StartTimeAttack(Handle:timer)
{
	tTimeAttack = INVALID_HANDLE;
	
	if (tBeacon != INVALID_HANDLE)
		tBeacon = INVALID_HANDLE;
	tBeacon = CreateTimer(1.0, Timer_Beacon, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	PrintCenterTextAll(" 타임 어택!\nTIME ATTACK!");
	PrintToChatAll("%t", "timeattack start");
}

public Action:Timer_Beacon(Handle:timer)
{
	new teamid = GetConVarInt(FindConVar("hns_team_divide"));
	new mode = GetConVarInt(cvMode);
	new sound = GetConVarInt(cvBeaconSound);
	new random;

	// Hider는 칼을 지급해주고, Seeker는 무기를 다 제거한 후 칼 지급 (나중에. 지금은 Hider 비콘켜기)
	for (new x = 1; x <= MaxClients; x++)
	{
		if (!IsClientInGame(x)) continue;
		if (!IsPlayerAlive(x)) continue;

		// 팀구분 값이 1이라면 숨는팀은 T, 찾는팀은 CT이므로 @t로 포맷
		if (teamid == 1 && GetClientTeam(x) != CS_TEAM_T)
			continue;

		// 값이 2라면 위와 반대되는 상황이므로 @ct
		if (teamid == 2 && GetClientTeam(x) != CS_TEAM_CT)
			continue;

		if (mode == 3)
		{
			random = GetRandomInt(0, 2);
		}
			
		// 비콘 모드가 어떤 것인가요?
		switch (mode || random)
		{
			// 비콘 전용.
			case 0:
			{
				if (HNS_IsClientSeeker(x))
					SetEntityHealth(x, 1000);

				new Float:vec[3];
				GetClientAbsOrigin(x, vec);
				vec[2] += 30;
				new beaconColorOne[4] = {255, 0, 0, 255};

				new modelindex = PrecacheModel("sprites/laser.vmt");
				new haloindex = PrecacheModel("sprites/glow02.vmt");
				TE_SetupBeamRingPoint(vec, 8.0, GetConVarFloat(cvBeaconRadius), modelindex, haloindex, 0, 10, 0.6, 8.0, 0.5, beaconColorOne, 10, 0);
				TE_SendToAll();
				
				PrecacheSound("tools/ifm/beep.wav", false);
				if (sound == 0)
				{
					EmitAmbientSound("tools/ifm/beep.wav", vec, x);
				}

				else if (sound == 1)
				{
					EmitAmbientSound("tools/ifm/beep.wav", vec, x);
				}
				
			}

			// 칼전 모드.
			case 1: 
			{
				RemovePlayerWeapons(x);
				GivePlayerItem(x, "weapon_knife");
				
				if (HNS_IsClientHider(x))
				{
					if (GetClientTeam(x) == CS_TEAM_T) SetEntityModel(x, "models/player/t_guerilla.mdl");
					else if (GetClientTeam(x) == CS_TEAM_CT) SetEntityModel(x, "models/player/ct_sas.mdl");
				}
				
				else if (HNS_IsClientSeeker(x))
				{
					if (GetClientTeam(x) == CS_TEAM_T) SetEntityModel(x, "models/player/ct_sas.mdl");
					else if (GetClientTeam(x) == CS_TEAM_CT) SetEntityModel(x, "models/player/t_guerilla.mdl");
				}
			}

			// 모델크기 변경 모드.
			case 2:
			{
				if (HNS_IsClientHider(x))
					SetEntPropFloat(x, Prop_Send, "m_flModelScale", 4.0);
			}
		}
	}
	
	return Plugin_Continue;
}

/**
 * 무기 모듈 :: 소지하고 있는 모든 무기 삭제
 *
 * @param client			클라이언트 인덱스
 */
public RemovePlayerWeapons(client)
{
	if (!HNS_IsEngineWork())	return;
	
	new iweapon = -1;
	
	for (new i = 0; i < 5; i++)
	{
		while ((iweapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iweapon);
			RemoveEdict(iweapon);
		}
	}
}