#include <amxmodx>

#define PLUGIN "Sistema de Party"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

#define is_user_valid_connected(%1) (1 <= %1 <= 32 && g_connected & (1<<%1-1))
#define is_user_valid(%1) (1 <= %1 <= 32)
#define user_has_party(%1) (0 <= g_party[%1] < PARTY_LIMIT)
#define party_master(%1) (g_partymembers[%1][0])

new g_MsgSync5, g_msgSayText, g_connected, g_playername[33][32];

// Cantidad maxima de jugadores en un equipo
const PARTY_MAX_USERS = 5

// Cantidad de equipos que se pueden crear
const PARTY_LIMIT = 15

// Maxima cantidad de caracteres para el nombre del party
const PARTY_NAME_LENGTH = 32;

// Party
new g_party[33] // Almacenar el party del jugador
new g_partymembers[PARTY_LIMIT][PARTY_MAX_USERS] // IDs de los miembros del party
new g_partyname[PARTY_LIMIT][PARTY_NAME_LENGTH] // Nombres de los party
new g_party_list_index[33][33]

public plugin_natives()
{
	register_native("menu_party_display", "native_show_menu_party", 1);
	register_native("get_user_party", "native_get_user_party", 1);
	register_native("get_party_name", "native_get_party_name", 0);
	register_native("get_party_users_alive", "native_get_party_users_alive", 1);
}

public native_check_party_users(plugin, params)
{
	new count
	static id, party, player;
	player = get_param(1);
	party = g_party[player];
	
	if (!party_master(party) || !(0 <= party < PARTY_LIMIT))
		return 0;
	
	static players[32];
	
	for (new i = 0; i < PARTY_MAX_USERS; i++)
	{
		id = g_partymembers[party][i]
		if (is_user_valid_connected(id) && is_user_alive(id))
		{
			players[count] = id;
			count++;
		}
	}
	
	set_array(2, players, 32);
	set_param_byref(3, count);
	
	return 1;
}

public native_get_party_name(plugin, params)
{
	new party = get_param(1)-1;
	
	if (!party_master(party))
		return 0;
	
	set_string(2, g_partyname[party], get_param(3));
	
	return 1;
}

public native_get_user_party(id)
{
	return g_party[id]+1;
}

public native_show_menu_party(id)
{
	show_menu_party(id);
}

public plugin_init()
{
	register_menucmd(register_menuid("Party Main Menu", 0), (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4), "menu_party");
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /party", "show_menu_party");
	register_clcmd("Nombre_Del_Equipo", "party_input")
	
	g_MsgSync5 = CreateHudSyncObj();
	
	g_msgSayText = get_user_msgid("SayText");
	
	arrayset(g_party, -1, 33);
}

public client_putinserver(id)
{
	g_connected |= (1<<id-1);
	// Cache player's name
	get_user_name(id, g_playername[id], charsmax(g_playername[]));
}

public client_disconnect(id)
{
	g_connected &= ~(1<<id-1);
	remove_from_party(id);
	g_party[id] = -1;
}

/*================================================================================
 [Sistema de Party]
=================================================================================*/

// Menu de party
public show_menu_party(id)
{
	static menu[200], len
	new party
	party = g_party[id]
	
	len = formatex(menu, charsmax(menu), "\rMenu de Equipo^n")
	
	if (-1 < party < PARTY_LIMIT)
	{
		len += formatex(menu[len], charsmax(menu), "\yEstas en el equipo:\r %s^n^n", g_partyname[party])
		
		if (party_master(party) == id)
		{
			g_party_list_index[0][id] = 2
			party = party_users(party)
			
			new bool:boolean = get_players_noparty() ? true : false;
			len += formatex(menu[len], charsmax(menu), "%sInvitar al party^n%sExpulsar del equipo", party >= PARTY_MAX_USERS ? "\d1. (Party lleno) " : boolean ? "\r1. \w" : "\d1. ", party > 1 ? "\r2. \w" : "\d2. ")
			len += formatex(menu[len], charsmax(menu), "^n\r3. \wCambiar nombre del equipo^n\r4. \wAbandonar el equipo^n^n\r5. \ySalir")
			len = (1<<2)|(1<<3)|(1<<4)
			
			if (boolean)
				len |= (1<<0);
			
			if (party > 1)
				len |= (1<<1);
		}	
		else
		{
			g_party_list_index[0][id] = 1
			len += formatex(menu[len], charsmax(menu), "\w�Deseas abandonar el equipo?^n^n\r1. \wSi^n\r2.\w No")
			len = (1<<0)|(1<<1)
		}
	}
	else
	{
		g_party_list_index[0][id] = 0
		party = party_count()
		len += formatex(menu[len], charsmax(menu), "\yNo estas en un equipo.^n^n")
		len += formatex(menu[len], charsmax(menu), "%sUnirse a un party^n%sCrear un equipo", party > 0 ? "\r1. \w" : "\d1. (No hay) ", party >= PARTY_LIMIT ? "\d2. (Slots agotados) " : "\r2. \w")
		len += formatex(menu[len], charsmax(menu), "^n^n\r3. \ySalir.")
		
		len = (1<<2)
		
		if (party > 0)
			len |= (1<<0)
		
		if (party < PARTY_LIMIT)
			len |= (1<<1)
		
	}
	
	show_menu(id, len, menu, -1, "Party Main Menu")
}

