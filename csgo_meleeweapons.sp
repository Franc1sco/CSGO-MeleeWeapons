/*  SM CS:GO Spawn With Melee Weapons
 *
 *  Copyright (C) 2018 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define DATA "2.1"

public Plugin myinfo =
{
	name = "SM CS:GO Spawn With Melee Weapons",
	author = "Franc1sco franug",
	description = "Force players to spawn different melee weapons",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

ConVar cv_team;
ConVar cv_fists;
ConVar cv_knife;
ConVar cv_axe;
ConVar cv_hammer;
ConVar cv_spanner;
ConVar cv_blockattack2;
ConVar cv_wtimer;

int g_iTeam;
int g_bFists;
int g_bKnife;
int g_bAxe;
int g_bHammer;
int g_bSpanner;
int g_bBlockAttack2;
float g_fTimer;

public void OnPluginStart()
{
	CreateConVar("sm_csgomeleeweapons_version", DATA, "Plugin Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cv_team = CreateConVar("sm_csgomeleeweapons_team", "4", "Apply only to a team. 2 = terrorist, 3 = counter-terrorist, 4 = both.", 0, true, 0.0, true, 4.0);
	cv_fists = CreateConVar("sm_csgomeleeweapons_fists", "1", "Give fists? 1 = yes, 0 = no.", 0, true, 0.0, true, 1.0);
	cv_knife = CreateConVar("sm_csgomeleeweapons_knife", "1", "Give knife? 1 = yes, 0 = no.", 0, true, 0.0, true, 1.0);
	cv_axe = CreateConVar("sm_csgomeleeweapons_axe", "0", "Give axe on spawn? 1 = yes, 0 = no.", 0, true, 0.0, true, 1.0);
	cv_hammer = CreateConVar("sm_csgomeleeweapons_hammer", "0", "Give hammer on spawn? 1 = yes, 0 = no.", 0, true, 0.0, true, 1.0);
	cv_spanner = CreateConVar("sm_csgomeleeweapons_spanner", "0", "Give spanner on spawn? 1 = yes, 0 = no.", 0, true, 0.0, true, 1.0);
	cv_blockattack2 = CreateConVar("sm_csgomeleeweapons_blockattack2", "1", "Block right click? 1 = yes, 0 = no.", 0, true, 0.0, true, 1.0);
	cv_wtimer = CreateConVar("sm_csgomeleeweapons_timer", "1.6", "Time in seconds after spawn to give melee weapons.", 0, true, 0.0);
	
	g_iTeam = GetConVarInt(cv_team);
	g_bFists = GetConVarInt(cv_fists);
	g_bKnife = GetConVarInt(cv_knife);
	g_bAxe = GetConVarInt(cv_axe);
	g_bHammer = GetConVarInt(cv_hammer);
	g_bSpanner = GetConVarInt(cv_spanner);
	g_bBlockAttack2 = GetConVarInt(cv_blockattack2);
	g_fTimer = GetConVarFloat(cv_wtimer);
	
	HookConVarChange(cv_team, OnConVarChanged);
	HookConVarChange(cv_fists, OnConVarChanged);
	HookConVarChange(cv_knife, OnConVarChanged);
	HookConVarChange(cv_axe, OnConVarChanged);
	HookConVarChange(cv_hammer, OnConVarChanged);
	HookConVarChange(cv_spanner, OnConVarChanged);
	HookConVarChange(cv_blockattack2, OnConVarChanged);
	HookConVarChange(cv_wtimer, OnConVarChanged);
	
	// Plugin only for csgo
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
		
	// hook spawn event
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	AutoExecConfig(true, "csgo_melee_weapons");
}

public void OnConVarChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	if (convar == cv_team) {
		g_iTeam = StringToInt(newVal);
	} else if (convar == cv_fists) {
		g_bFists = StringToInt(newVal);
	} else if (convar == cv_knife) {
		g_bKnife = StringToInt(newVal);
	} else if (convar == cv_axe) {
		g_bAxe = StringToInt(newVal);
	} else if (convar == cv_hammer) {
		g_bHammer = StringToInt(newVal);
	} else if (convar == cv_spanner) {
		g_bSpanner = StringToInt(newVal);
	} else if (convar == cv_blockattack2) {
		g_bBlockAttack2 = StringToInt(newVal);
	} else if (convar == cv_wtimer) {
		g_fTimer = StringToFloat(newVal);
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // delay for don't conflict with others plugins that give weapons on spawn (?)
    CreateTimer(g_fTimer, Timer_Delay, GetClientUserId(client));
}  

public Action Timer_Delay(Handle timer, int id)
{
	// check if client valid
	int client = GetClientOfUserId(id);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || (g_iTeam < 4 && g_iTeam != GetClientTeam(client)))
		return;
			
	// remove all the weapons on "melee slot" in order to prevent the bug of duplicated fists
	int weapon;
	while((weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != -1)
	{
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
	
	int iMelee;
	
	//Fists
	if (g_bFists)
	{
		iMelee = GivePlayerItem(client, "weapon_fists");
		EquipPlayerWeapon(client, iMelee);
	}
	
	if (g_bAxe)
	{
		iMelee = GivePlayerItem(client, "weapon_axe");
		EquipPlayerWeapon(client, iMelee);
	}
	
	if (g_bHammer)
	{
		iMelee = GivePlayerItem(client, "weapon_hammer");
		EquipPlayerWeapon(client, iMelee);
	}
	
	if (g_bSpanner)
	{
		iMelee = GivePlayerItem(client, "weapon_spanner");
		EquipPlayerWeapon(client, iMelee);
	}
	
	if (g_bKnife)
	{
		iMelee = GivePlayerItem(client, "weapon_knife");
		EquipPlayerWeapon(client, iMelee); // if not then knife dropped :s
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!g_bBlockAttack2)
	{
		return Plugin_Continue;
	}
	
	//Client is not valid
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if (g_iTeam < 4 && g_iTeam != GetClientTeam(client))
	{
		return Plugin_Continue;
	}
	
	//Attempting to use right click
	if (buttons & IN_ATTACK2)
	{
		char buffer[128];
		
		int item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		GetEntityClassname(item, buffer, sizeof(buffer));
		
		if (StrEqual(buffer, "weapon_fists", false) || StrEqual(buffer, "weapon_axe", false) || StrEqual(buffer, "weapon_hammer", false) || StrEqual(buffer, "weapon_spanner", false))
		{
			buttons &= ~IN_ATTACK2; //Don't press attack 2
			return Plugin_Changed;
		}		
	}
	
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if ((client <= 0) || (client > MaxClients)) {
		return false;
	}
	if (!IsClientInGame(client)) {
		return false;
	}
	return true;
}