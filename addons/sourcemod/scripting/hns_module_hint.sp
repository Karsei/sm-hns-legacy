/*==================================================================
	
	--------------------------------------
	-*- [Hide and Seek] Module :: Hint -*-
	--------------------------------------
	
	Filename: hns_module_hint.sp
	Author: Karsei
	Description: This allows hiders to use hints.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hns>

/*******************************************************
 V A R I A B L E S
*******************************************************/
new hns_iHintTotalCount = 5;
new hns_iHintUserCount[MAXPLAYERS+1] = {0,...};
new const String:hns_sHintSoundList[][] = {
								"ambient/animal/crow_1.wav", 
								"ambient/3dmeagle.wav", 
								"ambient/animal/dog2.wav", 
								"ambient/weather/thunder1.wav", 
								"ambient/misc/metal3.wav", 
								"ambient/animal/horse_4.wav", 
								"ambient/tones/equip1.wav", 
								"ambient/animal/horse_5.wav", 
								"ambient/misc/ambulance1.wav", 
								"ambient/animal/cow.wav", 
								"ambient/machines/train_horn_3.wav", 
								"ambient/misc/creak3.wav", 
								"ambient/machines/pneumatic_drill_1.wav", 
								"doors/door_metal_gate_close1.wav", 
								"ambient/misc/flush1.wav"
								};

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Module :: Hint",
	author = HNS_CREATOR,
	description = "This allows hiders to use hints.",
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
	
	RegConsoleCmd("sm_givehint", Command_PlayHintSound);
	
	HookEvent("round_freeze_end", Event_OnRoundFreezeEnd);
	HookEvent("round_end", Event_OnRoundEnd);
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Module) 'Hint' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (!HNS_IsEngineWork())	return;
	
	for (new i = 0; i < sizeof(hns_sHintSoundList); i++)
	{
		PrecacheSound(hns_sHintSoundList[i], true);
	}
}

/**
 * 유저들이 서버에서 나갔을 때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
		hns_iHintUserCount[client] = 0;
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 힌트 모듈 :: 힌트 사운드 재생
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_PlayHintSound(client, args)
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
	
	// 힌트를 주는 상황이 아닐때의 처리
	if (!HNS_IsGameToggle() && HNS_TeamHasClients())
	{
		HNS_T_PrintToChat(client, "hint no allow");
		return;
	}
	
	new counttotal = hns_iHintTotalCount;
	new String:username[64];
	
	GetClientName(client, username, sizeof(username));
	
	// 각 유저에게 부여된 변수의 값을 증가시켜서 힌트 재생 처리
	if (hns_iHintUserCount[client] < counttotal)
	{
		EmitSoundToAll(hns_sHintSoundList[GetRandomInt(0, sizeof(hns_sHintSoundList)-1)], client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		HNS_T_PrintToChatAll(false, false, "hint here", username);
		if (HNS_TeamHasClients())
		{
			hns_iHintUserCount[client]++;
			HNS_T_PrintToChat(client, "hint left", (counttotal-hns_iHintUserCount[client]));
		}
	}
	else
	{
		HNS_T_PrintToChat(client, "hint limit", counttotal);
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
	
	// 힌트 주기
	if (StrEqual(msg[1], "!hint", false) || StrEqual(msg[1], "!힌트", false))
	{
		Format(buffer, sizeof(buffer), "\x03%s \x01:  %s", name, msg[1]);
		SayText2All(client, buffer);
		PrintToServer(buffer);
		Command_PlayHintSound(client, 0);
		
		return Plugin_Handled;
	}
	if (StrEqual(msg[1], "/hint", false) || StrEqual(msg[1], "/힌트", false))
	{
		Command_PlayHintSound(client, 0);
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 라운드 프리즈 엔드 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 유저의 힌트 카운트 초기화
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!HNS_IsClientHider(i))	continue;
		
		hns_iHintUserCount[i] = 0;
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 라운드 엔드 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 유저의 힌트 카운트 만료 처리
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!HNS_IsClientHider(i))	continue;
		
		hns_iHintUserCount[i] = hns_iHintTotalCount;
	}
	
	return Plugin_Continue;
}
