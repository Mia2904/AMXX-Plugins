#if defined __zem_included
	#endinput
#endif

#define __zem_included

const EV_INT_monster_type = EV_INT_iuser1;
const EV_INT_predefined_ai = EV_INT_iuser2;
const EV_INT_ai_status = EV_INT_iuser3;
const EV_FL_attack_radius = EV_FL_fuser1;

enum _:stMonster
{
	SZ_NAME[32],
	Float:F_HEALTH,
	Float:F_RADIUS,
	SZ_MODEL[48],
	Float:F_MINS[3],
	Float:F_MAXS[3],
	MOVE_TYPE,
	PREDEFINED_AI,
	Float:F_SPEED
};

// Inteligencias predefinidas
enum
{
	AI_none,
	AI_nihilanth,
	AI_zombie,
	AI_gonome,
	AI_vortigaunt,
	AI_headcrab,
	AI_gunner,
	AI_revenant
};

// Movimientos
enum
{
	MOVE_none,
	MOVE_walk,
	MOVE_pursuit,
	MOVE_teletrans
};

native zem_register_monster(szName[32], Float:fDefaultHealth, Float:fAIRadius, szModel[48], Float:fMins[3], float:fMaxs[3], iMoveType, iAI, Float:fSpeed);

native zem_create_monster(iType, Float:fOrigin[3], Float:fAngles[3], Float:fHealth);

native zem_get_monsters_num();

native zem_get_monster_info(iType, aMonster[stMonster]);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
