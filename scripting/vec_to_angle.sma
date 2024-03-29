/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <engine>
#include <xs>

#define PLUGIN "Nuevo Plug-in"
#define VERSION "0.1"
#define AUTHOR "Mia2904"


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("probar", "clcmd_Test");
	
	register_concmd("test", "clcmd_Test2");
}

public clcmd_Test(id)
{
	new Float:angles[3], Float:va[3], Float:pa[3];
	/*entity_get_vector(id, EV_VEC_angles, angles);
	entity_get_vector(id, EV_VEC_v_angle, va);
	entity_get_vector(id, EV_VEC_punchangle, pa);
	client_print(id, print_chat, "Angles: %.0f %.0f %.0f VAngles: %.0f %.0f %.0f PAngles: %.0f %.0f %.0f", angles[0], angles[1], angles[2], va[0], va[1], va[2], pa[0], pa[1], pa[2]);*/
	
	entity_get_vector(id, EV_VEC_velocity, pa)
	VectorAngles(pa, angles);
	vec_to_angle(pa, va);
	client_print(id, print_chat, "Angles: %.0f %.0f %.0f VAngles: %.0f %.0f %.0f", angles[0], angles[1], angles[2], va[0], va[1], va[2]);
	/*entity_set_vector(id, EV_VEC_v_angle, va);
	entity_set_vector(id, EV_VEC_angles, va);
	entity_set_vector(id, EV_VEC_punchangle, va);*/
}

public clcmd_test2()
{
	new t1[6], t2[6], t3[6];
	read_argv(1, t1, 5);
	read_argv(2, t2, 5);
	read_argv(3, t3, 5);
	
	new Float:angles[3], Float:va[3], Float:pa[3];
	xs_vec_set(pa, str_to_float(t1), str_to_float(t2), str_to_float(t3));
	VectorAngles(pa, angles);
	vec_to_angle(pa, va);
	console_print(0, "Angles: %.0f %.0f %.0f VAngles: %.0f %.0f %.0f", angles[0], angles[1], angles[2], va[0], va[1], va[2]);
}

stock vec_to_angle(Float:in[3], Float:out[3])
{
	out[0] = -floatatan(in[2]/floatsqroot(in[0]*in[0] + in[1]*in[1]), degrees);
	out[1] = floatatan(in[0]/in[1], degrees);
	if (in[0] < 0.0)
		out[1] -= 180.0;
	out[2] = 0.0;
}

stock VectorAngles(Float:vec_t[3], Float:angles[3])
{
    new Float:length, Float:yaw, Float:pitch;

    if (vec_t[1] == 0.0 && vec_t[0] == 0.0)
    {
        yaw = 0.0;
        if (vec_t[2] > 0.0)
            pitch = 90.0;
        else
            pitch = 270.0;
    }
    else
    {
        yaw = floatatan2(vec_t[1], vec_t[0], radian) * 180.0 / M_PI;
        if (yaw < 0.0)
            yaw += 360.0;

        length = floatsqroot(vec_t[0] * vec_t[0] + vec_t[1] * vec_t[1]);

        pitch = floatatan2(vec_t[2], length, radian) * 180.0 / M_PI;
        if (pitch < 0.0)
            pitch += 360.0;
    }

    angles[0] = pitch;
    angles[1] = yaw;
    angles[2] = 0.0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10250\\ f0\\ fs16 \n\\ par }
*/
