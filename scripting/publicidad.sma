#include <amxmodx>
#include <engine>

#define PLUGIN "Publicidad"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

#define MESSAGES_FILE "mensajes.ini"

new g_cvar, Array:g_aMessages, g_num, g_szBuffer[190], Float:g_timer;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	get_localinfo("amxx_configsdir", g_szBuffer, charsmax(g_szBuffer));
	format(g_szBuffer, charsmax(g_szBuffer), "%s/%s", g_szBuffer, MESSAGES_FILE);
	
	if (!file_exists(g_szBuffer))
	{
		new file = fopen(g_szBuffer, "wt");
		fprintf(file, "; Escribe aqui tus mensajes");
		fclose(file);
		return;
	}
	
	g_cvar = register_cvar("publicidad_intervalo", "120.0");
	
	g_aMessages = ArrayCreate(190, 10);
	g_num = 0;
	
	new file = fopen(g_szBuffer, "rt");
	
	g_szBuffer[0] = '^x01';
	
	while (!feof(file))
	{
		fgets(file, g_szBuffer[1], charsmax(g_szBuffer) - 1);
		trim(g_szBuffer[1]);
		
		switch (g_szBuffer[1])
		{
			case EOS, ';', '^n', ' ':
				continue;
		}
		
		g_num++;
		
		ArrayPushString(g_aMessages, g_szBuffer);
	}
	
	fclose(file);
}

public plugin_cfg()
{
	if (!g_num)
	{
		ArrayDestroy(g_aMessages);
		set_fail_state("No se cargaron mensajes.");
		return;
	}
	
	g_timer = get_pcvar_float(g_cvar);
	set_task(g_timer == 0.0 ? 180.0 : g_timer, "display_message");
}

/*public server_frame()
{
	static display_num = 0, Float:curtime, Float:oldtime;
	
	curtime = halflife_time();
	
	if (curtime - oldtime < g_timer)
		return;
	
	oldtime = curtime;
	g_timer = get_pcvar_float(g_cvar);
	
	if (g_timer == 0.0)
	{
		g_timer = 180.0;
		return;
	}
	
	ArrayGetString(g_aMessages, display_num , g_szBuffer, charsmax(g_szBuffer));
	
	if (display_num == g_num - 1)
		display_num = 0;
	else
		display_num++;
	
	client_print(0, print_chat, g_szBuffer);
}*/

public display_message()
{
	static display_num = 0;
	
	g_timer = get_pcvar_float(g_cvar);
	
	if (g_timer == 0.0)
	{
		set_task(180.0, "display_message");
		return;
	}
	
	ArrayGetString(g_aMessages, display_num , g_szBuffer, charsmax(g_szBuffer));
	
	if (display_num == g_num - 1)
		display_num = 0;
	else
		display_num++;
	
	client_print(0, print_chat, g_szBuffer);
	
	set_task(g_timer, "display_message");
}
