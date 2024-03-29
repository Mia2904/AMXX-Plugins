/* Plugin generated by AMXX-Studio */

#include <amxmodx>

#define PLUGIN "All Chat"
#define VERSION "0.1"

const FLAG_VIP = ADMIN_CHAT;
const FLAG_ADMIN = ADMIN_KICK;
const FLAG_STAFF = ADMIN_IMMUNITY;

new g_msgSayText;
new g_msgTeamInfo;
new cvar_alltalk;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904")
	
	register_clcmd("say", "hook_say");
	
	g_msgSayText = get_user_msgid("SayText");
	g_msgTeamInfo = get_user_msgid("TeamInfo");
	
	if (cvar_exists("sv_alltalk"))
		cvar_alltalk = get_cvar_pointer("sv_alltalk");
	else
		cvar_alltalk = register_cvar("sv_alltalk", "1");
}

public client_putinserver(id)
{
	set_task(0.2, "chatcolor_send_teaminfo", id);
}

public chatcolor_send_teaminfo(id)
{
    if (!is_user_connected(id))
        return;
    
    static const pTeams[][] = { "", "TERRORIST", "CT" };
    
    for (new pid = 0; pid < 3; pid++)
    {
        message_begin(MSG_ONE_UNRELIABLE, g_msgTeamInfo, .player = id)
        write_byte(pid+33)
        write_string(pTeams[pid])
        message_end()
    }
} 

public hook_say(id)
{
	static arg[192], name[32], num, alive;
	read_args(arg, 191);
	
	un_mejor_remove_quotes(arg);

	if (!arg[0] || (arg[0] == ' ' && (!arg[1] || arg[1] == ' ')))
		return PLUGIN_HANDLED;
	
	replace_all(arg, 191, "%", " ");
	replace_all(arg, 191, "#", " ");
	
	get_user_name(id, name, 31);
	alive = is_user_alive(id);
	num = get_user_flags(id);
	
	format(arg, 191, "^x01%s%c%s^x01 : %c %s", alive ? "" : "*DEAD* ", num & FLAG_VIP ? '^x04' : '^x03', name, num & FLAG_ADMIN ? '^x03' : '^x01', arg);
	
	if (num & FLAG_STAFF)
		id = 35;
	else if (num & FLAG_ADMIN)
		id = 33;
	
	if (get_pcvar_num(cvar_alltalk))
	{
		message_begin(MSG_BROADCAST, g_msgSayText);
		write_byte(id);
		write_string(arg);
		message_end();
	}
	else
	{
		get_players(name, num, alive ? "a" : "b");
		
		for (new i = 0; i < num; i++)
		{
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, name[i]);
			write_byte(id);
			write_string(arg);
			message_end();
		}
	}
	
	return PLUGIN_HANDLED_MAIN;
}

stock un_mejor_remove_quotes(str[])
{
    static len; len = strlen(str);
    if (len <= 1)
        return 0;

    // No comprobamos que sea comilla, asi el maximo len siempre sera igual, con comilla o no
    if (str[--len] == 34)
	str[len] = EOS;
    
    for (new i = 0; i < len; i++)
    {
        if (str[i] == '"')
        {
            copy(str, len, str[++i])
            return len-i;
        }
    }

    return 0;
}
