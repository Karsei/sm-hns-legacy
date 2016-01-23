/*==================================================================
	
	---------------------------------------
	-*- [Hide and Seek] Manage :: Model -*-
	---------------------------------------
	
	Filename: hns_manage_model.sp
	Author: Karsei
	Description: This controls models for several systems.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <base64>
#include <hns>

#define MAX_LANGUAGES				27
#define MAX_MODELLISTCOUNT			300

/*******************************************************
 E N U M S
*******************************************************/
enum CVAR
{
	Handle:HDATABASESET,
	Handle:HDECODESET,
	Handle:HIDETIME
}

/*******************************************************
 V A R I A B L E S
*******************************************************/
new hns_eConvar[CVAR];

new Handle:hns_hSQLDatabase = INVALID_HANDLE;
new Handle:hns_hKvModel = INVALID_HANDLE;

new Handle:hns_hModelMenu[MAX_LANGUAGES] = {INVALID_HANDLE,...};
new String:hns_sModelMenuLanguage[MAX_LANGUAGES][4];
new bool:hns_bIsModelMenuCreated = false;

new hns_iModelCount = 0;
new String:hns_sModelInfo[MAX_MODELLISTCOUNT+1][MAX_LANGUAGES+1][128];

new bool:hns_bModelUserChanged[MAXPLAYERS+1] = {false,...};
new Float:hns_fFixedUserModelHeight[MAXPLAYERS+1] = {0.0,...};
new Float:hns_fTopMaxHeight[MAXPLAYERS+1] = {0.0,...};
new bool:hns_bFixedUserHigher[MAXPLAYERS+1] = {false,...};
new bool:hns_bTopMaxHeight[MAXPLAYERS+1] = {false,...};
new bool:hns_bIsUserMoving[MAXPLAYERS+1] = {false,...};

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Manage :: Model",
	author = HNS_CREATOR,
	description = "This controls models for several systems.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	hns_eConvar[HDATABASESET] = CreateConVar("hns_database_switch", "1", "1: KeyValue, 2: MySQL");
	hns_eConvar[HDECODESET] = CreateConVar("hns_load_list_decode_switch", "1", "Set Decode?");
	hns_eConvar[HIDETIME] = CreateConVar("hns_hide_time", "45.0", "Hide time.");
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegConsoleCmd("sm_showmodel", Command_ShowModelMenu);
	
	RegAdminCmd("sm_rebuildmodelmenu", Command_ReBuildModelMenu, ADMFLAG_ROOT);
	RegAdminCmd("sm_showmodellist", Command_ShowModelList, ADMFLAG_ROOT);
	
	HookEvent("round_freeze_end", Event_OnRoundFreezeEnd);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	
	LoadTranslations("plugin.hide_and_seek");
	
	PrintToServer("%s (Manage) 'Model' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

public OnMapStart()
{
	if (!HNS_IsEngineWork())	return;
	
	// 모델 데이터 관련 초기화
	DataInitialize();
	
	// 변장 모델 메뉴 생성
	if (GetConVarInt(hns_eConvar[HDATABASESET]) == 1)
		BuildMainModel();
	else if (GetConVarInt(hns_eConvar[HDATABASESET]) == 2)
		SQL_TConnect(SQL_GetDatabase, "hnslist");
}

public OnMapEnd()
{
	if (!HNS_IsEngineWork())	return;
	
	// 모델 데이터 관련 초기화
	DataInitialize();
}

/**
 * 본격적인 게임이 시작될 때
 *
 * @param start				시작 유/무
 */
public HNS_OnToggleGame_Post(bool:start)
{
	if (!HNS_IsEngineWork())	return;
	
	// 본격적인 게임이 시작할 때
	if (start)
	{
		// 특정 숨는 사람이 아직 모델을 정하지 않았다면 모델을 랜덤으로 적용
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && HNS_IsClientHider(i) && !hns_bModelUserChanged[i])
			{
				if (!IsFakeClient(i))
					HNS_T_PrintToChat(i, "time no choose random model");
				
				SetMainModel(i, 1, "");
			}
		}
	}
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 모델 모듈 :: 변수에 저장된 변장 모델 관련 정보 초기화
 */
public DataInitialize()
{
	if (!HNS_IsEngineWork())	return;
	
	// 모델 관련 핸들 및 변수 초기화
	if (GetConVarInt(hns_eConvar[HDATABASESET]) == 1)
	{
		if (hns_hKvModel != INVALID_HANDLE)
		{
			CloseHandle(hns_hKvModel);
		}
		hns_hKvModel = INVALID_HANDLE;
	}
	else if (GetConVarInt(hns_eConvar[HDATABASESET]) == 2)
	{
		if (hns_hSQLDatabase != INVALID_HANDLE)
		{
			CloseHandle(hns_hSQLDatabase);
		}
		hns_hSQLDatabase = INVALID_HANDLE;
	}
	
	for (new i = 0; i < MAX_LANGUAGES; i++)
	{
		if (hns_hModelMenu[i] != INVALID_HANDLE)
		{
			CloseHandle(hns_hModelMenu[i]);
		}
		hns_hModelMenu[i] = INVALID_HANDLE;
		Format(hns_sModelMenuLanguage[i], 4, "");
	}
	hns_iModelCount = 0;
	hns_bIsModelMenuCreated = false;
	
	for (new i = 0; i < hns_iModelCount+1; i++)
	{
		for (new k = 0; k < MAX_LANGUAGES+1; k++)
		{
			Format(hns_sModelInfo[i][k], 128, "");
		}
	}
}

