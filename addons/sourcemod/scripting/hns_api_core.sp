/*==================================================================
	
	---------------------------------------------
	-*- [Hide and Seek] Core :: API Processor -*-
	---------------------------------------------
	
	Filename: hns_api_core.sp
	Author: Karsei
	Description: Core API Processor
	
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


// Offset
new g_iOffFlags;
new g_iAccount;


// Variables
new bool:g_bIsHNSToggle = false;					// HNS 엔진 활성/비활성화
new bool:g_bIsGameToggle = false;					// HNS 게임 활성/비활성화
new bool:bHider[MAXPLAYERS + 1];					// 숨는 사람인지의 여부
new bool:bSeeker[MAXPLAYERS + 1];					// 찾는 사람인지의 여부
new bool:g_bIsClientFreezed[MAXPLAYERS + 1];		// 고정되었는지의 여부
new bool:g_bIsClientThirdPerson[MAXPLAYERS + 1];	// 3인칭으로 되어있는지의 여부
new Float:g_fClientModelHeight[MAXPLAYERS + 1];		// 유저별 모델 높이 값
new bool:g_bIsInDebugMode = false;					// 현 플러그인이 디버그 상태에 있는지의 여부


// forward handles
new Handle:g_hFWDOnToggleGame_Pre = INVALID_HANDLE;
new Handle:g_hFWDOnToggleGame_Post = INVALID_HANDLE;


// Plugin Information
public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Core :: API Processor",
	author		= HNS_CREATOR,
	description = "Process API the core of hns",
	version		= HNS_VERSION,
	url			= HNS_CREATOR_URL
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// 네이티브
	CreateNative("HNS_IsClientHider", Native_IsClientHider);
	CreateNative("HNS_IsClientSeeker", Native_IsClientSeeker);
	CreateNative("HNS_SetClientTo", Native_SetClientTo);
	CreateNative("HNS_IsEngineWork", Native_IsEngineWork);
	CreateNative("HNS_Engine", Native_Engine);
	CreateNative("HNS_IsGameToggle", Native_IsGameToggle);
	CreateNative("HNS_ToggleGame", Native_ToggleGame);
	CreateNative("HNS_IsClientFreezed", Native_IsClientFreezed);
	CreateNative("HNS_SetClientFreezed", Native_SetClientFreezed);
	CreateNative("HNS_IsClientThirdPerson", Native_IsClientThirdPerson);
	CreateNative("HNS_SetClientThirdPerson", Native_SetClientThirdPerson);
	CreateNative("HNS_GetClientModelHeight", Native_GetClientModelHeight);
	CreateNative("HNS_SetClientModelHeight", Native_SetClientModelHeight);
	CreateNative("HNS_SetClientBlind", Native_SetClientBlind);
	CreateNative("HNS_GetClientMoney", Native_GetClientMoney);
	CreateNative("HNS_SetClientMoney", Native_SetClientMoney);
	CreateNative("HNS_IsInDebugMode", Native_IsInDebugMode);
	CreateNative("HNS_SetDebugMode", Native_SetDebugMode);
	CreateNative("HNS_GetHNSTeamID", Native_GetHNSTeamID);
	
	// 포워드
	g_hFWDOnToggleGame_Pre = CreateGlobalForward("HNS_OnToggleGame_Pre", ET_Hook, Param_CellByRef);
	g_hFWDOnToggleGame_Post = CreateGlobalForward("HNS_OnToggleGame_Post", ET_Ignore, Param_Cell);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	g_iOffFlags = FindSendPropOffs("CBasePlayer", "m_fFlags");
	if (g_iOffFlags == -1)
		SetFailState("%s Couldnt find the m_fFlags offset!", HNS_PHRASE_PREFIX);
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
		SetFailState("%s Couldnt find the m_iAccount offset!", HNS_PHRASE_PREFIX);
	
	PrintToServer("%s (Core) 'Core API Processor' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnAllPluginsLoaded()
{
	HNS_Engine(true);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			InitializeSettings(i);
	}
}

public OnPluginEnd()
{
	HNS_Engine(false);
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

public InitializeSettings(client)
{
	bHider[client] = false;
	bSeeker[client] = false;
	g_bIsClientFreezed[client] = false;
	g_bIsClientThirdPerson[client] = false;
	g_fClientModelHeight[client] = 0.0;
}

public Native_IsClientHider(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!HNS_IsClientValid(client))
	{
		return false;
	}
	
	return bHider[client];
}

public Native_IsClientSeeker(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!HNS_IsClientValid(client))
	{
		return false;
	}
	
	return bSeeker[client];
}

public Native_SetClientTo(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new type = GetNativeCell(2);
	P_SetClientTo(client, type);
}

public Native_IsEngineWork(Handle:plugin, numParams)
{
	return g_bIsHNSToggle;
}

public Native_Engine(Handle:plugin, numParams)
{
	new bool:start = bool:GetNativeCell(1);
	
	if (start) g_bIsHNSToggle = true;
	else g_bIsHNSToggle = false;
}

public Native_IsGameToggle(Handle:plugin, numParams)
{
	return g_bIsGameToggle;
}

public Native_ToggleGame(Handle:plugin, numParams)
{
	new bool:start = bool:GetNativeCell(1);
	P_ToggleGame(start);
}

public Native_IsClientFreezed(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_bIsClientFreezed[client];
}

public Native_SetClientFreezed(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new bool:set = bool:GetNativeCell(2);
	new bool:sethold = bool:GetNativeCell(3);
	new bool:settele = bool:GetNativeCell(4);
	P_SetClientFreezed(client, set, sethold, settele);
}

public Native_IsClientThirdPerson(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_bIsClientThirdPerson[client];
}

public Native_SetClientThirdPerson(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new bool:set = bool:GetNativeCell(2);
	P_SetClientThirdPerson(client, set);
}

public Native_GetClientModelHeight(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return _:g_fClientModelHeight[client];
}

public Native_SetClientModelHeight(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new Float:height = Float:GetNativeCell(2);
	g_fClientModelHeight[client] = height;
}

public Native_SetClientBlind(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);
	P_SetClientBlind(client, amount);
}

public Native_GetClientMoney(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new money = GetEntData(client, g_iAccount);
	return money;
}

public Native_SetClientMoney(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);
	SetEntData(client, g_iAccount, amount, 4, true);
}

public Native_IsInDebugMode(Handle:plugin, numParams)
{
	return g_bIsInDebugMode;
}

public Native_SetDebugMode(Handle:plugin, numParams)
{
	new bool:set = bool:GetNativeCell(1);
	g_bIsInDebugMode = set;
}

// 아래의 함수는 후에 다시 살펴보아야 함
public Native_GetHNSTeamID(Handle:plugin, numParams)
{
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
	
	if (teamid[0] == teamid[1])
		return 0;
	
	SetNativeArray(1, teamid[0], 1);
	SetNativeArray(2, teamid[1], 1);
	
	return 1;
}

P_SetClientTo(client, type)
{
	if (!HNS_IsClientValid(client)) return;
	
	if (type == HNS_CLIENT_HIDER)
	{
		bHider[client] = true;
		bSeeker[client] = false;
		CS_SetClientClanTag(client, "[숨는 사람]");
	}
	
	else if (type == HNS_CLIENT_SEEKER)
	{
		bHider[client] = false;
		bSeeker[client] = true;
		CS_SetClientClanTag(client, "[찾는 사람]");
	}
}

P_ToggleGame(bool:start)
{
	new Action:result = P_FWD_OnToggleGame_Pre(start);
	if (result == Plugin_Handled) return;
	
	if (start) g_bIsGameToggle = true;
	else g_bIsGameToggle = false;
	
	P_FWD_OnToggleGame_Post(start);
}

Action:P_FWD_OnToggleGame_Pre(&bool:start)
{
	Call_StartForward(g_hFWDOnToggleGame_Pre);
	
	Call_PushCellRef(start);
	
	new Action:result;
	Call_Finish(result);
	return result;
}

P_FWD_OnToggleGame_Post(bool:start)
{
	Call_StartForward(g_hFWDOnToggleGame_Post);
	
	Call_PushCell(start);
	
	Call_Finish();
}

P_SetClientFreezed(client, set, sethold, settele)
{
	if (!HNS_IsClientValid(client)) return;
	
	if (set)
	{
		// 고정 처리
		if (sethold)
			SetEntData(client, g_iOffFlags, FL_CLIENT|FL_ATCONTROLS, 4, true);
		
		SetEntityMoveType(client, MOVETYPE_NONE);
		if (settele)
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,0.0});
		
		g_bIsClientFreezed[client] = true;
	}
	else if (!set)
	{
		// 고정 해제
		SetEntData(client, g_iOffFlags, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_bIsClientFreezed[client] = false;
	}
}

P_SetClientThirdPerson(client, set)
{
	if (!HNS_IsClientValid(client)) return;
	
	if (set)
	{
		// 3인칭 설정
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		g_bIsClientThirdPerson[client] = true;
	}
	else if (!set)
	{
		// 1인칭 설정
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		g_bIsClientThirdPerson[client] = false;
	}
}

P_SetClientBlind(client, amount)
{
	if (!HNS_IsClientValid(client)) return;
	
	new Handle:message = StartMessageOne("Fade", client);
	
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0) BfWriteShort(message, 0x0010);
	else BfWriteShort(message, 0x0008);
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount); // amount: 0 - 제거, 255 - 검정색
	EndMessage();
}