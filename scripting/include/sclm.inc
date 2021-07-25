#if defined _sclm_included
	#endinput
#endif

#define _sclm_included

// Constants
const MAX_EXTRA_ITEMS = 9;
const MAX_POWER_UPS = 9;

const PU_NAME_LENGHT = 32;
const EI_NAME_LENGHT = 32;

const MAX_LEVEL = 200;
const MAX_POWERUP_LEVEL = 20;
const MAX_ENERGY = 10;
const Float:ENERGY_INCREASE_INTERVAL = 30.0;

enum _:PU_STRUCT
{
	PU_NAME[PU_NAME_LENGHT] = 0,
	PU_MINLEVEL
};

enum _:EI_STRUCT
{
	EI_NAME[EI_NAME_LENGHT] = 0,
	EI_COST,
	EI_MINLEVEL
};

native sclm_get_user_level(const iId);

native sclm_set_user_level(const iId, const iLevel);

native sclm_get_user_exp(const iId);

native sclm_set_user_exp(const iId, const iExp);

native sclm_get_level_exp(const iLevel);

native sclm_register_extra_item(const szName[], const iCost, const iMinLevel);

native sclm_get_user_energy(const iId);

native sclm_set_user_energy(const iId, const iEnergy);

native sclm_register_powerup(const szName[], const iMinLevel);

native sclm_get_user_powerup_level(const iId, const iPowerUp);

native sclm_set_user_powerup_level(const iId, const iPowerUp, const iLevel);

native sclm_is_user_donor(const iId);

native sclm_register_dictionary(const szName[]);

native sclm_register_menu_entry(const szName[]);

native sclm_load_user_data(const iId, const szKey[]);

native sclm_save_user_data(const iId, const szKey[], const szData[]);

forward sclm_user_logged(iId, iExp, iLevel);

forward sclm_extra_item_selected(iId, iExtraItem);

forward sclm_level_increased(iId, iLevel);

forward sclm_menu_entry_selected(iId, iItem);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
