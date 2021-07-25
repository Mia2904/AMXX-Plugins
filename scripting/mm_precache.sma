#include <amxmodx>
#include <fakemeta>

#define PLUGIN "MM Precache"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new Trie:g_tries;

new fwa, fwb;

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_tries = TrieCreate();
	
	new map[32];
	get_mapname(map, 31);
	
	new buffer[160], len;
	len = copy(buffer, charsmax(buffer), "addons/amxmodx/configs/precacheControl/");
	formatex(buffer[len], charsmax(buffer)-len, "%s.ini", map);
	new file1, file2;
	
	if (file_exists(buffer))
		file1 = fopen(buffer, "rt");
	
	copy(buffer[len], charsmax(buffer)-len, "allmaps.ini");
	
	if (file_exists(buffer))
		file2 = fopen(buffer, "rt");
	
	if (file1)
	{
		while (fgets(file1, buffer[len], charsmax(buffer)-len))
		{
			trim(buffer);
			load_cfg(buffer);
		}
		
		fclose(file1);
	}
	
	if (file2)
	{
		while (fgets(file2, buffer[len], charsmax(buffer)-len))
		{
			trim(buffer);
			load_cfg(buffer);
		}
		
		fclose(file2);
	}
	
	fwa = register_forward(FM_PrecacheModel, "pf_precache", false);
	fwb = register_forward(FM_PrecacheSound,"pf_precache", false);
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

public pf_precache(model[])
{
	if (TrieKeyExists(g_tries, model))
	{
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public plugin_cfg()
{
	unregister_forward(FM_PrecacheModel, fwa);
	unregister_forward(FM_PrecacheSound, fwb);
	TrieDestroy(g_tries);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
