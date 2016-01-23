/*========================================================================

	-----------------------------
	-*- [Hide and Seek] ZTele -*-
	-----------------------------
	
	Name: hns_option_ztele.sp
	Type: Addon
	Description: Zombie Teleport
					Thanks to Fry! (AMXX) - zp_extra_ztele.sma
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
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
#include <hns>


/**********************************************************************
 Variables
 **********************************************************************/
// Convars.
enum CVAR
{
	Handle:ZTELEWAITTIME
}
new g_hCV[CVAR];

new bool:bWait[MAXPLAYERS + 1] = false;

new Handle:tWait[MAXPLAYERS + 1] = INVALID_HANDLE;

new Float:g_vecZTeleSpawn[MAXPLAYERS + 1][3];	// Client spawn position.


/**********************************************************************
 Plugin information
 **********************************************************************/
public Plugin:myinfo = 
{
	name 		= "[Hide and Seek] ZTele",
	author 		= "Karsei",
	description = "ZTele.",
	version 	= HNS_VERSION,
	url 		= HNS_CREATOR_URL
}


/**********************************************************************
 SourceMod Forwards
 **********************************************************************/
/**
 * Plugin is loading
 */
public OnPluginStart()
{
	// Convars.
	g_hCV[ZTELEWAITTIME] = CreateConVar("zp_ztele_wait_time", "10", "Teleport time"); 
	
	// Client command.
	RegConsoleCmd("ztele", Command_Ztele);
	RegConsoleCmd("say", Command_Say);
	
	// Game event.
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	// Notify to server.
	PrintToServer("%s (Option) 'ZTele' has been loaded successfully.", HNS_PHRASE_PREFIX);
}


/**********************************************************************
 Callbacks
 **********************************************************************/

public Action:Command_Say(client, args)
{
	new String:msg[256];
	GetCmdArgString(msg, sizeof(msg));
	msg[strlen(msg) - 1] = '\0';
	
	if (StrEqual(msg[1], "꼈어") || StrEqual(msg[1], "!꼈어") || StrEqual(msg[1], "/꼈어"))
	{
		Wait(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/**
 * Command: !ztele
 * 
 * @param client		The client index.
 * @param args 			Arguments.
 */
public Action:Command_Ztele(client, args)
{
	// Not alive.
	if (!IsPlayerAlive(client))
		return Plugin_Handled;

	if (bWait[client])
		return Plugin_Handled;

	Wait(client);
	
	return Plugin_Continue;
}

/**
 * Game event: player_spawn
 *
 * @param event				The event handle.
 * @param name				The name of event.
 * @param dontBroadcast		If true, event is broadcasted to all clients, false if not.
 */
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Client index.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Teleport mode.
	GetClientAbsOrigin(client, g_vecZTeleSpawn[client]);

	// Reset,
	bWait[client] = false;

	// Reset timer.
	if (tWait[client] != INVALID_HANDLE)
		KillTimer(tWait[client]);
	tWait[client] = INVALID_HANDLE;
}


/**********************************************************************
 Generals
 **********************************************************************/
Wait(client)
{
	bWait[client] = true;

	new Float:waittime = GetConVarFloat(g_hCV[ZTELEWAITTIME]);
	tWait[client] = INVALID_HANDLE;
	tWait[client] = CreateTimer(waittime, Timer_Teleport, client, TIMER_FLAG_NO_MAPCHANGE);

	PrintToChat(client, "[HNS] %.2f초 후에 텔레포트 됩니다.", waittime);
}

/**
 * Teleport client.
 * 
 * @param client 		The client index.
 */
public Action:Timer_Teleport(Handle:timer, any:client)
{
	tWait[client] = INVALID_HANDLE;

	bWait[client] = false;
	TeleportEntity(client, g_vecZTeleSpawn[client], NULL_VECTOR, NULL_VECTOR);
}
