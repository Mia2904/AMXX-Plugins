#include <amxmodx>
#include <cstrike>

#define PLUGIN "Admin Login"
#define VERSION "0.1"

#pragma semicolon 1

new g_adminIndex[33], g_time[33];

#define autenticado(%0) (g_adminIndex[0] & (1<<%0-1))
#define cvar_time g_time[0]

const OFFSET_VGUI_JOINTEAM = 2;

const NIVEL_DE_ADMIN = ADMIN_KICK;

enum (+=100)
{
	TASK_KICK = 1234,
	TASK_CHECK
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	register_message(get_user_msgid("ShowMenu"), "message_showmenu");
	register_message(get_user_msgid("VGUIMenu"), "message_vguimenu");
	register_clcmd("chooseteam", "clcmd_jointeam");
	register_clcmd("jointeam", "clcmd_jointeam");
	register_clcmd("ADMIN_PASS", "clcmd_pass");
	
	cvar_time = register_cvar("admin_login_time", "15");
}

public client_putinserver(id) check_admin(id);

public client_disconnect(id)
{
	remove_task(id + TASK_CHECK);
	remove_task(id + TASK_KICK);
}

public clcmd_jointeam(id)
{
	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if (!autenticado(id) && (get_user_flags(id) & NIVEL_DE_ADMIN))
	{
		AdminLogin(id);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public message_showmenu(junk1, junk2, id)
{
	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	
	if (!autenticado(id) && (get_user_flags(id) & NIVEL_DE_ADMIN))
	{
		static szCode[32];
		get_msg_arg_string(4, szCode, charsmax(szCode));
		
		if (contain(szCode, "#Team") != -1)
			AdminLogin(id);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public message_vguimenu(junk1, junk2, id)
{
	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	
	if (!autenticado(id) && (get_user_flags(id) & NIVEL_DE_ADMIN))
	{
		if (get_msg_arg_int(1) == OFFSET_VGUI_JOINTEAM)
			AdminLogin(id);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

AdminLogin(id)
{
	if (!is_user_connected(id))
		return;
	
	if (!task_exists(id + TASK_KICK))
	{
		g_time[id] = get_pcvar_num(cvar_time);
		set_task(1.0, "kick_admin", id + TASK_KICK, .flags = "a", .repeat = g_time[id]);
	}
	
	client_print(id, print_chat, "Ingresa tu PASS de Admin o seras expulsado en %d segundos.", g_time[id]);
	client_cmd(id, "messagemode ^"ADMIN_PASS^"");
}

public clcmd_pass(id)
{
	if (!is_user_connected(id) || autenticado(id))
		return;
	
	static szPass[32], szCorrectPass[32];
	read_args(szPass, 31);
	remove_quotes(szPass);
	
	admins_lookup(g_adminIndex[id], AdminProp_Password, szCorrectPass, 31);
	
	if (equal(szPass, szCorrectPass))
	{
		remove_task(id + TASK_KICK);
		g_adminIndex[0] |= (1<<id-1);
		client_print(id, print_center, "Te logueaste correctamente.");
		client_cmd(id, "jointeam");
	}
	else
	{
		client_print(id, print_center, "Password incorrecto.");
		client_cmd(id, "messagemode ^"ADMIN_PASS^"");
	}
}

public client_infochanged(id)
{
	if (!is_user_connected(id))
		return;
	
	static szName[2][32];
	get_user_name(id, szName[0], 31);
	get_user_info(id, "name", szName[1], 31);
	
	if (!equal(szName[0], szName[1]))
		set_task(2.0, "task_check_admin", id + TASK_CHECK);
}

public kick_admin(id)
{
	id -= TASK_KICK;
	
	if (!--g_time[id])
		server_cmd("kick #%d ^"No has introducido tu clave.^"", get_user_userid(id));
	else
		client_print(id, print_center, "Tienes %d segundos para introducir tu clave.", g_time[id]);
}

public task_check_admin(id)
{
	id -= TASK_CHECK;
	
	if (check_admin(id))
	{
		if (is_user_alive(id))
			user_kill(id);
		
		cs_set_user_team(id, CS_TEAM_UNASSIGNED);
		
		AdminLogin(id);
	}
}

check_admin(id)
{
	if (get_user_flags(id) & NIVEL_DE_ADMIN)
	{
		static AuthData[32], szName[32], Flags, Count, index;
		get_user_name(id, szName, 31);
		index = -1;
		Count = admins_num();
		for (new i = 0; i < Count; ++i)
		{
			Flags = admins_lookup(i, AdminProp_Flags);
			
			if ((Flags & FLAG_AUTHID) || (Flags & FLAG_IP) || (Flags & FLAG_NOPASS))
				continue;
			
			admins_lookup(i, AdminProp_Auth, AuthData, charsmax(AuthData));
			
			if (Flags & FLAG_CASE_SENSITIVE)
			{
				if (Flags & FLAG_TAG)
				{
					if (contain(szName, AuthData) != -1)
					{
						index = i;
						break;
					}
				}
				else if (equal(szName, AuthData))
				{
					index = i;
					break;
				}
			}
			else
			{
				if (Flags & FLAG_TAG)
				{
					if (containi(szName, AuthData) != -1)
					{
						index = i;
						break;
					}
				}
				else if (equali(szName, AuthData))
				{
					index = i;
					break;
				}
			}
		}
		
		if (index != -1) // Es un admin con PASS
		{
			g_adminIndex[id] = index;
			g_adminIndex[0] &= ~(1<<id-1);
			
			return 1;
		}
	}
		
	g_adminIndex[0] |= (1<<id-1);
	return 0;
}
