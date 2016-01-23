/*==================================================================
	
	----------------------------------------
	-*- [Hide and Seek] Manage :: Weapon -*-
	----------------------------------------
	
	Filename: hns_manage_weapon.sp
	Author: Karsei 
	Description: This controls weapons to use several systems.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <hns>


/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Manage :: Weapon",
	author = HNS_CREATOR,
	description = "This controls weapons to use several systems.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("item_pickup", Event_ItemPickup);
	
	PrintToServer("%s (Manage) 'Weapon' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (!HNS_IsEngineWork())	return;
	
	// 기존에 들어와있는 유저들 접속 처리
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

/**
 * 유저들이 서버에 접속하였을때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientPutInServer(client)
{
	if (!HNS_IsEngineWork())	return;
	
	// 무기 소지 관련
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

/**
 * 유저들이 서버에서 나갔을 때
 *
 * @param client			클라이언트 인덱스
 */
public OnClientDisconnect(client)
{
	if (!HNS_IsEngineWork())	return;
	
	// 무기 소지 관련
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 무기 모듈 :: 소지하고 있는 모든 무기 삭제
 *
 * @param client			클라이언트 인덱스
 */
public RemovePlayerWeapons(client)
{
	if (!HNS_IsEngineWork())	return;
	
	new iweapon = -1;
	
	for (new i = 0; i < 5; i++)
	{
		while ((iweapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, i));
			RemoveEdict(iweapon);
		}
	}
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 버튼 :: 플레이어 행동 반응
 *
 * @param client			클라이언트 인덱스
 * @param buttons			버튼 (copyback)
 * @param impulse			충격 (copyback)
 * @param vel				플레이어의 속도
 * @param angles			플레이어의 각도
 * @param weapon			플레이어가 무기를 변경할 때 그 후의 새로운 무기 인덱스 (copyback)
 */
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new initbuttons = buttons;
	
	// 본격적인 게임 시작 전의 처리
	if (!HNS_IsGameToggle() && HNS_TeamHasClients())
	{
		if (HNS_IsClientSeeker(client))
		{
			// 키 작동이 되지 않도록 처리 (공격 관련 버튼도 포함시켰으나 제대로 될 지는...?)
			if ((buttons & IN_ATTACK) || (buttons & IN_ATTACK2) || (buttons & IN_DUCK))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
				buttons &= ~IN_DUCK;
			}
		}
	}
	else if (HNS_IsGameToggle() && HNS_TeamHasClients())
	{
		// Hider일 경우
		if (HNS_IsClientHider(client))
		{
			/* 공격버튼만 막는다.
				기획 의도대로라면 타임어택이 가동됐을 때 공격이 가능하나
				그게 아직 안되므로 이것만 해둔다. */
			if ((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
		
		// Seeker일 경우
		else if (HNS_IsClientSeeker(client))
		{
			decl String:weaponname[32];
			
			GetClientWeapon(client, weaponname, sizeof(weaponname));
			
			// 칼 마우스 오른쪽 버튼 사용 방지
			if ((buttons & IN_ATTACK2) && StrEqual(weaponname, "weapon_knife"))
				buttons &= ~IN_ATTACK2;
		}
	}
	
	// 초기에 누른 버튼 처리와 이후의 버튼 처리가 다르면 변경된 값을 리턴
	if (initbuttons != buttons)
		return Plugin_Changed;
	else
		return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 플레이어 팀 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 숨는 사람의 경우
	if (HNS_IsClientHider(client))
	{
		if (IsPlayerAlive(client))
		{
			// 도중에 T로 들어오게 되는 경우 무기 삭제
			RemovePlayerWeapons(client);
		}
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 플레이어 스폰 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 각 종류 별 처리
	if (HNS_IsClientHider(client)) // 숨는 사람의 경우
	{
		// 스폰 시에 무기 삭제
		RemovePlayerWeapons(client);
	}
	else if (HNS_IsClientSeeker(client)) // 찾는 사람의 경우
	{
		// 스폰 시에 칼이라도 들도록 처리
		//CreateTimer(2.0, Timer_SetCTKnife, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

/**
 * 게임 이벤트 :: 아이템 픽업 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(0.4, Timer_RemoveAllWeaponAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	/*
	new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	// 숨는 사람의 경우
	if (HNS_IsClientHider(client))
	{
		if (IsPlayerAlive(client))
		{
			new String:weaponname[32];
			
			GetEdictClassname(weapon, weaponname, sizeof(weaponname));
			
			// 칼을 들었다면 즉시 삭제
			if (StrEqual(weaponname, "weapon_knife"))
			{
				RemovePlayerItem(client, weapon);
				RemoveEdict(weapon);
			}
			
			// 무기의 탄약을 전부 0으로 한다.
			Weapon_RemoveAllWeaponAmmo(client);
		}
	}
	*/
	
	return Plugin_Continue;
}

/**
 * 무기 모듈 :: 유저들이 무기를 사용하는 것과 관한 처리
 *
 * @param client			클라이언트 인덱스
 * @param weapon			무기 인덱스
 */
public Action:OnWeaponCanUse(client, weapon)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 숨는 사람의 경우
	if (HNS_IsClientHider(client) && IsFakeClient(client))
	{
		// 무기를 못들게 설정
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/**
 * 타이머 :: 대테러로 스폰할 경우 칼은 무조건 지급
 *
 * @param timer				타이머 핸들
 * @param client			클라이언트 인덱스
 */
public Action:Timer_SetCTKnife(Handle:timer, any:client)
{
	if (!HNS_IsEngineWork())	return Plugin_Stop;
	
	if (client <= 0)	return Plugin_Stop;
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && HNS_IsClientSeeker(client))
	{
		new iweapon = GetPlayerWeaponSlot(client, 2);
		
		if (iweapon == -1)
		{
			iweapon = GivePlayerItem(client, "weapon_knife");
			EquipPlayerWeapon(client, iweapon);
		}
	}
	
	return Plugin_Stop;
}

/**
 * 타이머 :: 무기 탄창 또는 갯수, 칼 삭제
 *
 * @param timer				타이머 핸들
 * @param client			클라이언트 인덱스
 */
public Action:Timer_RemoveAllWeaponAmmo(Handle:timer, any:client)
{
	new knifeweapon = GetPlayerWeaponSlot(client, 2);
	
	// 숨는 사람의 경우
	if (HNS_IsClientHider(client))
	{
		if (IsPlayerAlive(client))
		{
			if (IsValidEntity(knifeweapon) && (knifeweapon != -1))
			{
				new String:weaponname[32];
				
				GetEdictClassname(knifeweapon, weaponname, sizeof(weaponname));
				
				// 칼을 들었다면 즉시 삭제
				if (StrEqual(weaponname, "weapon_knife"))
				{
					RemovePlayerItem(client, knifeweapon);
					RemoveEdict(knifeweapon);
				}
			}
			
			// 무기의 탄약을 전부 0으로 한다.
			Weapon_RemoveAllWeaponAmmo(client);
		}
	}
	
	return Plugin_Stop;
}