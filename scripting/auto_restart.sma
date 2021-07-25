#include <amxmodx>

#define PLUGIN "Auto RR"
#define VERSION "0.1"

#pragma semicolon 1

new const PREFIJO[] = "[PeruGaming]";

new cvar_time, g_time;

const SECS_MENSAJE = 2;
const TASKID = 1512;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	register_logevent("logevent_game_commencing", 2, "1=Game_Commencing");
	
	cvar_time = register_cvar("amx_restart_time", "15.0");
}

public logevent_game_commencing()
{
	remove_task(TASKID);
	
	g_time = get_pcvar_num(cvar_time) + 1;
	set_task(1.0, "task_show_restart", TASKID, .flags = "a", .repeat = g_time + SECS_MENSAJE);
}

public task_show_restart()
{
	if (--g_time > 0)
	{
		static colors[3];
	
		switch (g_time % 10)
		{
			case 0:
			{
				colors[0] = 255;
				colors[1] = 255;
				colors[2] = 255;
			}
			case 1:
			{
				colors[0] = 180;
				colors[1] = 150;
				colors[2] = 20;
			}
			case 2:
			{
				colors[0] = 170;
				colors[1] = 50;
				colors[2] = 100;
			}
			case 3:
			{
				colors[0] = 255;
				colors[1] = 255;
				colors[2] = 0;
			}
			case 4:
			{
				colors[0] = 100;
				colors[1] = 50;
				colors[2] = 200;
			}
			case 5:
			{
				colors[0] = 255;
				colors[1] = 150;
				colors[2] = 50;
			}
			case 6:
			{
				colors[0] = 50;
				colors[1] = 200;
				colors[2] = 50;
			}
			case 7:
			{
				colors[0] = 0;
				colors[1] = 250;
				colors[2] = 250;
			}
			case 8:
			{
				colors[0] = 235;
				colors[1] = 50;
				colors[2] = 50;
			}
			case 9:
			{
				colors[0] = 20;
				colors[1] = 20;
				colors[2] = 150;
			}
		}
	
		set_hudmessage(colors[0], colors[1], colors[2], -1.0, -1.0, 0, 1.1, 1.0);
		show_hudmessage(0, "%s^nRestart en %d segundos.^n^n^n^n", PREFIJO, g_time);
	}
	else if (!g_time)
		set_cvar_num("sv_restart", 1);
	else if (g_time == 0 - SECS_MENSAJE)
	{
		set_hudmessage(255, 255, 255, -1.0, -1.0, 2, 4.0, 1.0);
		show_hudmessage(0, "%s^nEmpieza el Juego. Buena Suerte!^n^n^n^n", PREFIJO);
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
