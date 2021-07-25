/* AMX Mod X
*   Slots Reservation Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
* This file is part of AMX Mod X.
*
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation,
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve,
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/

#include <amxmodx>
#include <amxmisc>

new g_ResPtr
new g_HidePtr

new players[32], num, g_ping[33], loss

public plugin_init()
{
	register_plugin("Slots Reservation Ping", AMXX_VERSION_STR, "AMXX Dev Team")
	register_dictionary("adminslots.txt")
	register_dictionary("common.txt")
	g_ResPtr = register_cvar("amx_reservation", "2")
	g_HidePtr = register_cvar("amx_hideslots", "2")
}

public plugin_cfg()
{
	set_task(3.0, "MapLoaded")
	set_task(2.0, "store_pings", .flags="b");
}

public store_pings()
{
	static id, ping
	get_players(players, num, "ch")
	
	for (new i = 0; i < num; i++)
	{
		id = players[i]
		get_user_ping(id, ping, loss)
		g_ping[id] = ping < 58 ? 200 : ping
	}
}

check_pings(player)
{
	new id, ping, worse
	get_players(players, num, "ch")
	new highest = 0
		
	for (new i = 0; i < num; i++)
	{
		id = players[i]
		if (id == player || get_user_flags(id) & ADMIN_RESERVATION)
			continue;
		
		get_user_ping(id, ping, loss)
		ping += g_ping[id]
		
		if (ping > highest)
		{
			worse = id
			highest = ping
		}
	}
	
	return worse
}

public MapLoaded()
{
	if (!get_pcvar_num(g_HidePtr))
		return

	new maxplayers = get_maxplayers()
	new players = get_playersnum(1)
	new limit = maxplayers - get_pcvar_num(g_ResPtr)
	setVisibleSlots(players, maxplayers, limit)
}

public client_authorized(id)
{
	new maxplayers = get_maxplayers()
	new players = get_playersnum(1)
	new limit = maxplayers - get_pcvar_num(g_ResPtr)

	if (players <= limit)
	{
		if (get_pcvar_num(g_HidePtr) == 1)
			setVisibleSlots(players, maxplayers, limit)
		
		return PLUGIN_CONTINUE
	}
	else if (!access(id, ADMIN_RESERVATION))
	{
		new lReason[64]
		format(lReason, 63, "%L", id, "DROPPED_RES")
		server_cmd("kick #%d ^"%s^"", get_user_userid(id), lReason)

		return PLUGIN_HANDLED
	}
	
	if (players == maxplayers)
	{
		new drop = check_pings(id)
		server_cmd("kick #%d ^"Your ping is too high, try later...^"", get_user_userid(drop))
	}
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	if (!get_pcvar_num(g_HidePtr))
		return PLUGIN_CONTINUE

	g_ping[id] = 0
	
	new maxplayers = get_maxplayers()
	
	setVisibleSlots(get_playersnum(1) - 1, maxplayers, maxplayers - get_pcvar_num(g_ResPtr))
	return PLUGIN_CONTINUE
}

setVisibleSlots(players, maxplayers, limit)
{
	new numb = players + 1

	if (players == maxplayers)
		numb = maxplayers
	else if (players < limit)
		numb = limit
	
	set_cvar_num("sv_visiblemaxplayers", numb)
}
