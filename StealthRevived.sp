#include <StealthRevived>
#include <sdktools>
#include <sdkhooks>
#include <regex>
#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#tryinclude <ptah>
#tryinclude <SteamWorks>

#define PL_VERSION "1.0.1"
#define LoopValidPlayers(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))
#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1, false))

#pragma newdecls required;
#pragma semicolon 1;

public Plugin myinfo =  {
	name = "Stealth Revived", 
	author = "SM9(), moongetsu", 
	description = "Just another Stealth plugin.", 
	version = PL_VERSION, 
	url = "https://sm9.dev"
}

ConVar g_cvHostName = null;
ConVar g_cvHostPort = null;
ConVar g_cvHostIP = null;
ConVar g_cvCustomStatus = null;
ConVar g_cvSetTransmit = null;

bool g_bStealthed[MAXPLAYERS + 1];
bool g_bWindows = false;
bool g_bRewriteStatus = false;
bool g_bDataCached = false;
bool g_bSetTransmit = true;
bool g_bPTaH = false;

int g_iLastStatusCommand[MAXPLAYERS + 1];
int g_iTickRate = 0;
int g_iServerPort = 0;
int g_iPlayerManager = -1;

char g_sVersion[32];
char g_sHostName[256];
char g_sServerIP[32];
char g_sCurrentMap[PLATFORM_MAX_PATH];
char g_sMaxPlayers[12];

public void OnPluginStart() {
	AutoExecConfig_SetFile("StealthRevived", "SM9");
	
	g_cvCustomStatus = AutoExecConfig_CreateConVar("sm_stealthrevived_status", "1", "Should the plugin rewrite status?", _, true, 0.0, true, 1.0);
	g_cvCustomStatus.AddChangeHook(OnCvarChanged);
	
	g_cvSetTransmit = AutoExecConfig_CreateConVar("sm_stealthrevived_hidecheats", "1", "Should the plugin prevent cheats with 'spectator list' working? (This option may cause performance issues on some servers)", _, true, 0.0, true, 1.0);
	g_cvSetTransmit.AddChangeHook(OnCvarChanged);
	
	AutoExecConfig_CleanFile(); AutoExecConfig_ExecuteFile();
	
	g_cvHostName = FindConVar("hostname");
	g_cvHostPort = FindConVar("hostport");
	g_cvHostIP = FindConVar("hostip");
	
	#if defined _PTaH_included
	if (LibraryExists("PTaH")) {
		g_bPTaH = PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);
	}
	#endif
	
	if (!g_bPTaH) {
		AddCommandListener(Command_Status, "status");
	}
	
	if (!HookEventEx("player_team", Event_PlayerTeam_Pre, EventHookMode_Pre)) {
		SetFailState("player_team event does not exist on this mod, plugin disabled");
		return;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] eror, int err_max) {
	RegPluginLibrary("StealthRevived");
	CreateNative("SR_IsClientStealthed", Native_IsClientStealthed);
	return APLRes_Success;
}

public void OnCvarChanged(ConVar conVar, const char[] oldValue, const char[] newValue) {
	if (conVar == g_cvCustomStatus) {
		g_bRewriteStatus = view_as<bool>(StringToInt(newValue));
	} else if (conVar == g_cvSetTransmit) {
		g_bSetTransmit = view_as<bool>(StringToInt(newValue));
		
		if (g_bSetTransmit) {
			LoopValidPlayers(client) {
				if (!g_bStealthed[client]) {
					continue;
				}
				
				SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
			}
		}
	}
}

public void OnConfigsExecuted() {
	g_bRewriteStatus = g_cvCustomStatus.BoolValue;
	g_bSetTransmit = g_cvSetTransmit.BoolValue;
	
	LoopValidPlayers(client) {
		if (!CanGoStealth(client) || GetClientTeam(client) > 1) {
			continue;
		}
		
		if (g_bSetTransmit) {
			SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		}
		
		g_bStealthed[client] = true;
	}
}

public void OnMapStart() {
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	
	g_iPlayerManager = GetPlayerResourceEntity();
	
	if (g_iPlayerManager != -1) {
		SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PlayerManagerThinkPost);
	}
}

