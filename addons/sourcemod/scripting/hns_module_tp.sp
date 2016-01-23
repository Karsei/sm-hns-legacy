/*==================================================================
	
	----------------------------------------------------
	-*- [Hide and Seek] Module :: Toggle Perspective -*-
	----------------------------------------------------
	
	Filename: hns_module_tp.sp
	Author: Karsei 
	Description: This allows hiders to toggle perspective.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <hns>

/*******************************************************
 V A R I A B L E S
*******************************************************/
new Handle:hns_hForceHoldCamera = INVALID_HANDLE;

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Module :: Toggle Perspective",
	author = HNS_CREATOR,
	description = "This allows hiders to toggle perspective.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegConsoleCmd("sm_thirdperson", Command_TogglePers);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
	
	// 카메라 고정 관련
	hns_hForceHoldCamera = FindConVar("mp_forcecamera");
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Module) 'Toggle Perspective' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 유저가 서버에서 나갔을 때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientDisconnect(client)
{
	if (!HNS_IsEngineWork())	return;
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 시점 모듈 :: 시점 변경 응답
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_TogglePers(client, args)
{
	if (!HNS_IsEngineWork())	return;
	
	// 숨는 사람이 아니면 사용하지 못하도록 처리
	if (!HNS_IsClientHider(client))
	{
		HNS_T_PrintToChat(client, "only terrorists can use this");
		return;
	}
	
	// 죽은 사람은 무시
	if (!IsPlayerAlive(client))
	{
		HNS_T_PrintToChat(client, "no use player dead");
		return;
	}
	
	// 인칭 설정
	if (!HNS_IsClientThirdPerson(client))
	{
		// 3인칭 설정
		HNS_SetClientThirdPerson(client, true);
		HNS_T_PrintToChat(client, "tp previous pers msg");
	}
	else
	{
		// 1인칭 설정
		HNS_SetClientThirdPerson(client, false);
	}
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 채팅 :: 채팅 처리 함수
 *
 * @param client			클라이언트 인덱스
 * @param args				채팅 메세지
 */
public Action:Command_Say(client, args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new String:msg[256], String:name[256], String:buffer[256];
	
	GetCmdArgString(msg, sizeof(msg));
	
	msg[strlen(msg)-1] = '\x0';
	
	GetClientName(client, name, sizeof(name));
	
	// 시점 변경
	if (StrEqual(msg[1], "!tp", false) || StrEqual(msg[1], "!3", false) || StrEqual(msg[1], "!3인칭", false))
	{
		Format(buffer, sizeof(buffer), "\x03%s \x01:  %s", name, msg[1]);
		SayText2All(client, buffer);
		PrintToServer(buffer);
		Command_TogglePers(client, 0);
		
		return Plugin_Handled;
	}
	if (StrEqual(msg[1], "/tp", false) || StrEqual(msg[1], "/3", false) || StrEqual(msg[1], "/3인칭", false))
	{
		Command_TogglePers(client, 0);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 플레이어 스폰 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 3인칭과 관련해서는 반드시 player_spawn 이벤트로 해야 하니 주의!
	
	// 숨는 사람의 경우
	if (HNS_IsClientHider(client))
	{
		// 카메라 고정 해제
		if (!IsFakeClient(client) && (GetConVarInt(hns_hForceHoldCamera) == 1))
			SendConVarValue(client, hns_hForceHoldCamera, "0");
		
		// 3인칭으로 변경
		HNS_SetClientThirdPerson(client, true);
	}
	else if (HNS_IsClientSeeker(client))
	{
		// 카메라 고정 설정
		if (!IsFakeClient(client) && (GetConVarInt(hns_hForceHoldCamera) == 1))
			SendConVarValue(client, hns_hForceHoldCamera, "1");
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 플레이어 데스 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 절때 아래 주석 풀지 말 것!! (이유: 관전자 모드 나타남)
	//HNS_SetClientThirdPerson(client, false);
	
	// 모두 카메라 원상태로 변경
	if (GetConVarInt(hns_hForceHoldCamera) == 1)
	{
		if (!IsFakeClient(client) && !HNS_IsClientHider(client))
			SendConVarValue(client, hns_hForceHoldCamera, "1");
		else if (!IsFakeClient(client))
			SendConVarValue(client, hns_hForceHoldCamera, "0");
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 플레이어 팀 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	
	/*
	teamid 변수
	
	배열: 0 - Hider, 1 - Seeker
	*/
	new teamid[2];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (HNS_IsClientHider(i) && (teamid[0] == 0))
			{
				if (GetClientTeam(i) == CS_TEAM_T)	teamid[0] = CS_TEAM_T;
				else if (GetClientTeam(i) == CS_TEAM_CT)	teamid[0] = CS_TEAM_CT;
			}
			else if (HNS_IsClientSeeker(i) && (teamid[1] == 0))
			{
				if (GetClientTeam(i) == CS_TEAM_T)	teamid[1] = CS_TEAM_T;
				else if (GetClientTeam(i) == CS_TEAM_CT)	teamid[1] = CS_TEAM_CT;
			}
			
			if ((teamid[0] > 0) && (teamid[1] > 0) && (teamid[0] != teamid[1]))	break;
		}
	}
	
	if ((teamid[0] > 0) && (teamid[1] > 0) && (teamid[0] != teamid[1]))
	{
		// 카메라 관련 설정
		if ((client > 0) && !IsFakeClient(client) && GetConVarInt(hns_hForceHoldCamera) == 1)
		{
			if (team == teamid[0])
				SendConVarValue(client, hns_hForceHoldCamera, "0");
			else if (team == teamid[1])
				SendConVarValue(client, hns_hForceHoldCamera, "1");
		}
	}
	
	return Plugin_Continue;
}