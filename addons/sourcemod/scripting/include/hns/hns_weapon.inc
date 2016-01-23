/*==================================================================
	
	-------------------------------------
	-*- [Hide and Seek] API :: Weapon -*-
	-------------------------------------
	
	Filename: hns_weapon.inc
	Author: Karsei 
	Description: API Stocks.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

/**
 * 무기 이름의 최대길이
 */
#define WEAPON_MAX_LENGTH 32

/**
 * 실제 무기 슬롯의 숫자 (CS:S)
 */
#define WEAPON_SLOTS_MAX 5

/**
 * 무기의 갯수
 */
#define WEAPON_NUMS 24

/**
 * @section CS:S 시작 무기
 */
#define WEAPON_SPAWN_T_WEAPON "weapon_glock"
#define WEAPON_SPAWN_CT_WEAPON "weapon_usp"
/**
 * @endsection
 */

/**
 * @section 무기 명 인덱스와 탄약 인덱스
 */
new const String:g_sWeaponNames[WEAPON_NUMS][WEAPON_MAX_LENGTH] = 
{
	"weapon_ak47", "weapon_m4a1", "weapon_sg552",
	"weapon_aug", "weapon_galil", "weapon_famas",
	"weapon_scout", "weapon_m249", "weapon_mp5navy",
	"weapon_p90", "weapon_ump45", "weapon_mac10",
	"weapon_tmp", "weapon_m3", "weapon_xm1014",
	"weapon_glock", "weapon_usp", "weapon_p228",
	"weapon_deagle", "weapon_elite", "weapon_fiveseven",
	"weapon_awp", "weapon_g3sg1", "weapon_sg550"
};

new const g_WeaponAmmoData[WEAPON_NUMS][2] = 
{
	{2, 90}, {3, 90}, {3, 90},
	{2, 90}, {3, 90}, {3, 90},
	{2, 90}, {4, 200}, {6, 120},
	{10, 100}, {8, 100}, {8, 100},
	{6, 120}, {7, 32}, {7, 32},
	{6, 120}, {8, 100}, {9, 52},
	{1, 35}, {6, 120}, {10, 100},
	{5, 30}, {2, 90}, {3, 90}
};
/**
 * @endsection
 */

/**
 * @section 무기 슬롯
 */
enum WeaponsSlot
{
	Slot_Invalid		= -1,	/** 무효한 무기 (슬롯) */
	Slot_Primary		= 0,	/** 주 무기 슬롯 */
	Slot_Secondary		= 1,	/** 보조무기 슬롯 */
	Slot_Melee			= 2,	/** 근접무기 (칼) */
	Slot_Projectile		= 3,	/** 발사물 (폭탄, 플래시뱅 등) */
	Slot_Explosive		= 4,	/** 폭발물 (C4) 무기 슬롯 */
	Slot_NVGs			= 5,	/** NVG (가짜) 무기 슬롯 */
}
/**
 * @endsection
 */

/**
 * 클라이언트의 모든 무기 인덱스를 포함할 수 있는 배열을 반영(?)
 * (Return an array that contains all client's weapon indexes.)
 *
 * @param client		클라이언트 인덱스
 * @param weapons		무기 인덱스 배열.
 * 						슬롯에 무기가 없으면 '-1'
 */
stock Weapon_GetClientWeapons(client, weapons[WeaponsSlot])
{
	// x = 무기 슬롯.
	for (new x = 0; x < WEAPON_SLOTS_MAX; x++)
	{
		weapons[x] = GetPlayerWeaponSlot(client, x);
	}
}


/**
 * 클라이언트로부터 발사물 무기를 명백하게 제거할때 사용합니다.
 *
 * @param client		클라이언트 인덱스
 */
