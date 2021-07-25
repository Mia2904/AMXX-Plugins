#include <amxmodx>
#include <fvault>

// Borra esta linea o coméntala para usar el guardado por NOMBRE.
#define USE_STEAMID

// Comandos de chat
new const Comandos[2][] =
{
	"/advertencias",	// Abrir el menu de advertencias (ADMINS)
	"/infoadv"		// Ver info sobre el sistema de advertencias
}

// Nivel de admin requerido
new const NIVEL_DE_ADMIN = ADMIN_KICK;

// Nombre del vault para guardar los datos.
new const Vault[] = "warnings"

// Nombre del archivo donde se loguean las advertencias que dan los admins.
new const LogFile[] = "log_warnings.txt"

// Hasta aqui la parte editable. Continuar no estara soportado.

new g_warnings[33 char], g_day[33], g_month[33], g_year[33], g_connected;
new cvar_days, cvar_maxadv, cvar_bantime, cvar_banip;
new g_msgid_saytext;

#define PLUGIN "Sistema de Advertencias"
#define VERSION "0.2"

#pragma semicolon 1

// Como solo usamos g_warnings desde la celda 1 a la 32
// La celda 0 no se usa, la usaremos para guardar los slots
#define MAX_PLAYERS g_warnings{0}

#define set_player_connected(%0) (g_connected |= (1 << %0-1))
#define clear_player_connected(%0) (g_connected &= ~(1 << %0-1))
#define check_player_connected(%0) (g_connected & (1 << %0-1))

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	cvar_days = register_cvar("advertencias_duracion", "30");
	cvar_maxadv = register_cvar("advertencias_limite", "5");
	cvar_bantime = register_cvar("advertencias_minutosban", "0");
	cvar_banip = register_cvar("advertencias_banip", "0"); // 0 - SteamID | 1 - IP
	
	MAX_PLAYERS = get_maxplayers();
	
	new buffer[80];
	formatex(buffer, charsmax(buffer), "say %s", Comandos[0]);
	register_clcmd(buffer, "clcmd_saywarnings", NIVEL_DE_ADMIN);
	formatex(buffer, charsmax(buffer), "say %s", Comandos[1]);
	register_clcmd(buffer, "clcmd_sayinfoadv");
	
	g_msgid_saytext = get_user_msgid("SayText");
}

public client_putinserver(id)
{
	if (is_user_bot(id))
		return;
	
	set_player_connected(id);
	
	load_warnings(id);
}

public client_disconnect(id)
	clear_player_connected(id);
	
#if !defined USE_STEAMID
public client_infochanged(id)
	set_task(2.0, "task_warnings", id);

public task_warnings(id)
{
	if (!check_player_connected(id))
		return;
	
	load_warnings(id)
}
#endif

public clcmd_saywarnings(id, level)
{
	if (~get_user_flags(id) & level)
		return PLUGIN_CONTINUE;
	
	show_menu_warnings(id);
	return PLUGIN_HANDLED;
}

public clcmd_sayinfoadv(id)
{
	static motd[512], len, bantime;
	bantime = get_pcvar_num(cvar_bantime);
	
	len = formatex(motd, charsmax(motd), "<body bgcolor=#000000><pre><font color=#FFFFFF face=^"arial^" size=5>^n^n");
	len += formatex(motd[len], charsmax(motd)-len, "<center>Sistema de Advertencias</center>^n^n");
	len += formatex(motd[len], charsmax(motd)-len, "El sistema de advertencias es una herramienta para sancionar jugadores.^n");
	len += formatex(motd[len], charsmax(motd)-len, "Un administrador puede dar una advertencia a un jugador en cualquier momento.^n");
	len += formatex(motd[len], charsmax(motd)-len, "Si un jugador llega a %d advertencias, será baneado ", get_pcvar_num(cvar_maxadv));
	len += formatex(motd[len], charsmax(motd)-len, bantime ? "por %d minutos." : "permanentemente.", bantime);
	len += formatex(motd[len], charsmax(motd)-len, g_warnings{id} ? "^n^nTienes %d advertencias, recibiste la ultima el %d/%d/%d.^nT" : "Tu no has recibido advertencias.^nSi recibes algunas, t", g_warnings{id}, g_day[id], g_month[id], g_year[id]);
	len += formatex(motd[len], charsmax(motd)-len, "ienes que pasar %d dias sin recibir otra para que sean borradas.^n^n", get_pcvar_num(cvar_days));
	
	show_motd(id, motd, "Info de Advertencias");
}

