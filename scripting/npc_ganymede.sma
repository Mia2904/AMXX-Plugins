/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#pragma semicolon 1

#define PLUGIN "NPC Ganymede"
#define VERSION "0.1"

const Float:VIDA = 100.0;
const Float:SPEED = 400.0;
const Float:HIT_DAMAGE = 10.0;
const Float:MIN_DIST = 80.0;
const Float:JUMP_SPEED = 2000.0;
const Float:HIT_SPEED = 1000.0;
const Float:FIND_RADIUS = 3000.0;
const ATTACK_NUMS = 3;

new const NPC_CLASSNAME[] = "npc_ganymede";
new const NPC_MODEL[] = "models/ganymede/ganymede.mdl";

new const Float:normal_maxs[3] = { 25.0, 50.0, 80.0 };
new const Float:normal_mins[3] = { -25.0, -50.0, -35.0 };

new const Float:walk_maxs[3] = { 30.0, 30.0, 80.0 };
new const Float:walk_mins[3] = { -30.0, -30.0, -35.0 };

new const arenas[4][4] =
{
	{ -1518, -820, 16, 1518 },
	{ 1360, 2287, -1135, -40 },
	{ -750, 366, -2478, -1552 },
	{ 2512, 3438, -2670, -1545 }
};

enum _:Vector
{
	X = 0,
	R = 0,
	Y = 1,
	G = 1,
	Z = 2,
	B = 2
};

enum
{
	ANIM_STOP = 0,
	ANIM_HIT,
	ANIM_DIE,
	ANIM_STAND,
	ANIM_RUN
};

enum
{
	STATUS_APPEAR = 1,
	STATUS_MAKE_VISIBLE,
	STATUS_FIND_VICTIM,
	STATUS_WALK,
	STATUS_PURSUIT,
	STATUS_ATTACK,
	STATUS_IDLE,
	STATUS_JUMP,
	STATUS_DISAPPEAR
};

const EV_INT_status = EV_INT_iuser1;
const EV_INT_attacknum = EV_INT_iuser2;
const EV_INT_walkdir = EV_INT_iuser3;
const EV_INT_arena = EV_INT_iuser4;

enum RgbColor
{
	COLOR_WHITE = 0,
	COLOR_RED,
	COLOR_GREEN,
	COLOR_BLUE,
	COLOR_YELLOW,
	COLOR_CYAN,
	COLOR_MAGENTA,
	COLOR_PURPLE,
	COLOR_ORANGE
};

new const RGB_COLORS[RgbColor][Vector] =
{
	{	150,	170,	200	},	// Blanco
	{	255,	0,	0	},	// Rojo
	{	0,	255,	0	},	// Verde
	{	0,	0,	255	},	// Azul
	{	255,	255,	0	},	// Amarillo
	{	0,	250,	250	},	// Celeste
	{	170,	50,	100	},	// Magenta
	{	100,	50,	200	},	// Morado
	{	255,	150,	100	}	// Naranja
};

enum SprIndex
{
	SPR_FLARE6 = 0,
	SPR_LIGHTNING,
	SPR_XBEAM5,
	SPR_BLOOD,
	SPR_BLOODSPRAY,
	SPR_SMOKE,
	SPR_EXPLODE
};

new g_sprindex[SprIndex];

new g_model, g_reg, g_msgScreenFade, g_msgScreenShake, g_door;

new Float:g_origin[3];

public plugin_precache()
{
	//g_model = precache_model(NPC_MODEL);
	
	g_sprindex[SPR_BLOOD] = precache_model("sprites/blood.spr");
	g_sprindex[SPR_BLOODSPRAY] = precache_model("sprites/bloodspray.spr");
	g_sprindex[SPR_FLARE6] = precache_model("sprites/Flare6.spr");
	g_sprindex[SPR_LIGHTNING] = precache_model("sprites/lgtning.spr");
	g_sprindex[SPR_XBEAM5] = precache_model("sprites/xbeam5.spr");
	g_sprindex[SPR_SMOKE] = precache_model("sprites/smoke.spr");
	g_sprindex[SPR_EXPLODE] = precache_model("sprites/fire_explode.spr");
}

