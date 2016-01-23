/*==================================================================
	
	------------------------------------------------------
	-*- [Hide and Seek] Manage :: Cvar Control Manager -*-
	------------------------------------------------------
	
	Filename: hns_manage_cvar.sp
	Author: Karsei
	Description: This manages specific cvars to control those things.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <hns>

#define MAX_MANUAL_CVARS			14

/*******************************************************
 V A R I A B L E S
*******************************************************/
// Cvar Protection
new Handle:hns_hProtectCvars[MAX_MANUAL_CVARS] = {INVALID_HANDLE,...};
new hns_iPrevCvarValue[MAX_MANUAL_CVARS];
new const String:hns_sProtectCvars[MAX_MANUAL_CVARS][3][] = {
											// "cvar 이름", "설정 값", "csgo 여부"
											{"mp_flashlight", "1", "0"}, 
											{"sv_footsteps", "0", "0"}, 
											{"mp_limitteams", "0", "1"}, 
											{"mp_autoteambalance", "0", "1"}, 
											{"mp_freezetime", "0", "1"}, 
											{"sv_nonemesis", "1", "0"}, 
											{"sv_nomvp", "1", "0"}, 
											{"sv_nostats", "1", "0"}, 
											{"mp_playerid", "1", "1"}, 
											{"sv_allowminmodels", "0", "0"}, 
											{"sv_turbophysics", "1", "0"}, 
											{"mp_teams_unbalance_limit", "0", "0"},
											{"mp_forcecamera", "0", "1"},
											{"mp_show_voice_icons", "0", "0"}
											};

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Manage :: Cvar Control Manager",
	author = HNS_CREATOR,
	description = "This manages specific cvars to control those things.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	PrintToServer("%s (Manage) 'Cvar Control Manager' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (!HNS_IsEngineWork())	return;
	
	new String:gfoldername[32];
	
	GetGameFolderName(gfoldername, sizeof(gfoldername));
	
	// Cvar Protection
	for (new i = 0; i < sizeof(hns_sProtectCvars); i++)
	{
		// CS:GO 는 지원되는 Cvar 만 되도록 처리
		if (StrEqual(gfoldername, "csgo") && StrEqual(hns_sProtectCvars[i][2], "0"))	continue;
		
		hns_hProtectCvars[i] = FindConVar(hns_sProtectCvars[i][0]);
		hns_iPrevCvarValue[i] = GetConVarInt(hns_hProtectCvars[i]);
		
		if (hns_iPrevCvarValue[i] != StringToInt(hns_sProtectCvars[i][1]))
			SetConVarInt(hns_hProtectCvars[i], StringToInt(hns_sProtectCvars[i][1]), true);
	}
}