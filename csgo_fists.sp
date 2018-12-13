/*  SM Force Fists On Spawn
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

#define DATA "1.1"

public Plugin myinfo =
{
	name = "SM Force Fists On Spawn",
	author = "Franc1sco franug",
	description = "Force players to spawn with fists instead of knives.",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

ConVar cv_team, cv_knifeandfists;

public void OnPluginStart()
{
	cv_team = CreateConVar("sm_csgofists_team", "4", "Apply only to a team. 2 = terrorist, 3 = counter-terrorist, 4 = both.");
	cv_knifeandfists = CreateConVar("sm_csgofists_knifeandfists", "0", "Give knife and fists or just fists? 1 = both, 0 = only fists.");
	
	// Plugin only for csgo
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
		
	// hook spawn event
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // delay for don't conflict with others plugins that give weapons on spawn (?)
    CreateTimer(1.6, Timer_Delay, GetClientUserId(client));
}  

public Action Timer_Delay(Handle timer, int id)
{
	// check if client valid
	int client = GetClientOfUserId(id);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || (cv_team.IntValue < 4 && cv_team.IntValue != GetClientTeam(client)))
		return;
		
	
	int weapon, index;
	char sName[64]; 
	// clear all in the the melee slot except taser
	while((weapon = GetNextWeapon(client, index)) != -1)
	{
		GetEdictClassname(weapon, sName, sizeof(sName));
		if (StrEqual(sName, "weapon_melee") || StrEqual(sName, "weapon_knife"))
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
	
	// give fists
	int iFists = GivePlayerItem(client, "weapon_fists");
	EquipPlayerWeapon(client, iFists);
	
	if(cv_knifeandfists.BoolValue)
	{
		int knife = GivePlayerItem(client, "weapon_knife");
		EquipPlayerWeapon(client, knife); // if not then knife dropped :s
	}
}

// stock from https://forums.alliedmods.net/showthread.php?t=312551
stock int GetNextWeapon(int client, int &weaponIndex) 
{ 
    static int weaponsOffset = -1; 
    if (weaponsOffset == -1) 
        weaponsOffset = FindDataMapInfo(client, "m_hMyWeapons"); 
     
    int offset = weaponsOffset + (weaponIndex * 4); 
     
    int weapon; 
    while (weaponIndex < 48)  
    { 
        weaponIndex++; 
         
        weapon = GetEntDataEnt2(client, offset); 
         
        if (IsValidEdict(weapon))  
            return weapon; 
         
        offset += 4; 
    } 
     
    return -1; 
}  