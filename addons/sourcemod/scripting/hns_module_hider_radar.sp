/*==================================================================
	
	---------------------------------------------
	-*- [Hide and Seek] Module :: Hider Radar -*-
	---------------------------------------------
	
	Filename: hns_module_hider_radar.sp
	Author: Karsei
	Description: This allows seekers to check near the closest 
				 specific hider.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hns>

#define RADAR_RANGE					2000
#define RADAR_SOUND					"weapons/c4/c4_beep1.wav"

/*******************************************************
 V A R I A B L E S
*******************************************************/
new Handle:hns_hHiderRadar[MAXPLAYERS+1];
new Handle:hns_hCloseHiderRadar[MAXPLAYERS+1];
new bool:hns_bUseUserRadar[MAXPLAYERS+1];

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Module :: Hider Radar",
	author = HNS_CREATOR,
	description = "This allows seekers to check near the closest specific hider.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	// F1키 반응 훅
	// (추후에 변경 가능)
	AddCommandListener(Command_HiderRadar, "autobuy");
	
	PrecacheSound(RADAR_SOUND, true);
	
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_end", Event_OnRoundEnd);
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Module) 'Hider Radar' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnMapEnd()
{
	// 타이머 초기화
	for (new i = 1; i <= MaxClients; i++)
	{
		if (hns_hHiderRadar[i] != INVALID_HANDLE)
		{
			KillTimer(hns_hHiderRadar[i]);
		}
		hns_hHiderRadar[i] = INVALID_HANDLE;
		if (hns_hCloseHiderRadar[i] != INVALID_HANDLE)
		{
			KillTimer(hns_hCloseHiderRadar[i]);
		}
		hns_hCloseHiderRadar[i] = INVALID_HANDLE;
		
		hns_bUseUserRadar[i] = false;
	}
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 숨는 사람 레이더 모듈 :: 숨는 사람 찾기 처리 전 단계
 *
 * @param client			클라이언트 인덱스
 */
public HiderRadar(client)
{
	// 죽은 사람은 무시
	if (!IsPlayerAlive(client))
	{
		HNS_T_PrintToChat(client, "no use player dead");
		return;
	}
	
	// 지속 시간
	new Float:delay = 30.0;
	
	// 반복 시간
	new Float:backdelay = 3.0;
	
	// 타이머 작동!
	hns_hHiderRadar[client] = CreateTimer(backdelay, Timer_HiderRadar, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	hns_hCloseHiderRadar[client] = CreateTimer(delay, Timer_CloseHiderRadar, client, TIMER_FLAG_NO_MAPCHANGE);
	
	HNS_T_PrintToChat(client, "hider radar set");
}

/**
 * 숨는 사람 레이더 모듈 :: 가장 가까운 숨는 사람 찾기
 *
 * @param client			클라이언트 인덱스
 * @param range				찾으려는 범위
 * @param targetdist		대상과의 거리 (copyback)
 * @return	대상 인덱스
 */
FindClosestTarget(client, Float:range, &Float:targetdist=0.0)
{
	new target;
	new Float:clientpos[3], Float:targetpos[3], Float:userdist[MAXPLAYERS+1];
	
	// 모든 숨는 사람들과의 거리를 측정
	for (new i = 1; i <= MaxClients; i++)
	{
		if ((client != i) && IsClientInGame(i) && IsPlayerAlive(i) && HNS_IsClientHider(i))
		{
			GetClientAbsOrigin(client, clientpos);
			GetClientAbsOrigin(i, targetpos);
			
			new Float:dist = GetVectorDistance(clientpos, targetpos);
			
			// 측정한 거리가 만약 설정한 range 보다 낮거나 같으면 체크
			if (dist <= range)
				userdist[i] = dist;
		}
	}
	
	// 측정한 거리 값들 중에서 최솟값 체크
	for (new k = 1; k <= MaxClients; k++)
	{
		if ((client != k) && IsClientInGame(k) && IsPlayerAlive(k) && HNS_IsClientHider(k))
		{
			if (targetdist == 0.0)
			{
				targetdist = userdist[k];
				target = k;
			}
			else
			{
				if (targetdist > userdist[k])
				{
					targetdist = userdist[k];
					target = k;
				}
			}
		}
	}
	
	if (targetdist == 0.0)
		return -1;
	
	return target;
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 커맨드 리스너 :: 숨는 사람 레이더 명령어 반응 함수
 *
 * @param client			클라이언트 인덱스
 * @param command			명령어
 * @param args				기타 파라메터
 */
public Action:Command_HiderRadar(client, const String:command[], args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 해당 스킬을 보유한 사람만 가능하도록 처리
	if (HNS_GetClientSkill(client) != HNS_SKILL_WAVERADAR)	return Plugin_Continue;
	
	// 각 팀에 적어도 한 명이 없을 경우는 자유롭게!
	if (!HNS_IsGameToggle() && HNS_TeamHasClients())
	{
		HNS_T_PrintToChat(client, "hider radar no use");
		return Plugin_Continue;
	}
	
	// 이미 사용하고 있는 경우
	if (hns_bUseUserRadar[client])
	{
		HNS_T_PrintToChat(client, "hider radar now using");
		return Plugin_Continue;
	}
	
	// 찾자!
	HiderRadar(client);
	
	return Plugin_Continue;
}

/**
 * 타이머 :: 레이더 처리
 *
 * @param timer				타이머 핸들
 * @param client			클라이언트 인덱스
 */
public Action:Timer_HiderRadar(Handle:timer, any:client)
{
	hns_bUseUserRadar[client] = true;
	
	// 찾으려는 범위 설정
	new Float:range = float(RADAR_RANGE);
	
	new Float:dist;
	
	FindClosestTarget(client, range, dist);
	
	if (dist <= range)
	{
		// 비율 체크
		// ratio 변수가 작을 수록 클라이언트와 가까이!
		new Float:ratio = FloatDiv(dist, range);
		
		//PrintToChat(client, "Ratio: %f, dist: %f", ratio, dist);
		new Handle:sendparam = CreateArray(), Float:setvol;
		
		PushArrayCell(sendparam, client);
		
		if (ratio >= 0.8)
		{
			setvol = 0.2;
			
			PushArrayCell(sendparam, setvol);
			
			CreateTimer(0.4, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.8, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(1.2, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(1.6, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if ((ratio < 0.8) && (ratio >= 0.5))
		{
			setvol = 0.4;
			
			PushArrayCell(sendparam, setvol);
			
			CreateTimer(0.3, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.7, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(1.1, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(1.5, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if ((ratio < 0.5) && (ratio >= 0.3))
		{
			setvol = 0.7;
			
			PushArrayCell(sendparam, setvol);
			
			CreateTimer(0.2, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.6, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(1.0, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(1.4, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if ((ratio < 0.3) && (ratio > 0.0))
		{
			setvol = 1.0;
			
			PushArrayCell(sendparam, setvol);
			
			CreateTimer(0.0, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.3, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.6, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.9, Timer_PlayRadarSound, sendparam, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

/**
 * 타이머 :: 레이더 처리 타이머 핸들 제거
 *
 * @param timer				타이머 핸들
 * @param client			클라이언트 인덱스
 */
public Action:Timer_CloseHiderRadar(Handle:timer, any:client)
{
	if (hns_hHiderRadar[client] != INVALID_HANDLE)
	{
		KillTimer(hns_hHiderRadar[client]);
	}
	hns_hHiderRadar[client] = INVALID_HANDLE;
	hns_bUseUserRadar[client] = false;
	
	HNS_T_PrintToChat(client, "hider radar set end");
	
	return Plugin_Stop;
}

/**
 * 타이머 :: 레이더 소리 재생
 *
 * @param timer				타이머 핸들
 * @param data				기타 파라메터
 */
public Action:Timer_PlayRadarSound(Handle:timer, any:data)
{
	new client = GetArrayCell(data, 0);
	new Float:vol = GetArrayCell(data, 1);
	
	EmitSoundToClient(client, RADAR_SOUND, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, vol);
	
	return Plugin_Stop;
}

/**
 * 게임 이벤트 :: 라운드 프리즈 엔드 이벤트 (여기에서 스킬을 보유할 사람을 지정.)
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	Pickup_WaveRadarUser();
	return Plugin_Continue;
}

Pickup_WaveRadarUser()
{
	new Handle:aEligibleClients = INVALID_HANDLE;
	new eligibleclients = HNS_CreateEligibleClientList(aEligibleClients, true, true, false, true);
	
	// 적합한 클라이언트가 없다면 정지.
	if (!eligibleclients)
	{
		// 핸들 닫기.
		CloseHandle(aEligibleClients);
		PrintToServer("[HNS :: Wave Radar] There's no eligible client.");
		return;
	}
	
	new iClient;
	
	for (new x = 0; x < eligibleclients; x++)
	{
		// Stop pruning if there is only 1 player left.
		if (eligibleclients <= 1) break;
		
		iClient = GetArrayCell(aEligibleClients, x);
	}
	
	new randindex;
	randindex = GetRandomInt(0, eligibleclients - 1);
	iClient = GetArrayCell(aEligibleClients, randindex);
	
	// 스킬 설정.
	HNS_SetClientSkill(iClient, HNS_SKILL_WAVERADAR);
	HNS_T_PrintToChat(iClient, "hider radar you are selected");
	
	// 핸들 닫기.
	CloseHandle(aEligibleClients);
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
	
	// 타이머 초기화
	for (new i = 1; i <= MaxClients; i++)
	{
		if (hns_hHiderRadar[i] != INVALID_HANDLE)
		{
			KillTimer(hns_hHiderRadar[i]);
		}
		hns_hHiderRadar[i] = INVALID_HANDLE;
		if (hns_hCloseHiderRadar[i] != INVALID_HANDLE)
		{
			KillTimer(hns_hCloseHiderRadar[i]);
		}
		hns_hCloseHiderRadar[i] = INVALID_HANDLE;
		
		hns_bUseUserRadar[i] = false;
	}
	
	return Plugin_Continue;
}



/**
 * 배열을 생성하여 조건에 적합한 클라이언트를 이에 채워넣습니다.
 *
 * @param arrayEligibleClients		배열의 핸들, 이것이 완료되었을 때 CloseHandle 함수를 호출하는 것을 잊지 마세요.
 * @param team						클라이언트는 오직 팀 안에 들어가 있어야만 적합합니다.
 * @param alive						클라이언트는 오직 살아있어야만 적합합니다.
 * @param hider						클라이언트는 오직 Hider(숨는 사람)이어야만 적합합니다.
 * @param seeker					클라이언트는 오직 Seeker(찾는 사람)이어야만 적합합니다.
 */
stock HNS_CreateEligibleClientList(&Handle:arrayEligibleClients, bool:team = false, bool:alive = false, bool:hider = false, bool:seeker = false)
{
	// 배열 생성.
	arrayEligibleClients = CreateArray();
	
	// 적합한 클라이언트들을 리스트에 채워넣는다.
	// x = 클라이언트 인덱스
	for (new x = 1; x <= MaxClients; x++)
	{
		// 클라이언트가 in-game 상태가 아니면 정지.
		if (!IsClientInGame(x)) continue;
		
		// 클라이언트가 팀에 들어가있지 않으면 정지.
		if (team && !HNS_IsClientOnTeam(x)) continue;
		
		// 클라이언트가 죽어있다면 정지.
		if (alive && !IsPlayerAlive(x)) continue;
		
		// 클라이언트가 Hider (숨는 사람)이면 정지.
		if (hider && !HNS_IsClientHider(x)) continue;
		
		// 클라이언트가 Seeker (찾는 사람)이면 정지.
		if (seeker && !HNS_IsClientSeeker(x)) continue;
		
		// 적합한 클라이언트를 배열에 집어넣는다.
		PushArrayCell(arrayEligibleClients, x);
	}
	
	return GetArraySize(arrayEligibleClients);
}