/**
 * 모델 모듈 :: 기본 변장 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param select			처리 번호
 *							(1 - 변장 모델)
 */
public ShowMainModel(client, select)
{
	if (!HNS_IsEngineWork())	return;
	
	new cllangid = GetClientLanguageID(client, select);
	
	if (hns_bIsModelMenuCreated)
	{
		if (hns_hModelMenu[cllangid] != INVALID_HANDLE)
			DisplayMenu(hns_hModelMenu[cllangid], client, MENU_TIME_FOREVER);
		else
			HNS_T_PrintToChat(client, "no menu created");
	}
	else
	{
		HNS_T_PrintToChat(client, "no menu created");
	}
}

/**
 * 모델 모듈 :: 모델 변장 특별 처리
 *
 * @param client			클라이언트 인덱스
 * @param process			처리 번호
 *							(1 - 랜덤, 2 - 채팅 수동)
 */
public SetMainModel(client, process, String:data[])
{
	if (!HNS_IsEngineWork())	return;
	
	if (!hns_bIsModelMenuCreated)
	{
		HNS_T_PrintToChat(client, "no menu created");
		return;
	}
	
	new setid;
	
	if (process == 1)
	{
		setid = GetRandomInt(1, hns_iModelCount);
	}
	else if (process == 2)
	{
		ReplaceString(data, 128, '"', '');
		
		if (StrContains(data, "#") != -1)
		{
			new checkid = StringToInt(data[1]);
			
			if ((checkid <= hns_iModelCount) && (checkid != 0))
			{
				setid = checkid;
			}
			else
			{
				HNS_T_PrintToChat(client, "set parameter no id");
				return;
			}
		}
		else // 문자
		{
			new count;
			
			for (new i = 1; i <= hns_iModelCount; i++)
			{
				new samething = 0;
				
				for (new k = 0; k < MAX_LANGUAGES; k++)
				{
					if (StrContains(hns_sModelInfo[i][k], data, false) != -1)
					{
						setid = i;
						count++;
						samething++;
					}
				}
				
				// 한 모델에서 찾는 문장으로 한번 더 발견되는 경우는 count 수를 하나 감소
				if (samething > 0)
					count--;
			}
			
			if (count > 1)
			{
				HNS_T_PrintToChat(client, "set parameter one more");
				return;
			}
			else if (count < 1)
			{
				HNS_T_PrintToChat(client, "set parameter no model");
				return;
			}
		}
	}
	
	new String:setdata[128], MODELSETDATA = 27;
	new cllangid = GetClientLanguageID(client, 1);
	
	Format(setdata, sizeof(setdata), hns_sModelInfo[setid][MODELSETDATA]);
	
	new charpos1;
	
	// ROOT 어드민인지 체크하고 돈 적용 유/무 처리
	if (!HNS_IsClientAdmin(client, Admin_Root))
	{
		// 금액 로드 후 알아서 계산
		if ((charpos1 = StrContains(setdata, "||um_", false)) != -1)
		{
			new String:smodelmoney[16];
			new clientmoney = HNS_GetClientMoney(client);
			
			new charpos2 = StrContains(setdata[charpos1+5], "||hf_", false);
			
			if (charpos2 != -1)
				strcopy(smodelmoney, charpos2-charpos1+4, setdata[charpos1+5]);
			else
				strcopy(smodelmoney, sizeof(smodelmoney), setdata[charpos1+5]);
			
			new imodelmoney = StringToInt(smodelmoney);
			
			// 돈이 부족할 경우
			if (clientmoney < imodelmoney)
			{
				HNS_T_PrintToChat(client, "usemoney your money no");
				ShowMainModel(client, 1);
				return;
			}
			
			HNS_SetClientMoney(client, (clientmoney - imodelmoney));
			
			HNS_T_PrintToChat(client, "usemoney accept", imodelmoney);
		}
	}
	
	// 높이 초기화
	if (!hns_bIsUserMoving[client])
	{
		new Float:origin[3];
				
		GetClientAbsOrigin(client, origin);
		
		if (!hns_bTopMaxHeight[client])
			origin[2] -= hns_fFixedUserModelHeight[client];
		else
			origin[2] -= hns_fTopMaxHeight[client];
		
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	}
	hns_bFixedUserHigher[client] = false;
	
	// 화면 고정 해제 및 움직임 정상 처리
	HNS_SetClientFreezed(client, false);
	
	// 높이 조정 값 로드
	if((charpos1 = StrContains(setdata, "||hf_")) != -1)
	{
		hns_fFixedUserModelHeight[client] = StringToFloat(setdata[charpos1+5]);
		HNS_SetClientModelHeight(client, StringToFloat(setdata[charpos1+5]));
		HNS_T_PrintToChat(client, "heightfix fixed");
	}
	else
	{
		hns_fFixedUserModelHeight[client] = 0.0;
		HNS_SetClientModelHeight(client, 0.0);
		hns_fTopMaxHeight[client] = 0.0;
	}
	
	new String:modelpath[128];
	
	// 모델 경로 로드 및 적용
	if (SplitString(setdata, "||", modelpath, sizeof(modelpath)) == -1)
		strcopy(modelpath, sizeof(modelpath), setdata);
	
	SetEntityModel(client, modelpath);
	HNS_T_PrintToChat(client, "im this model", hns_sModelInfo[setid][cllangid]);
	
	hns_bModelUserChanged[client] = true;
}

