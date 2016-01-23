/*==================================================================
	
	---------------------------------------------------
	-*- [Hide and Seek] Option :: Objective Remover -*-
	---------------------------------------------------
	
	Filename: hns_option_objectiveremover.sp
	Author: Karsei
	Description: This removes no required objectives in HNS.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#include <sourcemod>
#include <sdktools>
#include <hns>

#pragma semicolon 1

/**
 * @section 맵에서 지울 대상 (엔티티)
 */
#define TO_REMOVE_OBJECTIVES	"func_bomb_target|func_hostage_rescue|hostage_entity|c4"
/**
 * @endsection
 */


/**
 * 플러그인 정보 입력
 */
public Plugin:myinfo = 
{
	name 		= "[Hide and Seek] Option :: Objective Remover",
	author 		= HNS_CREATOR,
	description = "Removes no required objectives.",
	version 	= HNS_VERSION,
	url 		= HNS_CREATOR_URL
}

/**
 * 플러그인이 시작될 때
 */
public OnPluginStart()
{
	// 오브젝트 리무버가 필요로 하는 게임이벤트에 고리를 걸기.
	HookEvent("round_start", Event_RoundStart);
	
	// 이 플러그인이 정상적으로 불러와졌음을 서버에 알림.
	PrintToServer("%s (Option) 'Objective Remover' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 게임 이벤트 :: 라운드가 시작할 때
 * 
 * @param event				본 이벤트의 핸들
 * @param name				본 이벤트의 이름
 * @param dontBroadcast		알리지 않습니다.
 */
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 오브젝트 제거를 실시합니다.
	ObjectiveRemove_Do();
	
	return Plugin_Continue;
}

/**
 * 오브젝트 제거를 실시합니다.
 */
ObjectiveRemove_Do()
{
	decl String:classname[64];
	
	new maxentities = GetMaxEntities();
	for (new e = 1; e <= maxentities; e++)
	{
		// 유효한 엔티티가 아니라면 정지.
		if (!IsValidEntity(e))	continue;
		if (!IsValidEdict(e))	continue;
		
		// Edict Classname을 획득
		GetEdictClassname(e, classname, sizeof(classname));
		
		// Edict Classname에 위에 선언한 TO_REMOVE_OBJECTIVES의 엔티티들과 일치하는 것이 있다면 제거.
		if (StrContains(TO_REMOVE_OBJECTIVES, classname) > -1) RemoveEdict(e);
		
		// 숨는 사람 진영의 무기 구매 존은 삭제
		/*new team, bool:set;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!HNS_IsClientHider(i))	continue;
			if (set)	break;
			
			team = GetClientTeam(i);
			set = true;
		}
		if ((StrContains(classname, "func_buyzone") > -1) && (GetEntProp(e, Prop_Data, "m_iTeamNum", 4) == team))
			RemoveEdict(e);*/
	}
}
