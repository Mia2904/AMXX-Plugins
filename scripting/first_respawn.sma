#include <amxmodx>
#include <hamsandwich>

#define PLUGIN "First Respawn"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new g_bRespawned;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("TeamInfo", "Event_TeamInfo", "a");
}

public client_putinserver(id) g_bRespawned &= ~(1<<(id-1));

public Event_TeamInfo()
{
	new id = read_data(1);
	
	if (g_bRespawned & (1<<(id-1)))
		return;
	
	new selectedteam[2];
	read_data(2, selectedteam, 1);
	if(selectedteam[0] == 'C' || selectedteam[0] == 'T')
		set_task(0.2, "respawn_player", id);
}

public respawn_player(id)
{
	if (!is_user_alive(id))
		ExecuteHamB(Ham_CS_RoundRespawn, id);
	
	g_bRespawned |= (1<<(id-1));
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang2057{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
