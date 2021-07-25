#include <amxmodx>
#include <sqlx>

/*
	SI USAS MYSQL NO TOQUES ESTO.
	SI USAS SQLITE BORRA LA SIGUIENTE LINEA
	
	IF YOU'RE USING MYSQL, DO NOT TOUCH THIS
	IF USING SQLITE, DELETE THE NEXT LINE	*/

// DELETE IF USING SQLITE
#define USE_MYSQL

new const _vault_dir[] = "addons/amxmodx/data/file_vault";

// FVault saves
new const g_VaultCreated[] = "za_created" // save accounts and character counts
new const g_VaultAccounts[] = "za_accounts" // save accounts
new const g_VaultCharacters[] = "za_characters" // save characters
new const g_VaultExp[] = "za_experience" // save experience
new const g_VaultClasses[] = "za_classes" // save class
new const g_VaultKills[] = "za_kills" // save kills
new const g_VaultDamage[] = "za_damage" // save damage
new const g_VaultSkills[] = "za_skills" // save skills
new const g_VaultQuests[] = "za_quests" // save quests
new const g_VaultTime[] = "za_time" // save time and rounds
new const g_VaultColors[] = "za_colors" // save colors


// CONFIGURAR ESTO IGUAL A LA CONFIG DE ZOMBIE APOCALYPSE (.ini)
// SET TIHS AS THE ZOMBIE APOCALYPSE CONFIG FILE (.ini)

#if defined USE_MYSQL
new const mysql_host[28] = "127.0.0.1"
new const mysql_user[25] = "root"
new const mysql_pass[25] = ""
#endif
new const mysql_database[25] = "zombie_apocalypse"

// SQL table's names
#define TABLE1 "account"
#define TABLE2 "experience"
#define TABLE3 "classes"
#define TABLE4 "statistics"
#define TABLE5 "skills"
#define TABLE6 "quest"
#define TABLE7 "time"
#define TABLE8 "colours"
#define TABLE9 "system"

// That's it...

#define PLUGIN "ZA Fvault a SQL"
#define VERSION "0.2"

new Handle:g_SqlTuple
new g_Error[100]

const TASKID = 1951

new g_confirm, g_size, addnum, charsnum, g_parts

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904")
	
	register_concmd("za_transfer", "concmd_transfer")
	register_concmd("CONTINUAR", "concmd_confirm")
}

public concmd_transfer(id)
{
	if (id == 0)
	{
		g_confirm = 0;
		console_print(0, "Preparando transferencia de cuentas ZA FVAULT a SQL")
		set_task(0.5, "load_message", TASKID, _, _, "b");
	}
}

public load_message()
{
	switch (g_confirm)
	{
		case 0:
		{
			#if defined USE_MYSQL
			g_SqlTuple = SQL_MakeDbTuple(mysql_host, mysql_user, mysql_pass, mysql_database)
		
			if (!g_SqlTuple)
			{
				// Log error
				log_to_file("SQL_ERROR.txt", "No se pudo conectar con la base de datos.")
				
				// Pause plugin
				pause("a");
				return;
			}
			
			console_print(0, "Sistema: MySQL")
			#else
			new get_type[12]
			
			SQL_SetAffinity("sqlite")
			
			SQL_GetAffinity(get_type, sizeof get_type)
		
			if (!equali(get_type, "sqlite"))
			{
				// Log error
				log_to_file( "SQLITE_ERROR.txt", "Conection error.")
				
				// Pause plugin
				pause( "a" );
				return;
			}
			
			console_print(0, "Sistema: SQLite")
			
			g_SqlTuple = SQL_MakeDbTuple( "", "", "", mysql_database)
			#endif
		}
		case 1:
		{
			console_print(0, "Este proceso puede demorar segundos, minutos, horas, dias.")
			console_print(0, "Dependiendo de factores como la cantidad de cuentas, la velocidad del ordenador, etc.")
			console_print(0, "El servidor se congelar� durante el proceso.")
		}
		case 2: console_print(0, "El proceso no debe de interrumpirse o sera necesario empezar de nuevo.")
		case 3:
		{
			g_size = fvault_size(g_VaultAccounts)
			g_parts = 1
			for (new i = g_size; i >= 30; g_parts++)
				i -= 30
			console_print(0, "El proceso se dividira en %d partes. 30 cuentas seran transferidas en cada una.", g_parts)
			console_print(0, "El tiempo estimado de cada parte es de entre 5 y 20 segundos.")
			console_print(0, "Cuentas totales: %d Tiempo estimado total: %.2f ~ %.2f minutos.", g_size, minutes(5*g_parts), minutes(20*g_parts))
		}
		case 4:
		{
			console_print(0, "Este plugin no tiene relacion con el autor de ZA.")
			console_print(0, "El autor de este plugin no se hace responsable del uso de este.")
			console_print(0, "Este plugin se ofrece TAL CUAL y sin ninguna garantia.")
		}
		case 5:
		{
			g_confirm = -2
			remove_task(TASKID)
			console_print(0, "Para continuar, ingrese el comando: CONTINUAR")
		}
	}
	
	g_confirm++
}

