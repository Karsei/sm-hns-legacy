/*==================================================================
	
	---------------------------------------------
	-*- [Hide and Seek] Manage :: Round Sound -*-
	---------------------------------------------
	
	Filename: hns_manage_round_sound.sp
	Author: Karsei
	Description: This plays several round sounds.
	
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
new Handle:hns_hStartDelay = INVALID_HANDLE;

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Manage :: Round Sound",
	author = HNS_CREATOR,
	description = "This plays several round sounds.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	HookEvent("round_freeze_end", Event_OnRoundFreezeEnd);
	HookEvent("round_end", Event_OnRoundEnd);
	
	PrintToServer("%s (Manage) 'Round Sound' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (!HNS_IsEngineWork())	return;
	
	PrecacheSound("hnstest/temproundstart.mp3", true);
	PrecacheSound("hnstest/temproundend.mp3", true);
	PrecacheSound("hnstest/temproundgaming.mp3", true);
}

/**
 * 모든 플러그인이 불러와진 후
 */
public OnAllPluginsLoaded()
{
	// 게임모드 시작 시간 콘솔명령어를 찾기.
	hns_hStartDelay = FindConVar("hns_start_delay");
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
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
	
	// 각 팀에 적어도 한 명이 있을 때 작동
	if (!HNS_TeamHasClients())	return Plugin_Continue;
	
	EmitSoundToAll("hnstest/temproundstart.mp3");
	CreateTimer(GetConVarFloat(hns_hStartDelay), Timer_GameStart, _, TIMER_FLAG_NO_MAPCHANGE);
	
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
	
	// 각 팀에 적어도 한 명이 있을 때 작동
	if (!HNS_TeamHasClients())	return Plugin_Continue;
	
	EmitSoundToAll("hnstest/temproundend.mp3");
	
	return Plugin_Continue;
}

/**
 * 타이머 :: 게임 시작 후
 *
 * @param timer				타이머 핸들
 */
public Action:Timer_GameStart(Handle:timer)
{
	if (!HNS_IsEngineWork())	return Plugin_Stop;
	
	// 각 팀에 적어도 한 명이 있을 때 작동
	if (!HNS_TeamHasClients())	return Plugin_Stop;
	
	EmitSoundToAll("hnstest/temproundgaming.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.7);
	
	return Plugin_Stop;
}