#include <amxmodx>
#include <engine>

#define PLUGIN "Hats"
#define VERSION "0.1"

new g_accesorio[33];
new g_cb_item_disabled;

new const info_nm[] = "_cm";

enum STRUCT_ACCESORIOS
{
	nombre[64],
	model[64],
	acceso
}

new const ACCESORIOS[][STRUCT_ACCESORIOS] =
{
	{ "Chocobo", 		"models/hats/chocobo_hat.mdl",		-1 },
	{ "Corona de reina",	"models/hats/crown_hat.mdl",		-1 },
	{ "KK Slider",	"models/hats/kk_hat.mdl",		-1 },
	{ "Luigi",	"models/hats/luigi_hat.mdl",		-1 },
	{ "Maker",		"models/hats/maker_hat.mdl",		-1 },
	{ "Hongo",		 	"models/hats/mushroom_hat.mdl",		-1 },
	//{ "Neon",	"models/hats/neon_hat.mdl",		-1 },
	{ "Neon",	"models/hats/neon_hat_gign.mdl",		-1 },
	{ "Pikachu",		"models/hats/pikachut.mdl",		-1 },
	{ "Slime",		"models/hats/slime_hat.mdl",		-1 },
	{ "Pony",		"models/hats/pony_v2.mdl",		-1 },
	{ "Yoshi",			"models/hats/yoshi_head.mdl",		-1 },
}

public plugin_precache()
{
	// Accesorios
	for (new i = 0; i < sizeof(ACCESORIOS); i++)
		precache_model(ACCESORIOS[i][model]);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	register_clcmd("say /hats", "show_menu_hats");
	register_clcmd("say /accesorios", "show_menu_hats");
	
	// Start hats
	new ent;
	for (new i = 1; i <= 32; i++)
	{
		ent = create_entity("info_target")
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW);
		entity_set_edict(ent, EV_ENT_owner, i);
		entity_set_string(ent, EV_SZ_classname, "zil_hat");
	}
	
	g_cb_item_disabled = menu_makecallback("cb_disabled");
}

public client_putinserver(id)
{
	set_task(4.0, "auto_set", id);
}

public auto_set(id)
{
	if (!is_user_connected(id) || g_accesorio[id])
	{
		return;
	}
	
	new info[33];
	get_user_info(id, info_nm, info, charsmax(info));
	
	new num, sznum[2];
	for (num = 0; num < 2; num++)
	{
		sznum[num] = info[num];
	}
	
	num = str_to_num(sznum);
	
	if (num)
	{
		if (get_user_flags(id) & ACCESORIOS[num-1][acceso])
		{
			g_accesorio[id] = num
			new ent = find_ent_by_owner(-1, "zil_hat", id);
			entity_set_model(ent, ACCESORIOS[num-1][model]);
			entity_set_edict(ent, EV_ENT_aiment, id);
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW);
			
			zp_colored_print(id, "^x04[Hats]^x01 Tu accesorio ha sido cargado (%c%s%c).", '^3', ACCESORIOS[num-1][nombre], '^1');
		}
		else
		{
			for (num = 0; num < 2; num++)
			{
				info[num] = 0;
			}
			
			set_user_info(id, info_nm, info);
			client_cmd(id, "setinfo ^"%s^" ^"%s^"", info_nm, info);
		}
	}
}

public client_disconnect(id)
{
	if (g_accesorio[id])
	{
		new ent = find_ent_by_owner(-1, "zil_hat", id);
		entity_set_model(ent, "");
		entity_set_edict(ent, EV_ENT_aiment, 0);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_origin(ent, Float:{8192.0,8192.0,8192.0});
		
		g_accesorio[id] = 0
	}
}

public show_menu_hats(id)
{
	new menutitle[90], flags;
	new menu = menu_create("\r[MultiMods] \yAccesorios", "menu_hats");
	
	flags = get_user_flags(id);
	
	formatex(menutitle, charsmax(menutitle), "%sRemover%s accesorio", g_accesorio[id] ? "\r" : "\d", g_accesorio[id] ? "\w" : "\d");
	menu_additem(menu, menutitle, .callback = g_accesorio[id] ? -1 : g_cb_item_disabled);
	
	for (new i = 0; i < sizeof(ACCESORIOS); i++)
	{
		if (flags & ACCESORIOS[i][acceso])
		{
			formatex(menutitle, charsmax(menutitle), "\w%s%s", ACCESORIOS[i][nombre], g_accesorio[id] == i+1 ? "\y [Seleccionado]" : "")
			menu_additem(menu, menutitle);
		}
		else
		{
			formatex(menutitle, charsmax(menutitle), "\y[Solo ADMIN]\d %s", ACCESORIOS[i][nombre])
			menu_additem(menu, menutitle, .callback = g_cb_item_disabled)
		}
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_BACKNAME, "Anterior")
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente")
	menu_setprop(menu, MPROP_EXITNAME, "\ySalir")
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public cb_disabled(id, menu, key)
{
	return ITEM_DISABLED;
}

public menu_hats(id, menu, key)
{
	if(!is_user_connected(id) || !(0 <= key <= sizeof(ACCESORIOS)))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(key == 0)
	{
		if (!g_accesorio[id]) zp_colored_print(id, "^x04[Hats]^x01 No llevas un accesorio.")
		else
		{
			new ent = find_ent_by_owner(-1, "zil_hat", id);
			entity_set_model(ent, "");
			entity_set_edict(ent, EV_ENT_aiment, 0);
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
			entity_set_origin(ent, Float:{8192.0,8192.0,8192.0});
			
			g_accesorio[id] = 0
			zp_colored_print(id, "^x04[Hats]^x01 Ahora no llevas un accesorio.")
			
			new info[33];
			get_user_info(id, info_nm, info, charsmax(info));
			
			for (new i = 0; i < 2; i++)
			{
				info[i] = 0;
			}
			
			set_user_info(id, info_nm, info);
			client_cmd(id, "setinfo ^"%s^" ^"%s^"", info_nm, info);
		}
	}
	else
	{
		g_accesorio[id] = key
		new ent = find_ent_by_owner(-1, "zil_hat", id);
		entity_set_model(ent, ACCESORIOS[key-1][model]);
		entity_set_edict(ent, EV_ENT_aiment, id);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW);
		
		new info[33];
		get_user_info(id, info_nm, info, charsmax(info));
		
		new sznum[3];
		num_to_str(key, sznum, 2); 
		for (new i = 0; i < 2; i++)
		{
			info[i] = sznum[i];
		}
		
		set_user_info(id, info_nm, info);
		client_cmd(id, "setinfo ^"%s^" ^"%s^"", info_nm, info);
		
		zp_colored_print(id, "^x04[Hats]^x01 Ahora llevas un accesorio (%c%s%c).", '^3', ACCESORIOS[key-1][nombre], '^1');
	}
	
	menu_destroy(menu)
	
	return PLUGIN_HANDLED;
}

stock zp_colored_print(id, const msg[], any:...)
{
	static message[191];
	vformat(message, 190, msg, 3);
	static msgSayText;
	if (!msgSayText)
		msgSayText = get_user_msgid("SayText");
	
	message_begin(id ? MSG_ONE : MSG_BROADCAST, msgSayText, _, id);
	write_byte(33);
	write_string(message);
	message_end();
}
