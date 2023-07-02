// Copyright © 2023 Vaqtincha

// #define DEMO_MODE


#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>



const any:GRENADE_BITS = ( (1 << _:WEAPON_HEGRENADE) | (1 << _:WEAPON_SMOKEGRENADE) | (1 << _:WEAPON_FLASHBANG) ) 
const any:ARMOURY_GRENADE_BITS = ( (1 << _:ARMOURY_HEGRENADE) | (1 << _:ARMOURY_SMOKEGRENADE) | (1 << _:ARMOURY_FLASHBANG) ) 
	
const m_pfnThink = 4
const m_pfnTouch = 5

new m_usCreateSmoke
new m_usCreateExplosion


new BounceTouch_GameDLLFunc
new TumbleThink_GameDLLFunc
new SG_TumbleThink_GameDLLFunc
new HookChain:g_hThrowGrenade


public plugin_init()
{
	register_plugin("Shoot Nades", "0.2", "Vaqtincha")
	
	RegisterHookChain(RG_IsPenetrableEntity, "IsPenetrableEntity", .post = true)
	RegisterHookChain(RG_CBaseEntity_FireBuckshots, "CBaseEntity_FireBuckshots", .post = true)
	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "CBasePlayer_ThrowGrenadeP", .post = true)
	g_hThrowGrenade = RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "CBasePlayer_ThrowGrenade", .post = false)
	
	
	m_usCreateSmoke = engfunc(EngFunc_PrecacheEvent, 1, "events/createsmoke.sc")
	m_usCreateExplosion = engfunc(EngFunc_PrecacheEvent, 1, "events/createexplo.sc")
}

GiveAndThrow(pPlayer, grenade[])
{
	set_msg_block(get_user_msgid("WeapPickup"), BLOCK_ONCE)
	set_msg_block(get_user_msgid("AmmoPickup"), BLOCK_ONCE)
	
	new pWeapon = rg_give_custom_item(pPlayer, grenade, .uid = 121212)
	
	if (!is_nullent(pWeapon))
	{
		rg_switch_weapon(pPlayer, pWeapon)
		set_member(pWeapon, m_flStartThrow, get_gametime())
		set_member(pWeapon, m_Weapon_flTimeWeaponIdle, 0.0)
		ExecuteHam(Ham_Weapon_WeaponIdle, pWeapon)
		ExecuteHam(Ham_Weapon_RetireWeapon, pWeapon)
		
		ExecuteHam(Ham_RemovePlayerItem, pPlayer, pWeapon)
	}
	
}


public CBasePlayer_ThrowGrenade(const pPlayer, const pWeapon, Float:vecSrc[3], Float:vecThrow[3], Float:time, const usEvent)
{
	if (SG_TumbleThink_GameDLLFunc && TumbleThink_GameDLLFunc)
	{
		DisableHookChain(g_hThrowGrenade)
	}
	else
	{
		if (!is_nullent(pWeapon) && get_entvar(pWeapon, var_impulse) == 121212)
		{
			vecSrc[0] = 0.0
			vecSrc[1] = 0.0
			vecSrc[2] = 0.0
			SetHookChainArg(6, ATYPE_INTEGER, 0)
			SetHookChainArg(5, ATYPE_FLOAT, get_gametime() + 999999.0)
		}
	}
}

public CBasePlayer_ThrowGrenadeP(const pPlayer, const pWeapon, Float:vecSrc[3], Float:vecThrow[3], Float:time, const usEvent)
{
	if (SG_TumbleThink_GameDLLFunc && TumbleThink_GameDLLFunc)
	{
		DisableHookChain(g_hThrowGrenade)
	}

	if (is_nullent(pWeapon))
		return
	
	new pGrenade = GetHookChainReturn(ATYPE_INTEGER)

	if (!is_nullent(pGrenade))
	{
		if (!BounceTouch_GameDLLFunc)
		{
			BounceTouch_GameDLLFunc = get_pdata_int(pGrenade, m_pfnTouch, 1)
			// server_print("BounceTouch_GameDLLFunc %i", BounceTouch_GameDLLFunc)
		}
		
		if (get_member(pWeapon, m_iId) == WEAPON_SMOKEGRENADE)
		{
			if (!SG_TumbleThink_GameDLLFunc)
			{
				SG_TumbleThink_GameDLLFunc = get_pdata_int(pGrenade, m_pfnThink, 0)
				// server_print("SG_TumbleThink_GameDLLFunc %i", SG_TumbleThink_GameDLLFunc)
			}
		}
		else
		{
			if (!TumbleThink_GameDLLFunc)
			{
				TumbleThink_GameDLLFunc = get_pdata_int(pGrenade, m_pfnThink, 0)
				// server_print("TumbleThink_GameDLLFunc %i", TumbleThink_GameDLLFunc)
			}	
		}

#if defined DEMO_MODE
		set_entvar(pGrenade, var_gravity, 0.01)
		
		new Float:velocity[3]
		get_entvar(pGrenade, var_velocity, velocity)
		
		for (new i; i < 3; i++)
			velocity[i] *= 0.2
		
		set_entvar(pGrenade, var_velocity, velocity)
		set_entvar(pGrenade, var_dmgtime, get_gametime() + 99999.0)
		
#endif
	}

}

