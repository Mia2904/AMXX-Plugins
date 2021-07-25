#include <amxmodx>
#include <engine>
#include <hamsandwich>

#if !defined MAX_PLAYERS
#define MAX_PLAYERS 32
#endif

#define PLUGIN "Force Cvars"
#define VERSION "0.1"
#define AUTHOR "Mia"

new g_iSize, g_iMaxPlayers;
new Array:g_aCvars, Array:g_aOperators, Array:g_aValues;
new g_iConnected[33];

new szCvar[50];
new szValue[20];
new szOperator[3];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new szBuffer[192], File;
	
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	format(szBuffer, charsmax(szBuffer), "%s/CvarValues.ini", szBuffer);
	
	g_aCvars = ArrayCreate(sizeof(szCvar), 10);
	g_aOperators = ArrayCreate(sizeof(szOperator), 10);
	g_aValues = ArrayCreate(sizeof(szValue), 10);
	
	if (!file_exists(szBuffer))
	{
		File = fopen(szBuffer, "wt");
		
		fprintf(File, "; Escribe aqui las CVARs y sus valores separados por espacios.^n; Ejemplo:^n; fps_max < 100^n; cl_bob > 0.01^n; cl_cmdrate < 102^n; developer = 0^n^n");
		
		fclose(File);
	}
	
	File = fopen(szBuffer, "rt");
	
	while (!feof(File))
	{
		fgets(File, szBuffer, charsmax(szBuffer));
		
		if (szBuffer[0] != '"' && !isalpha(szBuffer[0]))
			continue;
		
		szCvar[0] = EOS;
		
		parse(szBuffer, szCvar, charsmax(szCvar), szOperator, charsmax(szOperator), szValue, charsmax(szValue));
		remove_quotes(szCvar); remove_quotes(szValue); remove_quotes(szOperator);
		
		ArrayPushString(g_aCvars, szCvar);
		ArrayPushString(g_aValues, szValue);
		ArrayPushCell(g_aOperators, szOperator[0]);
	}
	
	fclose(File);
	
	g_iSize = ArraySize(g_aCvars);
	
	if (!g_iSize)
	{
		ArrayDestroy(g_aCvars); ArrayDestroy(g_aValues); ArrayDestroy(g_aOperators);
		set_fail_state("No CVARs loaded.");
		return;
	}
	
	g_iMaxPlayers = get_maxplayers();
}

public server_frame()
{
	static Float:fLast, Float:fTime, iId, iLast, szNum[3];
	fTime = halflife_time();
	
	if (fTime - fLast >= 0.3)
	{
		fLast = fTime;
		
		if (iLast == g_iSize)
		{
			iLast = 0;
		
			if (iId == g_iMaxPlayers)
				iId = 1;
			else
				iId++;
		}
		
		if (!g_iConnected[iId])
		{
			iLast = g_iSize;
			return;
		}
		
		ArrayGetString(g_aCvars, iLast, szCvar, charsmax(szCvar));
		num_to_str(iLast, szNum, charsmax(szNum));
		query_client_cvar(iId, szCvar, "onCvarQuery", charsmax(szNum), szNum);
		
		iLast++;
	}
}

public onCvarQuery(iId, const szQCvar[], const szClientValue[], const szParam[])
{
	if (!g_iConnected[iId])
		return;
	
	static iNum, cOperator, iKick, szText[15];
	
	iNum = str_to_num(szParam);
	ArrayGetString(g_aValues, iNum, szValue, charsmax(szValue));
	cOperator = ArrayGetCell(g_aOperators, iNum);
	
	iKick = 0;
	switch (cOperator)
	{
		case '<':
		{
			if (str_to_float(szClientValue) > str_to_float(szValue))
			{
				iKick = 1;
				copy(szText, charsmax(szText), "maximo");
			}
		}
		case '>':
		{
			if (str_to_float(szClientValue) < str_to_float(szValue))
			{
				iKick = 1;
				copy(szText, charsmax(szText), "minimo");
			}
		}
		case '=':
		{
			if (str_to_float(szClientValue) != str_to_float(szValue))
			{
				iKick = 1;
				copy(szText, charsmax(szText), "exigido");
			}
		}
	}
		
	if (iKick)
	{
		server_cmd("kick #%d   %s detectado: %s. Valor %s: %s.", get_user_userid(iId), szCvar, szClientValue, szText, szValue);
	}
}

public client_putinserver(iId)
{
	set_task(65.0, "client_accept_rules", iId);
	set_task(5.0, "print_rules", iId);
}

public print_rules(iId)
{
	if (!is_user_connected(iId))
		return;
	
	client_print(iId, print_chat, "En este servidor se exigen algunos comandos. Revisa tu consola.");
	client_print(iId, print_chat, "En este servidor se exigen algunos comandos. Revisa tu consola.");
	
	static szCvar[50], szValue[10], szText[15];
	
	client_print(iId, print_console, "============================");
	client_print(iId, print_console, "Tienes 1 minuto para establecer estos comandos o seras expulsado.");
	client_print(iId, print_console, "Comando | Valor");
	
	for (new i = 0; i < g_iSize; i++)
	{
		ArrayGetString(g_aCvars, i, szCvar, charsmax(szCvar));
		ArrayGetString(g_aValues, i, szValue, charsmax(szValue));
		
		switch (ArrayGetCell(g_aOperators, i))
		{
			case '<':
				copy(szText, charsmax(szText), "(maximo)");
			case '>':
				copy(szText, charsmax(szText), "(minimo)");
			case '=':
				szText[0] = EOS;
		}
		
		client_print(iId, print_console, "%s %s %s", szCvar, szValue, szText);
	}
	
	client_print(iId, print_console, "============================");
}

public client_accept_rules(iId)
{
	if (is_user_connected(iId))
		g_iConnected[iId] = 1;
}

public client_disconnect(iId)
{
	g_iConnected[iId] = 0;
}

