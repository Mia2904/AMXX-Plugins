#include <amxmodx>
#include <cstrike>

#define PLUGIN "Menu de models Admin"
#define VERSION "0.3"

#pragma semicolon 1

const NIVEL_DE_ADMIN = ADMIN_RESERVATION;

new g_menu, g_size, Array:g_models;

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	g_models = ArrayCreate(32, 1);
	g_menu = menu_create("Models para Admins\r", "menu_models");
	
	new szBuffer[192], File, szModel[32], szName[64];
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	
	format(szBuffer, charsmax(szBuffer), "%s/MenuAdminModels.ini", szBuffer);
	
	if (!file_exists(szBuffer))
	{
		File = fopen(szBuffer, "wt");
		
		fprintf(File, "; Comando de chat para abrir el menu.^nCOMANDO = /models^n^n; Aqui van los models junto a su respectivo nombre.^n^"vip^" ^"Model VIP^"");
		
		fclose(File);
	}
	
	File = fopen(szBuffer, "rt");
	
	while (!feof(File))
	{
		fgets(File, szBuffer, charsmax(szBuffer));
		
		if (!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '^n')
			continue;
		
		trim(szBuffer);
		
		if (szBuffer[0] == 'C') // Registrando el comando
		{
			format(szBuffer, charsmax(szBuffer), "say %s", szBuffer[10]);
			register_clcmd(szBuffer, "show_menu_models", NIVEL_DE_ADMIN);
			
			format(szBuffer, charsmax(szBuffer), "say_team %s", szBuffer[4]);
			register_clcmd(szBuffer, "show_menu_models", NIVEL_DE_ADMIN);
			
			continue;
		}
		
		parse(szBuffer, szModel, charsmax(szModel), szName, charsmax(szName));
		remove_quotes(szModel); remove_quotes(szName);
		
		formatex(szBuffer, charsmax(szBuffer), "models/player/%s/%s.mdl", szModel, szModel);
		
		if (file_exists(szBuffer))
			precache_model(szBuffer);
		else
		{
			// El archivo no existe. Si intentamos cargarlo, el servidor se caera.
			// Mejor me desactivo para no causar problemas :(
			ArrayDestroy(g_models);
			menu_destroy(g_menu);
			fclose(File);
			
			log_amx("No se encontro %s", szBuffer);
			set_fail_state("Error al cargar los models.");
			return;
		}
		
		// Si el model incluye las texturas aparte (modelT.mdl) cargar tambien
		copy(szBuffer[strlen(szBuffer)-4], charsmax(szBuffer), "T.mdl");
		
		if (file_exists(szBuffer))
			precache_model(szBuffer);
		
		ArrayPushString(g_models, szModel);
		menu_additem(g_menu, szName);
	}
	
	fclose(File);
	
	g_size = ArraySize(g_models);
	
	if (!g_size)
	{
		ArrayDestroy(g_models);
		menu_destroy(g_menu);
		set_fail_state("No se cargaron models.");
		return;
	}

	menu_additem(g_menu, "Ninguno \r(Model normal)", "", 0);
	
	menu_setprop(g_menu, MPROP_EXITNAME, "\ySalir^n");
	menu_setprop(g_menu, MPROP_BACKNAME, "Anterior");
	menu_setprop(g_menu, MPROP_NEXTNAME, "Siguiente^n");
	menu_setprop(g_menu, MPROP_NUMBER_COLOR, "\r");
}

public show_menu_models(id, level)
{
	if (~get_user_flags(id) & level)
		return PLUGIN_CONTINUE;
	
	menu_display(id, g_menu);
	
	return PLUGIN_HANDLED;
}

public menu_models(id, menu, item)
{
	if(!(0 <= item <= g_size) || !is_user_connected(id))
		return PLUGIN_HANDLED;
	
	if (item == g_size)
	{
		cs_reset_user_model(id);
		client_print(id, print_chat, "Has elegido usar el model normal.");
	}
	else
	{
		new szModel[32];
		ArrayGetString(g_models, item, szModel, charsmax(szModel));
		cs_set_user_model(id, szModel);
		client_print(id, print_chat, "Ahora llevas un model personalizado.");
	}
	
	return PLUGIN_HANDLED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