/**
 * 모델 모듈 :: 기본 변장 메뉴 준비
 */
public BuildMainModel()
{
	if (GetConVarInt(hns_eConvar[HDATABASESET]) == 1)
	{
		new String:mapname[32], String:filepath[128];
		
		// 현재 맵 이름 추출
		GetCurrentMap(mapname, sizeof(mapname));
		
		// 맵에 따른 모델 파일 경로 지정
		if (GetConVarBool(hns_eConvar[HDECODESET]))
			BuildPath(Path_SM, filepath, sizeof(filepath), "configs/hide_and_seek/maps/%s_encode.cfg", mapname);
		else
			BuildPath(Path_SM, filepath, sizeof(filepath), "configs/hide_and_seek/maps/%s.cfg", mapname);
		
		// kv 모델 핸들에 'models' 키밸류 추가
		hns_hKvModel = CreateKeyValues("Models");
		
		// 이전에 로드한 경로에 키밸류 접근 시도
		FileToKeyValues(hns_hKvModel, filepath);
		
		// 경로가 없을 경우 에러 출력
		if (!KvGotoFirstSubKey(hns_hKvModel))
		{
			//SetFailState("%s Can't parse this map(%s) model config file.", HNS_PHRASE_PREFIX, mapname);
			PrintToServer("%s Can't parse this map(%s) model config file [%s].", HNS_PHRASE_PREFIX, mapname, filepath);
			return;
		}
		
		// 반복하면서 각 하위 키벨류에 대해서 처리
		new langid, langreadyid = -1;
		
		do
		{
			hns_iModelCount++;
			
			decl String:finalresult[128];
			
			// 파일에 있는 모델 경로를 완전한 경로로 변경 후 프리캐시를 한 다음 결과값에 저장
			decl String:modelpath[128], String:enpath[256];
			
			if (GetConVarBool(hns_eConvar[HDECODESET]))
			{
				KvGetSectionName(hns_hKvModel, enpath, sizeof(enpath));
				DecodeBase64(modelpath, sizeof(modelpath), enpath);
			}
			else
			{
				KvGetSectionName(hns_hKvModel, modelpath, sizeof(modelpath));
			}
			Format(finalresult, sizeof(finalresult), "models/%s.mdl", modelpath);
			PrecacheModel(finalresult, true);
			
			// 모델 높이를 결과값에 저장
			decl String:hfix[16], String:enhfix[64];
			
			if (GetConVarBool(hns_eConvar[HDECODESET]))
			{
				KvGetString(hns_hKvModel, "aGVpZ2h0Zml4", enhfix, sizeof(enhfix), "no");
				if (!StrEqual(enhfix, "no", false))
				{
					DecodeBase64(hfix, sizeof(hfix), enhfix);
					Format(finalresult, sizeof(finalresult), "%s||hf_%s", finalresult, hfix);
				}
			}
			else
			{
				KvGetString(hns_hKvModel, "heightfix", hfix, sizeof(hfix), "no");
				if (!StrEqual(hfix, "no", false))
					Format(finalresult, sizeof(finalresult), "%s||hf_%s", finalresult, hfix);
			}
			
			// 금전을 결과값에 저장
			decl String:usemoney[16], String:enusemoney[64];
			
			if (GetConVarBool(hns_eConvar[HDECODESET]))
			{
				KvGetString(hns_hKvModel, "dXNlbW9uZXk=", enusemoney, sizeof(enusemoney), "no");
				if (!StrEqual(enusemoney, "no", false))
				{
					DecodeBase64(usemoney, sizeof(usemoney), enusemoney);
					Format(finalresult, sizeof(finalresult), "%s||um_%s", finalresult, usemoney);
				}
			}
			else
			{
				KvGetString(hns_hKvModel, "usemoney", usemoney, sizeof(usemoney), "no");
				if (!StrEqual(usemoney, "no", false))
					Format(finalresult, sizeof(finalresult), "%s||um_%s", finalresult, usemoney);
			}
			
			// 각 언어별 메뉴 생성
			for (new i = 0; i < GetLanguageCount(); i++)
			{
				decl String:langcode[4], String:modelname[128], String:enlangcode[32], String:enmodelname[128];
				
				// 언어 코드 로드
				GetLanguageInfo(i, langcode, sizeof(langcode));
				
				// 언어 코드에 따른 모델 이름 로드
				if (GetConVarBool(hns_eConvar[HDECODESET]))
				{
					EncodeBase64(enlangcode, sizeof(enlangcode), langcode);
					KvGetString(hns_hKvModel, enlangcode, enmodelname, sizeof(enmodelname));
					DecodeBase64(modelname, sizeof(modelname), enmodelname);
				}
				else
				{
					KvGetString(hns_hKvModel, langcode, modelname, sizeof(modelname));
				}
				
				// 메뉴 생성
				if (strlen(modelname) > 0)
				{
					// 금액이 붙은 모델은 모델 이름을 살짝 변경
					if (GetConVarBool(hns_eConvar[HDECODESET]))
					{
						if (!StrEqual(enusemoney, "no", false))
							Format(modelname, sizeof(modelname), "%s ($%d)", modelname, StringToInt(usemoney));
					}
					else
					{
						if (!StrEqual(usemoney, "no", false))
							Format(modelname, sizeof(modelname), "%s ($%d)", modelname, StringToInt(usemoney));
					}
					
					// 해당 언어가 변장 모델 메뉴의 언어 ID에 데이터가 존재하는지 체크
					langid = CheckMenuLanguageID(1, langcode);
					
					//PrintToServer("%s ----- MODEL NAME: %s, Langcode: %s (langid: %d ; -1 is none)", HNS_PHRASE_PREFIX, modelname, langcode, langid);
					
					// 그 데이터가 없을때 처리
					if (langid == -1)
					{
						langreadyid = GetMenuLanguageReadyID(1);
						hns_sModelMenuLanguage[langreadyid] = langcode;
					}
					
					if ((langid == -1) && (hns_hModelMenu[langreadyid] == INVALID_HANDLE))
					{
						hns_hModelMenu[langreadyid] = CreateMenu(Menu_MainModelS);
						
						//PrintToServer("%s ---------------- SET MENU ID : %d", HNS_PHRASE_PREFIX, langreadyid);
						
						decl String:buffer[512];
						
						Format(buffer, sizeof(buffer), "%t\n ", "select model title");
						SetMenuTitle(hns_hModelMenu[langreadyid], buffer);
						SetMenuExitButton(hns_hModelMenu[langreadyid], true);
						SetMenuExitBackButton(hns_hModelMenu[langreadyid], true);
					}
					
					// 메뉴 항목 생성
					if (langid == -1)
					{
						Format(hns_sModelInfo[hns_iModelCount][langreadyid], 128, modelname);
						AddMenuItem(hns_hModelMenu[langreadyid], finalresult, modelname);
					}
					else
					{
						Format(hns_sModelInfo[hns_iModelCount][langid], 128, modelname);
						AddMenuItem(hns_hModelMenu[langid], finalresult, modelname);
					}
				}
			}
			Format(hns_sModelInfo[hns_iModelCount][27], 128, finalresult);
		} while (KvGotoNextKey(hns_hKvModel));
		
		KvRewind(hns_hKvModel);
		
		hns_bIsModelMenuCreated = true;
	}
	else if (GetConVarInt(hns_eConvar[HDATABASESET]) == 2)
	{
		new String:genquery[512];
		
		Format(genquery, sizeof(genquery), "SELECT * FROM hns_modellist ORDER BY idnum ASC");
		SQL_TQuery(hns_hSQLDatabase, SQL_BuildMainMenu, genquery, 0);
	}
}

