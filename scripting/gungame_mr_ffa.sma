/* Plugin generated by AMXX-Studio */

#include <amxmodx>

#define PLUGIN "Gungame enabler"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /gungame", "clcmd_gungame", ADMIN_BAN);
	register_clcmd("say /mr", "clcmd_mr", ADMIN_BAN);
	register_clcmd("say /ffa", "clcmd_ffa", ADMIN_BAN);
}

public clcmd_gungame(id, level)
{
	if (~get_user_flags(id) & level)
		return PLUGIN_CONTINUE;
	
	server_cmd("exec gungame.cfg");
	
	return PLUGIN_CONTINUE;
}

public clcmd_mr(id, level)
{
	if (~get_user_flags(id) & level)
		return PLUGIN_CONTINUE;
	
	server_cmd("exec mr.cfg");
	
	return PLUGIN_CONTINUE;
}

public clcmd_ffa(id, level)
{
	if (~get_user_flags(id) & level)
		return PLUGIN_CONTINUE;
	
	server_cmd("exec server.cfg");
	
	return PLUGIN_CONTINUE;
}