public CBaseEntity_FireBuckshots(pWeapon, cShots, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread[3], Float:flDistance, iTracerFreq, iDamage, pevAttacker)
{
	new trace = create_tr2()
	new Float:vecEnd[3], Float:vecOrigin[3]
	new pEntity = NULLENT	
	new any:iGrenadeId
	
	velocity_by_aim(pevAttacker, floatround(flDistance), vecEnd)
	
	for (new i; i < 3; i++)
		vecEnd[i] = vecSrc[i] + vecEnd[i]
		
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, pevAttacker, 0)
	get_tr2(0, TR_vecEndPos, vecEnd)

	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecEnd, 18.0)))
	{
		if (FClassnameIs(pEntity, "weaponbox"))
		{
			iGrenadeId = rg_get_weaponbox_id(pEntity)

			if (!(GRENADE_BITS & (1 << any:iGrenadeId)))
				continue
		
			engfunc(EngFunc_TraceModel, vecSrc, vecEnd, HULL_POINT, pEntity, trace)
		
			if (get_tr2(trace, TR_pHit) == pEntity)
			{
				get_entvar(pEntity, var_origin, vecOrigin)
			
				if (ExplodeGrenade(pevAttacker, vecOrigin, iGrenadeId, false))
				{
					set_entvar(pEntity, var_nextthink, get_gametime() + 0.1)
					
					break
				}
			}
		}
		else if (FClassnameIs(pEntity, "armoury_entity"))
		{
			if (get_entvar(pEntity, var_effects) & EF_NODRAW)
				continue
	
			iGrenadeId = get_member(pEntity, m_Armoury_iItem)
		
			if (!(ARMOURY_GRENADE_BITS & (1 << any:iGrenadeId)))
				continue

			engfunc(EngFunc_TraceModel, vecSrc, vecEnd, HULL_POINT, pEntity, trace)
			
			if (get_tr2(trace, TR_pHit) == pEntity)
			{
				get_entvar(pEntity, var_origin, vecOrigin)
					
				if (ExplodeGrenade(pevAttacker, vecOrigin, iGrenadeId, true))
				{
					set_entvar(pEntity, var_effects, get_entvar(pEntity, var_effects) | EF_NODRAW)
					set_entvar(pEntity, var_solid, SOLID_NOT)
					
					set_member(pEntity, m_Armoury_iCount, 0)

					break
				}
			}
		}
	}
	
	free_tr2(trace)
}



public IsPenetrableEntity(const Float:vecStart[3], const Float:vecEnd[3], const pAttacker, const pHit)
{
	new trace = create_tr2()
	new any:iGrenadeId
	
	// shoot fly grenades

/* 	new pGrenade = NULLENT	
	while ((pGrenade = rg_find_ent_by_class(pGrenade, "grenade")))
	{
		iGrenadeId = GetGrenadeType(pGrenade)

		if (iGrenadeId == WEAPON_C4)
			continue
		
		engfunc(EngFunc_TraceModel, vecStart, vecEnd, HULL_POINT, pGrenade, trace)
		
		if (get_tr2(trace, TR_pHit) == pGrenade)
		{
			if (iGrenadeId == WEAPON_SMOKEGRENADE)
			{
				 // set_member(pGrenade, m_Grenade_iBounceCount, 11)
				set_entvar(pGrenade, var_flags, get_entvar(pGrenade, var_flags) | FL_ONGROUND)
			}

			set_entvar(pGrenade, var_dmgtime, 0.0)
			ExecuteHam(Ham_Think, pGrenade)
			break
		}
	}
	 */
	 
	 
	// shoot floor grenades
	
	new pWeaponBox = NULLENT

	while ((pWeaponBox = rg_find_ent_by_class(pWeaponBox, "weaponbox")))
	{
		iGrenadeId = rg_get_weaponbox_id(pWeaponBox)

		if (!(GRENADE_BITS & (1 << any:iGrenadeId)))
			continue
		
		engfunc(EngFunc_TraceModel, vecStart, vecEnd, HULL_POINT, pWeaponBox, trace)
		
		if (get_tr2(trace, TR_pHit) == pWeaponBox)
		{
			new Float:vecOrigin[3]
			get_entvar(pWeaponBox, var_origin, vecOrigin)
			
			if (ExplodeGrenade(pAttacker, vecOrigin, iGrenadeId, false))
			{
				set_entvar(pWeaponBox, var_nextthink, get_gametime() + 0.1)
				
				break
			}
		}

	}
	
	new pArmoury = NULLENT

	while ((pArmoury = rg_find_ent_by_class(pArmoury, "armoury_entity")))
	{
		if (get_entvar(pArmoury, var_effects) & EF_NODRAW)
			continue
	
		iGrenadeId = get_member(pArmoury, m_Armoury_iItem)
	
		if (!(ARMOURY_GRENADE_BITS & (1 << any:iGrenadeId)))
			continue

		engfunc(EngFunc_TraceModel, vecStart, vecEnd, HULL_POINT, pArmoury, trace)
		
		if (get_tr2(trace, TR_pHit) == pArmoury)
		{
			new Float:vecOrigin[3]
			get_entvar(pArmoury, var_origin, vecOrigin)
				
			if (ExplodeGrenade(pAttacker, vecOrigin, iGrenadeId, true))
			{
				set_entvar(pArmoury, var_effects, get_entvar(pArmoury, var_effects) | EF_NODRAW)
				set_entvar(pArmoury, var_solid, SOLID_NOT)
				
				set_member(pArmoury, m_Armoury_iCount, 0)

				break
			}
		}
	}
	
	free_tr2(trace)
}

