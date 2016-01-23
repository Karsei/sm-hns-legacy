/*==================================================================
	
	--------------------------------------
	-*- [Hide and Seek] Stocks Library -*-
	--------------------------------------
	
	Filename: hns_stocks.inc
	Author: Karsei
	Description: Stocks Library
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

/**
 * 공통 모듈; 클라이언트 별 전체 메세지 전달 함수
 *
 * @param client			클라이언트 인덱스
 * @param message			출력 메세지
 *
 * @ref CS:GO Protobuf 종류 - https://github.com/alliedmodders/hl2sdk/blob/csgo/public/game/shared/csgo/protobuf/cstrike15_usermessages.proto#L68
 */
stock SayText2All(client, const String:message[])
{
	new Handle:hMsg = StartMessageAll("SayText2");

	if (hMsg != INVALID_HANDLE)
	{
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hMsg, "ent_idx", client);
			PbSetBool(hMsg, "chat", true);
			PbSetString(hMsg, "msg_name", message);

			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");

			EndMessage();
		}
		else
		{
			BfWriteByte(hMsg, client);
			BfWriteByte(hMsg, true);
			BfWriteString(hMsg, message);
			EndMessage();
		}
	}
}

/**
 * 공통 모듈; nav_progress 관련 데이터 생성
 *
 * @param dataclear			빈 데이터 생성 유/무
 * @param msg				출력 메세지
 * @param current			현재 수치
 * @param max				최대 수치
 * @param showpercent		퍼센트 출력
 */
stock Handle:SetNavProgressData(bool:dataclear, const String:msg[], current = 0, max = 100, bool:showpercent = true)
{
	new String:buffer[256];
	
	buffer[0] = '\0';
	
	if (showpercent && (max > 0))
		Format(buffer, sizeof(buffer), "%s %.1f%", msg, 100.0*float(current)/float(max));
	else
		strcopy(buffer, sizeof(buffer), msg);
	
	new Handle:kv = CreateKeyValues("data");
	
	if (dataclear)
		return kv;
	
	KvSetString(kv, "msg", buffer);
	KvSetNum(kv, "total", max);
	KvSetNum(kv, "current", current);
	
	return kv;
}