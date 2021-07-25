#include <amxmodx>

#define PLUGIN "Rock the vote"
#define VERSION "0.1"
#define AUTHOR "Mia2904"

#pragma semicolon 1

new rtvcount, nextmapcounter;
new bool:player_rtv[33], bool:canvote;
new pcvar_delay;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say rtv", "RockTheVote");
	register_clcmd("say_team rtv", "RockTheVote");
	register_concmd("nortv", "CancelChange", ADMIN_MAP);
	register_concmd("say nortv", "CancelChange", ADMIN_MAP);
	register_concmd("say_team nortv", "CancelChange", ADMIN_MAP);
	pcvar_delay = register_cvar("rtv_delay", "3");
	new Float:delaytaskfloat = get_pcvar_num(pcvar_delay) * 60.0;
	set_task(delaytaskfloat, "TaskDelay", 35);
	canvote = false;
	rtvcount = 0;
}

public TaskDelay()
{
	canvote = true;
	ChatColor(0, "^x04[RTV]^x01 Escribe^x04 rtv^x01 en el chat para votar por un cambio de mapa.");
}

public client_putinserver(id) player_rtv[id] = false;

public client_disconnect(id)
{
	if(player_rtv[id]) rtvcount--;
	player_rtv[id] = false;
	if(CheckVotes(1) == 500) VoteForMap();
}

public CancelChange(id)
{
	if(get_user_flags(id) & ADMIN_MAP)
	{
		if(task_exists())
		{
			remove_task();
			new adminname[65];
			get_user_name(id, adminname, 64);
			ChatColor(0, "^x04[RTV]^x01 El admin^x04 %s^x01 ha cancelado el cambio de mapa.", adminname);
			rtvcount = 0;
			canvote = true;
			for(new i = 1; i <= get_maxplayers(); i++)
				player_rtv[id] = false;
		}
		else ChatColor(0, "^x04[RTV]^x01 No hay un cambio de mapa para cancelar.");
	}
}

public RockTheVote(id)
{
	if(!canvote)
	{
		ChatColor(id, "^x04[RTV]^x01 No puedes votar ahora.");
		return;
	}
	else if(player_rtv[id]) 
	{
		if(CheckVotes() == 500) VoteForMap();
		else ChatColor(id, "^x04[RTV]^x01 Ya has votado para cambiar el mapa.");
		return;
	}
	
	player_rtv[id] = true;
	rtvcount++;
	new checkvotesnum = CheckVotes();
	if(checkvotesnum == 500) VoteForMap();
	else 
	{
		ChatColor(id, "^x04[RTV]^x01 Has votado para cambiar el mapa.");
		ChatColor(0, "^x04[RTV]^x01 Hay %d voto%s para cambiar el mapa, se requiere%s %d mas para elegir otro mapa.", rtvcount, rtvcount != 1 ? "s" : "", checkvotesnum != 1 ? "n" : "", checkvotesnum);
	}
}

CheckVotes(disconnect = 0)
{
	new Float:floatrtvneeded;
	if(!disconnect) floatrtvneeded = get_playersnum() / 2.0;
	else floatrtvneeded = (get_playersnum() - 1) / 2.0;
	new rtvneeded = floatround(floatrtvneeded, floatround_floor);
	if(rtvcount > rtvneeded) return 500;
	new rtvleft = rtvneeded - rtvcount + 1;
	return rtvleft;
}

public VoteForMap()
{
	if(find_plugin_byfile("mapchooser.amxx") == INVALID_PLUGIN_ID || !canvote)
		return;
	
	new oldWinLimit = get_cvar_num("mp_winlimit"), oldMaxRounds = get_cvar_num("mp_maxrounds");
	set_cvar_num("mp_winlimit",0);
	set_cvar_num("mp_maxrounds",-1);
	ChatColor(0, "^x04[RTV]^x01 Se alcanzaron los votos necesarios para cambiar el mapa. Inicia la votacion.");
	set_task(20.0, "ChangeMapCounter");
	nextmapcounter = 10;
	canvote = false;

	if(callfunc_begin("voteNextmap","mapchooser.amxx") == 1)
		callfunc_end();
		
	set_cvar_num("mp_winlimit",oldWinLimit);
	set_cvar_num("mp_maxrounds",oldMaxRounds);
}

public ChangeMapCounter()
{
	switch(nextmapcounter)
	{
		case 10:
		{
			new NextMap[31];
			get_cvar_string("amx_nextmap", NextMap, 30);
			ChatColor(0, "^x04[RTV]^x01 Cambiando a^x04 %s^x01 en 10 segundos.", NextMap);
			client_cmd(0, "spk vox/ten.wav");
		}
		case 9: client_cmd(0, "spk vox/nine.wav");
		case 8: client_cmd(0, "spk vox/eight.wav");
		case 7: client_cmd(0, "spk vox/seven.wav");
		case 6: client_cmd(0, "spk vox/six.wav");
		case 5: client_cmd(0, "spk vox/five.wav");
		case 4: client_cmd(0, "spk vox/four.wav");
		case 3: client_cmd(0, "spk vox/three.wav");
		case 2: client_cmd(0, "spk vox/two.wav");
		case 1: client_cmd(0, "spk vox/one.wav");
		case 0: ChangeMap();
	}
	nextmapcounter--;
	set_task(1.0, "ChangeMapCounter");
}

public ChangeMap()
{
	new NextMap[31];
	get_cvar_string("amx_nextmap", NextMap, 30);
	server_cmd("changelevel %s", NextMap);
}

stock ChatColor( id, szInput[ ], any:... )
{
    static iMsgId[ 191 ];
    vformat( iMsgId, charsmax( iMsgId ), szInput, 3 );
    
    new iCount = 1, iPlayers[ 32 ];
    
    if( id )
        iPlayers[ 0 ] = id;
    else
        get_players( iPlayers, iCount, "ch" );
    
    for( new i = 0; i < iCount; i++ )
    {
        if( is_user_connected( iPlayers[ i ] ) )
        {
            message_begin( MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, iPlayers[ i ] );
            write_byte( iPlayers[ i ] );
            write_string( iMsgId );
            message_end( );
        }
    }
}