public plugin_init()
{
	//server_cmd("no_amxx_uncompress"); 
	register_plugin(PLUGIN, VERSION, "Mia2904");
	
	register_clcmd("make", "test");
	register_clcmd("test", "aa");
	register_clcmd("speed", "abc");
	register_clcmd("test2", "arena");
	
	register_clcmd("break", "clcmd_break");
	
	g_door = find_ent_by_class(-1, "func_door");
	
	register_think(NPC_CLASSNAME, "fw_NpcThink");
	register_touch(NPC_CLASSNAME, "player", "fw_NpcPlayerTouch");
	
	g_msgScreenFade = get_user_msgid("ScreenFade");
	g_msgScreenShake = get_user_msgid("ScreenShake");
}

public arena(id)
{
	new Float:originf[3];
	entity_get_vector(id, EV_VEC_origin, originf);
	client_print(id, print_chat, "%s", is_in_arena(originf, 0) ? "Si" : "No");
}

public clcmd_break(id)
{
	new origin[3] = { -790, 1630, 200 };
	
	for (new i = 0; i < 8; i++)
	{
		if (3 <= i <= 4)
			continue;
		
		origin[1] -= 190;
		explode(origin);
	}
	
	remove_entity(g_door);
	
	return PLUGIN_HANDLED;
}

public abc(id)
{
	set_user_maxspeed(id, 800.0);
}

public test(id)
{
	new Float:angles[3], Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);
	xs_vec_copy(origin, g_origin);
	
	entity_get_vector(id, EV_VEC_angles, angles);
	
	new tesa;
	
	while (!is_hull_vacant(origin, HULL_LARGE))
	{
		origin[0] = g_origin[0] + random_float(100.0, 300.0);
		origin[1] = g_origin[1] + random_float(100.0, 300.0);
		
		if (++tesa > 10)
		{
			client_print(id, print_chat, "error");
			return;
		}
	}
	
	create_ganymede(g_origin, angles);
	
	xs_vec_copy(origin, g_origin);
}

public aa(id)
{
	new Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);
	console_print(0, "%.0f %.0f %.0f", origin[0], origin[1], origin[2]);
	
	beam_cylinder(origin, SPR_SMOKE, COLOR_CYAN, 50.0, 20, 200, 1.5);
}

