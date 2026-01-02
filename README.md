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

**Stealth Revived** is a modern SourceMod plugin built for CS:GO, designed to help server admins catch cheaters by allowing them to truly vanish when spectating players.

---

## 🚀 Features

- **Invisible Admins:** Hide admins in spectator from scoreboard and status.
- **Bypass "Show Spectators":** Blocks cheats showing who is spectating.
- **CS:GO Optimized:** All code streamlined for CS:GO, no unused legacy or TF2 code.
- **Multilingual:** Supports English & Romanian out of the box.
- **Performance-Focused:** Clean implementation for minimal impact on your server.

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

## ✨ What's New in This Fork

- 🧹 Removed TF2 code, game detection, and unused variables.
- 🌎 Added full translation support (EN/RO).
- 🚀 Major code and performance improvements.
- 🏆 CS:GO only, no legacy baggage.

---

## 🤝 Credits

Big thanks to everyone who made this plugin possible!
- **Drixevel** – Knowledge & support (especially TF2 insights).
- **komashchenko** – For PTaH; rewriting status in CSGO wouldn't work without you.
- **Byte** – Private testing & ShouldTransmit method.
- **Sneak** – Private testing.
- **Psychonic** & **Asherkin** – Help and suggestions on Sourcemod IRC.
- **Necavi** – [Original Admin Stealth plugin](https://forums.alliedmods.net/showthread.php?p=1796351).

---

<p align="center">
  <img src="https://badgen.net/badge/Optimized%20for/CS:GO/green?icon=sourceengine" alt="CSGO Optimized" />
  <img src="https://badgen.net/badge/Language/SourcePawn/orange" alt="SourcePawn" />
</p>
