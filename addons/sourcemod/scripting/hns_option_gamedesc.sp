/*==================================================================
	
	--------------------------------------------------
	-*- [Hide and Seek] Option :: Game Description -*-
	--------------------------------------------------
	
	Filename: hns_option_gamedesc.sp
	Author: Karsei
	Description: This changes the game description.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <hns>

/*******************************************************
 V A R I A B L E S
*******************************************************/
new String:hns_sSetGameDesc[64] = "WE R DEVELOPING!";
new bool:hns_bMapLoaded = false;

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Option :: Game Description",
	author = HNS_CREATOR,
	description = "This changes the game description.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{	
	PrintToServer("%s (Option) 'Game Description' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnMapStart()
{
	hns_bMapLoaded = true;
}

public OnMapEnd()
{
	hns_bMapLoaded = false;
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 게임 설명 훅
 *
 * @param gamedesc			게임 설명 문자열
 */
public Action:OnGetGameDescription(String:gamedesc[64])
{
	strcopy(gamedesc, sizeof(gamedesc), hns_sSetGameDesc);
	
	if (hns_bMapLoaded)
	{
		return Plugin_Changed;
	}
	
	return Plugin_Handled;
}