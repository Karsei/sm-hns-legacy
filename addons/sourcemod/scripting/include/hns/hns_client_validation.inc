/*==================================================================
	
	-------------------------------------------------
	-*- [Hide and Seek] Base :: Client Validation -*-
	-------------------------------------------------
	
	Filename: hns_client_validation.inc
	Author: Karsei
	Description: Check client validation in-game.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

/**
 * 클라이언트가 유효한가요?
 *
 * @param client		클라이언트 인덱스.
 */
stock bool:HNS_IsClientValid(client, bool:console = false)
{
	if (client > MaxClients)
	{
		return false;
	}
	
	return console ? (client >= 0) : (client > 0);
}


/**
 * 클라이언트가 한쪽 팀에 들어가있기는 한가요?
 *
 * @param client		클라이언트 인덱스.
 * @param team			팀 인덱스.
 */
stock bool:HNS_IsClientOnTeam(client, team = -1)
{
	// 클라이언트가 유효하지 않으면 정지.
	if (!HNS_IsClientValid(client))
	{
		return false;
	}
	
	// 클라이언트가 속한 팀 획득.
	new clientteam = GetClientTeam(client);
	
	if (team == -1)
	{
		return (clientteam == CS_TEAM_T || clientteam == CS_TEAM_CT);
	}
	
	return (clientteam == team);
}


/**
 * 각 팀에 클라이언트가 있는지 검사.
 *
 * @param team			팀 인덱스.
 */
stock bool:HNS_TeamHasClients(team = -1)
{
	if (team == -1)
	{
		// 양 팀이 적어도 1명의 클라이언트를 포함하고있다면 return true.
		return (GetTeamClientCount(CS_TEAM_T) && GetTeamClientCount(CS_TEAM_CT));
	}

	// 주어진 팀에 적어도 1명의 클라이언트가 포함되어있다면 return true.
	return bool:GetTeamClientCount(team);
}
