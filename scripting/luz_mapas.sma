#include <amxmodx>

// Si se usa con un ZP, usar la cvar/cmd del ZP
//#define ZP "zp_lighting"

// Nivel de admin para cambiar la luz
const ADMIN_LEVEL = ADMIN_RCON;

#if !defined ZP
#include <fakemeta>
#endif

#pragma semicolon 1

#define PLUGIN "Luz Mapas"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new g_config;
new szLight[3], szCurrentMap[32];
new g_cb_item_disabled;
#if defined ZP
new g_pcvar_light;
#endif

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /luz", "clcmd_light");
	register_clcmd("NIVEL_DE_LUZ", "clcmd_nivel");
	
	g_cb_item_disabled = menu_makecallback("cb_item_disabled");
}

public plugin_cfg()
{
#if defined ZP
	if (cvar_exists(ZP))
	{
		g_pcvar_light = get_cvar_pointer(ZP);
	}
	else
	{
		copy(szLight, charsmax(szLight), "a");
	}
#else
	copy(szLight, charsmax(szLight), "a");
#endif
	
	leer_config();
}

public cb_item_disabled(id, menu, item)
{	
	return ITEM_DISABLED;
}

public clcmd_light(id)
{
	if (~get_user_flags(id) & ADMIN_LEVEL)
		return PLUGIN_CONTINUE;
	
	new szTitle[90];
#if defined ZP
	if (g_pcvar_light && !szLight[0])
		get_pcvar_string(g_pcvar_light, szLight, 2);
#endif
	formatex(szTitle, charsmax(szTitle), "\yMapa actual:\r %s^n\yNivel de luz:\r [\w%s\r]^n", szCurrentMap, szLight);
	
	new Menu = menu_create(szTitle, "menu_light");
	menu_additem(Menu, "Incrementar luz", .callback = equal(szLight, "#", 1) ? g_cb_item_disabled : -1);
	menu_additem(Menu, "Decrementar luz^n", .callback = equal(szLight, "a", 1) ? g_cb_item_disabled : -1);
	
	menu_additem(Menu, "Introducir valor de luz^n");
	
	menu_additem(Menu, "\yGuardar y salir");
	
	menu_setprop(Menu, MPROP_PERPAGE, 0);
	menu_setprop(Menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, Menu);
	
	return PLUGIN_HANDLED;
}

public menu_light(id, menu, item)
{
	menu_destroy(menu);
	
	if (!is_user_connected(id))
	{
		return PLUGIN_HANDLED;
	}
	
	switch (item)
	{
		case 0:
		{
			switch (szLight[0])
			{
				case 97 .. 121: szLight[0]++;
				case 122: szLight[0] = 35;
			}
			
			aplicar_light();
			
			clcmd_light(id);
		}
		case 1:
		{
			switch (szLight[0])
			{
				case 35: szLight[0] = 122;
				case 98 .. 122: szLight[0]--;
			}
			
			aplicar_light();
			
			clcmd_light(id);
		}
		case 2:
		{
			client_cmd(id, "messagemode NIVEL_DE_LUZ");
		}
		case 3:
		{
			guardar_config(id);
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_nivel(id)
{
	if (~get_user_flags(id) & ADMIN_LEVEL || !is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	read_argv(1, szLight, 2);
	strtolower(szLight);
	
	if (97 <= szLight[0] <= 122 || szLight[0] == 35)
	{
		aplicar_light();
		clcmd_light(id);
	}
	else
	{
		client_print(id, print_center, "Incorrecto. Introduzca una letra entre A y Z o #");
		client_cmd(id, "messagemode NIVEL_DE_LUZ");
	}
	
	return PLUGIN_HANDLED;
}

leer_config()
{
	new szBuffer[192], File;
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	get_mapname(szCurrentMap, 31);
	
	format(szBuffer, charsmax(szBuffer), "%s/LuzMapas", szBuffer);
	
	if (!dir_exists(szBuffer))
		mkdir(szBuffer);
	
	format(szBuffer, charsmax(szBuffer), "%s/%s.ini", szBuffer, szCurrentMap);
	
	if (!file_exists(szBuffer))
	{
		g_config = false;
		return;
	}
	
	File = fopen(szBuffer, "rt");
	
	fgets(File, szLight, 2);
	set_task(3.0, "aplicar_light");
	g_config = true;
	fclose(File);
}

public aplicar_light()
{
#if defined ZP
	if (g_pcvar_light)
		set_pcvar_string(g_pcvar_light, szLight);
	else
		server_cmd("%s %s", ZP, szLight);
#else
	engfunc(EngFunc_LightStyle, 0, szLight);
#endif
}

guardar_config(id)
{
	new szBuffer[192];
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	
	format(szBuffer, charsmax(szBuffer), "%s/LuzMapas/%s.ini", szBuffer, szCurrentMap);
	
	if (g_config)
	{
		delete_file(szBuffer);
	}
	
	new File = fopen(szBuffer, "wt");
	
	fputs(File, szLight);
	
	fclose(File);
	
	client_print(id, print_chat, "Configuracion guardada con exito.");
	
	g_config = true;
}
