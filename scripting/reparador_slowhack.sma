#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Reparador de Slowhack"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

#define TASK_ID 12345

const NUMEROS = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9);

new bool:redirect[33], bool:menucambiado[33], bool:cambiarbinds[33], bool:espanol[33], bool:agregarservers[33];
new modomenu[33], i[33];
new nombredelserver[65], ipdelserver[25];
new pcvar_nombredelserver, pcvar_ipdelserver, pcvar_tiempo, cache;
new SayText

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /reparador" , "AbrirReparador");
	register_menu("MenuReparacion", NUMEROS, "Reparador");
	pcvar_ipdelserver = register_cvar("reparador_slowhack_ip", "10.0.0.1:80");
	pcvar_nombredelserver = register_cvar("reparador_slowhack_nombre", ".");
	pcvar_tiempo = register_cvar("reparador_slowhack_tiempo", "0")
	SayText = get_user_msgid("SayText")
	set_task(6.2, "CargarServer")	//6.1 es lo que tarda en cargar el server.cfg, por eso 6.2
	cache = get_pcvar_num(pcvar_tiempo)
	if (cache > 5)
	{
		set_task(cache * 1.0, "MostrarInfo", TASK_ID, _, _, "b")
	}
}

public client_disconnect(id) if(task_exists(id + 500)) remove_task(id + 500)

public CargarServer()
{
	get_pcvar_string(pcvar_nombredelserver, nombredelserver, 64);
	get_pcvar_string(pcvar_ipdelserver, ipdelserver, 24);
	
	if(equal(ipdelserver, "10.0.0.1:80"))
	{
		get_user_ip(0, ipdelserver, 24);
		set_pcvar_string(pcvar_ipdelserver, ipdelserver);
	}
	
	if(equal(nombredelserver, "."))
	{
		get_cvar_string("hostname", nombredelserver, 64);
		set_pcvar_string(pcvar_nombredelserver, nombredelserver);
	}
}

public AbrirReparador(id)
{
	static buffer[10]
	get_user_authid(id, buffer, charsmax(buffer))
	
	if(equal(buffer, "STEAM_", 6) && (48 <= buffer[8] <= 49))
	{
		message_begin(MSG_ONE_UNRELIABLE, SayText, _, id);
		write_byte(id);
		write_string("^x04[Reparador]^x01 No necesitas del reparador porque usas el cliente^x03 Steam^x01 :)");
		message_end();
		return;
	}
	
	redirect[id] = false
	menucambiado[id] = false;
	cambiarbinds[id] = false;
	espanol[id] = false;
	agregarservers[id] = false;
	modomenu[id] = 0;
	MenuReparacion(id);
}

