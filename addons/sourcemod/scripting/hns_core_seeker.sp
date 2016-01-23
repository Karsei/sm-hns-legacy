/*==================================================================
	
	----------------------------------------------
	-*- [Hide and Seek] Core :: Seeker Control -*-
	----------------------------------------------
	
	Filename: hns_core_seeker.sp
	Author: Karsei
	Description: Controls Screen Fade-in/Fade-out and movement
				 to Seekers
	
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
 * ENUM
 */
enum CVAR
{
	Handle:HHIDERPUSH
}

/**
 * 변수
 */
new hns_eConvar[CVAR];
new hns_iOffFlags;

/**
 * 플러그인 정보 입력
 */
public Plugin:myinfo = 
{
	name 		= "[Hide and Seek] Core :: Seeker Control",
	author 		= HNS_CREATOR,
	description = "Controls Screen Fade-in/Fade-out and movement to Seekers.",
	version 	= HNS_VERSION,
	url 		= HNS_CREATOR_URL
}

/**
 * 플러그인 시작 시
 */
public OnPluginStart()
{
	hns_eConvar[HHIDERPUSH] = CreateConVar("hns_hider_push_switch", "1", "Seeker Push on?");
	
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	hns_iOffFlags = FindSendPropOffs("CBasePlayer", "m_fFlags");
	if (hns_iOffFlags == -1)
		SetFailState("%s Couldnt find the m_fFlags offset!", HNS_PHRASE_PREFIX);
	
	PrintToServer("%s (Core) 'Seeker Control' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (!HNS_IsEngineWork())	return;
	
	PrecacheSound("radio/go.wav", true);
}

/**
 * 버튼 :: 플레이어 행동 반응
 *
 * @param client			클라이언트 인덱스
 * @param buttons			버튼 (copyback)
 * @param impulse			충격 (copyback)
 * @param vel				플레이어의 속도
 * @param angles			플레이어의 각도
 * @param weapon			플레이어가 무기를 변경할 때 그 후의 새로운 무기 인덱스 (copyback)
 */
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new initbuttons = buttons;
	
	// 숨는 사람의 경우
	if (HNS_IsClientSeeker(client))
	{
		// 밀기 버튼 방지
		if (!GetConVarBool(hns_eConvar[HHIDERPUSH]))
		{
			if (buttons & IN_USE)
				buttons &= ~IN_USE;
		}
	}
	
	// 초기에 누른 버튼 처리와 이후의 버튼 처리가 다르면 변경된 값을 리턴
	if (initbuttons != buttons)
		return Plugin_Changed;
	else
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
	
	// 클라이언트 수가 2명 이상이라면
	if (HNS_TeamHasClients())
	{
		for (new x = 1; x <= MaxClients; x++)
		{
			if (!IsClientInGame(x)) continue;
			if (!IsPlayerAlive(x)) continue;
			if (!HNS_IsClientSeeker(x)) continue;
			
			// 페이드 가동
			HNS_SetClientBlind(x, 255);
			
			// 화면 고정 및 움직임 차단 처리
			HNS_SetClientFreezed(x, true, true, false);
		}
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
	
	for (new x = 1; x <= MaxClients; x++)
	{
		if (!IsClientInGame(x)) continue;
		if (!IsPlayerAlive(x)) continue;
		
		// 페이드 해제
		HNS_SetClientBlind(x, 0);
		
		// 화면 고정 해제 및 움직임 정상 처리
		HNS_SetClientFreezed(x, false);
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: player_team
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		true일 경우 알리지 않습니다.
 */
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	new bool:disconnect = GetEventBool(event, "disconnect");
	
	// 플레이어가 관전자로 갔을 경우
	if (!disconnect && team <= CS_TEAM_SPECTATOR)
	{
		// 페이드 해제
		HNS_SetClientBlind(client, 0);
		
		// 무기 출력
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		
		// 움직임을 정상으로 하고 이동 타입을 옵저버로 변경
		SetEntData(client, hns_iOffFlags, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
		SetEntityMoveType(client, MOVETYPE_OBSERVER);
	}
		
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: player_spawn
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		true일 경우 알리지 않습니다.
 */
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!HNS_IsGameToggle())
	{
		if (HNS_TeamHasClients())
		{
			if (HNS_IsClientHider(client))
			{
				// 페이드 해제
				HNS_SetClientBlind(client, 0);
				
				// 화면 고정 해제 및 움직임 정상 처리
				HNS_SetClientFreezed(client, false);
			}
			
			else if (HNS_IsClientSeeker(client))
			{
				// 페이드 가동
				HNS_SetClientBlind(client, 255);
				
				// 화면 고정 및 움직임 차단 처리
				HNS_SetClientFreezed(client, true, true, false);
			}
		}
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: player_death
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		true일 경우 알리지 않습니다.
 */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 페이드 해제
	HNS_SetClientBlind(client, 0);
	
	// 화면 고정 해제 및 움직임 정상 처리
	HNS_SetClientFreezed(client, false);
	
	return Plugin_Continue;
}

/**
 * 게임 시작 후.
 * 
 * @param start				시작/정지.
 */
public HNS_OnToggleGame_Post(bool:start)
{
	if (!HNS_IsEngineWork()) return;
	
	if (HNS_IsGameToggle())
	{
		for (new x = 1; x <= MaxClients; x++)
		{
			if (!IsClientInGame(x))	continue;
			
			// 페이드 해제
			HNS_SetClientBlind(x, 0);
			
			// 화면 고정 해제 및 움직임 정상 처리
			HNS_SetClientFreezed(x, false);
			
			// Ok! Let's Go
			if (HNS_IsClientSeeker(x))
				EmitSoundToClient(x, "radio/go.wav");
		}
	}
}