/**
 * 모델 모듈 :: 나는 누구 메세지 처리
 *
 * @param client			클라이언트 인덱스
 */
public Command_MyModel(client)
{
	// 숨는 사람이 아니면 사용하지 못하도록 처리
	if (!HNS_IsClientHider(client))
	{
		HNS_T_PrintToChat(client, "only terrorists can use this");
		return;
	}
	
	// 죽은 사람은 무시
	if (!IsPlayerAlive(client))
	{
		HNS_T_PrintToChat(client, "no use player dead");
		return;
	}
	
	// 변장하지 않았을 때의 처리
	if (!hns_bModelUserChanged[client])
	{
		HNS_T_PrintToChat(client, "did not select model yet");
		return;
	}
	
	new String:curmodelname[128]; 
	
	// 현재 클라이언트가 적용한 모델의 경로 추출
	GetClientModel(client, curmodelname, sizeof(curmodelname));
	
	// 본격적인 처리
	new cllangid = GetClientLanguageID(client, 1);
	
	for (new i = 1; i <= hns_iModelCount; i++)
	{
		new String:modelpath[128];
		
		new String:setdata[128];
		
		Format(setdata, sizeof(setdata), hns_sModelInfo[i][27]);
		
		// 모델 경로 로드 및 적용
		if (SplitString(setdata, "||", modelpath, sizeof(modelpath)) == -1)
			strcopy(modelpath, sizeof(modelpath), setdata);
		
		// 현재 모델 경로와 목록에 있는 경로가 같을때
		if (StrEqual(modelpath, curmodelname, false))
		{
			HNS_T_PrintToChat(client, "im this model", hns_sModelInfo[i][cllangid]);
			PrintToConsole(client, "==================== Model Info ====================");
			PrintToConsole(client, "식별 번호(ID): #%d\n이름(Name):", i);
			
			for (new k = 0; k < MAX_LANGUAGES; k++)
			{
				if (strlen(hns_sModelInfo[i][k]) > 0)
				{
					new String:langcode[4];
					
					GetLanguageInfo(k, langcode, sizeof(langcode));
					
					PrintToConsole(client, " [%s] %s", langcode, hns_sModelInfo[i][k]);
				}
			}
			PrintToConsole(client, "====================================================");
			
			break;
		}
	}
}

/**
 * 모델 모듈 :: 특정 메뉴의 언어 ID 데이터 존재 체크
 *
 * @param select			처리 번호
 *							(1 - 변장 모델)
 * @param langcode			언어 코드
 */
public CheckMenuLanguageID(select, const String:langcode[])
{
	for (new i = 0; i < MAX_LANGUAGES; i++)
	{
		// 변장 모델
		if (select == 1)
		{
			if (StrEqual(hns_sModelMenuLanguage[i], langcode, false))
				return i;
		}
	}
	return -1;
}

/**
 * 모델 모듈 :: 특정 메뉴의 언어 ID 빈자리 체크
 *
 * @param select			처리 번호
 *							(1 - 변장 모델)
 */
public GetMenuLanguageReadyID(select)
{
	for (new i = 0; i < MAX_LANGUAGES; i++)
	{
		// 변장 모델
		if (select == 1)
		{
			if (strlen(hns_sModelMenuLanguage[i]) == 0)
				return i;
		}
	}
	return -1;
}

