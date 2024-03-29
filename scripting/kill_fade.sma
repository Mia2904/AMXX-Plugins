/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <hamsandwich>

#define PLUGIN "Kill fade"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new g_msgScreenFade;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1);
	
	g_msgScreenFade = get_user_msgid("ScreenFade");
}

public fw_PlayerKilled_Post(id)
{
	new team = get_user_team(id);
	if (team < 1 || team > 2)
		return HAM_IGNORED;
	
	screen_fade(id);
	
	return HAM_IGNORED;
}

screen_fade(id)
{
	message_begin(MSG_BROADCAST, g_msgScreenFade, _, id)
	write_short(5*4096)
	write_short(2048)
	write_short(0x0001)
	write_byte(0) 		// Red
	write_byte(0) 		// Green
	write_byte(0)	 	// Blue
	write_byte(255)
	message_end()
}
