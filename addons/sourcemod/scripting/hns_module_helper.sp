/*==================================================================
	
	----------------------------------------
	-*- [Hide and Seek] Module :: Helper -*-
	----------------------------------------
	
	Filename: hns_module_helper.sp
	Author: Karsei
	Description: Help Menu.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <hns>

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Module :: Helper",
	author = HNS_CREATOR,
	description = "Help Menu.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegConsoleCmd("sm_showhelp", Menu_Help);
	
	LoadTranslations("plugin.hide_and_seek");
	
	// 맵 변경시 누락된 유저도 포함시키도록 처리, 플러그인 시작 시 도움말 메뉴가 나타나도록 처리
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
	
	PrintToServer("%s (Module) 'Helper' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 유저들이 서버에 접속하였을 때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientPutInServer(client)
{
	if (!HNS_IsEngineWork())	return;
	
	// (봇 체크를 안하면 충돌이 일어남)
	if (!IsFakeClient(client))
	{
		// 도움말 메뉴 출력
		Menu_Help(client, 0);
	}
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 도움말 모듈 :: 도움말 메뉴 출력
 * 
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Menu_Help(client, args)
{
	if (!HNS_IsEngineWork())	return;
	
	new Handle:helpmenu = CreateMenu(Menu_HelpS);
	
	decl String:buffer[512];
	
	Format(buffer, sizeof(buffer), "%t\n ", "help menu title");
	SetMenuTitle(helpmenu, buffer);
	SetMenuExitButton(helpmenu, true);
	
	Format(buffer, sizeof(buffer), "%t\n ", "help menu simple instruction");
	AddMenuItem(helpmenu, "0", buffer);
	Format(buffer, sizeof(buffer), "%t\n ", "help menu available chat cmd");
	AddMenuItem(helpmenu, "1", buffer);
	Format(buffer, sizeof(buffer), "%t", "help menu howto t");
	AddMenuItem(helpmenu, "2", buffer);
	Format(buffer, sizeof(buffer), "%t", "help menu howto ct");
	AddMenuItem(helpmenu, "3", buffer);
	
	DisplayMenu(helpmenu, client, MENU_TIME_FOREVER);
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 채팅 :: 채팅 처리 함수
 *
 * @param client			클라이언트 인덱스
 * @param args				채팅 메세지
 */
public Action:Command_Say(client, args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new String:msg[256], String:name[256], String:buffer[256];
	
	GetCmdArgString(msg, sizeof(msg));
	
	msg[strlen(msg)-1] = '\x0';
	
	GetClientName(client, name, sizeof(name));
	
	// 도움말 메뉴
	if (StrEqual(msg[1], "!hidehelp", false) || StrEqual(msg[1], "!help", false) || StrEqual(msg[1], "!헬프", false) || StrEqual(msg[1], "!도움말", false) || StrEqual(msg[1], "!도움", false))
	{
		Format(buffer, sizeof(buffer), "\x03%s \x01:  %s", name, msg[1]);
		SayText2All(client, buffer);
		PrintToServer(buffer);
		Menu_Help(client, 0);
		
		return Plugin_Handled;
	}
	if (StrEqual(msg[1], "/hidehelp", false) || StrEqual(msg[1], "/help", false) || StrEqual(msg[1], "/헬프", false) || StrEqual(msg[1], "/도움말", false) || StrEqual(msg[1], "/도움", false))
	{
		Menu_Help(client, 0);
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/**
 * 도움말 모듈 :: 도움말 메뉴 처리 함수
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client			클라이언트 인덱스
 * @param select			메뉴 선택 값
 */
public Menu_HelpS(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		new String:info[32], iInfo;
		
		GetMenuItem(menu, select, info, sizeof(info));
		iInfo = StringToInt(info);
		
		if (iInfo > 0)
		{
			new Handle:helpsubmenu = CreateMenu(Menu_HelpSubS);
			
			decl String:buffer[512];
			
			if (iInfo == 1)
			{
				/* help menu available cmd */
				Format(buffer, sizeof(buffer), "%t\n - %t\n ", "help menu title", "help menu available chat cmd");
				SetMenuTitle(helpsubmenu, buffer);
				SetMenuExitButton(helpsubmenu, true);
				SetMenuExitBackButton(helpsubmenu, true);
				
				Format(buffer, sizeof(buffer), "!hidehelp, !도움말 - %t", "help menu cmd hide help");
				AddMenuItem(helpsubmenu, "1", buffer);
				Format(buffer, sizeof(buffer), "!hide, !변장 - %t", "help menu cmd hide");
				AddMenuItem(helpsubmenu, "2", buffer);
				Format(buffer, sizeof(buffer), "!hint, !힌트 - %t", "help menu cmd hint");
				AddMenuItem(helpsubmenu, "3", buffer);
				Format(buffer, sizeof(buffer), "!ice, !얼음 - %t", "help menu cmd freeze");
				AddMenuItem(helpsubmenu, "4", buffer);
				Format(buffer, sizeof(buffer), "!tp, !3 - %t", "help menu cmd tp");
				AddMenuItem(helpsubmenu, "5", buffer);
				Format(buffer, sizeof(buffer), "!whoami, !난누구 - %t", "help menu cmd whoami");
				AddMenuItem(helpsubmenu, "6", buffer);
			}
			else if (iInfo == 2)
			{
				/* help menu howto t */
				Format(buffer, sizeof(buffer), "%t\n - %t\n ", "help menu title", "help menu howto t");
				SetMenuTitle(helpsubmenu, buffer);
				SetMenuExitButton(helpsubmenu, true);
				SetMenuExitBackButton(helpsubmenu, true);
				
				Format(buffer, sizeof(buffer), "%t", "help menu howto t inst1");
				AddMenuItem(helpsubmenu, "1", buffer);
			}
			else if (iInfo == 3)
			{
				/* help menu howto ct */
				Format(buffer, sizeof(buffer), "%t\n - %t\n ", "help menu title", "help menu howto ct");
				SetMenuTitle(helpsubmenu, buffer);
				SetMenuExitButton(helpsubmenu, true);
				SetMenuExitBackButton(helpsubmenu, true);
				
				Format(buffer, sizeof(buffer), "%t", "help menu howto ct inst1");
				AddMenuItem(helpsubmenu, "1", buffer);
			}
			DisplayMenu(helpsubmenu, client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/**
 * 도움말 모듈 :: 도움말 하위 메뉴 처리 함수
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client			클라이언트 인덱스
 * @param select			메뉴 선택 값
 */
public Menu_HelpSubS(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		new String:info[32], iInfo;
		
		GetMenuItem(menu, select, info, sizeof(info));
		iInfo = StringToInt(info);
		
		switch(iInfo)
		{
			default:
			{
				// Nothing
			}
		}
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (select == MenuCancel_ExitBack)
		{
			CloseHandle(menu);
			Menu_Help(client, 0);
		}
		else if (select == MenuCancel_Exit)
		{
			CloseHandle(menu);
		}
	}
}
