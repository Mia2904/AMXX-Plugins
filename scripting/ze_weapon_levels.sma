#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

#define PLUGIN "Armas de Nivel"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

/* hacer natives

get damage
get model
hacer internamente
efecto rayo traceattack
efecto particulas en killed
recoil
velocidad de disparo
otros efectos

Por hacer:
Renovar el menu de armas
Documentacion de disparo

Nivel 2:
Mejora de dmg
Mejora de recoil

Nivel 3:
Mejora de recoil / time
Balas viajan mas rapido (efecto)
Nuevo model

Nivel 4:
Mejora de dmg / recoil / time
Incremento del max clip
Aura plateada

Nivel 5:
No Recoil
Mejora de dmg
Incremento del max clip
Radioactiva
Aura dorada
Nuevo model
Hace explotar a los zombies
*/

enum (+= 100)
{
	TASK_AURA = 555
};

enum _:Vector
{
	X = 0,
	R = 0,
	Y = 1,
	G = 1,
	Z = 2,
	B = 2
};

enum SprIndex
{
	SPR_FLARE6 = 0,
	SPR_LIGHTNING,
	SPR_XBEAM5,
	SPR_BLOOD,
	SPR_BLOODSPRAY,
	SPR_SMOKE,
	SPR_EXPLODE
};

const SprIndex:SPR_NONE = SprIndex:-1;

enum RgbColor
{
	COLOR_WHITE = 0,
	COLOR_RED,
	COLOR_GREEN,
	COLOR_BLUE,
	COLOR_YELLOW,
	COLOR_CYAN,
	COLOR_MAGENTA,
	COLOR_PURPLE,
	COLOR_ORANGE
};

const RgbColor:COLOR_NONE = RgbColor:-1;

new const RGB_COLORS[RgbColor][Vector] =
{
	{	150,	170,	200	},	// Blanco
	{	255,	0,	0	},	// Rojo
	{	0,	255,	0	},	// Verde
	{	0,	0,	255	},	// Azul
	{	255,	255,	0	},	// Amarillo
	{	0,	250,	250	},	// Celeste
	{	170,	50,	100	},	// Magenta
	{	100,	50,	200	},	// Morado
	{	255,	150,	100	}	// Naranja
};

/* Efectos:
1 - Trace balas
2 - Cuadrado
4 - Sonido balas
8 - Aura
16 - Explosion al matar
32 - Particulas al matar
*/
enum ShootFx (*=2)
{
	SFX_TRACE = 1,
	SFX_SQUARE,
	SFX_BULSOUND,
	SFX_AURA,
	SFX_EXPLO,
	SFX_PARTICLES,
	SFX_UNKNOWN
};

const ShootFx:SFX_NONE = ShootFx:0;

new g_sprindex[SprIndex];

#define MODELS_DIR "models/perugaming_wpn/"
#define SOUNDS_DIR "perugaming_wpn/"

/* Equivalente:
1 TMP
2 MAC10
3 M3
4 XM1014
5 MP5
6 P90
7 GALIL
8 FAMAS
9 AUG
10 M4A1
11 AK47
12 SCOUT
13 G3SG1
14 AWP */

// Pitch:
// Menor a 0 indica el rango en el que va a oscilar (random)

// Nota: Todos los models en MODELS_DIR (models/ze_perugaming/) y sonidos en SOUNDS_DIR (sounds/ze_perugaming/)
enum WEAPON_LEVEL_STRUCT
{
	BUY_COST,
	NAME[32],
	CSW_ID,
	CLIP,
	Float:DMG,
	Float:RECOIL,
	Float:FIRE_INTERVAL,
	V_MODEL[30],
	SHOOT_SOUND[20],
	SHOOT_PITCH,
	ShootFx:SHOOT_EFFECTS,
	RgbColor:EFFECTS_COLOR,
	SprIndex:EFFECTS_SPR
};

// Para tenerlo mas ordenado
const ShootFx:SFX_1 = SFX_TRACE;
const ShootFx:SFX_2 = SFX_1|SFX_BULSOUND;
const ShootFx:SFX_3 = SFX_2|SFX_AURA|SFX_UNKNOWN;
const ShootFx:SFX_4 = SFX_3|SFX_EXPLO;
const ShootFx:SFX_5 = SFX_3|SFX_PARTICLES;

