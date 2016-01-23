/*========================================================================
	
	---------------------------------------
	-*- [Hide and Seek] Flashbang block -*-
	---------------------------------------
	
	Name: hns_option_flashbang_block.sp
	Type: Module
	Description: Flashbang blocker.
				Doesn't work

	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved.
	
========================================================================*/

/**********************************************************************
 Semicolon
 **********************************************************************/
#pragma semicolon 1


/**********************************************************************
 Headers
 **********************************************************************/
#include <sourcemod>
#include <sdktools>


/**********************************************************************
 Plugin information
 **********************************************************************/
public Plugin:myinfo =
{
    name			= "[ZP] Grenade : Flashbangs",
    author			= HNS_CREATOR,
    description		= "Flashbang modifier",
    version			= HNS_VERSION,
    url				= HNS_CREATOR_URL
};


/**********************************************************************
 SourceMod General Forwards
 **********************************************************************/
/**
 * Plugin is loading
 */
public OnPluginStart()
{
	// Game event.
	HookEvent("player_blind", Event_PlayerBlind);

	// Notify to server.
	PrintToServer("[HNS] Enable : Flashbang Blocker");
}


/**********************************************************************
 Callbacks
 **********************************************************************/
/**
 * Game event : player_blind
 *
 * @param event				The event handle.
 * @param name				The name of event.
 * @param dontBroadcast		If true, event is broadcasted to all clients, false if not.
 */
public Action:Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Client index.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Block flashbang effect.
	new g_iFlashDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
	new g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	SetEntDataFloat(client, g_iFlashAlpha, 0.05);
	SetEntDataFloat(client, g_iFlashDuration, 0.05);

	return Plugin_Handled;
}