public concmd_confirm(id)
{
	if (g_confirm != -1 || id != 0)
		return;
	
	new g_fdata[100]
	new g_query[100]
	new data1[20], data2[20]
	
	new Handle:query
	new ErrorCode, Handle:SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, charsmax(g_Error))
	
	if (SqlConnection == Empty_Handle)
	{
		console_print(0, "Error de SQL (%d): %s", ErrorCode, g_Error)
		return
	}
	
	if (fvault_get_data(g_VaultCreated, "Accounts / Characters", g_fdata, charsmax(g_fdata)))
	{
		parse(g_fdata, data1, 19, data2, 19)
		
		formatex(g_query, charsmax(g_query), "UPDATE `%s` SET `Created accounts`='%d', `Created characters`='%d'", TABLE9, str_to_num(data1), str_to_num(data2))
		query = SQL_PrepareQuery(SqlConnection, g_query)
		SQL_Execute(query)
		
		SQL_FreeHandle(query)
	}
	
	SQL_FreeHandle(SqlConnection)
	
	addnum = charsnum = 0
	console_print(0, "Iniciando parte 1 de %d", g_parts)
	
	set_task(0.3, "transfer_all", 1);
}

public transfer_all(part)
{
	new size = 30*part
	
	if (size > g_size)
		size = g_size
	
	new len, idlen, i
	new g_charactername[5][32]
	new g_query[1000]
	new g_fkey[100]
	new g_fdata[999]
	new user_id[33]
	new szPass[35]
	new szRegDate[11]
	new szLoggin[11]
	new data1[20], data2[20], data3[20], data4[20], data5[20], data6[20], data7[20], data8[20], data9[20], data10[20],
	data11[20], data12[20], data13[20], data14[20]
	
	new Handle:query
	
	new ErrorCode, Handle:SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, charsmax(g_Error))
	
	if (SqlConnection == Empty_Handle)
	{
		console_print(0, "Error de SQL (%d): %s", ErrorCode, g_Error)
		return
	}
	
	while (addnum < size)
	{
		fvault_get_key_and_data(g_VaultAccounts, addnum, user_id, 32, g_fdata, 999)
		addnum++
		
		parse(g_fdata, szPass, charsmax(szPass), szRegDate, charsmax(szRegDate), szLoggin, charsmax(szLoggin))
		
		idlen = formatex(g_fkey, 99, "ID: %s", user_id)
		
		if (fvault_get_data(g_VaultCharacters, g_fkey, g_fdata, charsmax(g_fdata)))
		{
			parse(g_fdata, g_charactername[0], 31, g_charactername[1], 31, g_charactername[2], 31, g_charactername[3], 31, g_charactername[4], 31)
			
			len = formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Password`, `Register Date`, `Last Loggin`", TABLE1)
			len += formatex(g_query[len], charsmax(g_query)-len, ", `Character 1`, `Character 2`, `Character 3`, `Character 4`, `Character 5`) VALUES ")
			len += formatex(g_query[len], charsmax(g_query)-len, "(^"%s^", ^"%s^", '%s', '%s', ", user_id, szPass, szRegDate, szLoggin)
			len += formatex(g_query[len], charsmax(g_query)-len, "^"%s^", ^"%s^", ^"%s^", ^"%s^", ^"%s^")", g_charactername[0], g_charactername[1], g_charactername[2], g_charactername[3], g_charactername[4])
			query = SQL_PrepareQuery(SqlConnection, g_query)
			SQL_Execute(query)
			
			SQL_FreeHandle(query)
		}
		else continue;
		
		// Cuenta creada. Ahora los personajes....
		for (i = 0; i < 5; i++)
		{
			if (equal(g_charactername[i], "None"))
				continue;
			
			charsnum++
			
			formatex(g_fkey[idlen], charsmax(g_fkey)-idlen, " Character: %s", g_charactername[i])
			
			if (fvault_get_data(g_VaultExp, g_fkey, g_fdata, charsmax(g_fdata)))
			{
				parse(g_fdata, data1, 19, data2, 19, data3, 19, data4, 19, data5, 19, data6, 19, data7, 19,
				data8, 19, data9, 19, data10, 19)
				
				formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`, `Level`, `Experience`, `Ammopacks`, `Used Ammopacks`, `Range`, `Fame`, `Human Points`, `Zombie Points`, `Used Human Points`, `Used Zombie Points`) VALUES (^"%s^", ^"%s^", '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')",
				TABLE2, user_id, g_charactername[i], str_to_num(data1), str_to_num(data2), str_to_num(data3), str_to_num(data4), str_to_num(data5), str_to_num(data6), str_to_num(data7), str_to_num(data8), str_to_num(data9), str_to_num(data10))
				
			}
			else formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`) VALUES (^"%s^", ^"%s^")", TABLE2, user_id, g_charactername[i])
				
			query = SQL_PrepareQuery(SqlConnection, g_query)
			SQL_Execute(query)
			SQL_FreeHandle(query)
			
			if (fvault_get_data(g_VaultClasses, g_fkey, g_fdata, charsmax(g_fdata)))
			{
				parse(g_fdata, data1, 19, data2, 19, data3, 19, data4, 19)
				
				formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`, Human Class`, `Next Human Class`, `Zombie Class`, `Next Zombie Class` VALUES (^"%s^", ^"%s^", '%d', '%d', '%d', '%d')", 
				TABLE3, user_id, g_charactername[i], str_to_num(data1), str_to_num(data2), str_to_num(data3), str_to_num(data4))
			}
			else formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`) VALUES (^"%s^", ^"%s^")", TABLE3, user_id, g_charactername[i])
			
			query = SQL_PrepareQuery(SqlConnection, g_query)
			SQL_Execute(query)
			SQL_FreeHandle(query)
			
			if (fvault_get_data(g_VaultKills, g_fkey, g_fdata, charsmax(g_fdata)))
			{
				parse(g_fdata, data1, 19, data2, 19, data3, 19, data4, 19, data5, 19, data6, 19, data7, 19,
				data8, 19, data9, 19, data10, 19, data11, 19, data12, 19, data13, 19, data14, 19)
				
				len = formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`, `Infected Human`, `Received Infect`, `Human Killed`, `Zombie Killed`, `Survivor Killed`, `Wesker Killed`, `Nemesis Killed`, `Alien Killed`, `Human Dead`, `Zombie Dead`, `Survivor Dead`, `Wesker Dead`, `Nemesis Dead`, `Alien Dead`",
				TABLE4)
				len += formatex(g_query[len], charsmax(g_query)-len, ", `Human Damage`, `Zombie Damage`, `Survivor Damage`, `Wesker Damage`, `Nemesis Damage`, `Alien Damage`, `Human RDamage`, `Zombie RDamage`, `Survivor RDamage`, `Wesker RDamage`, `Nemesis RDamage`, `Alien RDamage`) ")
				
				len += formatex(g_query[len], charsmax(g_query)-len, "VALUES (^"%s^", ^"%s^", '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d'", user_id, g_charactername[i], str_to_num(data1), str_to_num(data2), str_to_num(data3), str_to_num(data4), str_to_num(data5), str_to_num(data6), str_to_num(data7), str_to_num(data8), str_to_num(data9), str_to_num(data10), str_to_num(data11), str_to_num(data12), str_to_num(data13), str_to_num(data14))
				
				if (fvault_get_data(g_VaultDamage, g_fkey, g_fdata, charsmax(g_fdata)))
				{
					parse(g_fdata, data1, 19, data2, 19, data3, 19, data4, 19, data5, 19, data6, 19, data7, 19,
					data8, 19, data9, 19, data10, 19, data11, 19, data12, 19)
					
					formatex(g_query[len], charsmax(g_query)-len, ", '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", 
					str_to_num(data1), str_to_num(data2), str_to_num(data3), str_to_num(data4), str_to_num(data5), str_to_num(data6), str_to_num(data7), str_to_num(data8), str_to_num(data9), str_to_num(data10), str_to_num(data11), str_to_num(data12))
				}
				else formatex(g_query[len], charsmax(g_query)-len, ", '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0')")
			}
			else formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`) VALUES (^"%s^", ^"%s^")", TABLE4, user_id, g_charactername[i])
			
			query = SQL_PrepareQuery(SqlConnection, g_query)
			SQL_Execute(query)
			SQL_FreeHandle(query)
			
			if (fvault_get_data(g_VaultSkills, g_fkey, g_fdata, charsmax(g_fdata)))
			{
				parse(g_fdata, data1, 19, data2, 19, data3, 19, data4, 19, data5, 19, data6, 19, data7, 19,
				data8, 19, data9, 19, data10, 19)
				
				formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`, `HAttack Skill`, `HHealth Skill`, `HSpeed Skill`, `HGravity Skill`, `HArmor Skill`, `ZAttack Skill`, `ZHealth Skill`, `ZSpeed Skill`, `ZGravity Skill`, `ZDefense Skill`) VALUES (^"%s^", ^"%s^", '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", 
				TABLE5, user_id, g_charactername[i], str_to_num(data1), str_to_num(data2), str_to_num(data3), str_to_num(data4), str_to_num(data5), str_to_num(data6), str_to_num(data7), str_to_num(data8), str_to_num(data9), str_to_num(data10))
			}
			else formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`) VALUES (^"%s^", ^"%s^")", TABLE5, user_id, g_charactername[i])
			
			query = SQL_PrepareQuery(SqlConnection, g_query)
			SQL_Execute(query)
			SQL_FreeHandle(query)
			
			if (fvault_get_data(g_VaultQuests, g_fkey, g_fdata, charsmax(g_fdata)))
			{
				parse(g_fdata, data1, 19, data2, 19, data3, 19, data4, 19, data5, 19, data6, 19, data7, 19,
				data8, 19, data9, 19)
				
				formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`, `Selected Quest`, `Completed Quest`, `Quest Rounds`, `Quest Killed Human`, `Quest Killed Zombie`, `Quest Killed Survivor`, `Quest Killed Wesker`, `Quest Killed Nemesis`, `Quest Killed Alien`) VALUES (^"%s^", ^"%s^", '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", 
				TABLE6, user_id, g_charactername[i], str_to_num(data1), str_to_num(data2), str_to_num(data3), str_to_num(data4), str_to_num(data5), str_to_num(data6), str_to_num(data7), str_to_num(data8), str_to_num(data9))
			}
			else formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`) VALUES (^"%s^", ^"%s^")", TABLE6, user_id, g_charactername[i])
			
			query = SQL_PrepareQuery(SqlConnection, g_query)
			SQL_Execute(query)
			SQL_FreeHandle(query)
			
			if (fvault_get_data(g_VaultTime, g_fkey, g_fdata, charsmax(g_fdata)))
			{
				parse(g_fdata, data1, 19, data2, 19, data3, 19, data4, 19)
				
				formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`, `Rounds Played`, `Hours Played`, `Minutes Played`, `Seconds Played`) VALUES (^"%s^", ^"%s^", '%d', '%d', '%d', '%d')", 
				TABLE7, user_id, g_charactername[i], str_to_num(data1), str_to_num(data2), str_to_num(data3), str_to_num(data4))
			}
			else formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`) VALUES (^"%s^", ^"%s^")", TABLE7, user_id, g_charactername[i])
			
			query = SQL_PrepareQuery(SqlConnection, g_query)
			SQL_Execute(query)
			SQL_FreeHandle(query)
			
			if (fvault_get_data(g_VaultColors, g_fkey, g_fdata, charsmax(g_fdata)))
			{
				parse(g_fdata, data1, 19, data2, 19, data3, 19, data4, 19, data5, 19, data6, 19, data7, 19,
				data8, 19, data9, 19, data10, 19, data11, 19, data12, 19)
				
				formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`, `Hud Stat T`, `Hud Stat X`, `Hud Stat Y`, `Hud RGB`, `NVG RGB`, `Flashlight RGB`) VALUES (^"%s^", ^"%s^", '%d', '%f', '%f', '%d %d %d', '%d %d %d', '%d %d %d')", 
				TABLE8, user_id, g_charactername[i], str_to_num(data1), str_to_float(data2), str_to_float(data3), str_to_num(data4), str_to_num(data5), str_to_num(data6), str_to_num(data7), str_to_num(data8), str_to_num(data9), str_to_num(data10), str_to_num(data11), str_to_num(data12))
			}
			else formatex(g_query, charsmax(g_query), "INSERT INTO `%s` (`User ID`, `Character`) VALUES (^"%s^", ^"%s^")", TABLE8, user_id, g_charactername[i])
			
			query = SQL_PrepareQuery(SqlConnection, g_query)
			SQL_Execute(query)
			SQL_FreeHandle(query)
		}
	}
	
	SQL_FreeHandle(SqlConnection)
	
	if (part < g_parts)
	{
		console_print(0, "Parte %d completada.", part)
		part++
		console_print(0, "Iniciando parte %d de %d", part, g_parts)
		set_task(0.3, "transfer_all", part)
	}
	else
		console_print(0, "Comando completado. Se han transferido %d cuentas con %d personajes.", addnum, charsnum)
}

//#define USAR_TIMESTAMP
/** 
 * Retrieves a key name and its data specified by its number
 * 
 * @param vaultname	Vault name to look in
 * @param keynum	Key number within the vault to find key name and data
 * @param key		String which key name will be copied to
 * @param len_key	Length of key name
 * @param data		String which data will be copied to
 * @param len_data	Length of data
 * @param timestamp	The unix time of when the data was last set ( -1 if permanent data, 0 if old fvault version ) ( optional param )
 * @return		Returns 1 on success, 0 on failue.
 */
fvault_get_key_and_data(const vaultname[], const keynum, key[], len_key, data[], len_data, &timestamp=0)
{
	new _data[580];
	_FormatVaultName(vaultname, _data, sizeof(_data) - 1);
	
	if( !file_exists(_data) )
	{
		return 0;
	}
	
	new vault = fopen(_data, "rt");
	
	new line = -1;
	
	while( !feof(vault) )
	{
		fgets(vault, _data, sizeof(_data) - 1);
		
		if( ++line == keynum )
		{
			parse(_data, key, len_key, data, len_data);
			
			#if defined USAR_TIMESTAMP
			new _time[32];
				
			for( new i = strlen(data) - 1; i > 0; i-- )
			{
				if( data[i] == '"' ) break;
				
				if( data[i] == ' '
				&& data[i - 1] == '"' )
				{
					data[i - 1] = '^0';
					
					copy(_time, sizeof(_time) - 1, data[i + 1]);
					timestamp = str_to_num(_time);
					break;
				}
			}
			#endif
			
			fclose(vault);
			
			return 1;
		}
	}
	
	fclose(vault);
	
	return 0;
}

stock Float:minutes(secs)
	return (secs / 60.0)

// FVault Stocks (by Exolent)

/** 
 * Retrieves data specified by a key
 * 
 * @param vaultname	Vault name to look in
 * @param key		Key name to look for the data
 * @param data		String which data will be copied to
 * @param len		Length of data
 * @param timestamp	The unix time of when the data was last set ( -1 if permanent data, 0 if old fvault version ) ( optional param )
 * @return		Returns 1 on success, 0 on failue.
 */
stock fvault_get_data(const vaultname[], const key[], data[], len, &timestamp=0)
{
	static filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	if( !file_exists(filename) )
	{
		return 0;
	}
	
	static vault; vault = fopen(filename, "rt");
	
	static _data[512], _key[64], _time[32];
	
	while( !feof(vault) )
	{
		fgets(vault, _data, sizeof(_data) - 1);
		parse(_data, _key, sizeof(_key) - 1);
		
		if( equal(_key, key) )
		{
			static _len; _len  = strlen(_key) + 4; // + 2 = quotes on key, + 1 = space, + 1 = first quote
			for( new i = copy(data, len, _data[_len]) - 1; i > 0; i-- )
			{
				if( data[i] == '"' ) break;
				
				if( data[i] == ' '
				&& data[i - 1] == '"' )
				{
					data[i - 1] = '^0';
					
					copy(_time, sizeof(_time) - 1, data[i + 1]);
					timestamp = str_to_num(_time);
					break;
				}
			}
			
			fclose(vault);
			
			return 1;
		}
	}
	
	fclose(vault);
	
	copy(data, len, "");
	
	return 0;
}

/** 
 * Retrieves total keys located within the vault
 * 
 * @param vaultname	Vault name to look in
 * @return		Returns amount of keys in vault
 */
stock fvault_size(const vaultname[])
{
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	return file_exists(filename) ? file_size(filename, 1) - 1 : 0;
}

stock const _temp_vault[] = "fvault_temp.txt";

stock _FormatVaultName(const vaultname[], filename[], len)
{
	static const invalid_chars[][] =
	{
		"/", "\", "*", ":", "?", "^"", "<", ">", "|"
	};
	
	static tempvault[128], i;
	copy(tempvault, sizeof(tempvault) - 1, vaultname);
	
	for( i = 0; i < sizeof(invalid_chars); i++ )
	{
		replace_all(tempvault, sizeof(tempvault) - 1, invalid_chars[i], "");
	}
	
	if( !dir_exists(_vault_dir) )
	{
		mkdir(_vault_dir);
	}
	
	formatex(filename, len, "%s/%s.txt", _vault_dir, tempvault);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
