#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun> 
#include <polymorph>

#define FLAG_MENU ADMIN_KICK
#define PLUGIN "Menu Multimods"
#define VERSION "0.1"
#define AUTHOR "Mia2904"
#define FLAG_VIP	ADMIN_LEVEL_C
#define TASK_PARTICULAS 27777

enum STRUCT_ACCESORIOS
{
	nombre[64],
	model[64],
	acceso
}

new const ACCESORIOS[][STRUCT_ACCESORIOS] =
{
	{ "Peinado afro", 		"models/zombie_apocalypse/hat1.mdl",		-1 },
	{ "Sombrero de vaquero",	"models/zombie_apocalypse/hat2.mdl",		-1 },
	{ "Flecha en la cabeza",	"models/zombie_apocalypse/hat3.mdl",		-1 },
	{ "Auerola + alas de angel",	"models/zombie_apocalypse/hat4.mdl",		-1 },
	{ "Casco goauld",		"models/zombie_apocalypse/hat5.mdl",		-1 },
	{ "Arco",		 	"models/zombie_apocalypse/hat7.mdl",		-1 },
	{ "Cuernos + cola de demonio",	"models/zombie_apocalypse/hat8.mdl",		-1 },
	{ "Escudo del Cap. America",	"models/zombie_apocalypse/hat9.mdl",		-1 },
	{ "M�scara de Jason",		"models/zombie_apocalypse/hat11.mdl",		-1 },
	{ "Capa de Superman",		"models/zombie_apocalypse/hat12.mdl",		-1 },
	{ "Aud�fonos",			"models/zombie_apocalypse/hat13.mdl",		-1 },
	{ "Cabeza de Gara",		"models/zombie_apocalypse/hat14.mdl",		-1 },
	{ "Mascara scream",		"models/zombie_apocalypse/hat15.mdl",		-1 },
	{ "Naruto",			"models/zombie_apocalypse/hat17.mdl",		-1 },
	{ "Barril del Chavo",		"models/zombie_apocalypse/hat19.mdl",		-1 },
	{ "Cabeza de Sonic",		"models/zombie_apocalypse/hat20.mdl",		-1 },
	{ "Mascara de Darth Vader",	"models/zombie_apocalypse/hat21.mdl",		-1 },
	{ "Clon",			"models/zombie_infection/clon.mdl",		-1 },
	{ "Mascara de soldador",	"models/zombie_infection/svarshik.mdl",		-1 },
	{ "Nave",			"models/zombie_infection/Air_Tram2.mdl",	-1 },
	{ "Casco de futbol",		"models/zombie_infection/futbolista.mdl",	-1 },
	{ "Czerwony",			"models/zombie_infection/czerwony_sonic.mdl",	-1 },
	{ "Bomba",			"models/zombie_infection/bomba.mdl",		FLAG_VIP },
	{ "Sasuke",			"models/zombie_apocalypse/hat18.mdl",		FLAG_VIP },
	{ "Doom",			"models/zombie_infection/drdoom.mdl",		FLAG_VIP },
	{ "Cabeza de calabaza",		"models/zombie_apocalypse/hat10.mdl",		FLAG_VIP },
	{ "Sheih",			"models/zombie_infection/sheih.mdl",		FLAG_VIP },
	{ "Mascara de gas",		"models/zombie_infection/gazowa.mdl",		FLAG_VIP },
	{ "Zelazny",			"models/zombie_infection/zelazny.mdl",		FLAG_VIP },
	{ "Pony",			"models/zombie_infection/pony_v2.mdl",		FLAG_VIP },
	{ "Domo Alien",			"models/zombie_apocalypse/hat22.mdl",		ADMIN_IMMUNITY },
	{ "Cruz",			"models/zombie_apocalypse/hat6.mdl",		ADMIN_IMMUNITY },
	{ "Bandera ZIL",		"models/zombie_infection/zil_bandera.mdl",	ADMIN_IMMUNITY }
}

new g_accesorio[33];
new g_cb_item_disabled;

new g_synchud;
new g_modmenu;

new g_camera[33];
#define switch_speedometer(%0) g_camera[0]^=(1<<(%0&31))
#define set_speedometer(%0) g_camera[0]|=(1<<(%0&31))
#define clear_speedometer(%0) g_camera[0]&=~(1<<(%0&31))
#define get_speedometer(%0) (g_camera[0]&(1<<(%0&31)))

new g_bMuted[33], cvar_alltalk;
#define is_player_muted(%0,%1) (g_bMuted[%0]&(1 << %1&31))
#define switch_player_muted(%0,%1) g_bMuted[%0]^=(1<<%1&31)
#define clear_player_muted(%0,%1) g_bMuted[%0]&=~(1<<%1&31)
#define switch_mute_all(%0) g_bMuted[0]^=(1<<%0&31)
#define set_mute_all(%0) g_bMuted[0]|=(1<<%0&31)
#define clear_mute_all(%0) g_bMuted[0]&=~(1<<%0&31)
#define get_mute_all(%0) (g_bMuted[0]&(1<<%0&31))

