#include <amxmodx>

#define PLUGIN "Vote Ban"
#define VERSION "1.2"
#define AUTHOR "Alka"

#define MAX_PLAYERS	32

// All is here
new g_iData[MAX_PLAYERS+1][MAX_PLAYERS+1];

// Macros for easy use
#define g_iVotes(%0)			g_iData[0][%0-1]
#define g_iVotedPlayer(%0)		g_iData[%0][MAX_PLAYERS]
#define g_iPlayerMenuData(%0,%1)	g_iData[%0][%1]

// Goodbye, get_players
new g_iConnected;

// You've voted without entering a reason? INVALID VOTE!
new g_iConfirmed;

new g_iMsgidSayText;

enum _:PCVARS
{
	CVAR_PERCENT = 0,
	CVAR_BANTYPE,
	CVAR_BANTIME
};

new g_szCvarName[PCVARS][] =
{
	"voteban_percent",
	"voteban_type",
	"voteban_time"
};

new g_szCvarValue[PCVARS][] =
{
	"80",
	"1",
	"60"
};

new g_iPcvar[PCVARS];
new g_szLogFile[64];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_saycmd("voteban", "Cmd_VoteBan", -1, "");
	register_clcmd("_Voteban_Reason", "Cmd_VoteBanReason", -1, "");
	
	register_dictionary("voteban.txt");
	
	for(new i = 0 ; i < PCVARS; i++)
	{
		g_iPcvar[i] = register_cvar(g_szCvarName[i], g_szCvarValue[i]);
	}
	
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
	if(get_playersnum() < 3)
	{
		single_user_printc(id, "\g[Voteban] \d%L", id, "MORE_PLAYERS");
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
	static menushow[70], szName[32], count, percent;
	
	count = formatex(menushow, charsmax(menushow), "\r[Voteban] \y%L", id, "SELECT_PLAYER")
	// If there's more than one page, display "Page: x/y"
	if(get_playersnum() > 7)
		formatex(menushow[count], charsmax(menushow)-count, "^n%L:\r", id, "CURRENT_PAGE");
	
	new menu = menu_create(menushow, "Menu_VoteBan");
	count = 0;
	
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!(g_iConnected & (1 << i-1))) continue;
		
		g_iPlayerMenuData(id, count) = i;
		count++;
		
		get_user_name(i, szName, 31);
		
		percent = get_percent(g_iVotes(i), get_playersnum());
		
		formatex(menushow, charsmax(menushow), "%s \r[\%s%d%%\r]", szName, !percent ? "w" : "y", percent);
		
		menu_additem(menu, menushow, "", 0);
	}
	
	formatex(menushow, charsmax(menushow), "\y%L", id, "EXIT_NAME"); 
	menu_setprop(menu, MPROP_EXITNAME, menushow);
	
	formatex(menushow, charsmax(menushow), "%L", id, "BACK_NAME"); 
	menu_setprop(menu, MPROP_BACKNAME, "Anterior");
	
	formatex(menushow, charsmax(menushow), "%L^n", id, "NEXT_NAME"); 
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
		client_print(id, print_center, "* %L *", id, "ENTER_REASON");
		client_cmd(id, "messagemode _Voteban_Reason");
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
	format(szName, charsmax(szName), "\r[Voteban] \w%L \y%s^n%L", id, "ALREADY_VOTEBAN", szName, id, "CANCEL_VOTEBAN")
	new menu = menu_create(szName, "Menu_Confirm")
	
	formatex(szName, charsmax(szName), "%L", id, "YES_CANCEL")
	menu_additem(menu, szName, "")
	
	formatex(szName, charsmax(szName), "%L", id, "NON_CANCEL")
	menu_additem(menu, szName, "")
	
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
	iPlayer = g_iVotedPlayer(id)
	g_iConfirmed |= (1 << id-1)
	
	get_user_name(id, szName[0], charsmax(szName[]));
	get_user_name(iPlayer, szName[1], charsmax(szName[]));
	
	for(id = 1; id <= MAX_PLAYERS; id++)
	{
		if(!(g_iConnected & (1 << id-1))) continue;
		 
		single_user_printc(id, "\g[Voteban] \t%s \d%L \t%s\d (%L: %s)", szName[0], id, "VOTEBANNED_FOR", szName[1], id, "VOTEBAN_REASON", szArgs);
	}
			
	g_iVotes(iPlayer)++;
	CheckVotes(iPlayer, id, szArgs);
	
	return PLUGIN_HANDLED;
}

