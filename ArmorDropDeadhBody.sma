// Copyright © 2023 Vaqtincha

#include <amxmodx>
#include <fakemeta>
#include <reapi>


#define PL_VERSION  	"0.1"

new const KEVLAR_MODEL_DEF[] = "models/w_kevlar.mdl"
new const VESTHELM_MODEL_DEF[] = "models/w_assault.mdl"

new const ITEM_CLASSNAME[] = "item_battery"
new const CUSTOM_ITEM[] = "assaultsuit_item"

new gmsgArmorType

public plugin_precache()
{
	precache_model("models/w_battery.mdl")
	precache_model(KEVLAR_MODEL_DEF)
	precache_model(VESTHELM_MODEL_DEF)
}

public plugin_init()
{
	register_plugin("Drop Armor Dead Body", PL_VERSION, "Vaqtincha")

	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound", .post = true)
	RegisterHookChain(RG_CSGameRules_PlayerKilled, "CSGameRules_PlayerKilled", .post = true) // bomb kill ignore

	register_event_ex("ItemPickup", "Event_ItemPickupHelmet", RegisterEvent_Single | RegisterEvent_OnlyAlive | RegisterEvent_OnlyHuman, fmt("1=%s", CUSTOM_ITEM))
	
	gmsgArmorType = get_user_msgid("ArmorType")	
}

public Event_ItemPickupHelmet(const pPlayer)
{
	set_member(pPlayer, m_iKevlar, ARMOR_VESTHELM)
	
	message_begin(MSG_ONE, gmsgArmorType, .player = pPlayer)
	write_byte(1)	// 0 = ARMOR_KEVLAR, 1 = ARMOR_VESTHELM
	message_end()
}

public CSGameRules_RestartRound()
{
	CleanClass(ITEM_CLASSNAME)
	CleanClass(CUSTOM_ITEM)
}


public CSGameRules_PlayerKilled(const pPlayer, const pevKiller, const pevInflictor)
{
	CreateArmor(pPlayer)
}

public KillThink(const pEntity)
{
	if (!is_nullent(pEntity))
	{
		RemoveEnt(pEntity)
	}
}


CreateArmor(pPlayer)
{
	new ArmorType:iArmorType
	new iArmor = rg_get_user_armor(pPlayer, iArmorType)

	if (iArmor <= 0 || iArmorType == ARMOR_NONE)
        return NULLENT
	
	new Float:vecOrigin[3]
	get_entvar(pPlayer, var_origin, vecOrigin)
	vecOrigin[2] += 32.0
	
	new pEntity = rg_create_entity(ITEM_CLASSNAME)

	if (!is_nullent(pEntity))
	{
		set_entvar(pEntity, var_spawnflags, get_entvar(pEntity, var_spawnflags) | SF_NORESPAWN)		
		engfunc(EngFunc_SetOrigin, pEntity, vecOrigin)
		dllfunc(DLLFunc_Spawn, pEntity)
		
		if (iArmorType == ARMOR_VESTHELM)
			set_entvar(pEntity, var_classname, CUSTOM_ITEM) // hackhack

		engfunc(EngFunc_SetModel, pEntity, iArmorType == ARMOR_KEVLAR ? KEVLAR_MODEL_DEF : VESTHELM_MODEL_DEF)

		set_entvar(pEntity, var_owner, pPlayer)
		set_entvar(pEntity, var_armorvalue, float(iArmor))
		
		// engfunc(EngFunc_SetSize, pEntity, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 16.0})
		// engfunc(EngFunc_DropToFloor, pEntity)

		SetThink(pEntity, "KillThink")
		set_entvar(pEntity, var_nextthink, get_gametime() + get_cvar_float("mp_item_staytime"))
		
		return pEntity
	}

	return NULLENT
}

CleanClass(const class[])
{
	new pEntity = NULLENT
	
	while ((pEntity = rg_find_ent_by_class(pEntity, class)))
	{
		if (get_entvar(pEntity, var_owner) > 0 || get_entvar(pEntity, var_spawnflags) & SF_NORESPAWN) // custom items
		{
			RemoveEnt(pEntity)
		}
	}
	
}

RemoveEnt(const pEntity)
{
	SetThink(pEntity, "")
	set_entvar(pEntity, var_nextthink, -1.0)
	engfunc(EngFunc_RemoveEntity, pEntity)
	// set_entvar(pEntity, var_flags, FL_KILLME)
}
