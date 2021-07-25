#include <amxmodx>

#define PLUGIN "Vote Ban"
#define VERSION "1.2"
#define AUTHOR "Mia2904"

#define MAX_PLAYERS	32

// All is here
new g_iData[MAX_PLAYERS+1][MAX_PLAYERS+1];

// Macros for easy use
#define g_iVotes(%0)			g_iData[0][%0-1]
#define g_iVotedPlayer(%0)		g_iData[%0][MAX_PLAYERS]
#define g_iPlayerMenuData(%0,%1)	g_iData[%0][%1]

// Goodbye, get_players
new g_iConnected;

// Has voted but not entered a reason? INVALID VOTE!
new g_iConfirmed;

// Used for color printing
new g_iMsgidSayText;

const CVAR_PERCENT = 0
const CVAR_BANTIME = 1

new g_iPcvar[2];
new g_szLogFile[64];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_saycmd("voteban", "Cmd_VoteBan");
	register_clcmd("Razon_del_Voteban", "Cmd_VoteBanReason", -1, "");
	
	register_dictionary("voteban.txt");
	
	g_iPcvar[CVAR_PERCENT] = register_cvar("voteban_percent", "75");
	g_iPcvar[CVAR_BANTIME] = register_cvar("voteban_time", "30");
	
	g_iMsgidSayText = get_user_msgid("SayText");
	
	new szLogInfo[] = "amx_logdir";
	get_localinfo(szLogInfo, g_szLogFile, charsmax(g_szLogFile));
	add(g_szLogFile, charsmax(g_szLogFile), "/voteban");
	
	if(!dir_exists(g_szLogFile))
		mkdir(g_szLogFile);
		
	new szTime[32];
	get_time("%d-%m-%Y", szTime, charsmax(szTime));
	format(g_szLogFile, charsmax(g_szLogFile), "%s/%s.log", g_szLogFile, szTime);
}

public client_putinserver(id)
{
	g_iVotes(id) = 0
	g_iConnected |= (1 << id-1)
	g_iConfirmed &= ~(1 << id-1)
}

public client_disconnect(id)
{
	g_iConnected &= ~(1 << id-1)
	g_iConfirmed &= ~(1 << id-1)
	
	if(g_iVotedPlayer(id))
	{
		g_iVotes(g_iVotedPlayer(id))--;
		g_iVotedPlayer(id) = 0;
	}
	
	if(g_iVotes(id))
	{
		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if(g_iVotedPlayer(i) == id)
				g_iVotedPlayer(i) = 0
		}
	}
}

public Cmd_VoteBan(id)
{
	if(!(g_iConnected & (1 << id-1)))
		return PLUGIN_HANDLED;
	
	if(get_playersnum() < 3)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgidSayText, _, id);
		write_byte(id);
		write_string("^x04[Voteban]^x01 Comando no disponible. Se requieren 3 o mas jugadores.");
		message_end();
		
		return PLUGIN_HANDLED;
	}
	
	if(g_iVotedPlayer(id))
	{
		if(g_iConfirmed & (1 << id-1))
		{
			ConfirmMenu(id)
			return PLUGIN_CONTINUE;
		}
		else
			g_iVotedPlayer(id) = 0
	}
	
	VoteBanMenu(id);
	
	return PLUGIN_CONTINUE;
}

