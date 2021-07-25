//Special thanks to Sylwester for algorithm: http://forums.alliedmods.net/showthread.php?p=1613597

#include <amxmodx>

#pragma semicolon 1

#define VERSION "2.4"

new calc_enable, calc_message, calc_onlyadmins, calc_textmode;
new operation[33];
new a[33][33], b[33][33], calcstate[33][51], calcmessage[33][81], mathoperation[33][101];
new Float:calcresult[33];
new bool:show_result[33], bool:is_player_typing[33], bool:enter_operation[33], bool:not_admin[33];

new const operator_sign[5][2] = { "+", "-", "*", "/", "^^" };

const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<9);

public plugin_init() 
{
	register_plugin("Calculator", VERSION, "Mia2904");
	
	register_dictionary("calculator.txt");
	
	/*register_clcmd("say /calc" , "OpenCalc");
	register_clcmd("say .calc", "OpenCalc");
	register_clcmd("say_team /calc", "OpenCalc");
	register_clcmd("say_team .calc", "OpenCalc");*/
	register_clcmd("calculator", "OpenCalc");
	
	register_clcmd("Num1" , "Value1");
	register_clcmd("Num2" , "Value2");
	register_clcmd("CalcNum", "MathReceiver");
	
	calc_message = register_cvar("calc_message", "0");
	calc_enable = register_cvar("calc_enable", "1");
	calc_textmode = register_cvar("calc_textmode", "0");
	calc_onlyadmins = register_cvar("calc_textmode_admins", "1");
	
	register_menucmd(register_menuid("Calculator"), KEYSMENU, "CalcMenu");
}

public client_putinserver(id)
{
	if(!is_user_bot(id) && get_pcvar_num(calc_message) && get_pcvar_num(calc_enable))
		set_task(10.0, "CalculatorMessage", id + 2514);
}

public client_disconnect(id)
{
	if(task_exists(id + 2514))
		remove_task(id + 2514);
}

public CalculatorMessage(id)
{
	id -= 2514;
	if(is_user_connected(id))
		client_print(id, print_chat, "%L", id, "CALC_MSG");
}

public OpenCalc(id)
{
	if(!get_pcvar_num(calc_textmode) || (get_pcvar_num(calc_onlyadmins) && !(get_user_flags(id) & ADMIN_IMMUNITY)))
		not_admin[id] = true;
	else not_admin[id] = false;

	Calculator(id);
}

public Calculator(id)
{
	if(!get_pcvar_num(calc_enable))
		return PLUGIN_HANDLED;
	
	static menu[512];
	new len;
	static operator_name[16];
	
	switch(operation[id])
	{
		case 0: formatex(operator_name, 15, "%L", id, "ADDI");
		case 1: formatex(operator_name, 15, "%L", id, "SUBS");
		case 2: formatex(operator_name, 15, "%L", id, "MULT");
		case 3: formatex(operator_name, 15, "%L", id, "DIVS");
		case 4: formatex(operator_name, 15, "%L", id, "EXPO");
	}
		
	if(!enter_operation[id] || not_admin[id])
		len += formatex(menu[len], 511 - len, "\w%.3f \y%s\w %.3f^n^n" , str_to_float(a[id]), operator_sign[operation[id]], str_to_float(b[id]));
	else len += formatex(menu[len], 511 - len, "\y%L: \w%s^n^n", id, "OPERATION", mathoperation[id]);
	
	if(is_player_typing[id])
		len += formatex(menu[len], 511 - len, "\y%s ^n^n", calcmessage[id]);
	else
	{
		if(enter_operation[id] && show_result[id])
			len += formatex(menu[len], 511 - len, "\y%L:\w %.0f^n^n", id, "RESULT", calcresult[id]);
		else if(show_result[id])
			len += formatex(menu[len], 511 - len, "\y%L:\w %f^n^n", id, "RESULT", calcresult[id]);
		else len += formatex(menu[len], 511 - len, "%s\w%s ^n^n", calcstate[id], calcmessage[id]);
		
		len += formatex(menu[len], 511 - len, "\r1.\w %L^n", id, "VALUE_1");
		len += formatex(menu[len], 511 - len, "\r2.\w %L^n^n", id, "VALUE_2");
		len += formatex(menu[len], 511 - len, "\r3.\w %L:\r [\y %s\r ]\d %s^n^n", id, "OPERATION", operator_sign[operation[id]], operator_name);
		
		if(not_admin[id] || enter_operation[id])
		{
			len += formatex(menu[len], 511 - len, "\r4.\y %L^n^n", id, "OPER");
			len += formatex(menu[len], 511 - len, "\r5.\w %L^n^n", id, "CLEAR");
		}
		else 
		{
			len += formatex(menu[len], 511 - len, "\r4.\y %L^n^n", id, "OPER");
			len += formatex(menu[len], 511 - len, "\r5.\w %L^n^n", id, "ENTER_OP");
		}
		
		len += formatex(menu[len], 511 - len, "\r0.\w %L^n^n", id, "EXIT");
	}
	
	show_menu(id, KEYSMENU, menu, _, "Calculator");
	
	return PLUGIN_CONTINUE;
}

