#include <amxmodx>
#include <fakemeta>
#include <xs>

#define PLUGIN "AFK a SPEC"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new g_afktime[32], Float:g_origin[32][3], Float:g_angles[32][3], g_afklimit, g_ingame, cvar_afktime;
new g_msgShowMenu, g_msgVGUIMenu

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_logevent("logevent_round_start",2, "1=Round_Start");
	register_logevent("logevent_round_end", 2, "1=Round_End");
	register_message(get_user_msgid("TextMsg"), "message_textmsg");
	
	cvar_afktime = register_cvar("afk_to_spec_time", "45");
	
	set_task(1.0, "check_afk_players", .flags = "b");
	
	g_msgShowMenu = get_user_msgid("ShowMenu");
	g_msgVGUIMenu = get_user_msgid("VGUIMenu");
	
	g_ingame = false;
}

public client_disconnect(id)
	g_afktime[id-1] = 0;

public logevent_round_start()
{
	arrayset(g_afktime, 0, 32);
	g_ingame = true;
	g_afklimit = get_pcvar_num(cvar_afktime);
}

public logevent_round_end()
	g_ingame = false;

public message_textmsg()
{
	static textmsg[22];
	get_msg_arg_string(2, textmsg, charsmax(textmsg));
	
	if (equal(textmsg, "#Game_will_restart_in"))
		g_ingame = false;
}

public check_afk_players()
{
	if (!g_ingame)
		return;
	
	static players[32], num, Float:origin[3], Float:angles[3], id;
	
	get_players(players, num, "ach");
	
	for (new i = 0; i < num; i++)
	{
		id = players[i];
		pev(id, pev_origin, origin);
		pev(id, pev_angles, angles);
		if (xs_vec_equal(origin, g_origin[id-1]))
		{
			if (xs_vec_equal(angles, g_angles[id-1]))
			{
				g_afktime[id-1] += 1;
				
				if (g_afktime[id-1] >= g_afklimit)
					move_to_spec(id);
				
				continue;
			}
		}
		else
			xs_vec_copy(origin, g_origin[id-1]);
		
		xs_vec_copy(angles, g_angles[id-1]);
		g_afktime[id-1] = 0;
	}
}

move_to_spec(id)
{
	user_silentkill(id);
	force_jointeam(id, 3, true);
	g_afktime[id-1] = 0;
	new name[32];
	get_user_name(id, name, 31);
	client_print(0, print_chat, "[AFK] %s ha sido transferido a espectador por estar AFK por %d segundos.", name, g_afklimit);
}

// Destro
const m_iVGUI = 510;
const m_bools125 = 125;
const m_bHasChangeTeamThisRound = (1<<8);

/*
team:
-0: AUTO
-1: TT
-2: CT
-3: SPECT
free_changeteam:
true: habilita el cambio de team en esa ronda
false: (Only 1 team change is allowed.) 
*/
stock force_jointeam(id, team, free_changeteam)
{
	new param[2];param[0] = team;param[1] = free_changeteam;
	set_task(0.3, "task_jointeam", id, param, 2);
}

public task_jointeam(param[], id)
{
	if (!is_user_connected(id))
		return;
	
	static restore, bool25, vgui;
	static const str_teams[][] = { "5", "1", "2", "6" };
	
	restore = get_pdata_int(id, m_iVGUI);
	vgui = restore & (1<<0);
	if(vgui) set_pdata_int(id, m_iVGUI, restore & ~(1<<0));
	
	bool25 = get_pdata_int(id, m_bools125);
	
	if(bool25 & m_bHasChangeTeamThisRound)
	{
		bool25 &= ~m_bHasChangeTeamThisRound;
		set_pdata_int(id, m_bools125, bool25);
	}
	
	// No obtengo el bloqueo actual porque no hay ninguna razon para que un plugin bloquee estos mensajes globalmente. 
	set_msg_block(g_msgShowMenu, BLOCK_ONCE);
	set_msg_block(g_msgVGUIMenu, BLOCK_ONCE);
	
	engclient_cmd(id, "jointeam", str_teams[param[0]]);
	if(param[0] != 3) engclient_cmd(id, "joinclass", "5");
	
	set_msg_block(g_msgVGUIMenu, BLOCK_NOT);
	set_msg_block(g_msgShowMenu, BLOCK_NOT);
	
	if(vgui) set_pdata_int(id, m_iVGUI, restore);
	if(param[1]) set_pdata_int(id, m_bools125, bool25);
	
} 

