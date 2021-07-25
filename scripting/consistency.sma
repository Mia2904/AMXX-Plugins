#include <amxmodx>

#define PLUGIN "Consistency"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

#pragma semicolon 1

new cvar_consistency;

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	cvar_consistency = get_cvar_pointer("mp_consistency");
	
	set_pcvar_num(cvar_consistency, 0);
}

public plugin_cfg()
{
	set_pcvar_num(cvar_consistency, 0);
}
	
