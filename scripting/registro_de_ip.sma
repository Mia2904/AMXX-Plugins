#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Registro de IPs"
#define VERSION "1.0"
#define AUTHOR "Mia2904"

const MAX_IP_REG = 150

const MAX_CONNECT_TOTAL = 10
const MAX_CONNECT_TIME = 6
const MAX_TIME_BAN = 10

new ipreg[MAX_IP_REG][22], nickreg[MAX_IP_REG][32], tiempo[MAX_IP_REG], count, bool:reset;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_concmd("amx_ip", "GetIp", _, "<nombre|@> - Ver la ip de un jugador, @ para todos.");
	register_concmd("vertodaslasip", "PrintIps");
	reset = false;
}

public client_connect(id)
{
	if (is_user_bot(id))
		return;
	
	get_user_ip(id, ipreg[count], 21, 0);
	get_user_name(id, nickreg[count], 31);
	tiempo[count] = get_systime();
	new temp = count
	count++
	
	if(count >= MAX_IP_REG)
	{
		reset = true;
		count = 1;
	}
	
	CheckIp(temp, id);
}

CheckIp(temp, id)
{
	new maxloops, matches, i, bool:timecheck;
	static lastmatches[MAX_CONNECT_TOTAL];
	
	maxloops = reset ? MAX_IP_REG : temp
	
	for (i = 0; i < maxloops; i++)
	{
		if (i == temp)
			continue;
		
		if (equal(ipreg[temp], ipreg[i]))
		{
			lastmatches[matches] = i;
			
			if (++matches >= MAX_CONNECT_TIME-1)
				timecheck = true;
			
			if (matches >= MAX_CONNECT_TOTAL-1)
			{
				server_cmd("kick #%d ^"Fake client. Added to banned list.^"", get_user_userid(id))
				server_cmd("addip 120.0 ^"%s^";writeip", ipreg[temp])
				log_to_file("cliente_falso.txt", "IP %s ban por 2 horas por conectarse %d veces en total. (Nick: %s)", ipreg[temp], MAX_CONNECT_TOTAL, nickreg[temp])
				return;
			}
		}
	}
	
	if (timecheck)
	{
		new systime = get_systime();
		maxloops = matches > MAX_CONNECT_TOTAL ? MAX_CONNECT_TOTAL : matches;
		
		for (i = 0; i < maxloops; i++)
		{
			if (systime - tiempo[lastmatches[i]] <= MAX_TIME_BAN)
			{
				server_cmd("kick #%d ^"Fake client. Added to banned list.^"", get_user_userid(id))
				server_cmd("addip 120.0 ^"%s^";writeip", ipreg[temp])
				log_to_file("cliente_falso.txt", "IP %s ban por 2 horas por conectarse %d veces en %d segundos. (Nick: %s)", ipreg[temp], MAX_CONNECT_TIME, MAX_TIME_BAN, nickreg[temp])
				break;
			}
		}
	}
}

public PrintIps(id)
{
	if(id && ~get_user_flags(id) & ADMIN_BAN)
		return PLUGIN_CONTINUE;
		
	new maxloops = reset ? MAX_IP_REG : count;
	new actime = get_systime();
	new temptime;
	
	for (new i = 0; i < maxloops; i++)
	{
		temptime = actime - tiempo[i];
		console_print(id, "%d. (%dm %ds) IP de %s: %s", i + 1, temptime/60, temptime%60, nickreg[i], ipreg[i], tiempo[i]);
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
		new num, i, nick[32], ip[22];
		get_players(target, num, "c");
		
		for(new a=0; a < num; a++)
		{
			i = target[a];
			
			get_user_name(i, nick, 31);
			get_user_ip(i, ip, 21, 0);
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