ExplodeGrenade(const pPlayer, Float:vecOrigin[3], const any:iGrenadeType, bool:armoury)
{
	new pGrenade = rg_create_entity("grenade")

	if (is_nullent(pGrenade))
		return false
	
	new bool:exploded

	ExecuteHam(Ham_Spawn, pGrenade)
	
	vecOrigin[2] += 25.0
	engfunc(EngFunc_SetOrigin, pGrenade, vecOrigin)
	
	set_member(pGrenade, m_Grenade_bJustBlew, true)
	
	set_entvar(pGrenade, var_owner, pPlayer)
	set_entvar(pGrenade, var_effects, EF_NODRAW)
	set_entvar(pGrenade, var_velocity, Float:{0.0, 0.0, 0.0})
	
	set_entvar(pGrenade, var_dmgtime, get_gametime() + 0.1)

	if (BounceTouch_GameDLLFunc)
		 set_pdata_int(pGrenade, m_pfnTouch, BounceTouch_GameDLLFunc, 1)
	 
	if (iGrenadeType == armoury ? (any:ARMOURY_HEGRENADE) : (any:WEAPON_HEGRENADE)) // WEAPON_HEGRENADE = 4 // ARMOURY_HEGRENADE = 15
	{
		if (TumbleThink_GameDLLFunc)
		{
			// engfunc(EngFunc_SetModel, pGrenade, "models/w_hegrenade.mdl")
			
			set_member(pGrenade, m_Grenade_usEvent, m_usCreateExplosion)
			set_member(pGrenade, m_Grenade_iTeam, get_member(pPlayer, m_iTeam))
				
			set_entvar(pGrenade, var_dmg, 100.0)
				
			set_pdata_int(pGrenade, m_pfnThink, TumbleThink_GameDLLFunc, 0)
			
			exploded = true
		}
		else
			GiveAndThrow(pPlayer, "weapon_hegrenade")
	}
	else if (iGrenadeType == armoury ? (any:ARMOURY_FLASHBANG) : (any:WEAPON_FLASHBANG)) // WEAPON_FLASHBANG = 25 // ARMOURY_FLASHBANG = 14
	{
		if (TumbleThink_GameDLLFunc)
		{
			// engfunc(EngFunc_SetModel, pGrenade, "models/w_flashbang.mdl")
			
			set_entvar(pGrenade, var_dmg, 35.0)
			
			set_pdata_int(pGrenade, m_pfnThink, TumbleThink_GameDLLFunc, 0)
				
			exploded = true
		}
		else
			GiveAndThrow(pPlayer, "weapon_hegrenade")
	}
	else if (iGrenadeType == armoury ? (any:ARMOURY_SMOKEGRENADE) : (any:WEAPON_SMOKEGRENADE)) // WEAPON_SMOKEGRENADE = 9 // ARMOURY_SMOKEGRENADE = 18
	{
		if (SG_TumbleThink_GameDLLFunc)
		{
			// engfunc(EngFunc_SetModel, pGrenade, "models/w_smokegrenade.mdl")
			set_member(pGrenade, m_Grenade_usEvent, m_usCreateSmoke)
			set_member(pGrenade, m_Grenade_bLightSmoke, false)
			set_member(pGrenade, m_Grenade_bDetonated, false)
			set_member(pGrenade, m_Grenade_SGSmoke, 0)
			
			set_entvar(pGrenade, var_flags, get_entvar(pGrenade, var_flags) | FL_ONGROUND)
				
			set_entvar(pGrenade, var_dmgtime, 0.0)
			set_entvar(pGrenade, var_dmg, 35.0)

			set_pdata_int(pGrenade, m_pfnThink, SG_TumbleThink_GameDLLFunc, 0)
				
			exploded = true
			
			ExecuteHam(Ham_Think, pGrenade)
		}
		else
			GiveAndThrow(pPlayer, "weapon_smokegrenade")
	}
	
	set_entvar(pGrenade, var_nextthink, get_gametime() + 0.05)
	
	return exploded
}




