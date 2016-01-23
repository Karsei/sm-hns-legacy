/*==================================================================
	
	------------------------------------------------------
	-*- [Hide and Seek] Option :: Money System Wrapper -*-
	------------------------------------------------------
	
	Filename: hns_option_money_wrapper.sp
	Author: Karsei
	Description: Option Plugin
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2013-2015 by Karsei All Right Reserved.
	
==================================================================*/

/**********************************************************************
 Semicolon
 **********************************************************************/
#pragma semicolon 1


/**********************************************************************
 Headers
 **********************************************************************/
#include <sourcemod>
#include <cstrike>
#include <hns>


/**********************************************************************
 Variables
 **********************************************************************/
// 기존 돈.
new iPrevMoney[MAXPLAYERS + 1];

// 서버명령어
enum CVARS
{
	Handle:money_max,
	Handle:money_hider_gain
}
new g_hCV[CVARS];


/**********************************************************************
 Plugin information
 **********************************************************************/
public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Money System Wrapper",
	author		= "Karsei",
	description = "Change CS:S Money system.",
	version		= HNS_VERSION,
	url 		= HNS_CREATOR_URL
}


/**********************************************************************
 SourceMod General Forwards
 **********************************************************************/
/**
 * 플러그인 로딩중
 */
public OnPluginStart()
{
	// 서버 명령어.
	g_hCV[money_max] = CreateConVar("hns_moneywrap_max", "30000", "Wrap CS Money Maximum value.", _, _, _, true, 32000.0);
	g_hCV[money_hider_gain] = CreateConVar("hns_moneywrap_hider_gain", "500");
	
	// 게임 이벤트.
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);

	// 알림.
	PrintToServer("%s (Option) 'Money System Wrapper' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 설정이 완료된 후
 */
public OnMapStart()
{
	// 클라이언트 전체.
	// x = 클라이언트 인덱스.
	for (new x = 1; x <= MaxClients; x++)
	{
		iPrevMoney[x] = 0;
	}
}

/**
 * 클라이언트 퇴장.
 *
 * @param client 		클라이언트 인덱스.
 */
public OnClientDisconnect(client)
{
	iPrevMoney[client] = 0;
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
	// 클라이언트 인덱스.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// 찾는자인가요?
	if (HNS_IsClientSeeker(client))
		utilSetClientMoney(client, GetConVarInt(g_hCV[money_max]));

	else if (HNS_IsClientHider(client))
	{
		if (iPrevMoney[client] > 32000)
			utilSetClientMoney(client, 32000);
		else 
			utilSetClientMoney(client, iPrevMoney[client]);
	}
}

/**
 * Game event: player_death
 *
 * @param event				The event handle.
 * @param name				The name of event.
 * @param dontBroadcast		If true, event is broadcasted to all clients, false if not.
 */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// 클라이언트 인덱스.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// 돈 저장.
	iPrevMoney[client] = utilGetClientMoney(client);
}

/**
 * Game event: round_end
 *
 * @param event				The event handle.
 * @param name				The name of event.
 * @param dontBroadcast		If true, event is broadcasted to all clients, false if not.
 */
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// 이긴 팀.
	new winteam = GetEventInt(event, "winner");

	// 클라이언트 전체.
	// x = 클라이언트 인덱스.
	for (new x = 1; x <= MaxClients; x++)
	{
		// 클라이언트 유효성 검사.
		if (!IsClientInGame(x)) continue;
		if (!IsPlayerAlive(x)) continue;

		// 숨는자가 이겼나요?
		if (winteam == CS_TEAM_T && HNS_IsClientHider(x) || winteam == CS_TEAM_CT && HNS_IsClientHider(x))
			iPrevMoney[x] = (utilGetClientMoney(x) + GetConVarInt(g_hCV[money_hider_gain]));
	}
}


/*****************************************************************
 Generals
 *****************************************************************/
/**
 * 클라이언트의 돈을 구합니다.
 *
 * @param client		클라이언트 인덱스.
 */
stock utilGetClientMoney(client)
{
	// 클라이언트의 돈이 얼마있는지 확인.
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

/**
 * 클라이언트의 돈을 설정합니다.
 *
 * @param client		클라이언트 인덱스.
 * @param value			설정할 값.
 */
stock utilSetClientMoney(client, value)
{
	// 2번 매개변수에서 받은 값이 0 이하이면 0으로 설정.
	if (value < 0) 
		value = 0;
	
	// 클라이언트의 현금을 특정수치로 설정.
	SetEntProp(client, Prop_Send, "m_iAccount", value);
}
