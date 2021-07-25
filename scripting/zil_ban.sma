#include <amxmodx>
#include <amxmisc>
//#include <unixtime>

#define PLUGIN "ZIL Ban"
#define VERSION "0.1"

#pragma semicolon 1

new Trie:g_anames;
new szName[32], unixtime[32], szBuffer[90], g_unixtime;

public plugin_natives()
{
    g_anames = TrieCreate();
    
    get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
    
    add(szBuffer, charsmax(szBuffer), "%s/ZilBanned.ini");
    
    load_bans();
    
    register_native("zil_player_banned", "native_is_banned", 0);
    //register_native("zil_ban_player", "native_ban_player", 0);
    //register_native("zil_unban_player", "native_unban_player", 0);
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "Mia2904");
    //register_concmd("namelist_reload", "concmd_reload", ADMIN_IMMUNITY);
    
    register_concmd("zil_ban", "clcmd_ban", ADMIN_IMMUNITY);
}

public clcmd_ban(id)
{
    if (id && ~get_user_flags(id) & ADMIN_IMMUNITY)
	return 0;

    new minutes = read_argc();
    
    if (minutes < 3)
    {
    	console_print(id, "Uso: zil_ban <nombre> <minutos> <motivo>");
	return 0;
    }

    read_argv(1, szName, 31);
    read_argv(2, unixtime, 31);
    
    if (minutes >= 4)
	read_argv(3, szBuffer, 40);
    else
        szBuffer = "";
    
    minutes = str_to_num(unixtime);
    
    new player = cmd_target(id, szName, CMDTARGET_ALLOW_SELF);
    
    if (!player)
	return 0;

    get_user_name(player, szName, 31);
    
    server_cmd("kick #%d ^"Su cuenta %s ha sido baneada por %d minutos. (Motivo: %s)^"", get_user_userid(player), szName, minutes, szBuffer);
    minutes *= 60;
    minutes += get_systime();
    
    get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
    
    add(szBuffer, charsmax(szBuffer), "/ZilBannedNew.ini");
    
    new File = fopen(szBuffer, "rt+");
    fseek(File, 0, SEEK_END);
    fprintf(File, "^"%s^" %d^n", szName, minutes);
    fclose(File);
    
    TrieSetCell(g_anames, szName, minutes);
    
    return 1;
}

/*public native_unban_player()
{
    get_string(1, szName, 31);
    new minutes = get_param(2)*60;
    
    new File = fopen(szBuffer, "rt+");
    fseek(File, 0, SEEK_END);
    fprintf(File, "^"%s^" %s^n", szName, get_systime() + minutes);
    fclose(File);
    
    return 1;
}*/

public native_is_banned(plugin, params)
{
    get_string(1, szName, 31);
    
    if (TrieKeyExists(g_anames, szName))
    {
    	TrieGetCell(g_anames, szName, g_unixtime);
	g_unixtime -= get_systime();
	if (g_unixtime > 0)
		return g_unixtime;
    }
    
    return 0;
}

load_bans()
{
    if (!file_exists(szBuffer))
    {
        fclose(fopen(szBuffer, "wt"));
    }
    else
    {
        new File = fopen(szBuffer, "rt");
        get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
    
        format(szBuffer, charsmax(szBuffer), "%s/ZilBannedNew.ini", szBuffer);
	
        new newFile = fopen(szBuffer, "wt");
        
        while (!feof(File))
        {
            fgets(File, szBuffer, charsmax(szBuffer));
            
            if (!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '^n')
                continue;
            
            trim(szBuffer);
            parse(szBuffer, szName, 31, unixtime, 31);
            g_unixtime = str_to_num(unixtime);
            
            if (g_unixtime > get_systime())
            {
                TrieSetCell(g_anames, szName, g_unixtime);
                fprintf(newFile, "^"%s^" %d^n", szName, g_unixtime);
            }
        }
        
        fclose(File);
        fclose(newFile);
    }
}

public plugin_end()
{
    TrieDestroy(g_anames);
    
    get_localinfo("amxx_configsdir", szBuffer, charsmax(szBuffer));
    
    new backup[90];
    formatex(backup, charsmax(backup), "%s/ZilBannedNew.ini", szBuffer);
    format(szBuffer, charsmax(szBuffer), "%s/ZilBanned.ini", szBuffer);
    
    delete_file(szBuffer);
    CopyFile(backup, szBuffer);
    delete_file(backup);
} 

stock CopyFile(const szOldFile[], const szNewFile[])
{
    new iFile    = fopen(szOldFile, "rb"),
        iNewFile = fopen(szNewFile, "wb"),
        iFileSize,
        iReadSize,
        szBuffer[1024];
        
    if (iFile && iNewFile)
    {
        fseek(iFile, 0, SEEK_END);
        iFileSize = ftell(iFile);
        fseek(iFile, 0, SEEK_SET);
        
        for (new iIndex = 0; iIndex < iFileSize; iIndex += 256)
        {
            iReadSize = fread_blocks(iFile, szBuffer, 256, BLOCK_CHAR);
            fwrite_blocks(iNewFile, szBuffer, iReadSize, BLOCK_CHAR);
        }
        
    }
    
    fclose(iFile);
    fclose(iNewFile);
} 