new const info_nm[] = "_cgmm";

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
//new g_jb[33],g_dr[33],g_ffa[33],g_surf[33],g_sj[33],g_zp[33],g_bd[33],g_mr[33],g_gg[33]
new g_semiclip,g_particulas,g_parachute[33],g_disco[33] , g_knife[33]
new vwKNIFE[][] = {  "v_laserG", "v_laserR", "v_thunder", "v_xmen" }
new vwPLAYER[][] = { "vw_girl", "vw_saw", "vw_trollface","cuymagico_vw","vw_spirit" }

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Start speed entity
	new ent = create_entity("info_target");
	entity_set_string(ent, EV_SZ_classname, "speedometer");
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.25);
	register_think("speedometer", "speed_ent_think");
	g_synchud = CreateHudSyncObj();
	
	// Start hats
	for (new i = 1; i <= 32; i++)
	{
		ent = create_entity("info_target")
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW);
		entity_set_edict(ent, EV_ENT_owner, i);
		entity_set_string(ent, EV_SZ_classname, "zil_hat");
	}
	
	register_clcmd("say /hats", "show_menu_hats");
	register_clcmd("nightvision", "principal")
	register_cvar("amx_welcome",			"1");
	// Registros menu
	register_menu("Menu Usuarios",KEYSMENU,"menu_usuarios")
	register_menu("Menu Admin",KEYSMENU,"menu_admin")
	register_menu("Menu Moderacion",KEYSMENU,"menu_moderacion")
	register_menu("Menu Player", KEYSMENU, "menu_player")
	//register_menu("Menu Mods",KEYSMENU,"menu_modos")
	//register_menu("Menu Modos2",KEYSMENU,"menu_modos_next")	
	register_menu("Menu Vip",KEYSMENU, "menu_vip")
	register_menu("Menu Knife", KEYSMENU, "menu_knife")
	register_menu("Menu Player", KEYSMENU, "menu_player")
	//Glow Menu
	register_menucmd(register_menuid("\yGlow Menu:"), 1023, "GMenu1")

	//register_menucmd(register_menuid("Elige tu tipo de Camara"), 1023, "setview")
	RegisterHam( Ham_Item_Deploy, "weapon_knife", "Knife_Hook" , 1)
	
	register_forward(FM_Voice_SetClientListening, "fw_Voice");
	
	// Other
	g_cb_item_disabled = menu_makecallback("cb_disabled");
		
}

public plugin_cfg()
{
	set_task(0.5, "load_modmenu");
}

public load_modmenu()
{
	cvar_alltalk = get_cvar_pointer("sv_alltalk");
	
	g_modmenu = menu_create("\yMenu de Modos", "menu_modos");
	
	new count = polyn_get_mod_count();
	new name[64];
	for (new i = 0; i < count; i++)
	{
		polyn_get_mod_name(i, name, charsmax(name));
		menu_additem(g_modmenu, name);
	}
	
	menu_setprop(g_modmenu, MPROP_BACKNAME, "Anterior");
	menu_setprop(g_modmenu, MPROP_NEXTNAME, "Siguiente^n");
	menu_setprop(g_modmenu, MPROP_EXITNAME, "\yAtras");
}

/*================================================================================
 [General]
=================================================================================*/

public client_putinserver(id)
{
	load(id);
	
	// Auto seleccionar el hat
	set_task(4.0, "auto_set", id);
	set_task(4.0, "funcion_mensaje", id)
}

public client_disconnected(id)
{
	// Remover Hat
	if (g_accesorio[id])
	{
		new ent = find_ent_by_owner(-1, "zil_hat", id);
		entity_set_model(ent, "");
		entity_set_edict(ent, EV_ENT_aiment, 0);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_origin(ent, Float:{8192.0,8192.0,8192.0});
		
		g_accesorio[id] = 0
	}
	
	clear_speedometer(id);
	clear_mute_all(id);
	remove_task(id + TASK_PARTICULAS)
}

public cb_disabled(id, menu, key)
{
	return ITEM_DISABLED;
}
public funcion_mensaje(id)
{
	if(get_cvar_num("amx_welcome")==1)
	{
		new Name[32]
		get_user_name(id, Name, 31)
		ChatColor(id, "!g===================================================================")
		ChatColor(id, "!y Bienvenido !g%s!y a !gPeruGaming MultiModos", Name)
		ChatColor(id, "!y Visitanos en!g facebook.com/groups/PeruGamingCS/!y | Raidcall: !g12259533") 
		ChatColor(id, "!g===================================================================")
	}
}


public plugin_precache()
{	
	// Models
	precache_model("models/rpgrocket.mdl")
	precache_model("models/player/vw_spirit/vw_spiritT.mdl")
	
	new szKnifes[64]
	for(new i; i<sizeof vwKNIFE;i++)
	{
		formatex(szKnifes,sizeof szKnifes,"models/vw_knife/%s.mdl",vwKNIFE[i])
		precache_model(szKnifes)
	}
	new szModels[64]
	for(new i; i<sizeof vwPLAYER;i++)
	{
		formatex(szModels,sizeof szModels,"models/player/%s/%s.mdl",vwPLAYER[i],vwPLAYER[i])
		precache_model(szModels)
	}
	
	// Accesorios
	for (new i = 0; i < sizeof(ACCESORIOS); i++)
		precache_model(ACCESORIOS[i][model]);
}

/*================================================================================
 [Velocimetro]
=================================================================================*/

public speed_ent_think(ent)
{
	static id, Float:stime;
	id++;
	stime = halflife_time();
	if (id >= 32)
	{
		id = 0;
	}
	
	static target;
	static Float:velocity[3];
	static Float:speedh;
	
	if (get_speedometer(id))
	{
		target = entity_get_int(id, EV_INT_iuser1) != 4 ? id : entity_get_int(id, EV_INT_iuser2);
		entity_get_vector(target, EV_VEC_velocity, velocity);
		speedh = floatsqroot(floatpower(velocity[0], 2.0) + floatpower(velocity[1], 2.0));
		set_hudmessage(255, 255, 255, -1.0, 0.76, 0, 0.31, 0.31, 0.1, 0.2)
		ShowSyncHudMsg(id, g_synchud, "[%3.2f]", speedh);
	}
	
	entity_set_float(ent, EV_FL_nextthink, stime + 0.01);
}

