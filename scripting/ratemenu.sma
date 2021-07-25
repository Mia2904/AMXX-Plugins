#include <amxmodx>

#define PLUGIN "Ratemenu"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new g_rate, cvar1, cvar2;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("ratemenu", "clcmd_ratemenu", ADMIN_CHAT);
	cvar1 = get_cvar_pointer("sv_maxrate");
	cvar2 = get_cvar_pointer("sv_minrate");
	
	g_rate = (get_pcvar_num(cvar1) / 2000) * 2000;
}

public clcmd_ratemenu(id, level)
{
	if (~get_user_flags(id) & level)	
		return PLUGIN_CONTINUE;
	
	show_menu_rate(id);
	
	return PLUGIN_HANDLED;
}

show_menu_rate(id)
{
	new str[10];
	num_to_str(g_rate, str, 9);
	new menu = menu_create(str, "menu_rate");
	menu_additem(menu, "+");
	menu_additem(menu, "-");
	
	menu_display(id, menu);
}

public menu_rate(id, menu, item)
{
	switch (item)
	{
		case 0: g_rate += 2000;
		case 1: g_rate -= 2000;
	}
	
	set_pcvar_float(cvar1, float(g_rate));
	set_pcvar_float(cvar2, float(g_rate));
	
	menu_destroy(menu);
	
	if (item != MENU_EXIT)
		show_menu_rate(id);
	
	return PLUGIN_HANDLED;
}