public fw_NpcThink(ent)
{
	static Float:origin[3], Float:originT[3], Float:velocity[3];
	static trace, i, victim, Float:backup, Float:backupT;
	
	switch (entity_get_int(ent, EV_INT_status))
	{
		case STATUS_APPEAR:
		{
			entity_set_origin(ent, g_origin);
			xs_vec_copy(g_origin, origin);
			origin[2] = origin[2] - 20.0;
			entity_set_int(ent, EV_INT_sequence, ANIM_STAND);
			
			entity_set_int(ent, EV_INT_attacknum, 1);
			
			entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
			entity_set_int(ent, EV_INT_status, STATUS_MAKE_VISIBLE);
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.01);
		}
		case STATUS_MAKE_VISIBLE:
		{
			backup = floatadd(entity_get_float(ent, EV_FL_renderamt), 10.0);
			
			if (backup >= 255.0)
			{
				backup = 255.0;
				entity_set_int(ent, EV_INT_status, STATUS_WALK);
				entity_set_int(ent, EV_INT_walkdir, -1);
				entity_set_size(ent, walk_mins, walk_maxs);
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 1.5);
				beam_cylinder(origin, SPR_SMOKE, COLOR_WHITE, 120.0, 100, 200, 1.0);
			}
			else
			{
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.15);
			}
			
			entity_set_float(ent, EV_FL_renderamt, backup);
		}
		case STATUS_WALK:
		{
			entity_get_vector(ent, EV_VEC_origin, origin);
			
			/*if ((i = is_in_arena(origin, 0)))
			{
				entity_set_size(ent, normal_mins, normal_maxs);
				entity_set_int(ent, EV_INT_sequence, ANIM_STAND);
				entity_set_int(ent, EV_INT_status, STATUS_FIND_VICTIM);
				entity_set_int(ent, EV_INT_arena, i);
				entity_set_vector(ent, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 2.0);
			
				return;
			}*/
			
			victim = entity_get_int(ent, EV_INT_walkdir); // victim aqui es la direccion en la que corre
						
			if (victim == -1)
			{
				entity_set_int(ent, EV_INT_sequence, ANIM_RUN);
			}
			
			originT[2] = origin[2];
			
			for (i = 0; i < 4; i++)
			{
				if (i == victim)
					continue;
				
				switch(i)
				{
					case 0:
					{
						if (victim == 1)
							continue;
						
						originT[0] = origin[0] + 180.0;
						originT[1] = origin[1];
					}
					case 1:
					{
						if (victim == 0)
							continue;
						
						originT[0] = origin[0] - 180.0;
						originT[1] = origin[1];
					}
					case 2:
					{
						if (victim == 3)
							continue;
						
						originT[0] = origin[0];
						originT[1] = origin[1] + 180.0;
					}
					case 3:
					{
						if (victim == 2)
							continue;
						
						originT[0] = origin[0];
						originT[1] = origin[1] - 180.0;
					}
				}
						
				engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
				get_tr2(trace, TR_flFraction, backup);
				
				if (backup != 1.0)
					continue;
				
				xs_vec_copy(originT, velocity);
				
				switch(i)
				{
					case 0:
					{
						originT[1] = velocity[1] - 50.0;
						velocity[1] = originT[1] + 100.0;
					}
					case 1:
					{
						originT[1] = velocity[1] + 50.0;
						velocity[1] = originT[1] - 100.0;
					}
					case 2:
					{
						originT[0] = velocity[0] - 50.0;
						velocity[0] = originT[0] + 100.0;
					}
					case 3:
					{
						originT[0] = velocity[0] + 50.0;
						velocity[0] = originT[0] - 100.0;
					}
				}
				
				engfunc(EngFunc_TraceLine, originT, velocity, IGNORE_MONSTERS, ent, trace);
				get_tr2(trace, TR_flFraction, backup);
				
				if (backup == 1.0) // Hay un camino disponible
				{
					if (victim != -1) // Ya tenia un camino?
					{
						trace_vector(victim, origin, 90.0, originT);
						
						engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
						get_tr2(trace, TR_flFraction, backup);
						
						if (backup == 1.0 && random_num(0, 2)) // Puede seguir por el mismo camino
						{
							xs_vec_sub(originT, origin, velocity);
							xs_vec_normalize(velocity, velocity);
							//vector_to_angle(velocity, originT);
							xs_vec_mul_scalar(velocity, SPEED, velocity);
							
							entity_set_vector(ent, EV_VEC_velocity, velocity);
							//entity_set_vector(ent, EV_VEC_angles, originT);
							//entity_set_int(ent, EV_INT_walkdir, i);
							entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1);
							
							return;
						}
					}

					// No puede seguir por el mismo camino, tiene que tomar otro o empezar uno
					
					trace_vector(i, Float:{0.0, 0.0, 0.0}, SPEED, velocity);
					//xs_vec_normalize(velocity, velocity);
					vector_to_angle(velocity, originT);
					//xs_vec_mul_scalar(velocity, SPEED, velocity);
					
					entity_set_vector(ent, EV_VEC_velocity, velocity);
					entity_set_vector(ent, EV_VEC_angles, originT);
					entity_set_int(ent, EV_INT_walkdir, i);
					
					entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.3);
							
					return;
				}
			}
			
			/*trace_vector(victim, origin, 90.0, originT);
			
			// [DEBUG] comprobar que puede seguir de largo
			switch(victim)
			{
				case 0, 1:
				{
					origin[1] = originT[1] - walk_maxs[2];
					origin[1] = originT[1] + 1.0;
				}
				case 2, 3:
				{
					origin[0] = originT[0] - walk_maxs[2];
					origin[0] = originT[0] + 1.0;
				}
			}
			
			engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
			get_tr2(trace, TR_flFraction, backup);
			
			if (backup == 1.0) 
			{
				switch(victim)
				{
					case 0, 1:
					{
						origin[1] = originT[1] + (2.0*walk_maxs[2]);
						origin[1] = originT[1] - 2.0;
					}
					case 2, 3:
					{
						origin[0] = originT[0] + (2.0*walk_maxs[2]);
						origin[1] = originT[1] - 2.0;
					}
				}
				
				engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
				get_tr2(trace, TR_flFraction, backup);
				
				switch(victim)
				{
					case 0, 1:
					{
						origin[1] = originT[1] - walk_maxs[2];
						origin[1] = originT[1] + 1.0;
					}
					case 2, 3:
					{
						origin[0] = originT[0] - walk_maxs[2];
						origin[1] = originT[1] + 1.0;
					}
				}
				
				if (backup == 1.0) 
				{
					trace_vector(victim, Float:{0.0, 0.0, 0.0}, SPEED, velocity);
					//xs_vec_sub(originT, origin, velocity);
					//xs_vec_normalize(velocity, velocity);
					//vector_to_angle(velocity, originT);
					//xs_vec_mul_scalar(velocity, SPEED, velocity);
					
					entity_set_vector(ent, EV_VEC_velocity, velocity);
					//entity_set_vector(ent, EV_VEC_angles, originT);
					//entity_set_int(ent, EV_INT_walkdir, i);
					entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.10);
					
					return;
				}
			}
			else
			{
				switch(victim)
				{
					case 0, 1:
					{
						origin[1] = originT[1] + 30.0;
					}
					case 2, 3:
					{
						origin[0] = originT[0] + 30.0;
					}
				}
			}
			
			// Retroceder
			{
				trace_vector(victim, Float:{0.0, 0.0, 0.0}, -SPEED, velocity);
				//xs_vec_sub(origin, originT, velocity);
				//xs_vec_normalize(velocity, velocity);
				vector_to_angle(velocity, originT);
				//xs_vec_mul_scalar(velocity, SPEED, velocity);
				
				//vector_to_angle(velocity, originT);
				//xs_vec_mul_scalar(velocity, SPEED, velocity);
				
				entity_set_vector(ent, EV_VEC_velocity, velocity);
				entity_set_vector(ent, EV_VEC_angles, originT);
				
				switch(victim)
				{
					case 0:
					{
						i = 1;
					}
					case 1:
					{
						i = 0;
					}
					case 2:
					{
						i = 3;
					}
					case 3:
					{
						i = 2;
					}
				}
					
				entity_set_int(ent, EV_INT_walkdir, i);
				
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.10);
			}*/
			
			trace_vector(victim, Float:{0.0, 0.0, 0.0}, SPEED, velocity);
			
			//xs_vec_normalize(velocity, velocity);
			vector_to_angle(velocity, originT);
			//xs_vec_mul_scalar(velocity, SPEED, velocity);
						
			entity_set_vector(ent, EV_VEC_velocity, velocity);
			entity_set_vector(ent, EV_VEC_angles, originT);
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.15);
		}
		case STATUS_FIND_VICTIM:
		{
			victim = get_closest_player(ent);
			entity_get_vector(victim, EV_VEC_origin, originT);
			
			if (!victim || !is_in_arena(originT, entity_get_int(ent, EV_INT_arena)))
			{
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.5);
				return;
			}
			
			entity_get_vector(ent, EV_VEC_origin, origin);
			
			entity_set_edict(ent, EV_ENT_enemy, victim);
			
			entity_get_vector(ent, EV_VEC_origin, origin);
			//entity_get_vector(victim, EV_VEC_origin, originT);
			
			xs_vec_sub(originT, origin, velocity);
			vector_to_angle(velocity, velocity);
			
			entity_set_vector(ent, EV_VEC_angles, velocity);
			
			entity_set_int(ent, EV_INT_sequence, ANIM_RUN);
			entity_set_int(ent, EV_INT_status, STATUS_PURSUIT);
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.05);
		}
		case STATUS_PURSUIT:
		{
			victim = entity_get_edict(ent, EV_ENT_enemy);
			
			if (pev_valid(victim) >= 2)
				entity_get_vector(victim, EV_VEC_origin, originT);
			
			if (!is_user_alive(victim) || !is_in_arena(originT, entity_get_int(ent, EV_INT_arena)))
			{
				entity_get_vector(ent, EV_VEC_velocity, velocity);
				velocity[0] = velocity[1] = 0.0;
				entity_set_vector(ent, EV_VEC_velocity, velocity);
				
				entity_set_int(ent, EV_INT_sequence, ANIM_STAND);
				entity_set_int(ent, EV_INT_status, STATUS_FIND_VICTIM);
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.8);
				return;
			}
			
			if (entity_range(ent, victim) <= MIN_DIST)
			{
				entity_get_vector(ent, EV_VEC_velocity, velocity);
				velocity[0] = velocity[1] = 0.0;
				entity_set_vector(ent, EV_VEC_velocity, velocity);
				
				entity_set_int(ent, EV_INT_sequence, ANIM_HIT);
				entity_set_int(ent, EV_INT_status, STATUS_ATTACK);
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.2);
				return;
			}
			
			entity_get_vector(ent, EV_VEC_origin, origin);
			entity_get_vector(victim, EV_VEC_origin, originT);
			
			static trace, Float:fraction;
			engfunc(EngFunc_TraceLine, origin, originT, IGNORE_MONSTERS, ent, trace);
			
			get_tr2(trace, TR_flFraction, fraction);
				
			if (fraction != 1.0)
			{
				entity_get_vector(ent, EV_VEC_velocity, velocity);
				velocity[0] = velocity[1] = 0.0;
				entity_set_vector(ent, EV_VEC_velocity, velocity);
				
				entity_set_int(ent, EV_INT_sequence, ANIM_STAND);
				entity_set_int(ent, EV_INT_status, STATUS_FIND_VICTIM);
				entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.8);
				return;
			}
			
			entity_get_vector(ent, EV_VEC_velocity, velocity);
			
			backup = velocity[2];
			xs_vec_sub(originT, origin, velocity);
			xs_vec_normalize(velocity, velocity);
			xs_vec_mul_scalar(velocity, SPEED, velocity);
			backupT = velocity[2];
			velocity[2] = backup;
			
			entity_set_vector(ent, EV_VEC_velocity, velocity);
			velocity[2] = backupT;
			vector_to_angle(velocity, velocity);
			entity_set_vector(ent, EV_VEC_angles, velocity);
			
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.2);
		}
		case STATUS_ATTACK:
		{
			entity_get_vector(ent, EV_VEC_origin, origin);
			entity_get_vector(ent, EV_VEC_angles, originT);
			angle_vector(originT, ANGLEVECTOR_FORWARD, originT);
			xs_vec_normalize(originT, originT);
			xs_vec_mul_scalar(originT, 10.0, originT);
			xs_vec_add(originT, origin, originT);
			
			victim = -1;
			while ((victim = find_ent_in_sphere(victim, originT, 90.0)) > 0)
			{
				if (!(1 <= victim <= 32))
					continue;
				
				if (!is_user_alive(victim))
					continue;
				
				screen_shake(victim);
				screen_fade(victim, COLOR_RED, 160, 2);
				ExecuteHamB(Ham_TakeDamage, victim, ent, ent, HIT_DAMAGE, DMG_CLUB);
			}
			
			entity_set_edict(ent, EV_ENT_enemy, 0);
			entity_set_int(ent, EV_INT_status, STATUS_IDLE);
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.4);
		}
		case STATUS_IDLE:
		{
			entity_set_int(ent, EV_INT_sequence, ANIM_STAND);
			
			victim = entity_get_int(ent, EV_INT_attacknum);
			
			if (victim < ATTACK_NUMS)
			{
				entity_set_int(ent, EV_INT_attacknum, victim+1);
				entity_set_int(ent, EV_INT_status, STATUS_FIND_VICTIM);
			}
			else
			{
				entity_set_int(ent, EV_INT_status, STATUS_JUMP);
			}
			
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 2.0);
		}
		case STATUS_JUMP:
		{
			entity_set_int(ent, EV_INT_sequence, ANIM_STOP);
			entity_get_vector(ent, EV_VEC_origin, origin);
			origin[2] = origin[2] - 20.0;
			
			beam_cylinder(origin, SPR_SMOKE, COLOR_CYAN, 200.0, 60, 255, 1.0);
			velocity[0] = velocity[1] = 0.0;
			velocity[2] = JUMP_SPEED;
			entity_set_vector(ent, EV_VEC_velocity, velocity);
			
			entity_set_int(ent, EV_INT_status, STATUS_DISAPPEAR);
			entity_set_int(ent, EV_INT_solid, SOLID_NOT);
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.5);
		}
		case STATUS_DISAPPEAR:
		{
			entity_set_origin(ent, Float:{8000.0, 8000.0, 8000.0});
			entity_set_vector(ent, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
			
			entity_set_float(ent, EV_FL_renderamt, 0.0);
			
			entity_set_int(ent, EV_INT_status, STATUS_APPEAR);
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + 10.0);
		}
	}
}

