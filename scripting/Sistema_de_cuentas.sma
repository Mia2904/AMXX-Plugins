/*
	Sistema de Cuentas + Personajes
	
	Autor : Mia2904
	
	Thread : http://amxmodx-es.com/Thread-Sistema-de-Cuentas-Fvault-Con-Personajes
	
	Creditos :
	- Exolent : Sistema de guardado FVault.
	- Sangriento : Base del sistema de cuentas.
	- [R]ak : Encontrar el bug de bypassear el login con OldMenu (O adivinarlo?).
	
	Historial de versiones:
	
	v 1.2
	- Version final (Sangriento).
	
	v 1.3
	- Se agregaron personajes.
	- Se agregaron cvars, comando para entrar al men� de personajes.
	
	v 1.4
	- Cantidad de personajes din�mica.
	
	v 1.5
	- Guardado reconstruido: Ahora se usa un ID num�rico como key.
	
	v 1.6
	- Guardado automatico al desloguear.
	- Agregado: Entrar como invitado.
	
	v 1.6.1
	- Fixed: Entrar sin loguearse con el men� antiguo. (Gracias [R]ak).
	- Removido: #pragma semicolon.
	
	v 1.7
	- Optimizaci�n del c�digo.
	- Se agregaron 2 cvars.
	- Agregado: Aviso cuando alguien se loguea.
	- Agregado: Tag [No Registrado] a los usuarios invitados.
	- Agregado: Men� de confirmaci�n para crear una cuenta.
	- Fixed: Invitados se pueden cambiar el nombre.
	- Fixed: No puedes loguearte si est�s como invitado.
	- Fixed: Usar la misma cuenta simultaneamente.
	
	v 1.7.1
	- Fixed: Bug con el remove_quotes.
	- Se ordeno la informacion en la fuente del plugin.
	
	v 1.8
	- Agregado: Tries para precargar los nombres de personajes y cuentas.
	
	v 1.8.1
	- Agregado: Regex para solicitar un e-mail v�lido.
	- Fixed: Mas de un usuario no registrado con el mismo nombre.
	
	v 1.8.2
	- Fixed: Terrible bug con los User ID. (Gracias ivan)
	
================================================================================
	Como configurar el guardado
================================================================================

-->Funcion de Cargar Datos
CargarDatos(id)
{
	-->Si esta logueado
	if (personaje(id))
	{
		-->Esto no se toca O.O
		formatex(g_buffer[id], charsmax(g_buffer[]), "%d", id_personaje(id))
		
		-->Si tiene un personaje creado le cargamos los datos...
		if (fvault_get_data(g_db_datos, g_buffer[id], g_data, charsmax(g_data)))
		{
			-->Como guardamos solo una variable (dinero) entonces en el parse solo sacamos 1
			-->Fvault guarda numeros como si fueran palabras
			-->Asi que luego tenemos que convertir a numeros
			-->parse () es el dios salvador aqui, solo le agregamos la cantidad de datos
			-->Que vamos a obtener, aqui como solo es 1, creamos un string y se lo indicamos
			-->Despues de cada string va la longitud del numero, charsmax(sting) nos retorna este valor
			-->str_to_num( string ) nos convierte la palabra en un numero
			-->Si fueran 2 datos, dinero y ammpacks, hariamos esto
			
			-->APs puede almacenar 8 cifras, EXP puede almacenar 9
				
			new APs[ 9 ], EXP[ 10 ]
			parse( data, MONEY, charsmax( MONEY ), EXP, charsmax( EXP ) )
			cs_set_user_money( id, str_to_num( MONEY ) )
			zp_set_user_ammo_packs( id, str_to_num( EXP ) )
			
			-->Se cargaron datos, ya terminamos aqu�.
			return;
		}
	}
	
	-->Si es un personaje nuevo o es invitado le dejamos los stats iniciales
	-->Es decir le dejamos los datos normales para cuando un personaje nuevo empieza a jugar
	
	cs_set_user_money(id, 800)
	
	-->Si tambien guardamos AP, entonces aqui seteamos los APs iniciales.
	zp_set_user_ammo_packs( id, 5 )
}

--> Funcion de Guardar Datos
GuardarDatos(id)
{
	-->Asi se guardaran los datos, por ejemplo si tengo 5000 de dinero
	-->La linea de datos quedaria solo "5000"
	-->Si quiero guardar otros datos, por ejemplo los ammo packs (tengo 100)
	formatex( data, charsmax( data ), "%d %d", cs_get_user_money( id ), zp_get_user_ammo_packs( id ) )
	
	-->Y guardara asi "5000 100"
	
	-->Esto no se toca O.O
	Save(id)
}
*/

