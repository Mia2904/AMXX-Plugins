#include <amxmodx>
#include <engine>

#pragma semicolon 1
#define MAX_PLAYERS 32

/*================================================================================================

 Uncomment the next line if you want to use the API. Read the .inc file for instructions.
 Using the API will disable the following cvars:
 lottery_options, lottery_min_participants, lottery_cost, lottery_reward, lottery_fixed_reward.
 The API does not require the cstrike module.							*/


// #define EXTERNAL_MANAGEMENT

/*==============================================================================================*/

enum
{
	EVENT_TIME = 0,
	COUNTER,
	EVENT_ANNOUNCE,
	EVENT_RESULT
};

enum
{
	TIME_OVER = -2,
	AWAITING_RESULT,
	NOT_IN_PROGRESS
};

new g_bParticipate, g_bConfirmed, g_bDontAsk, g_bPaid;
#define player_set_bit(%0,%1) %0 |= (1<<%1-1)
#define player_clear_bit(%0,%1) %0 &= ~(1<<%1-1)
#define player_check_bit(%0,%1) %0 & (1<<%1-1)

new g_counter, g_participating, g_minparticipants, g_option[MAX_PLAYERS+1];
new cvar_time, cvar_duration, cvar_enable, cvar_minplayers;
new g_msgSayText;
#define g_options g_option[0]

const CONFIRMKEYS = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3;

#if defined EXTERNAL_MANAGEMENT
const MAXLEN = 100;
new forward_lotterystart, forward_check, forward_pay, forward_refund, forward_givereward;
new g_descriptions[2][MAXLEN];

public plugin_natives()
{
	register_native("lottery_set_description", "native_set_description", 0);
	register_native("lottery_set_options_num", "native_set_options_num", 1);
	register_native("lottery_set_min_participants", "native_set_min_participants", 1);
	register_native("lottery_is_in_progress", "native_is_in_progress", 1);
}

public native_set_description(plugin, params)
{
	new ld;
	
	if (!(0 <= (ld = get_param(1)) <= 1))
	{
		log_error(AMX_ERR_NATIVE, "Invalid lottery description (%d)", ld);
		return;
	}
	
	vdformat(g_descriptions[ld], charsmax(g_descriptions[]), 2, 3);
}

public native_set_options_num(const OptionsNum)
{
	g_options = OptionsNum;
}

public native_set_min_participants(const MinParticipants)
{
	g_minparticipants = MinParticipants;
}

public bool:native_is_in_progress()
{
	if (g_counter == NOT_IN_PROGRESS)
		return false;
	
	return true;
}
#else
#include <cstrike>
const MAXLEN = 25;
new cvar_cost, cvar_reward, cvar_fixedreward, cvar_maxoptions, cvar_minparticipants;
#endif

public plugin_init()
{
	new ent;
	do
	{
		ent = create_entity("info_target");
	}
	while (!is_valid_ent(ent));
	
	entity_set_string(ent, EV_SZ_classname, "RandomEvent");
	entity_set_float(ent, EV_FL_nextthink, 1.0);
    
	register_think("RandomEvent", "RandomEvent_Think");
	
	register_menucmd(register_menuid("EventMenu"), CONFIRMKEYS, "menu_event");
	register_clcmd("your_number", "clcmd_num");
	register_clcmd("say /lottery", "clcmd_saylottery");
	
	cvar_enable = register_cvar("lottery_enable", "1");
	cvar_time = register_cvar("lottery_interval", "300.0");
	cvar_duration = register_cvar("lottery_duration", "20.0");
	cvar_minplayers = register_cvar("lottery_min_players", "5");
	
	#if defined EXTERNAL_MANAGEMENT
	register_plugin("[API] AMXX Lottery", "0.5", "Mia2904");
	forward_lotterystart = CreateMultiForward("lottery_start", ET_STOP);
	forward_check = CreateMultiForward("lottery_check", ET_STOP, FP_CELL);
	forward_pay = CreateMultiForward("lottery_pay", ET_CONTINUE, FP_CELL);
	forward_refund = CreateMultiForward("lottery_refund", ET_CONTINUE, FP_CELL);
	forward_givereward = CreateMultiForward("lottery_give_reward", ET_CONTINUE, FP_CELL);
	#else
	register_plugin("AMXX Lottery", "0.5", "Mia2904");
	cvar_maxoptions = register_cvar("lottery_options", "0");
	cvar_minparticipants = register_cvar("lottery_min_participants", "3");
	cvar_cost = register_cvar("lottery_cost", "100");
	cvar_reward = register_cvar("lottery_reward", "500");
	cvar_fixedreward = register_cvar("lottery_fixed_reward", "0");
	#endif
	
	g_msgSayText = get_user_msgid("SayText");
	
	register_dictionary("amx_lottery.txt");
}

public client_disconnect(id)
{
	if (g_counter && player_check_bit(g_bParticipate, id))
		g_participating--;
	
	player_clear_bit(g_bParticipate, id);
	player_clear_bit(g_bDontAsk, id);
	player_clear_bit(g_bConfirmed, id);
}