public fw_NpcPlayerTouch(ent, id)
{
	if (!is_user_alive(id) || id == entity_get_edict(ent, EV_ENT_enemy))
		return;
	
	static Float:origin[3], Float:originT[3];
	entity_get_vector(ent, EV_VEC_origin, origin);
	entity_get_vector(id, EV_VEC_origin, originT);
	client_print(0, print_chat, "%.2f %.2f %.2f", originT[0], originT[1], originT[2]);
	
	xs_vec_sub(originT, origin, originT);
	client_print(0, print_chat, "%.2f %.2f %.2f", originT[0], originT[1], originT[2]);
	originT[2] = 0.0;
	xs_vec_normalize(originT, originT);
	client_print(0, print_chat, "%.2f %.2f %.2f", originT[0], originT[1], originT[2]);
	originT[2] = 1.0;
	xs_vec_mul_scalar(originT, HIT_SPEED, originT);
	client_print(0, print_chat, "%.2f %.2f %.2f", originT[0], originT[1], originT[2]);
	
	//entity_get_vector(id, EV_VEC_velocity, origin);
	//xs_vec_add(origin, originT, originT);
	
	entity_set_vector(id, EV_VEC_velocity, originT);
}

create_ganymede(Float:origin[3], Float:angles[3])
{
	new ent = create_entity("info_target");
	
	entity_set_float(ent, EV_FL_takedamage, 1.0);
	entity_set_float(ent, EV_FL_health, VIDA);
	
	entity_set_string(ent, EV_SZ_classname, NPC_CLASSNAME);
	entity_set_model(ent, NPC_MODEL);
	
	entity_set_int(ent, EV_INT_modelindex, g_model);
	entity_set_size(ent, normal_mins, normal_maxs);
	
	entity_set_int(ent, EV_INT_sequence, ANIM_STAND);
	entity_set_float(ent, EV_FL_animtime, get_gametime());
	entity_set_float(ent, EV_FL_framerate, 1.0);
	entity_set_int(ent, EV_INT_rendermode, kRenderTransAlpha);
	entity_set_float(ent, EV_FL_renderamt, 255.0);
	
	entity_set_origin(ent, origin);
	entity_set_vector(ent, EV_VEC_angles, angles);
	drop_to_floor(ent);
	
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP);
	entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags)|FL_MONSTER);
	entity_set_float(ent, EV_FL_gravity, 1.0);
	entity_set_float(ent, EV_FL_friction, 0.5);
	
	if (!g_reg)
	{
		//RegisterHamFromEntity(Ham_TakeDamage, ent, "fw_NpcTakeDamage", true);
		//RegisterHamFromEntity(Ham_Killed, ent, "fw_NpcKilled", true);
		
		g_reg = 1;
	}
	
	entity_set_int(ent, EV_INT_status, STATUS_APPEAR);
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1);
	
	/*anim(ent, 3)
	set_task(5.0, "ganymede_done", ent+npc_start_think)// Ganymede prepare time
	set_rendering(ent,kRenderFxNone,255,255,255,kRenderTransAdd,200)
	emit_sound(ent, CHAN_BODY, npc_sound[9], 1.0, ATTN_NORM, 0, PITCH_NORM)
	if(!y_start_npc)
	{
		y_start_npc = 1
		RegisterHamFromEntity(Ham_TakeDamage, ent, "ganymede_take_damage", 1)
	}
	y_hpbar = create_entity("env_sprite")
	set_pev(y_hpbar, pev_scale, 0.2)
	set_pev(y_hpbar, pev_owner, ent)
	engfunc(EngFunc_SetModel, y_hpbar, hp_spr)
	set_task(0.1, "ganymede_ready", ent+npc_restart, _, _, "b")
	set_task(random_float(7.0, 15.0), "punish", npc_ability)*/
}