show_menu_warnings(id)
{
	static szItem[40], szUserID[8], menu, i, len, advlimit;
	
	advlimit = get_pcvar_num(cvar_maxadv) - 1;
	
	menu = menu_create("\r[Advertencias] \yMenu de jugadores", "menu_warnings");
	
	for (i = 1; i <= MAX_PLAYERS; i++)
	{
		if (!check_player_connected(i))
			continue;
		
		len = get_user_name(i, szItem, 31);
		formatex(szItem[len], charsmax(szItem)-len, "\y [\%s%d\y]", g_warnings{i} >= advlimit ? "r" : g_warnings{i} ? "y" : "d", g_warnings{i});
		
		num_to_str(get_user_userid(i), szUserID, charsmax(szUserID));

		menu_additem(menu, szItem, szUserID, 0);
	}
	
	formatex(szItem, charsmax(szItem), "%L", LANG_SERVER, "MORE");
	menu_setprop(menu, MPROP_NEXTNAME, szItem);
	
	formatex(szItem, charsmax(szItem), "%L", LANG_SERVER, "EXIT");
	menu_setprop(menu, MPROP_EXITNAME, szItem);
	
	formatex(szItem, charsmax(szItem), "%L", LANG_SERVER, "BACK");
	menu_setprop(menu, MPROP_BACKNAME, szItem);

	menu_display(id, menu, 0);
}

