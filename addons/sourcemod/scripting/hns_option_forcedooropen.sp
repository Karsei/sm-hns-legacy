/*==================================================================
	
	---------------------------------------
	-*- [Hide and Seek] Option :: Force Door Open -*-
	---------------------------------------
	
	Filename: hns_option_forcedooropen.sp
	Author: Karsei 
	Description: This forces doors open.
	
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
	name = "[Hide and Seek] Option :: Force Door Open",
	author = HNS_CREATOR,
	description = "This forces doors open.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart);
	
	PrintToServer("%s (Option) 'Force Door Open' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 문 열기 모듈 :: 모든 문을 강제로 엽니다.
 */
ForceDoorOpen()
{
	new maxent = GetMaxEntities();
	new String:classname[64];
	
	for (new i = 1; i <= maxent; i++)
	{
		// 유효한 엔티티가 아니라면 정지
		if (!IsValidEntity(i))	continue;
		if (!IsValidEdict(i))	continue;
		
		// Edict Classname을 획득
		GetEdictClassname(i, classname, sizeof(classname));
		
		// 모든 문은 열리도록 설정
		if (StrContains(classname, "_door", false) != -1)
		{
			AcceptEntityInput(i, "Open");
			HookSingleEntityOutput(i, "OnClose", EntOutput_OnClose);
		}
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
public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 모든 문 열기
	ForceDoorOpen();
	
	return Plugin_Continue;
}

/**
 * 문 열기 모듈 :: OnClose Entity 대응
 *
 * @param output			Entity 이름
 * @param caller			호출한 Entity 인덱스
 * @param activator			작동시킨 Entity 인덱스
 * @param delay				해당 이벤트가 일어나기 전의 지연 시간(초)
 */
public EntOutput_OnClose(const String:output[], caller, activator, Float:delay)
{
	AcceptEntityInput(caller, "Open");
}