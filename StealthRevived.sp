#pragma semicolon 1

#include <StealthRevived>
#include <sdktools>
#include <sdkhooks>
#include <regex>
#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#tryinclude <ptah>
#tryinclude <SteamWorks>

#pragma newdecls required

#define PL_VERSION "v1.0.1"

public Plugin myinfo =
{
    name        = "Stealth Revived",
    author      = "SM9(), moongetsu",
    description = "Just another Stealth plugin.",
    version     = PL_VERSION,
    url         = "https://sm9.dev"
};

ConVar g_cvHostName     = null;
ConVar g_cvHostPort     = null;
ConVar g_cvHostIP       = null;
ConVar g_cvCustomStatus = null;
ConVar g_cvSetTransmit  = null;

bool   g_bStealthed[MAXPLAYERS + 1];
int    g_iStealthCount  = 0;

bool   g_bWindows       = false;
bool   g_bRewriteStatus = false;
bool   g_bDataCached    = false;
bool   g_bSetTransmit   = true;

int    g_iLastStatusCommand[MAXPLAYERS + 1];
int    g_iTickRate      = 0;
int    g_iServerPort    = 0;
int    g_iPlayerManager = -1;

char   g_sVersion[64];
char   g_sHostName[256];
char   g_sServerIP[32];
char   g_sCurrentMap[PLATFORM_MAX_PATH];
char   g_sMaxPlayers[12];

public void OnPluginStart()
{
    AutoExecConfig_SetFile("StealthRevived", "SM9");

    g_cvCustomStatus = AutoExecConfig_CreateConVar("sm_stealthrevived_status", "1", "Should the plugin rewrite status?", _, true, 0.0, true, 1.0);
    g_cvCustomStatus.AddChangeHook(OnCvarChanged);

    g_cvSetTransmit = AutoExecConfig_CreateConVar("sm_stealthrevived_hidecheats", "1", "Should the plugin prevent cheats with 'spectator list' working?", _, true, 0.0, true, 1.0);
    g_cvSetTransmit.AddChangeHook(OnCvarChanged);

    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();

    g_cvHostName = FindConVar("hostname");
    g_cvHostPort = FindConVar("hostport");
    g_cvHostIP   = FindConVar("hostip");

#if defined _PTaH_included
    PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);
#endif

    if (!HookEventEx("player_team", Event_PlayerTeam_Pre, EventHookMode_Pre))
    {
        SetFailState("player_team event does not exist on this mod, plugin disabled");
        return;
    }
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] eror, int err_max)
{
    RegPluginLibrary("StealthRevived");
    CreateNative("SR_IsClientStealthed", Native_IsClientStealthed);
    return APLRes_Success;
}

public void OnCvarChanged(ConVar conVar, const char[] oldValue, const char[] newValue)
{
    if (conVar == g_cvCustomStatus)
    {
        g_bRewriteStatus = conVar.BoolValue;
    }
    else if (conVar == g_cvSetTransmit)
    {
        g_bSetTransmit = conVar.BoolValue;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (g_bStealthed[i] && IsClientInGame(i))
            {
                if (g_bSetTransmit) SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
                else SDKUnhook(i, SDKHook_SetTransmit, Hook_SetTransmit);
            }
        }
    }
}

public void OnConfigsExecuted()
{
    g_bRewriteStatus = g_cvCustomStatus.BoolValue;
    g_bSetTransmit   = g_cvSetTransmit.BoolValue;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && CanGoStealth(i) && GetClientTeam(i) <= 1)
        {
            UpdateStealth(i, true);
        }
    }
}

public void OnMapStart()
{
    GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
    g_iPlayerManager = GetPlayerResourceEntity();

    if (g_iPlayerManager != -1)
    {
        SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PlayerManagerThinkPost);
    }
}

public void OnClientDisconnect(int client)
{
    g_iLastStatusCommand[client] = -1;
    if (g_bStealthed[client])
    {
        UpdateStealth(client, false);
    }
}

