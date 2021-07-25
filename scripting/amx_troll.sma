#include <amxmodx>
#include <amxmisc>

#define PLUGIN "AMXX Troll"
#define VERSION "0.1"

#pragma semicolon 1

#define MASTER "http://ytmnd.com/"
#define TROLL1 "; RickRoll^nhttp://rickastleypwns.ytmnd.com/"
#define TROLL2 "; Trololo^nhttp://detest.ytmnd.com/"
#define TROLL3 "; Chacarron macarron (ualeualeuale)^nhttp://dumbasians.ytmnd.com"

new Array:g_urls;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	register_concmd("amx_troll", "concmd_troll", ADMIN_BAN);
}

public plugin_cfg()
{
	g_urls = ArrayCreate(128, 1);
	
	new szBuffer[128], File;
	get_configsdir(szBuffer, charsmax(szBuffer));
	
	format(szBuffer, charsmax(szBuffer), "%s/TrollLinks.ini", szBuffer);
	
	if (!file_exists(szBuffer))
	{
		File = fopen(szBuffer, "wt");
		
		fprintf(File, "; AXMX Troll^n^n; Coloca aqui las URLs Troll!^n; Asegurate de colocar el protocolo http:// (No https)^n; Encontraras muchas aqui: %s^n; PD: El MOTD de HL no soporta Flash.^n^n%s^n^n%s^n^n%s^n",
		MASTER, TROLL1, TROLL2, TROLL3);
		
		fclose(File);
	}
	
	File = fopen(szBuffer, "rt");
	
	while (!feof(File))
	{
		fgets(File, szBuffer, charsmax(szBuffer));
		
		if (!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '^n')
			continue;
		
		if (!equal(szBuffer, "http://", 7))
		{
			log_amx("URL Invalida: %s", szBuffer);
			continue;
		}
		
		trim(szBuffer);
		ArrayPushString(g_urls, szBuffer);
	}
	
	fclose(File);
	
	if (!ArraySize(g_urls))
	{
		ArrayDestroy(g_urls);
		set_fail_state("No se cargaron URLs");
	}
}

public concmd_troll(id , level , cid)
{
	if(!cmd_access(id , level , cid , 2))
		return PLUGIN_HANDLED;
	
	static szBuffer[128], player;
	
	read_argv(1 , szBuffer, 31);
	player = cmd_target(id , szBuffer , CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF|CMDTARGET_NO_BOTS);
	
	if(!player)
		return PLUGIN_HANDLED;
	
	// random_num() es mil veces mejor que random()
	ArrayGetString(g_urls, random_num(0, ArraySize(g_urls)-1), szBuffer, charsmax(szBuffer));
	
	show_motd(player, szBuffer, "Has sido Trolleado");
	
	return PLUGIN_HANDLED;
}

public plugin_end()
	ArrayDestroy(g_urls);