public principal(id)
{
	new name[32]
	get_user_name(id, name, 31)
	static menu[999], slen = 0, slen2 = 0;
	new len
	
	if (!slen)
	{
		len = formatex(menu[len], sizeof menu - 1 - len, "\yComunidad \rwww.PeruGaming.tk MultiMods^n",VERSION)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yBienvenido a PeruGaming MultiMods \r%s^n",name )
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yMenu Usuarios^n^n")
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \wElegir Sombrero^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \wMutear a Alguien^n^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r3. \wCamara:\r [\y")
		slen2 = len;
		len += formatex(menu[len], sizeof menu - 1 - len, "               ^n");
		/*len += formatex(menu[len], sizeof menu - 1 - len, "\r4. \wVelocimetro:\r [");
		slen = len;*/
		len += formatex(menu[len], sizeof menu - 1 - len, "^n\r4. \wAdmins \rONLINE^n")
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\r5. \wMenu de \rAyuda^n^n")
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yMenu Admins^n^n")
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\r8. \wMenu \rVIPS^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r9. \wMenu de \rADMINS^n")
		
		
		formatex(menu[len], sizeof menu - 1 - len, "^n\r0. \wSalir")
	}
	
	copy(menu[slen2], 15, g_camera[id] ? g_camera[id] == 2 ? "Desde arriba\r]" : "3ra persona\r] " : "Normal\r]      ");
	menu[slen2 + 15] = '^n';
	
	/*copy(menu[slen], 8, get_speedometer(id) ? "\yON\r] " : "\wOFF\r]");
	menu[slen + 8] = '^n';*/
	
	show_menu(id, KEYSMENU, menu, -1, "Menu Usuarios")
}



public menu_usuarios(id,key)
{

	switch (key)
	{
		
		case 0:
		{
			show_menu_hats(id)
		}
		
		case 1:
		{
			show_menu_mute(id, 0)	
		}
		
		case 2:
		{
			g_camera[id]++;
			
			switch (g_camera[id])
			{
				case 0:
				{
					set_view(id, CAMERA_NONE);
				}
				case 1:
				{
					set_view(id, CAMERA_3RDPERSON);
				}
				case 2:
				{
					set_view(id, CAMERA_TOPDOWN);
				}
				case 3:
				{
					g_camera[id] = 0;
					set_view(id, CAMERA_NONE);
				}
			
			}
			
			principal(id);
		}
		/*case 3:
		{
			switch_speedometer(id);
			save(id);
			principal(id);
		}*/
		
		case 3: 
		{
			client_cmd(id,"mostrar_admins")
		}
		
		
		case 4: 
		{
			ChatColor(id, "!g[PeruGaming] !yVisita el Foro para poder ayudarte.")
		}
		
		case 7:
		{
			if (get_user_flags(id) & FLAG_VIP)
					show_menu_vip(id)
				else
					ChatColor(id, "!g[PeruGaming] !ySolo para VIPS y ADMIN")    //menu_vip(id)
			
		}
		
			
		case 8: {
			
			if(get_user_flags(id) & FLAG_MENU)
				show_menu_admin(id)
			else
				ChatColor(id, "!g[PeruGaming] !ySolo ADMINS!!!")
		}
		
	}
	return PLUGIN_HANDLED;
	
}

public auto_set(id)
{
	if (!is_user_connected(id) || !g_accesorio[id])
	{
		return;
	}
	
	new num = g_accesorio[id];
	
	if (get_user_flags(id) & ACCESORIOS[num-1][acceso])
	{
		new ent = find_ent_by_owner(-1, "zil_hat", id);
		entity_set_model(ent, ACCESORIOS[num-1][model]);
		entity_set_edict(ent, EV_ENT_aiment, id);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW);
		
		ChatColor(id, "^x04[PeruGaming]^x01 Tu accesorio ha sido cargado (%c%s%c).", '^3', ACCESORIOS[num-1][nombre], '^1');
	}
	else
	{
		g_accesorio[id] = 0;
		save(id);
	}
}

public show_menu_hats(id)
{
	new menutitle[90], flags;
	new menu = menu_create("\r[PeruGaming] \yAccesorios", "menu_hats");
	
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
			formatex(menutitle, charsmax(menutitle), "\y[Solo %s]\d %s", ACCESORIOS[i][acceso] == FLAG_VIP ? "VIP" : "ADMIN", ACCESORIOS[i][nombre])
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

public menu_hats(id, menu, key)
{
	if(!is_user_connected(id) || !(0 <= key <= sizeof(ACCESORIOS)))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(key == 0)
	{
		if (!g_accesorio[id]) ChatColor(id, "^x04[PeruGaming]^x01 No llevas un accesorio.")
		else
		{
			new ent = find_ent_by_owner(-1, "zil_hat", id);
			entity_set_model(ent, "");
			entity_set_edict(ent, EV_ENT_aiment, 0);
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
			entity_set_origin(ent, Float:{8192.0,8192.0,8192.0});
			
			g_accesorio[id] = 0
			save(id);
			
			ChatColor(id, "^x04[PeruGaming]^x01 Ahora no llevas un accesorio.")
		}
	}
	else
	{
		new ent = find_ent_by_owner(-1, "zil_hat", id);
		entity_set_model(ent, ACCESORIOS[key-1][model]);
		entity_set_edict(ent, EV_ENT_aiment, id);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW);
		
		g_accesorio[id] = key
		save(id);
		
		ChatColor(id, "^x04[PeruGaming]^x01 Ahora llevas un accesorio (%c%s%c).", '^3', ACCESORIOS[key-1][nombre], '^1');
	}
	
	menu_destroy(menu)
	
	return PLUGIN_HANDLED;
}