stock Weapon_RemoveClientGrenades(client)
{
	// 이 while 이라는 구조는 "unintended assignment" 로 정지되는 바보같은 실수를 합니다. 이런 개객기
	// GetPlayerWeaponsSlot 이 유효한 발사물을 반영(retutns)하는 동안 이를 제거하고 다시 실험합니다?
	//  - (While GetPlayerWeaponSlot returns a valid projectile, remove it and then test again)
	new grenade = GetPlayerWeaponSlot(client, _:Slot_Projectile);
	while (grenade != -1)
	{
		RemovePlayerItem(client, grenade);
		RemoveEdict(grenade);
		
		// 다음 폭탄 찾기.
		grenade = GetPlayerWeaponSlot(client, _:Slot_Projectile);
	}
}


/**
 * 무기를 가져가고 다시 주워주어 새로 고칩니다.
 * (Refresh a weapon by taking it and giving it back.)
 *
 * @param client		클라이언트 인덱스
 * @param slot			새로고칠 무기 슬롯 (enum WeaponsSlot을 보세요.)
 */
stock Weapon_RefreshClientWeapon(client, WeaponsSlot:slot)
{
	new weaponindex = GetPlayerWeaponSlot(client, _:slot);
	
	// 무기가 무효하다면 정지.
	if (weaponindex == -1)
	{
		return;
	}
	
	// 다시 줄 무기의 클래스네임을 획득
	decl String:entityname[WEAPON_MAX_LENGTH];
	GetEdictClassname(weaponindex, entityname, sizeof(entityname));
	
	// 무기 새로고침
	RemovePlayerItem(client, weaponindex);
	RemoveEdict(weaponindex);
	GivePlayerItem(client, entityname);
}


/**
 * 옵션과 함께 클라이언트한테 칼까지 포함한 모든 무기를 제거합니다.
 *
 * @param client		클라이언트 인덱스
 */
stock Weapon_RemoveAllClientWeapons(client, bool:drop = false)
{
	// 모든 클라이언트의 무기 인덱스 목록을 획득.
	new weapons[WeaponsSlot];
	Weapon_GetClientWeapons(client, weapons);
	
	// x = 무기 슬롯.
	for (new x = 0; x < WEAPON_SLOTS_MAX; x++)
	{
		// 무기가 무효하다면 정지.
		if (weapons[x] == -1)
		{
			continue;
		}
		
		// 이게 칼 슬롯이라면 빼앗고 정지한다.
		if (WeaponsSlot:x == Slot_Melee)
		{
			// 칼 빼앗기.
			RemovePlayerItem(client, weapons[x]);
			RemoveEdict(weapons[x]);
			continue;
		}
		
		if (drop)
		{
			// drop이 켜져있으면 무기를 떨군다.
			SDKHooks_DropWeapon(client, weapons[x], NULL_VECTOR, NULL_VECTOR);
		}
		
		else
		{
			// 무기 빼앗기.
			RemovePlayerItem(client, weapons[x]);
			RemoveEdict(weapons[x]);
		}
	}
	
	// 나머지 발사물 제거.
	Weapon_RemoveClientGrenades(client);
	
	// 새 칼을 지급한다. (If you leave the old one there will be glitches with the knife positioning)
	GivePlayerItem(client, "weapon_knife");
}


/**
 * 모든 클라이언트들의 무기를 가져가고 다시 지급해주어 새로 고칩니다.
 * (Refresh a weapon by taking it and giving it back.)
 *
 * @param client		클라이언트 인덱스
 */
stock Weapon_RefreshAllClientWeapons(client)
{
	// 모든 클라이언트의 무기 인덱스 목록을 획득.
	new weapons[WeaponsSlot];
	Weapon_GetClientWeapons(client, weapons);
	
	// x = 무기 슬롯
	for (new x = 0; x < WEAPON_SLOTS_MAX; x++)
	{
		// 무기가 무효하다면 정지.
		if (weapons[x] == -1)
		{
			continue;
		}
		
		Weapon_RefreshClientWeapon(client, WeaponsSlot:x);
	}
}