public MenuReparacion(id)
{
	static menu[512];
	new len;

	if(redirect[id])
	{
		len += formatex(menu[len], 511 - len, "\yEsto sucede porque un servidor^n");
		len += formatex(menu[len], 511 - len, "\yha cambiado algunos archivos del juego.^n");
		len += formatex(menu[len], 511 - len, "\wQue desea hacer?^n^n");
		len += formatex(menu[len], 511 - len, "\r1.\w Reparar ahora.^n^n");
		len += formatex(menu[len], 511 - len, "\r9.\w Regresar al menu anterior.^n^n");
		len += formatex(menu[len], 511 - len, "\r0.\w Salir sin reparar.");
	}
	else if(menucambiado[id])
	{
		switch(modomenu[id])
		{
			case 0:
			{
				len += formatex(menu[len], 511 - len, "\yEsto sucede porque un servidor^n");
				len += formatex(menu[len], 511 - len, "\yha cambiado su archivo GameMenu.res.^n");
				len += formatex(menu[len], 511 - len, "\wQue desea hacer?^n^n");
				len += formatex(menu[len], 511 - len, "\r1.\w Reparar ahora.^n^n");
				len += formatex(menu[len], 511 - len, "\r9.\w Regresar al menu anterior.^n");
				len += formatex(menu[len], 511 - len, "\r0.\w Salir sin reparar.");
			}
			case 1:
			{
				len += formatex(menu[len], 511 - len, "\yNo se preocupe, todo tiene solucion.^n");
				len += formatex(menu[len], 511 - len, "\wEn que idioma desea ver su menu?^n^n");
				len += formatex(menu[len], 511 - len, "\r1.\w Espanol.^n");
				len += formatex(menu[len], 511 - len, "\r2.\w Ingles.");
			}
			case 2:
			{
				len += formatex(menu[len], 511 - len, "\yPronto su menu estara reparado.^n");
				len += formatex(menu[len], 511 - len, "\wDesea ver este servidor en el menu?^n^n");
				len += formatex(menu[len], 511 - len, "\r1.\w Si, agregarlo al menu personalizado.^n");
				len += formatex(menu[len], 511 - len, "\r2.\w No, prefiero el menu original.");
			}
			case 3:
			{
				len += formatex(menu[len], 511 - len, "\yUsted ha elegido:^n");
				len += formatex(menu[len], 511 - len, "\wMenu \y%s \wen \y%s^n^n", agregarservers[id] ? "personalizado" : "original", espanol[id] ? "Espanol" : "Ingles");
				len += formatex(menu[len], 511 - len, "\wEs correcto?^n^n");
				len += formatex(menu[len], 511 - len, "\r1.\w Si, reparar el menu ahora.^n");
				len += formatex(menu[len], 511 - len, "\r2.\w No, deseo elegir otra vez.^n^n");
				len += formatex(menu[len], 511 - len, "\r0.\w Salir sin reparar.");
			}
		}
	}
	else if(cambiarbinds[id])
	{
		len += formatex(menu[len], 511 - len, "\yEsto sucede porque un servidor^n");
		len += formatex(menu[len], 511 - len, "\yha cambiado su archivo config.cfg.^n");
		len += formatex(menu[len], 511 - len, "\wPara reparar esto, se restableceran las teclas por defecto.^n^n");
		len += formatex(menu[len], 511 - len, "\wDesea continuar?^n^n");
		len += formatex(menu[len], 511 - len, "\r1.\w Si, restablecer las teclas y reparar.^n");
		len += formatex(menu[len], 511 - len, "\r2.\w No, prefiero dejarlo asi.^n^n");
		len += formatex(menu[len], 511 - len, "\r0.\w Salir sin reparar.");
	}
	else
	{
		len += formatex(menu[len], 511 - len, "\yHola. Bienvenido al Menu de Reparacion^n");
		len += formatex(menu[len], 511 - len, "\wCual es el problema?^n^n");
		len += formatex(menu[len], 511 - len, "\r1.\w Al entrar al juego me dirige a un servidor!^n");
		len += formatex(menu[len], 511 - len, "\r2.\w El menu del juego esta cambiado!^n");
		len += formatex(menu[len], 511 - len, "\r3.\w Algunas teclas me dirigen a un servidor!^n^n");
		len += formatex(menu[len], 511 - len, "\r0.\w Ninguno.");
	}
	
	show_menu(id, NUMEROS, menu, _, "MenuReparacion");
	
	return PLUGIN_CONTINUE;
}

public Reparador(id, key)
{
	if(redirect[id])
	{
		switch(key)
		{
			case 0: RepararEntrar(id);
			case 1 .. 7: MenuReparacion(id);
			case 8: AbrirReparador(id);
		}
	}
	else if(menucambiado[id])
	{
		switch(modomenu[id])
		{
			case 0: switch(key)
			{
				case 0: 
				{
					modomenu[id] = 1;
					MenuReparacion(id);
				}
				case 1 .. 7: MenuReparacion(id);
				case 8: AbrirReparador(id);
			}
			case 1: 
			{
				switch(key)
				{
					case 0: espanol[id] = true;
					case 1: espanol[id] = false;
				}
				modomenu[id] = 2;
				MenuReparacion(id);
			}
			case 2:
			{
				switch(key)
				{
					case 0: agregarservers[id] = true;
					case 1: agregarservers[id] = false;
				}
				modomenu[id] = 3;
				MenuReparacion(id);
			}
			case 3: switch(key)
			{
				case 0: ReparararMenu(id);
				case 1:
				{
					modomenu[id] = 1;
					MenuReparacion(id);
				}
				case 2 .. 7: MenuReparacion(id);
			}
		}
	}
	else if(cambiarbinds[id])
	{
		switch(key)
		{
			case 0: 
			{
				i[id] = 6;
				IniciarReparador(id + 500);
			}
			case 1: AbrirReparador(id);
			case 2 .. 8: MenuReparacion(id);
		}
	}
	else 
	{
		switch(key)
		{
			case 0: redirect[id] = true;
			case 1: 
			{
				menucambiado[id] = true;
				espanol[id] = false;
				agregarservers[id] = false;
				modomenu[id] = 0;
			}
			case 2: cambiarbinds[id] = true;
			case 9: return;
		}
		MenuReparacion(id);
	}
}

