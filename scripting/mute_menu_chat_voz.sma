#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Menu de Mute"
#define VERSION "0.1"

new g_bMutedC[33], g_bMutedV[33], g_players[32], g_menucallback, cvar_alltalk;

#define is_player_muted_chat(%0,%1) (g_bMutedC[%0] & (1 << %1-1))
#define is_player_muted_voice(%0,%1) (g_bMutedV[%0] & (1 << %1-1))
#define player_muted_all_chat(%0) (g_bMutedC[0] & (1 << %0-1))
#define player_muted_all_voice(%0) (g_bMutedV[0] & (1 << %0-1))

new const ESTADOS[][] = { "\dDesactivado", "\ySólo voz", "\ySólo chat", "\yVoz+Chat" };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	register_clcmd("say /mute", "clcmd_mute", 0);
	
	register_forward(FM_Voice_SetClientListening, "fw_Voice");
	
	register_message(get_user_msgid("SayText"), "message_SayText") 
	
	g_menucallback = menu_makecallback("menu_mute_cb");
	cvar_alltalk = get_cvar_pointer("sv_alltalk");
}

public client_putinserver(id)
{
	g_bMutedC[id] = g_bMutedV[id] = 0;
	
	id--;
	for (new i = 0; i <= 32; i++)
	{
		g_bMutedC[i] &= ~(1 << id);
		g_bMutedV[i] &= ~(1 << id);
	}
}

public fw_Voice(id, sender, listen) 
{
	if ((id != sender && player_muted_all_voice(id)) || is_player_muted_voice(id, sender))
	{
		engfunc(EngFunc_SetClientListening, id, sender, 0);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public message_SayText(msg_id, msg_dest, msg_ent)
{
	if (msg_dest != MSG_ONE && msg_dest != MSG_ONE_UNRELIABLE)
		return PLUGIN_CONTINUE;
	
	static sender, id;
	sender = get_msg_arg_int(1);
	id = msg_ent;
	
	if ((id != sender && player_muted_all_chat(id)) || is_player_muted_chat(id, sender))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public clcmd_mute(id, page)
{
	static i, status, num, menu, len, szItem[46], szData[2];
	menu = menu_create("Menu de Mute", "menu_mute");
	
	status = player_muted_all_voice(id) ? 1 : 0;
	if (player_muted_all_chat(id))
		status += 2;
    
	formatex(szItem, charsmax(szItem), "Mutear a todos\r [\y%s\r]", ESTADOS[status]);
	menu_additem(menu, szItem);
	
	if (!(num = get_pcvar_num(cvar_alltalk)))
		get_user_team(id, szItem, 11);
	
	get_players(g_players, num, num ? "" : "e", num ? "" : szItem);
	
	if (status == 3)
		szData[1] = 3;
	
	for (new a = 0; a < num; a++)
	{
		i = g_players[a];
				
		len = get_user_name(i, szItem, 31);
		
		switch (status)
		{
			case 0:
			{
				szData[1] = is_player_muted_voice(id, i) ? 1 : 0;
				if (is_player_muted_chat(id, i))
					szData[1] += 2;
			}
			case 1: szData[1] = is_player_muted_chat(id, i) ? 3 : 1;
			case 2: szData[1] = is_player_muted_voice(id, i) ? 3 : 2;
		}
		
		if (szData[1] && i != id)
			formatex(szItem[len], charsmax(szItem)-len, "\y [%s]", ESTADOS[szData[1]]);
		
		szData[0] = i;
		
		menu_additem(menu, szItem, szData, 0, g_menucallback);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Atras");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente^n");
	menu_setprop(menu, MPROP_EXITNAME, "\ySalir");
	
	menu_display(id, menu, page);
}

public menu_mute_cb(id, menu, item)
{
	if ((player_muted_all_chat(id) && player_muted_all_voice(id)) || id == g_players[item])
		return ITEM_DISABLED;
	
	return ITEM_ENABLED;
}

public menu_mute(id, menu, item)
{
	switch (item)
	{
		case 0:
		{
			if (player_muted_all_voice(id))
			{
				if (player_muted_all_chat(id))
					g_bMutedC[0] &= ~(1<<id-1);
				else
					g_bMutedC[0] |= (1<<id-1);
			}
			else
			{
				if (player_muted_all_chat(id))
					g_bMutedC[0] |= (1<<id-1);
				else
					g_bMutedC[0] &= ~(1<<id-1);
			}
			
			g_bMutedV[0] ^= (1<<id-1);
		}
		case MENU_EXIT:
		{
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		default:
		{
			new szData[2], Junk;
			
			menu_item_getinfo(menu, item, Junk, szData, sizeof(szData), .callback = Junk);
			
			Junk = szData[0]-1;
			
			if (player_muted_all_voice(id))
				g_bMutedC[id] ^= (1<<Junk);
			else if (player_muted_all_chat(id))
				g_bMutedV[0] ^= (1<<id-1);
			else
			{
				g_bMutedV[id] ^= (1<<Junk);
				
				if (szData[1] == 1 || szData[1] == 3)
					g_bMutedC[id] ^= (1<<Junk);
			}
		}
	}
	
	clcmd_mute(id, item/7);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
