#include <amxmodx>
/*================================================
[Seccion editable]
==================================================

El plugin maneja 2 tipos de admin:
- El de tipo 1 es el "normal".
- El de tipo 2 es el "supremo" con mas poder.
- El admin de tipo 1 (admin normal) no debe tener el flag del admin tipo 2.
- El admin de tipo 2 (admin superior) si puede tener el flag del admin tipo 1.	*/


new ADMIN_TIPO1	=	ADMIN_KICK			// Nivel de admin para aparecer entre los admins tipo 1 (normal) online.

new ADMIN_TIPO2	=	ADMIN_IMMUNITY			// Nivel de admin para aparecer entre los admins tipo 2 (superior) online.


/*================================================

Como aparecen los admins, ejemplo:
- Los de tipo 1: "X" Moderadores conectados: nombres...
- Los de tipo 2: "X" Admins conectados: nombres...	*/


new const NOMBRE_ADMIN1[] =	"Admin"				// Como sale el admin tipo 1 conectado (singular).

new const NOMBRE_ADMIN1S[] =	"Admins"			// Como salen los admins tipo 1 conectados (plural).

new const NOMBRE_ADMIN2[] =	"Admin general (Staff)"		// Como sale el admin tipo 2 conectado (singular).

new const NOMBRE_ADMIN2S[] =	"Admins generales (Staff)"	// Como salen los admins tipo 2 conectados (plural).


/*================================================

Datos de contacto:
- Si no quieres mostrar contacto, pon la cvar ac_contacto en 0.
- Primero pones el nombre del servicio, luego tus datos del servicio.
- Puedes agregar, cambiar o quitar los que quieras, siempre siguiendo el formato.
- Asegurate de seguir el formato o los datos no se mostraran correctamente.	*/


new const DATOS_CONTACTO[][] = { 
	"Facebook"	,	"fb.com/groups/ZILHS"
	,	"Discord"		,	"discord.gg/5HCxhhV"
	,	"Whatsapp"	,	"chat.whatsapp.com/Cj3222P9TS5K2ZjN9c83Vn"
}


/*================================================

Comandos para mostrar los datos:
- En COMANDOS_ADMIN estan los comandos de chat para mostrar los admins conectados.
- En COMANDOS_CONTACTO estan los comandos de chat para mostrar los datos de contacto.
- Si quieres que un comando muestre los 2, agregalo 2 veces.	*/


new const COMANDOS_ADMIN[][] = { "admin" }

new const COMANDOS_CONTACTO[][] = { "discord", "comprar", "contacto", "facebook", "whatsapp" }


/*================================================
[Fin de la seccion editable]
==================================================

Informacion de CVARs:
- El color funciona asi: 0 - Normal (Amarillo), 1 - Verde, 2 - Color de team.
- En caracteres puedes definir cuantos caracteres pueden entrar en una linea.
- Baja el numero de caracteres si no se muestra todo el contacto o los admins.
- Mostrar a todos: Si un user pone /admin, los admins se mostraran a todos.
- Mostrar comandos sirve si se usa el modo reconocimiento 0.

- Modo de reconocimiento:
* 0 - Para que tengas que escribir el comando exacto para mostrar la info.
* 1 - Para que puedas escribir el comando junto a otras palabras para mostrar la info.
** Ej: En modo 0:
(chat) TuNombre :  hay algun admin conectado?
(chat) (no sale nada)
(chat) TuNombre :  admin
(chat) 1 Admin conectado :  NombreDelAdmin
** Ej: En modo 1:
(chat) TuNombre :  hay algun admin conectado?
(chat) 1 Admin conectado :  NombreDelAdmin
- El modo 1 es algo m�s lento, si has puesto muchos comandos, considera usar el modo 0.


* ac_contacto <0|1>		// Activa o desactiva el contacto.

* ac_color_texto <0|1|2>	// Color para textos (Texto "Admins conectados", medios de contacto).

* ac_color_nombre <0|1|2>	// Color para nombres (Nombres de admins conectados, datos de contacto).

* ac_caracteres <#>		// Cantidad maxima preferida de caracteres en una linea.

* ac_mostrar_todos <0|1>	// Mostrar los admins o el contacto a todos. 0 - No, solo al user que pidio. 1 - Si.

* ac_mostrar_comandos <0|1>	// Si se usa modo de reconocimiento 0, 0 - No mostrar comandos, 1 - Mostrar comandos

* ac_modo_reconocimiento <0|1>	// Modo de reconocimiento, 0 - Comando exacto, 1 - Contener el comando


- ADVERTENCIA: Usar valores no permitidos puede crashear el servidor.

==================================================*/