public CalcMenu(id, key)
{
	show_result[id] = false;
	is_player_typing[id] = false;
	copy(calcstate[id], 0, "");
	copy(calcmessage[id], 0, "");
	switch(key)
	{
		case 0: 
		{
			formatex(calcmessage[id], 50, "%L", id, "TYPE_1");
			copy(a[id], 0, "");
			enter_operation[id] = false;
			is_player_typing[id] = true;
			client_cmd(id, "messagemode Num1");
		}
	
		case 1: 
		{
			formatex(calcmessage[id], 50, "%L", id, "TYPE_2");
			copy(b[id], 0, "");
			enter_operation[id] = false;
			is_player_typing[id] = true;
			client_cmd(id, "messagemode Num2");
		}
	
		case 2:
		{
			enter_operation[id] = false;
			operation[id] ++;
		
			if(operation[id] == 5)
				operation[id] = 0;
		}
	
		case 3: 
		{
			show_result[id] = true;
			
			if(enter_operation[id])
			{
				MathResolver(id);
				Calculator(id);
				return;
			}
			
			switch(operation[id])
			{
				case 0: calcresult[id] = str_to_float(a[id]) + str_to_float(b[id]);
					
				case 1: calcresult[id] = str_to_float(a[id]) - str_to_float(b[id]);
				
				case 2: calcresult[id] = str_to_float(a[id]) * str_to_float(b[id]);
					
				case 3: 
				{
					if(!str_to_num(b[id]))
					{
						show_result[id] = false;
						formatex(calcstate[id], 50, "\y%L: ", id, "SPEC");
						formatex(calcmessage[id], 80, "%L", id, "NO_DEF");
					}
					else calcresult[id] = str_to_float(a[id]) / str_to_float(b[id]);
				}
				
				//Power is inaccuarate and donesn't support floating points 
				//that's why I writted this code.
				case 4:
				{
					new Float:exp_base = str_to_float(a[id]);
					calcresult[id] = str_to_float(a[id]);
					new exponent = str_to_num(b[id]);
					if(!exponent && !exp_base)
					{
						show_result[id] = false;
						formatex(calcstate[id], 50, "\y%L: ", id, "SPEC");
						formatex(calcmessage[id], 80, "%L", id, "NO_DEF");
					}
					else if(!exponent)
					{
						calcresult[id] = 1.0;
					}
					else if( (exp_base > 20 || exp_base < -20) && (exponent > 9 || exponent < -9) )
					{
						show_result[id] = false;
						copy(a[id], 1, "0");
						formatex(calcstate[id], 50, "\y%L: ", id, "ERRO");
						formatex(calcmessage[id], 80, "%L", id, "TOO_BIG");
					}
					else if( (exp_base < 20 || exp_base > -20) && (exponent > 99 || exponent < -99) )
					{
						show_result[id] = false;
						copy(a[id], 1, "0");
						formatex(calcstate[id], 50, "\y%L: ", id, "ERRO");
						formatex(calcmessage[id], 80, "%L", id, "ONLY_2");
					}
					else if(exponent > 0)
					{
						for(new i=1; i < exponent; i++)
						{
							calcresult[id] *= exp_base;
						}
					}
					else if(exponent < 0)
					{
						for(new i=-1; i > exponent; i--)
						{
							calcresult[id] *= exp_base;
						}
						calcresult[id] = 1 / calcresult[id];
					}
				}
			}
		}
		
		case 4:
		{
			if(not_admin[id])
			{
				CalcMenu(id, 9);
				Calculator(id);
			}
			else if(!enter_operation[id])
			{
				enter_operation[id] = true;
				is_player_typing[id] = true;
				formatex(calcmessage[id], 50, "%L", id, "TYPE_OP");
				client_cmd(id, "messagemode CalcNum");
			}
			else 
			{
				copy(mathoperation[id], 0, "");
				enter_operation[id] = false;
			}
		}
			
		case 9: 
		{
			show_result[id] = false;
			enter_operation[id] = false;
			copy(a[id], 1, "0");
			copy(b[id], 1, "0");
			copy(mathoperation[id], 1, "0");
			operation[id] = 0;
			formatex(calcstate[id], 15, "\y%L: ", id, "CALC");
			formatex(calcmessage[id], 10, "%L", id, "WELC");
			return;
		}
	}

	Calculator(id);
}

