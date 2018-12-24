#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <multicolors>

#pragma newdecls required


#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = 
{
	name = "[TF2/ANY?] Damage multiplier",
	author = "Whai",
	description = "Multiply the damage of a player",
	version = PLUGIN_VERSION,
	url = ""
}

bool bIsTF2;
float fDamage[MAXPLAYERS+1], fWeakDamage[MAXPLAYERS+1];
bool bDamage[MAXPLAYERS+1], bWeakDamage[MAXPLAYERS+1];

bool bDefaultDamageDisabled;


//*******ConVars*******//
bool bEnable;
ConVar hEnable, hDefaultDamage;
float fDefaultDamage;
//*********************//

public void OnPluginStart()
{
	RegAdminCmd("sm_dmgmult", Command_DamageMult, ADMFLAG_SLAY, "Multiply the damage did of a player");
	RegAdminCmd("sm_dmgreset", Command_DamageReset, ADMFLAG_SLAY, "Reset the damage did of a player");
	RegAdminCmd("sm_dmgweakmult", Command_DamageWeakMult, ADMFLAG_SLAY, "Multiply the damage received of a player");
	RegAdminCmd("sm_dmgweakreset", Command_DamageWeakReset, ADMFLAG_SLAY, "Reset the damage received of a player");
	RegAdminCmd("sm_getdmgmult", Command_GetDamageMult, ADMFLAG_SLAY, "Get the damage did multiplied of a player");
	RegAdminCmd("sm_getdmgweakmult", Command_GetDamageWeakMult, ADMFLAG_SLAY, "Get the damage received multiplied of a player");
	RegAdminCmd("sm_dmgresetall", Command_DamageResetAll, ADMFLAG_SLAY, "Reset the damage did and the damage received of a player");
	
	hEnable = CreateConVar("sm_damagemult_enable", "1.0", "Enable/Disable the plugin", FCVAR_NOTIFY | FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(hEnable, ConVarChanged);
	
	hDefaultDamage = CreateConVar("sm_damagemult_default", "1", "Default damage multiplied (1 = disabled)");
	HookConVarChange(hDefaultDamage, ConVarChanged);
	
	CreateConVar("sm_damagemult_version", PLUGIN_VERSION, "Damage Multiplier Version", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	LoadTranslations("common.phrases");
	
	for(int iClient; iClient <= MaxClients; iClient++)
		if(IsValidClient(iClient))
			OnClientPutInServer(iClient);
			
	CheckGames();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	bEnable = GetConVarBool(hEnable);
	fDefaultDamage = GetConVarFloat(hDefaultDamage);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	bDamage[client] = false;
	bWeakDamage[client] = false;
	fDamage[client] = 1.0;
	fWeakDamage[client] = 1.0;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	bDamage[client] = false;
	bWeakDamage[client] = false;
	fDamage[client] = 1.0;
	fWeakDamage[client] = 1.0;
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
	if(!IsValidClient(attacker)) return Plugin_Continue;
	
	if(attacker == victim) return Plugin_Continue;
	
	if(!bEnable)return Plugin_Continue;
	
	if(fDefaultDamage != 1.0)
	{
		bDamage[attacker] = true;
		bWeakDamage[victim] = false;
		fDamage[attacker] = fDefaultDamage;
		fWeakDamage[victim] = 1.0;
		
		bDefaultDamageDisabled = false;
	}
	else
	{
		if(!bDefaultDamageDisabled)
		{
			fDamage[attacker] = 1.0;
			fWeakDamage[victim] = 1.0;
			bDamage[attacker] = false;
			bWeakDamage[victim] = false;
			
			bDefaultDamageDisabled = true;
		}
	}
	
	if(bDamage[attacker])
	{
		if(bWeakDamage[victim])
		{
			damage *= (fDamage[attacker] + fWeakDamage[victim]);
			//PrintToChatAll("%0.2f (attacker : %N) + %0.2f (victim : %N) : Damage total %0.2f", fDamage[attacker], attacker, fWeakDamage[victim], victim, damage);
		}
		else
		{
			damage *= fDamage[attacker];
			//PrintToChatAll("%0.2f (attacker : %N) Damage total %0.2f",  fDamage[attacker], attacker, damage);
		}
	}
	else if(bWeakDamage[victim])
	{
		if(bDamage[attacker])
		{
			damage *= (fWeakDamage[victim] + fDamage[attacker]);
			//PrintToChatAll("%0.2f (victim : %N) + %0.2f (attacker : %N) : Damage total %0.2f", fWeakDamage[victim], victim, fDamage[attacker], attacker, damage);
		}
		else
		{
			damage *= fWeakDamage[victim];
			//PrintToChatAll("%0.2f (victim : %N) Damage total %0.2f",  fWeakDamage[victim], victim, damage);
		}
	}
	return Plugin_Changed;
}

public Action OnPropTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!IsValidClient(attacker)) return Plugin_Continue;
	
	if(!bEnable)return Plugin_Continue;
	
	if(bIsTF2)
	{
		int iTank = -1;
		iTank = FindEntityByClassname(iTank, "tank_boss");
		int iEnt = -1;
		int iClient;
		
		if(iTank == victim)
		{
			if(bDamage[attacker])
			{
				damage *= fDamage[attacker];
				//PrintToChatAll("%0.2f : Total Damage ; %0.2f damage multiplied of %N", damage, fDamage[attacker], attacker);
			}
		}
		
		while((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
		{
			iClient = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");
			
			if(fDefaultDamage != 1.0)
			{
				bDamage[attacker] = true;
				bWeakDamage[iClient] = false;
				fDamage[attacker] = fDefaultDamage;
				fWeakDamage[iClient] = 1.0;
				
				bDefaultDamageDisabled = false;
			}
			else
			{
				if(!bDefaultDamageDisabled)
				{
					fDamage[attacker] = 1.0;
					fWeakDamage[iClient] = 1.0;
					bDamage[attacker] = false;
					bWeakDamage[iClient] = false;
					
					bDefaultDamageDisabled = true;
				}
			}
			
			if(iEnt == victim)
			{
				if(bDamage[attacker])
				{
					if(bWeakDamage[iClient])
					{ 
						damage *= (fDamage[attacker] + fWeakDamage[iClient]);
						//PrintToChatAll("%0.2f (attacker : %N) + %0.2f (victim : %N) : Damage total %0.2f", fDamage[attacker], attacker, fWeakDamage[iClient], iClient, damage);
					}
					else
					{			
						damage *= fDamage[attacker];
						//PrintToChatAll("%0.2f (attacker : %N) Damage total %0.2f",  fDamage[attacker], attacker, damage);
					}
				}
				else if(bWeakDamage[iClient])
				{
					if(bDamage[attacker])
					{
						damage *= (fWeakDamage[iClient] + fDamage[attacker]);
						//PrintToChatAll("%0.2f (victim : %N) + %0.2f (attacker : %N) : Damage total %0.2f", fWeakDamage[iClient], iClient, fDamage[attacker], attacker, damage);
					}
					else
					{
						damage *= fWeakDamage[iClient];
						//PrintToChatAll("%0.2f (victim : %N) Damage total %0.2f",  fWeakDamage[iClient], iClient, damage);
					}
				}
				if(GetEntProp(iEnt, Prop_Data, "m_iHealth") < 1) //Prevent buildings undestroyable
				{
					//AcceptEntityInput(iEnt, "Kill");
					SetVariantInt(1);
					AcceptEntityInput(iEnt, "AddHealth");
					SDKHooks_TakeDamage(iEnt, inflictor, attacker, 9999.0);
				}
			}
		}
		while((iEnt = FindEntityByClassname(iEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
		{
			iClient = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");
			
			if(fDefaultDamage != 1.0)
			{
				bDamage[attacker] = true;
				bWeakDamage[iClient] = false;
				fDamage[attacker] = fDefaultDamage;
				fWeakDamage[iClient] = 1.0;
				
				bDefaultDamageDisabled = false;
			}
			else
			{
				if(!bDefaultDamageDisabled)
				{
					fDamage[attacker] = 1.0;
					fWeakDamage[iClient] = 1.0;
					bDamage[attacker] = false;
					bWeakDamage[iClient] = false;
					
					bDefaultDamageDisabled = true;
				}
			}
			
			if(iEnt == victim)
			{
				if(bDamage[attacker])
				{
					if(bWeakDamage[iClient])
					{
						damage *= (fDamage[attacker] + fWeakDamage[iClient]);
						//PrintToChatAll("%0.2f (attacker : %N) + %0.2f (victim : %N) : Damage total %0.2f", fDamage[attacker], attacker, fWeakDamage[iClient], iClient, damage);
					}
					else
					{			
						damage *= fDamage[attacker];
						//PrintToChatAll("%0.2f (attacker : %N) Damage total %0.2f",  fDamage[attacker], attacker, damage);
					}
				}
				else if(bWeakDamage[iClient])
				{
					if(bDamage[attacker])
					{
						damage *= (fWeakDamage[iClient] + fDamage[attacker]);
						//PrintToChatAll("%0.2f (victim : %N) + %0.2f (attacker : %N) : Damage total %0.2f", fWeakDamage[iClient], iClient, fDamage[attacker], attacker, damage);
					}
					else
					{
						damage *= fWeakDamage[iClient];
						//PrintToChatAll("%0.2f (victim : %N) Damage total %0.2f",  fWeakDamage[iClient], iClient, damage);
					}
				}
				if(GetEntProp(iEnt, Prop_Data, "m_iHealth") < 1)
				{
					//AcceptEntityInput(iEnt, "Kill");
					SetVariantInt(1);
					AcceptEntityInput(iEnt, "AddHealth");
					SDKHooks_TakeDamage(iEnt, inflictor, attacker, 9999.0);
				}
			}
		}
		while((iEnt = FindEntityByClassname(iEnt, "obj_teleporter")) != INVALID_ENT_REFERENCE)
		{
			iClient = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");
			
			if(fDefaultDamage != 1.0)
			{
				bDamage[attacker] = true;
				bWeakDamage[iClient] = false;
				fDamage[attacker] = fDefaultDamage;
				fWeakDamage[iClient] = 1.0;
				
				bDefaultDamageDisabled = false;
			}
			else
			{
				if(!bDefaultDamageDisabled)
				{
					fDamage[attacker] = 1.0;
					fWeakDamage[iClient] = 1.0;
					bDamage[attacker] = false;
					bWeakDamage[iClient] = false;
					
					bDefaultDamageDisabled = true;
				}
			}
			
			if(iEnt == victim)
			{
				if(bDamage[attacker])
				{
					if(bWeakDamage[iClient])
					{
						damage *= (fDamage[attacker] + fWeakDamage[iClient]);
						//PrintToChatAll("%0.2f (attacker : %N) + %0.2f (victim : %N) : Damage total %0.2f", fDamage[attacker], attacker, fWeakDamage[iClient], iClient, damage);
					}
					else
					{
						damage *= fDamage[attacker];
						//PrintToChatAll("%0.2f (attacker : %N) Damage total %0.2f",  fDamage[attacker], attacker, damage);
					}
				}
				else if(bWeakDamage[iClient])
				{
					if(bDamage[attacker])
					{
						damage *= (fWeakDamage[iClient] + fDamage[attacker]);
						//PrintToChatAll("%0.2f (victim : %N) + %0.2f (attacker : %N) : Damage total %0.2f", fWeakDamage[iClient], iClient, fDamage[attacker], attacker, damage);
					}
					else
					{
						damage *= fWeakDamage[iClient];
						//PrintToChatAll("%0.2f (victim : %N) Damage total %0.2f",  fWeakDamage[iClient], iClient, damage);
					}
				}
				if(GetEntProp(iEnt, Prop_Data, "m_iHealth") < 1)
				{
					//AcceptEntityInput(iEnt, "Kill");
					SetVariantInt(1);
					AcceptEntityInput(iEnt, "AddHealth");
					SDKHooks_TakeDamage(iEnt, inflictor, attacker, 9999.0);
				}
			}
		}
	}
	return Plugin_Changed;
}

public Action Command_DamageMult(int client, int args)
{
	if(bEnable)
	{
		if(!client && args != 2)
		{
			ReplyToCommand(client, "[SM] Usage in server console: sm_dmgmult <target> <value>");
			return Plugin_Handled;
		}
		if(args < 1 ||args > 2)
		{
			ReplyToCommand(client, "[SM] Usage: sm_dmgmult <value>\n[SM] Usage: sm_dmgmult <target> <value>");
			return Plugin_Handled;
		}
		if(args == 1)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			float fVerifyDamage = StringToFloat(arg1);
			
			if(fVerifyDamage == 1.0)
			{
				bDamage[client] = false;
				fDamage[client] = 1.0;
			}
			else if(-0.01 < fVerifyDamage < 0.01)
			{
				bDamage[client] = true;
				fDamage[client] = 0.0;
			}
			else
			{
				bDamage[client] = true;
				fDamage[client] = fVerifyDamage;
			}
			
			CReplyToCommand(client, "[SM] Your {yellow}damage {default}is multiplied by {lime}%0.2f", fDamage[client]);
		}
		else if(args == 2)
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
					return Plugin_Handled;
				
				if(fVerifyDamage == 1.0)
				{
					bDamage[target] = false;
					fDamage[target] = 1.0;
				}
				else if(-0.01 < fVerifyDamage < 0.01)
				{
					bDamage[target] = true;
					fDamage[target] = 0.0;
				}
				else
				{
					bDamage[target] = true;
					fDamage[target] = fVerifyDamage;
				}
				CReplyToCommand(target, "[SM] Your {yellow}damage {default}is multiplied by {lime}%0.2f", fDamage[target]);
			}
			if(-0.01 < fVerifyDamage < 0.01)
				fVerifyDamage = 0.00;
				
			CShowActivity2(client, "[SM] ", "{grey}%s's {yellow}damage {default}multiplied by {lime}%0.2f", target_name, fVerifyDamage);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage multiplier\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageReset(int client, int args)
{
	if(bEnable)
	{
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: sm_dmgreset <target>");
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_dmgreset\n[SM] Usage: sm_dmgreset <target>");
			return Plugin_Handled;
		}
		if(!args)
		{
			if(bDamage[client])
				CReplyToCommand(client, "[SM] Your {yellow}damage {default}has been reset");
				
			else
				CReplyToCommand(client, "[SM] Your {yellow}damage {default}is already on the default value");
				
			bDamage[client] = false;
			fDamage[client] = 1.0;
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
					return Plugin_Handled;
					
				if(bDamage[target])
					CReplyToCommand(target, "[SM] Your {yellow}damage {default}has been reset to the default value");
					
				bDamage[target] = false;
				fDamage[target] = 1.0;
			}
			CShowActivity2(client, "[SM] ", "{grey}%s's {yellow}damage {default}is reset", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage multiplier\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeakMult(int client, int args)
{
	if(bEnable)
	{
		if(!client && args != 2)
		{
			ReplyToCommand(client, "[SM] Usage in server console: sm_dmgweakmult <target> <value>");
			return Plugin_Handled;
		}
		if(args < 1 || args > 2)
		{
			ReplyToCommand(client, "[SM] Usage: sm_dmgweakmult <value>\n[SM] Usage: sm_dmgweakmult <target> <value>");
			return Plugin_Handled;
		}
		if(args == 1)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			
			float fVerifyDamage = StringToFloat(arg1);
			
			if(fVerifyDamage == 1.0)
			{
				bWeakDamage[client] = false;
				fWeakDamage[client] = 1.0;
			}
			else if(-0.01 < fVerifyDamage < 0.01)
			{
				bWeakDamage[client] = true;
				fWeakDamage[client] = 0.0;
			}
			else
			{
				bWeakDamage[client] = true;
				fWeakDamage[client] = fVerifyDamage;
			}
			CReplyToCommand(client, "[SM] You will receive {yellow}damage {default}multiplied by {lime}%0.2f", fWeakDamage[client]);
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
					return Plugin_Handled;
					
				if(fVerifyDamage == 1.0)
				{
					bWeakDamage[target] = false;
					fWeakDamage[target] = 1.0;
				}
				else if(-0.01 < fVerifyDamage < 0.01)
				{
					bWeakDamage[target] = true;
					fWeakDamage[target] = 0.0;
				}
				else
				{
					bWeakDamage[target] = true;
					fWeakDamage[target] = fVerifyDamage;
				}
				CReplyToCommand(target, "[SM] You will receive {yellow}damage {default}multiplied by {lime}%0.2f", fWeakDamage[target]);
			}
			if(-0.01 < fVerifyDamage < 0.01)
				fVerifyDamage = 0.0;
				
			CShowActivity2(client, "[SM] ", "{grey}%s {default}will receive {yellow}damage {default}multiplied by {lime}%0.2f", target_name, fVerifyDamage);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage multiplier\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageWeakReset(int client, int args)
{
	if(bEnable)
	{
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: sm_dmgweakreset <target>");
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_dmgweakreset\n[SM] Usage: sm_dmgweakreset <target>");
			return Plugin_Handled;
		}
		if(!args)
		{
			if(bWeakDamage[client])
				CReplyToCommand(client, "[SM] You will receive {yellow}normal damage (x1 damage)");
			
			else
				CReplyToCommand(client, "[SM] You already receive {yellow}normal damage (x1 damage)");
				
			bWeakDamage[client] = false;
			fWeakDamage[client] = 1.0;
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
					return Plugin_Handled;
					
				if(bWeakDamage[target])
					CReplyToCommand(target, "[SM] You will receive {yellow}normal damage (x1 damage)");
					
				bWeakDamage[target] = false;
				fWeakDamage[target] = 1.0;
			}
			CShowActivity2(client, "[SM]", "{grey}%s {default}will receive {yellow}normal damage (x1 damage)", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage multiplier\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_GetDamageMult(int client, int args)
{
	if(bEnable)
	{
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: sm_getdmgmult <target>");
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_getdmgmult\n[SM] Usage: sm_getdmgmult <target>");
			return Plugin_Handled;
		}
		if(!args)
			CReplyToCommand(client, "[SM] Your {yellow}damage {default}is multiplied by {lime}%0.2f", fDamage[client]);
		
		if(args == 1)
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1);
			if(target == -1)
				return Plugin_Handled;
				
			CReplyToCommand(client, "[SM] %N's {yellow}damage {default}is multiplied by {lime}%0.2f", target, fDamage[target]);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage multiplier\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_GetDamageWeakMult(int client, int args)
{
	if(bEnable)
	{
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: sm_getdmgweakmult <target>");
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_getdmgweakmult\n[SM] Usage: sm_getdmgweakmult <target>");
			return Plugin_Handled;
		}
		if(!args)
			CReplyToCommand(client, "[SM] You receive {yellow}damage {default}multiplied by {lime}%0.2f", fWeakDamage[client]);
			
		if(args == 1)
		{
			char arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1);
			
			if(target == -1)
				return Plugin_Handled;
				
			CReplyToCommand(client, "[SM] %N receive {yellow}damage {default}multiplied by {lime}%0.2f", target, fWeakDamage[target]);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage multiplier\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_DamageResetAll(int client, int args)
{
	if(bEnable)
	{
		if(!client && args != 1)
		{
			ReplyToCommand(client, "[SM] Usage in server console: sm_dmgresetall <target>");
			return Plugin_Handled;
		}
		if(args > 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_dmgresetall\n[SM] Usage: sm_dmgresetall <target>");
			return Plugin_Handled;
		}
		if(!args)
		{	
			if(bDamage[client] && bWeakDamage[client])
			{
				CReplyToCommand(client, "{green}[SM] All damage (did or received) are now reset");
				bDamage[client] = false;
				bWeakDamage[client] = false;
				fDamage[client] = 1.0;
				fWeakDamage[client] = 1.0;
			}
			
			else if(bDamage[client] && !bWeakDamage[client])
			{
				CReplyToCommand(client, "{green}[SM] Your damage has been reset to the default value");
				bDamage[client] = false;
				bWeakDamage[client] = false;
				fDamage[client] = 1.0;
				fWeakDamage[client] = 1.0;
			}
			else if(!bDamage[client] && bWeakDamage[client])
			{
				CReplyToCommand(client, "{green}[SM] You will receive normal damage (x1 damage)");
				bDamage[client] = false;
				bWeakDamage[client] = false;
				fDamage[client] = 1.0;
				fWeakDamage[client] = 1.0;
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
					return Plugin_Handled;
				
				if(bDamage[target] && bWeakDamage[target])
				{
					CReplyToCommand(target, "{green}[SM] All damage (did or received) are now reset");
					bDamage[target] = false;
					bWeakDamage[target] = false;
					fDamage[target] = 1.0;
					fWeakDamage[target] = 1.0;
				}
					
				else if(bDamage[target] && !bWeakDamage[target])
				{
					CReplyToCommand(target, "[SM] Your {yellow}damage {default}has been reset to the default value");
					bDamage[target] = false;
					bWeakDamage[target] = false;
					fDamage[target] = 1.0;
					fWeakDamage[target] = 1.0;
				}
				else if(!bDamage[target] && bWeakDamage[target])
				{
					CReplyToCommand(target, "[SM] You will receive {yellow}normal damage (x1 damage)");
					bDamage[target] = false;
					bWeakDamage[target] = false;
					fDamage[target] = 1.0;
					fWeakDamage[target] = 1.0;
				}
			}
			CShowActivity2(client, "[SM] ", "{green}All damage of {grey}%s {green}(did or received) are now reset", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \"Damage multiplier\" plugin is not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void CheckGames()
{
	char cGame[32];
	GetGameFolderName(cGame, sizeof(cGame));
	
	if(StrEqual(cGame, "tf"))
		bIsTF2 = true;
}

//***********STOCKS***********//

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}