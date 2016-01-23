/*==================================================================
	
	----------------------------------------------
	-*- [Hide and Seek] API :: Option :: Skill -*-
	----------------------------------------------
	
	Filename: hns_option_skill.inc
	Author: Karsei
	Description: API
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012 by Karsei All Right Reserved
	
==================================================================*/

#define HNS_SKILL_NONE 0
#define HNS_SKILL_PROPDELETE 1
#define HNS_SKILL_WAVERADAR 2

/**
 * 클라이언트가 스킬을 보유중인가요?
 *
 * @param client		클라이언트 인덱스
 */
native bool:HNS_IsClientSkillUser(client);

/**
 * 클라이언트가 보유 중인 스킬을 획득합니다.
 *
 * @param client		클라이언트 인덱스
 */
native HNS_GetClientSkill(client);

/**
 * 클라이언트의 스킬을 지정합니다.
 *
 * @param client		클라이언트 인덱스
 * @param type			종류 인덱스 (해당 파일 상단 상수 참조)
 */
native HNS_SetClientSkill(client, type);

/**
 * 클라이언트 스킬 선택 후 호출합니다.
 *
 * @param client		클라이언트 인덱스
 * @param type			종류 인덱스 (해당 파일 상단 상수 참조)
 */
forward HNS_OnSetClientSkill(client, type);