VoteBanMenu(id)
{
	static menushow[50], szName[32];
	
	formatex(menushow, charsmax(menushow), "\r[Voteban] \ySeleccionar Jugador%s", get_playersnum() > 7 ? "^nPagina:\r" : "");
	
	new count, percent, menu = menu_create(menushow, "Menu_VoteBan");
	
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!(g_iConnected & (1 << i-1))) continue;
		
		g_iPlayerMenuData(id, count) = i;
		count++;
		
		get_user_name(i, szName, 31);
		
		percent = get_percent(g_iVotes(i), get_playersnum())
		
		formatex(menushow, charsmax(menushow), "%s \r[\%s%d%%\r]", szName, !percent ? "w" : "y", percent);
		
		menu_additem(menu, menushow, "", 0);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "\ySalir");
	menu_setprop(menu, MPROP_BACKNAME, "Anterior");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente^n");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public Menu_VoteBan(id, menu, key)
{
	if(key == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new iPlayer = g_iPlayerMenuData(id, key)
	
	if(g_iConnected & (1 << iPlayer-1))
	{
		g_iVotedPlayer(id) = iPlayer
		g_iConfirmed &= ~(1 << id-1)
		client_print(id, print_center, "* Ingresa la razon del voteban *");
		client_cmd(id, "messagemode Razon_del_Voteban");
	}
	else
		VoteBanMenu(id);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

ConfirmMenu(id)
{
	new szName[100]
	get_user_name(g_iVotedPlayer(id), szName, 31)
	format(szName, charsmax(szName), "\r[Voteban] \wYa has votado por \y%s^n¿Anular el voto?", szName)
	new menu = menu_create(szName, "Menu_Confirm")
	
	menu_additem(menu, "Si", "")
	menu_additem(menu, "No", "")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_display(id, menu)
}

public Menu_Confirm(id, menu, key)
{
	menu_destroy(menu)
	
	if(key != 0)
		return PLUGIN_HANDLED;
	
	g_iVotes(g_iVotedPlayer(id))--
	g_iVotedPlayer(id) = 0
	g_iConfirmed &= ~(1 << id-1)
	
	VoteBanMenu(id)
	
	return PLUGIN_HANDLED
}

public Cmd_VoteBanReason(id)
{
	if(!g_iVotedPlayer(id))
		return PLUGIN_HANDLED;
	
	new szArgs[50], szName[2][32], iPlayer;
	read_argv(1, szArgs, charsmax(szArgs));
	
	if(strlen(szArgs) < 4)
	{
		client_print(id, print_center, "* Minimo 4 caracteres *");
		client_cmd(id, "messagemode Razon_del_Voteban");
		return PLUGIN_HANDLED;
	}
	
	iPlayer = g_iVotedPlayer(id)
	g_iConfirmed |= (1 << id-1)
	
	get_user_name(id, szName[0], charsmax(szName[]));
	get_user_name(iPlayer, szName[1], charsmax(szName[]));
			
	client_printc("\g[Voteban] \t%s \dha votado por \t%s\d (Razon: %s)", szName[0], szName[1], szArgs);
	
	g_iVotes(iPlayer)++;
	CheckVotes(iPlayer, id, szArgs);
	
	return PLUGIN_HANDLED;
}

public CheckVotes(id, voter, const reason[])
{
	new iMinutes = get_pcvar_num(g_iPcvar[CVAR_BANTIME]);
	
	if(get_percent(g_iVotes(id), get_playersnum()) >= get_pcvar_num(g_iPcvar[CVAR_PERCENT]))
	{
		new szName[2][32];
		
		get_user_ip(id, szName[0], charsmax(szName[]), 1);
		
		server_cmd("kick #%d ^"Baneado %d minutos por votacion. (%s)^";wait;wait;addip %d ^"%s^";wait;wait;writeip", get_user_userid(id), iMinutes, reason, iMinutes , szName[0]);
	
		g_iVotes(id) = 0;
		
		get_user_name(id, szName[0], charsmax(szName[]));
		get_user_name(voter, szName[1], charsmax(szName[]));
		
		client_printc("\g[Voteban] \t%s \dha sido baneado por \g%d\d minutos! Razon (%s): %s", szName[0], iMinutes, szName[1], reason);
		
		log_to_file(g_szLogFile, "%s baneado. Razon (%s): %s", szName[0], szName[1], reason);
	}
}

stock get_percent(value, tvalue)
{     
	return floatround(floatmul(float(value) / float(tvalue) , 100.0));
}

stock register_saycmd(saycommand[], function[])
{
	new szTemp[64];
	formatex(szTemp, charsmax(szTemp), "say /%s", saycommand);
	register_clcmd(szTemp, function);
	formatex(szTemp, charsmax(szTemp), "say .%s", saycommand);
	register_clcmd(szTemp, function);
	formatex(szTemp, charsmax(szTemp), "say_team /%s", saycommand);
	register_clcmd(szTemp, function);
	formatex(szTemp, charsmax(szTemp), "say_team .%s", saycommand);
	register_clcmd(szTemp, function);
}

stock client_printc(const text[], any:...)
{
	new szMsg[191];
	vformat(szMsg, charsmax(szMsg), text, 3);
	
	replace_all(szMsg, charsmax(szMsg), "\g","^x04");
	replace_all(szMsg, charsmax(szMsg), "\d","^x01");
	replace_all(szMsg, charsmax(szMsg), "\t","^x03");
	
	for(new i = 1 ; i <= MAX_PLAYERS ; i++)
	{
		if(!(g_iConnected & (1 << i-1))) continue;
		
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgidSayText, _, i);
		write_byte(i);
		write_string(szMsg);
		message_end();
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