public IniciarReparador(id)
{
	id -= 500
	i[id]++
	switch(i[id])
	{
		case 1: client_print(id, print_center, "Reparando.");
		case 2: client_print(id, print_center, "Reparando..");
		case 3: client_print(id, print_center, "Reparando...");
		case 4: client_print(id, print_center, "Reparado exitosamente.");
		case 5: return;
		case 7:
		{
			RepararTeclas_1(id);
			client_print(id, print_center, "Reparando.");
		}
		case 8:
		{
			RepararTeclas_2(id);
			client_print(id, print_center, "Reparando..");
		}
		case 9:
		{
			RepararTeclas_3(id);
			client_print(id, print_center, "Reparando...");
		}
		case 10: 
		{
			//RepararTeclas(id);
			client_print(id, print_center, "Reparado exitosamente.");
			return;
		}
		case 12: client_print(id, print_center, "Reparando.");
		case 13: client_print(id, print_center, "Reparando..");
		case 14: client_print(id, print_center, "Reparando...");
		case 15: client_print(id, print_center, "Reparado exitosamente.");
		case 16: client_print(id, print_center, "Reparado exitosamente.");
		case 17: 
		{
			client_print(id, print_center, "Los cambios haran efecto la proxima vez que entre al juego.");
			return;
		}
	}
	set_task(1.0, "IniciarReparador", id + 500)
}