public CheckVotes(id, voter, const reason[])
{
	new szTime = get_pcvar_num(g_iPcvar[CVAR_BANTIME]);
	
	if(get_percent(g_iVotes(id), get_playersnum()) >= get_pcvar_num(g_iPcvar[CVAR_PERCENT]))
	{
		switch(get_pcvar_num(g_iPcvar[CVAR_BANTYPE]))
		{
			case 1:
			{
				new szAuthid[32];
				get_user_authid(id, szAuthid, charsmax(szAuthid));
				server_cmd("kick #%d ^"[Voteban] Banned for %d min. (%s)^";wait;wait;banid %d ^"%s^";wait;wait;writeid", get_user_userid(id), szTime, reason, szTime, szAuthid);
			}
			case 2:
			{
				new szIp[32];
				get_user_ip(id, szIp, charsmax(szIp), 1);
				server_cmd("kick #%d ^"[Voteban] Banned for %d min. (%s)^";wait;wait;addip %d ^"%s^";wait;wait;writeip", get_user_userid(id), szTime, reason, szTime, szIp);
			}
		}
	
		g_iVotes(id) = 0;
		
		new szName[2][32];
		get_user_name(id, szName[0], charsmax(szName[]));
		get_user_name(voter, szName[1], charsmax(szName[]));
		
		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if(!(g_iConnected & (1 << i-1))) continue;
			
			single_user_printc(i, "\g[Voteban] \t%s \d%L \g%d\d %L! %L (%s): %s", szName[0], i, "VOTEBANNED", szTime, i, "MINUTES", i, "VOTEBAN_REASON", szName[1], reason);
		}
		
		log_to_file(g_szLogFile, "%s banned for %d min. Reason (%s): %s", szName[0], szTime, szName[1], reason);
	}
}

single_user_printc(id, const text[], any:...)
{
	if(!(g_iConnected & (1 << id-1)) || !id)
		return;
	
	new szMsg[191];
	vformat(szMsg, charsmax(szMsg), text, 3);
	
	replace_all(szMsg, charsmax(szMsg), "\g","^x04");
	replace_all(szMsg, charsmax(szMsg), "\d","^x01");
	replace_all(szMsg, charsmax(szMsg), "\t","^x03");
	
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgidSayText, _, id);
	write_byte(id);
	write_string(szMsg);
	message_end();
}

stock get_percent(value, tvalue)
{     
	return floatround(floatmul(float(value) / float(tvalue) , 100.0));
}

stock register_saycmd(saycommand[], function[], flags = -1, info[])
{
	new szTemp[64];
	formatex(szTemp, charsmax(szTemp), "say %s", saycommand);
	register_clcmd(szTemp, function, flags, info);
	formatex(szTemp, charsmax(szTemp), "say_team %s", saycommand);
	register_clcmd(szTemp, function, flags, info);
	formatex(szTemp, charsmax(szTemp), "say /%s", saycommand);
	register_clcmd(szTemp, function, flags, info);
	formatex(szTemp, charsmax(szTemp), "say .%s", saycommand);
	register_clcmd(szTemp, function, flags, info);
	formatex(szTemp, charsmax(szTemp), "say_team /%s", saycommand);
	register_clcmd(szTemp, function, flags, info);
	formatex(szTemp, charsmax(szTemp), "say_team .%s", saycommand);
	register_clcmd(szTemp, function, flags, info);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
