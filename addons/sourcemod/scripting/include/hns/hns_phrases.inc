/*==================================================================
	
	-----------------------------------------------------
	-*- [Hide and Seek] API :: Translation and Phrase -*-
	-----------------------------------------------------
	
	Filename: hns_phrases.inc
	Author: Karsei
	Description: API
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012 by Karsei All Right Reserved.
	
==================================================================*/

/**
 * @section 다른 메시지 형식의 최대 길이.
 */
#define HNS_MAX_LENGTH_CHAT 192
#define HNS_MAX_LENGTH_CONSOLE 1024
/**
 * @endsection
 */

/**
 * 플러그인으로부터 출력되는 모든 메시지의 접두사. (아직 사용 안함)
 */
#define HNS_PHRASE_PREFIX "[HNS]"

/**
 * @section 문자 색깔 구분 기호.
 */
#define HNS_TEXT_COLOR_DEFAULT "\x01"
#define HNS_TEXT_COLOR_LGREEN "\x03"
#define HNS_TEXT_COLOR_GREEN "\x04"
#define HNS_TEXT_COLOR_OLIVE "\x05"
/**
 * @endsection
 */


/**
 * CS 1.6 스타일의 HUD로 메시지를 출력.
 *
 * @param client		클라이언트 인덱스, 0으로 설정하는경우 전체에게 표시됩니다.
 * @param channel		HUD가 표시될 채널을 지정합니다. (숫자)
 * @param x				내용이 표시될 좌표 x (-1은 중앙입니다.)
 * @param y				내용이 표시될 좌표 y (-1은 중앙입니다.)
 * @param firstcolor	첫번째 색 (r, g, b, a)
 * @param g1			두번째 색 (r, g, b, a)
 * @param effect		메시지를 출력할 때의 효과를 지정합니다.
							0: 페이드인/페이드아웃.
							1: 깜빡거리는 효과.
							2: 파워포인트의 '컬러타자기' 애니메이션 같은 타자효과.
 * @param fadein		서서히 나타날 때의 시간 (소숫점 가능).
 * @param fadeout		서서히 사라질 때의 시간 (소숫점 가능).
 * @param holdtime		고정될 시간 (소숫점 가능).
 * @param fxtime		효과가 출력될 시간 (소숫점 가능).
 * @param txt			출력할 메시지를 입력합니다.
 *
 * 예시: ZP_HudMsg(client, 6, 0.04, 0.82, 1stcolor, 2ndcolor, 1, 0.1, 1000.0, 10.0, 4.0, totalhud);
 */
stock HNS_HudMsg(client, 
				channel, 
				Float:x, Float:y, 
				const firstcolor[4], const secondcolor[4], 
				effect, Float:fadein, Float:fadeout, Float:holdtime, Float:fxtime, 
				const String:msg[], any:...)
{	
	new Handle:hudhandle = INVALID_HANDLE;
	
	if (client == 0) hudhandle = StartMessageAll("HudMsg");	
	else hudhandle = StartMessageOne("HudMsg", client);
	
	new String:txt[255];
	VFormat(txt, sizeof(txt), msg, 13);
	
	if (hudhandle != INVALID_HANDLE)
	{
		BfWriteByte(hudhandle, channel);
		BfWriteFloat(hudhandle, x);
		BfWriteFloat(hudhandle, y);
		
		// 두번째 색깔
		BfWriteByte(hudhandle, firstcolor[0]);
		BfWriteByte(hudhandle, firstcolor[1]);
		BfWriteByte(hudhandle, firstcolor[2]);
		BfWriteByte(hudhandle, firstcolor[3]);
		
		// 초기 색깔
		BfWriteByte(hudhandle, secondcolor[0]);
		BfWriteByte(hudhandle, secondcolor[1]);
		BfWriteByte(hudhandle, secondcolor[2]);
		BfWriteByte(hudhandle, secondcolor[3]);
		BfWriteByte(hudhandle, effect);
		BfWriteFloat(hudhandle, fadein);
		BfWriteFloat(hudhandle, fadeout);
		BfWriteFloat(hudhandle, holdtime);
		BfWriteFloat(hudhandle, fxtime);
		BfWriteString(hudhandle, txt);
		EndMessage();
	}	
}

/**
 * 키힌트 HUD를 이용한 메시지를 출력합니다.
 *
 * @param client	클라이언트 인덱스 (0을 입력할 경우 전체에게 표시합니다.)
 * @param msg		표시할 내용을 입력하세요.
 */
