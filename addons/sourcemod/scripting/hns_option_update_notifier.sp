/*==================================================================
	
	----------------------------------------------------------
	-*- [Hide and Seek] Option :: Update Contents Notifier -*-
	----------------------------------------------------------
	
	Filename: hns_option_update_notifier.sp
	Author: Karsei
	Description: Option Plugin
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#include <sourcemod>
#include <hns>

#pragma semicolon 1

#define PLUGIN_UPDATE_VERSION "0.1 (2012/08/28)"
#define UPDATE_NOTIFIER_MENU_TITLE "V.Unit 숨바꼭질 :: 업데이트 (2012/08/28)"

new g_iContentCount;

new Handle:g_hArrayUpdate = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Update Notifier",
	author		= "Karsei",
	description = "Display the update contents with menu panel.",
	version		= PLUGIN_UPDATE_VERSION,
	url 		= ""
}

public OnPluginStart()
{
	g_hArrayUpdate = CreateArray(256, 0);
	
	PushTheUpdates();
	
	RegConsoleCmd("update", Command_ShowUpdateContent);
	RegConsoleCmd("say", Command_Say);
	
	PrintToServer("%s (Option) 'Update Noitifier' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

PushTheUpdates()
{
	WriteUpdateContent("변장 모델 246개");
	WriteUpdateContent("F1키를 누르면 T는 '물건삭제', CT는 T를 찾기 위한 '음파레이더' 발동");
	WriteUpdateContent("-");
	WriteUpdateContent("아직은 베타입니다.");
	WriteUpdateContent("버그는 개발자에게 문의해주세요.");
	WriteUpdateContent("버니합과 속도 부분은 아직 설정된 바 없습니다.");
	WriteUpdateContent(" < -*- 숨바꼭질 개발자: Karsei, Eakgnarok -*- > ");
}

WriteUpdateContent(const String:texts[])
{
	PushArrayString(g_hArrayUpdate, texts);
	
	g_iContentCount++;
	
	return g_iContentCount - 1;
}

public Action:Command_ShowUpdateContent(client, args)
{
	if (!IsClientInGame(client)) return Plugin_Handled;
	
	PrintUpdateContents(client);
	
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	new String:msg[256];
	GetCmdArgString(msg, sizeof(msg));
	msg[strlen(msg) - 1] = '\0';
	
	if (StrEqual(msg[1], "업데이트내역") || StrEqual(msg[1], "업데이트") || StrEqual(msg[1], "업뎃"))
	{
		PrintUpdateContents(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

PrintUpdateContents(client)
{
	static Handle:hMenu, String:displaybuffer[128];
	hMenu = CreateMenu(Process_UpdateContents);
	
	SetMenuTitle(hMenu, UPDATE_NOTIFIER_MENU_TITLE);
	
	for (new x = 0; x < g_iContentCount; x++)
	{
		GetArrayString(g_hArrayUpdate, x, displaybuffer, sizeof(displaybuffer));
		AddMenuItem(hMenu, "", displaybuffer);
	}
	
	if (GetMenuItemCount(hMenu) <= 0)
	{
		PrintToChat(client, "업데이트 내역이 없습니다.");
		CloseHandle(hMenu);
		return;
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Process_UpdateContents(Handle:menu, MenuAction:action, client, slot)
{
	PrintToChat(client, "\x04업데이트 내역에 대한 자세한 사항은 개발자들에게 문의해주세요");
	CloseHandle(menu);
}
