/*==================================================================
	
	----------------------------------------------------
	-*- [Hide and Seek] Manage :: Game Round Manager -*-
	----------------------------------------------------
	
	Filename: hns_manage_round.sp
	Author: Karsei
	Description: Manages the round start/end
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

/**
 * 헤더 정렬
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
 * ENUM
 */
enum CVAR
{
	Handle:HSTARTDELAY,
	Handle:HWINFRAGSPOINT
}


/**
 * 변수
 */
new g_eConvar[CVAR];
new Handle:tCountdown = INVALID_HANDLE;
new Handle:tRoundEnd = INVALID_HANDLE;
new Handle:tRoundClock = INVALID_HANDLE;

new g_iCurRoundStart = 0;


/**
 * 플러그인 정보 입력
 */
public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Manage :: Game Round Manager",
	author		= HNS_CREATOR,
	description = "Manages the round start/end",
	version		= HNS_VERSION,
	url			= HNS_CREATOR_URL
}

/**
 * 플러그인 시작 시
 */
public OnPluginStart()
{
	// 콘바
	g_eConvar[HSTARTDELAY] = CreateConVar("hns_start_delay", "30");
	g_eConvar[HWINFRAGSPOINT] = CreateConVar("hns_win_frags_point", "5");
	
	// 이벤트
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_end", Event_RoundEnd);
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Manage) 'Game Round Manager' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 맵 시작 시
 */
public OnMapStart()
{
	if (!HNS_IsEngineWork())	return;
	
	// 모드선택 타이머와 라운드종료 타이머, 라운드 타임 시계의 핸들 초기화.
	tCountdown = INVALID_HANDLE;
	tRoundEnd = INVALID_HANDLE;
	tRoundClock = INVALID_HANDLE;
}

/**
 * 맵 종료 시
 */
public OnMapEnd()
{
	if (!HNS_IsEngineWork())	return;
	
	// 카운트다운 타이머 정지.
	if (tCountdown != INVALID_HANDLE)
	{
		KillTimer(tCountdown);
	}
	tCountdown = INVALID_HANDLE;
	
	// 라운드 종료 타이머 정지.
	if (tRoundEnd != INVALID_HANDLE)
	{
		KillTimer(tRoundEnd);
	}
	tRoundEnd = INVALID_HANDLE;
	
	// 라운드 정보 타이머 정지.
	if (tRoundClock != INVALID_HANDLE)
	{
		KillTimer(tRoundClock);
	}
	tRoundClock = INVALID_HANDLE;
}

/**
 * 게임 이벤트 :: round_start
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		true일 경우 알리지 않습니다.
 */
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 본격적인 게임 취소
	HNS_ToggleGame(false);
	
	// 카운트다운 타이머 정지.
	if (tCountdown != INVALID_HANDLE)
	{
		KillTimer(tCountdown);
	}
	tCountdown = INVALID_HANDLE;
	
	// 라운드 종료 타이머 정지.
	if (tRoundEnd != INVALID_HANDLE)
	{
		KillTimer(tRoundEnd);
	}
	tRoundEnd = INVALID_HANDLE;
	
	// 라운드 정보 타이머 정지.
	if (tRoundClock != INVALID_HANDLE)
	{
		KillTimer(tRoundClock);
	}
	tRoundClock = INVALID_HANDLE;
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: round_freeze_end
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		true일 경우 알리지 않습니다.
 */