stock HNS_KeyHintText(client, String:msg[], any:...)
{
	new Handle:hudhandle = INVALID_HANDLE;
	
	if (client == 0) hudhandle = StartMessageAll("KeyHintText");	
	else hudhandle = StartMessageOne("KeyHintText", client);	
	
	new String:txt[255];
	VFormat(txt, sizeof(txt), msg, 3);	
	
	if (hudhandle != INVALID_HANDLE)
	{
		BfWriteByte(hudhandle, 1);
		BfWriteString(hudhandle, txt);
		EndMessage();
	}
}

/**
 * Top-Left 메시지를 클라이언트에게 출력합니다.
 *
 * @param client		클라이언트 인덱스
 * @param color			표시할 문자의 색 (r, g, b)
 * @param text			출력할 내용
 */
stock HNS_Dialog(client, const color[3], String:text[], any:...)
{
	new String:message[100];
	VFormat(message, sizeof(message), text, 4);	
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", color[0], color[1], color[2], 255);
	KvSetNum(kv, "level", 1);
	KvSetNum(kv, "time", 5);
	
	CreateDialog(client, kv, DialogType_Msg);
	
	CloseHandle(kv);
}

/**
 * plugin.hide_and_seek.txt 내에 구문들을 번역합니다.
 * 
 * @param client        The client index
 * @param translation   The translated text.
 * @param maxlen        Maximum length of the translated string.
 * @param ...           Translation formatting parameters.  
 */
stock HNS_TranslatePhrase(client, String:translation[], maxlen, any:...)
{
	// Set translation target to given target.
	SetGlobalTransTarget(client);

	// Dump translation into return string.
	VFormat(translation, maxlen, "%t", 3);
}

/**
 * Format the string to the plugin's style.
 * 
 * @param text      Text to format.
 * @param maxlen    Maximum length of the formatted text.
 */
stock HNS_PluginFormatString(String:text[], maxlen, bool:color = true)
{
	if (color)
	{
		// Format prefix onto the string.
		Format(text, maxlen, "@olive%s @lightgreen%s", HNS_PHRASE_PREFIX, text);
		
		// Replace color tokens with CS:S color chars.
		ReplaceString(text, maxlen, "@default", HNS_TEXT_COLOR_DEFAULT);
		ReplaceString(text, maxlen, "@lightgreen", HNS_TEXT_COLOR_LGREEN);
		ReplaceString(text, maxlen, "@green", HNS_TEXT_COLOR_GREEN);
		ReplaceString(text, maxlen, "@olive", HNS_TEXT_COLOR_OLIVE);
		
		return;
	}

	// Format prefix onto the string.
	Format(text, maxlen, "%s %s", HNS_PHRASE_PREFIX, text);
}

/**
 * Print chat text to client. (with style)
 * 
 * @param client    The client index.
 * @param ...       Translation formatting parameters.  
 */
stock HNS_T_PrintToChat(client, any:...)
{
	// Set translation target
	SetGlobalTransTarget(client);
	
	// Translate phrase.
	decl String:translation[HNS_MAX_LENGTH_CHAT];
	VFormat(translation, sizeof(translation), "%t", 2);
	
	// Format string to create plugin style.
	HNS_PluginFormatString(translation, sizeof(translation));
	
	// Print translated phrase to client.
	PrintToChat(client, translation);
}

/**
 * Format the string to the plugin's style.
 * 
 * @param server    True to also print text to server console, false just to clients.
 * @param admin     True to only print text to admins, false to print to everyone.
 * @param ...       Translation formatting parameters.
 */
stock HNS_T_PrintToChatAll(bool:server, bool:admin, any:...)
{
	decl String:translation[HNS_MAX_LENGTH_CHAT];
	
	if (server)
	{
		// Set translation target
		SetGlobalTransTarget(LANG_SERVER);
		
		// Translate phrase.
		VFormat(translation, sizeof(translation), "%t", 3);
		
		// Format string to create plugin style.
		HNS_PluginFormatString(translation, sizeof(translation), false);
		
		// Print phrase to server.
		PrintToServer(translation);
	}

	// x = client index.
	for (new x = 1; x <= MaxClients; x++)
	{
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client isn't an admin, and we're only printing to admins, then stop.
		if (admin && !HNS_IsClientAdmin(x))
		{
			continue;
		}
		
		// Set translation target to client.
		SetGlobalTransTarget(x);
		
		// Translate phrase.
		VFormat(translation, sizeof(translation), "%t", 3);
		
		// Format string to create plugin style.
		HNS_PluginFormatString(translation, sizeof(translation));
		
		// Print translated phrase to client.
		PrintToChat(x, translation);
	}
}