bool:is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0);
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

trace_vector(direction, Float:origin[3], Float:distance, Float:out[3])
{
	switch(direction)
	{
		case 0:
		{
			out[0] = origin[0] + distance;
			out[1] = origin[1];
		}
		case 1:
		{
			out[0] = origin[0] - distance;
			out[1] = origin[1];
		}
		case 2:
		{
			out[0] = origin[0];
			out[1] = origin[1] + distance;
		}
		case 3:
		{
			out[0] = origin[0];
			out[1] = origin[1] - distance;
		}
	}
}

is_in_arena(Float:originf[3], num)
{	
	new iorigin[3];
	iorigin[0] = floatround(originf[0]);
	iorigin[1] = floatround(originf[1]);
	iorigin[2] = floatround(originf[2]);
	num--;
	
	if (-1 < num < sizeof(arenas))
	{
		if (arenas[num][0] <= iorigin[0] <= arenas[num][1] && arenas[num][2] <= iorigin[1] <= arenas[num][3])
			return 1;
		
		return 0;
	}
	
	for (new i = 0; i < sizeof(arenas); i++)
	{
		if (arenas[i][0] <= iorigin[0] <= arenas[i][1] && arenas[i][2] <= iorigin[1] <= arenas[i][3])
			return i+1;
	}
	
	return 0;
}
		