public menu_warnings(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[8], player;
	
	menu_item_getinfo(menu, item, player, data, charsmax(data), _, _, player);
	player = find_player("k", str_to_num(data));
	
	if (player)
	{
		new szName[2][32];
		get_user_name(id, szName[0], 31);
		get_user_name(player, szName[1], 31);
		log_to_file(LogFile, "ADMIN %s ha dado una advertencia a %s", szName[0], szName[1]);
		add_warning(player);
	}
	else
		show_menu_warnings(id);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

add_warning(id)
{
	g_warnings{id}++;
	
	new szName[32], szAuth[36], buffer[150], banip;
	get_user_name(id, szName, 31);
	banip = get_pcvar_num(cvar_banip);
	
	if (banip)
		get_user_ip(id, szAuth, charsmax(szAuth), 1);
	else
		get_user_authid(id, szAuth, charsmax(szAuth));
	
	date(g_year[id], g_month[id], g_day[id]);
	
	new maxadv = get_pcvar_num(cvar_maxadv);
	
	if (g_warnings{id} >= maxadv)
	{
		new len, minutes = get_pcvar_num(cvar_bantime);
		
		len = formatex(buffer, charsmax(buffer), "Jugador %s (%s) baneado por tener %d advertencias", szName, szAuth, maxadv);
		formatex(buffer[len], charsmax(buffer)-len, minutes ? " (%d minutos)" : " (Permanente)", minutes);
		
		client_print(0, print_chat, buffer);
		log_to_file(LogFile, buffer);
		
		clear_warnings(id);
		
		len = formatex(buffer, charsmax(buffer), "kick #%d ^"Has sido baneado ", get_user_userid(id));
		len += formatex(buffer[len], charsmax(buffer)-len, minutes ? "por %d minutos " : "permanentemente ", minutes);
		len += formatex(buffer[len], charsmax(buffer)-len, "por advertencias.^";wait;wait;%s %d ^"%s^";wait;wait;write%s", banip ? "addip" : "banid", minutes, szAuth, banip? "ip" : "id");
		
		server_cmd(buffer);
	}
	else
	{
		formatex(buffer, charsmax(buffer), "%sAhora tienes %d advertencia%s. Cuidado, si llegas a %d seras baneado.", "^x03", g_warnings{id}, g_warnings{id} == 1 ? "" : "s", maxadv);
		
		message_begin(MSG_ONE_UNRELIABLE, g_msgid_saytext, _, id);
		write_byte(id);
		write_string(buffer);
		message_end();
		
		client_print(0, print_chat, "El jugador %s ha recibido una advertencia.", szName);
		client_print(0, print_chat, "Para informacion sobre el sistema de advetencias, escribe: '%s'", Comandos[1]);
		
		new szData[15];
		formatex(szData, charsmax(szData), "%d %d %d %d", g_warnings{id}, g_month[id], g_day[id], g_year[id]);
		
		#if defined USE_STEAMID
		if (banip)
			get_user_authid(id, szAuth, charsmax(szAuth));
		
		fvault_set_data(Vault, szAuth, szData);
		#else
		fvault_set_data(Vault, szName, szData);
		#endif
	}
}

clear_warnings(id)
{
	#if defined USE_STEAMID
	new szKey[36];
	get_user_authid(id, szKey, charsmax(szKey));
	#else
	new szKey[32];
	get_user_name(id, szKey, 31);
	#endif
	
	fvault_remove_key(Vault, szKey);
	
	g_warnings{id} = 0;
}

load_warnings(id)
{
	#if defined USE_STEAMID
	static szKey[36], szBuffer[15];
	szKey[0] = szBuffer[0] = '^0';
	get_user_authid(id, szKey, charsmax(szKey));
	#else
	static szKey[32], szBuffer[15];
	szKey[0] = szBuffer[0] = '^0';
	get_user_name(id, szKey, 31);
	#endif
	
	date(g_year[0], g_month[0], g_day[0]);
	
	if (fvault_get_data(Vault, szKey, szBuffer, charsmax(szBuffer)))
	{
		static szWarnings[3], szMon[3], szDay[3], szYear[5];
		parse(szBuffer, szWarnings, 2, szMon, 2, szDay, 2, szYear, 4);
		
		g_month[id] = str_to_num(szMon);
		g_day[id] = str_to_num(szDay);
		g_year[id] = str_to_num(szYear);
		
		if (days_between_dates(g_day[id], g_month[id], g_year[id], g_day[0], g_month[0], g_year[0]) <= get_pcvar_num(cvar_days))
			g_warnings{id} = str_to_num(szWarnings);
		else
			clear_warnings(id);
	}
	else
		g_warnings{id} = 0;
}

// Esto es necesario para contar los dias
// Usar el timestamp de fvault haria que sea necesario convertir el tiempo UNIX al calendario Gregoriano...
// Mejor almacenar las fechas, ¿no?

// Algunos offsets del calendario...
const MONTHS = 12;
const LEAP_MONTH = 2;
const LEAP_DAY = 29;
const YEAR_DAYS = 365;
stock const mdays[MONTHS] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
#define MONTH_DAYS(%0) mdays[%0 - 1]

// Contar los dias entre 2 fechas (stock muy util y preciso)
// La fecha 1 debe ser menor a la fecha 2
stock days_between_dates(const day1, const month1, const year1, const day2, const month2, const year2)
{
	new days, buffer;
	
	if (year1 == year2)
	{
		days = (month1 == month2) ? day2 - day1 : MONTH_DAYS(month1) - day1 + day2;
		
		for (buffer = month1 + 1; buffer < month2; buffer++)
			days += MONTH_DAYS(buffer);
			
		if (leap_year(year1) && month1 <= LEAP_MONTH && month2 > LEAP_MONTH)
				days++;
	}
	else
	{
		days = MONTH_DAYS(month1) - day1 + day2;
		
		for (buffer = month1 + 1; buffer < month2 + MONTHS; buffer++)
			days += (buffer > MONTHS) ? MONTH_DAYS(buffer - MONTHS) : MONTH_DAYS(buffer);
		
		for (buffer = year2 - 1; buffer > year1; buffer--)
		{
			days += YEAR_DAYS;
			
			if (leap_year(buffer))
				days++;
		}
		
		if (leap_year(year1) && month1 <= LEAP_MONTH)
				days++;
		
		if (leap_year(year2) && month2 > LEAP_MONTH)
				days ++;
	}
	
	return days;
}

// Saber si un año es bisiesto
stock bool:leap_year(const year)
{
	if ((year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0))
		return true;
	
	return false;
}