public menu_party(id, key)
{
	key += (g_party_list_index[0][id]*3)
	
	switch(key)
	{
		case 0:
		{
			if(party_count()) show_menu_party_list(id)
			else show_menu_party(id)
		}
		case 1:
		{
			if(party_count() < PARTY_LIMIT)
			{
				client_cmd(id, "messagemode ^"Nombre_Del_Party^"");
				set_hudmessage(0, 255, 255, 0.03, 0.25, 0, 1.0, 4.0, 0.01, 0.01, -1)
				ShowSyncHudMsg(id, g_MsgSync5, "Ingresa un nombre para el Equipo^nPulsa ESC para salir")
				
			}
			else show_menu_party(id)
		}
		case 2: return;
		case 3: remove_from_party(id)
		case 4: return;
		case 6:
		{
			if(party_users(g_party[id]) < PARTY_MAX_USERS && get_players_noparty()) show_menu_players_noparty(id)
			else show_menu_party(id)
		}	
		case 7:
		{
			if(party_users(g_party[id]) > 1) show_menu_players_inparty(id)
			else show_menu_party(id)
		}
		case 8:
		{
			client_cmd(id, "messagemode ^"Nombre_Del_Equipo^"");
			set_hudmessage(0, 255, 255, -1.0, 0.05, 0, 0.1, 4.0, 0.01, 0.01, -1)
			ShowSyncHudMsg(id, g_MsgSync5, "Ingresa un nombre para el Equipo^nPulsa ESC para salir")
		}
		case 9: remove_from_party(id)
	}
}

show_menu_party_list(id)
{
	new buffer[PARTY_NAME_LENGTH+12], i, users, count, menu
	menu = menu_create("\yElegir un Party", "menu_party_list")
	
	for (i = 0; i < PARTY_LIMIT; i++)
	{
		if (is_user_valid_connected(party_master(i)))
		{
			g_party_list_index[id][count] = i
			count++
			buffer[0] = 0
			users = party_users(i)
			formatex(buffer, charsmax(buffer), "%s%s \y[%d/%d]", users < PARTY_MAX_USERS ? "\w" : "\d", g_partyname[i], users, PARTY_MAX_USERS)
			menu_additem(menu, buffer, "", 0)
		}
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NORMAL);
	menu_setprop(menu, MPROP_EXITNAME, "\yCancelar^n");
	menu_setprop(menu, MPROP_BACKNAME, "Anterior");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente^n");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_display(id, menu, 0)
}

