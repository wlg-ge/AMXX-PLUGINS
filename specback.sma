#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <hamsandwich>


#define CHAT_PREFIX "^4[^1WLG^4]^1"

new CsTeams:csLastTeam[MAX_PLAYERS + 1];
new g_num, g_maxplayers;
new bool:WAS_ASSIGNED[33];

public plugin_init() {
	register_plugin("Spec/Back", "0.1", "WLG & Vaqtincha");
	register_clcmd("say /spec", "spec_transfer");
	register_clcmd("say_team /spec", "spec_transfer");
	register_clcmd("say /back", "back_transfer");
	register_clcmd("say_team /back", "back_transfer");
	register_clcmd("say /join", "back_transfer");
	register_clcmd("say_team /join", "back_transfer");	
	register_clcmd("chooseteam", "ClientCommand_ChooseTeam");
	register_event("ResetHUD", "playerSpawned", "be");
	g_maxplayers = get_maxplayers();
}

public ClientCommand_ChooseTeam(id) {
	set_pdata_int(id, 125, get_pdata_int(id, 125, 5) &  ~(1 << 8), 5);
}

public client_connect(id) {
	csLastTeam[id] = CS_TEAM_UNASSIGNED;
	WAS_ASSIGNED[id] = false;
}

const TASK_RESPAWN = 945916

public playerSpawned(id) {
	WAS_ASSIGNED[id] = false;
	// new sid[1];
	// sid[0] = id;
	set_task(0.75, "delayedSpawn", TASK_RESPAWN + id); // Give the player time to drop to the floor when spawning
	return PLUGIN_HANDLED;
}

public delayedSpawn(taskid) {
	
	new pPlayer = taskid - TASK_RESPAWN
	
	WAS_ASSIGNED[pPlayer] = true;
	// if (is_user_connected(pPlayer) && !is_user_alive(pPlayer))
		// ExecuteHamB(Ham_CS_RoundRespawn, pPlayer)
	
	return PLUGIN_HANDLED;
}

public spec_transfer(id) {
	new CsTeams:csTeam = cs_get_user_team(id);
	if (csTeam != CS_TEAM_SPECTATOR) {
		csLastTeam[id] = csTeam;
		cs_set_user_team(id, CS_TEAM_SPECTATOR);
		if (is_user_alive(id))
			user_silentkill(id, 1);
		client_print_color(id, print_team_default, "%s You have been moved to^4 Spectator^1 team", CHAT_PREFIX);
	}
	else client_print_color(id, print_team_default, "%s You are already in^4 Spectator^1 team!", CHAT_PREFIX);
	
	return PLUGIN_HANDLED;
}

public back_transfer(id) {
	
	if (CS_TEAM_T <= cs_get_user_team(id) <= CS_TEAM_CT)
	{
		client_print_color(id, print_team_red, "%s ^3Only spectators can use this command!", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}
	
	
	set_pdata_int(id, 125, get_pdata_int(id, 125, 5) &  ~(1 << 8), 5);
	
	// if (csLastTeam[id] == CS_TEAM_UNASSIGNED)
	// {
		// engclient_cmd(id, "chooseteam");
		
		// return PLUGIN_HANDLED;
	// }

	if ((cs_get_user_team(id) == CS_TEAM_SPECTATOR) && csLastTeam[id] != CS_TEAM_UNASSIGNED && (WAS_ASSIGNED[id])) {
		cs_set_user_team(id, csLastTeam[id]);
		
		// if (is_user_connected(id) && !is_user_alive(id))
			// ExecuteHamB(Ham_CS_RoundRespawn, id)
	
		if (csLastTeam[id] == CS_TEAM_T)
			client_print_color(id, print_team_red, "%s You have been moved to ^3Terrorist^1 team", CHAT_PREFIX)
		else
			client_print_color(id, print_team_blue, "%s You have been moved to ^3Counter-Terrorist^1 team", CHAT_PREFIX)
	}
	
	if (!WAS_ASSIGNED[id]) {
		client_print_color(id, print_team_default, "%s may use < M > key for select team!", CHAT_PREFIX);
		
		set_msg_block(get_user_msgid("VGUIMenu"), BLOCK_ONCE);
		// engclient_cmd(id, "jointeam", "5"); / random game function
		
		const m_iMenu = 205
		const _Menu_ChooseAppearance = 3
		// set_pdata_int(id, m_iMenu, _Menu_ChooseAppearance, 5)
		// engclient_cmd(id, "joinclass", "1")
		
		
		new rand = random_num(1, 2);
		switch (rand)
		{
			case 1: {
				// cs_set_user_team(id, CS_TEAM_CT); 
				engclient_cmd(id, "jointeam", "2");
				
				set_pdata_int(id, m_iMenu, _Menu_ChooseAppearance, 5)
				
				engclient_cmd(id, "joinclass", "5"); 
				give_item(id, "weapon_knife"); 
				give_item(id, "weapon_usp"); 
				give_item(id, "ammo_45acp"); 
				client_print_color(id, print_team_blue, "%s You are in^3 Counter-Terrorist^1 team now", CHAT_PREFIX);
				
				// ExecuteHamB(Ham_CS_RoundRespawn, id)
			}
			case 2: {
				// cs_set_user_team(id, CS_TEAM_T);
				engclient_cmd(id, "jointeam", "1");
				
				set_pdata_int(id, m_iMenu, _Menu_ChooseAppearance, 5)
				
				engclient_cmd(id, "joinclass", "5"); 
				give_item(id, "weapon_knife"); 
				give_item(id, "weapon_glock18"); 
				give_item(id, "ammo_9mm"); 
				client_print_color(id, print_team_red, "%s You are in^3 Terrorist^1 team now", CHAT_PREFIX);
				
				// ExecuteHamB(Ham_CS_RoundRespawn, id)
			}
		}
	}
	
	if (check_clients() <= 2) {
		server_cmd("sv_restartround 1");
		server_cmd("mp_autoteambalance 2");
	}
	return PLUGIN_HANDLED;
}

public check_clients() {
	new id;
	g_num = 0;
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (is_user_connected(id) && !is_user_hltv(id) && !is_user_bot(id) && (get_user_team(id) == 1 || get_user_team(id) == 2))
			g_num++;
	}
	return g_num;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 *\\ {\\ \\ rtf1\\ \\ ansi\\ \\ deff0\\ {\\ \\ fonttbl\\ {\\ \\ f0\\ \\ fnil Tahoma;\\ }\\ }\n\\ par \\ \\ viewkind4\\ \\ uc1\\ \\ pard\\ \\ lang1049\\ \\ f0\\ \\ fs16 \n\\ par \\ \\ par \\ }\n\\ par }

client_print_color(id, print_team_default, "%s use M key for select team!", CHAT_PREFIX);
set_hudmessage(255, 255, 255, -1.0, -1.0, 2, 6.0, 6.0);
show_hudmessage(id, "use < M > key for select team!");
*/
