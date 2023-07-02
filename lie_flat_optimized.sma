#include <amxmodx>
#include <fakemeta>
#include <xs>
#include <engine>

#define PLUGIN "Lie Flat Optimized"
#define VERSION "1.1"
#define AUTHOR "Nomexous & Vaqtincha"

new const BOUNCE[] = "items/weapondrop1.wav"

public plugin_precache()
{
	precache_sound(BOUNCE)
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_touch("weaponbox", "worldspawn", "WeaponboxTouched")
	register_touch("item_battery", "worldspawn", "WeaponboxTouched")
	register_touch("assaultsuit_item", "worldspawn", "WeaponboxTouched")
	// register_touch("weaponbox", "func_breakable", "WeaponboxTouched")
}

public WeaponboxTouched(weaponbox, worldspawn)
{
	LieFlat(weaponbox)
	// return PLUGIN_HANDLED
}

LieFlat(ent)
{
	static Float:origin[3], Float:traceto[3], trace = 0, Float:fraction 

	entity_get_vector(ent, EV_VEC_origin, origin)	
	
	// We want to trace downwards 10 units.
	xs_vec_sub(origin, Float:{0.0, 0.0, 10.0}, traceto)

	engfunc(EngFunc_TraceLine, origin, traceto, IGNORE_MONSTERS|IGNORE_MISSILE, ent, trace)
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, BOUNCE, 0.25, ATTN_STATIC, 0, PITCH_NORM)

	// Most likely if the entity has the FL_ONGROUND flag, flFraction will be less than 1.0, but we need to make sure.
	get_tr2(trace, TR_flFraction, fraction)
	
	if(fraction == 1.0)
	{	
		return
	}
	// Normally, once an item is dropped, the X and Y-axis rotations (aka roll and pitch) are set to 0, making them lie "flat."
	// We find the forward vector: the direction the ent is facing before we mess with its angles.
	static Float:original_forward[3], Float:angles[3], Float:angles2[3]
	
	entity_get_vector(ent, EV_VEC_angles, angles)
	angle_vector(angles, ANGLEVECTOR_FORWARD, original_forward)
	
	// If your head was an entity, no matter which direction you face, these vectors would be sticking out of your right ear,
	// up out the top of your head, and forward out from your nose.
	static Float:right[3], Float:up[3], Float:fwd[3]
	
	// The plane's normal line will be our new ANGLEVECTOR_UP.
	get_tr2(trace, TR_vecPlaneNormal, up)
	
	// The cross product (aka vector product) will give us a vector, which is in essence our ANGLEVECTOR_RIGHT.
	xs_vec_cross(original_forward, up, right)
	// And this cross product will give us our new ANGLEVECTOR_FORWARD.
	xs_vec_cross(up, right, fwd)

	// Converts from the forward vector to angles. Unfortunately, vectors don't provide enough info to determine X-axis rotation (roll),
	// so we have to find it by pretending our right anglevector is a forward, calculating the angles, and pulling the corresponding value
	// that would be the roll.
	vector_to_angle(fwd, angles)
	vector_to_angle(right, angles2)

	// Multiply by -1 because pitch increases as we look down.
	angles[2] = -1.0 * angles2[0]
	
	// Finally, we turn our entity to lie flat.
	entity_set_vector(ent, EV_VEC_angles, angles)
}

