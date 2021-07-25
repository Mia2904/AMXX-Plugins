#include <amxmodx>

#define PLUGIN "Musica de fondo"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

new Array:g_sounds;
new g_count;

public plugin_precache()
{
	loadMusic();
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	if (g_count)
	{
		register_logevent("logevent_round_start", 2, "1=Round_Start");
		register_logevent("logevent_round_end", 2, "1=Round_End");
		register_message(get_user_msgid("TextMsg"), "message_textmsg");
	}
}

loadMusic()
{
	new szBuffer[160], File;
	get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
	
	format(szBuffer, charsmax(szBuffer), "%s/Musica_drace.ini", szBuffer);
	
	if (!file_exists(szBuffer))
	{
		File = fopen(szBuffer, "wt");
		
		fputs(File, "; Escriba aqui los sonidos a utilizar.^n; Ejemplo:^n; drace_cm/music1.mp3");
		fclose(File);
		
		return 0;
	}
	
	g_sounds = ArrayCreate(160, 1);
	File = fopen(szBuffer, "rt");
	new szCommand[180];
	new len = copy(szBuffer, charsmax(szBuffer), "sound/");
	
	while (!feof(File))
	{
		fgets(File, szBuffer[len], charsmax(szBuffer)-len);
		
		if (!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '^n')
			continue;
		
		trim(szBuffer);
		
		if (file_exists(szBuffer))
		{
			precache_generic(szBuffer);
			
			if (szBuffer[strlen(szBuffer)-1] == '3')
			{
				formatex(szCommand, charsmax(szCommand), "mp3 loop ^"%s^"", szBuffer);
			}
			else
			{
				formatex(szCommand, charsmax(szCommand), "spk ^"%s^"", szBuffer[len]);
			}
		}
		
		ArrayPushString(g_sounds, szCommand);
		g_count++;
	}
	
	fclose(File);

	if (!g_count)
	{
		ArrayDestroy(g_sounds);
		console_print(0, "[MusicaDeFondo] No se cargaron sonidos");
		return 0;
	}
	
	return 1;
}

public logevent_round_start()
{
	new szBuffer[160];
	ArrayGetString(g_sounds, random(g_count), szBuffer, charsmax(szBuffer))
	
	client_cmd(0, szBuffer);
}

public message_textmsg()
{
	static textmsg[13]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))
	
	// Game restarting, reset scores and call round end to balance the teams
	if (equal(textmsg, "#Game_will_r", 12))
	{
		logevent_round_end();
	}
}

public logevent_round_end()
{
	client_cmd(0, "mp3 stop;stopsound");
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
