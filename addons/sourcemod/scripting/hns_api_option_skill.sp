/*==================================================================
	
	--------------------------------------------------------
	-*- [Hide and Seek] API Processor :: Option :: Skill -*-
	--------------------------------------------------------
	
	Filename: hns_api_option_skill.sp
	Author: Karsei
	Description: API Processor
	
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


// 변수
new bool:bSelected[MAXPLAYERS + 1] = false;		// 이 boolean이 true일 경우 스킬이 선택되었다는 뜻, false면 아님.
new iSkillCode[MAXPLAYERS + 1] = HNS_SKILL_NONE;

// 포워드 핸들
new Handle:g_hFWDOnSetClientSkill = INVALID_HANDLE;


// 플러그인 정보
public Plugin:myinfo = 
{
	name		= "[Hide and Seek] API Processor :: Option :: Skill",
	author		= HNS_CREATOR,
	description = "Process Option API the skill of hns",
	version		= HNS_VERSION,
	url			= HNS_CREATOR_URL
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// 네이티브
	CreateNative("HNS_IsClientSkillUser", Native_IsClientSkillUser);
	CreateNative("HNS_GetClientSkill", Native_GetClientSkill);
	CreateNative("HNS_SetClientSkill", Native_SetClientSkill);
	
	// 포워드
	g_hFWDOnSetClientSkill = CreateGlobalForward("HNS_OnSetClientSkill", ET_Ignore, Param_Cell, Param_Cell);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
	
	HookEvent("round_end", Event_RoundEnd);
	
	PrintToServer("%s (Option) 'Skill API Processor' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnClientPutInServer(client)
{
	InitializeSettings(client);
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
		InitializeSettings(client);
}

InitializeSettings(client)
{
	bSelected[client] = false;
	iSkillCode[client] = HNS_SKILL_NONE;
}

public Native_IsClientSkillUser(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!HNS_IsClientValid(client))
	{
		return false;
	}
	
	return bSelected[client];
}

public Native_GetClientSkill(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!HNS_IsClientValid(client))
	{
		return false;
	}
	
	return iSkillCode[client];
}

public Native_SetClientSkill(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!HNS_IsClientValid(client))
	{
		return;
	}
	
	new type = GetNativeCell(2);
	P_SetClientSkill(client, type);
}

P_SetClientSkill(client, type)
{
	iSkillCode[client] = type;
	
	bSelected[client] = true;
}

// 포워드 처리 :: HNS_OnSetClientSkill
stock P_FWD_OnSetClientSkill(client, type)
{
	Call_StartForward(g_hFWDOnSetClientSkill);
	
	Call_PushCell(client);
	Call_PushCell(type);
	
	Call_Finish();
}


public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	InitializeSettings(client);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	InitializeSettings(client);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new x = 1; x <= MaxClients; x++)
	{
		if (!IsClientInGame(x)) continue;
		if (!IsPlayerAlive(x)) continue;
		
		InitializeSettings(x);
	}
}
