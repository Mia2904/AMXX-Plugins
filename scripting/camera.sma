#include <amxmodx>
#include <engine>

#define PLUGIN "Camera"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new g_cam[33];

public plugin_precache()
{
	precache_model("models/rpgrocket.mdl");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say /cam", "clcmd_cam");
}

public client_putinserver(id)
{
	g_cam[id] = 0;
}

public clcmd_cam(id)
{
	set_view(id,(g_cam[id] = !g_cam[id]));
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