show_menu_mute(id, page)
{
    static i, players[32], num, menu, szItem[46], szData[1];
    menu = menu_create("\r[P�ruGaming]\y Menu de Mute", "menu_mute");
    
    menu_additem(menu, get_mute_all(id) ? "\wMutear a todos\r [\yON\r]" : "\wMutear a todos\r [\dOFF\r]");
    
    if (!(num = get_pcvar_num(cvar_alltalk)))
        get_user_team(id, szItem, 11);
    
    get_players(players, num, num ? "" : "e", num ? "" : szItem);
    
    for (new a = 0; a < num; a++)
    {
        i = players[a];
        
        get_user_name(i, szItem, 31);
        
        if (!get_mute_all(id) && is_player_muted(id, i))
            add(szItem, charsmax(szItem), "\y [Muteado]");
        
        szData[0] = i;
        
        menu_additem(menu, szItem, szData, 0, (get_mute_all(id) || id == i) ? g_cb_item_disabled : -1);
    }
    
    menu_setprop(menu, MPROP_BACKNAME, "Atras");
    menu_setprop(menu, MPROP_NEXTNAME, "Siguiente^n");
    menu_setprop(menu, MPROP_EXITNAME, "\ySalir");
    
    menu_display(id, menu, page);
}

public menu_mute(id, menu, item)
{
	switch (item)
	{
		case 0:
		{
			switch_mute_all(id);
		}
		case MENU_EXIT:
		{
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		default:
		{
			new szData[1], Junk;
		    
			menu_item_getinfo(menu, item, Junk, szData, sizeof(szData), .callback = Junk);
		    
			switch_player_muted(id, szData[0])
		}
	}
	    
	show_menu_mute(id, item/7);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
} 

public fw_Voice(id, sender, listen)
{
	if (id != sender && (get_mute_all(id) || is_player_muted(id, sender)))
	{
		engfunc(EngFunc_SetClientListening, id, sender, 0);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public show_menu_admin(id){
	
	if (!(get_user_flags(id) & FLAG_MENU)) return;
	
	
	static menu[999], len
	new name[32]
	
	get_user_name(id, name, 31)
	len = 0
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yBienvenido Admin :\r%s ^n^n",name)
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yMenu Admins^n^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \wComenzar VoteMod^n^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \wMenu de Modos^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r3. \wMenu de Mapas^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r4. \wMenu de Moderacion^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r5. \wMenu de Revivir^n^n")
	if(g_parachute[id] == 0)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r6. \wParacaidas \r[Desactivado]^n")
	else
		len += formatex(menu[len], sizeof menu - 1 - len, "\r6. \wParacaidas \y[Activado]^n")
	
	/*
	if(g_sxe[id] == 0)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r6. \wsXe Injected \r[Desactivado]^n")
	else if(g_sxe[id] == 1)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r6. \wsXe Injected \y[Requerido]^n")
	else if(g_sxe[id] == 2)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r6. \wsXe Injected \y[Opcional]^n")
		*/
	
	if(!g_semiclip)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r7. \wModo Semiclip \r[Desactivado]^n")
	else
		len += formatex(menu[len], sizeof menu - 1 - len, "\r7. \wModo Semiclip \y[Activado]^n")
	
	
	if(g_disco[id] == 0)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r8. \wModo Disco \r[Desactivado]^n^n")
	else
		len += formatex(menu[len], sizeof menu - 1 - len, "\r8. \wModo Disco \y[Activado]^n^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r9. \wAtras^n")
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r0. \wSalir")
	
	show_menu(id, KEYSMENU, menu, -1, "Menu Admin")
	
}


public menu_admin(id, key){
	new name[32]
	get_user_name(id, name, 31)
	switch (key){
		case 0: 
		{
			console_cmd(id,"amx_votemod")
			ChatColor(0, "!g[PeruGaming] !yEl ADMIN !g%s !yha Activado: !gVoteMod", name)
		}
		case 1:
		{
			show_menu_modos(id)
		}
		case 2:
		{ 
			polyn_show_map_menu(id)
		}
		
		case 3: 
		{
			show_menu_moderacion(id)
		}
		case 4: 
		{
			show_menu_revivir(id)
		}
		case 5:
		{
			if(g_parachute[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_cvar sv_parachute 1")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[PeruGaming] !yEl ADMIN !g%s !yha Activado: !gParacaidas", name)
				g_parachute[id] = 1
				show_menu_admin(id)
			}
			else
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_cvar sv_parachute 0")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[PeruGaming] !yEl ADMIN !g%s !yha Desactivado: !gParacaidas", name)
				g_parachute[id] = 0
				show_menu_admin(id)
			}
			
		}
		/*
		case 5:
		{
			if(g_sxe[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_cvar __sxei_required 1")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yEl ADMIN !g%s !yha Activado sXe Injected en Modo: !gRequerido", name)
				g_sxe[id] = 1
				show_menu_admin(id)
			}
			else if(g_sxe[id] == 1)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_cvar __sxei_required 0")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yEl ADMIN !g%s !yha Activado sXe Injected en Modo: !gOpcional", name)
				g_sxe[id] = 2
				show_menu_admin(id)
			}
			else if(g_sxe[id] == 2)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_cvar __sxei_required -1")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yEl ADMIN !g%s !yha Desactivado sXe Injected", name)
				g_sxe[id] = 0
				show_menu_admin(id)
			}  
			
		}
		*/
		case 6:
		{
			if(!g_semiclip)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_cvar semiclip 1")
				server_cmd("amx_show_activity 2")
				g_semiclip = true
				show_menu_admin(id)
			}
			else 
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_cvar semiclip 0")
				server_cmd("amx_show_activity 2")
				g_semiclip = false
				show_menu_admin(id)
			}
			
			
			
		}
		case 7:
		{
			
			if(g_disco[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_disco 1")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[PeruGaming] !yEl ADMIN !g%s !yha Activado !gModo Disco", name)
				g_disco[id] = 1
				show_menu_admin(id)
			}
			else
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_disco 0")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[PeruGaming] !yEl ADMIN !g%s !yha Desactivado !gModo Disco", name)
				g_disco[id] = 0
				show_menu_admin(id)
			}
			
		}
		case 8:
		{ 
			principal(id)
		}
	}
	return PLUGIN_HANDLED;
}

