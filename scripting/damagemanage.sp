#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <multicolors>

#pragma newdecls required

#define PLUGIN_VERSION "2.0.0"

public Plugin myinfo = 
{
	name = "[TF2/ANY?] Damage Management",
	author = "Whai",
	description = "Manage the damage",
	version = PLUGIN_VERSION,
	url = ""
}

////////////////////////***DEBUG***////////////////////////
#define DEBUG 0
////////////////////////////////////////////////////////////////////

////Games////
bool		bIsTF2/*, 
		*/;

////////////////////

float		fDamageMult[MAXPLAYERS+1], 
		fDamageAdd[MAXPLAYERS+1], 
		fWeakDamageMult[MAXPLAYERS+1], 
		fWeakDamageAdd[MAXPLAYERS+1];
		
bool		bDamageMult[MAXPLAYERS+1], 
		bDamageAdd[MAXPLAYERS+1], 
		bWeakDamageMult[MAXPLAYERS+1], 
		bWeakDamageAdd[MAXPLAYERS+1];

//*******ConVars*******//

ConVar	hEnable,
		hDefaultDamageMult,
		hDefaultWeakDamageMult, 
		hEnableNegativeDamage;

bool		bEnable, 
		bEnableNegativeDamage;		

float		fDefaultDamageMult = 1.0,
		fDefaultWeakDamageMult = 1.0;
		
//*********************//

StringMap	WeaponDamageMult,
			WeaponDamageAdd;

public void OnPluginStart()
{
	RegisterCmds();
	RegisterCvars();
	
	CheckGames();
	
	LoadTranslations("common.phrases");
	
	for(int iClient; iClient <= MaxClients; iClient++)
		if(IsValidClient(iClient))
			OnClientPutInServer(iClient);
			
	if(bIsTF2)
	{
		int iEnt = -1, iBuildings = -1;
		#if DEBUG
		int iBuildingCount, iTankCount;
		#endif
		while((iBuildings = FindEntityByClassname(iBuildings, "obj_*")) != INVALID_ENT_REFERENCE)
		{
			SDKHook(iBuildings, SDKHook_OnTakeDamage, OnPropTakeDamage);
			#if DEBUG
			iBuildingCount++;
			#endif
		}
		while((iEnt = FindEntityByClassname(iEnt, "tank_boss")) != INVALID_ENT_REFERENCE)
		{
			SDKHook(iEnt, SDKHook_OnTakeDamage, OnPropTakeDamage);
			#if DEBUG
			iTankCount++;
			#endif
		}
		
		#if DEBUG
		if(iTankCount || iBuildingCount)
		{
			if(iBuildingCount)
				PrintToChatAll("[SM] Building%s detected ! (%i)", (iBuildingCount > 1 ? "s" : ""), iBuildingCount);
				
			if(iTankCount)
				PrintToChatAll("[SM] Tank%s detected ! (%i)", (iTankCount > 1 ? "s" : ""), iTankCount);
		}
		#endif
	}
}

void RegisterCmds()
{

//-------------------------------------------------- PLAYER ---------------------------------------------//

	/////////////////////////////////////////////////--DAMAGE ADDITIONNAL--//////////////////////////////////////////////
	
	RegAdminCmd("sm_dmgadd", Command_DamageAdd, ADMFLAG_SLAY, "Add damage did of a player");
	RegAdminCmd("sm_dmgweakadd", Command_DamageWeakAdd, ADMFLAG_SLAY, "Add the damage received of a player");
	
	RegAdminCmd("sm_dmgresetadd", Command_DamageResetAdd, ADMFLAG_SLAY, "Reset the damage additionnal did of a player");
	RegAdminCmd("sm_dmgweakresetadd", Command_DamageWeakResetAdd, ADMFLAG_SLAY, "Reset the damage additionnal received of a player");
	RegAdminCmd("sm_dmgresetalladd", Command_DamageResetAllAdd, ADMFLAG_SLAY, "Reset All damage (did or received) additionnal of a player");
	
	RegAdminCmd("sm_getdmgadd", Command_GetDamageAdd, ADMFLAG_SLAY, "Get the damage additionnal did of a player");
	RegAdminCmd("sm_getdmgweakadd", Command_GetDamageWeakAdd, ADMFLAG_SLAY, "Get the damage additionnal received of a player");

	//////////////////////////////////////////////--DAMAGE MULTIPLIER--/////////////////////////////////////////////////
	
	RegAdminCmd("sm_dmgmult", Command_DamageMult, ADMFLAG_SLAY, "Multiply the damage did of a player");
	RegAdminCmd("sm_dmgweakmult", Command_DamageWeakMult, ADMFLAG_SLAY, "Multiply the damage received of a player");
	
	RegAdminCmd("sm_dmgresetmult", Command_DamageResetMult, ADMFLAG_SLAY, "Reset the damage multiplier did of a player");
	RegAdminCmd("sm_dmgweakresetmult", Command_DamageWeakResetMult, ADMFLAG_SLAY, "Reset the damage multiplier received of a player");
	RegAdminCmd("sm_dmgresetallmult", Command_DamageResetAllMult, ADMFLAG_SLAY, "Reset All damage (did or received) multiplier of a player");
	
	RegAdminCmd("sm_getdmgmult", Command_GetDamageMult, ADMFLAG_SLAY, "Get the damage multiplier did of a player");
	RegAdminCmd("sm_getdmgweakmult", Command_GetDamageWeakMult, ADMFLAG_SLAY, "Get the damage multiplier received of a player");
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	RegAdminCmd("sm_dmgresetall", Command_DamageResetAll, ADMFLAG_SLAY, "Reset All damage (did or received) multiplier/additionnal of a player");
	
//------------------------------------------------------ WEAPON ----------------------------------------------//
	
	////////////////////////////////////////////--DAMAGE ADDITIONNAL--///////////////////////////////////////////////
	
	RegAdminCmd("sm_dmgweaponadd", Command_DamageWeaponAdd, ADMFLAG_SLAY, "Add damage of a weapon");
	
	RegAdminCmd("sm_dmgweaponresetadd", Command_DamageWeaponResetAdd, ADMFLAG_SLAY, "Reset the damage additionnal of a weapon");
	RegAdminCmd("sm_dmgweaponresetalladd", Command_DamageWeaponResetAllAdd, ADMFLAG_SLAY, "Reset the damage additionnal of all weapons");
	
	RegAdminCmd("sm_getdmgweaponadd", Command_GetDamageWeaponAdd, ADMFLAG_SLAY, "Get the damage additionnal of a weapon");
	
	/////////////////////////////////////////////--DAMAGE MULTIPLIER--////////////////////////////////////////////////
	
	RegAdminCmd("sm_dmgweaponmult", Command_DamageWeaponMult, ADMFLAG_SLAY, "Multiply the damage of a weapon");
	
	RegAdminCmd("sm_dmgweaponresetmult", Command_DamageWeaponResetMult, ADMFLAG_SLAY, "Reset the damage multiplier of a weapon");
	RegAdminCmd("sm_dmgweaponresetallmult", Command_DamageWeaponResetAllMult, ADMFLAG_SLAY, "Reset the damage multiplier of all weapons");
	
	RegAdminCmd("sm_getdmgweaponmult", Command_GetDamageWeaponMult, ADMFLAG_SLAY, "Get the damage multiplier of a weapon");
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	RegAdminCmd("sm_dmgweaponresetall", Command_DamageWeaponResetAll, ADMFLAG_SLAY, "Reset the damage multiplier/additionnal of all weapons");
	
//--------------------------------------------------------------------------------------------------------------------//
}

