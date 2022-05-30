#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include "kodinc.sp"

#pragma newdecls required


bool IsTarget[MAXPLAYERS + 1];
ConVar cankillteammate;
public Plugin myinfo =
{
	name = "Block Taser Death Sound",
	author = "F0rest",
	description = "Block death sound when player get killed by taser",
	version = "1.0",
	url = "https://kodplay.com",
}

public void OnPluginStart()
{
	//HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	AddNormalSoundHook(OnNormalSoundPlayed);
	cankillteammate = CreateConVar("ds_tk", "0", _, _, true, 0.0, true, 1.0);
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		IsTarget[client] = false;
	}
}

public Action OnNormalSoundPlayed(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{

	if(channel != SNDCHAN_VOICE || sample[0] != '~')
		return Plugin_Continue;

	if(!IsValidClient(client))
		return Plugin_Continue;
		
	if (StrContains(soundEntry, "death", false) == 0 && IsTarget[client])
	{
		IsTarget[client] = false;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action OnTakeDamage (int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!IsValidClient(victim) || !IsValidClient(attacker))
	{
		return Plugin_Continue;
	}
	if(!IsValidEntity(weapon)|| weapon < 0)
		return Plugin_Continue;
	char sWeapon[64];
	if(!GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)))
		return Plugin_Continue;
	if(StrContains(sWeapon,"taser") != -1)
	{	
		if(GetClientTeam(victim) == GetClientTeam(attacker) && !cankillteammate.BoolValue)
			return Plugin_Continue;
		int iDamage = RoundToZero(damage);
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");
		if(iDamage < health)
			return Plugin_Continue;
		else
		{
			IsTarget[victim] = true;
			SetEntProp(attacker, Prop_Send, "m_iAccount", GetEntProp(attacker, Prop_Send, "m_iAccount") + 800);
			//ForcePlayerSuicide(victim);
			SetEntProp(victim, Prop_Send, "m_ArmorValue", 0);
			SetEntityHealth(victim, 1);
			SDKHooks_TakeDamage(victim, attacker, attacker, damage, damagetype, _, damageForce , damagePosition);
			CreateDeathEvent(victim, attacker);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
/*
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsTarget[victim])
	{
		SetEventBroadcast(event, true);
	}
}
*/
public void CreateDeathEvent(int victim, int attacker)
{
	Event event = CreateEvent("player_death");
	event.SetInt("userid", GetClientUserId(victim));
	event.SetInt("attacker", GetClientUserId(attacker)); 
	event.SetString("weapon", "weapon_taser");
	event.SetBool("headshot", false);
	
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			event.FireToClient(i);
		}
	}
	
	//delete event;
}