public Value1(id, key) 
{
	read_argv(1, a[id], 32);
	is_player_typing[id] = false;
	if(str_to_float(a[id]) < 1000000 && str_to_float(a[id]) > -1000000)
	{
		formatex(calcstate[id], 50, "\d%L", id, "VAL_ENTER");
		copy(calcmessage[id], 0, "");
		
	}
	else 
	{
		formatex(calcstate[id], 50, "\r%L: ", id, "ERRO");
		formatex(calcmessage[id], 80, "%L", id, "ONLY_6");
		copy(a[id], 1, "0");
	}
	Calculator(id);
	return PLUGIN_HANDLED;
}

public Value2(id, key) 
{
	read_argv(1, b[id], 32);
	is_player_typing[id] = false;
	if(str_to_float(b[id]) < 1000000 && str_to_float(b[id]) > -1000000)
	{
		formatex(calcstate[id], 50, "\d%L", id, "VAL_ENTER");
		copy(calcmessage[id], 0, "");
	}
	else 
	{
		formatex(calcstate[id], 50, "\r%L: ", id, "ERRO");
		formatex(calcmessage[id], 80, "%L", id, "ONLY_6");
		copy(b[id], 1, "0");
	}
	Calculator(id);
	return PLUGIN_HANDLED;
}

public MathReceiver(id, key)
{
	read_argv(1, mathoperation[id], 100);
	is_player_typing[id] = false;
	formatex(calcstate[id], 50, "\d%L", id, "OPER_ENTER");
	copy(calcmessage[id], 0, "");
	Calculator(id);
	return PLUGIN_HANDLED;
}

//Algorithm from Sylwester: http://forums.alliedmods.net/showthread.php?p=1613597
public MathResolver(id)
{
    new stack[6], top;
    for(new i; i< strlen(mathoperation[id]); i++){
        switch(mathoperation[id][i]){
            case '0'..'9': stack[top] = stack[top]*10+mathoperation[id][i]-'0';
            case '+','-','/','*','x':{
                while(top > 0 && (stack[top-1] == '*' || stack[top-1] == 'x' || stack[top-1] == '/' || mathoperation[id][i] == '+' || mathoperation[id][i] == '-')){
                    switch(stack[top-1]){
                        case '+': stack[top-2] += stack[top];
                        case '-': stack[top-2] -= stack[top];
                        case '/': stack[top-2] /= stack[top];
                        case '*','x': stack[top-2] *= stack[top];
                    }
                    top -= 2;
                }                
                stack[++top] = mathoperation[id][i];  
                stack[++top] = 0;
            }
        }
    }
    while(top>0){
        switch(stack[top-1]){
            case '+': stack[top-2] += stack[top];
            case '-': stack[top-2] -= stack[top];
            case '/': stack[top-2] /= stack[top];
            case '*','x': stack[top-2] *= stack[top];
        }
        top -= 2;
    }       
    calcresult[id] = stack[top] * 1.0;
}