void RegisterCvars()
{
	CreateConVar("sm_damagemanage_version", PLUGIN_VERSION, "Damage Multiplier Version", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	hEnable = CreateConVar("sm_damagemanage_enable", "1", "Enable/Disable the plugin", FCVAR_NOTIFY | FCVAR_SPONLY, true, 0.0, true, 1.0);
	hEnable.AddChangeHook(ConVarChanged);
	
	hDefaultDamageMult = CreateConVar("sm_damagemult_default", "1.0", "Default damage deal multiplier (1 = disabled)", FCVAR_NOTIFY);
	hDefaultDamageMult.AddChangeHook(ConVarChanged);
	
	hDefaultWeakDamageMult = CreateConVar("sm_damageweakmult_default", "1.0", "Default damage received multiplier (1 = disabled)", FCVAR_NOTIFY);
	hDefaultWeakDamageMult.AddChangeHook(ConVarChanged);
	
	hEnableNegativeDamage = CreateConVar("sm_negativedamage_enable", "1", "Enable/Disable Negative damage become his opposite", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hEnableNegativeDamage.AddChangeHook(ConVarChanged);
	
	AutoExecConfig(true, "DamageManage");
}

public void ConVarChanged(ConVar hConvar, const char[] oldValue, const char[] newValue)
{	
	if(hConvar == hEnable)
		bEnable = view_as<bool>(StringToInt(newValue));
		
	if(hConvar == hDefaultDamageMult)
	{
		fDefaultDamageMult = StringToFloat(newValue);
		for(int iClient = 0; iClient <= MaxClients; iClient++)
			if(IsValidClient(iClient))
			{
				if(fDefaultDamageMult != 1.0)
					bDamageMult[iClient] = true;
					
				else
					bDamageMult[iClient] = false;
					
				fDamageMult[iClient] = fDefaultDamageMult;
			}
			
	}
	if(hConvar == hDefaultWeakDamageMult)
	{
		fDefaultWeakDamageMult = StringToFloat(newValue);
		for(int iClient = 0; iClient <= MaxClients; iClient++)
			if(IsValidClient(iClient))
			{
				if(fDefaultWeakDamageMult != 1.0)
					bWeakDamageMult[iClient] = true;
					
				else
					bWeakDamageMult[iClient] = false;
				
				fWeakDamageMult[iClient] = fDefaultWeakDamageMult;
			}
	}
	if(hConvar == hEnableNegativeDamage)
		bEnableNegativeDamage = view_as<bool>(StringToInt(newValue));
		
}

public void OnConfigsExecuted()
{
	bEnable = hEnable.BoolValue;
	fDefaultDamageMult = hDefaultDamageMult.FloatValue;
	fDefaultWeakDamageMult = hDefaultWeakDamageMult.FloatValue;
	bEnableNegativeDamage = hEnableNegativeDamage.BoolValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	if(fDefaultDamageMult != 1.0) 
		bDamageMult[client] = true;
		
	else 
		bDamageMult[client] = false;
	
	if(fDefaultWeakDamageMult != 1.0)
		bWeakDamageMult[client] = true;
		
	else
		bWeakDamageMult[client] = false;

	bDamageAdd[client] = false;
	bWeakDamageAdd[client] = false;
	fDamageAdd[client] = 0.0;
	fWeakDamageAdd[client] = 0.0;
	
	fDamageMult[client] = fDefaultDamageMult;
	fWeakDamageMult[client] = fDefaultWeakDamageMult;
}

public void OnClientDisconnect(int client)
{
	if(fDefaultDamageMult != 1.0) 
		bDamageMult[client] = true;
		
	else 
		bDamageMult[client] = false;
	
	if(fDefaultWeakDamageMult != 1.0)
		bWeakDamageMult[client] = true;
		
	else
		bWeakDamageMult[client] = false;
		
	bDamageAdd[client] = false;
	bWeakDamageAdd[client] = false;
	fDamageAdd[client] = 0.0;
	fWeakDamageAdd[client] = 0.0;	
	
	fDamageMult[client] = fDefaultDamageMult;
	fWeakDamageMult[client] = fDefaultWeakDamageMult;
}

public void OnMapStart()
{
	WeaponDamageMult = new StringMap();
	WeaponDamageAdd = new StringMap();
	WeaponDamageMult.Clear();
	WeaponDamageAdd.Clear();
}

public void OnMapEnd()
{
	WeaponDamageMult.Clear();
	WeaponDamageAdd.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(bIsTF2)
	{
		if(StrEqual(classname, "tank_boss", false) || StrEqual(classname, "obj_sentrygun", false) || StrEqual(classname, "obj_dispenser", false) || StrEqual(classname, "obj_teleporter", false))
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnPropTakeDamage);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	
///////////////////////////////////////////////////////////--CONFIGURATION--///////////////////////////////////////////////////////////
	char cWeapon[64];

	bool		bInitialDamageMultChanged, 
			bInitialDamageAddChanged;
			
	float		fWeaponMultDamage, 
			fWeaponAddDamage, 	
			fDamageStackMult, 
			fDamageStackAdd;
	
	#if DEBUG
	float		fDamageMultAttacker,
			fDamageMultVictim, 
			fDamageMultWeapon = 1.0;
	#endif

	if(!IsValidClient(attacker)) return Plugin_Continue;
	
	if(attacker == victim) return Plugin_Continue;
	
	if(!bEnable) return Plugin_Continue;
	
///////////////////////////////////////////////////--INFLICTOR PART--///////////////////////////////////////////////////

	if(bIsTF2)	//Add Other Games that store the weapon value
	{
		if(inflictor != attacker)
		{
			GetEdictClassname(inflictor, cWeapon, sizeof(cWeapon));
			
			if(StrEqual(cWeapon, "obj_sentrygun") || StrEqual(cWeapon, "obj_dispenser") || StrEqual(cWeapon, "obj_teleporter"))
				GetEdictClassname(inflictor, cWeapon, sizeof(cWeapon));
			
			else if(GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity") == attacker)
				GetEdictClassname(weapon, cWeapon, sizeof(cWeapon));
			
			else if(StrEqual(cWeapon, "tf_projectile_sentryrocket"))
				GetEdictClassname(GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity"), cWeapon, sizeof(cWeapon));
				
			else
				GetEdictClassname(GetEntPropEnt(inflictor, Prop_Send, "m_hLauncher"), cWeapon, sizeof(cWeapon));
			
		}
		else
			GetEdictClassname(weapon, cWeapon, sizeof(cWeapon));

	}
	else
	{
		if(inflictor != attacker)
			GetEdictClassname(inflictor, cWeapon, sizeof(cWeapon));		//Get the inflictor classname (for grenades in CS games and others)
		
		else
			GetClientWeapon(attacker, cWeapon, sizeof(cWeapon));

	}
	
	#if DEBUG
	PrintToChatAll("Inflictor Classname : \"%s\"", cWeapon);
	#endif
	
/////////////////////////////////////////--CONFIGURATION EP2--/////////////////////////////////////////
	
	if(	!bDamageMult[attacker] && 
		!bDamageAdd[attacker] && 
		!bWeakDamageMult[victim] && 
		!bWeakDamageAdd[victim] &&
		fDamageMult[attacker] == 1.0 && 
		!fDamageAdd[attacker] && 
		fWeakDamageMult[victim] == 1.0 && 
		!fWeakDamageAdd[victim] && 
		!WeaponDamageMult.GetValue(cWeapon, fWeaponMultDamage) && 
		!WeaponDamageAdd.GetValue(cWeapon, fWeaponAddDamage) ) return Plugin_Continue;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	if(bEnableNegativeDamage)
	{
		if(bDamageMult[attacker])
			if(fDamageMult[attacker] < 0.0)
				fDamageMult[attacker] = -(fDamageMult[attacker]);
			
		if(bWeakDamageMult[victim])
			if(fWeakDamageMult[victim] < 0.0)
				fWeakDamageMult[victim] = -(fWeakDamageMult[victim]);

	}
	
///////////////////////////////////////////////--DAMAGE ADDITIONAL--///////////////////////////////////////////////

	if(bDamageAdd[attacker] || fDamageAdd[attacker] != 0.0)
	{
		fDamageStackAdd += fDamageAdd[attacker];
		bInitialDamageAddChanged = true;
	}
	if(bWeakDamageAdd[victim] || fWeakDamageAdd[victim] != 0.0)
	{
		fDamageStackAdd += fWeakDamageAdd[victim];
		bInitialDamageAddChanged = true;
	}

	if(WeaponDamageAdd.GetValue(cWeapon, fWeaponAddDamage))
	{
		if(bEnableNegativeDamage)
			if(fWeaponAddDamage < 0.0)
				fWeaponAddDamage = -(fWeaponAddDamage);
				
		if(fWeaponAddDamage != 0.0)
		{	
			fDamageStackAdd += fWeaponAddDamage;
			bInitialDamageAddChanged = true;
		}	
	}

///////////////////////////////////////////////--DAMAGE MULTIPLIER--///////////////////////////////////////////////

	if(bDamageMult[attacker] || fDamageMult[attacker] != 1.0)
	{
		fDamageStackMult += fDamageMult[attacker];
		bInitialDamageMultChanged = true;
		
		
	#if DEBUG
		fDamageMultAttacker = fDamageMult[attacker];
	#endif
	}

	if(bWeakDamageMult[victim] || fWeakDamageMult[victim] != 1.0)
	{
		fDamageStackMult += fWeakDamageMult[victim];
		bInitialDamageMultChanged = true;
		
		
		#if DEBUG
		fDamageMultVictim = fWeakDamageMult[victim];
		#endif
	}
	
	if(WeaponDamageMult.GetValue(cWeapon, fWeaponMultDamage))
	{
		if(bEnableNegativeDamage)
			if(fWeaponMultDamage < 0.0)
				fWeaponMultDamage = -(fWeaponMultDamage);
		
		if(fWeaponMultDamage != 1.0)
		{
			fDamageStackMult += fWeaponMultDamage;
			bInitialDamageMultChanged = true;
			
			
			#if DEBUG
			fDamageMultWeapon = fWeaponMultDamage;
			#endif
		}
	}

///////////////////////////////////////////////--CONCLUSION--///////////////////////////////////////////////
	
	if(bInitialDamageAddChanged || bInitialDamageMultChanged)
	{
		if(bInitialDamageAddChanged)
		{
			damage += fDamageStackAdd;
			

			#if DEBUG
			/*
			CPrintToChat(attacker, "Damage Additional : {yellow}%0.1f {default}({yellow}attacker %0.1f {default}+ {yellow}victim %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackAdd, fDamageAdd[attacker], fWeakDamageAdd[victim], fWeaponAddDamage);

			CPrintToChat(victim, "Damage Additional : {yellow}%0.1f {default}({yellow}victim %0.1f {default}+ {yellow}attacker %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackAdd, fWeakDamageAdd[victim], fDamageAdd[attacker], fWeaponAddDamage);
			*/
			
			CPrintToChatAll("Damage Additional : {yellow}%0.1f {default}({yellow}attacker %0.1f {default}+ {yellow}victim %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackAdd, fDamageAdd[attacker], fWeakDamageAdd[victim], fWeaponAddDamage);
			#endif
		}
		
		if(bInitialDamageMultChanged)
		{
			damage *= fDamageStackMult;	
			
			
			#if DEBUG
			/*
			CPrintToChat(attacker, "Damage multiplier : {yellow}%0.1f {default}({yellow}attacker %0.1f {default}+ {yellow}victim %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackMult, fDamageMultAttacker, fDamageMultVictim, fWeaponMultDamage);
			CPrintToChat(attacker, "Damage Attacker Multiplier : {yellow}%0.1f{default}\nDamage Victim Multiplier : {yellow}%0.1f{default}\nDamage Weapon Multiplier : {yellow}%0.1f", fDamageMult[attacker], fWeakDamageMult[victim], fWeaponMultDamage);
			
			CPrintToChat(victim, "Damage multiplier : {yellow}%0.1f {default}({yellow}victim %0.1f {default}+ {yellow}attacker %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackMult, fDamageMultVictim, fDamageMultAttacker, fWeaponMultDamage);
			CPrintToChat(victim, "Damage Victim Multiplier : {yellow}%0.1f{default}\nDamage Damage Multiplier : {yellow}%0.1f{default}\nDamage Weapon Multiplier : {yellow}%0.1f", fWeakDamageMult[victim], fDamageMult[attacker], fWeaponMultDamage);
			*/
			
			CPrintToChatAll("Damage multiplier : {yellow}%0.1f {default}({yellow}attacker %0.1f {default}+ {yellow}victim %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackMult, fDamageMultAttacker, fDamageMultVictim, fWeaponMultDamage);
			CPrintToChatAll("Damage Attacker Multiplier : {yellow}%0.1f{default}\nDamage Victim Multiplier : {yellow}%0.1f{default}\nDamage Weapon Multiplier : {yellow}%0.1f", fDamageMult[attacker], fWeakDamageMult[victim], fDamageMultWeapon);
			#endif
		}
		
		
		#if DEBUG
		/*
		CPrintToChat(attacker, "Damage Total : {yellow}%0.1f", damage);
		CPrintToChat(victim, "Damage Total : {yellow}%0.1f", damage);
		*/
		
		CPrintToChatAll("Damage Total : {yellow}%0.1f", damage);
		#endif
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	return bInitialDamageMultChanged || bInitialDamageAddChanged ? Plugin_Changed : Plugin_Continue;
}




public Action OnPropTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	
///////////////////////////////////////////////--CONFIGURATION--///////////////////////////////////////////////

	char cWeapon[64];

	bool		bInitialDamageMultChanged, 
			bInitialDamageAddChanged;
			
	float		fWeaponMultDamage, 
			fWeaponAddDamage, 	
			fDamageStackMult, 
			fDamageStackAdd;
	
	#if DEBUG
	float		fDamageMultAttacker,
			fDamageMultVictim, 
			fDamageMultWeapon = 1.0, 
			fDamageAddVictim;
	#endif
	
	if(!IsValidClient(attacker)) return Plugin_Continue;
	
	if(!bEnable) return Plugin_Continue;
	
	if(attacker == victim) return Plugin_Continue;
	
///////////////////////////////////////////////--INFLICTOR PART--///////////////////////////////////////////////

	if(bIsTF2)	//Add Other Games that store the weapon value
	{
		if(inflictor != attacker)
		{
			GetEdictClassname(inflictor, cWeapon, sizeof(cWeapon));
			
			if(StrEqual(cWeapon, "obj_sentrygun") || StrEqual(cWeapon, "obj_dispenser") || StrEqual(cWeapon, "obj_teleporter"))
				GetEdictClassname(inflictor, cWeapon, sizeof(cWeapon));
			
			else if(GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity") == attacker)
				GetEdictClassname(weapon, cWeapon, sizeof(cWeapon));
			
			else if(StrEqual(cWeapon, "tf_projectile_sentryrocket"))
				GetEdictClassname(GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity"), cWeapon, sizeof(cWeapon));
				
			else
				GetEdictClassname(GetEntPropEnt(inflictor, Prop_Send, "m_hLauncher"), cWeapon, sizeof(cWeapon));
			
		}
		else
			GetEdictClassname(weapon, cWeapon, sizeof(cWeapon));

	}
	else
	{
		if(inflictor != attacker)
			GetEdictClassname(inflictor, cWeapon, sizeof(cWeapon));		//Get the inflictor classname (for grenades in CS games and others)
			
		else
			GetClientWeapon(attacker, cWeapon, sizeof(cWeapon));		
			
	}
	
	#if DEBUG
	PrintToChatAll("Inflictor Classname : \"%s\"", cWeapon);
	#endif
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	if(bEnableNegativeDamage)
	{
		if(bDamageMult[attacker])
			if(fDamageMult[attacker] < 0.0)
				fDamageMult[attacker] = -(fDamageMult[attacker]);

		if(bDamageAdd[attacker])
			if(fDamageAdd[attacker] < 0.0)
				fDamageAdd[attacker] = -(fDamageAdd[attacker]);
				
	}
	
	///////////////////////////////////////////////--DAMAGE ADDITIONAL--///////////////////////////////////////////////
	
	if(bDamageAdd[attacker] || fDamageAdd[attacker] != 0.0)
	{
		fDamageStackAdd += fDamageAdd[attacker];
		bInitialDamageAddChanged = true;
	}

	if(WeaponDamageAdd.GetValue(cWeapon, fWeaponAddDamage))
	{
		if(bEnableNegativeDamage)
			if(fWeaponAddDamage < 0.0)
				fWeaponAddDamage = -(fWeaponAddDamage);
				
		if(fWeaponAddDamage != 0.0)
		{	
			fDamageStackAdd += fWeaponAddDamage;
			bInitialDamageAddChanged = true;
		}	
	}
	
	///////////////////////////////////////////////--DAMAGE MULTIPLIER--///////////////////////////////////////////////
	
	if(bDamageMult[attacker] || fDamageMult[attacker] != 1.0)
	{
		fDamageStackMult += fDamageMult[attacker];
		bInitialDamageMultChanged = true;
		
		
	#if DEBUG
		fDamageMultAttacker = fDamageMult[attacker];
	#endif
	}

	if(WeaponDamageMult.GetValue(cWeapon, fWeaponMultDamage))
	{
		if(bEnableNegativeDamage)
			if(fWeaponMultDamage < 0.0)
				fWeaponMultDamage = -(fWeaponMultDamage);
				
		if(fWeaponMultDamage != 1.0)
		{
			fDamageStackMult += fWeaponMultDamage;
			bInitialDamageMultChanged = true;
			
			
			#if DEBUG
			fDamageMultWeapon = fWeaponMultDamage;
			#endif
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	if(bIsTF2)
	{
		int		iBuildings = -1, 
				iBuilder;
		
		while((iBuildings = FindEntityByClassname(iBuildings, "obj_*")) != INVALID_ENT_REFERENCE)
		{
			iBuilder = GetEntPropEnt(iBuildings, Prop_Send, "m_hBuilder");
			
			if(GetEntProp(iBuildings, Prop_Data, "m_iHealth") < 1) //Prevent buildings undestroyable by negative damage
			{
				//AcceptEntityInput(iBuildings, "Kill");
				SetVariantInt(1);
				AcceptEntityInput(iBuildings, "AddHealth");
				SDKHooks_TakeDamage(iBuildings, inflictor, attacker, 9999.0);
			}
			
			if(!IsValidClient(iBuilder)) continue;
			
			if(iBuildings == victim)
			{
				if(bEnableNegativeDamage)
				{
					if(bWeakDamageMult[iBuilder])
						if(fWeakDamageMult[iBuilder] < 0.0)
							fWeakDamageMult[iBuilder] = -(fWeakDamageMult[iBuilder]);
				}
				
				///////////////////////////////////////////////--DAMAGE ADDITIONAL--///////////////////////////////////////////////

				if(bWeakDamageAdd[iBuilder] || fWeakDamageAdd[iBuilder] != 0.0)
				{
					fDamageStackAdd += fWeakDamageAdd[victim];
					bInitialDamageAddChanged = true;
					
					
					#if DEBUG
					fDamageAddVictim = fWeakDamageAdd[iBuilder];
					#endif
				}
				#if DEBUG
				else
					fDamageAddVictim = 0.0;
				#endif
				
				///////////////////////////////////////////////--DAMAGE MULTIPLIER--///////////////////////////////////////////////

				if(bWeakDamageMult[iBuilder] || fWeakDamageMult[iBuilder] != 1.0)
				{
					fDamageStackMult += fWeakDamageMult[victim];
					bInitialDamageMultChanged = true;
					
					
					#if DEBUG
					fDamageMultVictim = fWeakDamageMult[iBuilder];
					#endif
				}
				
				/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				
				#if DEBUG
				if(bInitialDamageAddChanged || bInitialDamageMultChanged)
				{
					if(bInitialDamageAddChanged)
					{
						//CPrintToChat(iBuilder, "Damage Additional : {yellow}%0.1f {default}({yellow}victim %0.1f {default}+ {yellow}attacker %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackAdd, fDamageAddVictim, fDamageAdd[attacker], fWeaponAddDamage);
					}
					if(bInitialDamageMultChanged)
					{
						/*CPrintToChat(iBuilder, "Damage multiplier : {yellow}%0.1f {default}({yellow}victim %0.1f {default}+ {yellow}attacker %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackMult, fDamageMultVictim, fDamageMultAttacker, fWeaponMultDamage);
						CPrintToChat(iBuilder, "Damage Victim Multiplier : {yellow}%0.1f{default}\nDamage Damage Multiplier : {yellow}%0.1f{default}\nDamage Weapon Multiplier : {yellow}%0.1f", fWeakDamageMult[victim], fDamageMult[attacker], fDamageMultWeapon);
						*/
					}
				}
				#endif
				
			}
		}
	}
	
///////////////////////////////////////////////--CONCLUSION--///////////////////////////////////////////////

	if(bInitialDamageAddChanged || bInitialDamageMultChanged)
	{
		if(bInitialDamageAddChanged)
		{
			damage += fDamageStackAdd;
			

			#if DEBUG
			//CPrintToChat(attacker, "Damage Additional : {yellow}%0.1f {default}({yellow}attacker %0.1f {default}+ {yellow}victim %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackAdd, fDamageAdd[attacker], fDamageAddVictim, fWeaponAddDamage);
			
			CPrintToChatAll("Damage Additional : {yellow}%0.1f {default}({yellow}attacker %0.1f {default}+ {yellow}victim %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackAdd, fDamageAdd[attacker], fDamageAddVictim, fWeaponAddDamage);
			#endif
		}
		
		if(bInitialDamageMultChanged)
		{
			damage *= fDamageStackMult;	
			
			
			#if DEBUG
			/*CPrintToChat(attacker, "Damage multiplier : {yellow}%0.1f {default}({yellow}attacker %0.1f {default}+ {yellow}victim %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackMult, fDamageMultAttacker, fDamageMultVictim, fWeaponMultDamage);
			CPrintToChat(attacker, "Damage Attacker Multiplier : {yellow}%0.1f{default}\nDamage Victim Multiplier : {yellow}%0.1f{default}\nDamage Weapon Multiplier : {yellow}%0.1f", fDamageMult[attacker], fDamageMultVictim, fDamageMultWeapon);
			*/
			
			CPrintToChatAll("Damage multiplier : {yellow}%0.1f {default}({yellow}attacker %0.1f {default}+ {yellow}victim %0.1f {default}+ {yellow}weapon %0.1f{default})", fDamageStackMult, fDamageMultAttacker, fDamageMultVictim, fWeaponMultDamage);
			CPrintToChatAll("Damage Attacker Multiplier : {yellow}%0.1f{default}\nDamage Victim Multiplier : {yellow}%0.1f{default}\nDamage Weapon Multiplier : {yellow}%0.1f", fDamageMult[attacker], fDamageMultVictim, fDamageMultWeapon);
			
			#endif
		}
	}
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	return bInitialDamageMultChanged || bInitialDamageAddChanged ? Plugin_Changed : Plugin_Continue;
}



//------------------------------------ PLAYER ------------------------------------ //

			///////////////////////////////////////////////--DAMAGE ADDITIONNAL--///////////////////////////////////////////////

public Action Command_DamageAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 2)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target> <value>", arg0);
			return Plugin_Handled;
		}
		if(args < 1 || args > 2)
		{
			ReplyToCommand(client, "[SM] Usage: %s <value>\n[SM] Usage: %s <target> <value>", arg0, arg0);
			return Plugin_Handled;
		}
		if(args == 1)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			float fVerifyDamage = StringToFloat(arg1);
				
			if(fVerifyDamage == 0.0)
			{
				bDamageAdd[client] = false;
				fDamageAdd[client] = 0.0;
			}
			else if(-0.1 < fVerifyDamage < 0.1)
			{
				bDamageAdd[client] = false;
				fDamageAdd[client] = 0.0;
			}
			else
			{
				bDamageAdd[client] = true;
				fDamageAdd[client] = fVerifyDamage;
			}	
			CReplyToCommand(client, "[SM] Your {yellow}damage additionnal{default} is set to {lime}%0.1f", fDamageAdd[client]);
		}
		if(args == 2)
		{
			char arg1[64], arg2[32], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			float fVerifyDamage = StringToFloat(arg2);
	
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
					
				if(fVerifyDamage == 0.0)
				{
					bDamageAdd[target] = false;
					fDamageAdd[target] = 0.0;
				}
				else if(-0.1 < fVerifyDamage < 0.1)
				{
					bDamageAdd[target] = false;
					fDamageAdd[target] = 0.0;
				}
				else
				{
					bDamageAdd[target] = true;
					fDamageAdd[target] = fVerifyDamage;
				}
		
				CReplyToCommand(target, "[SM] Your {yellow}damage additionnal{default}  is set to {lime}%0.1f", fDamageAdd[target]);
			}
				
			if(-0.1 < fVerifyDamage < 0.1)
				fVerifyDamage = 0.0;
					
			CShowActivity2(client, "[SM] ", "{grey}%s's {yellow}damage additionnal{default} is set to {lime}%0.1f", target_name, fVerifyDamage);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeakAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 2)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target> <value>", arg0);
			return Plugin_Handled;
		}
		if(args < 1 || args > 2)
		{
			ReplyToCommand(client, "[SM] Usage: %s <value>\n[SM] Usage: %s <target> <value>", arg0, arg0);
			return Plugin_Handled;
		}
		if(args == 1)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			
			float fVerifyDamage = StringToFloat(arg1);
			
			if(fVerifyDamage == 0.0)
			{
				bWeakDamageAdd[client] = false;
				fWeakDamageAdd[client] = 0.0;
			}
			else if(-0.1 < fVerifyDamage < 0.1)
			{
				bWeakDamageAdd[client] = false;
				fWeakDamageAdd[client] = 0.0;
			}
			else
			{
				bWeakDamageAdd[client] = true;
				fWeakDamageAdd[client] = fVerifyDamage;
			}
			
			CReplyToCommand(client, "[SM] You will receive {yellow}damage additionnal{default} is set to {lime}%0.1f", fWeakDamageAdd[client]);
		}
		if(args == 2)
		{
			char arg1[64], arg2[32], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			float fVerifyDamage = StringToFloat(arg2);
			
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
					
				if(fVerifyDamage == 0.0)
				{
					bWeakDamageAdd[target] = false;
					fWeakDamageAdd[target] = 0.0;
				}
				else if(-0.1 < fVerifyDamage < 0.1)
				{
					bWeakDamageAdd[target] = false;
					fWeakDamageAdd[target] = 0.0;
				}
				else
				{
					bWeakDamageAdd[target] = true;
					fWeakDamageAdd[target] = fVerifyDamage;
				}
				
				CReplyToCommand(target, "[SM] You will receive {yellow}damage additionnal{default} set to {lime}%0.1f", fWeakDamageAdd[target]);
			}
			if(-0.1 < fVerifyDamage < 0.1)
				fVerifyDamage = 0.0;
				
			CShowActivity2(client, "[SM] ", "{grey}%s {default}will receive {yellow}damage additionnal{default} set to {lime}%0.1f", target_name, fVerifyDamage);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageResetAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
		{
			if(bDamageAdd[client])
				CReplyToCommand(client, "[SM] Your {yellow}damage additionnal {default}is now reset");
					
			else
				CReplyToCommand(client, "[SM] Your {yellow}damage additionnal {default}is already reset to the default value");
					
			bDamageAdd[client] = false;
			fDamageAdd[client] = 0.0;
		}
		if(args == 1)
		{
			char arg1[64], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
			
				if(!target)
					continue;
						
				if(bDamageAdd[target])
					CReplyToCommand(target, "[SM] Your {yellow}damage additionnal {default}is now reset to the default value");
						
				bDamageAdd[target] = false;
				fDamageAdd[target] = 0.0;
			}
			CShowActivity2(client, "[SM] ", "{grey}%s's {yellow}damage additionnal {default}is now reset to the default value", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeakResetAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
		{
			if(bWeakDamageAdd[client])
				CReplyToCommand(client, "[SM] Your {yellow}damage received additionnal{default} is now reset to the default value");
			
			else
				CReplyToCommand(client, "[SM] Your {yellow}damage received additionnal{default} is already reset to the default value");
				
			bWeakDamageAdd[client] = false;
			fWeakDamageAdd[client] = 0.0;
		}
		if(args == 1)
		{
			char arg1[64], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
					
				if(bWeakDamageAdd[target])
					CReplyToCommand(target, "[SM] Your {yellow}damage received additionnal{default} is now reset to the default value");
					
				bWeakDamageAdd[target] = false;
				fWeakDamageAdd[target] = 0.0;
			}
			CShowActivity2(client, "[SM]", "{yellow}Damage received additionnal{default} of {grey}%s{default} is now reset to the default value", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageResetAllAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
		{	
			if(bDamageAdd[client] && bWeakDamageAdd[client])
			{
				CReplyToCommand(client, "[SM] All of your {yellow}damage (did or received) additionnal {default}are now reset to the default");
				bDamageAdd[client] = false;
				bWeakDamageAdd[client] = false;
				fDamageAdd[client] = 0.0;
				fWeakDamageAdd[client] = 0.0;
			}
			
			else if(bDamageAdd[client] && !bWeakDamageAdd[client])
			{
				CReplyToCommand(client, "Your {yellow}damage additionnal{default} is now reset to the default value");
				bDamageAdd[client] = false;
				bWeakDamageAdd[client] = false;
				fDamageAdd[client] = 0.0;
				fWeakDamageAdd[client] = 0.0;
			}
			else if(!bDamageAdd[client] && bWeakDamageAdd[client])
			{
				CReplyToCommand(client, "[SM] Your {yellow}damage received additionnal{default} is now reset to the default value");
				bDamageAdd[client] = false;
				bWeakDamageAdd[client] = false;
				fDamageAdd[client] = 0.0;
				fWeakDamageAdd[client] = 0.0;
			}
		}
		if(args == 1)
		{
			char arg1[64], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
				
				if(bDamageAdd[target] && bWeakDamageAdd[target])
				{
					CReplyToCommand(target, "[SM] All of your {yellow}damage (did or received) additionnal{default} are now reset to the default value");
					bDamageAdd[target] = false;
					bWeakDamageAdd[target] = false;
					fDamageAdd[target] = 1.0;
					fWeakDamageAdd[target] = 1.0;
				}
					
				else if(bDamageAdd[target] && !bWeakDamageAdd[target])
				{
					CReplyToCommand(target, "[SM] Your {yellow}damage additionnal{default} is now reset to the default value");
					bDamageAdd[target] = false;
					bWeakDamageAdd[target] = false;
					fDamageAdd[target] = 0.0;
					fWeakDamageAdd[target] = 0.0;
				}
				else if(!bDamageAdd[target] && bWeakDamageAdd[target])
				{
					CReplyToCommand(target, "[SM] Your {yellow}damage received additionnal{default} is now reset to default value");
					bDamageAdd[target] = false;
					bWeakDamageAdd[target] = false;
					fDamageAdd[target] = 0.0;
					fWeakDamageAdd[target] = 0.0;
				}
			}
			CShowActivity2(client, "[SM] ", "{green}All damage (did or received) additionnal of {grey}%s{green} are now reset to default", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_GetDamageAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
			CReplyToCommand(client, "[SM] Your {yellow}damage {default}is additionnal set to {lime}%0.1f", fDamageAdd[client]);
		
		if(args == 1)
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1);
			if(target == -1)
				return Plugin_Handled;
				
			CReplyToCommand(client, "[SM] %N's {yellow}damage {default}is multiplied by {lime}%0.1f", target, fDamageAdd[target]);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_GetDamageWeakAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
			CReplyToCommand(client, "[SM] You receive {yellow}damage {default}additionnal set to {lime}%0.1f", fWeakDamageAdd[client]);
			
		if(args == 1)
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1);
			
			if(target == -1)
				return Plugin_Handled;
				
			CReplyToCommand(client, "[SM] %N receives {yellow}damage {default}additionnal set to {lime}%0.1f", target, fWeakDamageAdd[target]);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

				///////////////////////////////////////////////--DAMAGE MULTIPLIER--///////////////////////////////////////////////

public Action Command_DamageMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 2)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target> <value>", arg0);
			return Plugin_Handled;
		}
		if(args < 1 || args > 2)
		{
			ReplyToCommand(client, "[SM] Usage: %s <value>\n[SM] Usage: %s <target> <value>", arg0, arg0);
			return Plugin_Handled;
		}
		if(args == 1)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			float fVerifyDamage = StringToFloat(arg1);
				
			if(fVerifyDamage == 1.0)
			{
				bDamageMult[client] = false;
				fDamageMult[client] = 1.0;
			}
			else if(-0.1 < fVerifyDamage < 0.1)
			{
				bDamageMult[client] = true;
				fDamageMult[client] = 0.0;
			}
			else
			{
				bDamageMult[client] = true;
				fDamageMult[client] = fVerifyDamage;
			}	
			CReplyToCommand(client, "[SM] Your {yellow}damage {default}is multiplied by {lime}%0.1f", fDamageMult[client]);
		}
		if(args == 2)
		{
			char arg1[64], arg2[32], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			float fVerifyDamage = StringToFloat(arg2);
	
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
					
				if(fVerifyDamage == 1.0)
				{
					bDamageMult[target] = false;
					fDamageMult[target] = 1.0;
				}
				else if(-0.1 < fVerifyDamage < 0.1)
				{
					bDamageMult[target] = true;
					fDamageMult[target] = 0.0;
				}
				else
				{
					bDamageMult[target] = true;
					fDamageMult[target] = fVerifyDamage;
				}
		
				CReplyToCommand(target, "[SM] Your {yellow}damage {default}is multiplied by {lime}%0.1f", fDamageMult[target]);
			}
				
			if(-0.1 < fVerifyDamage < 0.1)
				fVerifyDamage = 0.0;
					
			CShowActivity2(client, "[SM] ", "{grey}%s's {yellow}damage {default}multiplied by {lime}%0.1f", target_name, fVerifyDamage);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeakMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 2)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target> <value>", arg0);
			return Plugin_Handled;
		}
		if(args < 1 || args > 2)
		{
			ReplyToCommand(client, "[SM] Usage: %s <value>\n[SM] Usage: %s <target> <value>", arg0, arg0);
			return Plugin_Handled;
		}
		if(args == 1)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			
			float fVerifyDamage = StringToFloat(arg1);
			
			if(fVerifyDamage == 1.0)
			{
				bWeakDamageMult[client] = false;
				fWeakDamageMult[client] = 1.0;
			}
			else if(-0.1 < fVerifyDamage < 0.1)
			{
				bWeakDamageMult[client] = true;
				fWeakDamageMult[client] = 0.0;
			}
			else
			{
				bWeakDamageMult[client] = true;
				fWeakDamageMult[client] = fVerifyDamage;
			}
			
			CReplyToCommand(client, "[SM] You will receive {yellow}damage {default}multiplied by {lime}%0.1f", fWeakDamageMult[client]);
		}
		if(args == 2)
		{
			char arg1[64], arg2[32], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			float fVerifyDamage = StringToFloat(arg2);
			
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
					
				if(fVerifyDamage == 1.0)
				{
					bWeakDamageMult[target] = false;
					fWeakDamageMult[target] = 1.0;
				}
				else if(-0.1 < fVerifyDamage < 0.1)
				{
					bWeakDamageMult[target] = true;
					fWeakDamageMult[target] = 0.0;
				}
				else
				{
					bWeakDamageMult[target] = true;
					fWeakDamageMult[target] = fVerifyDamage;
				}
				
				CReplyToCommand(target, "[SM] You will receive {yellow}damage {default}multiplied by {lime}%0.1f", fWeakDamageMult[target]);
			}
			if(-0.1 < fVerifyDamage < 0.1)
				fVerifyDamage = 0.0;
				
			CShowActivity2(client, "[SM] ", "{grey}%s {default}will receive {yellow}damage {default}multiplied by {lime}%0.1f", target_name, fVerifyDamage);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageResetMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
		{
			if(bDamageMult[client])
				CReplyToCommand(client, "[SM] Your {yellow}damage multiplier {default}is now reset");
					
			else
				CReplyToCommand(client, "[SM] Your {yellow}damage multiplier {default}is already reset to the default value");
					
			bDamageMult[client] = false;
			fDamageMult[client] = 1.0;
		}
		if(args == 1)
		{
			char arg1[64], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
			
				if(!target)
					continue;
						
				if(bDamageMult[target])
					CReplyToCommand(target, "[SM] Your {yellow}damage multiplier {default}is now reset to the default value");
						
				bDamageMult[target] = false;
				fDamageMult[target] = 1.0;
			}
			CShowActivity2(client, "[SM] ", "{grey}%s's {yellow}damage multiplier {default}is now reset to the default value", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeakResetMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
		{
			if(bWeakDamageMult[client])
				CReplyToCommand(client, "[SM] Your {yellow}damage received multiplier{default} is now reset to the default value");
			
			else
				CReplyToCommand(client, "[SM] Your {yellow}damage received multiplier{default} is already reset to the default value");
				
			bWeakDamageMult[client] = false;
			fWeakDamageMult[client] = 1.0;
		}
		if(args == 1)
		{
			char arg1[64], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
					
				if(bWeakDamageMult[target])
					CReplyToCommand(target, "[SM] Your {yellow}damage received multiplier{default} is now reset to the default value");
					
				bWeakDamageMult[target] = false;
				fWeakDamageMult[target] = 1.0;
			}
			CShowActivity2(client, "[SM]", "{yellow}Damage received multiplier{default} of {grey}%s{default} is now reset to the default value", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageResetAllMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
		{	
			if(bDamageMult[client] && bWeakDamageMult[client])
			{
				CReplyToCommand(client, "[SM] All of your {yellow}damage (did or received) multiplier {default}are now reset to the default");
				bDamageMult[client] = false;
				bWeakDamageMult[client] = false;
				fDamageMult[client] = 1.0;
				fWeakDamageMult[client] = 1.0;
			}
			
			else if(bDamageMult[client] && !bWeakDamageMult[client])
			{
				CReplyToCommand(client, "Your {yellow}damage multiplier{default} is now reset to the default value");
				bDamageMult[client] = false;
				bWeakDamageMult[client] = false;
				fDamageMult[client] = 1.0;
				fWeakDamageMult[client] = 1.0;
			}
			else if(!bDamageMult[client] && bWeakDamageMult[client])
			{
				CReplyToCommand(client, "[SM] Your {yellow}damage received multiplier{default} is now reset to the default value");
				bDamageMult[client] = false;
				bWeakDamageMult[client] = false;
				fDamageMult[client] = 1.0;
				fWeakDamageMult[client] = 1.0;
			}
		}
		if(args == 1)
		{
			char arg1[64], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
				
				if(bDamageMult[target] && bWeakDamageMult[target])
				{
					CReplyToCommand(target, "[SM] All of your {yellow}damage (did or received) multiplier{default} are now reset to the default value");
					bDamageMult[target] = false;
					bWeakDamageMult[target] = false;
					fDamageMult[target] = 1.0;
					fWeakDamageMult[target] = 1.0;
				}
					
				else if(bDamageMult[target] && !bWeakDamageMult[target])
				{
					CReplyToCommand(target, "[SM] Your {yellow}damage multiplier{default} is now reset to the default value");
					bDamageMult[target] = false;
					bWeakDamageMult[target] = false;
					fDamageMult[target] = 1.0;
					fWeakDamageMult[target] = 1.0;
				}
				else if(!bDamageMult[target] && bWeakDamageMult[target])
				{
					CReplyToCommand(target, "[SM] Your {yellow}damage received multiplier{default} is now reset to default value");
					bDamageMult[target] = false;
					bWeakDamageMult[target] = false;
					fDamageMult[target] = 1.0;
					fWeakDamageMult[target] = 1.0;
				}
			}
			CShowActivity2(client, "[SM] ", "{green}All damage (did or received) multiplier of {grey}%s{green} are now reset to default", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_GetDamageMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
			CReplyToCommand(client, "[SM] Your {yellow}damage {default}is multiplied by {lime}%0.1f", fDamageMult[client]);
		
		if(args == 1)
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1);
			if(target == -1)
				return Plugin_Handled;
				
			CReplyToCommand(client, "[SM] %N's {yellow}damage {default}is multiplied by {lime}%0.1f", target, fDamageMult[target]);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_GetDamageWeakMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
			CReplyToCommand(client, "[SM] You receive {yellow}damage {default}multiplied by {lime}%0.1f", fWeakDamageMult[client]);
			
		if(args == 1)
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1);
			
			if(target == -1)
				return Plugin_Handled;
				
			CReplyToCommand(client, "[SM] %N receives {yellow}damage {default}multiplied by {lime}%0.1f", target, fWeakDamageMult[target]);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Action Command_DamageResetAll(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: %s <target>", arg0);
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s\n[SM] Usage: %s <target>", arg0, arg0);
			return Plugin_Handled;
		}
		if(!args)
		{	
			CReplyToCommand(client, "[SM] All of your {yellow}damage (did or received) multiplier/additionnal{default} are now reset to default value");
				
			bDamageMult[client] = false;
			bWeakDamageMult[client] = false;
			fDamageMult[client] = 1.0;
			fWeakDamageMult[client] = 1.0;
				
			bDamageAdd[client] = false;
			bWeakDamageAdd[client] = false;
			fDamageAdd[client] = 0.0;
			fWeakDamageAdd[client] = 0.0;
			
		}
		if(args == 1)
		{
			char arg1[64], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					continue;
				
				CReplyToCommand(target, "[SM] All of your {yellow}damage (did or received) multiplier/additionnal{default} are now reset to default value");
				
				bDamageMult[target] = false;
				bWeakDamageMult[target] = false;
				fDamageMult[target] = 1.0;
				fWeakDamageMult[target] = 1.0;
				
				bDamageAdd[target] = false;
				bWeakDamageAdd[target] = false;
				fDamageAdd[target] = 0.0;
				fWeakDamageAdd[target] = 0.0;
			}
			CShowActivity2(client, "[SM] ", "{green}All damage (did or received) multiplier/additionnal of {grey}%s{green} are now reset to default", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//--------------------------------------------- WEAPON ---------------------------------------------//


				///////////////////////////////////////////////--DAMAGE ADDITIONNAL--///////////////////////////////////////////////

public Action Command_DamageWeaponAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 2)
		{
			ReplyToCommand(client, "[SM] Usage: %s <weapon classname> <value>", arg0);
			return Plugin_Handled;
		}
		else
		{
			char arg1[64], arg2[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			float fWeaponDamage = StringToFloat(arg2);

			if(-0.1 < fWeaponDamage < 0.1)
				fWeaponDamage = 0.0;

			if(SetTrieValue(WeaponDamageAdd, arg1, fWeaponDamage, true))
				CShowActivity2(client, "[SM] ", "{green}Damage additional of the weapon : {default}\"{grey}%s{default}\" {green}is now set to {yellow}%0.1f", arg1, fWeaponDamage);

		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeaponResetAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s <weapon classname> <value>", arg0);
			return Plugin_Handled;
		}
		else
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			if(WeaponDamageAdd.Remove(arg1))
				CShowActivity2(client, "[SM] ", "{green}Damage additional of the weapon : {default}\"{grey}%s{default}\" {green}is now reset to default", arg1);
				
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeaponResetAllAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 0)
		{
			ReplyToCommand(client, "[SM] Usage: %s", arg0);
			return Plugin_Handled;
		}
		else
		{
			WeaponDamageAdd.Clear();
			CShowActivity2(client, "[SM] ", "{green}Damage Addtional of {grey}all weapons{green} are now reset to default");
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_GetDamageWeaponAdd(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s <weapon classname>", arg0);
			return Plugin_Handled;
		}
		else
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			float fWeaponDamage;

			if(WeaponDamageAdd.GetValue(arg1, fWeaponDamage))
				CShowActivity2(client, "[SM] ", "{green}The Additional Damage of the weapon : {default}\"{grey}%s{default}\" {green}is set to {yellow}%0.1f", arg1, fWeaponDamage);

			else
				CReplyToCommand(client, "[SM] Invalid Classname or Classname {yellow}damage additional{default} value not set");
				
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

			///////////////////////////////////////////////--DAMAGE MULTIPLIER--///////////////////////////////////////////////
public Action Command_DamageWeaponMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 2)
		{
			ReplyToCommand(client, "[SM] Usage: %s <weapon classname> <value>", arg0);
			return Plugin_Handled;
		}
		else
		{
			char arg1[64], arg2[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			float fWeaponDamage = StringToFloat(arg2);
				
			if(-0.1 < fWeaponDamage < 0.1)
				fWeaponDamage = 0.0;

			if(SetTrieValue(WeaponDamageMult, arg1, fWeaponDamage, true))
				CShowActivity2(client, "[SM] ", "{green}Damage of the weapon : {default}\"{grey}%s{default}\" {green}is now multiplied by {yellow}%0.1f", arg1, fWeaponDamage);

		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeaponResetMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s <weapon classname> <value>", arg0);
			return Plugin_Handled;
		}
		else
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			if(WeaponDamageMult.Remove(arg1))
				CShowActivity2(client, "[SM] ", "{green}Damage Multiplier of the weapon : {default}\"{grey}%s{default}\" {green}is now reset to default", arg1);

		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeaponResetAllMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 0)
		{
			ReplyToCommand(client, "[SM] Usage: %s", arg0);
			return Plugin_Handled;
		}
		else
		{
			WeaponDamageMult.Clear();
			CShowActivity2(client, "[SM] ", "{green}Damage Multiplier of {grey}all weapons{green} are now reset to default");
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_GetDamageWeaponMult(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 1)
		{
			ReplyToCommand(client, "[SM] Usage: %s <weapon classname>", arg0);
			return Plugin_Handled;
		}
		else
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			float fWeaponDamage;

			if(WeaponDamageMult.GetValue(arg1, fWeaponDamage))
				CShowActivity2(client, "[SM] ", "{green}The Damage of the weapon : {default}\"{grey}%s{default}\" {green}is multiplied by {yellow}%0.1f", arg1, fWeaponDamage);

			else
				CReplyToCommand(client, "[SM] Invalid Classname or Classname {yellow}damage multiplier{default} value not set");
				
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Action  Command_DamageWeaponResetAll(int client, int args)
{
	if(bEnable)
	{
		char arg0[32];
		GetCmdArg(0, arg0, sizeof(arg0));
		if(args != 0)
		{
			ReplyToCommand(client, "[SM] Usage: %s", arg0);
			return Plugin_Handled;
		}
		else
		{
			WeaponDamageAdd.Clear();
			WeaponDamageMult.Clear();
			CShowActivity2(client, "[SM] ", "{green}Damage Addtional and Multiplier of {grey}all weapons{green} are now reset to default");
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage Management\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//-------------------------------------------------------------------------------------------//

void CheckGames()
{
	if(GetEngineVersion() == Engine_TF2)
		bIsTF2 = true;
		
	/*if(GetEngineVersion() == )
		*/
}

//***********STOCKS***********//

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}