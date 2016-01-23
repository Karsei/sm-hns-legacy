/*==================================================================
	
	----------------------------------------------
	-*- [Hide and Seek] Option :: Duck Limiter -*-
	----------------------------------------------
	
	Filename: hns_option_ducklimit.sp
	Author: Karsei
	Description: Module
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved.
	
==================================================================*/

/**********************************************************************
 Semicolon
 **********************************************************************/
#pragma semicolon 1


/**********************************************************************
 Headers
 **********************************************************************/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <hns>


/**********************************************************************
 Variables
 **********************************************************************/
// 제트팩 배터리
new iDuckBattery[MAXPLAYERS + 1];
new iDuckBatteryMax[MAXPLAYERS + 1];

// 콘솔 명령어
new Handle:hCVBatteryMax = INVALID_HANDLE;
new Handle:hCVBatteryFillInterval = INVALID_HANDLE;


/**********************************************************************
 Plugin information
 **********************************************************************/
public Plugin:myinfo =
{
	name		= "[Hide and Seek] Option :: Duck Limiter",
	author		= "Karsei",
	description = "Duck Limit Controller",
	version		= HNS_VERSION,
	url			= HNS_CREATOR_URL
};


/**********************************************************************
 SourceMod General Forwards
 **********************************************************************/
/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	// 콘바
	hCVBatteryMax = CreateConVar("hns_duck_battery_max", "300");
	hCVBatteryFillInterval = CreateConVar("hns_duck_battery_fill_interval", "50");
	
	// 이벤트 훅
	HookEvent("player_spawn", Event_PlayerSpawn);

	// 알림.
	PrintToServer("%s (Option) 'Duck Limiter' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 클라이언트 서버 접속
 *
 * @param client 		클라이언트 인덱스.
 */
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThinkPost, OnClientPreThinkPost);
}

/**
 * 클라이언트 접속 해제.
 *
 * @param client 		클라이언트 인덱스.
 */
public OnClientDisconnect(client)
{
	DoDuck(client, false);
	SDKUnhook(client, SDKHook_PreThinkPost, OnClientPreThinkPost);
}


/*****************************************************************
 Callbacks
 *****************************************************************/
/**
 * Game event: player_spawn
 *
 * @param event				The event handle.
 * @param name				The name of event.
 * @param dontBroadcast		If true, event is broadcasted to all clients, false if not.
 */
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	iDuckBatteryMax[client] = GetConVarInt(hCVBatteryMax);
	iDuckBattery[client] = GetConVarInt(hCVBatteryMax);
}

/**
 * SDKHooks: PreThinkPost
 * DUCK 게이지 충전 및 감소
 *
 * @param client 		클라이언트 인덱스.
 */
public OnClientPreThinkPost(client)
{
	// 클라이언트 유효성
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;

	// 엔진 켜짐여부
	if (!HNS_IsEngineWork()) return;
	
	// 숨는사람이 맞나요?
	if (!HNS_IsClientHider(client)) return;

	// 버튼 감지.
	new buttons = GetClientButtons(client);
	if (buttons & IN_DUCK)
	{
		if (GetEntityFlags(client) & FL_ONGROUND)
		// 배터리가 충분한가요?
		if (iDuckBattery[client] > 0)
		{
			// 앉기방지 켜짐. (bool :: true)
			DoDuck(client, true);
		}

		// 아니면 앉기 방지.
		else 
		{
			buttons &= ~IN_DUCK;

			decl Float:velocity[3];
			velocity[0] = 0.0;
			velocity[1] = 0.0;
			velocity[2] = 50.0;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			SlapPlayer(client, 0, false);
			SlapPlayer(client, 0, false);
		}
	}
	
	// 앉기방지 해제. (bool: false)
	else DoDuck(client, false);

	// 알림
	PrintHintText(client, "Duck Limit: %d / %d", iDuckBattery[client], iDuckBatteryMax[client]);
}


/**********************************************************************
 Generals
 **********************************************************************/
/**
 * 앉기 방지.
 *
 * @param client 		클라이언트 인덱스.
 * @param turn 			켜기/끄기.
 */
DoDuck(client, bool:turn = false)
{
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	
	// 게이지 감소.
	if (turn)
	{
		
		if (iDuckBattery[client] != 0)
			iDuckBattery[client]--;
		
		else iDuckBattery[client] = 0;
	}

	// 게이지 증가.
	else
	{
		new cool = 0;
		new interval = GetConVarInt(hCVBatteryFillInterval);

		if (cool != interval)
		{
			// 게이지 다시 증가.
			if (iDuckBattery[client] != iDuckBatteryMax[client])
				iDuckBattery[client]++;
			
			else iDuckBattery[client] = iDuckBatteryMax[client];

			cool++;
		}

		else cool = 0;
	}
}