new const Weapons_Var[][WEAPON_LEVEL_STRUCT] =
{
	//{ 5, "TMP Lv 2", CSW_TMP, 30, 1.2, 0.9, 0.9, "", "", 90, SFX_NONE, COLOR_NONE, SPR_NONE },
	//{ 5, "MAC-10 Lv 2", CSW_MAC10, 30, 1.2, 0.9, 0.9, "", "", 90, SFX_NONE, COLOR_NONE, SPR_NONE },
	//{ 5, "Magnum MP5 Lv 1", CSW_MP5NAVY, 30, 1.1, 0.7, 0.6, "v_mp5.mdl", "mp5-1.wav", 98, SFX_2, COLOR_PURPLE, SPR_XBEAM5 },
	//{ 1, "P90 Lv 1", CSW_P90, 50, 1.1, 0.9, 0.9, "v_p90.mdl", "p90-1.wav", 98, SFX_NONE, COLOR_BLUE, SPR_XBEAM5 },
	//{ 3, "P90 Lv 2", CSW_P90, 55, 1.3, 0.7, 0.5, "v_p90.mdl", "p90-1.wav", 98, SFX_2, COLOR_GREEN, SPR_SMOKE },
	
	{ 1, "Dual Lego Lv 1", CSW_P90, 50, 1.1, 0.9, 0.9, "v_p90.mdl", "p90-1.wav", 98, SFX_1, COLOR_BLUE, SPR_XBEAM5 },
	{ 1, "PLA G35C", CSW_SG552, 40, 1.2, 1.1, 0.9, "v_pla_g35c.mdl", "pla_g35c.wav", 98, SFX_1, COLOR_GREEN, SPR_SMOKE },
	{ 1, "Magnum MP5", CSW_MP5NAVY, 35, 1.3, 0.9, 0.85, "v_mp5.mdl", "mp5-1.wav", 98, SFX_1, COLOR_WHITE, SPR_SMOKE },
	{ 2, "Dual LEGO Lv 2", CSW_P90, 55, 1.3, 0.7, 0.5, "v_p90.mdl", "p90-1.wav", 98, SFX_2, COLOR_GREEN, SPR_SMOKE },
	{ 3, "Asimov", CSW_AWP, 12, 2.2, 1.1, 0.9, "v_Asimov.mdl", "", -10, SFX_2, COLOR_ORANGE, SPR_LIGHTNING },
	{ 5, "LEGO Shotgun", CSW_XM1014, 12, 1.4, 0.8, 1.1, "v_LEGOShotgun.mdl", "", -10, SFX_2, COLOR_ORANGE, SPR_XBEAM5 },
	{ 5, "PP-2000 Bastard Lv 1", CSW_TMP ,35, 1.4, 0.8, 0.8, "v_tmp_3.mdl", "tmp-0.wav", 93, SFX_2, COLOR_PURPLE, SPR_XBEAM5 },
	{ 6, "Monkey MP5 Lv 1", CSW_MP5NAVY, 40, 1.4, 0.5, 0.5, "v_mp6.mdl", "mp5-2.wav", -10, SFX_3, COLOR_RED, SPR_LIGHTNING },
	{ 7, "Red Hazard", CSW_G3SG1, 35, 1.4, 0.8, 0.9, "v_Red_Hazard.mdl", "", -10, SFX_3, COLOR_RED, SPR_LIGHTNING },
	{ 8, "Cursed MAC-11 Lv 2", CSW_MAC10, 40, 1.4, 0.6, 0.7, "v_mac_3.mdl", "tmp-0.wav", 85, SFX_3, COLOR_GREEN, SPR_SMOKE },
	{ 9, "PP-2000 Bastard Lv 2", CSW_TMP, 40, 1.7, 0.6, 0.7, "v_tmp_3.mdl", "tmp-0.wav", 85, SFX_3, COLOR_YELLOW, SPR_SMOKE },
	{ 10, "Decimator", CSW_M4A1, 35, 1.8, 0.6, 0.3, "v_Decimator.mdl", "", -10, SFX_4, COLOR_PURPLE, SPR_LIGHTNING },
	{ 11, "P90 Lv 3", CSW_P90, 55, 1.4, 0.6, 0.5, "v_p91.mdl", "p90-2.wav", -10, SFX_4, COLOR_YELLOW, SPR_LIGHTNING },
	{ 12, "Special Force", CSW_M3, 14, 2.4, 0.7, 1.3, "v_Special_Force.mdl", "", -10, SFX_4, COLOR_RED, SPR_LIGHTNING },
	{ 14, "Crossfire CF-05", CSW_MAC10, 47, 1.5, 0.3, 0.4, "v_mac_5.mdl", "tmp-1.wav", -10, SFX_4, COLOR_RED, SPR_LIGHTNING },
	{ 16, "Monkey MP5 Lv 2", CSW_MP5NAVY, 45, 1.5, 0.4, 0.4, "v_mp6.mdl", "mp5-2.wav", -10, SFX_4, COLOR_CYAN, SPR_LIGHTNING },
	{ 18, "Blaze", CSW_UMP45, 40, 1.7, 0.5, 1.2, "v_Blaze.mdl", "", -10, SFX_4, COLOR_RED, SPR_LIGHTNING },
	{ 20, "P90 Lv 4", CSW_P90, 60, 1.5, 0.7, 0.5, "v_p91.mdl", "p90-2.wav", -10, SFX_4, COLOR_ORANGE, SPR_LIGHTNING },
	{ 22, "Canon of Holy Water", CSW_MP5NAVY, 50, 1.9, 0.6, 0.6, "v_CoHW.mdl", "CoHW.wav", -25, SFX_4, COLOR_BLUE, SPR_LIGHTNING },
	{ 25, "Judgement of Anubis Bizon", CSW_TMP, 45, 2.0, 0.4, 0.5, "v_tmp_5.mdl", "tmp-1.wav", -10, SFX_4, COLOR_CYAN, SPR_LIGHTNING },
	{ 28, "Turbulent 5", CSW_AK47, 40, 2.2, 0.3, 0.9, "v_turbulent5.mdl", "turbulent5.wav", -10, SFX_5, COLOR_YELLOW, SPR_LIGHTNING },
	{ 30, "DragonKing", CSW_M4A1, 45, 2.4, 0.4, 0.8, "v_DragonKing.mdl", "DragonKing.wav", -10, SFX_5, COLOR_RED, SPR_LIGHTNING },
	{ 34, "Golden Century", CSW_M4A1, 47, 2.6, 0.3, 0.8, "v_Golden_Century.mdl", "", -10, SFX_5, COLOR_ORANGE, SPR_LIGHTNING },
	{ 38, "Paladin", CSW_AK47, 47, 2.7, 0.1, 0.8, "v_Paladin.mdl", "", -10, SFX_5, COLOR_WHITE, SPR_LIGHTNING },
	{ 45, "Green Glass", CSW_AWP, 12, 5.0, 0.9, 1.1, "v_Green_Glass.mdl", "", -10, SFX_5, COLOR_GREEN, SPR_LIGHTNING }
};

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" };

new const WPN_EVENTS[][] =
{
	"events/tmp.sc",
	"events/mac10.sc",
	"events/ump45.sc",
	"events/m3.sc",
	"events/xm1014.sc",
	"events/mp5n.sc",
	"events/p90.sc",
	//"events/galil.sc",
	//"events/famas.sc",
	//"events/aug.sc",
	"events/sg552.sc",
	"events/m4a1.sc",
	"events/ak47.sc",
	//"events/scout.sc",
	"events/g3sg1.sc",
	"events/awp.sc"
};

#define is_player(%0) (1<=%0<=32)

new g_iOldClip;
new Float:g_vPunchAngle[3];

new g_fwPrecache;
new g_orig_event;
new g_BlockPlayback;

native ze_wpn_menu_finished(id, item);
native ze_get_user_glow(id);

public plugin_natives()
{
	register_native("ze_wpn_display_menu", "native_display_menu", 1);
}