show_menu_revivir(id)
{
    if(!(get_user_flags(id) & ADMIN_LEVEL_H))
    {
        client_print(id,print_chat,"No tienes acceso a este comando")
        return
    }
    new menu = menu_create("\rElegir jugador:","handle_menu_revivir")
    new temp2[2],player[32]

    for (new i = 1; i <= get_maxplayers(); i++)
    {
        if(is_user_alive(i) || !is_user_connected(i))
            continue
        get_user_name(i,player,charsmax(player))
        num_to_str(i,temp2,1)
        menu_additem(menu,player,temp2)
    }
    menu_setprop(menu, MPROP_EXITNAME, "Salir")
    menu_display(id,menu,0)
}

public handle_menu_revivir(id,menu,item)
{
    if(!is_user_connected(id))
    {
        menu_destroy(menu)
        return 
    }
    if(item == MENU_EXIT)
    {
        show_menu_admin(id)
        menu_destroy(menu)
        return 
    }
    static ac, cb, accion[15], name[33], i, id2,szname[33]
    menu_item_getinfo(menu, item, ac, accion, charsmax(accion), name, charsmax(name), cb)
    
    for (i = 1; i <= get_maxplayers(); i++)
    {
        if (is_user_alive(i) || !is_user_connected(i) ) continue
        
        get_user_name(i,szname,charsmax(szname))
        if (equal(name, szname))
        {
            id2 = i
            break
        }
        
        else id2 = 0
    }
    if (!id2)
    {
        client_print(id,print_chat, "No se encontro el jugador seleccionado")
        show_menu_revivir(id)
        return 
    }
    ExecuteHamB(Ham_CS_RoundRespawn, id2)
    get_user_name(id, szname, 31);
    ChatColor(0, "^x04[PeruGaming]^x01 El ADMIN %s ha revivido a^x03 %s", szname, name);
} 

show_menu_modos(id)
{
	menu_display(id, g_modmenu);
}

public menu_modos(id, menu, item)
{
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT)
	{
		show_menu_admin(id);
		return PLUGIN_HANDLED;
	}
	
	new count = polyn_get_submode_count(item);
	new name[64]
	
	if (count)
	{
		new menu = menu_create("\yElegir submodo:", "menu_submodo");
		polyn_get_submode_name(item, 1, name, charsmax(name));
		
		new data[1];
		data[0] = item;
		menu_additem(menu, name, data);
		
		for (new i = 2; i <= count; i++)
		{
			polyn_get_submode_name(item, i, name, charsmax(name));
			menu_additem(menu, name);
		}
		
		menu_setprop(menu, MPROP_PERPAGE, 0);
		menu_setprop(menu, MPROP_EXITNAME, "\yAtras");
		menu_display(id, menu);
	}
	else
	{
		polyn_set_next_mod(item);
		polyn_get_mod_name(item, name, charsmax(name))
		ChatColor(id, "!g[PeruGaming]!y El siguiente modo sera^x03 %s!y. Cambie el mapa para iniciarlo.", name);
		show_menu_admin(id);
	}
	
	return PLUGIN_HANDLED;
}