public RandomEvent_Think(ent)
{
	static players[32], num, action;
	#if defined EXTERNAL_MANAGEMENT
	static ret;
	#endif
	
	if (!get_pcvar_num(cvar_enable))
	{
		g_counter = NOT_IN_PROGRESS;
		action = EVENT_TIME;
		entity_set_float(ent, EV_FL_nextthink, halflife_time() + get_pcvar_float(cvar_time));
		return;
	}
	
	get_players(players, num, "ch");
	
	if (!num || num < get_pcvar_num(cvar_minplayers))
	{
		g_counter = NOT_IN_PROGRESS;
		action = EVENT_TIME;
		entity_set_float(ent, EV_FL_nextthink, halflife_time() + get_pcvar_float(cvar_time));
		return;
	}
	
	switch (action)
	{
		case EVENT_TIME:
		{
			#if defined EXTERNAL_MANAGEMENT
			ExecuteForward(forward_lotterystart, ret);
			
			if (ret >= PLUGIN_HANDLED)
			{
				action = EVENT_TIME;
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + get_pcvar_float(cvar_time));
				return;
			}
			#else
			if (!(g_options = get_pcvar_num(cvar_maxoptions)))
			{
				g_options = num * 3 / 2;
			}
			
			g_minparticipants = get_pcvar_num(cvar_minparticipants);
			#endif
			
			g_counter = get_pcvar_num(cvar_duration);
			g_bPaid = 0;
			g_bParticipate = 0;
			g_bConfirmed = 0;
			g_participating = 0;
			
			show_menu_event(0);
			
			for (new id, i = 0; i < num; i++)
			{
				id = players[i];
				
				if (player_check_bit(g_bDontAsk, id))
				{
					player_set_bit(g_bConfirmed, id);
					continue;
				}
				
				show_menu_event(id);
			}
			
			action = COUNTER;
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 1.0);
		}
		case COUNTER:
		{
			if (!--g_counter)
			{
				g_counter = TIME_OVER;
				action = EVENT_ANNOUNCE;
			}
			else
			{
				for (new id, i = 0; i < num; i++)
				{
					id = players[i];
					if (~player_check_bit(g_bConfirmed, id))
					{
						show_menu_event(id);
					}
				}
			}
			
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 1.0);
		}
		case EVENT_ANNOUNCE:
		{
			if (g_participating >= g_minparticipants)
			{
				g_counter = AWAITING_RESULT;
				send_colored_message(players[0], "%L %L", LANG_SERVER, "LT_TIMEOVER", LANG_SERVER, "LT_5SECS");
				action = EVENT_RESULT;
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 5.0);
			}
			else
			{
				g_counter = NOT_IN_PROGRESS;
				send_colored_message(players[0], "%L %L", LANG_SERVER, "LT_TIMEOVER", LANG_SERVER, "LT_NOENGH");
				
				if (g_participating)
				{
					#if !defined EXTERNAL_MANAGEMENT
					new cost = get_pcvar_num(cvar_cost);
					#endif
					for (new id, i = 0; i < num; i++)
					{
						id = players[i];
						if (player_check_bit(g_bParticipate, id))
						{
							#if defined EXTERNAL_MANAGEMENT
							ExecuteForward(forward_refund, ret, id);
							#else
							cs_set_user_money(id, cs_get_user_money(id) + cost);
							#endif
							
							client_print(id, print_center, "%L", LANG_SERVER, "LT_REFUND");
						}
					}
				}
				
				action = EVENT_TIME;
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + get_pcvar_float(cvar_time));
			}
		}
		case EVENT_RESULT:
		{
			g_counter = NOT_IN_PROGRESS;
			
			new len, szNames[32*MAX_PLAYERS], winners, result = random(g_options)+1;
			send_colored_message(players[0], "%L^x04 %d", LANG_SERVER, "LT_LUCKYNUM", result);
			
			for (new id, i = 0; i < num; i++)
			{
				id = players[i];
				
				if (~player_check_bit(g_bParticipate, id))
					continue;
				
				if (g_option[id] == result)
				{
					if (winners)
						len += copy(szNames[len], charsmax(szNames)-len, "^x01,^x04 ");
					
					len += get_user_name(id, szNames[len], charsmax(szNames)-len);
					
					client_print(id, print_center, "%L", LANG_SERVER, "LT_YOUWON");
					winners++;
					
					#if defined EXTERNAL_MANAGEMENT
					ExecuteForward(forward_givereward, ret, id);
					#else
					cs_set_user_money(id, ((get_pcvar_num(cvar_fixedreward)) ? 1 : g_participating) * get_pcvar_num(cvar_reward) + cs_get_user_money(id));
					#endif
				}
				else
				{
					client_print(id, print_center, "%L", LANG_SERVER, "LT_SORRY", g_option[id]);
				}
			}
			
			send_colored_message(players[0], !winners ? "%L" : "%L (%d): ^x04%s", LANG_SERVER, !winners ? "LT_NOONE" : "LT_WINNERS", winners, szNames);
			
			action = EVENT_TIME;
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + get_pcvar_float(cvar_time));
		}
	}
}