#define PLUGIN_NAME	"Ver Admins y Contacto"
#define PLUGIN_VERSION	"1.2"

new const DATA_COL[3][] = { "^x01", "^x04", "^x03" };

#pragma semicolon 1

new msgsaytext, COLOR_TEXTOS, COLOR_NOMBRES, CARACTERES;
new cvar_tcolor, cvar_ncolor, cvar_chars, cvar_contacto, cvar_recon, cvar_show, cvar_all;

public plugin_init()
{
	msgsaytext = get_user_msgid("SayText");
	
	cvar_tcolor = register_cvar("ac_color_texto", "2");
	cvar_ncolor = register_cvar("ac_color_nombres", "1");
	cvar_chars = register_cvar("ac_caracteres", "120");
	cvar_contacto = register_cvar("ac_contacto", "1");
	cvar_recon = register_cvar("ac_modo_reconocimiento", "1");
	cvar_show = register_cvar("ac_mostrar_comandos", "1");
	cvar_all = register_cvar("ac_mostrar_todos", "1");
	
	register_clcmd("say", "handle_say");
	register_clcmd("say_team", "handle_say");
	
	register_clcmd("mostrar_admins", "forze_admins");
	
	new buffer[50], i;
	for(i = 0; i < sizeof(COMANDOS_ADMIN); i++)
	{
		formatex(buffer, 29, "say %s", COMANDOS_ADMIN[i]);
		register_clcmd(buffer, "func_admins");
		formatex(buffer, 29, "say_team %s", COMANDOS_ADMIN[i]);
		register_clcmd(buffer, "func_admins");
	}
	
	for(i = 0; i < sizeof(COMANDOS_CONTACTO); i++)
	{
		formatex(buffer, 29, "say %s", COMANDOS_CONTACTO[i]);
		register_clcmd(buffer, "func_contact_info");
		formatex(buffer, 29, "say_team %s", COMANDOS_CONTACTO[i]);
		register_clcmd(buffer, "func_contact_info");
	}
	
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, "Mia2904");
}