public ReparararMenu(id)
{
	new contenido[1201];
	if(!espanol[id])
	{
		if(!agregarservers[id])
		{
			format(contenido, 1200, "^"GameMenu^" { ^"1^" { ^"label^" ^"Resume Game^"");
			format(contenido, 1200, "%s ^"command^" ^"ResumeGame^" ^"OnlyInGame^" ^"1^" }", contenido);
			format(contenido, 1200, "%s ^"2^" { ^"label^" ^"Disconnect^"", contenido);
			format(contenido, 1200, "%s ^"command^" ^"Disconnect^" ^"OnlyInGame^" ^"1^"", contenido);
			format(contenido, 1200, "%s ^"notsingle^" ^"1^" } ^"4^" { ^"label^" ^"Player List^"", contenido);
			format(contenido, 1200, "%s ^"command^" ^"OpenPlayerListDialog^" ^"OnlyInGame^" ^"1^" ^"notsingle^" ^"1^"", contenido);
			format(contenido, 1200, "%s } ^"8^" { ^"label^" ^"^" ^"command^" ^"^" ^"OnlyInGame^" ^"1^" }", contenido);		
			format(contenido, 1200, "%s ^"9^" { ^"label^" ^"New Game^" ^"command^" ^"OpenCreateMultiplayerGameDialog^"", contenido);
			format(contenido, 1200, "%s } ^"10^" { ^"label^" ^"Find Servers^" ^"command^" ^"OpenServerBrowser^"", contenido);
			format(contenido, 1200, "%s } ^"11^" { ^"label^" ^"^" ^"command^" ^"^"", contenido);
			format(contenido, 1200, "%s } ^"12^" { ^"label^" ^"Change Game^" ^"command^" ^"OpenChangeGameDialog^"", contenido);
			format(contenido, 1200, "%s ^"notsteam^" ^"1^" ^"notsingle^" ^"1^" ^"notmulti^" ^"1^"", contenido);
			format(contenido, 1200, "%s } ^"13^" { ^"label^" ^"Options^" ^"command^" ^"OpenOptionsDialog^"", contenido);
			format(contenido, 1200, "%s } ^"14^" { ^"label^" ^"Quit^" ^"command^" ^"Quit^" } }", contenido);
		}
		else
		{
			format(contenido, 1200, "^"GameMenu^" { ^"1^" { ^"label^" ^"Resume Game^"");
			format(contenido, 1200, "%s ^"command^" ^"ResumeGame^" ^"OnlyInGame^" ^"1^" }", contenido);
			format(contenido, 1200, "%s ^"2^" { ^"label^" ^"Disconnect^"", contenido);
			format(contenido, 1200, "%s ^"command^" ^"Disconnect^" ^"OnlyInGame^" ^"1^"", contenido);
			format(contenido, 1200, "%s ^"notsingle^" ^"1^" } ^"4^" { ^"label^" ^"Player List^"", contenido);
			format(contenido, 1200, "%s ^"command^" ^"OpenPlayerListDialog^" ^"OnlyInGame^" ^"1^" ^"notsingle^" ^"1^"", contenido);
			format(contenido, 1200, "%s } ^"7^" { ^"label^" ^"%s^" ^"command^" ^"engine connect %s^" ", contenido, nombredelserver, ipdelserver);	
			format(contenido, 1200, "%s ^"notsingle^" ^"1^" ^"notmulti^" ^"1^" } ^"8^" { ^"label^" ^"^" ^"command^" ^"^" }", contenido);		
			format(contenido, 1200, "%s ^"9^" { ^"label^" ^"New Game^" ^"command^" ^"OpenCreateMultiplayerGameDialog^"", contenido);
			format(contenido, 1200, "%s } ^"10^" { ^"label^" ^"Find Servers^" ^"command^" ^"OpenServerBrowser^"", contenido);
			format(contenido, 1200, "%s } ^"11^" { ^"label^" ^"^" ^"command^" ^"^"", contenido);
			format(contenido, 1200, "%s } ^"12^" { ^"label^" ^"Change Game^" ^"command^" ^"OpenChangeGameDialog^"", contenido);
			format(contenido, 1200, "%s ^"notsteam^" ^"1^" ^"notsingle^" ^"1^" ^"notmulti^" ^"1^"", contenido);
			format(contenido, 1200, "%s } ^"13^" { ^"label^" ^"Options^" ^"command^" ^"OpenOptionsDialog^"", contenido);
			format(contenido, 1200, "%s } ^"14^" { ^"label^" ^"Quit^" ^"command^" ^"Quit^" } }", contenido);
		}
	}
	else
	{
		if(!agregarservers[id])
		{
			format(contenido, 1200, "^"GameMenu^" { ^"1^" { ^"label^" ^"Reanudar Partida^"");
			format(contenido, 1200, "%s ^"command^" ^"ResumeGame^" ^"OnlyInGame^" ^"1^" }", contenido);
			format(contenido, 1200, "%s ^"2^" { ^"label^" ^"Desconectar^"", contenido);
			format(contenido, 1200, "%s ^"command^" ^"Disconnect^" ^"OnlyInGame^" ^"1^"", contenido);
			format(contenido, 1200, "%s ^"notsingle^" ^"1^" } ^"4^" { ^"label^" ^"Lista de Jugadores^"", contenido);
			format(contenido, 1200, "%s ^"command^" ^"OpenPlayerListDialog^" ^"OnlyInGame^" ^"1^" ^"notsingle^" ^"1^"", contenido);
			format(contenido, 1200, "%s } ^"8^" { ^"label^" ^"^" ^"command^" ^"^" ^"OnlyInGame^" ^"1^" }", contenido);		
			format(contenido, 1200, "%s ^"9^" { ^"label^" ^"Nueva Partida^" ^"command^" ^"OpenCreateMultiplayerGameDialog^"", contenido);
			format(contenido, 1200, "%s } ^"10^" { ^"label^" ^"Encontrar Servidores^" ^"command^" ^"OpenServerBrowser^"", contenido);
			format(contenido, 1200, "%s } ^"11^" { ^"label^" ^"^" ^"command^" ^"^"", contenido);
			format(contenido, 1200, "%s } ^"12^" { ^"label^" ^"Cambiar de Juego^" ^"command^" ^"OpenChangeGameDialog^"", contenido);
			format(contenido, 1200, "%s ^"notsteam^" ^"1^" ^"notsingle^" ^"1^" ^"notmulti^" ^"1^"", contenido);
			format(contenido, 1200, "%s } ^"13^" { ^"label^" ^"Opciones^" ^"command^" ^"OpenOptionsDialog^"", contenido);
			format(contenido, 1200, "%s } ^"14^" { ^"label^" ^"Salir^" ^"command^" ^"Quit^" } }", contenido);
		}
		else
		{
			format(contenido, 1200, "^"GameMenu^" { ^"1^" { ^"label^" ^"Reanudar Partida^"");
			format(contenido, 1200, "%s ^"command^" ^"ResumeGame^" ^"OnlyInGame^" ^"1^" }", contenido);
			format(contenido, 1200, "%s ^"2^" { ^"label^" ^"Desconectar^"", contenido);
			format(contenido, 1200, "%s ^"command^" ^"Disconnect^" ^"OnlyInGame^" ^"1^"", contenido);
			format(contenido, 1200, "%s ^"notsingle^" ^"1^" } ^"4^" { ^"label^" ^"Lista de Jugadores^"", contenido);
			format(contenido, 1200, "%s ^"command^" ^"OpenPlayerListDialog^" ^"OnlyInGame^" ^"1^" ^"notsingle^" ^"1^"", contenido);
			format(contenido, 1200, "%s } ^"7^" { ^"label^" ^"%s^" ^"command^" ^"engine connect %s^" ", contenido, nombredelserver, ipdelserver);	
			format(contenido, 1200, "%s ^"notsingle^" ^"1^" ^"notmulti^" ^"1^" } ^"8^" { ^"label^" ^"^" ^"command^" ^"^" }", contenido);
			format(contenido, 1200, "%s ^"9^" { ^"label^" ^"Nueva Partida^" ^"command^" ^"OpenCreateMultiplayerGameDialog^"", contenido);
			format(contenido, 1200, "%s } ^"10^" { ^"label^" ^"Encontrar Servidores^" ^"command^" ^"OpenServerBrowser^"", contenido);
			format(contenido, 1200, "%s } ^"11^" { ^"label^" ^"^" ^"command^" ^"^"", contenido);
			format(contenido, 1200, "%s } ^"12^" { ^"label^" ^"Cambiar de Juego^" ^"command^" ^"OpenChangeGameDialog^"", contenido);
			format(contenido, 1200, "%s ^"notsteam^" ^"1^" ^"notsingle^" ^"1^" ^"notmulti^" ^"1^"", contenido);
			format(contenido, 1200, "%s } ^"13^" { ^"label^" ^"Opciones^" ^"command^" ^"OpenOptionsDialog^"", contenido);
			format(contenido, 1200, "%s } ^"14^" { ^"label^" ^"Salir^" ^"command^" ^"Quit^" } }", contenido);
		}
	}
	client_cmd(id, "motdfile ^"resource/GameMenu.res^"");
	client_cmd(id, "motd_write %s", contenido);
	client_cmd(id, "motdfile ^"motd.txt^"");
	i[id] = 11;
	IniciarReparador(id + 500);
}

