#include <amxmodx>

// Name for the log file
new const LogFile[] = "sxei_admin_menu.txt"

// Chat commands to open the menus
new const Commands[2][] =
{
	"/sxeban",		// For the local ban menu
	"/sxescreen"		// For the screenshot menu
}

// ================================================================

new g_action, g_connected, g_maxplayers[1 char];

#define PLUGIN "sXe-I Admin Menu"
#define VERSION "1.1"

#pragma semicolon 1

#define set_action_localban(%0) (g_action |= (1 << %0-1))
#define clear_action_localban(%0) (g_action &= ~(1 << %0-1))
#define check_action_localban(%0) (g_action & (1 << %0-1))

#define set_player_connected(%0) (g_connected |= (1 << %0-1))
#define clear_player_connected(%0) (g_connected &= ~(1 << %0-1))
#define check_player_connected(%0) (g_connected & (1 << %0-1))

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	new buffer[100];
	
	formatex(buffer, charsmax(buffer), "say %s", Commands[0]);
	register_clcmd(buffer, "clcmd_localban", ADMIN_BAN);
	
	formatex(buffer, charsmax(buffer), "say %s", Commands[1]);
	register_clcmd(buffer, "clcmd_screen", ADMIN_BAN);
	
	register_dictionary("common.txt");
	
	g_maxplayers{0} = get_maxplayers();
}

public client_putinserver(id)
	if (!is_user_bot(id)) set_player_connected(id);
	
public client_disconnect(id)
	clear_player_connected(id);

public clcmd_localban(id, level)
{
	if (~get_user_flags(id) & level)
		return PLUGIN_CONTINUE;
	
	set_action_localban(id);
	show_menu_players(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_screen(id, level)
{
	if (~get_user_flags(id) & level)
		return PLUGIN_CONTINUE;
	
	clear_action_localban(id);
	show_menu_players(id);
	
	return PLUGIN_HANDLED;
}
	
show_menu_players(id)
{
	new szItem[32];
	formatex(szItem, charsmax(szItem), "\r[sXe-I] \y%s Menu", check_action_localban(id) ? "Local Ban" : "Screenshot");
	
	new menu = menu_create(szItem, "menu_players");

	new i, szUserID[8];

	for (i = 1; i < g_maxplayers{0}; i++)
	{
		if (!check_player_connected(i))
			continue;

		get_user_name(i, szItem, charsmax(szItem));
		
		num_to_str(get_user_userid(i), szUserID, charsmax(szUserID));

		menu_additem(menu, szItem, szUserID, 0);
	}
	
	formatex(szItem, charsmax(szItem), "%L", LANG_SERVER, "MORE");
	menu_setprop(menu, MPROP_NEXTNAME, szItem);
	
	formatex(szItem, charsmax(szItem), "%L", LANG_SERVER, "EXIT");
	menu_setprop(menu, MPROP_EXITNAME, szItem);
	
	formatex(szItem, charsmax(szItem), "%L", LANG_SERVER, "BACK");
	menu_setprop(menu, MPROP_BACKNAME, szItem);

	menu_display(id, menu);
}

public menu_players(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szData[8], player, userid;

	// We don't need &access and &callback, so we'll use player.
	menu_item_getinfo(menu, item, player, szData, charsmax(szData), _, _, player);
	
	userid = str_to_num(szData);
	player = find_player("k", userid);
	
	if (player)
	{
		if (check_action_localban(id))
			show_confirm_ban(id, player, szData);
		else
		{
			server_cmd("sxe_screen #%d #%d", userid, get_user_userid(id));
		
			new szName[2][32];
			get_user_name(id, szName[0], 31);
			get_user_name(player, szName[1], 31);
			
			log_to_file(LogFile, "%L %s - Screenshot %s", LANG_SERVER, "ADMIN", szName[0], szName[1]);
		}
	}
		
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

show_confirm_ban(id, player, szUserID[])
{
	new menu, szItem[50];
	
	// We're using 'menu' to store the len of string.
	menu = copy(szItem, charsmax(szItem), "\r[sXe-I]\y Local Ban\w ");
	menu += get_user_name(player, szItem[menu], charsmax(szItem)-menu);
	copy(szItem[menu], charsmax(szItem)-menu, "\y?");
	
	// Now 'menu' is the pointer of the menu.
	menu = menu_create(szItem, "confirm_ban");
	
	formatex(szItem, charsmax(szItem), "%L", LANG_SERVER, "YES");
	menu_additem(menu, szItem, szUserID);
	
	formatex(szItem, charsmax(szItem), "%L", LANG_SERVER, "NO");
	menu_additem(menu, szItem);
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu);
}

public confirm_ban(id, menu, item)
{
	if (item == 0) // Key 1 - Yes
	{
		new szData[8], player, userid;

		// We don't need &access and &callback, so we'll use player.
		menu_item_getinfo(menu, item, player, szData, charsmax(szData), _, _, player);
		
		userid = str_to_num(szData);
		player = find_player("k", userid);
		
		if (player)
		{
			server_cmd("sxe_ban #%d", userid);
		
			new szName[2][32];
			get_user_name(id, szName[0], 31);
			get_user_name(player, szName[1], 31);
			
			log_to_file(LogFile, "%L %s - Local ban %s", LANG_SERVER, "ADMIN", szName[0], szName[1]);
		
			client_print(0, print_chat, "[sXe-I] %L %s - Local ban %s", LANG_SERVER, "ADMIN", szName[0], szName[1]);
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