/*================================================================================
	Inicio del Plugin
=================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <fvault>
#include <cstrike>

// Esto sirve para no aceptar E-Mails inv�lidos.
// Comenta o elimina esta linea si tienes errores con Regex.
#include <regex>

/*================================================================================
	Variables / Constantes / Macros
=================================================================================*/

// Cuantos personajes se pueden crear en una cuenta.
const CANTIDAD_PERSONAJES = 5

// Nombres de los vaults
new const g_db_ac[] = "Cuentas"
new const g_db_pj[] = "Personajes"
new const g_db_datos[] = "Datos"

// Sonido al conectarse (.wav)
new const SONIDO_ENTRAR[] = "buttons/bell1.wav"

// Esta de mas decirlo...
new const NOMBRE_DE_TU_SERVER[] = "Nombre del Server"

// Variables del plugin
new g_userid[33];
new g_pjconnect[33 char];
new g_buffer[33][34];
new g_nombre[33][CANTIDAD_PERSONAJES+1][32];
new g_bLogueado, g_bInvitado;
new g_data[CANTIDAD_PERSONAJES*35], g_msg[150];
new g_reg_menu;
new Trie:g_personajes_creados, Trie:g_cuentas_creadas;
new cvar_minacchar, cvar_minpwchar, cvar_jointeam, cvar_allowguests, cvar_enablemail, cvar_saylog;
new g_msgSayText;
#if defined _regex_included
new Regex:g_regexid
#endif

new const PLUGIN[] = "Sistema de Cuentas";
const OFFSET_VGUI_JOINTEAM = 2;

#define menu_registro(%0) menu_display(%0,g_reg_menu)
#define player_buffer(%0) g_nombre[0][0][%0-1]
#define player_logueado(%0) (g_bLogueado & (1<<%0-1))
#define player_invitado(%0) (g_bInvitado & (1<<%0-1))
#define personaje(%0) g_pjconnect{%0}
#define g_lastuserid g_userid[0]
#define id_personaje(%0) ((g_userid[%0]-1)*CANTIDAD_PERSONAJES)+g_pjconnect{%0}
#define MAXPLAYERS g_pjconnect{0}
#define Save(%0) {\
	g_buffer[%0][0] = EOS;\
	formatex(g_buffer[%0], charsmax(g_buffer[]), "%d", id_personaje(%0));\
	fvault_set_data(g_db_datos, g_buffer[%0], g_data);\
}

#define REGEX_PATTERN "^^[A-Z0-9._+-]+@[A-Z0-9.-]+\.(?:[A-Z]{2}|com|net|fox|biz)$"

// Esto es para mas orden...
#define MENU_ITEM_KEY(%0) (1<<%0)

/*================================================================================
	Cargar / Guardar datos
=================================================================================*/

CargarDatos(id)
{
	if (personaje(id))
	{
		formatex(g_buffer[id], charsmax(g_buffer[]), "%d", id_personaje(id))
	
		// Cargar datos (Si existen)
		if (fvault_get_data(g_db_datos, g_buffer[id], g_data, charsmax(g_data)))
		{
			new MONEY[9]
			parse(g_data, MONEY, charsmax(MONEY))
			cs_set_user_money(id, str_to_num(MONEY))
			
			return;
		}
	}
	
	 // No se cargaron datos, es un usuario nuevo o un invitado.
	cs_set_user_money(id, 800)
}

GuardarDatos(id)
{
	formatex(g_data, charsmax(g_data), "%d", cs_get_user_money(id))
	
	Save(id)
}