public handle_say(id)
{
	if(!get_pcvar_num(cvar_recon)) return PLUGIN_CONTINUE;
	
	static said[192];
	new i;
	read_args(said,192);
	
	for(i = 0; i < sizeof(COMANDOS_ADMIN); i++)
	{
		if(containi(said, COMANDOS_ADMIN[i]) != -1)
		{
			set_task(0.1, "print_admins", id);
			break;
		}
	}
	
	if(get_pcvar_num(cvar_contacto)) for(i = 0; i < sizeof(COMANDOS_CONTACTO); i++)
	{
		if(containi(said, COMANDOS_CONTACTO[i]) != -1)
		{
			set_task(0.1, "print_contact_info", id);
			break;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public forze_admins(id)
{
	set_task(0.1, "print_admins", id);
	return PLUGIN_HANDLED;
}

public func_admins(id)
{
	if(get_pcvar_num(cvar_recon)) return PLUGIN_CONTINUE;
	
	set_task(0.1, "print_admins", id);
	
	return (get_pcvar_num(cvar_show)) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public func_contact_info(id)
{
	if(get_pcvar_num(cvar_recon) || !get_pcvar_num(cvar_contacto)) return PLUGIN_CONTINUE;
	
	set_task(0.1, "print_contact_info", id);
	
	return (get_pcvar_num(cvar_show)) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public print_admins(id)
{
	static adminsids[2][32 char], message[192], players[32], playersnum;
	new count, gcount, len, i;
	
	CARACTERES = get_pcvar_num(cvar_chars);
	COLOR_TEXTOS = get_pcvar_num(cvar_tcolor);
	COLOR_NOMBRES = get_pcvar_num(cvar_ncolor);
	
	get_players(players, playersnum, "ch");
	
	for(i = 0; i < playersnum; i++)
	{
		len = get_user_flags(players[i]);
		
		if(len & ADMIN_TIPO2)
		{
			//get_user_name(players[i], adminnames[31 - gcount], charsmax(adminnames[]));
			adminsids[1]{gcount} = players[i];
			gcount++;
		}
		else if(len & ADMIN_TIPO1)
		{
			//get_user_name(players[i], adminnames[count], charsmax(adminnames[]));
			adminsids[0]{count} = players[i];
			count++;
		}
	}
	
	len = 0;
	
	if(count || gcount)
	{
		new name[32];
		if(count)
		{
			len += formatex(message, 191, "%s%d %s conectad%s:%s ", DATA_COL[COLOR_TEXTOS], count, count > 1 ? NOMBRE_ADMIN1S : NOMBRE_ADMIN1, count > 1 ? "os" : "o", DATA_COL[COLOR_NOMBRES]);
		
			for(i = 0; i < count; i++)
			{
				if(len > CARACTERES)
				{
					print_message(id, message);
					len = formatex(message, 191, "%s", DATA_COL[COLOR_NOMBRES]);
				}
				
				get_user_name(adminsids[0]{i}, name, 31);
				len += formatex(message[len], 191-len, "%s%s ", name, i < (count-1) ? ",":"");
			}
		
			print_message(id, message);
		}
		
		if(gcount)
		{
			len = formatex(message, 191, "%s%d %s conectad%s:%s ", DATA_COL[COLOR_TEXTOS], gcount, gcount > 1 ? NOMBRE_ADMIN2S : NOMBRE_ADMIN2, gcount > 1 ? "os" : "o", DATA_COL[COLOR_NOMBRES]);
		
			for(i = 0; i < gcount; i++)
			{
				if(len > CARACTERES)
				{
					print_message(id, message);
					len = formatex(message, 191, "%s", DATA_COL[COLOR_NOMBRES]);
				}
				
				get_user_name(adminsids[1]{i}, name, 31);
				len += formatex(message[len], 191-len, "%s%s ", name, i < (gcount-1) ? ",":"");
			}
			
			print_message(id, message);
		}
	}
	else
	{
		formatex(message, 191, "%sNo hay %s conectados.", DATA_COL[COLOR_TEXTOS], NOMBRE_ADMIN1S);
		print_message(id, message);
	}
}

public print_contact_info(id)
{
	CARACTERES = get_pcvar_num(cvar_chars);
	COLOR_TEXTOS = get_pcvar_num(cvar_tcolor);
	COLOR_NOMBRES = get_pcvar_num(cvar_ncolor);
	
	static contactmsg[192], i;
	new len;
	
	for(i = 0; i < sizeof(DATOS_CONTACTO); i += 2)
	{
		if(len > CARACTERES)
		{
			print_message(id, contactmsg);
			len = 0;
		}
		
		len += formatex(contactmsg[len], 191, "%s%s:%s %s ", DATA_COL[COLOR_TEXTOS], DATOS_CONTACTO[i], DATA_COL[COLOR_NOMBRES], DATOS_CONTACTO[i+1]);
	}
	
	if(len) print_message(id, contactmsg);
}

print_message(id, msg[])
{
	if(!get_pcvar_num(cvar_all))
	{
		message_begin(MSG_ONE_UNRELIABLE, msgsaytext, _, id);
		write_byte(33);
		write_string(msg);
		message_end();
		
		return;
	}
	
	static players[32], count;
	get_players(players, count, "ch");
	
	for(new i = 0; i < count; i++)
	{
		id = players[i];
		message_begin(MSG_ONE_UNRELIABLE, msgsaytext, _, id);
		write_byte(33);
		write_string(msg);
		message_end();
	}
}