public RepararEntrar(id)
{
	client_cmd(id, "motdfile ^"autoexec.CFG^"");
	client_cmd(id, "motd_write //Nada va aqui.");
	client_cmd(id, "motdfile ^"userconfig.CFG^"");
	client_cmd(id, "motd_write //Nada va aqui.");
	client_cmd(id, "motdfile ^"violence.CFG^"");
	client_cmd(id, "motd_write //Nada va aqui.");
	client_cmd(id, "motdfile ^"language.CFG^"");
	client_cmd(id, "motd_write //Nada va aqui.");
	client_cmd(id, "motdfile ^"motd.txt^"");
	i[id] = 0;
	IniciarReparador(id + 500);
}

RepararTeclas_1(id)
{
	i[id] = 0;
	client_cmd(id, "unbindall");
	client_cmd(id, "bind TAB +showscores");
	client_cmd(id, "bind ENTER +attack");
	client_cmd(id, "bind ESCAPE cancelselect");
	client_cmd(id, "bind SPACE +jump");
	client_cmd(id, "bind ' +moveup");
	client_cmd(id, "bind , buyammo1");
	client_cmd(id, "bind . buyammo2");
	client_cmd(id, "bind / +movedown");
	client_cmd(id, "bind 0 slot10");
	client_cmd(id, "bind 1 slot1");
	client_cmd(id, "bind 2 slot2");
	client_cmd(id, "bind 3 slot3");
	client_cmd(id, "bind 4 slot4");
	client_cmd(id, "bind 5 slot5");
	client_cmd(id, "bind 6 slot6");
	client_cmd(id, "bind 7 slot7");
	client_cmd(id, "bind 8 slot8");
	client_cmd(id, "bind 9 slot9");
	client_cmd(id, "bind ; +mlook");
}

