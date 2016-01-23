/*==================================================================
	
	-----------------------------------
	-*- [Hide and Seek] API :: Core -*-
	-----------------------------------
	
	Filename: hns_core.inc
	Author: Karsei
	Description: Core API
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

/**
 * Is client hider?
 *
 * @param client		Client index.
 */
native bool:HNS_IsClientHider(client);

/**
 * Is client seeker?
 *
 * @param client		Client index.
 */
native bool:HNS_IsClientSeeker(client);

/**
 * Set Client Preference (hns.inc)
 * 
 * 1 is Hider, 2 is Seeker
 * 
 * @param client		Client index.
 * @param type			Client preference index.
 */
native HNS_SetClientTo(client, type = HNS_CLIENT_HIDER);

/**
 * Is HNS Engine work?
 *
 * @note if return true, HNS(Engine) start and working, otherwise, stopped and can't anything.
 */
native bool:HNS_IsEngineWork();

/**
 * Command to start/stop HNS Engine.
 *
 * @param start			True to start, else false.
 */
native HNS_Engine(bool:start = false);

/**
 * Is HNS Game toggled?
 *
 * @note if return true, game start and working, otherwise, stopped and something.
 */
native bool:HNS_IsGameToggle();

/**
 * Command to start/stop Game.
 *
 * @param start			True to start, else false.
 */
native HNS_ToggleGame(bool:start = false);

/**
 * Call BEFORE game start (HNS_ToggleGame)
 *
 * @param start			True to start, else false.
 */
forward Action:HNS_OnToggleGame_Pre(&bool:start);

/**
 * Call AFTER game start (HNS_ToggleGame)
 *
 * @param start			True to start, else false.
 */
forward HNS_OnToggleGame_Post(bool:start);

/**
 * Is Client Freezed?
 *
 * @param client		Client index.
 * @note if return true, the client is freezed.
 */
native bool:HNS_IsClientFreezed(client);

/**
 * Set Client Freezed
 * 
 * @param client		Client index.
 * @param set			True to set freezed, else false.
 * @param sethold		True to hold user's screen, else false.
 * @param settele		True to use teleport, else false.
 */
native HNS_SetClientFreezed(client, bool:set = false, bool:sethold = false, bool:settele = false);

/**
 * Is Client Thirdperson View?
 *
 * @param client		Client index.
 * @note if return true, the client set thirdperson view.
 */
native bool:HNS_IsClientThirdPerson(client);

/**
 * Set Client Thirdperson view
 * 
 * @param client		Client index.
 * @param set			True to set thirdperson view, else false.
 */
native HNS_SetClientThirdPerson(client, bool:set = false);

/**
 * Get Client's Model Height
 *
 * @param client		Client index.
 * @note if return, this returns the client's model height.
 */
native Float:HNS_GetClientModelHeight(client);

/**
 * Set Client's Model Height
 * 
 * @param client		Client index.
 * @param height		Model Height.
 */
native HNS_SetClientModelHeight(client, Float:height = 0.0);

/**
 * Set Client Blind
 * 
 * @param client		Client index.
 * @param amount		blind amount.
 */
native HNS_SetClientBlind(client, amount = 0);

/**
 * Get Client's Money Amount
 *
 * @param client		Client index.
 * @note if return, this returns the client's model height.
 */
native HNS_GetClientMoney(client);

/**
 * Set Client's Money Amount
 * 
 * @param client		Client index.
 * @param money			Money Amount.
 */
native HNS_SetClientMoney(client, money = 0);

/**
 * Check HNS Plugins are in debug mode
 *
 * @note if return, this returns debug mode status.
 */
native bool:HNS_IsInDebugMode();

/**
 * Set HNS Plugins to be in debug mode
 * 
 * @param set			debug mode set
 */
native HNS_SetDebugMode(bool:set = false);

/**
 * Get Hiders, Seekers Team ID
 *
 * @param hiderteam		Hider Team ID
 * @param seekerteam	Seeker Team ID
 * @note if return, this returns true if it has successed, else false.
 */
native HNS_GetHNSTeamID(&hiderteam = 0, &seekerteam = 0);