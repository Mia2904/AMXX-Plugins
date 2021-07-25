#include <amxmodx>

#define PLUGIN "Exec CFG"
#define VERSION "0.2"

#define DEFAULT_CFG "addons/amxmodx/configs/mm_cfg.cfg"

new szLine[128];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	register_concmd("exec_cfg", "exec_commands");
}

public plugin_cfg()
{
	set_task(2.0, "exec_commands", 33);
}

public exec_commands(id)
{
	if (id == 33 || read_argc() != 2)
	{
		copy(szLine, charsmax(szLine), DEFAULT_CFG);
	}
	else
	{
		read_argv(1, szLine, charsmax(szLine));
	}
	
	if (id == 33)
	{
		id = 0;
	}
	
	if (!file_exists(szLine))
	{
		console_print(id, "Archivo de configuracion %s no existe!", szLine);
		return;
	}
	
	console_print(id, "Ejecutando %s", szLine);
	
	new file = fopen(szLine, "rt");
	
	while (!feof(file))
	{
		fgets(file, szLine, charsmax(szLine));
		
		switch (szLine[0])
		{
			case 0, '^n', '/', ';':
			{
				continue;
			}
			default:
			{
				trim(szLine);
				server_cmd(szLine);
				
				//console_print(id, "Ejecutar linea: %s", szLine);
			}
		}
	}
	
	server_exec();
	
	fclose(file);
}
	
