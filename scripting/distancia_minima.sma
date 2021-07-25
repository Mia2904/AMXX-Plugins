#include <amxmodx>
#include <engine>

new g_pCvarTime, g_pCvarHp, g_pCvarDist;
new g_iTime, g_iHp, Float:g_fDist;
new g_iMsgIdSayText

new const mensaje1[] = "^x04[CORONAVIRUS]^x01 Recuerda mantenerte a^x04 %.1fm^x01 de distancia de los demas.";
new const mensaje2[] = "^x04[CORONAVIRUS]^x01 Estas muy cerca de^x03 %s^x01. Alejate a^x04 %.1fm!";

new g_szText[190];
const TASKID = 1821;

public plugin_init()
{
	register_plugin("Distancia minima", "0.1", "Mia2904");
	
	// Distancia minima en metros para slapear
	g_pCvarDist = register_cvar("covid_distancia_minima", "1.0");
	
	// Intervalo entre slap (segundos)
	g_pCvarTime = register_cvar("covid_distancia_tiempo", "10");
	
	// Cuanda vida bajar con el slap
	g_pCvarHp = register_cvar("covid_distancia_dano", "10");
	
	register_logevent("logevent_round_start", 2, "1=Round_Start");
	
	g_iMsgIdSayText = get_user_msgid("SayText");
}

public logevent_round_start() {
	g_iTime = get_pcvar_num(g_pCvarTime);
	g_fDist = get_pcvar_float(g_pCvarDist);
	g_iHp = get_pcvar_num(g_pCvarHp);
	
	set_task(3.0, "display_message");
	
	if (g_iTime > 0) {
		if (task_exists(TASKID)) {
			change_task(TASKID, float(g_iTime));
			} else {
			set_task(float(g_iTime), "check_dist", TASKID, .flags="b");
		}
		} else {
		remove_task(TASKID);
	}
}

public display_message() {
	formatex(g_szText, charsmax(g_szText), mensaje1, g_fDist);
	broadcast_text();
}

public check_dist(taskid) {
	static iPlayers[32], iNum, iId, iEnts[5], iEntsNum, szName[32], Float:fDist, iFoundId;
	get_players(iPlayers, iNum, "a", "CT");
	
	if (iNum == 0) {
		return;
	}
	
	fDist = floatmul(g_fDist, 80.0);
	new i, j;
	for (i = 0; i < iNum; i++) {
		iId = iPlayers[i];
		if (!is_player_ducking(iId)) {
			continue;
		}
		
		iEntsNum = find_sphere_class(iId, "player", fDist, iEnts, sizeof(iEnts));
		if (!iEntsNum) {
			continue;
		}
		
		for (j = 0; j < iEntsNum; j++) {
			iFoundId = iEnts[j];
			
			if (iFoundId == iId || !is_user_alive(iFoundId) || !is_player_ducking(iFoundId)) {
				continue;
			}
			
			get_user_name(iFoundId, szName, charsmax(szName));
			formatex(g_szText, charsmax(g_szText), mensaje2, szName, g_fDist);
			oneplayer_text(iId);
			user_slap(iId, g_iHp);
			break;
		}
	}
}

is_player_ducking(id) {
	return (entity_get_int(id, EV_INT_flags) & FL_DUCKING);
}

broadcast_text() {
	message_begin(MSG_BROADCAST, g_iMsgIdSayText);
	write_byte(33);
	write_string(g_szText);
	message_end();
}

oneplayer_text(id) {
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgIdSayText, .player = id);
	write_byte(33);
	write_string(g_szText);
	message_end();
}
