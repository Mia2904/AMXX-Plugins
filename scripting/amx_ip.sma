#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Ver IPs"
#define VERSION "0.1"

const NIVEL = ADMIN_KICK

#pragma semicolon 1

#define USO "<nombre|@> - Ver la ip de un jugador, @ para todos."

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	register_concmd("amx_ip", "GetIp", NIVEL, USO);
}

public GetIp(id, level, cid)
{
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED;

	static target[32];
	new ip[25], player;
	read_argv(1, target, 31);
	
	if (!target[0])
	{
		console_print(id, "Uso: amx_ip %s", USO);
	}
	else if (target[0] == '@')
	{
		new players[32];
		get_players(players, cid, "");
		
		for (new i; i < cid; i++)
		{
			player = players[i];
			get_user_name(player, target, 31);
			get_user_ip(player, ip, 24, 0);
			console_print(id, "%d. IP de %s: %s", i+1, target, ip);
		}
	}
	else
	{
		player = cmd_target(id, target, 0);
		
		if (player)
		{
			get_user_name(player, target, 31);
			get_user_ip(player, ip, 24, 0);
			console_print(id, "IP de %s: %s", target, ip);
		}
	}
	
	return PLUGIN_HANDLED;
}