/**
 * 모델 모듈 :: 클라이언트가 쓸 수 있는 특정 메뉴의 언어 ID 체크
 *
 * @param client			클라이언트 인덱스
 * @param select			처리 번호
 *							(1 - 변장 모델)
 * @param langcode			저장할 문자열 언어 코드
 * @param len				문자열 길이
 */
GetClientLanguageID(client, select, String:bflangcode[]="", len=0)
{
	new String:langcode[4], langid;
	
	GetLanguageInfo(GetClientLanguage(client), langcode, sizeof(langcode));
	
	langid = CheckMenuLanguageID(select, langcode);
	
	// 클라이언트의 언어가 데이터에 존재할때
	if (langid != -1)
	{
		strcopy(bflangcode, len, langcode);
		return langid;
	}
	else
	{
		GetLanguageInfo(GetServerLanguage(), langcode, sizeof(langcode));
		
		langid = CheckMenuLanguageID(select, langcode);
		
		// 서버의 기본 언어가 데이터에 존재할때
		if (langid != -1)
		{
			strcopy(bflangcode, len, langcode);
			return langid;
		}
		else
		{
			// ...그래도 없다면 영어 데이터의 언어 ID로!
			for (new i = 0; i < MAX_LANGUAGES; i++)
			{
				// 변장 모델
				if (select == 1)
				{
					if (StrEqual(hns_sModelMenuLanguage[i], "en", false))
					{
						strcopy(bflangcode, len, "en");
						return i;
					}
				}
			}
			
			// ...영어도 없으면.... 제일 첫 번째의 언어로 선정
			// 변장 모델
			if (select == 1)
			{
				if (strlen(hns_sModelMenuLanguage[0]) > 0)
				{
					strcopy(bflangcode, len, hns_sModelMenuLanguage[0]);
					return 0;
				}
			}
		}
	}
	return -1;
}

/**
 * 모델 모듈 :: 메세지 안에 쌍따옴표가 있는 지 체크
 *
 * @param msg				체크를 할 메세지
 */
bool:CheckDQMInMsg(String:msg[])
{
	if (StrContains(msg, '"') != -1)
		return true;
	
	return false;
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
	
	// 높이 조정 모델 관련 처리
	if ((hns_fFixedUserModelHeight[client] != 0.0) && IsPlayerAlive(client) && HNS_IsClientHider(client))
	{
		new Float:vec[3];
		
		vec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		vec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		vec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
		
		// 움직이고 있지 않을때
		if ((vec[0] == 0.0) && (vec[1] == 0.0) && (vec[2] == 0.0) && !((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT) || (buttons & IN_JUMP)))
		{
			hns_bIsUserMoving[client] = false;
			
			if (!hns_bFixedUserHigher[client] && (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1))
			{
				new Float:origin[3], Float:toporigin[3];
				
				GetClientAbsOrigin(client, origin);
				
				new Float:cleyeang[3];
				
				GetClientEyeAngles(client, cleyeang);
				
				cleyeang[0] = -89.0;
				
				new Handle:trace = TR_TraceRayFilterEx(origin, cleyeang, MASK_SOLID, RayType_Infinite, TraceEntityFilter, client);
				
				// toporigin[2] 는 맵의 실질 높이 위치값으로 나타난다. (GetClientAbsOrigin 과의 차이: +64)
				if (TR_DidHit(trace))
					TR_GetEndPosition(toporigin, trace);
				
				//PrintToChat(client, "TX: %f, TY: %f, TZ: %f", toporigin[0], toporigin[1], toporigin[2]);
				//PrintToChat(client, "X: %f, Y: %f, Z: %f", origin[0], origin[1], origin[2] + 64);
				
				new Float:result = origin[2] + 64 + hns_fFixedUserModelHeight[client];
				
				// 맵 밖으로 나가는 것을 방지하기 위한 조치
				if (toporigin[2] >= result)
				{
					origin[2] += hns_fFixedUserModelHeight[client];
					hns_bTopMaxHeight[client] = false;
				}
				else if (toporigin[2] < result)
				{
					hns_fTopMaxHeight[client] = toporigin[2] - 64 - 20 - origin[2];
					origin[2] = toporigin[2] - 64 - 20;
					hns_bTopMaxHeight[client] = true;
				}
				TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(client, MOVETYPE_NONE);
				
				hns_bFixedUserHigher[client] = true;
			}
		}
		else // 움직이고 있을때
		{
			hns_bIsUserMoving[client] = true;
			
			if (hns_bFixedUserHigher[client])
			{
				new Float:origin[3];
				
				GetClientAbsOrigin(client, origin);
				
				if (!hns_bTopMaxHeight[client])
					origin[2] -= hns_fFixedUserModelHeight[client];
				else
					origin[2] -= hns_fTopMaxHeight[client];
				
				TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(client, MOVETYPE_WALK);
				
				hns_bFixedUserHigher[client] = false;
			}
		}
	}
	
	return Plugin_Continue;
}