public menu_submodo(id, menu, item)
{
	if (!is_user_connected(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		show_menu_admin(id);
		return PLUGIN_HANDLED;
	}
	
	new data[2], junk;
	menu_item_getinfo(menu, 0, junk, data, 1, "", 0, junk);
	
	polyn_set_next_mod(data[0]);
	polyn_set_next_submode(item + 1);
	
	new name[2][32]
	
	polyn_get_mod_name(data[0], name[0], charsmax(name[]))
	polyn_get_submode_name(data[0], item + 1, name[1], charsmax(name[]))
	ChatColor(id, "!g[PeruGaming]!y El siguiente modo sera^x03 %s - %s!y. Cambie el mapa para iniciarlo.", name[0], name[1]);
	show_menu_admin(id);
	
	menu_destroy(menu)
	return PLUGIN_HANDLED;
}

/*
public show_menu_modos(id){
	
	static menu[999], len
	len = 0
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yMenu de Modos VirtualWorld [1-2] ^n^n" )
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \wMod JailBreak^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \wMod Deathrun^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r3. \wMod Soccerjam^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r4. \wMod Captura La Banderas^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r5. \wMod Base Builder^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r6. \wMod Super Hero^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r7. \wMod FFA/VIP^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r8. \wMod Rubaka^n^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r9. \wSiguiente^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r0. \wSalir")
	
	show_menu(id, KEYSMENU, menu, -1, "Menu Mods")
}

public menu_modos(id, key){
	new name[32]
	get_user_name(id, name, 31)
	switch (key){
		
		case 0 : 
		{ 
			if(g_jb[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 1")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gJailbreak", name)
				g_jb[id] = 1
				show_menu_modos(id)
			}
			else
				
			
			ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
			
			
		}
		case 1 :
		{ 
			if(g_dr[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 4")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gDeathRun", name)
				g_dr[id] = 1
				show_menu_modos(id)
			}
			else
				ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
		}
		case 2 :
		{ 
			if(g_sj[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 8")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gSoccerjam", name)
				g_sj[id] = 1
				show_menu_modos(id)
			}
			else
				
			ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
		}
		case 3 :
		{ 
			if(g_bd[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 7")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gCaptura La Bandera", name)
				g_bd[id] = 1
				show_menu_modos(id)
			}
			else
				
			ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
		}
		
		case 4 :
		{ 
			if(g_mr[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 9")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gBase Builder", name)
				g_mr[id] = 1
				show_menu_modos(id)
			}
			else
				
			ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
		}
		
		case 5 :
		{ 
			if(g_surf[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 3")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gSuper Hero", name)
				g_surf[id] = 1
				show_menu_modos(id)
			}
			else
				
			ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
		}
		case 6 :
		{ 
			if(g_ffa[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 2")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gFFA/VIP", name)
				g_ffa[id] = 1
				show_menu_modos(id)
			}
			else
				
			ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
		}
		case 7 : 
		{ 
			if(g_zp[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 6")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gRubaka", name)
				g_zp[id] = 1
				show_menu_modos(id)
			}
			else
				
			ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
		}
		case 8 :
		{
			show_menu_modos2(id)
		}
		
		
	}
	

	

	
	return PLUGIN_HANDLED;
	
	
}

public show_menu_modos2(id){
	
	static menu[999], len
	len = 0
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yMenu de Modos VirtualWorld [2-2] ^n^n" )
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \wMod GunGame^n^n^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r9. \wAtras^n")
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r0. \wSalir")
	
	show_menu(id, KEYSMENU, menu, -1, "Menu Modos2")
}

public menu_modos_next(id, key){
	new name[32]
	get_user_name(id, name, 31)
	switch (key){
		
		case 0 : 
		{ 
			if(g_gg[id] == 0)
			{
				server_cmd("amx_show_activity 0")
				server_cmd("amx_smod 5")
				server_cmd("amx_show_activity 2")
				ChatColor(0, "!g[VirtualWorld] !yADMIN !g%s !yha Activado el Modo !gGunGame", name)
				g_gg[id] = 1
				show_menu_modos2(id)
			}
			else
				
			ChatColor(id, "!g[VirtualWorld] !yNo puedes activar un Modo si ya se esta Ejecutando.")
			
		}
		case 8 :
		{
			show_menu_modos(id)
		}
		
	}
	
	return PLUGIN_HANDLED;
	
	
}*/

public show_menu_moderacion(id){
	
	
	static menu[999], len
	len = 0
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yMenu Moderacion ^n^n" )
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \wExpulsar Jugador^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \wBanear Jugador^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r3. \wSlapear/Matar Jugador^n")		
	len += formatex(menu[len], sizeof menu - 1 - len, "\r4. \wEquipo del Jugador^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r5. \wRevivir Jugador^n^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r6. \wCambiar de Mapa^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r7. \wVotacion de Mapas^n^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r9. \wAtras^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r0. \wSalir")
	
	show_menu (id, KEYSMENU, menu, -1, "Menu Moderacion")
}

public menu_moderacion(id,key){
	
	switch(key){
		case 0:{
			client_cmd(id, "amx_kickmenu")
		}
		case 1: {
			client_cmd(id, "amx_banmenu")
		}
		case 2:{
			client_cmd(id,"amx_slapmenu")			
		}	
		case 3:{
			client_cmd(id,"amx_teammenu")
		}	
		case 4:{
			client_cmd(id,"amx_revivemenu")
		}	
		case 5:{
			client_cmd(id,"amx_mapmenu")
		}	
		case 6:{
			client_cmd(id,"amx_votemapmenu")	
		}
		case 8:
		{
			show_menu_admin(id)
		}
		
	}
	
	return PLUGIN_HANDLED
	
	
}
public show_publicidad(id){
	
	set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, -1.0, 1, 6.0, 3.0)
	show_hudmessage(0, "Visitanos en Facebook o en nuestra pagina:^nwww.PeruGaming.tk")
	set_task(1.0, "hud2")
	
}

public show_ayuda(id){
	ChatColor(id, "!g[VirtualWorld] !yEscribe /sayrules para ver las reglas o consultalas a un admin")
	
}
public show_menu_knife(id)
{
		static menu[999], len
		len = 0
	
		len += formatex(menu[len], sizeof menu - 1 - len, "\yMenu de KNIFE^n^n")
	
		len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \wKnife Laser Verde^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \wKnife Laser Rojo^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r3. \wKnife Thunder^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r4. \wX-MEN Knife^n")
	
		len += formatex(menu[len], sizeof menu - 1 - len, "^n\r9. \wAtras")
	
		show_menu(id, KEYSMENU, menu, -1, "Menu Knife")
}

