#include <amxmodx>

#pragma semicolon 1

new const SONIDO[] = "buttons/bell1.wav";

public plugin_precache()
{
    register_plugin("Mensaje al conectar", "0.1", "Mia2904");
    precache_sound(SONIDO);
}

public client_putinserver(id)
{
    static szMsg[66], len, msgSayText;
    
    if (!len)
    {
        msgSayText = get_user_msgid("SayText");
        len = copy(szMsg, charsmax(szMsg), "^x04[MultiMods]^x01 Ha entrado^x04 ");
    }
    
    get_user_name(id, szMsg[len], 31);
    add(szMsg, charsmax(szMsg), "^x01. Bienvenido!");
    
    message_begin(MSG_BROADCAST, msgSayText);
    write_byte(33);
    write_string(szMsg);
    message_end();
    
    client_cmd(0, "spk ^"%s^"", SONIDO);
} 