/**
 * Print console text to client. (with style)
 * 
 * @param client    The client index.
 * @param ...       Translation formatting parameters.  
 */
stock HNS_T_PrintToConsole(client, any:...)
{
	// Set translation target
	SetGlobalTransTarget(client);

	// Translate phrase.
	decl String:translation[HNS_MAX_LENGTH_CONSOLE];
	VFormat(translation, sizeof(translation), "%t", 2);

	// Format string to create plugin style.
	HNS_PluginFormatString(translation, sizeof(translation), false);

	// Print translated phrase to client.
	PrintToConsole(client, translation);
}

/**
 * Format the string to the plugin's style.
 * 
 * @param server    True to also print text to server console, false just to clients.
 * @param ...       Translation formatting parameters.
 */
stock HNS_T_PrintToConsoleAll(bool:server, bool:admin, any:...)
{
	decl String:translation[HNS_MAX_LENGTH_CONSOLE];

	if (server)
	{
		// Set translation target
		SetGlobalTransTarget(LANG_SERVER);
		
		// Translate phrase.
		VFormat(translation, sizeof(translation), "%t", 3);
		
		// Format string to create plugin style.
		HNS_PluginFormatString(translation, sizeof(translation), false);
		
		// Print phrase to server.
		PrintToServer(translation);
	}

	// x = client index.
	for (new x = 1; x <= MaxClients; x++)
	{
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client isn't an admin, and we're only printing to admins, then stop.
		if (admin && !HNS_IsClientAdmin(x))
		{
			continue;
		}
		
		// Set translation target
		SetGlobalTransTarget(LANG_SERVER);
		
		// Translate phrase.
		VFormat(translation, sizeof(translation), "%t", 3);
		
		// Format string to create plugin style.
		HNS_PluginFormatString(translation, sizeof(translation), false);
		
		// Print translated phrase to client.
		PrintToConsole(x, translation);
	}
}

/**
 * Print center text to client. (with style)
 * 
 * @param client    The client index.
 * @param ...       Translation formatting parameters.  
 */
stock HNS_T_PrintCenterText(client, any:...)
{
	// Set translation target
	SetGlobalTransTarget(client);

	// Translate phrase.
	decl String:translation[HNS_MAX_LENGTH_CHAT];
	VFormat(translation, sizeof(translation), "%t", 2);

	// Print translated phrase to client.
	PrintCenterText(client, translation);
}

/**
 * Print center text to all clients. (with style)
 * 
 * @param client    The client index.
 * @param ...       Translation formatting parameters.  
 */
stock HNS_T_PrintCenterTextAll(bool:admin, any:...)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		// Skip clients not in game.
		if (!IsClientInGame(client))
		{
			continue;
		}

		// Skip clients who haven't selected a team yet (team menu open).
		if (GetClientTeam(client) == CS_TEAM_NONE)
		{
			continue;
		}

		// Skip non-admins if only printing to admins.
		if (admin && !HNS_IsClientAdmin(client))
		{
			continue;
		}

		// Set translation target
		SetGlobalTransTarget(client);

		// Translate phrase.
		decl String:translation[HNS_MAX_LENGTH_CHAT];
		VFormat(translation, sizeof(translation), "%t", 2);

		// Print translated phrase to client.
		PrintCenterText(client, translation);
	}
}

/**
 * CS:S 스타일의 HUD 메시지를 클라이언트에게 전송합니다.
 * 
 * @param client    클라이언트 인덱스
 * @param ...       Translation formatting parameters.  
 */
stock HNS_T_PrintHintText(client, any:...)
{
	// 번역 대상 지정 (Set translation target)
	SetGlobalTransTarget(client);

	// 문구 번역.
	decl String:translation[HNS_MAX_LENGTH_CHAT];
	VFormat(translation, sizeof(translation), "%t", 2);

	// Print translated phrase to client.
	PrintHintText(client, translation);
}

