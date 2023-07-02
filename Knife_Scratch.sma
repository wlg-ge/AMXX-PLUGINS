#include <amxmodx>
#include <fakemeta>

new decal

public plugin_init() {
    register_forward(FM_EmitSound, "forward_emit_sound")
    decal = engfunc(EngFunc_DecalIndex,"{bproof1")
    register_plugin("Knife Scratch", "1.0", "PahanCS")
}

public forward_emit_sound(id, channel, const Sound[]) {
    if(!equali(Sound, "weapons/knife_hitwall1.wav"))
        return FMRES_IGNORED
    if(!is_user_alive(id))
        return FMRES_IGNORED
    static iStart[3], iEnd[3]
    get_user_origin(id, iStart)
    get_user_origin(id, iEnd, 3)
    if((pev(id, pev_button) & IN_ATTACK || pev(id, pev_oldbuttons) & IN_ATTACK) && get_distance(iStart, iEnd) < 66) {
        static ent, body
        get_user_aiming(id, ent, body)
        create_decal(iEnd, decal, true, ent)
    }
    else if((pev(id, pev_button) & IN_ATTACK2 || pev(id, pev_oldbuttons) & IN_ATTACK2) && get_distance(iStart, iEnd) < 51) {
        static ent, body
        get_user_aiming(id, ent, body)
        create_decal(iEnd, decal, true, ent)
    }
    return FMRES_IGNORED
}

stock create_decal(iOrigin[3], decal_index, bool:create_sparks = false, entity = 0) {
    if(decal_index && !entity) {
        message_begin(MSG_ALL, SVC_TEMPENTITY)
        write_byte(TE_WORLDDECAL)
        write_coord(iOrigin[0])
        write_coord(iOrigin[1])
        write_coord(iOrigin[2])
        write_byte(decal_index)
        message_end()
    }
    else if(decal_index && !is_user_alive(entity) && pev_valid(entity)) {
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_DECAL)
        write_coord(iOrigin[0])
        write_coord(iOrigin[1])
        write_coord(iOrigin[2])
        write_byte(decal_index)
        write_short(entity)
        message_end()
    }
    if(create_sparks) {
        message_begin(MSG_ALL, SVC_TEMPENTITY)
        write_byte(TE_SPARKS)
        write_coord(iOrigin[0])
        write_coord(iOrigin[1])
        write_coord(iOrigin[2])
        message_end()
    }
    return 1
}