/*================================================================================
	Forwards
=================================================================================*/

public plugin_init()
{
	register_plugin(PLUGIN, "1.8", "Mia2904, Sangriento");
	
	// Regex
	#if defined _regex_included
	g_regexid = regex_compile(REGEX_PATTERN, g_reg_menu, g_msg, charsmax(g_msg), "i")
	if (g_regexid < REGEX_OK)
	{
		log_amx("Error de Regex (%d): %s", g_reg_menu, g_msg);
		pause("a");
		return;
	}
	#endif
	
	// Hooks
	register_message(get_user_msgid("ShowMenu"), "message_showmenu");
	register_message(get_user_msgid("VGUIMenu"), "message_vguimenu");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_clcmd("chooseteam", "clcmd_jointeam");
	register_clcmd("jointeam", "clcmd_jointeam");
	
	// Comandos / Funciones internas
	register_clcmd("say /personajes", "clcmd_personajes");
	register_clcmd("Nueva_cuenta", "creando_cuenta");
	register_clcmd("Nueva_password", "creando_password");
	register_clcmd("Nuevo_email", "creando_email");
	register_clcmd("Loguear_cuenta", "logueando_cuenta");
	register_clcmd("Loguear_password", "logueando_password");
	
	// Cvars
	cvar_allowguests = register_cvar("cuentas_invitados", "1");
	cvar_saylog = register_cvar("cuentas_log_aviso", "1");
	cvar_enablemail = register_cvar("cuentas_reg_email", "0");
	cvar_jointeam = register_cvar("cuentas_elegir_team", "1");
	cvar_minacchar = register_cvar("cuentas_ac_min_char", "4");
	cvar_minpwchar = register_cvar("cuentas_pw_min_char", "4");
	
	// Etc
	MAXPLAYERS = get_maxplayers();
	g_msgSayText = get_user_msgid("SayText");
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged");
}

public plugin_cfg()
{
	g_personajes_creados = TrieCreate();
	g_cuentas_creadas = TrieCreate();
	
	cargar_todos_los_datos();
	
	formatex(g_msg, charsmax(g_msg), "Bienvenido a\r %s^n\y%s", NOMBRE_DE_TU_SERVER, PLUGIN);
	g_reg_menu = menu_create(g_msg, "handler_registro");
	
	menu_additem(g_reg_menu, "\yLoguear\w Cuenta");
	menu_additem(g_reg_menu, "\yCrear\w Cuenta^n");
	if (get_pcvar_num(cvar_allowguests))
		menu_additem(g_reg_menu, "Entrar como\y Invitado");
	
	menu_setprop(g_reg_menu, MPROP_EXIT, MEXIT_NEVER);
}

public plugin_end()
{
	TrieDestroy(g_personajes_creados);
	TrieDestroy(g_cuentas_creadas);
}

public client_disconnect(id)
{
	if (personaje(id))
		GuardarDatos(id);
	
	ResetearVariables(id);
}

public fw_ClientUserInfoChanged(id)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED;
	
	static szOldName[32], szName[32];
	
	get_user_name(id, szOldName, 31);
	get_user_info(id, "name", szName, 31);
	
	if (equal(szName, szOldName))
		return FMRES_IGNORED;
	
	if ((personaje(id) || player_invitado(id)) && !equal(szName, g_nombre[id][personaje(id)], strlen(szName)))
	{
		set_user_info(id, "name", g_nombre[id][personaje(id)]);
		formatex(g_msg, charsmax(g_msg), "No puedes cambiarte el nombre.");
		send_message(id);
	}
	
	return FMRES_SUPERCEDE;
}

/*================================================================================
	Hooks globales
=================================================================================*/

public message_vguimenu(junk1, junk2, id)
{
	if (get_msg_arg_int(1) != OFFSET_VGUI_JOINTEAM)
		return PLUGIN_CONTINUE;
	
	if (player_logueado(id))
	{
		if (!personaje(id) && !player_invitado(id))
		{
			menu_personajes(id);
			return PLUGIN_HANDLED;
		}
		
		return PLUGIN_CONTINUE;
	}
	
	menu_registro(id);
	return PLUGIN_HANDLED;
}