/**
 * 키힌트텍스트를 클라이언트에게 전송합니다.
 *
 * @param client		클라이언트 인덱스
 * @param ...			기타 변수 등등
 */
stock HNS_T_PrintKeyHintText(client, any:...)
{
	// 번역 대상 지정 (Set translation target)
	SetGlobalTransTarget(client);

	// Translate phrase.
	decl String:translation[HNS_MAX_LENGTH_CHAT];
	VFormat(translation, sizeof(translation), "%t", 2);
	
	// 클라이언트에게 번역된 문구를 출력.
	HNS_KeyHintText(client, translation);
}

stock HNS_T_PrintHudText(client, 
						disp_channel, 
						Float:pos_x, Float:pos_y, 
						const initcolor[4], 
						const finalcolor[4], 
						Float:text_fadein, Float:text_fadeout, 
						Float:holdingtime, 
						Float:effecttime, 
						any:...)
{
	// Set translation target
	SetGlobalTransTarget(client);

	// Translate phrase.
	decl String:translation[HNS_MAX_LENGTH_CHAT];
	VFormat(translation, sizeof(translation), "%t", 8);
	
	// Print translated phrase to client.
	HNS_HudMsg(client,
				disp_channel,
				pos_x, pos_y, 
				finalcolor[0], finalcolor[1], finalcolor[2], finalcolor[3], 
				initcolor[0], initcolor[1], initcolor[2], initcolor[3], 
				text_fadein, text_fadeout,
				holdingtime, effecttime, translation);
}


/**
 * Print text to server. (with style)
 * 
 * @param ...       Translation formatting parameters.  
 */
stock HNS_T_PrintToServer(any:...)
{
	// Set translation target
	SetGlobalTransTarget(LANG_SERVER);

	// Translate phrase.
	decl String:translation[HNS_MAX_LENGTH_CONSOLE];
	VFormat(translation, sizeof(translation), "%t", 1);

	// Format string to create plugin style.
	HNS_PluginFormatString(translation, sizeof(translation), false);

	// Print translated phrase to client.
	PrintToServer(translation);
}

/**
 * Print chat text to client. (with style)
 * 
 * @param client    The client index.
 * @param ...       Translation formatting parameters.  
 */
stock HNS_T_ReplyToCommand(client, any:...)
{
	// Set translation target
	SetGlobalTransTarget(client);

	// Translate phrase.
	decl String:translation[HNS_MAX_LENGTH_CONSOLE];
	VFormat(translation, sizeof(translation), "%t", 2);

	if (HNS_IsClientValid(client))
	{
		// Format string to create plugin style. (color)
		HNS_PluginFormatString(translation, sizeof(translation));
	}
	else
	{
		// Format string to create plugin style. (no color)
		HNS_PluginFormatString(translation, sizeof(translation), false);
	}

	// Print translated phrase to server or client's chat/console.
	ReplyToCommand(client, translation);
}

/**
 * Replies to a client with a given message describing a targetting 
 * failure reason. (formatted for HNS)
 *
 * Note: The translation phrases are found in common.phrases.txt.
 *
 * @param client		Client index, or 0 for server.
 * @param reason		COMMAND_TARGET reason.
 */
stock HNS_ReplyToTargetError(client, reason)
{
	switch (reason)
	{
		case COMMAND_TARGET_NONE:
		{
			HNS_T_ReplyToCommand(client, "No matching client");
		}
		case COMMAND_TARGET_NOT_ALIVE:
		{
			HNS_T_ReplyToCommand(client, "Target must be alive");
		}
		case COMMAND_TARGET_NOT_DEAD:
		{
			HNS_T_ReplyToCommand(client, "Target must be dead");
		}
		case COMMAND_TARGET_NOT_IN_GAME:
		{
			HNS_T_ReplyToCommand(client, "Target is not in game");
		}
		case COMMAND_TARGET_IMMUNE:
		{
			HNS_T_ReplyToCommand(client, "Unable to target");
		}
		case COMMAND_TARGET_EMPTY_FILTER:
		{
			HNS_T_ReplyToCommand(client, "No matching clients");
		}
		case COMMAND_TARGET_NOT_HUMAN:
		{
			HNS_T_ReplyToCommand(client, "Cannot target bot");
		}
		case COMMAND_TARGET_AMBIGUOUS:
		{
			HNS_T_ReplyToCommand(client, "More than one client matched");
		}
	}
}
