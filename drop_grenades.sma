#include <amxmodx>
#include <hamsandwich>
#include <reapi>

const WeaponIdType:WEAPON_MOLOTOV = WEAPON_GLOCK
new const ITEM_CLASSNAME[] = "weapon_molotov"
new const AMMO_NAME[] = "Molotov"
new const WEAPON_MODEL_WORLD_MOLOTOV[] = "models/grenaderad/w_molotov.mdl"

const GRENADE_WPN_BS = ((1<<_:WEAPON_HEGRENADE)|(1<<_:WEAPON_SMOKEGRENADE)|(1<<_:WEAPON_FLASHBANG))

enum {
	GRENADE_HEGRENADE,
	GRENADE_FLASHBANG,
	GRENADE_SMOKEGRENADE,
	GRENADE_MOLOTOV,
	MAX_GRENADES,
}

new g_iCvar_CanDropGrenade[MAX_GRENADES]

public plugin_init() {
	register_plugin("Drop Grenades (molotov)", "1.0.1", "fl0wer & Vaqtincha")
	
	
	
	new grenades[][] = {
		"weapon_hegrenade",
		"weapon_flashbang",
		"weapon_smokegrenade",
	}

	for (new i = 0; i < sizeof(grenades); i++) {
		RegisterHam(Ham_CS_Item_CanDrop, grenades[i], "CGrenade_Item_CanDrop_Pre", false)
	}

	RegisterHookChain(RG_CWeaponBox_SetModel, "CWeaponBox_SetModel", .post = false)
	RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "CBasePlayer_DropPlayerItem", .post = true)
	

	bind_pcvar_num(
		create_cvar(
			"amx_candrop_hegrenade", "1", _,
			"Player can drop HE grenade. (Default: 1)",
			true, 0.0,
			true, 1.0
		),
		g_iCvar_CanDropGrenade[GRENADE_HEGRENADE]
	)
	bind_pcvar_num(
		create_cvar(
			"amx_candrop_flasbang", "1", _,
			"Player can drop flashbang. (Default: 1)",
			true, 0.0,
			true, 1.0
		),
		g_iCvar_CanDropGrenade[GRENADE_FLASHBANG]
	)
	bind_pcvar_num(
		create_cvar(
			"amx_candrop_smokegrenade", "1", _,
			"Player can drop smoke grenade. (Default: 1)",
			true, 0.0,
			true, 1.0
		),
		g_iCvar_CanDropGrenade[GRENADE_SMOKEGRENADE]
	)
	bind_pcvar_num(
		create_cvar(
			"amx_candrop_molotov", "1", _,
			"Player can drop molotov grenade. (Default: 1)",
			true, 0.0,
			true, 1.0
		),
		g_iCvar_CanDropGrenade[GRENADE_MOLOTOV]
	)
	
	// fix: molotov picked up even when there is already a molotov in inventory
	const MAX_MOLOTOV_AMMO = 1
	rg_set_weapon_info(WEAPON_MOLOTOV, WI_MAX_ROUNDS, MAX_MOLOTOV_AMMO)
}

public CGrenade_Item_CanDrop_Pre(id) {
	new player = get_member(id, m_pPlayer)
	new primaryAmmoType = get_member(id, m_Weapon_iPrimaryAmmoType)
	if (get_member(player, m_rgAmmo, primaryAmmoType) <= 0) {
		return HAM_IGNORED
	}
	
	switch (get_member(id, m_iId)) {
		case WEAPON_HEGRENADE: {
			if (!g_iCvar_CanDropGrenade[GRENADE_HEGRENADE]) {
				return HAM_IGNORED
			}
		}
		case WEAPON_FLASHBANG: {
			if (!g_iCvar_CanDropGrenade[GRENADE_FLASHBANG]) {
				return HAM_IGNORED
			}
		}
		case WEAPON_SMOKEGRENADE: {
			if (!g_iCvar_CanDropGrenade[GRENADE_SMOKEGRENADE]) {
				return HAM_IGNORED
			}
		}
		case WEAPON_MOLOTOV: {
			if (!g_iCvar_CanDropGrenade[GRENADE_MOLOTOV]) {
				return HAM_IGNORED
			}
		}	
	}
	
	SetHamReturnInteger(true)
	return HAM_OVERRIDE
}