public menu_knife(id, key)
{
	switch (key)
	{
		case 0: g_knife[id] = 1, ChatColor(id, "!g[PeruGaming] !yHas Elegido Knife Laser Verde."),show_menu_knife(id)
		case 1: g_knife[id] = 2, ChatColor(id, "!g[PeruGaming] !yHas Elegido Knife Laser Rojo."),show_menu_knife(id)
		case 2: g_knife[id] = 3, ChatColor(id, "!g[PeruGaming] !yHas Elegido Knife Thunder."),show_menu_knife(id)
		case 3: g_knife[id] = 4, ChatColor(id, "!g[PeruGaming] !yHas Elegido X-MEN Knife."),show_menu_knife(id)
		case 8: show_menu_vip(id)
	}
    
	return PLUGIN_HANDLED
}

public uqz_particulas(id)
{
    id -= TASK_PARTICULAS
    
    if (!is_user_alive(id))
        return
    
    static Float:Origin[3]
    pev(id, pev_origin, Origin)

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0) 
    write_byte(TE_IMPLOSION) 
    engfunc(EngFunc_WriteCoord, Origin[0]) 
    engfunc(EngFunc_WriteCoord, Origin[1])
    engfunc(EngFunc_WriteCoord, Origin[2]) 
    write_byte(128)
    write_byte(48)
    write_byte(2)
    message_end()
}

public showReviveMenu(id)
{
	new iMenu = menu_create("Revive Menu", "handleReviveMenu");
	new iPlayers[32], iNum, iTemp, iName[32], iAuth[35];
	get_players(iPlayers, iNum);
	
	for( new i; i < iNum; i++ )
	{
		iTemp = iPlayers[i];
		get_user_name(iTemp, iName, charsmax(iName));
		num_to_str(iTemp, iAuth, charsmax(iAuth));
		
		menu_additem(iMenu, iName, iAuth, ADMIN_KICK);
	}
	
	menu_display(id, iMenu, 0);
}

public handleReviveMenu(id, iMenu, iItem)
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}
	
	new iData[6], iName[64];
	new access, iCallback;
	menu_item_getinfo(iMenu, iItem, access, iData, charsmax(iData), iName, charsmax(iName), iCallback);
	
	new iTemp = str_to_num(iData);
	new iTempName[33], iAdmin[33];
	get_user_name(id, iAdmin, charsmax(iAdmin));
	get_user_name(iTemp, iTempName, charsmax(iTempName));
	
	ExecuteHamB(Ham_CS_RoundRespawn, iTemp);
	ChatColor(0, "!g[PeruGaming] !yADMIN: !g%s !yRevivio a !g%s ", iAdmin, iTempName );	
	
	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

  
public show_menu_vip(id){
	
	
	static menu[999], len
	len = 0
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r-> \yMenu Vip^n^n" )
	
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \wMenu Models^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \wMenu Cuchillos^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r3. \wGlow Menu^n")		
	len += formatex(menu[len], sizeof menu - 1 - len, "\r4. \wMenu Fuegos Artificiales^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r5. \r[Activar] \wParticulas^n^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r6. \rPublicidad Server^n^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r9. \wAtras^n")
	
	show_menu (id, KEYSMENU, menu, -1, "Menu Vip")
}

public menu_vip(id,key){
	
	switch(key){
		case 0 :{
			show_menu_player(id)
		}
		case 1 :{
			show_menu_knife(id)
		}
		case 2 :{
			GlowMenu(id)
		}		
		case 3 :{
			console_cmd(id,"fireworks")
		}		
		case 4 :
		{
		
				if(!g_particulas)
				{
					set_task(0.1, "uqz_particulas", id + TASK_PARTICULAS, _, _, "b")
					g_particulas = true
					show_menu_vip(id)
				}
				else
				{
					remove_task(id + TASK_PARTICULAS)
					g_particulas = false
					show_menu_vip(id)
				}
			}
	
		case 5 :{
			show_publicidad(id)
		}		
		case 8 :{
			principal(id)
		}
	}
	
	return PLUGIN_HANDLED
	
	
}

public show_menu_player(id)
{
		static menu[999], len
		len = 0
	
		len += formatex(menu[len], sizeof menu - 1 - len, "\yMenu de Models^n^n")
	
		len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \wChica VirtualWorld^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \wSaw^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r3. \wTrollFace^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r4. \wCuy Magico VirtualWorld^n")
		len += formatex(menu[len], sizeof menu - 1 - len, "\r5. \wSpirit^n")
	
		len += formatex(menu[len], sizeof menu - 1 - len, "^n\r9. \wAtras")
	
		show_menu(id, KEYSMENU, menu, -1, "Menu Player")
}


public menu_player(id, key)
{
	new name[32]
	get_user_name(id, name, 31)
	switch (key)
	{
		case 0: cs_set_user_model(id,"vw_girl"), ChatColor(id, "!g[PeruGaming] !yHaz elegido !gChica VirtualWorld")
		case 1: cs_set_user_model(id,"vw_saw"), ChatColor(id, "!g[PeruGaming] !yHaz elegido !gSaw")
		case 2: cs_set_user_model(id,"vw_trollface"), ChatColor(id, "!g[PeruGaming] !yHaz elegido !gTrollFace")
		case 3: cs_set_user_model(id,"cuymagico_vw"), ChatColor(id, "!g[PeruGaming] !yHaz elegido !gCuy Magico")
		case 4: cs_set_user_model(id,"vw_spirit"), ChatColor(id, "!g[PeruGAming] !yHaz elegido !gSpirit")
		case 8: show_menu_vip(id)

	}
    
	return PLUGIN_HANDLED
}  

