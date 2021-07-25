/*
 *	Include for Polymorph by Fysiks. Edited version by Mia2904
 */

#if defined _polymorph_included
	#endinput
#endif
#define _polymorph_included

#pragma reqlib "polymorph"

native polyn_endofmap()

native polyn_get_thismod(modname[], len)

native polyn_get_this_submode(submodename[], len)

native polyn_get_nextmod(modname[], len)

native polyn_votemod()

native polyn_get_mod_count()

native polyn_get_submode_count(modid)

native polyn_get_mod_name(modid, name[], maxlen)

native polyn_get_submode_name(modid, submodeid, name[], maxlen)

native polyn_set_next_mod(modid)

native polyn_set_next_submode(smodid)

native polyn_show_map_menu(id)