/**
 * 모델 모듈 :: 변장 모델 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_ShowModelMenu(client, args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 변장 모델 메뉴 출력
	if (HNS_IsClientHider(client))
	{
		if (IsPlayerAlive(client))
		{
			if (!HNS_IsGameToggle() || !HNS_TeamHasClients())
				ShowMainModel(client, 1);
			else
				HNS_T_PrintToChat(client, "can not change model");
		}
		else
		{
			HNS_T_PrintToChat(client, "no use player dead");
		}
	}
	else
	{
		HNS_T_PrintToChat(client, "only terrorists can use this");
	}
	
	return Plugin_Continue;
}

/**
 * 모델 모듈 :: 변장 모델 메뉴 다시 재생성
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_ReBuildModelMenu(client, args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	// 기존에 생성된 모델 관련 핸들 초기화
	OnMapEnd();
	
	// 기본 모델 메뉴 생성
	BuildMainModel();
	
	return Plugin_Continue;
}

/**
 * 모델 모듈 :: 변장 모델 목록 보기
 *
 * @param client			클라이언트 인덱스
 * @param args				기타 파라메터
 */
public Action:Command_ShowModelList(client, args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	new count, subcount;
	
	PrintToConsole(client, "============================= Model List =============================");
	
	for (new i = 1; i <= hns_iModelCount; i++)
	{
		new String:modelname[256];
		
		Format(modelname, sizeof(modelname), "Name:");
		
		for (new k = 0; k < MAX_LANGUAGES; k++)
		{
			if (strlen(hns_sModelInfo[i][k]) > 0)
			{
				new String:langcode[4];
				
				GetLanguageInfo(k, langcode, sizeof(langcode));
				
				Format(modelname, sizeof(modelname), "%s [%s] %s", modelname, langcode, hns_sModelInfo[i][k]);
				
				subcount++;
			}
		}
		
		if (subcount == 0)	continue;
		
		PrintToConsole(client, "ID: %d | %s", i, modelname);
		count++;
	}
	
	if (count == 0)
		PrintToConsole(client, "None!");
	
	PrintToConsole(client, "======================================================================");
	
	return Plugin_Continue;
}

/**
 * 채팅 :: 채팅 처리 함수
 *
 * @param client			클라이언트 인덱스
 * @param args				채팅 메세지
 */
public Action:Command_Say(client, args)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;

	// 서버 채팅은 통과
	if (client == 0)	return Plugin_Continue;

	// 메세지 받고 맨 끝 따옴표 제거
	new String:sMsg[256];

	GetCmdArgString(sMsg, sizeof(sMsg));
	sMsg[strlen(sMsg)-1] = '\x0';

	// 파라메터 추출 후 분리
	new String:sMainCmd[32], String:sParamStr[4][64], sParamIdx;

	sParamIdx = SplitString(sMsg[1], " ", sMainCmd, sizeof(sMainCmd));
	ExplodeString(sMsg[1 + sParamIdx], " ", sParamStr, sizeof(sParamStr), sizeof(sParamStr[]));
	if (sParamIdx == -1)
	{
		strcopy(sMainCmd, sizeof(sMainCmd), sMsg[1]);
		strcopy(sParamStr[0], 64, sMsg[1]);
	}
	/*
	new String:msg[256], String:name[256], String:buffer[256], String:checkcmd[64], bool:checkparam, String:explodestr[2][256];
	
	GetCmdArgString(msg, sizeof(msg));
	
	msg[strlen(msg)-1] = '\x0';
	
	if (SplitString(msg[1], " ", checkcmd, sizeof(checkcmd)) == -1)
		strcopy(checkcmd, sizeof(checkcmd), msg[1]);
	else
		checkparam = true;
	
	if (checkparam)
		ExplodeString(msg[1], " ", explodestr, 2, 256, true);
	
	GetClientName(client, name, sizeof(name));*/

	// 클라이언트 닉네임 추출
	new String:sUsrName[32];
	GetClientName(client, sUsrName, sizeof(sUsrName));

	// 필요 변수
	new String:buffer[256];
	
	// 변장 메뉴
	if (StrEqual(sMainCmd[1], "hide", false) || StrEqual(sMainCmd[1], "변장", false))
	{
		// 느낌표인 경우에 채팅 표시
		if (sMainCmd[0] == '!')
		{
			Format(buffer, sizeof(buffer), "\x03%s \x01:  %s", sUsrName, sMsg[1]);
			SayText2All(client, buffer);
			PrintToServer(buffer);
		}

		// 클라이언트가 대테러인 경우는 차단
		if (!HNS_IsClientHider(client))
		{
			HNS_T_PrintToChat(client, "only terrorists can use this");

			return Plugin_Handled;
		}

		// 클라이언트가 죽었다면 차단
		if (!IsPlayerAlive(client))
		{
			HNS_T_PrintToChat(client, "no use player dead");

			return Plugin_Handled;
		}

		// 파라메터가 없을 경우
		if (StrEqual(sParamStr[0], "", false))
		{
			if (!HNS_IsGameToggle() || !HNS_TeamHasClients())
				ShowMainModel(client, 1);
			else
				HNS_T_PrintToChat(client, "can not change model");
			
			return Plugin_Handled;
		}

		// 쌍따옴표가 없을 경우
		if (!CheckDQMInMsg(sParamStr[0]))
		{
			HNS_T_PrintToChat(client, "set parameter dqm plz");

			return Plugin_Handled;
		}
		
		if (!HNS_IsGameToggle() || !HNS_TeamHasClients() || (GetConVarFloat(hns_eConvar[HIDETIME]) < GetGameTime()))
			SetMainModel(client, 2, sParamStr[0]);
		else
			HNS_T_PrintToChat(client, "can not change model");

		return Plugin_Handled;
	}

	// 여긴 어디 나는 누구
	if (StrEqual(sMainCmd[1], "whoami", false) || StrEqual(sMainCmd[1], "난누구", false))
	{
		if (sMainCmd[0] == '!')
		{
			Format(buffer, sizeof(buffer), "\x03%s \x01:  %s", sUsrName, sMsg[1]);
			SayText2All(client, buffer);
			PrintToServer(buffer);
		}

		Command_MyModel(client);
		
		return Plugin_Handled;
	}
	
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
	
	// 변장 메뉴 생성
	if (GetConVarInt(hns_eConvar[HDATABASESET]) == 2)
		BuildMainModel();
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