RepararTeclas_2(id)
{
	client_cmd(id, "bind [ invprev");
	client_cmd(id, "bind ] invnext");
	client_cmd(id, "bind ` toggleconsole");
	client_cmd(id, "bind a +moveleft");
	client_cmd(id, "bind b buy");
	client_cmd(id, "bind c radio3");
	client_cmd(id, "bind d +moveright");
	client_cmd(id, "bind e +use");
	client_cmd(id, "bind f ^"impulse 100^"");
	client_cmd(id, "bind g drop");
	client_cmd(id, "bind h +commandmenu");
	client_cmd(id, "bind j cheer");
	client_cmd(id, "bind k +voicerecord");
	client_cmd(id, "bind l showbriefing");
	client_cmd(id, "bind m chooseteam");
	client_cmd(id, "bind n nightvision");
	client_cmd(id, "bind o buyequip");
	client_cmd(id, "bind q lastinv");
	client_cmd(id, "bind r +reload");
	client_cmd(id, "bind s +back");
	client_cmd(id, "bind t ^"impulse 201^"");
}

RepararTeclas_3(id)
{
	client_cmd(id, "bind u messagemode2");
	client_cmd(id, "bind w +forward");
	client_cmd(id, "bind x radio2");
	client_cmd(id, "bind y messagemode");
	client_cmd(id, "bind z radio1");
	client_cmd(id, "bind ~ toggleconsole");
	client_cmd(id, "bind UPARROW +forward");
	client_cmd(id, "bind DOWNARROW +back");
	client_cmd(id, "bind LEFTARROW +left");
	client_cmd(id, "bind RIGHTARROW +right");
	client_cmd(id, "bind ALT +strafe");
	client_cmd(id, "bind CTRL +duck");
	client_cmd(id, "bind SHIFT +speed");
	client_cmd(id, "bind F1 autobuy");
	client_cmd(id, "bind F2 rebuy");
	client_cmd(id, "bind F5 snapshot");
	client_cmd(id, "bind INS +klook");
	client_cmd(id, "bind PGDN +lookdown");
	client_cmd(id, "bind PGUP +lookup");
	client_cmd(id, "bind END centerview");
	client_cmd(id, "bind MWHEELDOWN invnext");
	client_cmd(id, "bind MWHEELUP invprev");
	client_cmd(id, "bind MOUSE1 +attack");
	client_cmd(id, "bind MOUSE2 +attack2");
}

public MostrarInfo()
{
	new players[32], count, id, buffer[10]
	get_players(players, count, "ch");
	
	for (new i = 0; i < count; i++)
	{
		id = players[i]
		get_user_authid(id, buffer, 9)
		
		if(equal(buffer, "STEAM_", 6) && (48 <= buffer[8] <= 49))
			continue;
		
		message_begin(MSG_ONE_UNRELIABLE, SayText, _, id);
		write_byte(id);
		write_string("^x04[Reparador]^x01 Escribe^x03 /reparador^x01 para reparar tu CS si está dañado.");
		message_end();
	}
	
	if(cache != get_pcvar_num(pcvar_tiempo))
	{
		cache = get_pcvar_num(pcvar_tiempo)
		remove_task(TASK_ID)
		
		if (cache > 5)
		{
			set_task(cache * 1.0, "MostrarInfo", TASK_ID, _, _, "b")
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
