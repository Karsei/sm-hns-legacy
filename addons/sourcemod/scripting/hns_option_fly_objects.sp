/*==================================================================
	
	-----------------------------------------------------
	-*- [Hide and Seek] Option :: Fly for the objects -*-
	-----------------------------------------------------
	
	Filename: hns_option_fly_objects.sp
	Author: Karsei
	Description: Option plugin that make fly to the flying objects.
	
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
 Constants
 **********************************************************************/
// 대상모델.
#define TARGET_MDL_COMBINEDROPSHIP 	"combinedropship.mdl"
#define TARGET_MDL_CHOPPA 	"helicopter.mdl"


/**********************************************************************
 Variables
 **********************************************************************/
// 제트팩 배터리
new iBattery[MAXPLAYERS + 1];
new iBatteryMax[MAXPLAYERS + 1];

// 콘솔 명령어
new Handle:hCVBatteryMax = INVALID_HANDLE;
new Handle:hCVBatteryFillInterval = INVALID_HANDLE;

// 동적 배열.
stock Handle:hArrayTargetModel = INVALID_HANDLE;

// 트레일 속성.
new g_iTrailModel;
new g_iTrailHaloModel;
new g_iTrailColor[4] = {0, 255, 200, 255};


/**********************************************************************
 Plugin information
 **********************************************************************/
public Plugin:myinfo =
{
	name		= "[Hide and Seek] Option :: Fly for objects!",
	author		= "Karsei",
	description = "Make flying to the flying objects.",
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
	hCVBatteryMax = CreateConVar("hns_fly_object_battery_max", "250");
	hCVBatteryFillInterval = CreateConVar("hns_fly_object_battery_fill_interval", "50");

	// 이벤트 훅
	HookEvent("player_spawn", Event_PlayerSpawn);

	// 동적배열 활성.
	hArrayTargetModel = CreateArray(128);

	// 알림.
	PrintToServer("%s (Option) 'Fly for objects' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 맵 불러오는 중
 */
public OnMapStart()
{
	g_iTrailModel = PrecacheModel("sprites/laser.vmt");
	g_iTrailHaloModel = PrecacheModel("sprites/glow02.vmt");
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
	
	iBatteryMax[client] = GetConVarInt(hCVBatteryMax);
	iBattery[client] = GetConVarInt(hCVBatteryMax);
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

	// 클라이언트의 모델.
	decl String:clientmodel[128];
	GetClientModel(client, clientmodel, sizeof(clientmodel));

	// 대상모델과 동일하나요?
	if (StrContains(clientmodel, TARGET_MDL_CROW) != -1 || StrContains(clientmodel, TARGET_MDL_PIGEON) != -1)
	{
		new buttons = GetClientButtons(client);
		if (buttons & IN_SPEED)
		{
			if (iBattery[client] != 0)
			{
				iBattery[client]--;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(client, MOVETYPE_FLY);
				
				TE_SetupBeamFollow(client, g_iTrailModel, g_iTrailHaloModel, 2.5, 2.5, 1.0, 1, g_iTrailColor);
				TE_SendToAll();
			}

			else
			{
				iBattery[client] = 0;
				SetEntityMoveType(client, MOVETYPE_WALK);
				buttons &= ~IN_SPEED;
			}
		}

		else
		{
			SetEntityMoveType(client, MOVETYPE_WALK);

			new cool = 0;
			new interval = GetConVarInt(hCVBatteryFillInterval);

			if (cool != interval)
			{
				// 게이지 다시 증가.
				if (iBattery[client] != iBatteryMax[client])
					iBattery[client]++;
				
				else iBattery[client] = iBatteryMax[client];

				cool++;
			}

			else cool = 0;

			// 알림
			PrintCenterText(client, "Fly: %d / %d", iBattery[client], iBatteryMax[client]);
		}
	}
}