public plugin_precache()
{
	g_sprindex[SPR_BLOOD] = precache_model("sprites/blood.spr")
	g_sprindex[SPR_BLOODSPRAY] = precache_model("sprites/bloodspray.spr")
	g_sprindex[SPR_FLARE6] = precache_model("sprites/Flare6.spr")
	g_sprindex[SPR_LIGHTNING] = precache_model("sprites/lgtning.spr")
	g_sprindex[SPR_XBEAM5] = precache_model("sprites/xbeam5.spr")
	g_sprindex[SPR_SMOKE] = precache_model("sprites/smoke.spr")
	g_sprindex[SPR_EXPLODE] = precache_model("sprites/fexplo1.spr");
	
	new i;
	
	new szSoundDir[120], szModelDir[120];	
	new lenm, lens;
	lenm = copy(szModelDir, charsmax(szModelDir), MODELS_DIR);
	lens = copy(szSoundDir, charsmax(szSoundDir), SOUNDS_DIR);
	
	for (i = 0; i < sizeof Weapons_Var; i++)
	{
		if (Weapons_Var[i][V_MODEL])
		{
			copy(szModelDir[lenm], charsmax(szModelDir)-lenm, Weapons_Var[i][V_MODEL]);
			precache_model(szModelDir);
		}
		
		if (Weapons_Var[i][SHOOT_SOUND])
		{
			copy(szSoundDir[lens], charsmax(szSoundDir)-lens, Weapons_Var[i][SHOOT_SOUND]);
			precache_sound(szSoundDir);
		}
	}
	
	g_fwPrecache = register_forward(FM_PrecacheEvent , "fw_PrecacheEvent_Post", 1);
}

public fw_PrecacheEvent_Post(type, const name[])
{
	for (new i = 0; i < sizeof WPN_EVENTS; i++)
	{
		if (equal(WPN_EVENTS[i], name))
		{
			g_orig_event |= (1<<get_orig_retval());
			return FMRES_HANDLED;
		}
	}
	
	return FMRES_IGNORED;
}

new g_currentweapon[33];
new g_currentvar[33];
new g_cb_item_disabled;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg");
	
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1);
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1);
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1);
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1);
	
	new i;	
	for (i = 0; i < sizeof WEAPONENTNAMES; i++)
	{
		if (!WEAPONENTNAMES[i][0])
			continue;
		
		RegisterHam(Ham_Weapon_PrimaryAttack, WEAPONENTNAMES[i], "fw_Weapon_PrimaryAttack_Pre", 0);
		RegisterHam(Ham_Weapon_PrimaryAttack, WEAPONENTNAMES[i], "fw_Weapon_PrimaryAttack_Post", 1);
		RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1);
		//RegisterHam(Ham_Weapon_Reload, ENT_NAMES[i], "fw_Weapon_Reload_Post", 1);
		RegisterHam(Ham_Item_AttachToPlayer, WEAPONENTNAMES[i], "Item_AttachToPlayer");
		
		if (equal(WEAPONENTNAMES[i][7], "m3") || equal(WEAPONENTNAMES[i][7], "xm1014"))
		{
			RegisterHam(Ham_Item_PostFrame, WEAPONENTNAMES[i], "Shotgun_PostFrame");
			RegisterHam(Ham_Weapon_WeaponIdle, WEAPONENTNAMES[i], "Shotgun_WeaponIdle");
		}
		else
		{
			RegisterHam(Ham_Item_PostFrame, WEAPONENTNAMES[i], "Item_PostFrame");
		}
	}
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Pre");
	RegisterHam(Ham_TakeDamage, "func_breakable", "fw_TakeDamage_Pre");
	RegisterHam(Ham_Killed, "player", "fw_Player_Killed_Pre");
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	
	unregister_forward(FM_PrecacheEvent, g_fwPrecache, 1);
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent_Pre");
	register_forward(FM_SetModel, "fw_SetModel_Pre");
	
	g_cb_item_disabled = menu_makecallback("cb_disabled");
	
	//register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	
	register_clcmd("wpn", "cmdwpn", ADMIN_RCON);
}

public zp_user_humanized_pre(id, survivor)
{
	if (survivor)
		g_currentvar[id] = 0;
}

public zp_user_infected_pre(id, infector, nemesis)
{
	g_currentvar[id] = 0;
}

public event_round_start()
{
	arrayset(g_currentvar, 0, 33);
	arrayset(g_currentweapon, 0, 33);
}

public cb_disabled(id, menu, item)
	return ITEM_DISABLED;

public native_display_menu(id, reset, var_pos)
{
	if (var_pos > 0 && reset >= Weapons_Var[var_pos-1][BUY_COST])
	{
		var_pos--;
		
		new csw = Weapons_Var[var_pos][CSW_ID];
	
		g_currentvar[id] = var_pos + 1;
		
		strip_user_weapons(id);
		new ent = give_item(id, WEAPONENTNAMES[csw]);
		cs_set_weapon_ammo(ent, Weapons_Var[var_pos][CLIP]);
		g_currentweapon[id] = cs_get_weapon_id(ent);
		cs_set_user_bpammo(id, csw, 200);
		
		ze_wpn_menu_finished(id, var_pos + 1);
		
		return;
	}
	
	new menu = menu_create("\r[ZE]\y Armas del\r Inframundo", "menu_select_weapon");
	static text[35];
	
	for (new i = 0; i < sizeof Weapons_Var; i++)
	{
		if (reset >= Weapons_Var[i][BUY_COST])
			menu_additem(menu, Weapons_Var[i][NAME]);
		else
		{
			formatex(text, charsmax(text), "\y[Resets %d+]\d %s", Weapons_Var[i][BUY_COST], Weapons_Var[i][NAME]);
			menu_additem(menu, text, .callback = g_cb_item_disabled);
		}
	}
	
	//menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_setprop(menu, MPROP_BACKNAME, "\wAnterior")
	menu_setprop(menu, MPROP_NEXTNAME, "\wSiguiente")
	menu_setprop(menu, MPROP_EXITNAME, "\ySalir")
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");

	menu_display(id, menu);
}

