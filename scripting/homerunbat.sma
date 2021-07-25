#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <knifeapi>

new cvar_strength, cvar_height, cvar_cheers, cvar_boo;
new g_homerun, g_attacker[33 char], Float:g_origin[33][3];
new g_msgScreenFade, g_msgScreenShake, g_msgSayText, g_sprTrail;

new const p_model[] = "models/knifeapi/homerunbat/p_homerunbat.mdl";
new const v_model[] = "models/knifeapi/homerunbat/v_homerunbat.mdl";
new const w_model[] = "models/knifeapi/homerunbat/w_homerunbat.mdl";
#define w_model_T     "models/knifeapi/homerunbat/w_homerunbatT.mdl"

new const slash_sound[] = "weapons/cbar_hitbod2.wav";
new const stab_sound[] = "knifeapi/homerunbat/homerunbat_stab.wav";
new const whiff_sound[] = "weapons/cbar_miss1.wav";
new const wall_sound[] = "knifeapi/homerunbat/homerunbat_wall.wav";

new const sound_boo[] = "knifeapi/homerunbat/boo.wav";
new const sound_cheers[] = "knifeapi/homerunbat/cheers.wav";

public plugin_precache()
{
	// HUD sprite
	precache_generic("sprites/knife_homerunbat.txt");
	precache_generic("sprites/knifeapi/homerunbat.spr");
	
	// Trail for flying player
	g_sprTrail = precache_model("sprites/laserbeam.spr");
	
	// Models
	precache_model(p_model);
	precache_model(v_model);
	precache_model(w_model);
	precache_model(w_model_T);
	
	// Sounds
	precache_sound(slash_sound);
	precache_sound(stab_sound);
	precache_sound(wall_sound);
	precache_sound(whiff_sound);
	
	// Ambience sounds
	precache_sound(sound_boo);
	precache_sound(sound_cheers);
}

public plugin_init()
{
	register_plugin("Knife: Home Run Bat", "0.2", "Mia2904");
	
	g_homerun = Knife_Register("Home Run Bat", v_model, p_model, w_model, "weapons/knife_slash2.wav", slash_sound, stab_sound, whiff_sound, wall_sound, 0.2, 0.2);
	
	Knife_SetProperty(g_homerun, KN_CLL_PrimaryDmgBits, DMG_CRUSH|DMG_BULLET);
	Knife_SetProperty(g_homerun, KN_CLL_SecondaryDmgBits, DMG_CRUSH|DMG_BULLET);
	Knife_SetProperty(g_homerun, KN_CLL_PrimaryNextAttack, 0.5);
	Knife_SetProperty(g_homerun, KN_CLL_SecondaryDamageDelay, 0.2);
	Knife_SetProperty(g_homerun, KN_CLL_SecondaryNextAttack, 1.5);
	Knife_SetProperty(g_homerun, KN_CLL_PrimaryRange, 50.0);
	Knife_SetProperty(g_homerun, KN_CLL_Droppable, true);
	Knife_SetProperty(g_homerun, KN_STR_SpriteName, "knife_homerunbat");
	Knife_SetProperty(g_homerun, KN_CLL_IgnoreFriendlyFire, true);
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	
	cvar_strength = register_cvar("homerunbat_strength", "2000");
	cvar_height = register_cvar("homerunbat_height", "1000");
	cvar_boo = register_cvar("homerunbat_min_distance", "200");
	cvar_cheers = register_cvar("homerunbat_hr_distance", "700");
	
	g_msgScreenFade = get_user_msgid("ScreenFade");
	g_msgScreenShake = get_user_msgid("ScreenShake");
	g_msgSayText = get_user_msgid("SayText");
}

