/*==================================================================
	
	----------------------------------------------------
	-*- [Hide and Seek] Option :: Player Dead Effect -*-
	----------------------------------------------------
	
	Filename: hns_option_dead_effect.sp
	Author: Karsei
	Description: Dead Effect.
	
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
new hns_iVMTFire;
new hns_iVMTHalo;
new hns_iVMTSpriteFire;

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Option :: Player Dead Effect",
	author = HNS_CREATOR,
	description = "Dead Effect.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	
	PrintToServer("%s (Option) 'Player Dead Effect' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (!HNS_IsEngineWork())	return;
	
	hns_iVMTFire = PrecacheModel("materials/sprites/fire2.vmt", true);
	hns_iVMTHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
	hns_iVMTSpriteFire = PrecacheModel("sprites/sprite_fire01.vmt", true);
	PrecacheSound("ambient/explosions/explode_8.wav", true);
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 이펙트 모듈 :: 펑!
 *
 * @param client			클라이언트 인덱스
 */
public SetExplodeEffect(client)
{
	decl Float:loc[3];
	
	GetClientAbsOrigin(client, loc);
	
	new color[4] = {188, 220, 255, 200};
	
	TE_SetupExplosion(loc, hns_iVMTSpriteFire, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(loc, 10.0, 500.0, hns_iVMTFire, hns_iVMTHalo, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
	TE_SendToAll();
	
	EmitSoundToAll("ambient/explosions/explode_8.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, loc, NULL_VECTOR, true, 0.0);
	
	loc[2] += 10;
	
	EmitSoundToAll("ambient/explosions/explode_8.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, loc, NULL_VECTOR, true, 0.0);
	
	TE_SetupExplosion(loc, hns_iVMTSpriteFire, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
}

/**
 * 이펙트 모듈 :: 샤라라라랅 --- -- -
 *
 * @param client			클라이언트 인덱스
 */
public SetDissolveRagdoll(client)
{
	if (!IsValidEntity(client) || IsPlayerAlive(client))	return;
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if (ragdoll == -1)	return;
	
	new String:targetname[32];
	
	Format(targetname, sizeof(targetname), "dis_%d", client);
	
	new dissolver = CreateEntityByName("env_entity_dissolver");
	
	if (dissolver > -1)
	{
		DispatchKeyValue(ragdoll, "targetname", targetname);
		DispatchKeyValue(dissolver, "dissolvetype", "0");
		DispatchKeyValue(dissolver, "target", targetname);
		
		AcceptEntityInput(dissolver, "Dissolve");
		AcceptEntityInput(dissolver, "kill");
	}
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 게임 이벤트 :: 플레이어 데스 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new String:gfoldername[32];
	
	GetGameFolderName(gfoldername, sizeof(gfoldername));
	
	// CS:GO 는 나중에 처리
	if (StrEqual(gfoldername, "csgo"))	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 각 타입 별 처리
	if (HNS_IsClientHider(client)) // 숨는 사람의 경우
	{
		// '펑!'
		SetExplodeEffect(client);
		
		// 샤라라라랅 --- -- -
		CreateTimer(0.4, Timer_SetDissolveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (HNS_IsClientSeeker(client))
	{
		// 샤라라라랅 --- -- -
		CreateTimer(0.4, Timer_SetDissolveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

/**
 * 타이머 :: '샤라라라랅 --- -- -' 이벤트 준비
 *
 * @param timer				타이머 핸들
 * @param client			클라이언트 인덱스
 */
public Action:Timer_SetDissolveRagdoll(Handle:timer, any:client)
{
	SetDissolveRagdoll(client);
	
	return Plugin_Stop;
}