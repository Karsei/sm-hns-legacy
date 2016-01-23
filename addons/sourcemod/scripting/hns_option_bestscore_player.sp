/*==================================================================
	
	----------------------------------------------
	-*- [Hide and Seek] Option :: Player Score -*-
	----------------------------------------------
	
	Filename: hns_option_player_score.sp
	Author: Karsei
	Description: Record player's score of the map.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2013-2015 by Karsei All Right Reserved.
	
==================================================================*/

/**********************************************************************
 Semicolon
 **********************************************************************/
#pragma semicolon 1


/**********************************************************************
 Headers
 **********************************************************************/
#include <sourcemod>
#include <cstrike>
#include <hns>


/**********************************************************************
 Variables
 **********************************************************************/
// 플레이어당 점수.
new iScore[MAXPLAYERS + 1] = 0;

// 서버 명령어.
enum CVARS
{
	Handle:hider_win,
	Handle:hider_bunny,
	Handle:hider_bunnycount,
	Handle:hider_bunnyspeed,
	Handle:hider_onlyone,
	Handle:seeker_win,
	Handle:seeker_attack,
	Handle:seeker_kill,
	Handle:seeker_onlyone
}
new g_hCV[CVARS];


/**********************************************************************
 Plugin information
 **********************************************************************/
public Plugin:myinfo = 
{
	name		= "[Hide and Seek] Best Score Player",
	author		= "Karsei",
	description = "Best Score Player of the map",
	version		= HNS_VERSION,
	url 		= HNS_CREATOR_URL
}


/**********************************************************************
 SourceMod General Forwards
 **********************************************************************/
/**
 * 플러그인 로딩중
 */
public OnPluginStart()
{
	// 서버 명령어.
	g_hCV[hider_win] = CreateConVar("hns_scoreplayer_hider_win", "500", "Gain score to win t player.");
	g_hCV[hider_bunny] = CreateConVar("hns_scoreplayer_hider_bunny", "100", "Gain score when t player doing bunny hopping.");
	g_hCV[hider_bunnycount] = CreateConVar("hns_scoreplayer_hider_bunny_count", "5", "Detect bunny hopping count for gaining score.");
	g_hCV[hider_bunnyspeed] = CreateConVar("hns_scoreplayer_hider_bunny_speed", "5.0", "Detect bunny hopping speed for gaining score.");
	g_hCV[hider_onlyone] = CreateConVar("hns_scoreplayer_hider_onlyone", "1000", "Gain score to last t survivor.");
	g_hCV[seeker_win] = CreateConVar("hns_scoreplayer_seeker_win", "500", "Gain score to win t player.");
	g_hCV[seeker_attack] = CreateConVar("hns_scoreplayer_seeker_attack", "10", "Gain score to ct player attacks t.");
	g_hCV[seeker_kill] = CreateConVar("hns_scoreplayer_seeker_kill", "500", "Gain score to ct player kills t.");
	g_hCV[seeker_onlyone] = CreateConVar("hns_scoreplayer_seeker_onlyone", "1000", "Gain score to last ct player.");
	
	// 게임 이벤트.
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);

	// 알림.
	PrintToServer("%s (Option) 'Money System Wrapper' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 설정이 완료된 후
 */
public OnMapStart()
{
	// 클라이언트 전체.
	// x = 클라이언트 인덱스.
	for (new x = 1; x <= MaxClients; x++)
	{
		iScore[x] = 0;
	}
}

/**
 * 클라이언트 퇴장.
 *
 * @param client 		클라이언트 인덱스.
 */
public OnClientDisconnect(client)
{
	iScore[client] = 0;
}


/*****************************************************************
 Callbacks
 *****************************************************************/
/**
 * Game event: player_hurt
 *
 * @param event				The event handle.
 * @param name				The name of event.
 * @param dontBroadcast		If true, event is broadcasted to all clients, false if not.
 */
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// 공격자 인덱스.
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	// 찾는자에게 공격점수를 가산시키나요?
	new icvvSeekerAttack = GetConVarInt(g_hCV[seeker_attack]);
	if (icvvSeekerAttack > 0) {
		// 찾는자인가요?
		if (HNS_IsClientSeeker(attacker))
			iScore[attacker] += icvvSeekerAttack;
	}
}

/**
 * Game event: player_death
 *
 * @param event				The event handle.
 * @param name				The name of event.
 * @param dontBroadcast		If true, event is broadcasted to all clients, false if not.
 */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// 공격자 인덱스.
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	// 찾는자에게 공격점수를 가산시키나요?
	new icvvSeekerKill = GetConVarInt(g_hCV[seeker_kill]);
	if (icvvSeekerKill > 0) {
		// 찾는자인가요?
		if (HNS_IsClientSeeker(attacker))
			iScore[attacker] += icvvSeekerKill;
	}
}

