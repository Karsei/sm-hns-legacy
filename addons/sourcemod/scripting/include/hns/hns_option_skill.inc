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
 * Ŭ���̾�Ʈ�� ��ų�� �������ΰ���?
 *
 * @param client		Ŭ���̾�Ʈ �ε���
 */
native bool:HNS_IsClientSkillUser(client);

/**
 * Ŭ���̾�Ʈ�� ���� ���� ��ų�� ȹ���մϴ�.
 *
 * @param client		Ŭ���̾�Ʈ �ε���
 */
native HNS_GetClientSkill(client);

/**
 * Ŭ���̾�Ʈ�� ��ų�� �����մϴ�.
 *
 * @param client		Ŭ���̾�Ʈ �ε���
 * @param type			���� �ε��� (�ش� ���� ��� ��� ����)
 */
native HNS_SetClientSkill(client, type);

/**
 * Ŭ���̾�Ʈ ��ų ���� �� ȣ���մϴ�.
 *
 * @param client		Ŭ���̾�Ʈ �ε���
 * @param type			���� �ε��� (�ش� ���� ��� ��� ����)
 */
forward HNS_OnSetClientSkill(client, type);