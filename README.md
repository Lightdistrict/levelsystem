# MAX Level System

A from-scratch DarkRP leveling/XP/prestige system with skill points, similar in concept to vrondakis' DarkRP Leveling System but fully custom code you own outright.

## Install

Drop this whole repo into `garrysmod/addons/levelsystem/` and restart. The Skills tab in the F4 menu only appears if this addon **and** the `f4menu` addon (with its latest update) are both installed.

## What it does

- **XP & levels**: max level 100, with an increasing XP curve (`Config.xpForLevel`). XP comes from killing players, killing NPCs, and a passive tick just for being online.
- **Prestige**: at level 100, prestige to reset to level 1 and gain a Prestige rank, up to Prestige 10. Optionally wipes spent skill points on prestige (configurable).
- **Skill points**: 1 point per level-up (configurable), spendable on 7 stat categories: Jump Height, Health, Armor, Salary, Run Speed, Fall Damage, and XP (a gain-rate multiplier). Each has its own max points and per-point effect, all defined in config.
- **Job level-gating**: require a minimum level (and optionally prestige) for any job, checked server-side via DarkRP's real `playerCanChangeTeam` hook — not just hidden in the UI, actually enforced.
- **Persistence**: self-contained, one JSON file per player under `data/levelsystem/players/<steamid64>.txt` — no external database required.

## Configuration

Everything tunable lives in `lua/levelsystem/sh_config.lua`:

- `maxLevel`, `maxPrestige`
- `xpForLevel(level)` — the XP curve formula
- `xpRewards` — XP per player kill, NPC kill, and the passive tick amount/interval
- `skillPointsPerLevel`
- `resetSkillsOnPrestige` — wipe skill points on prestige or keep them
- `skills` — the 7 stat categories: display name, max points, and per-point effect value
- `resetSkillsCost` — DarkRP money cost to respec all skill points (0 = free)
- `jobRequirements` — keyed by job name (not team index), e.g.:
  ```lua
  Config.jobRequirements = {
      ["Police Officer"] = { level = 10 },
      ["SWAT"] = { level = 25, prestige = 1 },
  }
  ```

## How each skill point actually works

- **Jump Height**: `+perPoint` as a multiplier on `SetJumpPower` (default 2%/point)
- **Health**: `+perPoint` to max health, applied via `SetMaxHealth` (default 5/point)
- **Armor**: `+perPoint` starting armor on spawn (default 5/point)
- **Salary**: `+perPoint` flat bonus added to every DarkRP paycheck, via the real `playerGetSalary` hook (default $3/point)
- **Run Speed**: `+perPoint` to run/walk speed (default 5 units/sec per point)
- **Fall Damage**: `-perPoint` percentage off fall damage taken, via the real `GetFallDamage` hook, which correctly mirrors DarkRP's own damage calc (flat vs. speed-based, depending on your server's `mp_falldamage`/`realisticfalldamage` settings) before applying the reduction (default -3%/point, capped at -90%)
- **XP**: `+perPoint` percentage bonus to all future XP gained (default 2%/point) — compounds with itself as you invest more

All effects are re-applied fresh on every spawn and immediately after spending/resetting points, so they never stack across respawns or desync.

## Admin commands

Registered through SAM (as `!setlevel`, `!givexp`, `!takexp`, `!setprestige`) if SAM is installed, each gated behind its own permission (defaults to the `moderator` group -- adjust in SAM's permissions UI). Concommands with the same names are always registered too, as a console/RCON fallback that works even without SAM:

```
levelsystem_setlevel <steamid|userid> <level>
levelsystem_givexp <steamid|userid> <amount>
levelsystem_takexp <steamid|userid> <amount>
levelsystem_setprestige <steamid|userid> <prestige>
```

Console commands only run from the dedicated server console or a superadmin's client console. `givexp`/`takexp` don't apply the XP-skill bonus and `takexp` never delevels a player, it just floors their current XP at 0.

## Notes

- The salary and fall-damage hooks were verified against DarkRP's actual gamemode source (not guessed) to make sure they hook the real, correct mechanism.
- Job-gating uses `playerCanChangeTeam`, DarkRP's real job-change validation hook — it blocks the change server-side with a message, so it can't be bypassed by a modified client.
- No XP bar/HUD element yet — that's planned for the HUD pass. The F4 menu Skills tab shows level/prestige/points as text only for now.