public Action:Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 2인 이상일 때만 작동
	if (!HNS_TeamHasClients())	return Plugin_Continue;
	
	// 카운트다운 시작.
	if (tCountdown != INVALID_HANDLE) tCountdown = INVALID_HANDLE;
	
	new Float:actiontime = GetConVarFloat(g_eConvar[HSTARTDELAY]);
	tCountdown = CreateTimer(actiontime, Timer_StartGame, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// 라운드 정상종료를 위한 타이머 동작
	if (tRoundEnd != INVALID_HANDLE) tRoundEnd = INVALID_HANDLE;
	
	// 라운드 시간을 60.0 초 단위로 변환하여 이를 타이머 발동 시간으로 지정
	new Float:server_roundtime = GetConVarFloat(FindConVar("mp_roundtime"));
	server_roundtime *= 60.0;
	tRoundEnd = CreateTimer(server_roundtime, Timer_RoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// 오른쪽 HUD 라운드 정보 생성
	g_iCurRoundStart = GetTime();
	tRoundClock = CreateTimer(0.5, Timer_RoundInfo, RoundToNearest(server_roundtime), TIMER_FLAG_NO_MAPCHANGE);
	
	// 숨기 관련 메세지 출력
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))	continue;
		if (!IsPlayerAlive(i))	continue;
		
		if (HNS_IsClientHider(i))
			HNS_T_PrintToChat(i, "start hide", GetConVarInt(g_eConvar[HSTARTDELAY]));
		else if (HNS_IsClientSeeker(i))
			HNS_T_PrintToChat(i, "wait hide", GetConVarInt(g_eConvar[HSTARTDELAY]));
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: round_end
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		true일 경우 알리지 않습니다.
 */
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 카운트다운 타이머 정지.
	if (tCountdown != INVALID_HANDLE)
	{
		KillTimer(tCountdown);
	}
	tCountdown = INVALID_HANDLE;
	
	// 라운드 종료 타이머 정지.
	if (tRoundEnd != INVALID_HANDLE)
	{
		KillTimer(tRoundEnd);
	}
	tRoundEnd = INVALID_HANDLE;
	
	// 라운드 정보 타이머 정지.
	if (tRoundClock != INVALID_HANDLE)
	{
		KillTimer(tRoundClock);
	}
	tRoundClock = INVALID_HANDLE;
	
	// 이긴 팀에게는 점수를!
	new teamid, bool:alivehider, winnerteam = GetEventInt(event, "winner");
	new getcvfrags = GetConVarInt(g_eConvar[HWINFRAGSPOINT]);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (HNS_IsClientHider(i) && (teamid == 0))
			{
				if (GetClientTeam(i) == CS_TEAM_T)	teamid = CS_TEAM_T;
				else if (GetClientTeam(i) == CS_TEAM_CT)	teamid = CS_TEAM_CT;
			}
			
			if (teamid > CS_TEAM_SPECTATOR)	break;
		}
	}
	
	if (winnerteam == teamid)
	{
		for (new k = 1; k <= MaxClients; k++)
		{
			if (IsClientInGame(k) && IsPlayerAlive(k) && (GetClientTeam(k) > CS_TEAM_SPECTATOR))
			{
				if (HNS_IsClientHider(k))
				{
					if (getcvfrags > 0)
					{
						new setfrags;
						
						setfrags = GetClientFrags(k) + getcvfrags;
						SetEntProp(k, Prop_Data, "m_iFrags", setfrags, 4);
						alivehider = true;
					}
				}
				// 라운드가 끝났을 때 살아있는 사람은 모두 무적 처리
				SetEntProp(k, Prop_Data, "m_takedamage", 0, 1);
			}
		}
		
		// 점수 획득 메세지 출력
		if (alivehider)
			HNS_T_PrintToChatAll(false, false, "hiders get frags", getcvfrags);
	}
	
	return Plugin_Continue;
}

/**
 * 타이머 :: 카운트 다운이 끝나고 난 후의 처리
 *
 * @param timer				타이머 핸들
 */
