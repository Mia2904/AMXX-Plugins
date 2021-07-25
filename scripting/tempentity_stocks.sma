#include <amxmodx>
#include <fakemeta>

enum _:Vector
{
    X = 0,
    R = 0,
    Y = 1,
    G = 1,
    Z = 2,
    B = 2
};

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
    {    150,    170,    200    },    // Blanco
    {    255,    0,    0    },    // Rojo
    {    0,    255,    0    },    // Verde
    {    0,    0,    255    },    // Azul
    {    255,    255,    0    },    // Amarillo
    {    0,    250,    250    },    // Celeste
    {    170,    50,    100    },    // Magenta
    {    100,    50,    200    },    // Morado
    {    255,    150,    100    }    // Naranja
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

new g_msgScreenFade;
new g_msgScreenShake;

public plugin_precache()
{
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
    g_msgScreenFade = get_user_msgid("ScreenFade");
    g_msgScreenShake = get_user_msgid("ScreenShake");
}

stock beam_points(origin1[3], origin2[3], SprIndex:sprite = SPR_XBEAM5, RgbColor:color = COLOR_WHITE, brightness = 255, secs = 5, noise = 20, speed = 50)
{
    message_begin(MSG_PVS, SVC_TEMPENTITY, int_origin);
    write_byte(TE_BEAMENTS);
    write_coord(origin1[X]);    //X // starting pos
    write_coord(origin1[Y]);    //Y
    write_coord(origin1[Z]);    //Z
    write_coord(origin2[X]);    //X // ending pos
    write_coord(origin2[Y]);    //Y
    write_coord(origin2[Z]);    //Z
    write_short(g_sprindex[sprite]);            // sprite index
    write_byte(0);                    // byte (starting frame)
    write_byte(0);                    // byte (frame rate in 0.1's)
    write_byte(10*secs);                // byte (life in 0.1's)
    write_byte(50);                    // byte (line width in 0.1's) 50
    write_byte(noise);                // byte (noise amplitude in 0.01's) 20
    write_byte(RGB_COLORS[color][R]);         // Red
    write_byte(RGB_COLORS[color][G]);         // Green
    write_byte(RGB_COLORS[color][B]);         // Blue
    write_byte(brightness);                // brightness
    write_byte(speed);                 // (scroll speed in 0.1's)
    message_end();
}

stock beam_disk(origin[3], SprIndex:sprite = SPR_LIGHTNING, RgbColor:color = COLOR_RED, speed = 0, Float:radius = 1000.0, brightness = 255, secs = 5)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMDISK) // TE_BEAMDISK
    engfunc(EngFunc_WriteCoord, origin[X]); // Start X
    engfunc(EngFunc_WriteCoord, origin[Y]); // Start Y
    engfunc(EngFunc_WriteCoord, origin[Z]); // Start Z
    engfunc(EngFunc_WriteCoord, 0.0)		// coord coord coord (axis x, y, z)
    engfunc(EngFunc_WriteCoord, 0.0)
    engfunc(EngFunc_WriteCoord, radius)
    write_short(g_sprindex[sprite])			// short (sprite index)
    write_byte(0)					// byte (starting frame)
    write_byte(0)					// byte (frame rate in 0.1's)
    write_byte(10*secs)				// byte (life in 0.1's)
    write_byte(0)					// byte (line width in 0.1's)
    write_byte(150)					// byte (noise amplitude in 0.01's)
    write_byte(RGB_COLORS[color][R])		// byte,byte,byte (color)
    write_byte(RGB_COLORS[color][G])
    write_byte(RGB_COLORS[color][B])
    write_byte(brightness)				// byte (brightness)
    write_byte(speed)				// byte (scroll speed in 0.1's)
    message_end()
}

stock beam_torus(origin[3], SprIndex:sprite = SPR_XBEAM5, RgbColor:color = COLOR_RED, speed = 0, Float:radius = 2500.0, brightness = 255, secs = 8)
{
    message_begin(MSG_PVS, SVC_TEMPENTITY, int_origin);
    write_byte(TE_BEAMTORUS);
    engfunc(EngFunc_WriteCoord, origin[X]); // Start X
    engfunc(EngFunc_WriteCoord, origin[Y]); // Start Y
    engfunc(EngFunc_WriteCoord, origin[Z]); // Start Z
    engfunc(EngFunc_WriteCoord, 0.0); // End X
    engfunc(EngFunc_WriteCoord, 0.0); // End Y
    engfunc(EngFunc_WriteCoord, radius); // End Z
    write_short(g_sprindex[sprite]); // sprite
    write_byte(0); // Starting frame
    write_byte(0); // framerate * 0.1
    write_byte(10*secs); // life * 0.1
    write_byte(500); // width
    write_byte(0); // noise
    write_byte(RGB_COLORS[color][R])		// byte,byte,byte (color)
    write_byte(RGB_COLORS[color][G])
    write_byte(RGB_COLORS[color][B])
    write_byte(brightness)				// byte (brightness)
    write_byte(speed)				// byte (scroll speed in 0.1's)
    message_end()
}

