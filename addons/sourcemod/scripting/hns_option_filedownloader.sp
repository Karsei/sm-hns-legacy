/*==================================================================
	
	-------------------------------------------------
	-*- [Hide and Seek] Option :: File Downloader -*-
	-------------------------------------------------
	
	Filename: hns_option_filedownloader.sp
	Author: Karsei
	Description: This controls the specific download list file to
				 download several files for HNS Server.
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012-2015 by Karsei All Right Reserved
	
==================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hns>

/*******************************************************
 E N U M S
*******************************************************/
enum CVAR
{
	Handle:HDOWNLOADERSWITCH,
	Handle:HDOWNLOADERDBGSWITCH
}

/*******************************************************
 V A R I A B L E S
*******************************************************/
new hns_eConvar[CVAR];

/*******************************************************
 P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = "[Hide and Seek] Option :: File Downloader",
	author = HNS_CREATOR,
	description = "This controls the specific download list file to download several files for HNS Server.",
	version = HNS_VERSION,
	url = HNS_CREATOR_URL
};

/*******************************************************
 F O R W A R D   F U N C T I O N S
*******************************************************/
public OnPluginStart()
{
	hns_eConvar[HDOWNLOADERSWITCH] = CreateConVar("hns_filedownloader_switch", "1", "File Downloader On?");
	hns_eConvar[HDOWNLOADERDBGSWITCH] = CreateConVar("hns_filedownloader_dbg_switch", "0", "File Downloader Debug On?");
	
	PrintToServer("%s (Option) 'File Downloader' has been loaded successfully.", HNS_PHRASE_PREFIX);
}

/**
 * 플러그인의 모든 설정을 로드하고 난 이후의 처리
 */
public OnConfigsExecuted()
{
	if (!HNS_IsEngineWork())	return;
	
	// 파일 다운로더 시작
	DoReadFile();
}

/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 파일 다운로더 모듈 :: 파일을 읽어 각 라인을 판단한 후 파일 경로를 다른 함수에 넘깁니다.
 */
public DoReadFile()
{
	if (GetConVarBool(hns_eConvar[HDOWNLOADERSWITCH]))
	{
		new Handle:filehandle = INVALID_HANDLE;
		
		filehandle = OpenFile("./addons/sourcemod/configs/hns_downloader.ini", "r");
		if (filehandle == INVALID_HANDLE)
		{
			PrintToServer("%s 'configs/hns_downloader.ini' is not loadable.", HNS_PHRASE_PREFIX);
			return;
		}
		else
		{
			new String:line[512];
			
			while (ReadFileLine(filehandle, line, sizeof(line)))
			{
				TrimString(line);
				
				if ((StrContains(line, ";") == -1) && (strlen(line) > 0))
					SetFileToDownloadTable(line);
			}
		}
	}
}

/**
 * 파일 다운로더 모듈 :: 파일 경로를 다운로드 테이블에 등록합니다.
 *
 * @param dir				파일 경로
 */
public SetFileToDownloadTable(const String:dir[])
{
	new Handle:curdir = OpenDirectory(dir);
	new String:filename[32], String:setdir[128], FileType:type;
	
	if (curdir != INVALID_HANDLE)
	{
		while (ReadDirEntry(curdir, filename, sizeof(filename), type))
		{
			if (type == FileType_Directory)
			{
				if (FindCharInString(filename, '.', false) == -1)
				{
					if (GetConVarBool(hns_eConvar[HDOWNLOADERDBGSWITCH]))
						PrintToServer("%s -DEBUG- Adding this File to Download Tables (%s)...", HNS_PHRASE_PREFIX, filename);
					
					Format(setdir, sizeof(setdir), "%s/%s", dir, filename);
					AddFileToDownloadsTable(setdir);
				}
			}
			else if (type == FileType_File)
			{
				if (GetConVarBool(hns_eConvar[HDOWNLOADERDBGSWITCH]))
					PrintToServer("%s -DEBUG- Adding this File to Download Tables (%s)...", HNS_PHRASE_PREFIX, filename);
				
				Format(setdir, sizeof(setdir), "%s/%s", dir, filename);
				AddFileToDownloadsTable(setdir);
			}
		}
	}
	else
	{
		PrintToServer("%s Adding to Download table is Failed: %s", HNS_PHRASE_PREFIX, dir);
	}
}