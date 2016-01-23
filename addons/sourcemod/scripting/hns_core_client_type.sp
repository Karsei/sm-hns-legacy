/*==================================================================
	
	------------------------------------------------------
	-*- [Hide and Seek] Core :: Client Type Controller -*-
	------------------------------------------------------
	
	Filename: hns_core_client_type.sp
	Author: Karsei
	Description: General
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved.
	
==================================================================*/

// Headers
#include <sourcemod>
#include <cstrike>
#include <hns>


//  MUST. D'oh!
#pragma semicolon 1


// enum
enum CVAR
{
	Handle:HTEAMDIVIDE
}


// variables
new g_eConvar[CVAR];


// Plugin Information
public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Core :: Client Type Controller",
	author		= HNS_CREATOR,
	description = "Client type control (Hider / Seeker)",
	version		= HNS_VERSION,
	url			= HNS_CREATOR_URL
}

public OnPluginStart()
{
	g_eConvar[HTEAMDIVIDE] = CreateConVar("hns_team_divide", "1", "1 is T: Hider / 2 is T: Seeker");
	
	/*
	 - 참고 (player_team -> player_spawn -> round_start -> round_freeze_end)
	 
	 - Note // 좀 더 유연성있게 플러그인이 동작하려면 플레이어가 스폰하기 전에 찾는 사람, 숨는 사람 선정이 빠르게 진행되어야 하니 참고!
	*/
	HookEvent("player_team", Event_OnPlayerTeam);
	//HookEvent("player_spawn", Event_OnPlayerSpawn);
	//HookEvent("round_freeze_end", Event_OnRoundFreezeEnd);
	
	PrintToServer("%s (Core) 'Client Type Controller' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 게임 이벤트 :: player_team
 * 
 * @param event				본 이벤트의 핸들
 * @param name				본 이벤트의 이름
 * @param dontBroadcast		알리지 않습니다.
 */
public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork()) return Plugin_Continue;
	
	/* 플레이어 팀 이벤트 정보
	short	 userid	 user ID on the server
	byte	 team	 team id
	byte	 oldteam	 old team id
	bool	 disconnect	 team change because player disconnects
	bool	 autoteam	 true if the player was auto assigned to the team (OB only)
	bool	 silent	 if true wont print the team join messages (OB only)
	string	 name	 player's name (OB only)
	*/
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team"); // GetClientTeam 으로 하지 말 것!! (GetClientTeam 경우는 이전 팀으로 선정)
	
	if (GetConVarInt(g_eConvar[HTEAMDIVIDE]) == 1)
	{
		if (team == CS_TEAM_T)	HNS_SetClientTo(client, HNS_CLIENT_HIDER);
		else if (team == CS_TEAM_CT)	HNS_SetClientTo(client, HNS_CLIENT_SEEKER);
	}
	
	else if (GetConVarInt(g_eConvar[HTEAMDIVIDE]) == 2)
	{
		if (team == CS_TEAM_T)	HNS_SetClientTo(client, HNS_CLIENT_SEEKER);
		else if (team == CS_TEAM_CT)	HNS_SetClientTo(client, HNS_CLIENT_HIDER);
	}
	
	return Plugin_Continue;
}

/*
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork()) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	if (g_eConvar[ITEAMDIVIDE] == 1)
	{
		if (team == CS_TEAM_T)	HNS_SetClientTo(client, HNS_CLIENT_HIDER);
		else if (team == CS_TEAM_CT)	HNS_SetClientTo(client, HNS_CLIENT_SEEKER);
	}
	
	else if (g_eConvar[ITEAMDIVIDE] == 2)
	{
		if (team == CS_TEAM_T)	HNS_SetClientTo(client, HNS_CLIENT_SEEKER);
		else if (team == CS_TEAM_CT)	HNS_SetClientTo(client, HNS_CLIENT_HIDER);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork()) return Plugin_Continue;
	
	for (new x = 1; x <= MaxClients; x++)
	{
		if (!IsClientInGame(x)) continue;
		if (!IsPlayerAlive(x)) continue;
		
		new team = GetClientTeam(x);
		
		if (g_eConvar[ITEAMDIVIDE] == 1)
		{
			if (team == CS_TEAM_T) HNS_SetClientTo(x, HNS_CLIENT_HIDER);
			else if (team == CS_TEAM_CT) HNS_SetClientTo(x, HNS_CLIENT_SEEKER);
		}
		
		else if (g_eConvar[ITEAMDIVIDE] == 2)
		{
			if (team == CS_TEAM_T) HNS_SetClientTo(x, HNS_CLIENT_SEEKER);
			else if (team == CS_TEAM_CT) HNS_SetClientTo(x, HNS_CLIENT_HIDER);
		}
	}
	
	return Plugin_Continue;
}
*/