public cmdwpn(id)
{
	if (~get_user_flags(id) & ADMIN_RCON)
		return PLUGIN_CONTINUE;
	
	new menu = menu_create("\r[ZE]\y Elegir arma", "menu_select_weapon");
	
	for (new i = 0; i < sizeof Weapons_Var; i++)
		menu_additem(menu, Weapons_Var[i][NAME]);
	
	//menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public menu_select_weapon(id, menu, var_pos)
{
	menu_destroy(menu);
	
	if (!(0 <= var_pos < sizeof Weapons_Var) || !is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return PLUGIN_HANDLED;
	
	new csw = Weapons_Var[var_pos][CSW_ID];
	
	g_currentvar[id] = var_pos + 1;
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	new ent = give_item(id, WEAPONENTNAMES[csw]);
	cs_set_weapon_ammo(ent, Weapons_Var[var_pos][CLIP]);
	g_currentweapon[id] = cs_get_weapon_id(ent);
	cs_set_user_bpammo(id, csw, 200);
	
	ze_wpn_menu_finished(id, var_pos + 1);
	
	return PLUGIN_HANDLED;
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	static szTruncatedWeapon[10], id;
	
	id = get_msg_arg_int(1);
	
	if (!is_player(id))
		return PLUGIN_CONTINUE;
	
	static weaponid; weaponid = g_currentweapon[id];
	
	if (weaponid > 30)
		return PLUGIN_CONTINUE;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
	
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return PLUGIN_CONTINUE;
		
	if (Weapons_Var[var_pos][CSW_ID] != weaponid)
		return PLUGIN_CONTINUE;
	
	if (!(Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_UNKNOWN))
		return PLUGIN_CONTINUE;
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon));
	
	if (!equal(WEAPONENTNAMES[weaponid][7], szTruncatedWeapon, strlen(szTruncatedWeapon)))
		return PLUGIN_CONTINUE;
	
	// Headshot
	//set_msg_arg_int(3, ARG_BYTE, 1);
	
	set_msg_arg_string(4, "unknown");
	
	return PLUGIN_CONTINUE;
}

#define m_fWeaponState 74
#define WEAPONSTATE_GLOCK18_BURST_MODE (1<<1)
#define WEAPONSTATE_FAMAS_BURST_MODE (1<<4)

#define m_pPlayer 41
#define m_flNextPrimaryAttack   46
#define m_flNextSecondaryAttack 47
#define m_iClip 51
#define m_fInReload 54

public fw_PlaybackEvent_Pre(flags, id, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!g_BlockPlayback || !(g_orig_event & (1 << eventid)) || !is_player(id))
		return FMRES_IGNORED;
	
	static weaponid; weaponid = g_currentweapon[id];
	
	if (weaponid > 30)
		return FMRES_IGNORED;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
	
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return FMRES_IGNORED;
	
	if (Weapons_Var[var_pos][CSW_ID] != g_currentweapon[id])
		return FMRES_IGNORED;
	
	if (!Weapons_Var[var_pos][SHOOT_SOUND])
		return FMRES_IGNORED;
	
	static pitch;
	pitch = Weapons_Var[var_pos][SHOOT_PITCH];
	switch (pitch)
	{
		case -100 .. -1: pitch = PITCH_NORM + pitch + random_num(0, -2*pitch);
		case 0: pitch = PITCH_NORM;
	}
	
	static path[80], len;
	if (!len)
		len = copy(path, charsmax(path), SOUNDS_DIR);
	
	copy(path[len], charsmax(path)-len, Weapons_Var[var_pos][SHOOT_SOUND]);
	emit_sound(id, CHAN_WEAPON, path, VOL_NORM, ATTN_NORM, 0, pitch);
	
	return FMRES_HANDLED;
}

public fw_Weapon_PrimaryAttack_Pre(iEnt)
{
	static id; id = get_pdata_cbase(iEnt, m_pPlayer, 4);
	static weaponid; weaponid = g_currentweapon[id];
		
	if (weaponid > 30)
		return HAM_IGNORED;
		
	static var_pos; var_pos = g_currentvar[id] - 1;
	
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return HAM_IGNORED;
		
	if (Weapons_Var[var_pos][CSW_ID] != g_currentweapon[id])
		return HAM_IGNORED;
	
	g_iOldClip = get_pdata_int(iEnt, m_iClip, 4);
	
	if( g_iOldClip <= 0 && !get_pdata_int(iEnt, m_fInReload, 4) )
	{
		ExecuteHamB(Ham_Weapon_PlayEmptySound, iEnt);
		set_pdata_float(iEnt, m_flNextPrimaryAttack, 0.2, 4);
		return HAM_SUPERCEDE;
	}
	else
	{
		pev(id,pev_punchangle, g_vPunchAngle);
		
		if (Weapons_Var[var_pos][SHOOT_SOUND])
		{
			g_BlockPlayback = 1;
		}
		
		static endorigin[3];//, startorigin[3]
		
		if (Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_1)
		{
			//get_user_origin(id, startorigin, 1);
			get_user_origin(id, endorigin, 3);
			//client_print(0, print_chat, "Mandando fx %s %s", (Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_TRACE) ? "TRACE " : "", (Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_SQUARE) ? "SQUARE" : "");
			
			if (Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_TRACE)
				bullet_trace(id, endorigin, Weapons_Var[var_pos][EFFECTS_SPR], Weapons_Var[var_pos][EFFECTS_COLOR], 150, 2, 0, 1);
			
			//if (Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_SQUARE)
			//	bullet_square(startorigin, endorigin, SPR_SMOKE, 1);
		}
	}
	
	return HAM_IGNORED;
}

public fw_Weapon_PrimaryAttack_Post(iEnt)
{
	g_BlockPlayback = 0;
	
	static id;
	id = get_pdata_cbase(iEnt, m_pPlayer, 4);
	
	if( g_iOldClip > get_pdata_int(iEnt, m_iClip, 4) )
	{
		static weaponid; weaponid = g_currentweapon[id];
		
		if (weaponid > 30)
			return HAM_IGNORED;
		
		static var_pos; var_pos = g_currentvar[id] - 1;
		
		if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
			return HAM_IGNORED;
		
		if (Weapons_Var[var_pos][CSW_ID] != g_currentweapon[id])
			return HAM_IGNORED;
		
		static Float:push[3];
		pev(id,pev_punchangle,push);
		xs_vec_sub(push,g_vPunchAngle,push);
		
		xs_vec_mul_scalar(push, Weapons_Var[var_pos][RECOIL],push);
		xs_vec_add(push,g_vPunchAngle,push);
		set_pev(id,pev_punchangle,push);
		
		set_pdata_float(iEnt, m_flNextPrimaryAttack, get_pdata_float(iEnt, m_flNextPrimaryAttack, 4) * Weapons_Var[var_pos][FIRE_INTERVAL], 4);
		set_pdata_float(iEnt, m_flNextSecondaryAttack, get_pdata_float(iEnt, m_flNextSecondaryAttack, 4) * Weapons_Var[var_pos][FIRE_INTERVAL], 4);
		
		/*if (Weapons_Var[var_pos][SHOOT_SOUND])
		{
			static pitch;
			pitch = Weapons_Var[var_pos][SHOOT_PITCH];
			switch (pitch)
			{
				case -100 .. -1: pitch = PITCH_NORM + pitch + random_num(0, -2*pitch);
				case 0: pitch = PITCH_NORM;
			}
			static path[80], len;
			if (!len)
				len = copy(path, charsmax(path), SOUNDS_DIR);
			
			copy(path[len], charsmax(path)-len, Weapons_Var[var_pos][SHOOT_SOUND]);
			emit_sound(id, CHAN_WEAPON, path, VOL_NORM, ATTN_NORM, 0, pitch);
		}*/
	}
	
	return HAM_IGNORED;
}