public CBasePlayer_DropPlayerItem(const pPlayer, const pszItemName[])
{
	new pWeaponBox = GetHookChainReturn(ATYPE_INTEGER)
	
	if (is_nullent(pWeaponBox))
		return
	
	new iId = _:rg_get_weaponbox_id(pWeaponBox)
	if (!(GRENADE_WPN_BS & (1<<iId)))
		return	
	
	new iBoxAmmo = get_member(pWeaponBox, m_WeaponBox_rgAmmo, 1)
	
	if (iBoxAmmo > 1)
	{
		new pWeapon = NULLENT
		switch (iId)
		{
			case WEAPON_HEGRENADE: pWeapon = give_weapon_silent(pPlayer, "weapon_hegrenade")
			case WEAPON_FLASHBANG: pWeapon = give_weapon_silent(pPlayer, "weapon_flashbang")
			case WEAPON_SMOKEGRENADE: pWeapon = give_weapon_silent(pPlayer, "weapon_smokegrenade")
		}
		
		if (pWeapon != NULLENT)
			rg_switch_weapon(pPlayer, pWeapon)
		
		rg_set_user_bpammo(pPlayer, any:iId, --iBoxAmmo)
		
		set_member(pWeaponBox, m_WeaponBox_rgAmmo, 1, 1)
	}
}

stock give_weapon_silent(const pPlayer, const szWeapon[])
{
	static gmsgWeapPickup, gmsgAmmoPickup

	if (!gmsgWeapPickup)
		gmsgWeapPickup = get_user_msgid("WeapPickup")
	if (!gmsgAmmoPickup)
		gmsgAmmoPickup = get_user_msgid("AmmoPickup")
	
	set_msg_block(gmsgWeapPickup, BLOCK_ONCE)
	set_msg_block(gmsgAmmoPickup, BLOCK_ONCE)

	new pWeapon = rg_create_entity(szWeapon, .useHashTable = true)
	
	if (is_nullent(pWeapon))
		return NULLENT

	set_entvar(pWeapon, var_spawnflags, SF_NORESPAWN)
	ExecuteHamB(Ham_Spawn, pWeapon)
	
	if (ExecuteHamB(Ham_AddPlayerItem, pPlayer, pWeapon))
	{
		ExecuteHamB(Ham_Item_AttachToPlayer, pWeapon, pPlayer)
		// emit_sound(pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		return pWeapon
	}
	
	new pOwner = get_entvar(pWeapon, var_owner)
	if (is_nullent(pOwner) || pOwner != pPlayer)
		set_entvar(pWeapon, var_flags, get_entvar(pWeapon, var_flags) | FL_KILLME)

	return NULLENT
}

public CWeaponBox_SetModel(const pWeaponBox, const szModel[])
{
	if (pWeaponBox <= 0 || szModel[0] > 0)
		return

	new pWeapon = GetWeaponBoxWeapon(pWeaponBox, ITEM_CLASSNAME, GRENADE_SLOT)
	
	if (FClassnameIs(pWeapon, ITEM_CLASSNAME) && get_member(pWeapon, m_iId) == WEAPON_MOLOTOV)
	{
		set_member(pWeaponBox, m_WeaponBox_rgiszAmmo, AMMO_NAME, 1)
		set_member(pWeaponBox, m_WeaponBox_rgAmmo, 1, 1)
		
		SetHookChainArg(2, ATYPE_STRING, WEAPON_MODEL_WORLD_MOLOTOV)
	}
}

stock GetWeaponBoxWeapon(const pWeaponBox, const classname[], const InventorySlotType:slot = NONE_SLOT)
{
	new pWeapon = get_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, slot)
	
	while (!is_nullent(pWeapon))
	{
		if (FClassnameIs(pWeapon, classname))
			return pWeapon
			
		pWeapon = get_member(pWeapon, m_pNext)
	}

	return NULLENT
}