stock get_closest_player(iEntity)
{
    // iEntity = entity you are finding players closest to
    
    static iPlayers[ 32 ], iNum;
    get_players( iPlayers, iNum, "a" );
    
    new iClosestPlayer = 0;
    static iPlayer, Float:flDist, Float:flClosestDist;
    flClosestDist = FIND_RADIUS;
    
    for( new i = 0; i < iNum; i++ )
    {
        iPlayer = iPlayers[ i ];

        flDist = entity_range( iPlayer, iEntity );
        
        if( flDist <= flClosestDist )
        {
            iClosestPlayer = iPlayer;
            flClosestDist = flDist;
        }
    }
    
    return iClosestPlayer;
}

stock get_random_alive()
{
	static players[32], num;
	get_players(players, num, "a");
	
	return players[random(num)];
}

stock beam_cylinder(Float:origin[3], SprIndex:sprite = SPR_SMOKE, RgbColor:color = COLOR_GREEN, Float:radius = 100.0, high = 40, brightness = 255, Float:secs = 1.0)
{
	radius = radius / 1.41; // 1.41 = raiz(2), de esta forma la suma vectorial es igual al radio
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, origin[X]);
	engfunc(EngFunc_WriteCoord, origin[Y]);
	engfunc(EngFunc_WriteCoord, origin[Z]);
	engfunc(EngFunc_WriteCoord, floatadd(origin[2], radius));
	engfunc(EngFunc_WriteCoord, floatadd(origin[2], radius));
	engfunc(EngFunc_WriteCoord, floatadd(origin[2], radius));
	write_short(g_sprindex[sprite]);
	write_byte(0);
	write_byte(0);
	write_byte(floatround(secs*10.0));
	write_byte(high);
	write_byte(0);
	write_byte(RGB_COLORS[color][R]); 		// Red
	write_byte(RGB_COLORS[color][G]); 		// Green
	write_byte(RGB_COLORS[color][B]);	 	// Blue
	write_byte(brightness);
	write_byte(9);
	message_end();
}

stock screen_fade(id, RgbColor:color = COLOR_RED, alpha = 255, secs = 1)
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_msgScreenFade, _, id);
	write_short(secs*4096); // duracion
	write_short(0); // tiempo de espera
	write_short(0x0000);
	write_byte(RGB_COLORS[color][R]); 		// Red
	write_byte(RGB_COLORS[color][G]); 		// Green
	write_byte(RGB_COLORS[color][B]);	 	// Blue
	write_byte(alpha);
	message_end();
}

stock screen_shake(id, amplitude = 10)
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_msgScreenShake, _,id);
	write_short(15*4096);
	write_short(4096*amplitude);
	write_short(200*256);
	message_end();
}

stock explode(origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short(g_sprindex[SPR_EXPLODE]);
	write_byte(30);
	write_byte(15);
	write_byte(0);
	message_end(); 
}

