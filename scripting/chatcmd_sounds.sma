#include <amxmodx>

#define PLUGIN "Chat CMD Sounds"
#define VERSION "0.1"

#pragma semicolon 1

new Array:g_sounds, Array:g_commands, Array:g_names, g_size, cvar_speak;
//new g_motd[1530], g_len;
new g_bMuted;
#define is_player_muted(%0) (g_bMuted&(1<<(%0&0b11111)))
#define unset_mute(%0) g_bMuted&=~(1<<(%0&0b11111))
#define toggle_mute(%0) g_bMuted^=(1<<(%0&0b11111))

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	new szBuffer[192], File, szCommand[50], szSound[128], Len, i, bool:Folder;
	
	g_sounds = ArrayCreate(128, 1); g_commands = ArrayCreate(1, 1), g_names = ArrayCreate(32, 1);
	
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	format(szBuffer, charsmax(szBuffer), "%s/ChatCMDSounds.ini", szBuffer);
			
	if (!file_exists(szBuffer))
	{
		File = fopen(szBuffer, "wt");
		
		fprintf(File,
		"; Escribe aqui los sonidos y el comando respectivo (dejar en blanco para usar el nombre del archivo).^n; Los comandos no pueden llevar caracteres especiales.^n; Los sonidos deben estar en la carpeta /sound^n; Formatos: .mp3 y .wav.^n^n^"vox/hello.wav^" ^"hello^"^n");
		
		fclose(File);
	}
	
	File = fopen(szBuffer, "rt");
	
	while (!feof(File))
	{
		fgets(File, szBuffer, charsmax(szBuffer));
		
		if (szBuffer[0] != '"')
			continue;
		
		szCommand[0] = EOS;
		
		parse(szBuffer, szSound, charsmax(szSound), szCommand, charsmax(szCommand));
		remove_quotes(szCommand); remove_quotes(szSound);
		
		if (szCommand[0] == EOS)
		{
			Folder = false;
			Len = strlen(szSound) - 5;
			
			for (i = Len - 1; i >= 0; i--)
			{
				if (szSound[i] == '/')
				{
					formatex(szCommand, Len - i, "%s", szSound[i+1]);
					Folder = true;
					break;
				}
			}
			
			if (!Folder)
				formatex(szCommand, Len - 4, "%s", szSound);
		}
		
		formatex(szBuffer, charsmax(szBuffer), "say %s", szCommand);
		ArrayPushCell(g_commands, register_clcmd(szBuffer, "clcmd_sound"));
		ArrayPushString(g_names, szCommand);
		//Motdlen += formatex(g_motd[Motdlen], charsmax(g_motd) - Motdlen, "%s^n", szCommand);
		
		if (szSound[strlen(szSound)-1] == '3')
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound);
			formatex(szBuffer, charsmax(szBuffer), "mp3 play ^"%s^"", szSound);
			precache_generic(szSound);
		}
		else
		{
			formatex(szBuffer, charsmax(szBuffer), "spk ^"%s^"", szSound);
			precache_sound(szSound);
		}
		
		ArrayPushString(g_sounds, szBuffer);
	}
	
	fclose(File);
	
	g_size = ArraySize(g_commands);
	
	if (!g_size)
	{
		ArrayDestroy(g_commands); ArrayDestroy(g_sounds); ArrayDestroy(g_names);
		set_fail_state("No sounds loaded.");
		return;
	}
	
	register_clcmd(".listsounds", "clcmd_listsounds");
	register_clcmd("sonidos", "clcmd_listsounds");
	register_clcmd("say sounds", "clcmd_togglesounds");
	//g_len = strlen(g_motd);
	
	cvar_speak = register_cvar("ccs_speakloud", "1");
}

public client_putinserver(id)
{
	unset_mute(id);
}

public clcmd_togglesounds(id)
{
	toggle_mute(id);
	
	if (is_player_muted(id))
		client_print(id, print_chat, "Ya no escucharas los sonidos del chat. Escribe 'sounds' en el chat otra vez para reactivarlos.");
	else
		client_print(id, print_chat, "Has reactivado los sonidos del chat. Escribe 'sounds' en el chat otra vez para desactivarlos.");
}

public clcmd_listsounds(id)
{
	console_print(id, "Sonidos disponibles:^n");
	static szBuffer[128];
	for (new i = 0; i < g_size; i++)
	{
		ArrayGetString(g_names, i, szBuffer, charsmax(szBuffer));
		engclient_print(id, engprint_console, szBuffer);
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_sound(id, junk, cid)
{
	static szBuffer[128];
	
	for (new i = 0; i < g_size; i++)
	{
		if (ArrayGetCell(g_commands, i) == cid)
		{
			ArrayGetString(g_sounds, i, szBuffer, charsmax(szBuffer));
						
			if (get_pcvar_num(cvar_speak))
			{
				static players[32], num;
				get_players(players, num, "ch");
				for (new j = 0; j < num; j++)
				{
					id = players[j];
					if (is_player_muted(id))
						continue;
					
					client_cmd(id, szBuffer);
				}
			}
			else
				client_cmd(id, szBuffer);
				
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}
