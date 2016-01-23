/*==================================================================
	
	-----------------------------------------------
	-*- [Hide and Seek] Manage :: Ratio Control -*-
	-----------------------------------------------
	
	Filename: hns_manage_ratio.sp
	Author: Karsei 
	Description: This controls team balance.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hns>

/*******************************************************
 E N U M S
*******************************************************/
enum CVAR
{
	Handle:HTEAMRATIO
}

/*******************************************************
 V A R I A B L E S
*******************************************************/
new hns_eConvar[CVAR];

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Manage :: Ratio Control",
	author = HNS_CREATOR,
	description = "This controls team balance.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	hns_eConvar[HTEAMRATIO] = CreateConVar("hns_team_ratio", "3", "hider/seeker = ? (integer)");
	
	AddCommandListener(Command_TeamListener, "jointeam");
	
	//HookEvent("player_team", Event_OnPlayerTeam);
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Manage) 'Ratio Control' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 커맨드 리스너 :: 팀 변경 시 체크
 *
 * @param client			클라이언트 인덱스
 * @param command			명령어
 * @param args				기타 파라메터
 */
public Action:Command_TeamListener(client, const String:command[], args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 각 팀에 한 명이라도 없으면 그냥 통과
	if (!HNS_TeamHasClients())	return Plugin_Continue;
	
	// 팀을 변경해도 되는지 체크
	// 어느 팀이 숨는 자, 찾는 자의 팀인지 모르니 간단하게 구별
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
	
	// 팀 구별이 완료끝났으면 비율을 체크
	if ((teamid[0] > 0) && (teamid[1] > 0) && (teamid[0] != teamid[1]))
	{
		// 숨는 사람 팀, 찾는 사람 팀의 총 인원 수 체크
		new hidermax = GetTeamClientCount(teamid[0]);
		new seekermax = GetTeamClientCount(teamid[1]);
		
		// 현재 팀의 비율 ( 찾는 사람 인원 / 숨는 사람 인원 )
		new Float:curteamratio = FloatDiv(float(seekermax), float(hidermax));
		
		// 지정한 비율 로드
		new Float:setteamratio = GetConVarFloat(hns_eConvar[HTEAMRATIO]);
		
		// 1을 기준으로 몇 배 정도의 비율로 한정할지 체크
		new Float:limitratio = FloatDiv(1.0, setteamratio);
		
		/*
		curteamratio 값은 limitratio 값의 아래로 떨어지면 안된다.
		(팀 변경을 허용하려면 curteamratio 값이 limitratio 값보다 큰 값으로 있어야 하기 때문)
		
		curteamratio >= limitratio : 팀 변경 가능
		curteamratio < limitratio : 팀 변경 불가능
		*/
		if ((curteamratio > 0) && (setteamratio > 0) && (curteamratio >= limitratio))
		{
			return Plugin_Continue;
		}
		else
		{
			//HNS_T_PrintCenterText(client, "team ratio seeker full");
			HNS_T_PrintToChat(client, "team ratio no change due to ratio");
			HNS_T_PrintCenterText(client, "team ratio no change due to ratio");
			return Plugin_Handled;
		}
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
/*
public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(0.2, Timer_CheckTeamChange, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}*/