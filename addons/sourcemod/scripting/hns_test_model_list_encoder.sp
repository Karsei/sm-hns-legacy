/*==================================================================
	
	--------------------------------------------------
	-*- [Hide and Seek] Test :: Model List Encoder -*-
	--------------------------------------------------
	
	Filename: hns_test_model_list_encoder.sp
	Author: Karsei
	Description: MODEL LIST ENCODER.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <base64>
#include <hns>

/*******************************************************
 E N U M S
*******************************************************/
enum CVAR
{
	Handle:HDATABASESET
}

/*******************************************************
 V A R I A B L E S
*******************************************************/
new hns_eConvar[CVAR];

new Handle:hns_hSQLDatabase = INVALID_HANDLE;

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Test :: Model List Encoder",
	author = HNS_CREATOR,
	description = "MODEL LIST ENCODER.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	hns_eConvar[HDATABASESET] = CreateConVar("hns_database_encode_switch", "1", "1: KeyValue, 2: MySQL");
	
	RegAdminCmd("sm_encodedata", Command_EncodeList, ADMFLAG_ROOT);
	
	PrintToServer("%s (Test) 'Model List Encoder' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (GetConVarInt(hns_eConvar[HDATABASESET]) == 2)
		SQL_TConnect(SQL_GetDatabase, "hnslist");
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 암호화 모듈 :: 모델 목록 암호화
 */
public EncodeModelList()
{
	new Handle:loadkv = INVALID_HANDLE;
	
	if (GetConVarInt(hns_eConvar[HDATABASESET]) == 1)
	{
		new Handle:savekv = INVALID_HANDLE;
		new String:mapname[32], String:filepath[64], String:savepath[64];
		
		// 현재 맵 이름 추출
		GetCurrentMap(mapname, sizeof(mapname));
		
		// 맵에 따른 모델 파일 경로 지정
		BuildPath(Path_SM, filepath, sizeof(filepath), "configs/hide_and_seek/maps/%s.cfg", mapname);
		
		// 저장 파일 경로 지정
		BuildPath(Path_SM, savepath, sizeof(savepath), "configs/hide_and_seek/maps/%s_encode.cfg", mapname);
		
		// 로드 kv 모델 핸들에 'models' 키밸류 추가
		loadkv = CreateKeyValues("Models");
		
		// 저장 kv 모델 핸들에 'models' 키밸류 추가
		savekv = CreateKeyValues("Models");
		
		// 로드 kv에서 이전에 로드한 경로에 키밸류 접근 시도
		FileToKeyValues(loadkv, filepath);
		
		// 저장 파일을 지정한 것이 존재할 경우 저장 kv에서 이전에 로드한 경로에 키밸류 접근 시도
		if (FileExists(savepath))
			FileToKeyValues(savekv, savepath);
		
		// 경로가 없을 경우 에러 출력
		if (!KvGotoFirstSubKey(loadkv))
		{
			SetFailState("%s Can't parse this map(%s) model config file.", HNS_PHRASE_PREFIX, mapname);
			return;
		}
		
		do
		{
			// 파일에 있는 모델 경로 로드
			decl String:modelpath[128], String:enpath[256];
			
			KvGetSectionName(loadkv, modelpath, sizeof(modelpath));
			
			EncodeBase64(enpath, sizeof(enpath), modelpath);
			KvJumpToKey(savekv, enpath, true);
			
			// 각 언어별 체크
			for (new i = 0; i < GetLanguageCount(); i++)
			{
				decl String:langcode[4], String:modelname[128], String:enlangcode[32], String:enmodelname[128];
				
				// 언어 코드 로드
				GetLanguageInfo(i, langcode, sizeof(langcode));
				
				// 언어 코드에 따른 모델 이름 로드
				KvGetString(loadkv, langcode, modelname, sizeof(modelname));
				
				// 각 언어에 대한 이름이 있으면 체크
				if (strlen(modelname) > 0)
				{
					EncodeBase64(enlangcode, sizeof(enlangcode), langcode);
					EncodeBase64(enmodelname, sizeof(enmodelname), modelname);
					KvSetString(savekv, enlangcode, enmodelname);
				}
			}
			
			// 모델 높이 로드
			decl String:hfix[16], String:enhfixtitle[64], String:enhfix[64];
			
			KvGetString(loadkv, "heightfix", hfix, sizeof(hfix), "no");
			if (!StrEqual(hfix, "no", false))
			{
				EncodeBase64(enhfixtitle, sizeof(enhfixtitle), "heightfix");
				EncodeBase64(enhfix, sizeof(enhfix), hfix);
				KvSetString(savekv, enhfixtitle, enhfix);
			}
			
			// 금전 로드
			decl String:usemoney[16], String:enumtitle[64], String:enusemoney[64];
			
			KvGetString(loadkv, "usemoney", usemoney, sizeof(usemoney), "no");
			if (!StrEqual(usemoney, "no", false))
			{
				EncodeBase64(enumtitle, sizeof(enumtitle), "usemoney");
				EncodeBase64(enusemoney, sizeof(enusemoney), usemoney);
				KvSetString(savekv, enumtitle, enusemoney);
			}
			
			KvRewind(savekv);
			
		} while (KvGotoNextKey(loadkv));
		
		KvRewind(loadkv);
		KvRewind(savekv);
		
		KeyValuesToFile(savekv, savepath);
		
		CloseHandle(loadkv);
		CloseHandle(savekv);
	}
	else if (GetConVarInt(hns_eConvar[HDATABASESET]) == 2)
	{
		new String:mapname[32], String:filepath[64];
		
		// 현재 맵 이름 추출
		GetCurrentMap(mapname, sizeof(mapname));
		
		// 맵에 따른 모델 파일 경로 지정
		BuildPath(Path_SM, filepath, sizeof(filepath), "configs/hide_and_seek/maps/%s.cfg", mapname);
		
		// 로드 kv 모델 핸들에 'models' 키밸류 추가
		loadkv = CreateKeyValues("Models");
		
		// 이전에 로드한 경로에 키밸류 접근 시도
		FileToKeyValues(loadkv, filepath);
		
		// 경로가 없을 경우 에러 출력
		if (!KvGotoFirstSubKey(loadkv))
		{
			SetFailState("%s Can't parse this map(%s) model config file.", HNS_PHRASE_PREFIX, mapname);
			return;
		}
		
		do
		{
			// 파일에 있는 모델 경로 로드
			decl String:modelpath[128];
			
			KvGetSectionName(loadkv, modelpath, sizeof(modelpath));
			
			// 모델 높이 로드
			decl String:hfix[16];
			
			KvGetString(loadkv, "heightfix", hfix, sizeof(hfix), "no");
			
			// 금전 로드
			decl String:usemoney[16];
			
			KvGetString(loadkv, "usemoney", usemoney, sizeof(usemoney), "no");
			
			// 각 언어별 메뉴 생성
			new String:langnamedata[512];
			
			for (new i = 0; i < GetLanguageCount(); i++)
			{
				decl String:langcode[4], String:modelname[128];
				
				// 언어 코드 로드
				GetLanguageInfo(i, langcode, sizeof(langcode));
				
				// 언어 코드에 따른 모델 이름 로드
				KvGetString(loadkv, langcode, modelname, sizeof(modelname));
				
				// 각 언어에 대한 이름이 있으면 체크
				if (strlen(modelname) > 0)
					Format(langnamedata, sizeof(langnamedata), "%s[[%s]]%s", langnamedata, langcode, modelname);
			}
			
			// 암호화
			decl String:enpath[256], String:enhfix[64], String:enmoney[64], String:enlangnamedata[512];
			
			EncodeBase64(enpath, sizeof(enpath), modelpath);
			EncodeBase64(enhfix, sizeof(enhfix), hfix);
			EncodeBase64(enmoney, sizeof(enmoney), usemoney);
			EncodeBase64(enlangnamedata, sizeof(enlangnamedata), langnamedata);
			
			// 익스포트
			decl String:genquery[1024];
			
			Format(genquery, sizeof(genquery), "INSERT INTO hns_modellist(modelpath, heightfix, usemoney, langnamedata) VALUES('%s', '%s', '%s', '%s')", 
												enpath, enhfix, enmoney, enlangnamedata);
			SQL_TQuery(hns_hSQLDatabase, SQL_ErrorProcess, genquery, 0);
			
		} while (KvGotoNextKey(loadkv));
		
		KvRewind(loadkv);
	}
}

/*******************************************************
 C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 암호화 모듈 :: 모델 목록 암호화 처리 전 준비
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_EncodeList(client, args)
{
	EncodeModelList();
	
	return Plugin_Continue;
}

/**
 * SQL :: SQL 메인 처리 함수
 *
 * @param owner				알 수 없음
 * @param hndl				데이터베이스 핸들
 * @param error				에러 메세지
 * @param data				기타 파라메터
 */
public SQL_GetDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ((hndl == INVALID_HANDLE) || (error[0]))
	{
		PrintToServer("%s Database failure: %s", HNS_PHRASE_PREFIX, error);
		return;
	}
	hns_hSQLDatabase = hndl;
	
	new String:charquery[64];
	
	// UTF-8 로 처리하도록 설정
	Format(charquery, sizeof(charquery), "SET NAMES \"UTF8\"");
	SQL_TQuery(hndl, SQL_ErrorProcess, charquery, data);
}

/**
 * SQL :: 일반 에러 출력 함수
 *
 * @param owner				알 수 없음
 * @param hndl				데이터베이스 핸들
 * @param error				에러 메세지
 * @param data				기타 파라메터
 */
public SQL_ErrorProcess(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ((hndl == INVALID_HANDLE) || (error[0]))
	{
		PrintToServer("%s Query Failed: %s", HNS_PHRASE_PREFIX, error);
		if (data > 0)
			PrintToChat(data, "\x04%s \x01오류가 발생했습니다: %s", HNS_PHRASE_PREFIX, error);
	}
}