public fw_Item_Deploy_Post(iEnt)
{
	static id;
	id = get_pdata_cbase(iEnt, m_pPlayer, 4);
	
	// Get weapon's id
	static weaponid; weaponid = cs_get_weapon_id(iEnt);
	g_currentweapon[id] = weaponid;
	
	replace_weapon_models(id, weaponid);
	
	if (weaponid > 30)
		return HAM_IGNORED;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
	
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return HAM_IGNORED;
	
	if (Weapons_Var[var_pos][CSW_ID] != weaponid)
		return HAM_IGNORED;
	
	if (Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_AURA && is_user_alive(id) && !ze_get_user_glow(id))
	{
		new RgbColor:color = Weapons_Var[var_pos][EFFECTS_COLOR];
		set_user_rendering(id, kRenderFxGlowShell, RGB_COLORS[color][R], RGB_COLORS[color][G], RGB_COLORS[color][B], kRenderNormal, 25);
	}
	
	return HAM_IGNORED;
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	const USE_STOPPED = 0;

	// Someone stopped using a stationary gun
	if (use_type == USE_STOPPED && is_player(caller) && is_user_connected(caller))
		replace_weapon_models(caller, g_currentweapon[caller]); // replace weapon models (bugfix)
}

public fw_TakeDamage_Pre(victim, inflictor, id, Float:damage)
{
	if (victim == id)
		return HAM_IGNORED;
	
	if (!is_player(id))
		return HAM_IGNORED;
	
	static weaponid; weaponid = g_currentweapon[id];
	
	if (weaponid > 30)
		return HAM_IGNORED;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
	
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return HAM_IGNORED;
		
	if (Weapons_Var[var_pos][CSW_ID] != weaponid)
		return HAM_IGNORED;
	
	SetHamParamFloat(4, damage *= Float:Weapons_Var[var_pos][DMG]);
	
	return HAM_IGNORED;
}

public fw_Player_Killed_Pre(victim, id, shouldgib)
{
	if (victim == id)
		return HAM_IGNORED;
	
	if (!is_player(id))
		return HAM_IGNORED;
	
	static weaponid; weaponid = g_currentweapon[id];
	
	if (weaponid > 30)
		return HAM_IGNORED;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
	
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return HAM_IGNORED;
		
	if (Weapons_Var[var_pos][CSW_ID] != weaponid)
		return HAM_IGNORED;
	
	#define GIB_ALWAYS 2
	
	static origin[3];
	
	if (Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_EXPLO)
	{
		get_user_origin(victim, origin, 0);
		body_explotion(origin);
	}
	
	if (Weapons_Var[var_pos][SHOOT_EFFECTS] & SFX_PARTICLES)
		SetHamParamInteger(3, GIB_ALWAYS);
	
	return HAM_IGNORED;
}

replace_weapon_models(id, weaponid)
{
	if (weaponid > 30)
		return;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
	
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return;
		
	if (Weapons_Var[var_pos][CSW_ID] != g_currentweapon[id])
		return;
	
	static path[80], len;
	if (!len)
		len = copy(path, charsmax(path), MODELS_DIR);
	
	if (Weapons_Var[var_pos][V_MODEL])
	{
		copy(path[len], charsmax(path)-len, Weapons_Var[var_pos][V_MODEL]);
		set_pev(id, pev_viewmodel2, path);
	}
}

stock cs_get_weaponbox_type(iWeaponBox) // assuming weaponbox contain only 1 weapon
{
	new iWeapon
	
	new const m_rgpPlayerItems_CWeaponBox[6] = { 34 , 35 , ... };
	const XO_CWEAPONBOX = 4;
	
	for(new i=1; i<=5; i++)
	{
		iWeapon = get_pdata_cbase(iWeaponBox, m_rgpPlayerItems_CWeaponBox[i], XO_CWEAPONBOX);
		if( iWeapon > 0 )
		{
			return cs_get_weapon_id(iWeapon);
		}
	}
	
	return 0;
}

/* effects */
stock npc_beam_disk(Float:origin[3], SprIndex:sprite = SPR_LIGHTNING, RgbColor:color = COLOR_RED, speed = 0, Float:radius = 1000.0, brightness = 255, secs = 5)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMDISK) // TE_BEAMDISK
	engfunc(EngFunc_WriteCoord, origin[X]); // Start X
	engfunc(EngFunc_WriteCoord, origin[Y]); // Start Y
	engfunc(EngFunc_WriteCoord, origin[Z]-200.0); // Start Z
	engfunc(EngFunc_WriteCoord, 10.0)		// coord coord coord (axis x, y, z)
	engfunc(EngFunc_WriteCoord, 10.0)
	engfunc(EngFunc_WriteCoord, radius)		
	/*engfunc(EngFunc_WriteCoord, origin[X]); // Start X
	engfunc(EngFunc_WriteCoord, origin[Y]); // Start Y
	engfunc(EngFunc_WriteCoord, origin[Z]); // Start Z
	engfunc(EngFunc_WriteCoord, origin[X]); // End X
	engfunc(EngFunc_WriteCoord, origin[Y]); // End Y
	engfunc(EngFunc_WriteCoord, origin[Z]+radius); // End Z*/
	write_short(g_sprindex[sprite])			// short (sprite index)
	write_byte(0)					// byte (starting frame)
	write_byte(0)					// byte (frame rate in 0.1's)
	write_byte(10*secs)				// byte (life in 0.1's)
	write_byte(0)					// byte (line width in 0.1's)
	write_byte(150)					// byte (noise amplitude in 0.01's)
	write_byte(RGB_COLORS[color][R])		// byte,byte,byte (color)
	write_byte(RGB_COLORS[color][G])
	write_byte(RGB_COLORS[color][B])
	write_byte(brightness)				// byte (brightness)
	write_byte(speed)				// byte (scroll speed in 0.1's)
	message_end()
}

