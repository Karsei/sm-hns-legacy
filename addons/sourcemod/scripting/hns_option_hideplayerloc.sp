/*==================================================================
	
	------------------------------------------------------
	-*- [Hide and Seek] Option :: Hide Player Location -*-
	------------------------------------------------------
	
	Filename: hns_option_hideplayerloc.sp
	Author: Karsei
	Description: This hides the location info shown next to players
				 name on voice chat and teamsay.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <hns>

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Option :: Hide Player Location",
	author = HNS_CREATOR,
	description = "This hides the location info shown next to players name on voice chat and teamsay.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	PrintToServer("%s (Option) 'Hide Player Location' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 유저들이 서버에 접속하였을 때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientPutInServer(client)
{
	if (!HNS_IsEngineWork())	return;
	
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

/**
 * 유저들이 서버에서 나갔을 때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
public OnPostThinkPost(client)
{
	if (!HNS_IsEngineWork())	return;
	
	SetEntPropString(client, Prop_Send, "m_szLastPlaceName", "");
}