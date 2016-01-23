/*==================================================================
	
	--------------------------------------------------
	-*- [Hide and Seek] Test :: Check Model Height -*-
	--------------------------------------------------
	
	Filename: hns_test_checkmodelheight.sp
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
new Float:hns_fCurrentSetHeight[MAXPLAYERS+1] = {0.0,...};

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Test :: Check Model Height",
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
	RegAdminCmd("sm_modelheighttool", Command_TestModelHeight, ADMFLAG_ROOT);
	RegAdminCmd("sm_modelheighttool_reset", Command_TestModelHeight_Reset, ADMFLAG_ROOT);
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Test) 'Check Model Height' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 테스트 모듈 :: 모델 높이 체크 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_TestModelHeight(client, args)
{
	// 죽은 사람은 무시
	if (!IsPlayerAlive(client))
	{
		HNS_T_PrintToChat(client, "no use player dead");
		return Plugin_Continue;
	}
	
	new Handle:modelheight = CreateMenu(Menu_ModelHeightS);
	
	decl String:buffer[512];
	
	Format(buffer, sizeof(buffer), "-*- MODEL HEIGHT TEST -*-\n ~ Current = %f\n ", hns_fCurrentSetHeight[client]);
	SetMenuTitle(modelheight, buffer);
	SetMenuExitButton(modelheight, true);
	
	Format(buffer, sizeof(buffer), "Z + 1");
	AddMenuItem(modelheight, "1", buffer);
	Format(buffer, sizeof(buffer), "Z - 1");
	AddMenuItem(modelheight, "2", buffer);
	Format(buffer, sizeof(buffer), "Z + 10");
	AddMenuItem(modelheight, "3", buffer);
	Format(buffer, sizeof(buffer), "Z - 10");
	AddMenuItem(modelheight, "4", buffer);
	Format(buffer, sizeof(buffer), "Z + 50");
	AddMenuItem(modelheight, "5", buffer);
	Format(buffer, sizeof(buffer), "Z - 50\n ");
	AddMenuItem(modelheight, "6", buffer);
	Format(buffer, sizeof(buffer), "Reset And Move Again");
	AddMenuItem(modelheight, "7", buffer);
	
	DisplayMenu(modelheight, client, MENU_TIME_FOREVER);
	
	return Plugin_Continue;
}

/**
 * 테스트 모듈 :: 모델 높이 체크 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_TestModelHeight_Reset(client, args)
{
	hns_fCurrentSetHeight[client] = 0.0;
	
	return Plugin_Continue;
}

/**
 * 테스트 모듈 :: 모델 높이 체크 메뉴 처리
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client			클라이언트 인덱스
 * @param select			메뉴 선택 값
 */
public Menu_ModelHeightS(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		if (!IsPlayerAlive(client))
		{
			HNS_T_PrintToChat(client, "no use player dead");
			return;
		}
		
		new String:info[32], iInfo, Float:origin[3];
		
		GetMenuItem(menu, select, info, sizeof(info));
		iInfo = StringToInt(info);
		
		GetClientAbsOrigin(client, origin);
		
		if (iInfo == 1)
		{
			origin[2] += 1;
			hns_fCurrentSetHeight[client] += 1.0;
			TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_NONE);
			Command_TestModelHeight(client, 0);
		}
		else if (iInfo == 2)
		{
			origin[2] -= 1;
			hns_fCurrentSetHeight[client] -= 1.0;
			TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_NONE);
			Command_TestModelHeight(client, 0);
		}
		else if (iInfo == 3)
		{
			origin[2] += 10;
			hns_fCurrentSetHeight[client] += 10.0;
			TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_NONE);
			Command_TestModelHeight(client, 0);
		}
		else if (iInfo == 4)
		{
			origin[2] -= 10;
			hns_fCurrentSetHeight[client] -= 10.0;
			TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_NONE);
			Command_TestModelHeight(client, 0);
		}
		else if (iInfo == 5)
		{
			origin[2] += 50;
			hns_fCurrentSetHeight[client] += 50.0;
			TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_NONE);
			Command_TestModelHeight(client, 0);
		}
		else if (iInfo == 6)
		{
			origin[2] -= 50;
			hns_fCurrentSetHeight[client] -= 50.0;
			TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_NONE);
			Command_TestModelHeight(client, 0);
		}
		else if (iInfo == 7)
		{
			hns_fCurrentSetHeight[client] = 0.0;
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}