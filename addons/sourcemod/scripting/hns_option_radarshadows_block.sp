/*==================================================================
	
	-----------------------------------------------------------
	-*- [Hide and Seek] Option :: Radar and shadows Blocker -*-
	-----------------------------------------------------------
	
	Filename: hns_option_radarshadows_block.sp
	Author: Karsei 
	Description: This controls the client side console variable.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hns>

/*******************************************************
 V A R I A B L E S
*******************************************************/
new g_flFlashDuration;
new g_flFlashMaxAlpha;

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Option :: Radar and shadows Blocker",
	author = HNS_CREATOR,
	description = "This controls the client side console variable.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	//LoadTranslations("plugin.hide_and_seek");
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_blind", Event_PlayerBlind);
	
	// for hiding players on radar
	g_flFlashDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
	if(g_flFlashDuration == -1) SetFailState("%s Couldnt find the m_flFlashDuration offset!", HNS_PHRASE_PREFIX);
	
	g_flFlashMaxAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	if(g_flFlashMaxAlpha == -1) SetFailState("%s Couldnt find the m_flFlashMaxAlpha offset!", HNS_PHRASE_PREFIX);
	
	PrintToServer("%s (Option) 'Radar and shadows Blocker' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnMapStart()
{
	if (!HNS_IsEngineWork())	return;
	
	// 그림자 감추기
	new entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "shadow_control")) != -1)
	{
		SetVariantInt(1);
		AcceptEntityInput(entity, "SetShadowsDisabled");
	}
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 게임 이벤트 :: 라운드 스타트 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 그림자 감추기
	new entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "shadow_control")) != -1)
	{
		SetVariantInt(1);
		AcceptEntityInput(entity, "SetShadowsDisabled");
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
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 레이더 감추기
	SetEntDataFloat(client, g_flFlashDuration, 10000.0, true);
	SetEntDataFloat(client, g_flFlashMaxAlpha, 0.5, true);
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 플레이어 블라인드 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 레이더 감추기
	new Float:flashdura = GetEntDataFloat(client, g_flFlashDuration);
	
	if (flashdura > 0.1)
		flashdura -= 0.1;
	
	if ((client > 0) && (GetClientTeam(client) > 1))
		CreateTimer(flashdura, Timer_FlashEnd, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

/**
 * 타이머 :: 레이더 관련 처리
 *
 * @param timer				타이머 핸들
 * @param client			클라이언트 인덱스
 */
public Action:Timer_FlashEnd(Handle:timer, any:client)
{
	if ((client > 0) && (GetClientTeam(client) > 1))
	{
		SetEntDataFloat(client, g_flFlashDuration, 10000.0, true);
		SetEntDataFloat(client, g_flFlashMaxAlpha, 0.5, true);
	}
	
	return Plugin_Stop;
}