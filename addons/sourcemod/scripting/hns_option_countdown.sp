/*==================================================================
	
	-----------------------------------------------------
	-*- [Hide and Seek] Option :: Countdown Displayer -*-
	-----------------------------------------------------
	
	Filename: hns_option_countdown.sp
	Author: Karsei
	Description: Game Countdown Displayer
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved.
	
==================================================================*/

/**
 * 해더 정렬
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hns>

/**
 * 세미콜론 지시
 */
#pragma semicolon 1

/**
 * 플러그인 정보 입력
 */
public Plugin:myinfo = 
{
	name 		= "[Hide and Seek] Option :: Countdown Displayer",
	author 		= HNS_CREATOR,
	description = "Announce the remaining time for game start.",
	version 	= HNS_VERSION,
	url 		= HNS_CREATOR_URL
}

/**
 * 핸들 리스트
 */
new Handle:g_hCVDelay = INVALID_HANDLE;
new Handle:g_hCVCountdown = INVALID_HANDLE;
new Handle:tCountdown = INVALID_HANDLE;

/**
 * 플러그인 시작 시
 */
public OnPluginStart()
{
	LoadTranslations("plugin.hide_and_seek");
	
	g_hCVCountdown = CreateConVar("hns_display_countdown", "1", "Enable/Disable countdown display");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	
	PrintToServer("%s (Option) 'Countdown Displayer' has been loaded successfully.", HNS_SERVER_PREFIX);
}

/**
 * 맵 시작 시
 */
public OnMapStart()
{
	tCountdown = INVALID_HANDLE;
}

/**
 * 모든 플러그인이 불러와진 후
 */
public OnAllPluginsLoaded()
{
	// 게임모드 시작 시간 콘솔명령어를 찾기.
	g_hCVDelay = FindConVar("hns_start_delay");
}

/**
 * 게임이벤트 :: round_start
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		true일 경우 알리지 않습니다.
 */
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// 카운트다운 타이머 종료.
	HNS_EndTimer(tCountdown);
}

/**
 * 게임이벤트 :: round_freeze_end
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		true일 경우 알리지 않습니다.
 */
public Action:Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// 클라이언트 수가 2명 이상이라면 타이머 허용 장치 가동.
	if (HNS_TeamHasClients())
	{
		// 카운트다운 타이머 종료.
		HNS_EndTimer(tCountdown);
		
		// 게임모드 시작 시간값을 획득
		new Float:delaytime = GetConVarFloat(g_hCVDelay);
		
		// 카운트다운 표시 여부를 획득
		new bool:countdown = GetConVarBool(g_hCVCountdown);
		
		// 카운트다운을 할 수 있고 카운트다운 시간이 1.0초보다 크다면
		if (countdown && delaytime > 1.0)
		{
			// 게임이 시작하기 전까지 시간을 저장하고 카운터를 도입합니다.
			// Store the time until game mode start, and initialize the counter.
			new Handle:hCountdownData = CreateDataPack();
			WritePackFloat(hCountdownData, delaytime);
			WritePackFloat(hCountdownData, 0.0);
			
			// 타이머 생성.
			tCountdown = CreateTimer(1.0, Timer_Countdown, hCountdownData, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			
			// 카운트다운값을 표시합니다.
			// Display initial tick.
			Timer_Countdown(tCountdown, hCountdownData);
		}
	}
}

/**
 * 타이머 ::  게임시작을 알리는 카운트다운
 *
 * @param timer				타이머 핸들
 * @param hCountdownData	카운트다운 데이터
 */
public Action:Timer_Countdown(Handle:timer, Handle:hCountdownData)
{
	// 카운트다운 허용여부 획득
	new bool:countdown = GetConVarBool(g_hCVCountdown);
	
	// 허용 되어있지 않다면
	if (!countdown)
	{
		// 타이머 제거 후 정지.
		HNS_EndTimer(tCountdown, false);
		CloseHandle(hCountdownData);
		return Plugin_Stop;
	}

	// 데이터팩으로부터 정보를 읽습니다.
	ResetPack(hCountdownData);
	new Float:length = ReadPackFloat(hCountdownData);
	new Float:counter = ReadPackFloat(hCountdownData);

	// 카운트다운이 완료되었는지 확인합니다.
	if (counter >= length)
	{
		// 타이머 제거.
		HNS_EndTimer(tCountdown, false);
		CloseHandle(hCountdownData);
		return Plugin_Stop;
	}

	// 클라이언트들에게 카운트다운 텍스트를 출력합니다.
	HNS_T_PrintCenterTextAll(false, "Game countdown", RoundToNearest(length - counter));

	counter++;

	// 새 카운터 값을 데이터팩에 작성합니다.
	// (Write the new counter value to the datapack.)
	ResetPack(hCountdownData);
	WritePackFloat(hCountdownData, length);
	WritePackFloat(hCountdownData, counter);
	
	// 반복 계속.
	return Plugin_Continue;
}

/**
 * 게임 시작 후.
 * 
 * @param start			시작/정지.
 */
public HNS_OnGameToggle_Post(bool:start)
{
	if (HNS_IsGameToggle())
	{
		// 타이머 종료.
		HNS_EndTimer(tCountdown);
	}
}