show_menu_event(id)
{
	static len, menu[2*MAXLEN+400];
	
	if (!id)
	{
		#if defined EXTERNAL_MANAGEMENT
		len = formatex(menu, charsmax(menu), "\r%L\y %L^n%L \r%s^n", LANG_SERVER, "LT_PREFIX", LANG_SERVER, "LT_ASK", LANG_SERVER, "LT_COST", g_descriptions[0]);
		len += formatex(menu[len], charsmax(menu)-len, "\y%L \r%s^n^n\r1.\w %L^n\r2.\w %L", LANG_SERVER, "LT_REWARD", g_descriptions[1], LANG_SERVER, "LT_YES", LANG_SERVER, "LT_NO");
		#else
		len = formatex(menu, charsmax(menu), "\r%L\y %L^n%L \r%d \w$^n", LANG_SERVER, "LT_PREFIX", LANG_SERVER, "LT_ASK", LANG_SERVER, "LT_COST", get_pcvar_num(cvar_cost));
		
		if (get_pcvar_num(cvar_fixedreward))
			len += formatex(menu[len], charsmax(menu)-len, "\y%L \r%d \w$^n^n\r1.\w %L^n\r2.\w %L", LANG_SERVER, "LT_REWARD", get_pcvar_num(cvar_reward), LANG_SERVER, "LT_YES", LANG_SERVER, "LT_NO");
		else
			len += formatex(menu[len], charsmax(menu)-len, "\y%L \r%L \w$^n^n\r1.\w %L^n\r2.\w %L", LANG_SERVER, "LT_REWARD", LANG_SERVER, "LT_MULTI", get_pcvar_num(cvar_reward), LANG_SERVER, "LT_YES", LANG_SERVER, "LT_NO");
		#endif
		
		len += formatex(menu[len], charsmax(menu)-len, "^n\r3.\w %L^n^n\r%L\y ", LANG_SERVER, "LT_NEVER", LANG_SERVER, "LT_REMAIN");
		
		return;
	}
	
	formatex(menu[len], charsmax(menu)-len, "%02d", g_counter);
	
	show_menu(id, CONFIRMKEYS, menu, g_counter == 1 ? 1 : 2, "EventMenu");
}

public menu_event(id, key)
{
	switch (1<<key)
	{
		case MENU_KEY_1:
		{
			#if defined EXTERNAL_MANAGEMENT
			static ret;
			ExecuteForward(forward_check, ret, id);
			if (ret < PLUGIN_HANDLED)
			{
				ExecuteForward(forward_pay, ret, id);
			#else
			static money, cost;
			money = cs_get_user_money(id);
			cost = get_pcvar_num(cvar_cost);
			if (money > cost)
			{
				cs_set_user_money(id, money - cost);
			#endif
				g_bPaid |= (1<<id-1);
				client_cmd(id, "messagemode ^"your_number^"");
				client_print(id, print_center, "%L 1-%d.", LANG_SERVER, "LT_RANGE", g_options);
			}
			else
			{
				client_print(id, print_center, "%L", LANG_SERVER, "LT_CANTPAY");
			}
		}
		case MENU_KEY_3:
		{
			client_print(id, print_chat, "%L %L", LANG_SERVER, "LT_PREFIX", LANG_SERVER, "LT_NOMORE");
			player_set_bit(g_bDontAsk, id);
		}
	}
	
	player_set_bit(g_bConfirmed, id);
	
	// Just for security.
	show_menu(id, 0, "^n", 1);

	return PLUGIN_HANDLED;
}

public clcmd_saylottery(id)
{
	player_clear_bit(g_bDontAsk, id);
	client_print(id, print_chat, "%L %L", LANG_SERVER, "LT_PREFIX", LANG_SERVER, "LT_AGAIN");
	return PLUGIN_HANDLED;
}

public clcmd_num(id)
{
	if (~player_check_bit(g_bPaid, id))
	{
		client_print(id, print_center, "%L", LANG_SERVER, "LT_NOTPAID");
		return PLUGIN_HANDLED;
	}
	
	if (g_counter <= 0)
	{
		client_print(id, print_center, "%L", LANG_SERVER, "LT_NOTINTIME");
		return PLUGIN_HANDLED;
	}
	
	static szNum[5];
	read_argv(1, szNum, charsmax(szNum));
	
	if (1 <= (g_option[id] = str_to_num(szNum)) <= g_options)
	{
		client_print(id, print_center, "%L", LANG_SERVER, "LT_GOODLUCK", g_option[id]);
		player_set_bit(g_bParticipate, id);
		g_participating++;
	}
	else
	{
		client_print(id, print_center, "%L", LANG_SERVER, "LT_INVALID");
		client_cmd(id, "messagemode ^"your_number^"");
	}
	
	return PLUGIN_HANDLED;
}

send_colored_message(sender, const message[], any:...)
{
	static szMsg[192], len;
	
	if (!len)
		len = formatex(szMsg, charsmax(szMsg), "^x04%L^x01 ", LANG_SERVER, "LT_PREFIX");
	
	vformat(szMsg[len], charsmax(szMsg)-len, message, 3);
	
	message_begin(MSG_BROADCAST, g_msgSayText);
	write_byte(sender);
	write_string(szMsg);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