/**
 * SQL :: 변장 메뉴 생성
 *
 * @param owner				알 수 없음
 * @param hndl				데이터베이스 핸들
 * @param error				에러 메세지
 * @param data				기타 파라메터
 */
public SQL_BuildMainMenu(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ((hndl == INVALID_HANDLE) || (error[0]))
	{
		PrintToServer("%s Failed to retrieve Model Infos from the database: %s.", HNS_PHRASE_PREFIX, error);
		return;
	}
	
	// 반복하면서 각 하위 데이터에 대해서 처리
	new langid, langreadyid = -1;
	
	while (SQL_MoreRows(hndl))
	{
		if (!SQL_FetchRow(hndl))
			continue;
		
		hns_iModelCount++;
		
		decl String:finalresult[128];
		
		decl String:info1[256], String:info2[64], String:info3[64], String:info4[512];
		decl String:modelpath[128], String:heightfix[16], String:usemoney[16], String:langnamedata[512];
		
		// 정보 로드
		SQL_FetchString(hndl, 1, info1, 256);
		SQL_FetchString(hndl, 2, info2, 64);
		SQL_FetchString(hndl, 3, info3, 64);
		SQL_FetchString(hndl, 4, info4, 512);
		
		// 복호화
		DecodeBase64(modelpath, 128, info1);
		DecodeBase64(heightfix, 16, info2);
		DecodeBase64(usemoney, 16, info3);
		DecodeBase64(langnamedata, 512, info4);
		
		// 파일에 있는 모델 경로를 완전한 경로로 변경 후 프리캐시를 한 다음 결과값에 저장
		Format(finalresult, sizeof(finalresult), "models/%s.mdl", modelpath);
		PrecacheModel(finalresult, true);
		
		// 모델 높이를 결과값에 저장
		if (!StrEqual(heightfix, "no", false))
			Format(finalresult, sizeof(finalresult), "%s||hf_%s", finalresult, heightfix);
		
		// 금전을 결과값에 저장
		if (!StrEqual(usemoney, "no", false))
			Format(finalresult, sizeof(finalresult), "%s||um_%s", finalresult, usemoney);
		
		// 각 언어별 메뉴 생성
		for (new i = 0; i < GetLanguageCount(); i++)
		{
			decl String:langcode[4], String:modelname[128], String:tempbuffer[512];
			new charpos = -1;
			
			// 언어 코드 로드
			GetLanguageInfo(i, langcode, sizeof(langcode));
			
			// 언어 코드에 따른 모델 이름 로드
			Format(tempbuffer, sizeof(tempbuffer), "[[%s]]", langcode);
			if ((charpos = StrContains(langnamedata, tempbuffer)) != -1)
			{
				if (SplitString(langnamedata[charpos+6], "[[", modelname, sizeof(modelname)) == -1)
					strcopy(modelname, sizeof(modelname), langnamedata[charpos+6]);
			}
			
			// 메뉴 생성
			if (strlen(modelname) > 0)
			{
				// 금액이 붙은 모델은 모델 이름을 살짝 변경
				if (!StrEqual(usemoney, "no", false))
					Format(modelname, sizeof(modelname), "%s ($%d)", modelname, StringToInt(usemoney));
				
				// 해당 언어가 변장 모델 메뉴의 언어 ID에 데이터가 존재하는지 체크
				langid = CheckMenuLanguageID(1, langcode);
				
				// 그 데이터가 없을때 처리
				if (langid == -1)
				{
					langreadyid = GetMenuLanguageReadyID(1);
					hns_sModelMenuLanguage[langreadyid] = langcode;
				}
				
				if ((langid == -1) && (hns_hModelMenu[langreadyid] == INVALID_HANDLE))
				{
					hns_hModelMenu[langreadyid] = CreateMenu(Menu_MainModelS);
					
					//PrintToServer("%s ---------------- SET MENU ID : %d", HNS_PHRASE_PREFIX, langreadyid);
					
					decl String:buffer[512];
					
					Format(buffer, sizeof(buffer), "%t\n ", "select model title");
					SetMenuTitle(hns_hModelMenu[langreadyid], buffer);
					SetMenuExitButton(hns_hModelMenu[langreadyid], true);
					SetMenuExitBackButton(hns_hModelMenu[langreadyid], true);
				}
				
				// 메뉴 항목 생성
				if (langid == -1)
				{
					Format(hns_sModelInfo[hns_iModelCount][langreadyid], 128, modelname);
					AddMenuItem(hns_hModelMenu[langreadyid], finalresult, modelname);
				}
				else
				{
					Format(hns_sModelInfo[hns_iModelCount][langid], 128, modelname);
					AddMenuItem(hns_hModelMenu[langid], finalresult, modelname);
				}
			}
		}
		Format(hns_sModelInfo[hns_iModelCount][27], 128, finalresult);
	}
	
	hns_bIsModelMenuCreated = true;
}

/**
 * 게임 이벤트 :: 라운드 프리즈 엔드 이벤트
 *
 * @param event				이벤트 핸들
 * @param name				이벤트 이름
 * @param dontBroadcast		이벤트 전달 유/무
 */