public KnifeAction_ProcessAttack_Post(Attacker, Victim, Knife, bool:PrimaryAttack, Float:EndPoint[3], Float:AimVector[3])
{
	if (!Victim || PrimaryAttack || Knife != g_homerun)
		return KnifeAction_DoNothing;
		
	// Store the attacker's index.
	g_attacker{Victim} = Attacker;
	
	// Store the origin to get the distance later.
	entity_get_vector(Victim, EV_VEC_origin, g_origin[Victim]);
	
	// Let's fly!
	static Float:Buffer[3];
	velocity_by_aim(Attacker, get_pcvar_num(cvar_strength), Buffer);
	
	// Custom height.
	static Float:Height;
	if ((Height = get_pcvar_float(cvar_height)) > 0)
		Buffer[2] = Height;
	
	entity_set_vector(Victim, EV_VEC_velocity, Buffer);
	
	// Move the angles! Who can stay quiet after receiving that kind of hit?
	entity_get_vector(Victim, EV_VEC_punchangle, Buffer);
	
	Buffer[0] += random_float(-30.0, 30.0);
	Buffer[1] += random_float(-30.0, 30.0);
	Buffer[2] += random_float(-30.0, 30.0);
	
	entity_set_vector(Victim, EV_VEC_punchangle, Buffer);
	
	// Some effects
	fx_Trail(Victim);
	fx_ScreenFade(Victim);
	fx_ScreenShake(Victim);
	
	return KnifeAction_DoNothing;
}

public client_PostThink(id)
{
	// Not in flight.
	if (!g_attacker{id})
		return;
	
	static Flags;
	Flags = entity_get_int(id, EV_INT_flags);
	
	// Not flying anymore.
	if (Flags & FL_ONGROUND)
	{
		// Remove the trail.
		fx_RemoveTrail(id);
		
		static szName[2][32], Attacker, Float:Distance, Float:Origin[3];
		Attacker = g_attacker{id};
		
		// Remove the flying flag.
		g_attacker{id} = 0;
		
		if (!is_user_connected(Attacker)) // Security
			return;
		
		// Calculate the distance.
		entity_get_vector(id, EV_VEC_origin, Origin);
		
		Distance = get_distance_f(g_origin[id], Origin);
		
		// Flew enough?
		if (Distance >= get_pcvar_float(cvar_cheers))
		{
			// Home Run!
			emit_sound(Attacker, CHAN_VOICE, sound_cheers, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			get_user_name(Attacker, szName[0], 31);
			get_user_name(id, szName[1], 31);
			colored_print(Attacker, "%s^x01 just hit %s and did a^x04 Home Run!", szName[0], szName[1]);
		}
		else if (Distance <= get_pcvar_float(cvar_boo))
		{
			// Booooooooooooooooooo!
			emit_sound(Attacker, CHAN_VOICE, sound_boo, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

// This part is for security.
public fw_PlayerSpawn_Post(id)
{
	g_attacker{id} = 0;
}

public client_putinserver(id)
	g_attacker{id} = 0;

// Custom effects.
fx_Trail(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(id);
	write_short(g_sprTrail);
	write_byte(10);
	write_byte(10);
	write_byte(255);
	write_byte(130);
	write_byte(20);
	write_byte(200);
	message_end();
}

fx_RemoveTrail(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(id);
	message_end();
}

fx_ScreenFade(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id);
	write_short(20480); // 4096 = 1 second, 5 * 4096 = 20480.
	write_short(0);
	write_short(0x0000);
	write_byte(250);
	write_byte(0);
	write_byte(0);
	write_byte(150);
	message_end();
}

fx_ScreenShake(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id);
	write_short(40960); // 4096 = 1 second, 10 * 4096 = 40960.
	write_short(4096);
	write_short(51200); // 256 = 1 unit, 200 * 256 = 51200.
	message_end();
}

colored_print(sender, const szMessage[], any:...)
{
	static szText[191] = "^x03";
	
	vformat(szText[1], 189, szMessage, 3);
	
	message_begin(MSG_BROADCAST, g_msgSayText);
	write_byte(sender);
	write_string(szText);
	message_end();
}