stock npc_beam_torus(Float:origin[3], SprIndex:sprite = SPR_XBEAM5, RgbColor:color = COLOR_RED, speed = 0, Float:radius = 1000.0, brightness = 255, secs = 8)
{
	message_begin(MSG_PVS, SVC_TEMPENTITY, int_origin);
	write_byte(TE_BEAMTORUS);
	engfunc(EngFunc_WriteCoord, origin[X]); // Start X
	engfunc(EngFunc_WriteCoord, origin[Y]); // Start Y
	engfunc(EngFunc_WriteCoord, origin[Z]); // Start Z
	engfunc(EngFunc_WriteCoord, origin[X]+radius); // End X
	engfunc(EngFunc_WriteCoord, origin[Y]+radius); // End Y
	engfunc(EngFunc_WriteCoord, origin[Z]+radius); // End Z
	write_short(g_sprindex[sprite]); // sprite
	write_byte(0); // Starting frame
	write_byte(0); // framerate * 0.1
	write_byte(10*secs); // life * 0.1
	write_byte(500); // width
	write_byte(0); // noise
	write_byte(RGB_COLORS[color][R])		// byte,byte,byte (color)
	write_byte(RGB_COLORS[color][G])
	write_byte(RGB_COLORS[color][B])
	write_byte(brightness)				// byte (brightness)
	write_byte(speed)				// byte (scroll speed in 0.1's)
	message_end()
}

stock npc_beam_ent(ent, id, SprIndex:sprite = SPR_XBEAM5, RgbColor:color = COLOR_WHITE, brightness = 255, secs = 5, noise = 20, speed = 50)
{
	message_begin(MSG_PVS, SVC_TEMPENTITY, int_origin)
	write_byte(TE_BEAMENTS)
	write_short(ent) 				// start entity
	write_short(id)					// end entity
	write_short(g_sprindex[sprite])			// sprite index
	write_byte(0)					// byte (starting frame)
	write_byte(0)					// byte (frame rate in 0.1's)
	write_byte(10*secs)				// byte (life in 0.1's)
	write_byte(50)					// byte (line width in 0.1's) 50
	write_byte(noise)				// byte (noise amplitude in 0.01's) 20
	write_byte(RGB_COLORS[color][R]) 		// Red
	write_byte(RGB_COLORS[color][G]) 		// Green
	write_byte(RGB_COLORS[color][B])	 	// Blue
	write_byte(brightness)				// brightness
	write_byte(speed) 				// (scroll speed in 0.1's)
	message_end()
}

stock npc_large_funnel(Float:origin[3], SprIndex:sprite = SPR_LIGHTNING, flag = 1)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_LARGEFUNNEL)
	engfunc(EngFunc_WriteCoord, origin[X]); // Start X
	engfunc(EngFunc_WriteCoord, origin[Y]); // Start Y
	engfunc(EngFunc_WriteCoord, origin[Z]); // Start Z
	write_short(g_sprindex[sprite]) // sprite
	write_short(flag) // flag
	message_end()
}

stock npc_explotion(Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0]+random_float(-150.0, 150.0))
	engfunc(EngFunc_WriteCoord, origin[1]+random_float(-150.0, 150.0))
	engfunc(EngFunc_WriteCoord, origin[2]+random_float(-150.0, 150.0))
	write_short(g_sprindex[SPR_EXPLODE])
	write_byte(30)
	write_byte(15)
	write_byte(0)
	message_end(); 
}

stock beam_cylinder(Float:origin[3], SprIndex:sprite = SPR_SMOKE, RgbColor:color = COLOR_GREEN, Float:radius = 100.0, brightness = 255, secs  = 1)
{
	message_begin(MSG_PVS, SVC_TEMPENTITY, int_origin)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, origin[X])
	engfunc(EngFunc_WriteCoord, origin[Y])
	engfunc(EngFunc_WriteCoord, origin[Z])
	engfunc(EngFunc_WriteCoord, origin[X])
	engfunc(EngFunc_WriteCoord, origin[Y])
	engfunc(EngFunc_WriteCoord, origin[Z] + radius)
	write_short(g_sprindex[sprite])
	write_byte(0)
	write_byte(0)
	write_byte(secs*10)
	write_byte(10)
	write_byte(0)
	write_byte(RGB_COLORS[color][R]) 		// Red
	write_byte(RGB_COLORS[color][G]) 		// Green
	write_byte(RGB_COLORS[color][B])	 	// Blue
	write_byte(brightness)
	write_byte(0)
	message_end()
}

stock screen_fade(id, RgbColor:color = COLOR_RED, alpha = 255, secs = 1)
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_msgScreenFade, _, id)
	write_short(secs*4096) // duracion
	write_short(0) // tiempo de espera
	write_short(0x0000)
	write_byte(RGB_COLORS[color][R]) 		// Red
	write_byte(RGB_COLORS[color][G]) 		// Green
	write_byte(RGB_COLORS[color][B])	 	// Blue
	write_byte(alpha)
	message_end()
}

stock screen_shake(id, amplitude = 10)
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_msgScreenShake, _,id)
	write_short(15*4096)
	write_short(4096*amplitude)
	write_short(200*256)
	message_end()
}

public task_aura(data[], id)
{
	id -= TASK_AURA;
	
	if (!is_user_alive(id))
	{
		remove_task(id + TASK_AURA);
		return;
	}
	
	static origin[3];
	get_user_origin(id, origin, 0);
	
	dynamic_aura(origin, 25, RgbColor:data[2], 4);
}

stock dynamic_aura(origin[3], radius = 50, RgbColor:color = COLOR_WHITE, duration = 5)
{
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_DLIGHT);
	write_coord(origin[X])
	write_coord(origin[Y])
	write_coord(origin[Z])
	write_byte(radius)
	write_byte(RGB_COLORS[color][R]) 		// Red
	write_byte(RGB_COLORS[color][G]) 		// Green
	write_byte(RGB_COLORS[color][B])	 	// Blue
	write_byte(duration);	// life * 10
	write_byte(0)
	message_end();
}

