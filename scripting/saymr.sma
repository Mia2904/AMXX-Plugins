#include <amxmodx>

#define PLUGIN "Activar MR/FFA"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

#pragma semicolon 1

new cvar_restart;
new g_msgSayText;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /live", "clcmd_live", ADMIN_KICK);
	register_clcmd("say /pre", "clcmd_pre", ADMIN_KICK);
	
	g_msgSayText = get_user_msgid("SayText");
	cvar_restart = get_cvar_pointer("sv_restart");
}

public clcmd_live(id, level)
{
	if (get_user_flags(id) & level)
	{
		server_cmd("exec mr.cfg");
		set_task(0.4, "live_messages");
		print_color("^x04=============================================================");
		print_color("^x03Modo LIVE activado. Configurando el servidor...");
	}
	
	return PLUGIN_CONTINUE;
}

public live_messages()
{
	client_print(0, print_center, "Empezando en 5 segundos. Buena suerte!");
	print_color("^x03Servidor configurado. Empezando en 5 segundos.");
	print_color("^x03Que la suerte este contigo. Diviertete!");
	print_color("^x04=============================================================");
}

public clcmd_pre(id, level)
{
	if (get_user_flags(id) & level)
	{
		server_cmd("exec server.cfg");
		set_pcvar_float(cvar_restart, 1.0);
	}
	
	return PLUGIN_CONTINUE;
}

print_color(text[])
{
	message_begin(MSG_BROADCAST, g_msgSayText);
	write_byte(33);
	write_string(text);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