public message_showmenu(junk1, junk2, id)
{
	static szCode[32];
	get_msg_arg_string(4, szCode, charsmax(szCode));
	
	if (contain(szCode, "#Team") == -1)
		return PLUGIN_CONTINUE;
	
	if (player_logueado(id))
	{
		if (!personaje(id) && !player_invitado(id))
		{
			menu_personajes(id);
			return PLUGIN_HANDLED;
		}
		
		return PLUGIN_CONTINUE;
	}
	
	menu_registro(id);
	return PLUGIN_HANDLED;
}

public clcmd_jointeam(id)
{
	if (player_logueado(id))
	{
		if (!personaje(id) && !player_invitado(id))
		{
			menu_personajes(id);
			return PLUGIN_HANDLED;
		}
		
		return PLUGIN_CONTINUE;
	}
	
	menu_registro(id);
	return PLUGIN_HANDLED;
}

public event_new_round()
{
	for (new i = 1; i <= MAXPLAYERS; i++)
		if (personaje(i))
			GuardarDatos(i);
}

/*================================================================================
	Comandos / Funciones internas
=================================================================================*/

public clcmd_personajes(id)
{
	if (player_invitado(id))
		menu_registro(id);
	else if (!player_logueado(id))
		client_print(id, print_center, "No te has logueado.");
	else
		menu_personajes(id);
	
	return PLUGIN_HANDLED;
}