/**
 * 무기의 투명도를 설정합니다.
 * 
 * @param client		클라이언트 인덱스
 * @param alpha			투명도 값.
 */
stock Weapon_SetWeaponsAlpha(client, alpha)
{
	// 플레이어가 살아있지 않으면 정지.
	if (!IsPlayerAlive(client))
	{
		return;
	}

	// Get client's list of weapons.
	new weapons[WeaponsSlot];
	Weapon_GetClientWeapons(client, weapons);

	// Loop through array slots and set alpha.
	// x = weapon slot.
	for (new x = 0; x < WEAPON_SLOTS_MAX; x++)
	{
		// If weapon is invalid, then stop.
		if (weapons[x] == -1)
		{
			continue;
		}
		
		// Turn rendermode on, on the weapon.
		SetEntityRenderMode(weapons[x], RENDER_TRANSALPHA);
		
		// Set alpha value on the weapon.
		SetEntityRenderColor(weapons[x], _, _, _, alpha);
	}
}

stock Weapon_GetAmmoDataIndex(const String:weapon[])
{
	for (new i = 0; i < WEAPON_NUMS; i++)
	{
		if (StrEqual(weapon, g_sWeaponNames[i]))
		{
			return i;
		}
	}
	return -1;
}

stock Weapon_RestockAmmo(client)
{
	new weaponIndex, dataIndex, ammoOffset;
	decl String:sClassName[32];
	for (new i = 0; i <= 1; i++)
	{
		if (((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
			&& GetEdictClassname(weaponIndex, sClassName, 32)
			&& ((dataIndex = Weapon_GetAmmoDataIndex(sClassName)) != -1)
			&& ((ammoOffset = FindDataMapOffs(client, "m_iAmmo")+(g_WeaponAmmoData[dataIndex][0]*4)) != -1))
		{
			/* Restock! */
			SetEntData(client, ammoOffset, g_WeaponAmmoData[dataIndex][1]);
		}
	}
}

stock Weapon_RemoveAmmo(client)
{
	new weaponIndex, dataIndex, ammoOffset;
	decl String:sClassName[32];
	for (new i = 0; i <= 1; i++)
	{
		if (((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
			&& GetEdictClassname(weaponIndex, sClassName, 32)
			&& ((dataIndex = Weapon_GetAmmoDataIndex(sClassName)) != -1)
			&& ((ammoOffset = FindDataMapOffs(client, "m_iAmmo")+(g_WeaponAmmoData[dataIndex][0]*4)) != -1))
		{
			/* Restock! */
			SetEntData(client, ammoOffset, 0);
		}
	}
}

stock Weapon_RemoveAllWeaponAmmo(client)
{
	new weapons[WeaponsSlot];
	Weapon_GetClientWeapons(client, weapons);
	
	// x = 무기 슬롯.
	for (new x = 0; x < WEAPON_SLOTS_MAX; x++)
	{
		// 무기가 무효하다면 정지.
		if (weapons[x] == -1)	continue;
		
		new String:weaponname[WEAPON_MAX_LENGTH];
		
		if (GetEdictClassname(weapons[x], weaponname, sizeof(weaponname)))
		{
			// 발사물은 그냥 삭제
			if (StrEqual(weaponname, "weapon_hegrenade") || StrEqual(weaponname, "weapon_smokegrenade") || StrEqual(weaponname, "weapon_flashbang"))
			{
				// 무기 삭제
				RemovePlayerItem(client, weapons[x]);
				RemoveEdict(weapons[x]);
			}
			else if (Weapon_GetAmmoDataIndex(weaponname) != -1)
			{
				// 주 총알 제거
				SetEntProp(weapons[x], Prop_Data, "m_iClip1", 0);
				// 보조 총알 제거
				SetEntProp(weapons[x], Prop_Data, "m_iPrimaryAmmoType", 0);
			}
		}
	}
}