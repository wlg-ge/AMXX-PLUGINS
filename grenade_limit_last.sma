// Copyright © 2023 Vaqtincha

/*■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG START ■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#define HEGRENADE_MAX_AMMO 2
#define FLASHBANG_MAX_AMMO 2
#define SMOKEGRENADE_MAX_AMMO 2

/*■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG END ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#include <amxmodx>
#include <hamsandwich>

public plugin_precache()
{
	register_plugin("Grenade Limit", "0.2", "Vaqtincha")
	
	RegisterHam(Ham_Item_GetItemInfo, "weapon_hegrenade", "CBasePlayerItem_GetItemInfo", .Post = true)
	RegisterHam(Ham_Item_GetItemInfo, "weapon_smokegrenade", "CBasePlayerItem_GetItemInfo", .Post = true)
	RegisterHam(Ham_Item_GetItemInfo, "weapon_flashbang", "CBasePlayerItem_GetItemInfo", .Post = true)
}

public CBasePlayerItem_GetItemInfo(const pItem, const iItemInfo) 
{
	switch(GetHamItemInfo(iItemInfo, Ham_ItemInfo_iId))
	{
		case CSW_HEGRENADE: SetHamItemInfo(iItemInfo, Ham_ItemInfo_iMaxAmmo1, HEGRENADE_MAX_AMMO)
		case CSW_FLASHBANG: SetHamItemInfo(iItemInfo, Ham_ItemInfo_iMaxAmmo1, FLASHBANG_MAX_AMMO)
		case CSW_SMOKEGRENADE: SetHamItemInfo(iItemInfo, Ham_ItemInfo_iMaxAmmo1, SMOKEGRENADE_MAX_AMMO)
	}
}