public void OnEntityCreated(int entity, const char[] className)
{
    if (StrEqual(className, "player_manager", false))
    {
        g_iPlayerManager = entity;
        SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PlayerManagerThinkPost);
    }
}

public Action Command_Status(int client, const char[] commandName, int args)
{
    if (!client || !g_bRewriteStatus)
    {
        return Plugin_Continue;
    }

    ExecuteStringCommand(client, "status");
    return Plugin_Handled;
}

public Action ExecuteStringCommand(int client, char commandName[512])
{
    if (!client || !g_bRewriteStatus || !IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    if (StrContains(commandName, "status", false) != -1)
    {
        if (g_iLastStatusCommand[client] == -1 || GetTime() - g_iLastStatusCommand[client] >= 1)
        {
            PrintCustomStatus(client);
        }
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Event_PlayerTeam_Pre(Event event, char[] eventName, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!client || IsFakeClient(client) || event.GetBool("disconnect"))
    {
        return Plugin_Continue;
    }

    int toTeam = event.GetInt("team");

    if (toTeam > 1)
    {
        if (g_bStealthed[client])
        {
            event.BroadcastDisabled = true;
            UpdateStealth(client, false);
        }
        return Plugin_Continue;
    }

    if (CanGoStealth(client))
    {
        event.BroadcastDisabled = true;
        UpdateStealth(client, true);
    }

    return Plugin_Continue;
}

public void Hook_PlayerManagerThinkPost(int entity)
{
    if (g_iStealthCount == 0)
    {
        return;
    }

    bool changed = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bStealthed[i])
        {
            SetEntProp(entity, Prop_Send, "m_bConnected", false, _, i);
            changed = true;
        }
    }

    if (changed)
    {
        ChangeEdictState(entity);
    }
}

public Action Hook_SetTransmit(int entity, int client)
{
    if (entity == client)
    {
        return Plugin_Continue;
    }

    if (!g_bSetTransmit || !g_bStealthed[entity])
    {
        SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

#if defined _SteamWorks_Included
public Action SteamWorks_OnGetPlayerInfo(int client, char[] name, int &score, float &duration)
{
    if (client >= 1 && client <= MaxClients && g_bStealthed[client])
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}
#endif

stock void UpdateStealth(int client, bool state)
{
    if (g_bStealthed[client] == state) return;

    g_bStealthed[client] = state;

    if (state)
    {
        g_iStealthCount++;
        if (g_bSetTransmit) SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
    }
    else
    {
        g_iStealthCount--;
        SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
    }
}

stock bool PrintCustomStatus(int client)
{
    if (!g_bDataCached)
    {
        CacheInformation();
    }

    PrintToConsole(client, "hostname: %s", g_sHostName);
    PrintToConsole(client, "version : %s", g_sVersion);
    PrintToConsole(client, "udp/ip  :  %s:%d", g_sServerIP, g_iServerPort);
    PrintToConsole(client, "os      :  %s", g_bWindows ? "Windows" : "Linux");
    PrintToConsole(client, "type    :  community dedicated");
    PrintToConsole(client, "map     : %s", g_sCurrentMap);

    int humans = 0;
    int bots   = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (GetClientTeam(i) <= 1 && CanGoStealth(i))
            {
                g_bStealthed[i] = true;
                continue;
            }

            if (!g_bStealthed[i])
            {
                if (IsFakeClient(i)) bots++;
                else humans++;
            }
        }
    }

    PrintToConsole(client, "players : %d humans, %d bots %s (not hibernating)\n", humans, bots, g_sMaxPlayers);
    PrintToConsole(client, "# userid name uniqueid connected ping loss state rate");

    char clientAuthId[64], sTime[12], sRate[12], clientName[MAX_NAME_LENGTH];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || g_bStealthed[i]) continue;

        FormatEx(clientName, sizeof(clientName), "\"%N\"", i);

        if (!IsFakeClient(i))
        {
            if (!GetClientAuthId(i, AuthId_Steam2, clientAuthId, sizeof(clientAuthId)) || strlen(clientAuthId) < 5)
            {
                if (!GetClientAuthId(i, AuthId_Steam3, clientAuthId, sizeof(clientAuthId)))
                {
                    strcopy(clientAuthId, sizeof(clientAuthId), "STEAM_ID_PENDING");
                }
            }
            GetClientInfo(i, "rate", sRate, sizeof(sRate));
            FormatShortTime(RoundToFloor(GetClientTime(i)), sTime, sizeof(sTime));
            PrintToConsole(client, "# %2d %d %-24s %-20s %s %d %d active %s", GetClientUserId(i), i, clientName, clientAuthId, sTime, GetPing(i), GetLoss(i), sRate);
        }
        else
        {
            PrintToConsole(client, "# %2d %-24s BOT active %d", GetClientUserId(i), clientName, g_iTickRate);
        }
    }

    PrintToConsole(client, "#end");
    g_iLastStatusCommand[client] = GetTime();
    return true;
}

