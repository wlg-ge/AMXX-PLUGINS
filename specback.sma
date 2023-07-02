#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <fun>

#define CHAT_PREFIX "^4[^3WLG^4]^1"
new CsTeams:csLastTeam[MAX_PLAYERS + 1];
new g_num, g_maxplayers;
new bool:WAS_ASSIGNED[33];

public plugin_init() {
	register_plugin("Spec/Back", "0.1", "WLG");
	register_clcmd("say /spec", "spec_transfer");
	register_clcmd("say_team /spec", "spec_transfer");
	register_clcmd("say /back", "back_transfer");
	register_clcmd("say_team /back", "back_transfer");
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

public playerSpawned(id) {
	WAS_ASSIGNED[id] = false;
	new sid[1];
	sid[0] = id;
	set_task(0.75, "delayedSpawn", _, sid, 1); // Give the player time to drop to the floor when spawning
	return PLUGIN_HANDLED;
}

public delayedSpawn(sid[]) {
	WAS_ASSIGNED[sid[0]] = true;
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
	set_pdata_int(id, 125, get_pdata_int(id, 125, 5) &  ~(1 << 8), 5);
	if ((cs_get_user_team(id) == CS_TEAM_SPECTATOR) && (WAS_ASSIGNED[id])) {
		cs_set_user_team(id, csLastTeam[id]);
		client_print_color(id, print_team_default, "%s You have been moved to^4 %s^1 team", CHAT_PREFIX, csLastTeam[id] == CS_TEAM_T ? "Terrorist" : "Counter-Terrorist");
	}
	if (!WAS_ASSIGNED[id]) {
		client_print_color(id, print_team_default, "%s may use < M > key for select team!", CHAT_PREFIX);
		new rand = random_num(1, 2);
		switch (rand)
		{
			case 1: {
				cs_set_user_team(id, CS_TEAM_CT); 
				engclient_cmd(id, "jointeam", "2");
				engclient_cmd(id, "joinclass", "6"); 
				give_item(id, "weapon_knife"); 
				give_item(id, "weapon_usp"); 
				give_item(id, "ammo_45acp"); 
				client_print_color(id, print_team_default, "%s You are in^4 Counter-Terrorist^1 team now", CHAT_PREFIX); 
			}
			case 2: {
				cs_set_user_team(id, CS_TEAM_T);
				engclient_cmd(id, "jointeam", "1");
				engclient_cmd(id, "joinclass", "6"); 
				give_item(id, "weapon_knife"); 
				give_item(id, "weapon_glock18"); 
				give_item(id, "ammo_9mm"); 
				client_print_color(id, print_team_default, "%s You are in^4 Terrorist^1 team now", CHAT_PREFIX); 
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
