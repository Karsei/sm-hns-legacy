/*==================================================================
	
	-----------------------------------------------
	-*- [Hide and Seek] Option :: Auto Announce -*-
	-----------------------------------------------
	
	Filename: hns_option_auto_announce.sp
	Author: Karsei 
	Description: This shows several messages at regular intervals.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <hns>

#define	ANNOUNCE_COUNT				8

/*******************************************************
 E N U M S
*******************************************************/
enum CVAR
{
	Handle:HANNOUNCEDELAY
}

/*******************************************************
 V A R I A B L E S
*******************************************************/
new hns_eConvar[CVAR];
new Handle:hns_sShowAnnounceMsgTimer = INVALID_HANDLE;
new const String:hns_sShowMessages[ANNOUNCE_COUNT][2][] = {
	// 하위 첫 배열: 메세지, 두 번째 배열: 타입(0 - Notice, 1 - Tip)
	{"이 서버는 숨바꼭질 서버입니다.", "0"},
	{"현재 이 숨바꼭질 모드는 개발 상태입니다.", "0"},
	{"개발자: Karsei, Karsei", "0"},
	{"채팅창에 \"!힌트\"를 치면 힌트를 줄 수 있습니다.", "1"},
	{"채팅창에 \"!3\"을 치면 인칭을 변경할 수 있습니다.", "1"},
	{"채팅창에 \"!얼음\"을 치면 해당 자리에서 고정할 수 있습니다.", "1"},
	{"건의 사항이나 아이디어가 있으시면 해당 서버 어드민에게 의견을 주시면 됩니다.", "0"},
	{"비신사적인 언동을 하는 유저가 있는 경우 서버 어드민에게 신고를 하실 수 있습니다.", "0"}
};

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Option :: Auto Announce",
	author = HNS_CREATOR,
	description = "This shows several messages at regular intervals.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	hns_eConvar[HANNOUNCEDELAY] = CreateConVar("hns_announce_delay", "80");
	
	PrintToServer("%s (Option) 'Auto Announce' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (!HNS_IsEngineWork())	return;
	
	hns_sShowAnnounceMsgTimer = CreateTimer(GetConVarFloat(hns_eConvar[HANNOUNCEDELAY]), Timer_ShowAnnounceMsg, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	if (hns_sShowAnnounceMsgTimer != INVALID_HANDLE)
	{
		KillTimer(hns_sShowAnnounceMsgTimer);
		hns_sShowAnnounceMsgTimer = INVALID_HANDLE;
	}
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 타이머 :: 자동 알림 메세지 출력
 *
 * @param timer				타이머 핸들
 */
public Action:Timer_ShowAnnounceMsg(Handle:timer)
{
	new select = GetRandomInt(0, ANNOUNCE_COUNT-1);
	new type = StringToInt(hns_sShowMessages[select][1]);
	
	new String:prefix[32];
	
	if (type == 0)	Format(prefix, sizeof(prefix), "\x04-Notice-");
	else if (type == 1)	Format(prefix, sizeof(prefix), "\x07E1B771-Tip-");
	
	PrintToChatAll("\x05%s %s \x03%s", HNS_PHRASE_PREFIX, prefix, hns_sShowMessages[select][0]);
	
	return Plugin_Continue;
}