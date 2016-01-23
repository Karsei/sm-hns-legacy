/*==================================================================
	
	----------------------------------------------
	-*- [Hide and Seek] Module :: Prop Cleaner -*-
	----------------------------------------------
	
	Filename: hns_module_prop_cleaner.sp
	Author: Karsei
	Description: This allows hiders to delete a specific entity.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hns>

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Module :: Prop Cleaner",
	author = HNS_CREATOR,
	description = "This allows hiders to delete a specific entity.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	// F1키 반응 훅
	AddCommandListener(Command_PropCleaner, "autobuy");
	
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Module) 'Prop Cleaner' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 프롭 삭제 모듈 :: 프롭 삭제!
 *
 * @param client			클라이언트 인덱스
 */
public DeleteEntity(client)
{
	// 죽은 사람은 무시
	if (!IsPlayerAlive(client))
	{
		HNS_T_PrintToChat(client, "no use player dead");
		return;
	}
	
	// 거리 설정
	new Float:limitdist = 150.0;
	
	new Float:cleyepos[3], Float:cleyeang[3], Float:tarorigin[3], Float:dist;
	
	GetClientEyePosition(client, cleyepos);
	GetClientEyeAngles(client, cleyeang);
	
	new Handle:trace = TR_TraceRayFilterEx(cleyepos, cleyeang, MASK_SOLID, RayType_Infinite, TraceEntityFilter, client);
	
	if (TR_DidHit(trace))
	{
		// 목표 인덱스
		new target = TR_GetEntityIndex(trace);
		
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", tarorigin);
		
		dist = GetVectorDistance(cleyepos, tarorigin);
		
		if (dist <= limitdist)
		{
			new String:classname[64];
			
			GetEdictClassname(target, classname, sizeof(classname));
			
			//PrintToChatAll("%s -DEBUG- Entity Index: %d, Name: %s, Distance: %f", HNS_PHRASE_PREFIX, target, classname, dist);
			
			// 대부분 맵에 있는 Entity 들은 worldspawn
			// (worldspawn 은 삭제하다간 서버 폭파가 되는 경우가 있으니 하지 말 것!)
			if (StrContains(classname, "prop_", false) != -1)
			{
				AcceptEntityInput(target, "Kill");
				HNS_T_PrintToChat(client, "clean a prop success");
			}
			else
			{
				HNS_T_PrintToChat(client, "clean a prop no that entity");
			}
		}
		else
		{
			HNS_T_PrintToChat(client, "clean a prop too far or no that entity");
		}
	}
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 커맨드 리스너 :: 프롭 지우기 명령어 반응 함수
 *
 * @param client			클라이언트 인덱스
 * @param command			명령어
 * @param args				기타 파라메터
 */
public Action:Command_PropCleaner(client, const String:command[], args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 해당 스킬을 보유한 사람만 가능하도록 처리
	if (HNS_GetClientSkill(client) != HNS_SKILL_PROPDELETE)	return Plugin_Continue;
	
	// 각 팀에 적어도 한 명이 없을 경우는 자유롭게!
	if (HNS_IsGameToggle() && HNS_TeamHasClients())
	{
		HNS_T_PrintToChat(client, "no use");
		return Plugin_Continue;
	}
	
	// 프롭 삭제!
	DeleteEntity(client);
	
	return Plugin_Continue;
}

/**
 * 트레이스 필터 :: 플레이어 구분
 *
 * @param entity			엔티티 인덱스
 * @param mask				알 수 없음
 * @param data				기타 파라메터
 */
public bool:TraceEntityFilter(entity, mask, any:data)
{
	if (entity != data)
	{
		return true;
	}
	
	return false;
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
	
	Pickup_PropDeleteUser();
	return Plugin_Continue;
}


Pickup_PropDeleteUser()
{
	new Handle:aEligibleClients = INVALID_HANDLE;
	new eligibleclients = HNS_CreateEligibleClientList(aEligibleClients, true, true, true, false);
	
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
	HNS_SetClientSkill(iClient, HNS_SKILL_PROPDELETE);
	PrintToChat(iClient, "\x05[HNS] \x03당신은 물건제거기능을 사용할 수 있습니다");
	
	// 핸들 닫기.
	CloseHandle(aEligibleClients);
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