public Action Command_Status(int client, const char[] commandName, int args) {
	if (!client || !g_bRewriteStatus) {
		return Plugin_Continue;
	}
	
	ExecuteStringCommand(client, "status");
	return Plugin_Handled;
}

public Action ExecuteStringCommand(int client, char commandName[1024]) {
	if (!client || !g_bRewriteStatus) {
		return Plugin_Continue;
	}
	
	TrimString(commandName);
	
	if (StrContains(commandName, "status") != 0) {
		return Plugin_Continue;
	}
	
	if (!IsClientInGame(client) || (g_iLastStatusCommand[client] > -1 && GetTime() - g_iLastStatusCommand[client] < 1)) {
		return Plugin_Handled;
	}
	
	PrintCustomStatus(client);
	return Plugin_Handled;
}

public Action Event_PlayerTeam_Pre(Event event, char[] eventName, bool dontBroadcast) {
	int client;
	
	if (!(client = GetClientOfUserId(event.GetInt("userid"))) || IsFakeClient(client) || view_as<bool>(event.GetInt("disconnect"))) {
		return Plugin_Continue;
	}
	
	int toTeam = event.GetInt("team");
	
	if (toTeam > 1) {
		if (g_bStealthed[client]) {
			event.BroadcastDisabled = true;
		}
		
		g_bStealthed[client] = false;
		return Plugin_Continue;
	}
	
	if (CanGoStealth(client)) {
		g_bStealthed[client] = true;
		event.BroadcastDisabled = true;
		
		if (g_bSetTransmit) {
			SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client) {
	g_iLastStatusCommand[client] = -1;
	g_bStealthed[client] = false;
}

public void OnEntityCreated(int entity, const char[] className) {
	if (StrContains(className, "player_manager", false) == -1) {
		return;
	}
	
	g_iPlayerManager = entity;
	SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PlayerManagerThinkPost);
}

public void Hook_PlayerManagerThinkPost(int entity) {
	bool changed = false;
	
	LoopValidPlayers(client) {
		if (!g_bStealthed[client]) {
			continue;
		}
		
		SetEntProp(g_iPlayerManager, Prop_Send, "m_bConnected", false, _, client);
		changed = true;
	}
	
	if (changed) {
		ChangeEdictState(entity);
	}
}

public Action Hook_SetTransmit(int entity, int client) {
	if (entity == client) {
		return Plugin_Continue;
	}
	
	if (!g_bSetTransmit || !g_bStealthed[entity]) {
		SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

stock bool PrintCustomStatus(int client) {
	if (!g_bDataCached) {
		CacheInformation();
	}
	
	PrintToConsole(client, "hostname: %s", g_sHostName);
	PrintToConsole(client, g_sVersion);
	PrintToConsole(client, "udp/ip  : %s:%d", g_sServerIP, g_iServerPort);
	PrintToConsole(client, "os      : %s", g_bWindows ? "Windows" : "Linux");
	PrintToConsole(client, "type    : community dedicated");
	PrintToConsole(client, "map     : %s", g_sCurrentMap);
	PrintToConsole(client, "players : %d humans, %d bots %s (not hibernating)\n", GetPlayerCount(), GetBotCount(), g_sMaxPlayers);
	PrintToConsole(client, "# userid name uniqueid connected ping loss state rate");
	
	char clientAuthId[64];
	char sTime[9];
	char sRate[9];
	char clientName[MAX_NAME_LENGTH];
	
	LoopValidClients(i) {
		if (g_bStealthed[i]) {
			continue;
		}
		
		FormatEx(clientName, sizeof(clientName), "\"%N\"", i);
		
		if (!IsFakeClient(i)) {
			GetClientAuthId(i, AuthId_Steam2, clientAuthId, sizeof(clientAuthId));
			GetClientInfo(i, "rate", sRate, sizeof(sRate));
			FormatShortTime(RoundToFloor(GetClientTime(i)), sTime, sizeof(sTime));
			
			PrintToConsole(client, "# %d %d %s %s %s %d %d active %s", GetClientUserId(i), i, clientName, clientAuthId, sTime, GetPing(i), GetLoss(i), sRate);
		} else {
			PrintToConsole(client, "#%d %s BOT active %d", i, clientName, g_iTickRate);
		}
	}
	
	PrintToConsole(client, "#end");
	
	g_iLastStatusCommand[client] = GetTime();
	
	return true;
}

public void CacheInformation() {
	bool secure = false; bool steamWorks;
	char sStatus[512]; char sBuffer[512]; ServerCommandEx(sStatus, sizeof(sStatus), "status");
	
	g_iTickRate = RoundToZero(1.0 / GetTickInterval());
	
	g_bWindows = StrContains(sStatus, "os      :  Windows", true) != -1;
	g_cvHostName.GetString(g_sHostName, sizeof(g_sHostName));
	g_iServerPort = g_cvHostPort.IntValue;
	
	#if defined _SteamWorks_Included
	steamWorks = LibraryExists("SteamWorks");
	
	if (steamWorks) {
		int ip[4];
		SteamWorks_GetPublicIP(ip);
		secure = SteamWorks_IsVACEnabled();
		FormatEx(g_sServerIP, sizeof(g_sServerIP), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
	}
	#endif
	
	if (!steamWorks) {
		int serverIP = g_cvHostIP.IntValue;
		FormatEx(g_sServerIP, sizeof(g_sServerIP), "%d.%d.%d.%d", serverIP >>> 24 & 255, serverIP >>> 16 & 255, serverIP >>> 8 & 255, serverIP & 255);
	}
	
	Regex regex = CompileRegex("version (.*?) secure");
	int matches = regex.Match(sStatus);
	
	if (matches < 1) {
		delete regex;
		
		if (!steamWorks) {
			secure = false;
		}
		
		regex = CompileRegex("version (.*?) insecure");
		matches = regex.Match(sStatus);
	} else if (!steamWorks) {
		secure = true;
	}
	
	if (matches > 0) {
		regex.GetSubString(0, sBuffer, sizeof(sBuffer));
	}
	
	delete regex;
	
	char sSplit[2][64];
	ExplodeString(sBuffer, "/", sSplit, sizeof(sSplit), sizeof(sSplit[]));
	FormatEx(g_sVersion, sizeof(g_sVersion), "%s %s", sSplit[0], secure ? "secure" : "insecure");
	
	regex = CompileRegex("\\((.*? max)\\)");
	matches = regex.Match(sStatus);
	
	if (matches > 0) {
		regex.GetSubString(1, sBuffer, sizeof(sBuffer));
	}
	
	delete regex;
	
	FormatEx(g_sMaxPlayers, sizeof(g_sMaxPlayers), "(%s)", sBuffer);
	
	g_bDataCached = true;
}

stock bool IsValidClient(int client, bool ignoreBots = true) {
	if (client < 1 || client > MaxClients) {
		return false;
	}
	
	if (!IsClientInGame(client)) {
		return false;
	}
	
	if (IsFakeClient(client) && ignoreBots) {
		return false;
	}
	
	return true;
}

stock bool CanGoStealth(int client) {
	return CheckCommandAccess(client, "admin_stealth", ADMFLAG_KICK);
}

stock int GetPlayerCount() {
	int count = 0;
	
	LoopValidPlayers(client) {
		if (g_bStealthed[client]) {
			continue;
		}
		
		count++;
	}
	
	return count;
}

stock int GetBotCount() {
	int count = 0;
	
	LoopValidClients(client) {
		if (!IsFakeClient(client)) {
			continue;
		}
		
		count++;
	}
	
	return count;
}

stock int GetLoss(int client) {
	return RoundFloat(GetClientAvgLoss(client, NetFlow_Both));
}

stock int GetPing(int client) {
	return RoundFloat(GetClientLatency(client, NetFlow_Both) * 1000.0);
}

// Thanks Necavi - https://forums.alliedmods.net/showthread.php?p=1796351
stock void FormatShortTime(int time, char[] sOut, int iSize) {
	int tempInt = time % 60;
	
	FormatEx(sOut, iSize, "%02d", tempInt);
	tempInt = (time % 3600) / 60;
	
	FormatEx(sOut, iSize, "%02d:%s", tempInt, sOut);
	
	tempInt = (time % 86400) / 3600;
	
	if (tempInt > 0) {
		FormatEx(sOut, iSize, "%d%:s", tempInt, sOut);
	}
}

public int Native_IsClientStealthed(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	return g_bStealthed[client];
} 