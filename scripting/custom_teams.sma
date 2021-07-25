#include <amxmodx>
#include <cstrike>

#define PLUGIN "Custom Teams"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new TEAM_NAMES[2][32], TEAM_SOUNDS[2][44], Array:g_class_names[2], Array:g_class_models[2], g_menu[160];
new g_class1_menu, g_class2_menu, g_menulen;

const OFFSET_VGUI_JOINTEAM = 2;
const OFFSET_VGUI_JOINCLASS1 = 26;
const OFFSET_VGUI_JOINCLASS2 = 27;
const CHOOSE_KEYS = MENU_KEY_1|MENU_KEY_2|MENU_KEY_5

enum _:OLD_MENU_CODES
{
	TEAM_SELECT_SPECT,
	TERRORIST_SELECT,
	CT_SELECT,
	IG_TEAM_SELECT,
	IG_TEAM_SELECT_SPEC
}

new const OLDMENU_CODES[OLD_MENU_CODES][] =
{	
	"#Team_Select_Spect",
	"#Terrorist_Select",
	"#CT_Select",
	"#IG_Team_Select",
	"#IG_Team_Select_Spect"
}

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_class_names[0] = ArrayCreate(32, 1); g_class_names[1] = ArrayCreate(32, 1);
	g_class_models[0] = ArrayCreate(32, 1); g_class_models[1] = ArrayCreate(32, 1);
	
	new szBuffer[70], File, szClass[32], szModel[41], TempTeam, len;
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	
	format(szBuffer, charsmax(szBuffer), "%s/CustomTeams.ini", szBuffer);
	
	if (!file_exists(szBuffer))
	{
		File = fopen(szBuffer, "wt");
		
		fprintf(File, "; Aqui van los equipos.^n; SOLO SON 2 EQUIPOS! No hay limite de personajes.^n; Los personajes van con su respectivo model.^n^n");
		fprintf(File, "[TEAM1]^nNOMBRE = ^"Prisioneros^"^nSONIDO = ^"radio/terwin.wav^"^n^"Phoenix Connexion^" ^"terror^"^n^"L337 Krew^" ^"leet^"^n^"Arctic Avengers^" ^"arctic^"^n^"Guerilla Warfare^" ^"guerilla^"^n^n")
		fprintf(File, "[TEAM2]^nNOMBRE = ^"Policias^"^nSONIDO = ^"radio/ctwin.wav^"^n^"Seal Team 6^" ^"urban^"^n^"Germam GSG-9^" ^"gsg9^"^n^"UK SAS^" ^"sas^"^n^"French GIGN^" ^"gign^"");
		
		fclose(File);
	}
	
	File = fopen(szBuffer, "rt");
	
	while (!feof(File))
	{
		fgets(File, szBuffer, charsmax(szBuffer));
		trim(szBuffer);
		
		switch (szBuffer[0])
		{
			case '[': TempTeam = szBuffer[5] - '1';
			case 'N':
			{
				copy(TEAM_NAMES[TempTeam], charsmax(TEAM_NAMES[]), szBuffer[9]);
				remove_quotes(TEAM_NAMES[TempTeam]);
			}
			case 'S':
			{
				remove_quotes(szBuffer[9]);
				len = strlen(szBuffer[9]) - 1;
				
				if (szBuffer[len] == '3') // MP3
				{
					formatex(szModel, charsmax(szBuffer), "sound/%s", szBuffer[9]);
					precache_generic(szModel);
				}
				else
				{
					copy(szModel, charsmax(szModel), szBuffer[9]);
					precache_sound(szModel);
				}
				
				formatex(TEAM_SOUNDS[TempTeam], charsmax(TEAM_SOUNDS[]), "%s ^"%s^"", szBuffer[len] == '3' ? "mp3 play" : "spk", szModel);
			}
			case '"':
			{	
				parse(szBuffer, szClass, charsmax(szClass), szModel, charsmax(szModel));
				remove_quotes(szClass); remove_quotes(szModel);
				
				ArrayPushString(g_class_names[TempTeam], szClass);
				ArrayPushString(g_class_models[TempTeam], szModel);
				
				format(szModel, charsmax(szModel), "models/player/%s/%s.mdl", szModel, szModel)
				
				if (file_exists(szModel))
					precache_model(szModel);
				else
				{
					format(szModel, charsmax(szModel), "Model no existe: %s", szModel);
					set_fail_state(szModel);
				}
				
				copy(szModel[strlen(szModel)-4], charsmax(szModel), "T.mdl");
				if (file_exists(szModel))
					precache_model(szModel);
			}
		}
	}
	
	fclose(File);
}

public plugin_init()
{
	register_message(get_user_msgid("VGUIMenu"), "message_vguimenu");
	register_message(get_user_msgid("ShowMenu"), "message_showmenu");
	register_message(get_user_msgid("SendAudio"), "message_sendaudio");
	register_message(get_user_msgid("TextMsg"), "message_textmsg");
	
	register_clcmd("joinclass", "clcmd_joinclass");
	
	register_menucmd(register_menuid("CustomChooseTeam"),
	MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6|MENU_KEY_0, "menu_chooseteam");
	
	new szBuffer[32], i;
	g_menulen = formatex(g_menu, charsmax(g_menu), "\ySeleccione un equipo^n^n\r1.\w %s", TEAM_NAMES[0]);
	g_menulen += formatex(g_menu[g_menulen], charsmax(g_menu)-g_menulen, "^n\r2.\w %s", TEAM_NAMES[1]);
	g_menulen += formatex(g_menu[g_menulen], charsmax(g_menu)-g_menulen, "^n^n\r5.\w Auto-seleccion");
	
	g_class1_menu = menu_create("Seleccione su apariencia", "menu_class");
	new len = ArraySize(g_class_names[0]);
	for (i = 0; i < len; i++)
	{
		ArrayGetString(g_class_names[0], i, szBuffer, charsmax(szBuffer));
		menu_additem(g_class1_menu, szBuffer);
	}
	
	menu_addblank(g_class1_menu, 0);
	menu_additem(g_class1_menu, "Auto-seleccion");
	
	menu_setprop(g_class1_menu, MPROP_EXIT, MEXIT_NEVER);
	
	g_class2_menu = menu_create("Seleccione su apariencia", "menu_class");
	len = ArraySize(g_class_names[1]);
	for (i = 0; i < len; i++)
	{
		ArrayGetString(g_class_names[1], i, szBuffer, charsmax(szBuffer));
		menu_additem(g_class2_menu, szBuffer);
	}
	
	menu_addblank(g_class2_menu, 0);
	menu_additem(g_class2_menu, "Auto-seleccion");
	
	menu_setprop(g_class2_menu, MPROP_EXIT, MEXIT_NEVER);

	return PLUGIN_CONTINUE;
}

