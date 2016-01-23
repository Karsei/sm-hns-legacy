/*==================================================================
	
	---------------------------------------------
	-*- [Hide and Seek] Core :: Hider Control -*-
	---------------------------------------------
	
	Filename: hns_core_hider.sp
	Author: Karsei
	Description: This Controls Several Things about Hiders.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <hns>

/*******************************************************
 E N U M S
*******************************************************/
enum CVAR
{
	Handle:HHIDERDUCK
}

/*******************************************************
 V A R I A B L E S
*******************************************************/
new hns_eConvar[CVAR];

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Core :: Hider Control",
	author = HNS_CREATOR,
	description = "This Controls Several Things about Hiders.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	hns_eConvar[HHIDERDUCK] = CreateConVar("hns_hider_duck_switch", "1", "Hider Duck on?");
	
	AddCommandListener(Command_BuyMenuListener, "buymenu");
	
	PrintToServer("%s (Core) 'Hider Control' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
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
	if (HNS_IsClientHider(client))
	{
		// 앉기 버튼 눌렀을때 모델이 사라지는 현상 방지
		if (!GetConVarBool(hns_eConvar[HHIDERDUCK]))
		{
			if (buttons & IN_DUCK)
				buttons &= ~IN_DUCK;
		}
	}
	
	// 초기에 누른 버튼 처리와 이후의 버튼 처리가 다르면 변경된 값을 리턴
	if (initbuttons != buttons)
		return Plugin_Changed;
	else
		return Plugin_Continue;
}

/**
 * 커맨드 리스너 :: 무기 구입 방지
 *
 * @param client			클라이언트 인덱스
 * @param command			명령어
 * @param args				기타 파라메터
 */
public Action:Command_BuyMenuListener(client, const String:command[], args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 숨는 사람의 경우는 구입 메뉴를 열지 못하도록 처리
	if (HNS_IsClientHider(client))
		return Plugin_Handled;
	
	return Plugin_Continue;
}