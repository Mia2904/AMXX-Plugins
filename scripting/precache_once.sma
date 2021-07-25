#include <amxmodx>
#include <fakemeta>
#include <orpheu>
#include <orpheu_stocks>

#define PLUGIN "Precache Fix"
#define VERSION "1.0"
#define AUTHOR "Mia2904"

new Trie:g_tries;
new OrpheuHook:reg[6];

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_tries = TrieCreate();
	
	new map[32];
	get_mapname(map, 31);
	
	new buffer[160], len;
	len = copy(buffer, charsmax(buffer), "addons/amxmodx/configs/precacheControl/");
	formatex(buffer[len], charsmax(buffer)-len, "%s.ini", map);
	
	if (file_exists(buffer))
	{
		new file = fopen(buffer, "rt");
		
		while (fgets(file, buffer[len], charsmax(buffer)-len))
		{
			trim(buffer);
			load_cfg(buffer);
		}
		
		fclose(file)
	}
	
	new OrpheuFunction:func;
	
	func = OrpheuGetEngineFunction("pfnPrecacheModel", "PrecacheModel");
	reg[0] = OrpheuRegisterHook(func, "pf_precache", OrpheuHookPre);
	reg[1] = OrpheuRegisterHook(func, "pf_precache_post", OrpheuHookPost);
	
	func = OrpheuGetEngineFunction("pfnPrecacheGeneric", "PrecacheGeneric");
	reg[2] = OrpheuRegisterHook(func, "pf_precache", OrpheuHookPre);
	reg[3] = OrpheuRegisterHook(func, "pf_precache_post", OrpheuHookPost);
	
	func = OrpheuGetEngineFunction("pfnPrecacheSound" , "PrecacheSound");
	reg[4] = OrpheuRegisterHook(func, "pf_precache", OrpheuHookPre);
	reg[5] = OrpheuRegisterHook(func, "pf_precache_post", OrpheuHookPost);
	
	//OrpheuRegisterHook( OrpheuGetEngineFunction( "pfnPrecacheModel", "PrecacheModel" ), "PrecacheModel" );
	//OrpheuRegisterHook( OrpheuGetEngineFunction( "pfnPrecacheGeneric", "PrecacheGeneric" ), "PrecacheGeneric" );
	
	//OrpheuRegisterHook(OrpheuGetFunction("PF_precache_model_I"), "pf_precache", OrpheuHookPre);
	//OrpheuRegisterHook(OrpheuGetFunction("PF_precache_model_I"), "pf_precache_post", OrpheuHookPost);
	//register_forward(FM_PrecacheModel, "precache");
	//register_forward(FM_PrecacheSound,"precache")
	
	return 0;
}

load_cfg(const szFile[])
{
	new file = fopen(szFile, "rt");
	
	new buf[120];
	
	while (fgets(file, buf, charsmax(buf)))
	{
		trim(buf);
		TrieSetCell(g_tries, buf, 1);
	}
}

public OrpheuHookReturn:pf_precache(model[])
{
	if (TrieKeyExists(g_tries, model))
	{
		//log_to_file("precached.txt", "BLOCK %s - %d", model, modeli);
		/*if (modeli > 1)
		{
			OrpheuSetReturn(modeli);
		}*/
		return OrpheuSupercede;
	}
	
	return OrpheuIgnored;
}

public OrpheuHookReturn:pf_precache_post(model[])
{
	/*static ret;
	ret = OrpheuGetReturn();
	
	if (ret > 1)
	{
		TrieSetCell(g_tries, model, ret);
	}*/
	TrieSetCell(g_tries, model, 1);
	//log_to_file("precached.txt", "%s - %d", model, ret);
}

/*public precache(data[])
{
	if (TrieKeyExists(g_tries, data))
	{
		return FMRES_SUPERCEDE;
	}
	
	TrieSetCell(g_tries, data, true);
	return FMRES_IGNORED;
}*/

public plugin_cfg()
{
	OrpheuUnregisterHook(reg[0]);
	OrpheuUnregisterHook(reg[1]);
	OrpheuUnregisterHook(reg[2]);
	OrpheuUnregisterHook(reg[3]);
	OrpheuUnregisterHook(reg[4]);
	OrpheuUnregisterHook(reg[5]);
	TrieDestroy(g_tries);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
