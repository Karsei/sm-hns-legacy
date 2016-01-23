/*==================================================================
	
	------------------------------------------------
	-*- [Hide and Seek] Manage :: Damage Manager -*-
	------------------------------------------------
	
	Filename: hns_manage_damage.sp
	Author: Karsei
	Description: Manages the damage
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

/**
 * 헤더 정렬
 */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <hns>

/**
 * 세미콜론 지시
 */
#pragma semicolon 1

/**
 * ENUM
 */
enum CVAR
{
	Handle:HHIDERBLOOD,
	Handle:HHPSEEKERSHOOT,
	Handle:HHPSEEKERHURT,
	Handle:HHPSEEKERKILL
}

/**
 * 변수
 */
new hns_eConvar[CVAR];

/**
 * 플러그인 정보 입력
 */
public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Manage :: Damage Manager",
	author		= HNS_CREATOR,
	description = "Manages the damage",
	version		= HNS_VERSION,
	url			= HNS_CREATOR_URL
}

/**
 * 플러그인 시작 시
 */
public OnPluginStart()
{
	hns_eConvar[HHIDERBLOOD] = CreateConVar("hns_hider_blood_switch", "1", "Hider Blood on?");
	hns_eConvar[HHPSEEKERSHOOT] = CreateConVar("hns_hp_seeker_shoot", "5");
	hns_eConvar[HHPSEEKERHURT] = CreateConVar("hns_hp_seeker_hurt", "15");
	hns_eConvar[HHPSEEKERKILL] = CreateConVar("hns_hp_seeker_kill", "50");
	
	HookEvent("weapon_fire", Event_OnWeaponFire);
	
	PrintToServer("%s (Manage) 'Damage Manager' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 클라이언트가 서버에 접속했을 때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientPutInServer(client)
{
	if (!HNS_IsEngineWork())	return;
	
	// 일반 데미지 관련
	SDKHook(client, SDKHook_OnTakeDamage, SDKH_OnTakeDamage);
	
	// 무기 사용 관련
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

/**
 * 클라이언트가 서버에서 나갔을 때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientDisconnect(client)
{
	if (!HNS_IsEngineWork())	return;
	
	// 일반 데미지 관련
	SDKUnhook(client, SDKHook_OnTakeDamage, SDKH_OnTakeDamage);
	
	// 무기 사용 관련
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
}

/**
 * 데미지 모듈 :: 유저들이 무기를 사용하여 맞았을 경우의 처리 (일반적인 경우)
 *
 * @param victim			피해자 인덱스
 * @param attacker			가해자 인덱스 (copyback)
 * @param inflictor			가해자 인덱스 (copyback)
 * @param damage			데미지 양 (copyback)
 * @param damagetype		데미지 종류 (copyback)
 * @param weapon			알 수 없음 (copyback)
 * @param damageForce		알 수 없음
 * @param damagePosition	알 수 없음
 * @param damagecustom		알 수 없음
 */
public Action:SDKH_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 본격적인 게임이 시작되기 전까지는 모두 무적
	if (!HNS_IsGameToggle())	return Plugin_Handled;
	
	return Plugin_Continue;
}

/**
 * 데미지 모듈 :: 유저들이 무기를 사용하여 맞았을 경우의 처리 (특별한 경우)
 *
 * @param victim			피해자 인덱스
 * @param attacker			가해자 인덱스 (copyback)
 * @param inflictor			가해자 인덱스 (copyback)
 * @param damage			데미지 양 (copyback)
 * @param damagetype		데미지 종류 (copyback)
 * @param ammotype			Ammo 종류 (copyback)
 * @param hitbox			히트 박스
 * @param hitgroup			히트 그룹
 */
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 본격적인 게임이 시작되기 전까지는 모두 무적
	if (!HNS_IsGameToggle())	return Plugin_Handled;
	
	// 숨는 사람의 경우
	if (HNS_IsClientHider(victim))
	{
		// 데미지를 입은 후의 체력 계산
		new remainhealth = GetClientHealth(victim) - RoundToFloor(damage);
		
		// 숨는 사람을 맞추었을때 체력 처리
		if ((victim > 0) && IsPlayerAlive(victim) && (attacker > 0) && IsPlayerAlive(attacker) && (victim != attacker))
		{
			new prevhealth = GetClientHealth(attacker) + GetConVarInt(hns_eConvar[HHPSEEKERSHOOT]);
			
			if (remainhealth > 0)
				SetEntityHealth(attacker, (prevhealth + GetConVarInt(hns_eConvar[HHPSEEKERHURT])));
			else if (remainhealth <= 0)
				SetEntityHealth(attacker, (prevhealth + GetConVarInt(hns_eConvar[HHPSEEKERKILL])));
		}
		
		// 남은 체력이 0 보다 작을 경우 기본 모델로 변경하고 일반 죽음 처리
		if (remainhealth < 0)
		{
			new String:gfoldername[32];
			
			GetGameFolderName(gfoldername, sizeof(gfoldername));
			
			if (StrEqual(gfoldername, "csgo"))
			{
				PrecacheModel("models/player/tm_phoenix.mdl", true);
				SetEntityModel(victim, "models/player/tm_phoenix.mdl");
			}
			else {
				SetEntityModel(victim, "models/player/t_guerilla.mdl");
			}
			//ForcePlayerSuicide(victim);
			return Plugin_Continue;
		}
		
		// 피 관련
		// 수동적으로 체력을 처리하는 코드이므로, 위에 있는 remainhealth 값을 주의!
		// (주의안하고 하면 victim 유저의 체력이 이상하게 설정될 수 있음!)
		if (GetConVarBool(hns_eConvar[HHIDERBLOOD]))
		{
			// 체력은 수동적으로 이전에 일단 깎이게 하고
			SetEntityHealth(victim, remainhealth);
			
			// 후에 피를 내고 체력이 깎이는 이벤트는 무시
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 웨폰 파이어 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	if (!HNS_IsGameToggle())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new health = GetClientHealth(client);
	
	// 찾는 사람의 경우
	if (HNS_IsClientSeeker(client))
	{
		// 무기를 사용했을 경우의 처리
		// (누군가가 맞았을 경우는 OnTraceAttack 함수를 참고)
		if ((health - GetConVarInt(hns_eConvar[HHPSEEKERSHOOT])) > 0)
			SetEntityHealth(client, (health - GetConVarInt(hns_eConvar[HHPSEEKERSHOOT])));
		else
			ForcePlayerSuicide(client);
	}
	
	return Plugin_Continue;
}