stock beam_ents(id1, id2, SprIndex:sprite = SPR_XBEAM5, RgbColor:color = COLOR_WHITE, brightness = 255, secs = 5, noise = 20, speed = 50)
{
    message_begin(MSG_PVS, SVC_TEMPENTITY, int_origin)
    write_byte(TE_BEAMENTS)
    write_short(id1) 				// start entity
    write_short(id2)					// end entity
    write_short(g_sprindex[sprite])			// sprite index
    write_byte(0)					// byte (starting frame)
    write_byte(0)					// byte (frame rate in 0.1's)
    write_byte(10*secs)				// byte (life in 0.1's)
    write_byte(50)					// byte (line width in 0.1's) 50
    write_byte(noise)				// byte (noise amplitude in 0.01's) 20
    write_byte(RGB_COLORS[color][R]) 		// Red
    write_byte(RGB_COLORS[color][G]) 		// Green
    write_byte(RGB_COLORS[color][B])	 	// Blue
    write_byte(brightness)				// brightness
    write_byte(speed) 				// (scroll speed in 0.1's)
    message_end()
}

stock large_funnel(origin[3], SprIndex:sprite = SPR_LIGHTNING, flag = 1)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_LARGEFUNNEL)
    //engfunc(EngFunc_WriteCoord, g_origin[X]); // Start X
    //engfunc(EngFunc_WriteCoord, g_origin[Y]); // Start Y
    //engfunc(EngFunc_WriteCoord, g_origin[Z]); // Start Z
    write_coord(origin[X]);    //X // starting pos
    write_coord(origin[Y]);    //Y
    write_coord(origin[Z]);    //Z
    write_short(g_sprindex[sprite]) // sprite
    write_short(flag) // flag
    message_end()
}

stock explotion(origin[3])
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_EXPLOSION)
    write_coord(origin[X]);    //X // starting pos
    write_coord(origin[Y]);    //Y
    write_coord(origin[Z]);    //Z
    write_short(g_sprindex[SPR_EXPLODE])
    write_byte(30)
    write_byte(15)
    write_byte(0)
    message_end(); 
}

stock beam_cylinder(Float:origin[3], SprIndex:sprite = SPR_SMOKE, RgbColor:color = COLOR_GREEN, Float:radius = 2500.0, brightness = 255, secs  = 1)
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin)
    write_byte(TE_BEAMCYLINDER)
    engfunc(EngFunc_WriteCoord, origin[X])
    engfunc(EngFunc_WriteCoord, origin[Y])
    engfunc(EngFunc_WriteCoord, origin[Z])
    engfunc(EngFunc_WriteCoord, 0.0)
    engfunc(EngFunc_WriteCoord, 0.0)
    engfunc(EngFunc_WriteCoord, radius)
    write_short(g_sprindex[sprite])
    write_byte(0)
    write_byte(0)
    write_byte(secs*10)
    write_byte(10)
    write_byte(0)
    write_byte(RGB_COLORS[color][R]) 		// Red
    write_byte(RGB_COLORS[color][G]) 		// Green
    write_byte(RGB_COLORS[color][B])	 	// Blue
    write_byte(brightness)
    write_byte(0)
    message_end()
}

stock screen_fade(id, RgbColor:color = COLOR_RED, alpha = 255, secs = 1)
{
    message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_msgScreenFade, _, id)
    write_short(secs*4096) // duracion
    write_short(0) // tiempo de espera
    write_short(0x0000)
    write_byte(RGB_COLORS[color][R]) 		// Red
    write_byte(RGB_COLORS[color][G]) 		// Green
    write_byte(RGB_COLORS[color][B])	 	// Blue
    write_byte(alpha)
    message_end()
}

stock screen_shake(id, amplitude = 10)
{
    message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_msgScreenShake, _,id)
    write_short(15*4096)
    write_short(4096*amplitude)
    write_short(200*256)
    message_end()
}

stock dynamic_light(Float:origin[3], radius = 50, RgbColor:color = COLOR_WHITE, secs = 10)
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
    write_byte(TE_DLIGHT);
    engfunc(EngFunc_WriteCoord, origin[X])
    engfunc(EngFunc_WriteCoord, origin[Y])
    engfunc(EngFunc_WriteCoord, origin[Z])
    write_byte(radius)
    write_byte(RGB_COLORS[color][R]) 		// Red
    write_byte(RGB_COLORS[color][G]) 		// Green
    write_byte(RGB_COLORS[color][B])	 	// Blue
    write_byte(secs*10);	// life * 10
    write_byte(100)
    message_end();
}