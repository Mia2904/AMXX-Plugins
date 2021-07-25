#include < amxmodx >
#include < hamsandwich >
#include < engine >

new Float:g_Origen[ 33 ][ 3 ];

public plugin_init( )
{
    register_plugin( "Checkpoint", "0.1",  "Mia2904" ); 
    register_clcmd( "say /checkpoint",    "Cmd_CrearCheckPoint" );
    register_clcmd( "say /s",    "Cmd_CrearCheckPoint" );
    register_clcmd( "say /gocheck",    "Cmd_CheckPoint" );
    register_clcmd( "say /p",    "Cmd_CheckPoint" );
}

public Cmd_CrearCheckPoint( id )
{
    entity_get_vector( id, EV_VEC_origin, g_Origen[ id ] );
    client_print( id, print_center, "Checkpoint creado." );

    return PLUGIN_HANDLED;
}

public Cmd_CheckPoint( id )
{
    ExecuteHamB( Ham_CS_RoundRespawn, id );
    entity_set_origin( id, g_Origen[ id ] );

    return PLUGIN_HANDLED;
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
