/*==================================================================
	
	----------------------------------------------------
	-*- [Hide and Seek] Manage :: Hook User Messages -*-
	----------------------------------------------------
	
	Filename: hns_manage_hookusermsg.sp
	Author: Karsei
	Description: About 'HookUserMessage' Function.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <hns>

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Manage :: Hook User Messages",
	author = HNS_CREATOR,
	description = "About 'HookUserMessage' Function.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("HintText"), Command_HintText, true);
	
	PrintToServer("%s (Manage) 'Hook User Messages' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 유저 메세지 훅 :: 힌트 텍스트 처리
 *
 * @param msg_id			메세지 인덱스
 * @param bf				버퍼 핸들
 * @param players			클라이언트 인덱스 배열
 * @param playersNum		클라이언트 인원
 * @param reliable			의존성 유/무
 * @param init				초기 메세지 유/무
 */
public Action:Command_HintText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	decl String:buffer[256];
	
	buffer[0] = '\0';
	BfReadString(bf, buffer, sizeof(buffer), false);
	
	// '적을 발견했습니다' 메세지 삭제
	if (StrContains(buffer, "spotted_an_enemy") != -1)
		return Plugin_Handled;
	// '탄약이 다 떨어졌습니다' 메세지 삭제
	if (StrContains(buffer, "out_of_ammo") != -1)
		return Plugin_Handled;
	
	return Plugin_Continue;
}