/**
 * Game event: round_end
 *
 * @param event				The event handle.
 * @param name				The name of event.
 * @param dontBroadcast		If true, event is broadcasted to all clients, false if not.
 */
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// 이긴 팀 인덱스.
	new winteam = GetEventInt(event, "winner");

	new icvvHiderWin = GetConVarInt(g_hCV[hider_win]);
	new icvvHiderSurvivor = GetConVarInt(g_hCV[hider_onlyone]);
	new icvvSeekerWin = GetConVarInt(g_hCV[seeker_win]);
	new icvvSeekerSurvivor = GetConVarInt(g_hCV[seeker_onlyone]);
	new iAlive = GetAliveCount();

	// 클라이언트 전체.
	// x = 클라이언트 인덱스.
	for (new x = 1; x <= MaxClients; x++)
	{
		// 유효성 검사.
		if (!IsClientInGame(x)) continue;
		if (!IsPlayerAlive(x)) continue;
		
		if (icvvHiderWin > 0)
		{
			if (winteam == CS_TEAM_T && HNS_IsClientHider(x) 
				|| winteam == CS_TEAM_CT && HNS_IsClientHider(x))
			{
				iScore[x] += icvvHiderWin;
			}
		}

		if (icvvSeekerWin > 0)
		{
			if (winteam == CS_TEAM_T && HNS_IsClientSeeker(x) 
				|| winteam == CS_TEAM_CT && HNS_IsClientSeeker(x))
			{
				iScore[x] += icvvSeekerWin;
			}
		}
		
		if (iAlive == 1 && winteam == CS_TEAM_T && HNS_IsClientHider(x)
				|| iAlive == 1 && winteam == CS_TEAM_CT && HNS_IsClientHider(x))
		{
			iScore[x] += icvvHiderSurvivor;
		}

		if (iAlive == 1 && winteam == CS_TEAM_T && HNS_IsClientSeeker(x)
				|| iAlive == 1 && winteam == CS_TEAM_CT && HNS_IsClientSeeker(x))
		{
			iScore[x] += icvvSeekerSurvivor;
		}
	}
}

/**
 * @param client		Index of the client.
 * @param buttons		Copyback buffer containing the current commands (as bitflags - see entity_prop_stocks.inc).
 * @param impulse		Copyback buffer containing the current impulse command.
 * @param vel			Players desired velocity.
 * @param angles		Players desired view angles.
 * @param weapon		Entity index of the new weapon if player switches weapon, 0 otherwise.
 * @param subtype		Weapon subtype when selected from a menu.
 * @param cmdnum		Command number. Increments from the first command sent.
 * @param tickcount		Tick count. A client's prediction based on the server's GetGameTickCount value.
 * @param seed			Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param mouse			Mouse direction (x, y).
 */
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	// 숨는자 인가요?
	if (!HNS_IsClientHider(client))
		return Plugin_Continue;

	// SHIFT를 누르고 있나요? (비행물체 방지.)
	if (!(buttons & IN_SPEED))
		return Plugin_Continue;

	new icvvBunny = GetConVarInt(g_hCV[hider_bunny]);
	if (icvvBunny > 0)
	{
		new flag = GetEntityFlags(client);
		new bunnycount = GetBunnyHopCount(client);
		if (!(flag & FL_ONGROUND) && bunnycount >= 5)
		{
			iScore[client] += icvvBunny;
		}
	}

	return Plugin_Continue;
}


/*****************************************************************
 Generals
 *****************************************************************/
/**
 * 살아있는 플레이어의 수를 셉니다.
 */
stock GetAliveCount()
{
	// 살아있는 플레이어 식별자.
	new iAlive;

	// 클라이언트 전체 구하기.
	// x = 클라이언트 인덱스.
	for (new x = 1; x <= MaxClients; x++)
	{
		// 유효성 검사.
		if (!IsClientInGame(x)) continue;
		if (!IsPlayerAlive(x)) continue;

		// 수 증가.
		iAlive++;
	}

	// 반영.
	return iAlive;
}

/**
 * 버니합 횟수를 셉니다.
 *
 * @param client 		클라이언트 인덱스.
 */
stock GetBunnyHopCount(client)
{
	// 버니합 횟수 식별자.
	new count[MAXPLAYERS + 1];

	// 플레이어의 속도(벨로서티)
	new Float:velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

	// 콘바값.
	new Float:flcvvHiderBunnySpeed = GetConVarFloat(g_hCV[hider_bunnyspeed]);

	// 플레이어 상태.
	new buttons = GetClientButtons(client);
	
	// 속도가 지정 값 이상인가요?
	if (velocity[0] >= flcvvHiderBunnySpeed)
	{
		if (buttons & IN_JUMP)
			count[client]++;
	}

	// 아니면 초기화.
	else count[client] = 0;

	// 반영.
	return count[client];
}
