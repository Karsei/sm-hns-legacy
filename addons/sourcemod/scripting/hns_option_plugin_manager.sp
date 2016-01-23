/*==================================================================
	
	------------------------------------------------
	-*- [Hide and Seek] Option :: Plugin Manager -*-
	------------------------------------------------
	
	Filename: hns_option_plugin_manager.sp
	Author: Karsei 
	Description: This Controls Several Plugins.
	
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
	name = "[Hide and Seek] Option :: Plugin Manager",
	author = HNS_CREATOR,
	description = "This Controls Several Plugins.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	RegAdminCmd("sm_pluginmanager", Command_PluginManagementMenu, ADMFLAG_ROOT);
	
	PrintToServer("%s (Option) 'Plugin Manager' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 플러그인 관리 모듈 :: 플러그인 관리 메뉴 출력
 * 
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_PluginManagementMenu(client, args)
{
	new String:dir[128] = "addons/sourcemod/plugins";
	new Handle:curdir = OpenDirectory(dir);
	new String:filename[64], FileType:type, count;
	//new String:setdir[128];
	
	if (curdir != INVALID_HANDLE)
	{
		new Handle:managemenu = CreateMenu(Menu_ManagerS);
		
		decl String:buffer[512];
		
		Format(buffer, sizeof(buffer), "-*- Plugin Manager -*-\n ");
		SetMenuTitle(managemenu, buffer);
		SetMenuExitButton(managemenu, true);
		
		while (ReadDirEntry(curdir, filename, sizeof(filename), type))
		{
			if (type == FileType_File)
			{
				AddMenuItem(managemenu, filename, filename);
				count++;
			}
		}
		
		if (count == 0)
		{
			AddMenuItem(managemenu, "0", "None", ITEMDRAW_DISABLED);
		}
		
		DisplayMenu(managemenu, client, MENU_TIME_FOREVER);
		
		curdir = INVALID_HANDLE;
	}
	else
	{
		PrintToServer("%s Retrieving Directory is Failed: %s", HNS_PHRASE_PREFIX, dir);
	}
	
	return Plugin_Continue;
}

/**
 * 플러그인 관리 모듈 :: 플러그인 관리 메뉴 처리 함수
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client			클라이언트 인덱스
 * @param select			메뉴 선택 값
 */
public Menu_ManagerS(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		new String:info[32], String:info2[32], String:sendparam[128];
		
		GetMenuItem(menu, select, info, sizeof(info), _, info2, sizeof(info2));
		
		new Handle:managemenu_sub = CreateMenu(Menu_Manager_SubS);
		
		decl String:buffer[512];
		
		Format(buffer, sizeof(buffer), "-*- Plugin Manager -*-\n ~ Select : %s\n ", info2);
		SetMenuTitle(managemenu_sub, buffer);
		SetMenuExitButton(managemenu_sub, true);
		
		Format(buffer, sizeof(buffer), "Load");
		Format(sendparam, sizeof(sendparam), "1^%s", info2);
		AddMenuItem(managemenu_sub, sendparam, buffer);
		Format(buffer, sizeof(buffer), "Reload");
		Format(sendparam, sizeof(sendparam), "2^%s", info2);
		AddMenuItem(managemenu_sub, sendparam, buffer);
		Format(buffer, sizeof(buffer), "Unload");
		Format(sendparam, sizeof(sendparam), "3^%s", info2);
		AddMenuItem(managemenu_sub, sendparam, buffer);
		
		DisplayMenu(managemenu_sub, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/**
 * 플러그인 관리 모듈 :: 플러그인 관리 하위 메뉴 처리 함수
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client			클라이언트 인덱스
 * @param select			메뉴 선택 값
 */
public Menu_Manager_SubS(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		new String:info[32], String:info2[32], String:explodestr[2][128], String:pluginname[32];
		
		GetMenuItem(menu, select, info, sizeof(info), _, info2, sizeof(info2));
		
		ExplodeString(info, "^", explodestr, 2, 128);
		
		new proc = StringToInt(explodestr[0]);
		SplitString(explodestr[1], ".smx", pluginname, sizeof(pluginname));
		
		if (proc == 1)
		{
			ServerCommand("sm plugins load %s", pluginname);
			PrintToChatAll("%s The Request is Successful! (Load: %s)", HNS_PHRASE_PREFIX, pluginname);
		}
		else if (proc == 2)
		{
			ServerCommand("sm plugins reload %s", pluginname);
			PrintToChatAll("%s The Request is Successful! (Reload: %s)", HNS_PHRASE_PREFIX, pluginname);
		}
		else if (proc == 3)
		{
			ServerCommand("sm plugins unload %s", pluginname);
			PrintToChatAll("%s The Request is Successful! (Unload: %s)", HNS_PHRASE_PREFIX, pluginname);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}