public menu_party_list(player, menu, key)
{
	if(key == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new party = g_party_list_index[player][key]
	
	if (party_users(party) >= PARTY_MAX_USERS)
	{
		show_menu_party_list(player)
	}
	else
	{
		new id = party_master(party)
		new data[2];
		data[0] = player;
		data[1] = g_party[id];
		colored_print(player, "^x04[ZIL]^x01 Has enviado una solicitud para unirte al equipo %s", g_partyname[party])
		
		new title[60];
		formatex(title, charsmax(title), "\r[ZE]\w %s \yDesea unirse al equipo.^nAceptar la solicitud?", g_playername[player]);
		new menu = menu_create(title, "menu_confirm");
		menu_additem(menu, "Si, \yaceptar.", data);
		menu_additem(menu, "No, \yrechazar.");
		
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
		menu_display(id, menu);
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public menu_confirm(id, menu, key)
{
	if (!key && is_user_valid_connected(id))
	{
		new data[2];
		menu_item_getinfo(menu, 0, key, data, 2, "", 0, key);
		join_to_party(data[0], data[1]);
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

show_menu_players_inparty(id)
{
	new buffer[33], player, party, count, menu
	party = g_party[id]
	menu = menu_create("\yExpulsar del party", "menu_players_inparty")
	
	for(new i = 0; i < PARTY_MAX_USERS; i++)
	{
		player = g_partymembers[party][i]
		if(is_user_valid_connected(player))
		{
			g_party_list_index[id][count] = player
			count++
			buffer[0] = 0
			formatex(buffer, 32, "%s%s", player != id ? "\w" : "\d", g_playername[player])
			menu_additem(menu, buffer, "", 0)
		}
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NORMAL);
	menu_setprop(menu, MPROP_EXITNAME, "\yCancelar^n");
	menu_setprop(menu, MPROP_BACKNAME, "Anterior");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente^n");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_display(id, menu, 0)
}

public menu_players_inparty(id, menu, key)
{
	if(key == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new player = g_party_list_index[id][key]
	
	if(player != id && is_user_valid_connected(player))
		remove_from_party(player)
	else
		show_menu_players_inparty(id)
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

// Menu para invitar a unirse al party
show_menu_players_noparty(id)
{
	new buffer[33], count, menu
	
	menu = menu_create("\yInvitar al party", "menu_players_noparty")
	
	for(new i = 1; i < 33; i++)
	{
		if(!is_user_valid_connected(i) || g_party[i] != -1)
			continue;
		
		g_party_list_index[id][count] = i
		count++
		buffer[0] = 0
		formatex(buffer, 32, "%s%s", i != id ? "\w" : "\d", g_playername[i])
		menu_additem(menu, buffer, "", 0)
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "\yCancelar^n");
	menu_setprop(menu, MPROP_BACKNAME, "Anterior");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente^n");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_display(id, menu, 0)
}

public menu_players_noparty(player, menu, key)
{
	if(key == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new id = g_party_list_index[player][key]
	
	if(is_user_valid_connected(id) && g_party[id] == -1)
	{
		new data[2];
		data[0] = id;
		data[1] = g_party[player];
		
		new title[60];
		formatex(title, charsmax(title), "\r[ZE]\y Has sido invitado a unirte al equipo \w%s^nDeseas unirte?", g_partyname[data[1]]);
		new menu = menu_create(title, "menu_confirm");
		menu_additem(menu, "Si, \yunirme.", data);
		menu_additem(menu, "No, \yrechazar la invitacion.");
		
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
		menu_display(id, menu);
		
		colored_print(player, "^x04[ZIL]^x01 Has invitado a^x03 %s^x01 a unirse al equipo.", g_playername[id])
	}
	else 
		show_menu_players_noparty(player)
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

// Unir a un jugador a un party
join_to_party(id, party)
{
	if (party == -1 || g_party[id] != -1 || !is_user_valid_connected(party_master(party))) return;

	for (new i = 1; i < PARTY_MAX_USERS; i++)
	{
		if (!is_user_valid(g_partymembers[party][i]))
		{
			g_partymembers[party][i] = id
			g_party[id] = party
			party_print(id, "^x03%s^x01 se ha unido al equipo.", g_playername[id])
			return;
		}
	}
	
	colored_print(id, "^x04[ZIL]^x01 El equipo^x03 %s^x01 esta lleno, no has podido unirte.", g_partyname[party])
}

// Remover a un jugador del party
remove_from_party(id)
{
	new party = g_party[id]
	
	if(party == -1) return;
	
	//g_combo[id] = 0
	
	for(new i = 0; i < PARTY_MAX_USERS; i++)
	{
		if(g_partymembers[party][i] != id) continue;
		
		party_print(id, "^x03%s^x01 ha abandonado el equipo.", g_playername[id])
		g_partymembers[party][i] = 0
		g_party[id] = -1
		if(!i || !party_users(party)) party_destroy(party)
		
		break;
	}
}

// Destruir un party
party_destroy(party)
{
	new buffer
	for (new i = 0; i < PARTY_MAX_USERS; i++)
	{
		buffer = g_partymembers[party][i]
		
		if (is_user_valid_connected(buffer))
		{
			g_party[buffer] = -1
			//g_combo[buffer] = 0
			colored_print(buffer, "^x04[ZIL]^x01 El equipo^x03 %s^x01 ha sido destruido.", g_partyname[party])
		}
		
		g_partymembers[party][i] = 0
	}
	
	g_partyname[party][0] = 0
}

// Crear un party o cambiar el nombre
public party_input(id)
{
	static party; party = g_party[id]
	
	if (party != -1 && party_master(party) != id)
		return PLUGIN_CONTINUE;
	
	
	new name[33]
	read_args(name, 32)
	remove_quotes(name)
	replace_all(name, 32, "%", " ")
	
	if(strlen(name) < 4)
	{
		client_print(id, print_center, "Error: 4 caracteres como minimo")
		client_cmd(id, "messagemode ^"Nombre_Del_Equipo^"")
		set_hudmessage(0, 255, 255, 0.03, 0.05, 0, 0.1, 4.0, 0.01, 0.01, -1)
		ShowSyncHudMsg(id, g_MsgSync5, "Ingresa un nombre para el Equipo^nPulsa ESC para salir")
		return PLUGIN_HANDLED;
	}
	
	party = g_party[id]
	
	if(party == -1)
	{
		for(new i = 0; i < PARTY_LIMIT; i++)
		{
			if(!party_master(i))
			{
				g_party[id] = i
				g_partymembers[i][0] = id
				copy(g_partyname[i], charsmax(g_partyname[]), name)
				colored_print(id, "^x04[ZIL]^x01 Se ha creado el equipo^x03 %s", name, i)
				break;
			}
		}
		
		return PLUGIN_HANDLED;
	}
	
	party_print(id, "El nombre del equipo fue cambiado a^x03 %s", name)
	copy(g_partyname[party], charsmax(g_partyname[]), name)
	
	return PLUGIN_HANDLED;
}		

// Retorna la cantidad de parties creados
party_count()
{
	new i, count
	count = 0
	for(i = 0; i < PARTY_LIMIT; i++)
	{
		if(is_user_valid(party_master(i)))
			count++
	}
	
	return count;
}

// Retorna la cantidad de usuarios en un party
party_users(party)
{
	new i, count
	count = 0
	for(i = 0; i < PARTY_MAX_USERS; i++)
	{
		if(is_user_valid(g_partymembers[party][i]))
			count++
	}
	
	return count;
}

// Dividir la exp entre los miembros del party
stock party_bonus(party, bonus)
{
	static count; count = party_users(party)
	
	if (count + 2 >= PARTY_MAX_USERS)
		return (2*bonus)/count;
	
	return bonus/count;
}

// Retorna la cantidad de usuarios sin party
get_players_noparty()
{
	new count;
	count = 0
	for(new i = 1; i < 33; i++)
	{
		if(is_user_valid_connected(i) && g_party[i] == -1)
			count++
	}
	
	return count;
}

// Envia un mensaje a todos los miembros del mismo party
party_print(id, const message[], any:...)
{
	static buffer[191]
	new party, player
	party = g_party[id]
	vformat(buffer, 186-PARTY_NAME_LENGTH, message, 3)
	
	for(id = 0; id < PARTY_MAX_USERS; id++)
	{
		player = g_partymembers[party][id]
		if(!is_user_valid_connected(player)) continue;
		
		colored_print(player, "^x04(%s)^x01 %s", g_partyname[party], buffer)
	}
	
	for(id = 1; id <= 32; id++)
	{
		if(!is_user_valid_connected(id)) continue;
		
		if(!(get_user_flags(id) & ADMIN_IMMUNITY) || g_party[id] == party) continue;
		
		colored_print(id, "^x04(PARTY %s)^x01 %s", g_partyname[party], buffer)
	}
}

colored_print(target, const input[], any:...)
{
	static szMsg[191], id;
    
	vformat(szMsg, 190, input, 3);
	
	id = (target > 32) ? target-33 : target;
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_msgSayText, .player = id);
	write_byte(is_user_valid(target) ? target : 33);
	write_string(szMsg);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