stock bullet_trace(id, endorigin[3], SprIndex:sprite = SPR_XBEAM5, RgbColor:color = COLOR_WHITE, brightness = 255, decisecs = 5, noise = 20, speed = 50)
{
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte (TE_BEAMENTPOINT)
	write_short(id | 0x1000) // lean el comentario de abajo :D
	write_coord(endorigin[0])        // Start X
	write_coord(endorigin[1])        // Start Y
	write_coord(endorigin[2])        // Start Z
	write_short(g_sprindex[sprite])			// sprite index
	write_byte(0)					// byte (starting frame)
	write_byte(0)					// byte (frame rate in 0.1's)
	write_byte(decisecs)				// byte (life in 0.1's)
	write_byte(50)					// byte (line width in 0.1's) 50
	write_byte(noise)				// byte (noise amplitude in 0.01's) 20
	write_byte(RGB_COLORS[color][R]) 		// Red
	write_byte(RGB_COLORS[color][G]) 		// Green
	write_byte(RGB_COLORS[color][B])	 	// Blue
	write_byte(brightness)				// brightness
	write_byte(speed) 				// (scroll speed in 0.1's)
	message_end()
}

stock body_explotion(origin[3])
{
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_TAREXPLOSION) // TE_
	write_coord(origin[0]) // X
	write_coord(origin[1]) // Y
	write_coord(origin[2]) // Z
	message_end();
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_LAVASPLASH) // TE_
	write_coord(origin[0]) // X
	write_coord(origin[1]) // Y
	write_coord(origin[2]) // Z
	message_end();
}

/*stock bullet_square(startorigin[3], endorigin[3], SprIndex:sprite = SPR_XBEAM5, secs = 5)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY) //white squares
	write_byte(TE_SPRITETRAIL)
	write_coord(startorigin[0]) //startorigin
	write_coord(startorigin[1])
	write_coord(startorigin[2])
	write_coord(endorigin[0]) //endorigin
	write_coord(endorigin[1])
	write_coord(endorigin[2])
	write_short(g_sprindex[sprite]) //sprite
	write_byte(70) //count
	write_byte(10*secs) //life
	write_byte(1) //scale
	write_byte(0) //velocity along vector 10's
	write_byte(0) //randomness of velocity in 10's
	message_end()
}*/

/* weas del clip */
// weapons offsets
#define XTRA_OFS_WEAPON			4
#define m_iId					43
#define m_fKnown				44
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_fInSpecialReload		55
#define m_fSilent				74

enum {
	idle,
	shoot1,
	shoot2,
	insert,
	after_reload,
	start_reload,
	draw
}

enum _:ShotGuns {
	m3,
	xm1014
}

const NOCLIP_WPN_BS	= ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
const SHOTGUNS_BS	= ((1<<CSW_M3)|(1<<CSW_XM1014))
const SILENT_BS	= ((1<<CSW_USP)|(1<<CSW_M4A1))

// players offsets
#define XTRA_OFS_PLAYER		5
#define m_flNextAttack		83
#define m_rgAmmo_player_Slot0	376

stock const g_iDftMaxClip[CSW_P90+1] = {
	-1,  13, -1, 10,  1,  7,    1, 30, 30,  1,  30, 
		20, 25, 30, 35, 25,   12, 20, 10, 30, 100, 
		8 , 30, 30, 20,  2,    7, 30, 30, -1,  50}

stock const Float:g_fDelay[CSW_P90+1] = {
	0.00, 2.70, 0.00, 2.00, 0.00, 0.55,   0.00, 3.15, 3.30, 0.00, 4.50, 
		 2.70, 3.50, 3.35, 2.45, 3.30,   2.70, 2.20, 2.50, 2.63, 4.70, 
		 0.55, 3.05, 2.12, 3.50, 0.00,   2.20, 3.00, 2.45, 0.00, 3.40
}

stock const g_iReloadAnims[CSW_P90+1] = {
	-1,  5, -1, 3, -1,  6,   -1, 1, 1, -1, 14, 
		4,  2, 3,  1,  1,   13, 7, 4,  1,  3, 
		6, 11, 1,  3, -1,    4, 1, 1, -1,  1}

public Item_AttachToPlayer(iEnt, id)
{
	if(get_pdata_int(iEnt, m_fKnown, XTRA_OFS_WEAPON))
	{
		return
	}
	
	static iId ; iId = cs_get_weapon_id(iEnt);
	
	if (iId > 30 || iId <= 0)
		return;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
		
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return;
		
	if (Weapons_Var[var_pos][CSW_ID] != iId)
		return;
	
	set_pdata_int(iEnt, m_iClip, Weapons_Var[var_pos][CLIP], XTRA_OFS_WEAPON)
}

public Item_PostFrame(iEnt)
{
	static id ; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
	
	if (!is_player(id))
		return;
	
	static iId ; iId = cs_get_weapon_id(iEnt);
	
	if (iId > 30 || iId <= 0)
		return;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
		
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return;
		
	if (Weapons_Var[var_pos][CSW_ID] != iId)
		return;
	
	//static newammo; newammo = Weapons_Var[var_pos][CLIP];
	
	//static iId ; iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON)
	static iMaxClip ; iMaxClip = Weapons_Var[var_pos][CLIP];
	static fInReload ; fInReload = get_pdata_int(iEnt, m_fInReload, XTRA_OFS_WEAPON)
	static Float:flNextAttack ; flNextAttack = get_pdata_float(id, m_flNextAttack, XTRA_OFS_PLAYER)

	static iAmmoType ; iAmmoType = m_rgAmmo_player_Slot0 + get_pdata_int(iEnt, m_iPrimaryAmmoType, XTRA_OFS_WEAPON)
	static iBpAmmo ; iBpAmmo = get_pdata_int(id, iAmmoType, XTRA_OFS_PLAYER)
	static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON)

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(iMaxClip - iClip, iBpAmmo)
		set_pdata_int(iEnt, m_iClip, iClip + j, XTRA_OFS_WEAPON)
		set_pdata_int(id, iAmmoType, iBpAmmo-j, XTRA_OFS_PLAYER)
		
		set_pdata_int(iEnt, m_fInReload, 0, XTRA_OFS_WEAPON)
		fInReload = 0
	}

	static iButton ; iButton = pev(id, pev_button)
	if(	(iButton & IN_ATTACK2 && get_pdata_float(iEnt, m_flNextSecondaryAttack, XTRA_OFS_WEAPON) <= 0.0)
	||	(iButton & IN_ATTACK && get_pdata_float(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) <= 0.0)	)
	{
		return
	}

	if( iButton & IN_RELOAD && !fInReload )
	{
		if( iClip >= iMaxClip )
		{
			set_pev(id, pev_button, iButton & ~IN_RELOAD)
			if( SILENT_BS & (1<<iId) && !get_pdata_int(iEnt, m_fSilent, XTRA_OFS_WEAPON) )
			{
				SendWeaponAnim( id, iId == CSW_USP ? 8 : 7 )
			}
			else
			{
				SendWeaponAnim(id, 0)
			}
		}
		else if( iClip == g_iDftMaxClip[iId] )
		{
			if( iBpAmmo )
			{
				set_pdata_float(id, m_flNextAttack, g_fDelay[iId], XTRA_OFS_PLAYER)

				if( SILENT_BS & (1<<iId) && get_pdata_int(iEnt, m_fSilent, XTRA_OFS_WEAPON) )
				{
					SendWeaponAnim( id, iId == CSW_USP ? 5 : 4 )
				}
				else
				{
					SendWeaponAnim(id, g_iReloadAnims[iId])
				}
				set_pdata_int(iEnt, m_fInReload, 1, XTRA_OFS_WEAPON)

				set_pdata_float(iEnt, m_flTimeWeaponIdle, g_fDelay[iId] + 0.5, XTRA_OFS_WEAPON)
			}
		}
	}
}

SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id,pev_body))
	message_end()
}

public Shotgun_WeaponIdle( iEnt )
{
	if( get_pdata_float(iEnt, m_flTimeWeaponIdle, XTRA_OFS_WEAPON) > 0.0 )
	{
		return
	}
	
	static id ; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
	
	if (!is_player(id))
		return;
	
	static iId ; iId = cs_get_weapon_id(iEnt);
	
	if (iId > 30 || iId <= 0)
		return;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
	
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return;
		
	if (Weapons_Var[var_pos][CSW_ID] != iId)
		return;

	//static iId ; iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON)
	static iMaxClip ; iMaxClip = Weapons_Var[var_pos][CLIP];

	static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON)
	static fInSpecialReload ; fInSpecialReload = get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON)

	if( !iClip && !fInSpecialReload )
	{
		return
	}

	if( fInSpecialReload )
	{
		//static id ; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
		static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, XTRA_OFS_PLAYER)
		static iDftMaxClip ; iDftMaxClip = g_iDftMaxClip[iId]

		if( iClip < iMaxClip && iClip == iDftMaxClip && iBpAmmo )
		{
			Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
			return
		}
		else if( iClip == iMaxClip && iClip != iDftMaxClip )
		{
			SendWeaponAnim( id, after_reload )

			set_pdata_int(iEnt, m_fInSpecialReload, 0, XTRA_OFS_WEAPON)
			set_pdata_float(iEnt, m_flTimeWeaponIdle, 1.5, XTRA_OFS_WEAPON)
		}
	}
	return
}

public Shotgun_PostFrame( iEnt )
{
	static id ; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
	
	if (!is_player(id))
		return;
	
	static iId ; iId = cs_get_weapon_id(iEnt);
	
	if (iId > 30 || iId <= 0)
		return;
	
	static var_pos; var_pos = g_currentvar[id] - 1;
		
	if (var_pos < 0 ||  var_pos >= sizeof Weapons_Var) 
		return;
		
	if (Weapons_Var[var_pos][CSW_ID] != iId)
		return;
	
	static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, XTRA_OFS_PLAYER)
	static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON)
	//static iId ; iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON)
	static iMaxClip ; iMaxClip = Weapons_Var[var_pos][CLIP];

	// Support for instant reload (used for example in my plugin "Reloaded Weapons On New Round")
	// It's possible in default cs
	if( get_pdata_int(iEnt, m_fInReload, XTRA_OFS_WEAPON) && get_pdata_float(id, m_flNextAttack, 5) <= 0.0 )
	{
		new j = min(iMaxClip - iClip, iBpAmmo)
		set_pdata_int(iEnt, m_iClip, iClip + j, XTRA_OFS_WEAPON)
		set_pdata_int(id, 381, iBpAmmo-j, XTRA_OFS_PLAYER)
		
		set_pdata_int(iEnt, m_fInReload, 0, XTRA_OFS_WEAPON)
		return
	}

	static iButton ; iButton = pev(id, pev_button)
	if( iButton & IN_ATTACK && get_pdata_float(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) <= 0.0 )
	{
		return
	}

	if( iButton & IN_RELOAD  )
	{
		if( iClip >= iMaxClip )
		{
			set_pev(id, pev_button, iButton & ~IN_RELOAD) // still this fucking animation
			set_pdata_float(iEnt, m_flNextPrimaryAttack, 0.5, XTRA_OFS_WEAPON)  // Tip ?
		}

		else if( iClip == g_iDftMaxClip[iId] )
		{
			if( iBpAmmo )
			{
				Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
			}
		}
	}
}

Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
{
	if(iBpAmmo <= 0 || iClip == iMaxClip)
		return

	if(get_pdata_int(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) > 0.0)
		return

	switch( get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON) )
	{
		case 0:
		{
			SendWeaponAnim( id , start_reload )
			set_pdata_int(iEnt, m_fInSpecialReload, 1, XTRA_OFS_WEAPON)
			set_pdata_float(id, m_flNextAttack, 0.55, 5)
			set_pdata_float(iEnt, m_flTimeWeaponIdle, 0.55, XTRA_OFS_WEAPON)
			set_pdata_float(iEnt, m_flNextPrimaryAttack, 0.55, XTRA_OFS_WEAPON)
			set_pdata_float(iEnt, m_flNextSecondaryAttack, 0.55, XTRA_OFS_WEAPON)
			return
		}
		case 1:
		{
			if( get_pdata_float(iEnt, m_flTimeWeaponIdle, XTRA_OFS_WEAPON) > 0.0 )
			{
				return
			}
			set_pdata_int(iEnt, m_fInSpecialReload, 2, XTRA_OFS_WEAPON)
			emit_sound(id, CHAN_ITEM, random_num(0,1) ? "weapons/reload1.wav" : "weapons/reload3.wav", 1.0, ATTN_NORM, 0, 85 + random_num(0,0x1f))
			SendWeaponAnim( id, insert )

			set_pdata_float(iEnt, m_flTimeWeaponIdle, iId == CSW_XM1014 ? 0.30 : 0.45, XTRA_OFS_WEAPON)
		}
		default:
		{
			set_pdata_int(iEnt, m_iClip, iClip + 1, XTRA_OFS_WEAPON)
			set_pdata_int(id, 381, iBpAmmo-1, XTRA_OFS_PLAYER)
			set_pdata_int(iEnt, m_fInSpecialReload, 1, XTRA_OFS_WEAPON)
		}
	}
}
