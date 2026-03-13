<h1 align="center">
  <img src="https://images.gamebanana.com/img/ico/sprays/naruto.gif" width="64" alt="Stealth Revived"/>
  <br />
  Stealth Revived
</h1>
<p align="center">
  <b>Powerful SourceMod plugin for <span style="color:#19a974;">stealthy</span> spectating and admin tools in CS:GO servers.</b><br>
  <i>Catching cheaters has never been easier or cleaner.</i>
</p>

<hr>

## 🕵️ About

**Stealth Revived** is a modern SourcePawn plugin built for CS:GO, designed to help server admins catch cheaters by allowing them to truly vanish when spectating players.

---

## ⚙️ How Does It Work?

1. **Join Spectator:** Switch to spectator with admin flag (kick by default, or customize via `admin_stealth` override).
2. **Vanishing Act:** Your presence is hidden from scoreboard, status, and "Show spectators" features.
3. **Spectate & Catch:** Watch potential cheaters without alerting them. All announcement messages are suppressed when entering/leaving teams as stealth.

---

## 🛠️ Requirements

- **[PTaH](https://forums.alliedmods.net/showthread.php?t=264667)** (CS:GO) – for best-in-class status rewriting (falls back to slower command listening if absent).
- **[SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556)** – for accurate IP/VAC checks (falls back to `hostip`).

<sub>*Both are optional, but highly recommended for full functionality and performance.*</sub>

---

## 📦 Installation

1. Add the files into your CS:GO server.
2. Install the extensions ([PTaH](https://github.com/komashchenko/PTaH/releases) and [SteamWorks](https://github.com/KyleSanderson/SteamWorks/releases)).
3. Set up the `admin_stealth` override as desired (`@flag`).
4. Join spectator and monitor freely & discreetly!

---

## 📝 ConVars

| ConVar                            | Description                                                           | Default |
|------------------------------------|-----------------------------------------------------------------------|:-------:|
| `sm_stealthrevived_status`         | Should plugin rewrite status?                                         |   1     |
| `sm_stealthrevived_hidecheats`     | Prevent 'spectator list' cheats? (may impact performance on some servers) |   1     |

---

## ✨ What's New in v1.0.1 (Refactor)

- 🚀 **Performance Optimization:** Global counter system to skip expensive loops when no admins are in stealth.
- 🛠️ **Stability Fix:** Resolved compilation errors (Error 147) related to legacy `ptah.inc`.
- 🧹 **Code Cleanup:** Massive refactor removing legacy macros, TF2 remnants, and inconsistent spacing.
- 📡 **Better Caching:** Improved detection logic for Server Version, OS, and Public IP.
- 💎 **Standardized Structure:** Professional code organization for easier maintenance.

---

## 🤝 Credits

Big thanks to everyone who made this plugin possible!
- **SM9()** – Original developer.
- **moongetsu** – Refactoring, optimizations, and modern features.
- **Drixevel** – Knowledge & support (especially TF2 insights).
- **komashchenko** – For PTaH; rewriting status in CSGO wouldn't work without you.
- **Byte** – Private testing & ShouldTransmit method.
- **Sneak** – Private testing.
- **Psychonic** & **Asherkin** – Help and suggestions on Sourcemod IRC.
- **Necavi** – [Original Admin Stealth plugin](https://forums.alliedmods.net/showthread.php?p=1796351).

---

<p align="center">
  <img src="https://badgen.net/badge/Optimized%20for/CS:GO/green?icon=sourceengine" alt="CSGO Optimized" />
  <img src="https://badgen.net/badge/Version/v1.0.1/blue" alt="Version" />
  <img src="https://badgen.net/badge/Language/SourcePawn/orange" alt="SourcePawn" />
</p>
