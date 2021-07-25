#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Registro de IPs"
#define VERSION "1.0"
#define AUTHOR "Mia2904"

#define MAX_IP_REG	150

new nickreg[MAX_IP_REG][33], ipreg[MAX_IP_REG][15], tiempo[MAX_IP_REG], count, bool:reset;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_concmd("amx_ip", "GetIp", _, "<nombre|@> - Ver la ip de un jugador, @ para todos.");
	register_concmd("vertodaslasip", "PrintIps");
	reset = false;
}

public client_connect(id)
{
	if(is_user_bot(id))
		return;
	
	get_user_name(id, nickreg[count], 32);
	get_user_ip(id, ipreg[count], 14, 1);
	tiempo[count] = get_systime();
	new temp = count
	count++
	
	if(count >= MAX_IP_REG)
	{
		reset = true;
		count = MAX_IP_REG;
	}
	
	CheckIp(temp, get_user_userid(id));
}

CheckIp(temp, usrid)
{
	static elotronick[32];
	new otrosnick, maxloops, matches, i
	new lastmatches[5];
	
	maxloops = (reset ? MAX_IP_REG : temp + 1)
	
	for(i=0; i < maxloops; i++)
	{
		if(equal(ipreg[temp], ipreg[i]))
		{
			lastmatches[matches] = i;
			
			if (++matches >= 5)
				matches = 0;
			
			if (!equal(nickreg[temp], nickreg[i]))
			{
				if(!otrosnick)
				{
					console_print(0, "=============================================");
					console_print(0, "Inicio del registro de IP - Nombres de %s:", ipreg[temp]);
					console_print(0, "1. %s", nickreg[i]);
					copy(elotronick, 31, nickreg[i]);
					otrosnick++
				}
				else if(!equal(nickreg[i], elotronick))
				{
					console_print(0, "%d. %s", otrosnick + 1, nickreg[i]);
					otrosnick++
				}
			}
		}
	}
	
	if(otrosnick)
	{
		console_print(0, "%d. %s", otrosnick + 1, nickreg[temp]);
		console_print(0, "Final del registro de IP - Hecho por Mia2904");
		console_print(0, "=============================================");
	}
	
	if (lastmatches[4]) // 5 veces misma ip en un minuto
	{
		new systime = get_systime();
		
		for (i = 0; i < 5; i++)
		{
			if (systime - tiempo[lastmatches[i]] <= 60)
			{
				server_cmd("kick #%d ^"Te has conectado 5 veces en un minuto. Intentas tumbar el server? Ban por 1 hora.^"", usrid)
				server_cmd("addip 60 %s;writeip", ipreg[temp])
				log_to_file("cliente_falso.txt", "IP %s baneado por conectarse 5 veces en un minuto. (Nick %s)", ipreg[temp], nickreg[temp])
				break;
			}
		}
	}
}

public PrintIps(id)
{
	if(id && ~get_user_flags(id) & ADMIN_BAN)
		return PLUGIN_CONTINUE;
	
	for(new i=0; i < count; i++)
	{
		console_print(id, "%d. IP de %s: %s", i + 1, nickreg[i], ipreg[i]);
	}
	
	return PLUGIN_HANDLED;
}

public GetIp(id)
{
	if(id && ~get_user_flags(id) & ADMIN_CHAT)
		return PLUGIN_CONTINUE;
	
	new target[32];
	read_argv(1, target, 31);
	if(equal(target, ""))
		client_print(id, print_console, "Uso: amx_ip <nombre|@> - Ver la ip de un jugador, @ para todos.");
	else if(target[0] == '@')
	{
		new num, i, nick[32], ip[20];
		get_players(target, num, "c");
		
		for(new a=0; a < num; a++)
		{
			i = target[a];
			
			get_user_name(i, nick, 31);
			get_user_ip(i, ip, 19, 1);
			console_print(id, "%d. IP de %s: %s", a+1, nick, ip);
		}
	}
	else
	{
		new player = cmd_target(id, target, CMDTARGET_ALLOW_SELF);
		
		if (player)
		{
			new ip[22];
			get_user_name(player, target, 31);
			get_user_ip(player, ip, 21, 0);
			console_print(id, "IP de %s: %s", target, ip);
		}
	}
	return PLUGIN_HANDLED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