public Action:Timer_StartGame(Handle:timer)
{
	// 타이머 핸들 초기화.
	tCountdown = INVALID_HANDLE;
	
	// 플레이어가 존재하면 시작.
	if (HNS_TeamHasClients())
	{
		HNS_ToggleGame(true);
		
		// 숨기 관련 메세지 출력
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))	continue;
			if (!IsPlayerAlive(i))	continue;
			
			if (HNS_IsClientHider(i))
				HNS_T_PrintToChat(i, "be careful hide", GetConVarInt(g_eConvar[HSTARTDELAY]));
			else if (HNS_IsClientSeeker(i))
				HNS_T_PrintToChat(i, "find hider", GetConVarInt(g_eConvar[HSTARTDELAY]));
		}
	}
	
	// 아니면 스탑.
	else
	{
		HNS_ToggleGame(false);
		PrintToServer("%s There's no client to play the game.", HNS_PHRASE_PREFIX);
	}
}

/**
 * 타이머 :: 라운드 엔드 시에 별도로 처리할 타이머
 *
 * @param timer				타이머 핸들
 */
public Action:Timer_RoundEnd(Handle:timer)
{
	// 타이머 핸들 초기화.
	tRoundEnd = INVALID_HANDLE;
	
	// 엔진과 게임이 동작하고 있는 상태에서
	if (HNS_IsEngineWork() && HNS_IsGameToggle())
	{
		// 숨는 사람이 아닌 플레이어들을 라운드 시간이 0:00일 때 사살시킨다.
		// x = 클라이언트 인덱스.
		for (new x = 1; x <= MaxClients; x++)
		{
			// 게임에 없으면 패스.
			if (!IsClientInGame(x)) continue;
			
			// 살아있지 않으면 패스.
			if (!IsPlayerAlive(x)) continue;
			
			// 술래 아니면 패스.
			if (!HNS_IsClientSeeker(x)) continue;
			
			// 플레이어 사살.
			ForcePlayerSuicide(x);
		}
	}
}

/**
 * 타이머 :: 라운드 정보
 *
 * @param timer				타이머 핸들
 * @param roundTime			라운드 시간
 */
public Action:Timer_RoundInfo(Handle:timer, any:roundTime)
{
	decl String:roundinfo[256];
	new seconds = roundTime - GetTime() + g_iCurRoundStart;
	
	new minutes = RoundToFloor(float(seconds) / 60.0);
	new secs = seconds - minutes*60;
	
	new tnum, ctnum;
	
	for (new k = 1; k <= MaxClients; k++)
	{
		if (IsClientInGame(k) && IsPlayerAlive(k))
		{
			if (HNS_IsClientHider(k))	tnum++;
			else if (HNS_IsClientSeeker(k))	ctnum++;
		}
	}
	
	new String:gfoldername[32];
	
	GetGameFolderName(gfoldername, sizeof(gfoldername));
	
	if (StrEqual(gfoldername, "csgo"))
	{
		if (secs < 10)
			Format(roundinfo, sizeof(roundinfo), "남은 시간\n  %d:0%d", minutes, secs);
		else
			Format(roundinfo, sizeof(roundinfo), "남은 시간\n  %d:%d", minutes, secs);
	}
	else
	{
		if (secs < 10)
			Format(roundinfo, sizeof(roundinfo), "-*- 남은 시간 -*-\n         %d:0%d\n \n-*-     인원     -*-\n 숨는 사람: %d 명\n 찾는 사람: %d 명", minutes, secs, tnum, ctnum);
		else
			Format(roundinfo, sizeof(roundinfo), "-*- 남은 시간 -*-\n         %d:%d\n \n-*-     인원     -*-\n 숨는 사람: %d 명\n 찾는 사람: %d 명", minutes, secs, tnum, ctnum);
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			new Handle:hBuffer = StartMessageOne("KeyHintText", i);
			BfWriteByte(hBuffer, 1);
			BfWriteString(hBuffer, roundinfo);
			EndMessage();
		}
	}
	
	if (seconds > 0)
		tRoundClock = CreateTimer(0.5, Timer_RoundInfo, roundTime, TIMER_FLAG_NO_MAPCHANGE);
	else
		tRoundClock = INVALID_HANDLE;
	
	return Plugin_Stop;
}