public Knife_Hook(Knife)
{
	new id = get_pdata_cbase(Knife, 41, 4);
	
	switch(g_knife[id])
	{
		case 0: set_pev( id, pev_viewmodel2, "models/v_knife.mdl" )
		case 1: set_pev( id, pev_viewmodel2, "models/vw_knife/v_laserG.mdl" )
		case 2: set_pev( id, pev_viewmodel2, "models/vw_knife/v_laserR.mdl" )
		case 3: set_pev( id, pev_viewmodel2, "models/vw_knife/v_thunder.mdl" )
		case 4: set_pev( id, pev_viewmodel2, "models/vw_knife/v_xmen.mdl" )
	}
}
	
public Red(id){
	ChatColor(id, "!g[PeruGaming] !yHaz Seleccionado !gGlow Rojo")
	set_user_rendering(id, kRenderFxGlowShell,255,0,0,kRenderFxNone,0)
	GlowMenu(id)
}

public Yellow(id){
	ChatColor(id, "!g[PeruGaming] !yHaz Seleccionado !gGlow Amarillo")
	set_user_rendering(id,kRenderFxGlowShell,255,255,0,kRenderFxNone,0)
	GlowMenu(id)
}

public Green(id){
	ChatColor(id, "!g[PeruGaming] !yHaz Seleccionado !gGlow Verde")
	set_user_rendering(id,kRenderFxGlowShell,18,166,122,kRenderFxNone,0)
	GlowMenu(id)
}

public Orange(id){
	ChatColor(id, "!g[PeruGaming] !yHaz Seleccionado !gGlow Naranja")
	set_user_rendering(id,kRenderFxGlowShell,255,145,26,kRenderFxNone,0)
	GlowMenu(id)
}

public Blue(id){
	ChatColor(id, "!g[PeruGaming] !yHaz Seleccionado !gGlow Azul")
	set_user_rendering(id,kRenderFxGlowShell,0,64,255,kRenderFxNone,0)
	GlowMenu(id)
}

public LBlue(id){
	ChatColor(id, "!g[PeruGaming] !yHaz Seleccionado !gGlow Celeste")
	set_user_rendering(id,kRenderFxGlowShell,0,176,255,kRenderFxNone,0)
	GlowMenu(id)
}

public Pink(id){
	ChatColor(id, "!g[PeruGaming] !yHaz Seleccionado !gGlow Rosado")
	set_user_rendering(id,kRenderFxGlowShell,255,51,255,kRenderFxNone,0)
	GlowMenu(id)
}

public GlowMenu(id)
{
		new szMenuBody[512]
		new keys
		new len
		len = format(szMenuBody,511,"\yGlow Menu:^n" )
		len += format( szMenuBody[len],511-len,"^n\r1. \yGlowing \wRojo" )
		len += format( szMenuBody[len],511-len,"^n\r2. \yGlowing \wAmarillo" )
		len += format( szMenuBody[len],511-len,"^n\r3. \yGlowing \wVerde" )
		len += format( szMenuBody[len],511-len,"^n\r4. \yGlowing \wNaranja" )
		len += format( szMenuBody[len],511-len,"^n\r5. \yGlowing \wAzul" )
		len += format( szMenuBody[len],511-len,"^n\r6. \yGlowing \wCeleste" )
		len += format( szMenuBody[len],511-len,"^n\r7. \yGlowing \Rosado" )
		len += format( szMenuBody[len],511-len,"^n^n\r9. \wAtras" )
		keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<8)
		show_menu( id, keys, szMenuBody, -1 )
}	

public GMenu1(id,key) {

	switch(key) {
		case 0: Red(id)
		case 1: Yellow(id)
		case 2: Green(id)
		case 3: Orange(id)
		case 4: Blue(id)
		case 5: LBlue(id)
		case 6: Pink(id)
		case 8: show_menu_vip(id)
	}

	return PLUGIN_HANDLED
}

load(id)
{
	new data[33];
	get_user_info(id, info_nm, data, charsmax(data));
	
	new accesorio[3];
	accesorio[0] = data[0];
	accesorio[1] = data[1];
	g_accesorio[id] = str_to_num(accesorio);
	
	data[2] -= 48;
	if (!(0 <= data[2] < 4))
	{
		data[2] = 0;
	}
	
	if (data[2] / 2)
	{
		set_speedometer(id);
	}
	else
	{
		clear_speedometer(id);
	}
	
	if (data[2] % 2)
	{
		set_mute_all(id);
	}
	else
	{
		clear_mute_all(id);
	}
}

save(id)
{
	new info[33];
	
	formatex(info, 2, "%d", g_accesorio[id]);
	
	info[2] = 48 + _:!!(get_mute_all(id));
	if (get_speedometer(id))
	{
		info[2] += 2;
	}
	
	set_user_info(id, info_nm, info);
	client_cmd(id, "setinfo ^"%s^" ^"%s^"", info_nm, info);
}
	
/*================================================================================
[ Stocks ]
=================================================================================*/
/*=================================================================================*/
stock ChatColor(const id, const input[], any:...)
{
	static msg[191];
	vformat(msg, 190, input, 3);
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!team", "^3") // Team Color
	
	static msgSayText;
	if (!msgSayText)
		msgSayText = get_user_msgid("SayText");
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgSayText, _, id);
	write_byte(33);
	write_string(msg);
	message_end();
}

/*=================================================================================*/  