public handler_registro(id, menu, item)
{
	if (item == MENU_EXIT)
		return PLUGIN_HANDLED;
	
	if (cs_get_user_team(id) != CS_TEAM_UNASSIGNED)
	{
		if (player_invitado(id) && item == 2)
		{
			formatex(g_msg, charsmax(g_msg), "Ya has entrado como invitado.");
			send_message(id);
			
			return PLUGIN_HANDLED;
		}
		else
		{
			if (is_user_alive(id))
				dllfunc(DLLFunc_ClientKill, id);
			
			cs_set_user_team(id, CS_TEAM_UNASSIGNED);
			ResetearVariables(id);
		}
	}
	
	switch (MENU_ITEM_KEY(item))
	{
		case MENU_KEY_1:
		{
			client_cmd(id, "messagemode Loguear_cuenta");
			formatex(g_msg, charsmax(g_msg), "Ingrese su cuenta");
			send_message(id);
		}
		case MENU_KEY_2:
		{
			client_cmd(id, "messagemode Nueva_cuenta");
			formatex(g_msg, charsmax(g_msg), "Crear cuenta.^nIngrese una nueva cuenta.");
			send_message(id);
		}
		case MENU_KEY_3:
		{
			g_bLogueado |= (1 << id-1);
			g_bInvitado |= (1 << id-1);
			personaje(id) = 0;
			
			set_pdata_int(id, 125, (get_pdata_int(id, 125) & ~(1 << 8)));
			client_cmd(id, "jointeam%s", get_pcvar_num(cvar_jointeam) ? "" : " 5");
			
			formatex(g_nombre[id][0], charsmax(g_nombre[][]), "[No Reg]#%02d ", id);
			get_user_name(id, g_nombre[id][0][12], 19);
			set_user_info(id, "name", g_nombre[id][0]);
			
			CargarDatos(id);
			
			if (get_pcvar_num(cvar_saylog))
			{
				formatex(g_msg, charsmax(g_msg), "^x04[AMXX]^x01 Ha entrado^x04 %s^x01 (No Registrado).", g_nombre[id][0][12]);
				connect_message(id);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public creando_cuenta(id)
{
	if (player_logueado(id)) return;
	
	g_buffer[id][0] = g_data[0] = EOS;
	read_args(g_buffer[id], charsmax(g_buffer[]));
	
	if (check_input(g_buffer[id], g_nombre[id][0]) < get_pcvar_num(cvar_minacchar))
	{
		formatex(g_msg, charsmax(g_msg), "La cuenta debe tener %d caracteres como minimo,^ny no puede llevar comillas ( ^" ).", get_pcvar_num(cvar_minacchar));
		send_message(id);
	}
	else if (TrieKeyExists(g_cuentas_creadas, g_nombre[id][0]))
	{
		formatex(g_msg, charsmax(g_msg), "La cuenta que quieres crear ya existe.");
		send_message(id);
	}
	else
	{
		formatex(g_msg, charsmax(g_msg), "Ingresa una contraseña para tu nueva cuenta.");
		send_message(id);
		client_cmd(id, "messagemode Nueva_password");
		return;
	}
	
	g_nombre[id][0][0] = EOS;
	menu_registro(id);
}

public creando_password( id )
{
	if (player_logueado(id)) return;
	
	g_buffer[id][0] = g_data[0] = EOS;
	read_args(g_buffer[id], charsmax(g_buffer[]));
	
	if (check_input(g_buffer[id], g_buffer[id]) < get_pcvar_num(cvar_minpwchar))
	{
		formatex(g_msg, charsmax(g_msg), "La contraseña debe tener %d caracteres como minimo y no puede llevar comillas ( ^" ).^nVuelve a intentarlo.", get_pcvar_num(cvar_minpwchar));
		send_message(id);
		client_cmd(id, "messagemode Nueva_password");
	}
	else if (get_pcvar_num(cvar_enablemail))
	{
		formatex(g_msg, charsmax(g_msg), "Ingresa un E-mail para proteger tu nueva cuenta.");
		send_message(id);
		client_cmd(id, "messagemode Nuevo_email");
	}
	else
	{
		formatex(g_data, charsmax(g_data), "Datos Ingresados:^n^nCuenta:\r %s^n\yPassword:\r %s^n^n\yRegistrar Cuenta?",
		g_nombre[id][0], g_buffer[id]);
		g_msg = "NO_EMAIL";
		confirmar(id);
	}
}

public creando_email(id)
{
	if (player_logueado(id)) return;
	
	g_msg[0] = g_data[0] = EOS;
	read_args(g_msg, 64);
	
	#if defined _regex_included
	static junk;
	if (check_input(g_msg, g_msg) <= 6 || !regex_match_c(g_msg, g_regexid, junk))
	#else
	if (check_input(g_msg, g_msg) <= 6 || contain(g_msg, "@") == -1)
	#endif
	{
		g_msg[0] = EOS;
		formatex(g_msg, charsmax(g_msg), "Direccion de E-Mail no valida.^nVuelve a intentarlo.");
		send_message(id);
		
		client_cmd(id, "messagemode Nuevo_email");
	}
	else
	{
		formatex(g_data, charsmax(g_data), "Datos Ingresados:^n^nCuenta:\r %s^n\yPassword:\r %s^n\yE-Mail:\r %s^n^n\yRegistrar Cuenta?", g_nombre[id][0], g_buffer[id], g_msg);
		
		confirmar(id);
	}
}

confirmar(id)
{
	new menu = menu_create(g_data, "registrar");
	
	menu_additem(menu, "\ySi,\w registrar cuenta", g_msg);
	menu_additem(menu, "\rNo,\w cancelar operacion");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu);
}

public registrar(id, menu, item)
{
	if (item)
	{
		menu_registro(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	g_data[0] = g_msg[0] = EOS;
	
	menu_item_getinfo(menu, 0, item, g_msg, charsmax(g_msg), .callback = item);
	
	g_userid[id] = ++g_lastuserid;
	
	md5(g_buffer[id], g_buffer[id]);
	
	formatex(g_data, charsmax(g_data), "%s %s %d", g_buffer[id], g_msg , g_userid[id]);
	fvault_set_data(g_db_ac, g_nombre[id][0], g_data);
	
	TrieSetCell(g_cuentas_creadas, g_nombre[id][0], 1);
	
	formatex(g_msg, charsmax(g_msg), "Cuenta creada con exito.");
	send_message(id);
	
	CargarCuenta(id);
	menu_personajes(id);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public logueando_cuenta(id)
{
	if (player_logueado(id)) return;
	
	g_nombre[id][0][0] = EOS;
	read_args(g_nombre[id][0], charsmax(g_nombre[][]));
	// Aqui si se puede usar remove_quotes, como al registrar hay un maximo de caracteres
	// No se puede exceder al loguear (cuenta no existe?)
	remove_quotes(g_nombre[id][0]); trim(g_nombre[id][0]);
	
	if (TrieKeyExists(g_cuentas_creadas, g_nombre[id][0]))
	{
		fvault_get_data(g_db_ac, g_nombre[id][0], g_data, charsmax(g_data));
		static userid[10];
		parse(g_data, g_buffer[id], charsmax(g_buffer[]), "", 0, userid, charsmax(userid));
		g_userid[id] = str_to_num(userid);
		
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			if (!player_logueado(i))
				continue;
			
			if (g_userid[i] == g_userid[id])
			{
				formatex(g_msg, charsmax(g_msg), "La cuenta ingresada esta en uso.");
				send_message(id);
				
				ResetearVariables(id);
				menu_registro(id);
				
				return;
			}
		}
		
		client_cmd(id, "messagemode ^"Loguear_password^"");
		
		formatex(g_msg, charsmax(g_msg), "Escribe tu contraseña.");
		send_message(id);
	}
	else
	{
		formatex(g_msg, charsmax(g_msg), "La cuenta ingresada no existe.");
		send_message(id);
		
		ResetearVariables(id);
		menu_registro(id);
	}
}

public logueando_password(id)
{
	if (player_logueado(id)) return;
	
	g_buffer[0][0] = EOS;
	read_args(g_buffer[0], charsmax(g_buffer[]));
	remove_quotes(g_buffer[0]); trim(g_buffer[0]);
	md5(g_buffer[0], g_buffer[0]);
	
	if (equal(g_buffer[id], g_buffer[0]))
	{
		CargarCuenta(id);
		menu_personajes(id);
	}
	else
	{
		formatex(g_msg, charsmax(g_msg), "Contraseña incorrecta.");
		send_message(id);
		
		ResetearVariables(id);
		menu_registro(id);
	}
	
	g_buffer[0][0] = EOS;
}

menu_personajes(id, pag = 0)
{
	formatex(g_msg, charsmax(g_msg), "%s^nCuentas creadas:\r %d^n^n\yCuenta: \r%s", PLUGIN, g_lastuserid, g_nombre[id][0]);
	
	#if CANTIDAD_PERSONAJES > 7
	add(g_msg, charsmax(g_msg), "^n\yPagina:\r", 12);
	#endif
	
	new menu = menu_create(g_msg, "handler_personaje");
	
	for (new i = 1; i <= CANTIDAD_PERSONAJES; i++)
	{
		if (g_nombre[id][i][0])
			formatex(g_msg, charsmax(g_msg), "%s%s", personaje(id) == i ? "\yRegresar al Juego \r[En Uso]\d " : "", g_nombre[id][i]);
		else
			formatex(g_msg, charsmax(g_msg), "Crear Personaje \y[Slot %d Disponible]", i);
		
		menu_additem(menu, g_msg);
	}
	
	#if CANTIDAD_PERSONAJES > 7
	menu_setprop(menu, MPROP_BACKNAME, "Anterior");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente^n");
	#else
	menu_setprop(menu, MPROP_PERPAGE, CANTIDAD_PERSONAJES);
	#endif
	
	menu_setprop(menu, MPROP_EXITNAME, "Desloguear \yCuenta");
	menu_display(id, menu, pag);
}

public handler_personaje(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		if (is_user_connected(id))
		{
			if (personaje(id))
			{
				if (is_user_alive(id))
					dllfunc(DLLFunc_ClientKill, id);
				
				GuardarDatos(id);
				cs_set_user_team(id, CS_TEAM_UNASSIGNED);
			}
			
			formatex(g_msg, charsmax(g_msg), "Te has deslogueado.");
			send_message(id);
			
			menu_registro(id);
		}
		
		ResetearVariables(id);
		
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if (++item == personaje(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if (1 <= item <= CANTIDAD_PERSONAJES)
	{
		if (g_nombre[id][item][0])
		{
			set_user_info(id, "name", g_nombre[id][item]);
			g_data[0] = EOS;
			personaje(id) = item;
			CargarDatos(id);
			
			set_pdata_int(id, 125, (get_pdata_int(id, 125) & ~(1 << 8)));
			client_cmd(id, "jointeam%s", get_pcvar_num(cvar_jointeam) ? "" : " 5");
			
			formatex(g_msg, charsmax(g_msg), "Bienvenido, %s.^nDisfruta tu estadia.", g_nombre[id][item]);
			send_message(id);
			
			if (get_pcvar_num(cvar_saylog))
			{
				formatex(g_msg, charsmax(g_msg), "^x04[AMXX]^x01 Ha entrado^x04 %s", g_nombre[id][item]);
				connect_message(id);
			}
		}
		else
		{
			if (personaje(id))
			{
				if (is_user_alive(id))
					dllfunc(DLLFunc_ClientKill, id);
				
				GuardarDatos(id);
				cs_set_user_team(id, CS_TEAM_UNASSIGNED);
				
				personaje(id) = 0;
			}
			
			player_buffer(id) = item;
			get_user_info(id, "name", g_buffer[id], charsmax(g_buffer[]));
			formatex(g_msg, charsmax(g_msg), "\y%s^n\yCrear Personaje en Slot %d ?^nNombre: \r%s", PLUGIN, item, g_buffer[id]);
			new pmenu = menu_create(g_msg, "creando_personaje");
			
			menu_additem(pmenu, "\ySi,\w crear personaje");
			menu_additem(pmenu, "\rNo,\w usare otro nombre");
			menu_setprop(pmenu, MPROP_EXIT, MEXIT_NEVER);
			menu_display(id, pmenu);
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public creando_personaje(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if (item)
	{
		formatex(g_msg, charsmax(g_msg), "Vuelve a 'Crear personaje' luego de elegir otro nombre.");
		send_message(id);
	}
	else if (TrieKeyExists(g_personajes_creados, g_buffer[id]))
	{
		formatex(g_msg, charsmax(g_msg), "El nombre ya ha sido usado.^nElige otro nombre.");
		send_message(id);
	}
	else if (contain(g_buffer[id], "[No Reg]") != -1)
	{
		formatex(g_msg, charsmax(g_msg), "El nombre del personaje no puede llevar [No Reg]");
		send_message(id);
	}
	else
	{
		copy(g_nombre[id][player_buffer(id)], charsmax(g_nombre[][]), g_buffer[id]);
		
		for (new i = 1, b = 0; i <= CANTIDAD_PERSONAJES; i++)
			b += formatex(g_data[b], charsmax(g_data)-b, "%s^"%s^"", i == 1 ? "" : " ", g_nombre[id][i]);
		
		formatex(g_buffer[id], charsmax(g_buffer[]), "%d", g_userid[id]);
		fvault_set_data(g_db_pj, g_buffer[id], g_data);
		
		TrieSetCell(g_personajes_creados, g_nombre[id][player_buffer(id)], 1);
		
		formatex(g_msg, charsmax(g_msg), "Personaje creado con exito.");
		send_message(id);
	}
	
	menu_personajes(id, (player_buffer(id)-1)/7);
	player_buffer(id) = 0;
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

CargarCuenta(id)
{
	new i;
	
	g_bLogueado |= (1 << id-1);
	g_bInvitado &= ~(1 << id-1);
	g_data[0] = g_buffer[id][0] = EOS;
	personaje(id) = 0;
	formatex(g_buffer[id], charsmax(g_buffer[]), "%d", g_userid[id]);
	
	if (fvault_get_data(g_db_pj, g_buffer[id], g_data, charsmax(g_data)))
	{
		// No puedo usar parse() porque la cantidad de personajes es dinamica
		// Este bucle es un reemplazo de parse
		new bool:temp = false, start = 0, b = 0, c = strlen(g_data);
		
		for (i = 0; i < c; i++)
		{
			if (g_data[i] != '"')
				continue;
			
			if (!temp)
			{
				start = i+1;
				temp = true;
				continue;
			}
			
			temp = false; b++;
			
			if (g_data[i-1] != '"')
			{
				g_data[i] = EOS;
				copy(g_nombre[id][b], charsmax(g_nombre[][]), g_data[start]);
			}
			else
				g_nombre[id][b][0] = EOS;
		}
		
		return;
	}
	
	for (i = 1; i <= CANTIDAD_PERSONAJES; i++)
		g_nombre[id][i][0] = EOS;
}

ResetearVariables(id)
{
	g_userid[id] = 0;
	g_buffer[id][0] = EOS;
	personaje(id) = 0;
	
	g_bInvitado &= ~(1 << id-1);
	g_bLogueado &= ~(1 << id-1);
	
	for (new i = 0; i < sizeof(g_nombre[]); i++)
		g_nombre[id][i][0] = EOS;
}

send_message(id)
{
	set_hudmessage(0, 255, 0, -1.0, 0.25, 0, 3.0, 3.0);
	show_hudmessage(id, g_msg);
	
	// Para ZP: Los HUDs suelen estar ocupados
	replace_all(g_msg, strlen(g_msg), "^n", " ");
	client_print(id, print_center, g_msg);
	g_msg[0] = EOS;
}

connect_message(id)
{
	message_begin(MSG_ALL, g_msgSayText, _, 0);
	write_byte(id);
	write_string(g_msg);
	message_end();
	
	client_cmd(0, "spk ^"%s^"", SONIDO_ENTRAR);
	g_msg[0] = EOS;
}

cargar_todos_los_datos()
{
	new vault, vault_size;
	new buffer[128], _data[(1+CANTIDAD_PERSONAJES)*35];
	
	_FormatVaultName(g_db_ac, buffer, sizeof(buffer) - 1);
	
	if (file_exists(buffer))
	{
		vault_size = file_size(buffer, 1) - 2;
		vault = fopen(buffer, "rt");
		
		for (new line = 0; !feof(vault); line++)
		{
			fgets(vault, _data, sizeof(_data) - 1);
			parse(_data, buffer, sizeof(buffer) - 1);
			
			TrieSetCell(g_cuentas_creadas, buffer, 1);
			
			if (line == vault_size)
			{
				line = strlen(buffer) + 4; // + 2 = quotes on key, + 1 = space, + 1 = first quote
				copy(g_data, sizeof(g_data)-1, _data[line]);
				parse(g_data, "", 0, "", 0, g_buffer[0], charsmax(g_buffer[]));
				g_lastuserid = str_to_num(g_buffer[0]);
				break;
			}
		}
		
		fclose(vault);
	}
	
	buffer[0] = EOS;
	_FormatVaultName(g_db_pj, buffer, sizeof(buffer) - 1);
	
	if (file_exists(buffer))
	{
		new i, b, start, bool:temp;
		vault = fopen(buffer, "rt");
		
		while (!feof(vault))
		{
			fgets(vault, _data, sizeof(_data) - 1);
			if (!_data[0])
				continue;
			
			parse(_data, buffer, sizeof(buffer) - 1);
			for (b = strlen(_data), i = strlen(buffer)+4, temp = false; i < b; i++)
			{
				if (_data[i] != '"')
					continue;
				
				if (!temp)
				{
					start = i+1;
					temp = true;
					continue;
				}
				
				temp = false;
				
				if (_data[i-1] != '"')
				{
					_data[i] = EOS;
					TrieSetCell(g_personajes_creados, _data[start], 1);
				}
			}
		}
		
		fclose(vault);
	}
}

// Fix del remove_quotes
// Retorna 0 si str contiene comillas (sin contar las de los extremos)
stock check_input(const str[], out[])
{
	if (!str[1])
	{
		out[0] = EOS;
		return 0;
	}
	
	copy(out, strlen(str)-2, str[1]);
	trim(out);
	
	static len; len = strlen(out);
	
	for (new i = 0; i < len; i++)
	{
		if (out[i] == '"')
			return 0;
	}
	
	return len;
}