public Action:Event_OnRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!HNS_IsEngineWork())	return Plugin_Continue;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!HNS_IsClientHider(i))	continue;
		if (!IsPlayerAlive(i))	continue;
		if (IsFakeClient(i))	continue;
		
		// 모델 메뉴 출력
		// 플레이어 스폰에다가 하지 말 것... -ㅅ-;;.....
		ShowMainModel(i, 1);
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
	
	// 숨는 사람의 경우
	if (HNS_IsClientHider(client))
	{
		if (IsPlayerAlive(client))
		{
			// 높이 조정 초기화
			hns_fFixedUserModelHeight[client] = 0.0;
			HNS_SetClientModelHeight(client, 0.0);
			hns_bFixedUserHigher[client] = false;
			
			// 모델 변경 여부 초기화
			hns_bModelUserChanged[client] = false;
		}
	}
	
	return Plugin_Continue;
}

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
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// 숨는 사람의 경우
	if (HNS_IsClientHider(client))
	{
		// 높이 조정 초기화
		if ((hns_fFixedUserModelHeight[client] != 0.0) && hns_bFixedUserHigher[client])
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			hns_bFixedUserHigher[client] = false;
		}
		hns_fFixedUserModelHeight[client] = 0.0;
		HNS_SetClientModelHeight(client, 0.0);
		hns_bFixedUserHigher[client] = false;
		
		// 모델 변경 여부 초기화
		hns_bModelUserChanged[client] = false;
	}
	
	return Plugin_Continue;
}

/**
 * 모델 모듈 :: 기본 변장 메뉴 처리 함수
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client			클라이언트 인덱스
 * @param select			메뉴 선택 값
 */
public Menu_MainModelS(Handle:menu, MenuAction:action, client, select)
{
	if ((client > 0) && HNS_IsClientHider(client))
	{
		if (action == MenuAction_Select)
		{
			if (!IsPlayerAlive(client))
			{
				HNS_T_PrintToChat(client, "no use player dead");
				return;
			}
			
			if (HNS_IsGameToggle())
			{
				HNS_T_PrintToChat(client, "can not change model");
				return;
			}
			
			new String:info[256], String:info2[128], String:modelpath[128];
			
			GetMenuItem(menu, select, info, sizeof(info), _, info2, sizeof(info2));
			
			//PrintToChatAll("[Client: %d] 로드 완료(전체 데이터): %s", client, info);
			
			new charpos1;
			
			// ROOT 어드민인지 체크하고 돈 적용 유/무 처리
			if (!HNS_IsClientAdmin(client, Admin_Root))
			{
				// 금액 로드 후 알아서 계산
				if ((charpos1 = StrContains(info, "||um_", false)) != -1)
				{
					new String:smodelmoney[16];
					new clientmoney = HNS_GetClientMoney(client);
					
					new charpos2 = StrContains(info[charpos1+5], "||hf_", false);
					
					if (charpos2 != -1)
						strcopy(smodelmoney, charpos2-charpos1+4, info[charpos1+5]);
					else
						strcopy(smodelmoney, sizeof(smodelmoney), info[charpos1+5]);
					
					new imodelmoney = StringToInt(smodelmoney);
					
					// 돈이 부족할 경우
					if (clientmoney < imodelmoney)
					{
						HNS_T_PrintToChat(client, "usemoney your money no");
						ShowMainModel(client, 1);
						return;
					}
					
					HNS_SetClientMoney(client, (clientmoney - imodelmoney));
					
					HNS_T_PrintToChat(client, "usemoney accept", imodelmoney);
				}
			}
			
			// 높이 초기화
			if (!hns_bIsUserMoving[client])
			{
				new Float:origin[3];
				
				GetClientAbsOrigin(client, origin);
				
				if (!hns_bTopMaxHeight[client])
					origin[2] -= hns_fFixedUserModelHeight[client];
				else
					origin[2] -= hns_fTopMaxHeight[client];
				
				TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
			}
			hns_bFixedUserHigher[client] = false;
			
			// 화면 고정 해제 및 움직임 정상 처리
			HNS_SetClientFreezed(client, false);
			
			// 높이 조정 값 로드
			if((charpos1 = StrContains(info, "||hf_")) != -1)
			{
				hns_fFixedUserModelHeight[client] = StringToFloat(info[charpos1+5]);
				HNS_SetClientModelHeight(client, StringToFloat(info[charpos1+5]));
				HNS_T_PrintToChat(client, "heightfix fixed");
			}
			else
			{
				hns_fFixedUserModelHeight[client] = 0.0;
				HNS_SetClientModelHeight(client, 0.0);
				hns_fTopMaxHeight[client] = 0.0;
			}
			
			// 모델 경로 로드 및 적용
			if (SplitString(info, "||", modelpath, sizeof(modelpath)) == -1)
				strcopy(modelpath, sizeof(modelpath), info);
			
			SetEntityModel(client, modelpath);
			HNS_T_PrintToChat(client, "im this model", info2);
			
			hns_bModelUserChanged[client] = true;
			
		}
		else if (action == MenuAction_End)
		{
			CloseHandle(menu);
		}
	}
}

/**
 * 트레이스 필터 :: 플레이어 구분
 *
 * @param entity			엔티티 인덱스
 * @param mask				알 수 없음
 * @param data				기타 파라메터
 */
public bool:TraceEntityFilter(entity, mask, any:data)
{
	if (entity != data)
	{
		return true;
	}
	
	return false;
}