public message_textmsg(msg_id, msg_dest, msg_entity)
{
	static szArg[20];
	get_msg_arg_string(2, szArg, charsmax(szArg));

	if (equal(szArg, "#Terrorists_Win") || equal(szArg, "#CTs_Win"))
	{
		client_print(0, print_center, "%s win!", TEAM_NAMES[(szArg[1] == 'T') ? 0 : 1]);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public message_sendaudio(msg_id, msg_dest, id)
{
	static szArg[20];
	get_msg_arg_string(2, szArg, charsmax(szArg));
	
	if (equali(szArg, "%!MRAD_ctwin"))
		client_cmd(0, TEAM_SOUNDS[1]);
	else if (equali(szArg, "%!MRAD_terwin"))
		client_cmd(0, TEAM_SOUNDS[0]);
	else
		return PLUGIN_CONTINUE;
	
	return PLUGIN_HANDLED;
}

public clcmd_joinclass(id)
	return PLUGIN_HANDLED;

public message_vguimenu(msg_id, msg_dest, id)
{
	switch (get_msg_arg_int(1))
	{
		case OFFSET_VGUI_JOINCLASS1: menu_display(id, g_class1_menu);
		case OFFSET_VGUI_JOINCLASS2: menu_display(id, g_class2_menu);
		case OFFSET_VGUI_JOINTEAM:
		{
			if (CS_TEAM_T <= cs_get_user_team(id) <= CS_TEAM_CT)
			{
				if (is_user_alive(id))
				{
					formatex(g_menu[g_menulen], charsmax(g_menu)-g_menulen, "^n^n\r0.\w Salir");
					show_menu(id, CHOOSE_KEYS|MENU_KEY_0, g_menu, -1, "CustomChooseTeam");
				}
				else
				{
					formatex(g_menu[g_menulen], charsmax(g_menu)-g_menulen, "^n\r6.\w Espectador^n^n\r0.\w Salir");
					show_menu(id, CHOOSE_KEYS|MENU_KEY_6|MENU_KEY_0, g_menu, -1, "CustomChooseTeam");
				}
			}
			else
			{
				formatex(g_menu[g_menulen], charsmax(g_menu)-g_menulen, "^n\r6.\w Espectador");
				show_menu(id, CHOOSE_KEYS|MENU_KEY_6, g_menu, -1, "CustomChooseTeam");
			}
		}
		default: return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_HANDLED;
}

public message_showmenu(msg_id, msg_dest, id)
{
	static szArg[25];
	get_msg_arg_string(4, szArg, charsmax(szArg));
	
	for (new i = 0; i < OLD_MENU_CODES; i++)
	{
		if (equal(OLDMENU_CODES[i], szArg))
		{
			switch (i)
			{
				case TERRORIST_SELECT: menu_display(id, g_class1_menu);
				case CT_SELECT: menu_display(id, g_class2_menu);
				case TEAM_SELECT_SPECT:
				{
					formatex(g_menu[g_menulen], charsmax(g_menu)-g_menulen, "^n\r6.\w Espectador");
					show_menu(id, CHOOSE_KEYS|MENU_KEY_6, g_menu, -1, "CustomChooseTeam");
				}
				case IG_TEAM_SELECT:
				{
					formatex(g_menu[g_menulen], charsmax(g_menu)-g_menulen, "^n^n\r0.\w Salir");
					show_menu(id, CHOOSE_KEYS|MENU_KEY_0, g_menu, -1, "CustomChooseTeam");
				}
				case IG_TEAM_SELECT_SPEC:
				{
					formatex(g_menu[g_menulen], charsmax(g_menu)-g_menulen, "^n\r6.\w Espectador^n^n\r0.\w Salir");
					show_menu(id, CHOOSE_KEYS|MENU_KEY_6|MENU_KEY_0, g_menu, -1, "CustomChooseTeam");
				}
			}
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public menu_chooseteam(id, item)
{
	if (item == 9 || !is_user_connected(id))
		return PLUGIN_HANDLED;
	
	client_cmd(id, "jointeam %d", item+1)
	
	return PLUGIN_HANDLED;
}

public menu_class(id, menu, item)
{
	if (item == MENU_EXIT)
		return PLUGIN_HANDLED;
	
	menu = menu_items(menu)-1;
	
	if (item == menu) // Auto select
		item = random(menu);
	
	static szBuffer[32], Team; Team = (menu == g_class2_menu);
	
	ArrayGetString(g_class_models[Team], item, szBuffer, charsmax(szBuffer));
	engclient_cmd(id, "joinclass", "5");
	cs_set_user_model(id, szBuffer);
	
	return PLUGIN_HANDLED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
