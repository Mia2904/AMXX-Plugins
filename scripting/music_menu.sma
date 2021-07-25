#include <amxmodx>

#define PLUGIN "Music Menu"
#define VERSION "0.1"

#pragma semicolon 1

new Array:g_sounds, g_menu, g_size;

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	g_sounds = ArrayCreate(128, 1);
	g_menu = menu_create("Music Menu", "menu_music");
	
	new szBuffer[196], File, szName[64], szSound[128];
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	
	format(szBuffer, charsmax(szBuffer), "%s/MusicMenu.ini", szBuffer);
	
	if (!file_exists(szBuffer))
	{
		File = fopen(szBuffer, "wt");
		
		fprintf(File,
		"; Comando para abrir el menu de musica^n^nCOMANDO = /musica^n^n; Coloca aqu�: ^"nombre^" ^"sonido^"^n; Formatos: .mp3 y .wav (Si es .wav tendra que estar en la carpeta /sound).^n^n^"Half Life Intro^" ^"media/Half-Life13.mp3^"^n^"Suspense^" ^"media/Suspense07.mp3^"^n^"Hello^" ^"vox/hello.wav^" ; Esta en sound/vox como es .wav^n");
		
		fclose(File);
	}
	
	File = fopen(szBuffer, "rt");
	
	while (!feof(File))
	{
		fgets(File, szBuffer, charsmax(szBuffer));
		
		if (!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '^n')
			continue;
		
		trim(szBuffer);
		
		if (szBuffer[0] == 'C')
		{
			format(szBuffer, charsmax(szBuffer), "say %s", szBuffer[10]);
			register_clcmd(szBuffer, "clcmd_music");
            
			format(szBuffer, charsmax(szBuffer), "say_team %s", szBuffer[4]);
			register_clcmd(szBuffer, "clcmd_music");
            
			continue;
		}
		
		parse(szBuffer, szName, charsmax(szName), szSound, charsmax(szSound));
		remove_quotes(szName); remove_quotes(szSound);
		
		if (szSound[strlen(szSound)-1] == '3') // .mp3
		{
			formatex(szBuffer, charsmax(szBuffer), "mp3 play ^"%s^"", szSound);
			precache_generic(szSound);
		}
		else
		{
			formatex(szBuffer, charsmax(szBuffer), "spk ^"%s^"", szSound);
			precache_sound(szSound);
		}
		
		ArrayPushString(g_sounds, szBuffer);
		menu_additem(g_menu, szName);
	}
	
	fclose(File);
	
	g_size = ArraySize(g_sounds);
	
	if (!g_size)
	{
		ArrayDestroy(g_sounds);
		menu_destroy(g_menu);
		set_fail_state("No sounds loaded.");
		return;
	}
	
	menu_additem(g_menu, "\rStop the music.");
}

public clcmd_music(id)
	menu_display(id, g_menu);

public menu_music(id, menu, item)
{
	if (item == g_size)
	{
		client_cmd(id, "stopsound;mp3 stop;");
	}
	else if (0 <= item < g_size)
	{
		static szBuffer[128];
		ArrayGetString(g_sounds, item, szBuffer, charsmax(szBuffer));
		
		client_cmd(id, "stopsound;mp3 stop;");
		client_cmd(id, szBuffer);
	}
	
	return PLUGIN_HANDLED;
}
