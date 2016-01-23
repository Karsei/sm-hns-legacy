/*==================================================================
	
	-----------------------------------------------
	-*- [Hide and Seek] Module :: Toggle Freeze -*-
	-----------------------------------------------
	
	Filename: hns_module_freeze.sp
	Author: Karsei 
	Description: This allows hiders to toggle freeze.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hns>

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Module :: Toggle Freeze",
	author = HNS_CREATOR,
	description = "This allows hiders to toggle freeze.",
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
	
	RegConsoleCmd("sm_setfreeze", Command_ToggleFreeze);
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Module) 'Toggle Freeze' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 고정 모듈 :: 고정 변경 응답
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_ToggleFreeze(client, args)
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
	
	// 프리즈 설정
	if (!HNS_IsClientFreezed(client))
	{
		// 고정 처리
		new Float:modelheight = HNS_GetClientModelHeight(client);
		
		if ((GetEntityFlags(client) & FL_ONGROUND) || (modelheight > 0.0))
		{
			HNS_SetClientFreezed(client, true, true, true);
			HNS_T_PrintToChat(client, "hider freezed");
		}
	}
	else
	{
		// 고정 해제 처리
		HNS_SetClientFreezed(client, false);
		HNS_T_PrintToChat(client, "hider unfreezed");
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
	
	// 프리즈
	if (StrEqual(msg[1], "!ice", false) || StrEqual(msg[1], "!고정", false) || StrEqual(msg[1], "!얼음", false))
	{
		Format(buffer, sizeof(buffer), "\x03%s \x01:  %s", name, msg[1]);
		SayText2All(client, buffer);
		PrintToServer(buffer);
		Command_ToggleFreeze(client, 0);
		
		return Plugin_Handled;
	}
	if (StrEqual(msg[1], "/ice", false) || StrEqual(msg[1], "/고정", false) || StrEqual(msg[1], "/얼음", false))
	{
		Command_ToggleFreeze(client, 0);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