public void CacheInformation()
{
    g_iTickRate = RoundToZero(1.0 / GetTickInterval());
    g_cvHostName.GetString(g_sHostName, sizeof(g_sHostName));
    g_iServerPort = g_cvHostPort.IntValue;

    char sStatus[512];
    ServerCommandEx(sStatus, sizeof(sStatus), "status");

    g_bWindows = (StrContains(sStatus, "os      :  Windows", true) != -1);

    ConVar cvVersion = FindConVar("sv_version");
    if (cvVersion != null)
    {
        cvVersion.GetString(g_sVersion, sizeof(g_sVersion));
    }
    else
    {
        Regex regex = new Regex("version (.*?) secure");
        if (regex.Match(sStatus) > 0)
        {
            regex.GetSubString(1, g_sVersion, sizeof(g_sVersion));
        }
        else
        {
            strcopy(g_sVersion, sizeof(g_sVersion), "1.38.x");
        }
        delete regex;
    }

    bool steamWorks = false;
    bool secure     = true;

#if defined _SteamWorks_Included
    steamWorks = LibraryExists("SteamWorks");
    if (steamWorks)
    {
        int ip[4];
        SteamWorks_GetPublicIP(ip);
        secure = SteamWorks_IsVACEnabled();
        FormatEx(g_sServerIP, sizeof(g_sServerIP), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
    }
#endif

    if (!steamWorks)
    {
        int serverIP = g_cvHostIP.IntValue;
        FormatEx(g_sServerIP, sizeof(g_sServerIP), "%d.%d.%d.%d", serverIP >>> 24 & 255, serverIP >>> 16 & 255, serverIP >>> 8 & 255, serverIP & 255);
    }

    Format(g_sVersion, sizeof(g_sVersion), "%s %s", g_sVersion, secure ? "secure" : "insecure");
    FormatEx(g_sMaxPlayers, sizeof(g_sMaxPlayers), "(%d/0 max)", MaxClients);
    g_bDataCached = true;
}

stock bool CanGoStealth(int client)
{
    if (!client || !IsClientInGame(client)) return false;
    return (GetUserFlagBits(client) & (ADMFLAG_KICK | ADMFLAG_ROOT)) != 0;
}

stock int GetLoss(int client)
{
    return RoundFloat(GetClientAvgLoss(client, NetFlow_Both));
}

stock int GetPing(int client)
{
    return RoundFloat(GetClientLatency(client, NetFlow_Both) * 1000.0);
}

stock void FormatShortTime(int time, char[] sOut, int iSize)
{
    int h = time / 3600;
    int m = (time / 60) % 60;
    int s = time % 60;

    if (h > 0) FormatEx(sOut, iSize, "%d:%02d:%02d", h, m, s);
    else FormatEx(sOut, iSize, "%02d:%02d", m, s);
}

public int Native_IsClientStealthed(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients) return false;
    return g_bStealthed[client];
}