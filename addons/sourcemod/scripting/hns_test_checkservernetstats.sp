/*==================================================================
	
	------------------------------------------------------
	-*- [Hide and Seek] Test :: Check Server Net Stats -*-
	------------------------------------------------------
	
	Filename: hns_test_checkservernetstats.sp
	Author: Karsei 
	Description: FOR TEST.
	
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
new Handle:hns_hTimerNetStats = INVALID_HANDLE;
new bool:hns_bTimerOpen = false;

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Test :: Check Server Net Stats",
	author = HNS_CREATOR,
	description = "FOR TEST.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	RegAdminCmd("sm_servernetstats", Command_TestServerNetStats, ADMFLAG_ROOT);
	
	PrintToServer("%s (Test) 'Check Server Net Stats' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnMapEnd()
{
	if (hns_hTimerNetStats != INVALID_HANDLE)
	{
		KillTimer(hns_hTimerNetStats);
		hns_hTimerNetStats = INVALID_HANDLE;
	}
	hns_bTimerOpen = false;
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 테스트 모듈 :: 서버 네트워크 트래픽 속도 및 Tick 체크
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_TestServerNetStats(client, args)
{
	if (!hns_bTimerOpen)
	{
		if (hns_hTimerNetStats == INVALID_HANDLE)
		{
			hns_bTimerOpen = true;
			hns_hTimerNetStats = CreateTimer(1.0, Timer_CheckServerNetStats, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("%s Opening Server Net Stats is Successful!", HNS_PHRASE_PREFIX);
		}
	}
	else
	{
		if (hns_hTimerNetStats != INVALID_HANDLE)
		{
			hns_bTimerOpen = false;
			KillTimer(hns_hTimerNetStats);
			hns_hTimerNetStats = INVALID_HANDLE;
		}
	}
	
	return Plugin_Continue;
}

/**
 * 타이머 :: 서버 네트워크 트래픽 속도 및 Tick을 힌트 텍스트로 출력
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Timer_CheckServerNetStats(Handle:timer, any:client)
{
	new Float:svin, Float:svout, Float:tickinterval;
	
	GetServerNetStats(svin, svout);
	tickinterval = GetTickInterval();
	
	PrintHintTextToAll("-*- Average Server Network Traffic -*-\n(bytes/sec)\nin: %f\nout: %f\n \n-*- Tick -*-\nTick Interval: %f", svin, svout, tickinterval);
	
	return Plugin_Continue;
}